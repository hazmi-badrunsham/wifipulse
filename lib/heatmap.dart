import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    fetchUserLocation();
    fetchHeatmapData();
  }

  Future<void> fetchUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();

      if (!mounted) return;
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
        initialCenter ??= userLocation;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> fetchHeatmapData() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('heatmap_points')
          .select()
          .eq('wifi_name', 'Umi Wi-Fi 4');

      final data = response as List<dynamic>;

      final Map<String, Map<String, dynamic>> latestPerPoint = {};

      for (var record in data) {
        try {
          final lat = record['lat']?.toDouble();
          final lng = record['lng']?.toDouble();
          final download = record['download']?.toDouble();
          final createdStr = record['created_at'] as String?;
          final created = DateTime.tryParse(createdStr ?? '');

          if (lat == null || lng == null || download == null || created == null) continue;

          final key = '$lat,$lng';
          final existing = latestPerPoint[key];
          final existingCreated = existing != null ? existing['created'] as DateTime : null;

          if (existingCreated == null || created.isAfter(existingCreated)) {
            latestPerPoint[key] = {
              'lat': lat,
              'lng': lng,
              'download': download,
              'created': created,
            };
          }
        } catch (_) {
          debugPrint("Skipping invalid heatmap record.");
        }
      }

      bluePoints.clear();
      yellowPoints.clear();
      orangePoints.clear();
      redPoints.clear();
      purplePoints.clear();

      for (var point in latestPerPoint.values) {
        final latLng = LatLng(point['lat'], point['lng']);
        final download = point['download'] as double;

        final weighted = WeightedLatLng(latLng, 1.0);
        if (download <= 5) {
          bluePoints.add(weighted);
        } else if (download <= 15) {
          yellowPoints.add(weighted);
        } else if (download <= 50) {
          orangePoints.add(weighted);
        } else if (download <= 100) {
          redPoints.add(weighted);
        } else {
          purplePoints.add(weighted);
        }
      }

      if (!mounted) return;
      setState(() {
        isLoading = false;
        if (initialCenter == null &&
            (bluePoints + yellowPoints + orangePoints + redPoints + purplePoints).isNotEmpty) {
          initialCenter = (bluePoints + yellowPoints + orangePoints + redPoints + purplePoints).first.latLng;
        }
      });
    } catch (e) {
      debugPrint('Failed to fetch heatmap data: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load heatmap data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'IIUM Student WiFi Heatmap',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              fetchUserLocation();
              fetchHeatmapData();
            },
          ),
        ],
      ),
      body: isLoading || initialCenter == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: initialCenter!,
                      initialZoom: 17,
                      minZoom: 10,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                      ),
                      if (userLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: userLocation!,
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      if (bluePoints.isNotEmpty) _buildHeatLayer(bluePoints, Colors.blue),
                      if (yellowPoints.isNotEmpty) _buildHeatLayer(yellowPoints, Colors.yellow),
                      if (orangePoints.isNotEmpty) _buildHeatLayer(orangePoints, Colors.orange),
                      if (redPoints.isNotEmpty) _buildHeatLayer(redPoints, Colors.red),
                      if (purplePoints.isNotEmpty) _buildHeatLayer(purplePoints, Colors.purple),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendBox(color: Colors.blue, label: "<= 5 Mbps"),
                      _buildLegendBox(color: Colors.yellow, label: "<= 15 Mbps"),
                      _buildLegendBox(color: Colors.orange, label: "<= 50 Mbps"),
                      _buildLegendBox(color: Colors.red, label: "<= 100 Mbps"),
                      _buildLegendBox(color: Colors.purple, label: "> 100 Mbps"),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
    );
  }

  Widget _buildHeatLayer(List<WeightedLatLng> points, Color color) {
    return HeatMapLayer(
      heatMapDataSource: InMemoryHeatMapDataSource(data: points),
      heatMapOptions: HeatMapOptions(
        radius: 12.0,
        layerOpacity: 0.5,
        gradient: <double, MaterialColor>{1.0: color as MaterialColor},
      ),
    );
  }

  Widget _buildLegendBox({required Color color, required String label}) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
