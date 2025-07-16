import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum HeatmapType { iiumStudent, maxis, celcom, umobile, unifi, digi }

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

  HeatmapType selectedType = HeatmapType.iiumStudent;

  @override
  void initState() {
    super.initState();
    fetchUserLocation();
    fetchHeatmapData();
  }

  Future<void> fetchUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
    setState(() {
    userLocation = LatLng(position.latitude, position.longitude);
    initialCenter ??= userLocation;
  });
}
  }

  Future<void> fetchHeatmapData() async {
    try {
      final supabase = Supabase.instance.client;

      late final List<dynamic> response;

      if (selectedType == HeatmapType.iiumStudent) {
        response = await supabase
            .from('heatmap_points')
            .select()
            .eq('wifi_name', '"Umi Wi-Fi 4"');
            print("Fetched ${response.length} heatmap records for ${selectedType.name}");
            
      } if (selectedType == HeatmapType.maxis) {
        response = await supabase
            .from('heatmap_points')
            .select()
            .eq('wifi_name', 'Maxis');
    
      } if (selectedType == HeatmapType.celcom) {
        response = await supabase
            .from('heatmap_points')
            .select()
            .eq('wifi_name', 'Celcom');
    
      } if (selectedType == HeatmapType.umobile) {
        response = await supabase
            .from('heatmap_points')
            .select()
            .eq('wifi_name', 'Umobile');
    
      } if (selectedType == HeatmapType.unifi) {
        response = await supabase
            .from('heatmap_points')
            .select()
            .eq('wifi_name', 'Unifi');
    
      } if (selectedType == HeatmapType.digi) {
        response = await supabase
            .from('heatmap_points')
            .select()
            .eq('wifi_name', 'Digi');
    
      }

      final Map<String, Map<String, dynamic>> latestPerPoint = {};

      for (var record in response) {
        try {
          final lat = record['lat'] as double?;
          final lng = record['lng'] as double?;
          final download = record['download'] as double?;
          final createdStr = record['created_at'] as String?;
          if (lat == null || lng == null || download == null || createdStr == null) continue;
          final created = DateTime.tryParse(createdStr);
          if (created == null) continue;

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

      if (mounted) {
      setState(() {
        isLoading = false;
        if (initialCenter == null &&
            (bluePoints + yellowPoints + orangePoints + redPoints + purplePoints).isNotEmpty) {
          initialCenter = (bluePoints + yellowPoints + orangePoints + redPoints + purplePoints).first.latLng;
        }
      });
      }
    } catch (e) {
      debugPrint('Failed to fetch heatmap data: $e');
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
          'WiFi Pulse Heatmap',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          DropdownButton<HeatmapType>(
            value: selectedType,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Color.fromARGB(255, 255, 255, 255)),
            items: const [
              DropdownMenuItem(
                value: HeatmapType.iiumStudent,
                child: Text("IIUM WiFi", style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              ),
              DropdownMenuItem(
                value: HeatmapType.maxis,
                child: Text("Maxis", style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              ),
              DropdownMenuItem(
                value: HeatmapType.celcom,
                child: Text("Celcom", style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              ),
              DropdownMenuItem(
                value: HeatmapType.umobile,
                child: Text("Umobile", style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              ),
              DropdownMenuItem(
                value: HeatmapType.unifi,
                child: Text("Unifi", style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              ),
              DropdownMenuItem(
                value: HeatmapType.digi,
                child: Text("Digi", style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedType = value;
                  isLoading = true;
                });
                fetchHeatmapData();
              }
            },
          ),
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
                        userAgentPackageName: 'com.example.wifipulse', // ✅ Use your actual package name
                        additionalOptions: const {
                            'User-Agent': 'WiFiPulse/1.0 (https://github.com/hazmi-badrunsham)', // ✅ Must include a real URL
                      },
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
                                color: Color.fromARGB(183, 244, 67, 54),
                                size: 15,
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
}
