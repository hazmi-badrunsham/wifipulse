import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import the insight card we created above
import '../services/pulse_insight.dart';

enum HeatmapType { iiumStudent, iiumWifi, maxis, celcom, umobile, unifi, digi }

class IIUMStudentHeatmapPage extends StatefulWidget {
  const IIUMStudentHeatmapPage({super.key});

  @override
  State<IIUMStudentHeatmapPage> createState() => _IIUMStudentHeatmapPageState();
}

class _IIUMStudentHeatmapPageState extends State<IIUMStudentHeatmapPage> {
  final List<WeightedLatLng> bluePoints = [];
  final List<WeightedLatLng> yellowPoints = [];
  final List<WeightedLatLng> orangePoints = [];
  final List<WeightedLatLng> redPoints = [];
  final List<WeightedLatLng> purplePoints = [];

  LatLng? initialCenter;
  LatLng? userLocation;
  bool isLoading = true;
  bool isAiLoading = false;
  String aiInsight = "Analyzing campus WiFi patterns...";
  final MapController mapController = MapController();

  HeatmapType selectedType = HeatmapType.iiumStudent;

  @override
  void initState() {
    super.initState();
    debugPrint('📍 initState called');
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('🔄 Starting _initialize()');
    await fetchUserLocation();
    await fetchHeatmapData();
    await fetchAIInsight();
    debugPrint('✅ _initialize() completed');
  }

  Future<void> fetchUserLocation() async {
    debugPrint('📡 Attempting to fetch user location...');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location service not enabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Location permission denied, requesting...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
          debugPrint('🚫 Location permission permanently denied or denied again');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
          initialCenter = userLocation;
        });
        debugPrint('✅ User location set: ${userLocation!.latitude}, ${userLocation!.longitude}');
      }
    } catch (e) {
      debugPrint('❌ Error in fetchUserLocation: $e');
    }
  }

  Future<void> fetchAIInsight() async {
    if (userLocation == null) {
      debugPrint('⚠️ Skipping AI insight: userLocation is null');
      return;
    }
    setState(() => isAiLoading = true);
    debugPrint('🧠 Fetching AI insight for ${selectedType.name} at ${userLocation!.latitude}, ${userLocation!.longitude}');

    try {
      final response = await Supabase.instance.client.rpc('get_wifi_insight', params: {
        'target_lat': userLocation!.latitude,
        'target_lng': userLocation!.longitude,
        'target_wifi': selectedType == HeatmapType.iiumStudent ? '"IIUM-Student"' : selectedType.name,
      });

      if (mounted) {
        setState(() {
          aiInsight = response.isNotEmpty ? response[0]['insight_text'] : "No patterns detected yet.";
          isAiLoading = false;
        });
        debugPrint('💡 AI Insight received: $aiInsight');
      }
    } catch (e) {
      debugPrint('❌ AI RPC Error: $e');
      if (mounted) {
        setState(() {
          aiInsight = "Collect more data to unlock AI insights!";
          isAiLoading = false;
        });
      }
    }
  }

  Future<void> fetchHeatmapData() async {
    debugPrint('📥 Fetching heatmap data for type: $selectedType');
    try {
      final supabase = Supabase.instance.client;
      String wifiName = '';
      if (selectedType == HeatmapType.iiumStudent) wifiName = '"IIUM-Student"';
      else if (selectedType == HeatmapType.iiumWifi) wifiName = '"IIUM-WiFi"';
      else wifiName = selectedType.name[0].toUpperCase() + selectedType.name.substring(1);

      debugPrint('🔍 Querying heatmap_points with wifi_name = $wifiName');
      final response = await supabase.from('heatmap_points').select().eq('wifi_name', wifiName);

      final Map<String, Map<String, dynamic>> latestPerPoint = {};
      for (var record in response) {
        final lat = record['lat'] as double?;
        final lng = record['lng'] as double?;
        final download = record['download'] as double?;
        final createdStr = record['created_at'] as String?;

        if (lat == null || lng == null || download == null || createdStr == null) continue;
        final created = DateTime.tryParse(createdStr);
        if (created == null) continue;

        final key = '$lat,$lng';
        if (latestPerPoint[key] == null || created.isAfter(latestPerPoint[key]!['created'])) {
          latestPerPoint[key] = {'lat': lat, 'lng': lng, 'download': download, 'created': created};
        }
      }

      bluePoints.clear(); yellowPoints.clear(); orangePoints.clear(); redPoints.clear(); purplePoints.clear();

      int totalPoints = 0;
      for (var point in latestPerPoint.values) {
        final weighted = WeightedLatLng(LatLng(point['lat'], point['lng']), 1.0);
        double d = point['download'];
        if (d <= 5) bluePoints.add(weighted);
        else if (d <= 15) yellowPoints.add(weighted);
        else if (d <= 50) orangePoints.add(weighted);
        else if (d <= 100) redPoints.add(weighted);
        else purplePoints.add(weighted);
        totalPoints++;
      }

      debugPrint('📊 Heatmap data processed: $totalPoints points grouped by speed');

      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      debugPrint('❌ Error in fetchHeatmapData: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🧱 Building UI...');
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Pulse Heatmap', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: [
          DropdownButton<HeatmapType>(
            value: selectedType,
            underline: const SizedBox(),
            dropdownColor: Colors.grey[900],
            items: HeatmapType.values.map((type) {
              return DropdownMenuItem(value: type, child: Text(type.name, style: const TextStyle(color: Colors.white)));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                debugPrint('🎛️ Heatmap type changed to: ${value.name}');
                setState(() { selectedType = value; isLoading = true; });
                fetchHeatmapData();
                fetchAIInsight();
              }
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _initialize),
        ],
      ),
      body: isLoading || initialCenter == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(initialCenter: initialCenter!, initialZoom: 17),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.wifipulse'),
                          if (userLocation != null)
                            MarkerLayer(markers: [
                              Marker(point: userLocation!, width: 50, height: 50, child: const Icon(Icons.my_location, color: Colors.blue, size: 22)),
                            ]),
                          _buildHeatLayer(bluePoints, Colors.blue),
                          _buildHeatLayer(yellowPoints, Colors.yellow),
                          _buildHeatLayer(orangePoints, Colors.orange),
                          _buildHeatLayer(redPoints, Colors.red),
                          _buildHeatLayer(purplePoints, Colors.purple),
                        ],
                      ),
                      // 🔹 AI Insight Overlay
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: PulseInsightCard(insight: aiInsight, isLoading: isAiLoading),
                      ),
                      if (userLocation != null)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: Colors.white,
                            onPressed: () => mapController.move(userLocation!, 17),
                            child: const Icon(Icons.my_location, color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendBox(color: Colors.blue, label: "≤ 5 mbps"),
                    _buildLegendBox(color: Colors.yellow, label: "≤ 15 mbps"),
                    _buildLegendBox(color: Colors.orange, label: "≤ 50 mbps"),
                    _buildLegendBox(color: Colors.red, label: "≤ 100 mbps"),
                    _buildLegendBox(color: Colors.purple, label: "> 100 mbps"),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
    );
  }

  Widget _buildHeatLayer(List<WeightedLatLng> points, Color color) {
    if (points.isEmpty) {
      debugPrint('🟥 Heatmap layer skipped (no points) for color: $color');
      return const SizedBox.shrink();
    }
    debugPrint('🟢 Rendering heatmap layer with ${points.length} points in color: $color');
    return HeatMapLayer(
      heatMapDataSource: InMemoryHeatMapDataSource(data: points),
      heatMapOptions: HeatMapOptions(
        radius: 12.0,
        layerOpacity: 0.5,
        gradient: {1.0: MaterialColor(color.value, {500: color, 900: color})},
      ),
    );
  }

  Widget _buildLegendBox({required Color color, required String label}) {
    return Column(
      children: [
        Container(width: 18, height: 18, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}