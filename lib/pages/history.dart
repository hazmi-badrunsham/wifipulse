import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:osm_nominatim/osm_nominatim.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final Nominatim _nominatim = Nominatim(
    userAgent: 'Speed Test History App',
  );
  List<Map<String, dynamic>> entries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFromHive();
  }

  Future<void> _loadFromHive() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final box = Hive.box('history');
      List<Map<String, dynamic>> data = [];

      for (int i = box.length - 1; i >= 0; i--) {
        final item = Map<String, dynamic>.from(box.getAt(i));
        String locationName = item['location_name'] ?? "Unknown";

        if (locationName == "Unknown" || locationName.isEmpty) {
          try {
            final reverseSearchResult = await _nominatim.reverseSearch(
              lat: item['lat'],
              lon: item['lng'],
              addressDetails: true,
              extraTags: true,
              nameDetails: true,
            );

            locationName = _shortenLocationName(
              reverseSearchResult.displayName ?? "Unnamed Location"
            );
            item['location_name'] = locationName;

            await box.putAt(i, item);
          } catch (e) {
            debugPrint('Error getting location: $e');
            locationName = "Location unavailable";
          }
        } else {
          locationName = _shortenLocationName(locationName);
          item['location_name'] = locationName;
        }

        item['location_name'] = locationName;
        item['hive_index'] = i;
        data.add(item);
      }

      if (mounted) {
        setState(() {
          entries = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _shortenLocationName(String fullName) {
    if (fullName.isEmpty || fullName == "Unknown") {
      return "Unknown Location";
    }

    final parts = fullName.split(',');

    // Take only the most relevant parts (usually first 2)
    if (parts.length > 2) {
      // Return city/town and country/region
      final cityPart = parts[0].trim();
      final regionPart = parts[parts.length - 2].trim();
      return '$cityPart, $regionPart';
    }

    return fullName;
  }

  Future<void> _deleteEntry(int hiveIndex) async {
    try {
      final box = Hive.box('history');
      await box.deleteAt(hiveIndex);
      await _loadFromHive();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Entry deleted"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to delete entry"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear History"),
        content: const Text("Are you sure you want to delete all history records? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete All",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final box = Hive.box('history');
        await box.clear();
        
        if (mounted) {
          setState(() {
            entries.clear();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("History cleared"),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error clearing history: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to clear history"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadFromHive();
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return "N/A";
    
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} "
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      debugPrint("Error parsing timestamp: $e");
      return "Invalid date";
    }
  }

  Future<void> _showDeleteDialog(int hiveIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Entry"),
        content: const Text("Are you sure you want to delete this history entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteEntry(hiveIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: _buildSlivers(),
        ),
      ),
    );
  }

  List<Widget> _buildSlivers() {
    final slivers = <Widget>[
      SliverAppBar(
        title: const Text(
          "Speed Test History",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        pinned: true,
        floating: true,
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              tooltip: "Clear All History",
            ),
        ],
      ),
    ];

    if (_isLoading && entries.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    } else if (entries.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No History Yet",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "Your speed test history will appear here",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = entries[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[850],
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 100,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(
                      item['location_name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildSpeedIcon(Icons.download, Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${item['download'].toStringAsFixed(2)} Mbps",
                                style: const TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 16),
                            _buildSpeedIcon(Icons.upload, Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${item['upload'].toStringAsFixed(2)} Mbps",
                                style: const TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (item['wifi_name'] != null && 
                            item['wifi_name'].isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.wifi, size: 14, color: Colors.white70),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item['wifi_name'],
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.white38),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatTimestamp(item['timestamp']),
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _showDeleteDialog(item['hive_index']),
                    ),
                  ),
                ),
              );
            },
            childCount: entries.length,
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _buildSpeedIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}