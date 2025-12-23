import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final MapController mapController = MapController();

  HeatmapType selectedType = HeatmapType.iiumStudent;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await fetchUserLocation();
    await fetchHeatmapData();
  }

  Future<void> fetchUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever || 
            permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permissions are denied.');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
          initialCenter = userLocation;
        });
        debugPrint('📍 User location: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching user location: $e');
    }
  }

  Future<void> fetchHeatmapData() async {
    try {
      final supabase = Supabase.instance.client;
      late final List<dynamic> response;
      String wifiName = '';

      if (selectedType == HeatmapType.iiumStudent) {
        wifiName = 'Umi Wi-Fi 4';
      } else if (selectedType == HeatmapType.iiumWifi) {
        wifiName = '"IIUM-WiFi"';
      } else if (selectedType == HeatmapType.maxis) {
        wifiName = 'Maxis';
      } else if (selectedType == HeatmapType.celcom) {
        wifiName = 'Celcom';
      } else if (selectedType == HeatmapType.umobile) {
        wifiName = 'Umobile';
      } else if (selectedType == HeatmapType.unifi) {
        wifiName = 'Unifi';
      } else if (selectedType == HeatmapType.digi) {
        wifiName = 'Digi';
      } else {
        response = [];
      }

      debugPrint('🌐 Fetching heatmap data for Wi-Fi: $wifiName');

      response = await supabase
          .from('heatmap_points')
          .select()
          .eq('wifi_name', wifiName);

      debugPrint('✅ Fetched ${response.length} records from Supabase');

      if (response.isEmpty) {
        debugPrint('⚠️ No data found for Wi-Fi: $wifiName');
      }

      // Process latest per coordinate
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
        } catch (e) {
          debugPrint("⚠️ Skipping invalid heatmap record: $e");
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
      debugPrint('❌ Failed to fetch heatmap data: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load heatmap data')),
        );
      }
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
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: Colors.grey[800],
            items: const [
              DropdownMenuItem(
                value: HeatmapType.iiumStudent,
                child: Text("IIUM-Student", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: HeatmapType.iiumWifi,
                child: Text("IIUM-WiFi", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: HeatmapType.maxis,
                child: Text("Maxis", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: HeatmapType.celcom,
                child: Text("Celcom", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: HeatmapType.umobile,
                child: Text("Umobile", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: HeatmapType.unifi,
                child: Text("Unifi", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: HeatmapType.digi,
                child: Text("Digi", style: TextStyle(color: Colors.white)),
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
              _initialize();
            },
          ),
          
        ],
      ),
      body: isLoading || initialCenter == null
    ? const Center(child: CircularProgressIndicator())
    : Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // 🔹 The map
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: initialCenter!,
                    initialZoom: 17,
                    minZoom: 10,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.wifipulse',
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
                              color: Colors.blue,
                              size: 20,
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
                // 🔹 FAB: Bottom-right on the map
                if (userLocation != null)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      elevation: 4,
                      onPressed: () {
                        mapController.move(userLocation!, 17);
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendBox(color: Colors.blue, label: "≤ 5 Mbps"),
                _buildLegendBox(color: Colors.yellow, label: "≤ 15 Mbps"),
                _buildLegendBox(color: Colors.orange, label: "≤ 50 Mbps"),
                _buildLegendBox(color: Colors.red, label: "≤ 100 Mbps"),
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
    final MaterialColor materialColor = MaterialColor(
      color.value,
      <int, Color>{
        50: color.withValues(alpha: 0.1),
        100: color.withValues(alpha: 0.2),
        200: color.withValues(alpha: 0.3),
        300: color.withValues(alpha: 0.4),
        400: color.withValues(alpha: 0.5),
        500: color.withValues(alpha: 0.6),
        600: color.withValues(alpha: 0.7),
        700: color.withValues(alpha: 0.8),
        800: color.withValues(alpha: 0.9),
        900: color,
      },
    );

    return HeatMapLayer(
      heatMapDataSource: InMemoryHeatMapDataSource(data: points),
      heatMapOptions: HeatMapOptions(
        radius: 12.0,
        layerOpacity: 0.5,
        gradient: <double, MaterialColor>{
          1.0: materialColor,
        },
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
