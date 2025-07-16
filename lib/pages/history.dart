import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:osm_nominatim/osm_nominatim.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> entries = [];

  @override
  void initState() {
    super.initState();
    loadFromHive();
  }

  Future<void> loadFromHive() async {
    final box = Hive.box('history');
    List<Map<String, dynamic>> data = [];

    // Early exit if the widget is not mounted.
    // This is crucial for avoiding setState after dispose.
    if (!mounted) return;

    for (int i = box.length - 1; i >= 0; i--) {
      final item = Map<String, dynamic>.from(box.getAt(i));
      String locationName = item['location_name'] ?? "Unknown";

      if (locationName == "Unknown") {
        try {
          final reverseSearchResult = await Nominatim.reverseSearch(
            lat: item['lat'],
            lon: item['lng'],
            addressDetails: true,
            extraTags: true,
            nameDetails: true,
          );

          locationName = reverseSearchResult.displayName ?? "Unnamed Location";
          item['location_name'] = locationName;

          // Cache it to Hive. No need for setState here, as it's local to the loop.
          // The setState at the end of the function will handle the UI update.
          await box.putAt(i, item);
        } catch (e) {
          locationName = "Failed to get location";
          debugPrint('Error getting location for ${item['lat']}, ${item['lng']}: $e');
        }
      }

      item['location_name'] = locationName;
      item['hive_index'] = i; // for deletion
      data.add(item);
    }

    // Only call setState if the widget is still mounted
    if (mounted) {
      setState(() {
        entries = data;
      });
    }
  }

  Future<void> deleteEntry(int hiveIndex) async {
    final box = Hive.box('history');
    await box.deleteAt(hiveIndex);
    // After deletion, reload the data to update the UI
    await loadFromHive(); // loadFromHive already has the mounted check
    if (mounted) { // Check mounted before showing SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entry deleted")),
      );
    }
  }

  Future<void> clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset History"),
        content: const Text("Are you sure you want to delete all history records?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final box = Hive.box('history');
      await box.clear();
      // Only call setState if the widget is still mounted
      if (mounted) {
        setState(() {
          entries.clear();
        });
      }
      if (mounted) { // Check mounted before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("History cleared")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Speed Test History",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), // Added color
        ),
        backgroundColor: Colors.transparent, // Added for consistency
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              onPressed: clearHistory,
              icon: const Icon(Icons.delete_forever, color: Colors.white), // Added color
              tooltip: "Reset All History",
            ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text("No speed test history yet", style: TextStyle(color: Colors.white)),
            )
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final item = entries[index];
                // Check if 'timestamp' is a valid DateTime string and format it
                String formattedTimestamp = "N/A";
                try {
                  if (item['timestamp'] != null) {
                    final dateTime = DateTime.parse(item['timestamp']);
                    formattedTimestamp = "${dateTime.toLocal().day}/${dateTime.toLocal().month}/${dateTime.toLocal().year} ${dateTime.toLocal().hour.toString().padLeft(2, '0')}:${dateTime.toLocal().minute.toString().padLeft(2, '0')}";
                  }
                } catch (e) {
                  debugPrint("Error parsing timestamp: $e");
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey[850],
                  child: ListTile(
                    title: Text(
                      item['location_name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Download: ${item['download'].toStringAsFixed(2)} Mbps",
                            style: const TextStyle(color: Colors.white)),
                        Text("Upload: ${item['upload'].toStringAsFixed(2)} Mbps",
                            style: const TextStyle(color: Colors.white)),
                        Text("WiFi/Telco: ${item['wifi_name']}",
                            style: const TextStyle(color: Colors.white70)),
                        Text("Time: $formattedTimestamp", // Use formatted timestamp
                            style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      tooltip: 'Delete Entry',
                      onPressed: () => deleteEntry(item['hive_index']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}