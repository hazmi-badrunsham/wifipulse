import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_network_speed_test/flutter_network_speed_test.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';


import 'heatmap.dart';
import 'history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive initialization
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox('history');

  // Supabase initialization
  await Supabase.initialize(
    url: 'https://dnuuypmnlkxmodlajtao.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudXV5cG1ubGt4bW9kbGFqdGFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2ODYxNDgsImV4cCI6MjA2NzI2MjE0OH0.YA5eSrICFBNu8gMBuow5uuh1uwE545FLyrPEK1lW35c',
  );

  runApp(const WiFiPulseApp());
}

const darkBackgroundColor = Color(0xFF1E1E1E);

class WiFiPulseApp extends StatelessWidget {
  const WiFiPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SpeedTestProvider(
      args: const SpeedTestArgs(duration: Duration(seconds: 10)),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: darkBackgroundColor,
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'GreycliffCF'),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF266991),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              textStyle: const TextStyle(fontFamily: 'GreycliffCF', fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        home: const MainNavigation(),
      ),
    );
  }
}

// ------------------ Navigation Wrapper ------------------

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1;

  final List<Widget> _pages = [
    const HistoryPage(),
    const MainScreen(),
    const IIUMStudentHeatmapPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.lightBlueAccent,
        unselectedItemColor: Colors.white54,
        backgroundColor: darkBackgroundColor,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Speed Test'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Heatmap'),
        ],
      ),
    );
  }
}

// ------------------ Speed Test Page ------------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String wifiName = "Unknown";
  String wifiBSSID = "Unknown";
  String wifiIP = "Unknown";
  String selectedTelco = '';
  bool isWifiConnected = true;
  bool isTesting = false;
  bool showUploadGauge = false;
  bool isInitializing = true;

  double downloadSpeed = 0.0;
  double uploadSpeed = 0.0;
  double gaugeValue = 0.0;

  final List<String> telcoProviders = ['Maxis', 'Celcom', 'UMobile', 'Yes', 'Unifi', 'Digi', 'ONEXOX'];

  Future<void> scanWifiInfo() async {
    final info = NetworkInfo();
    final ssid = await info.getWifiName();
    final bssid = await info.getWifiBSSID();
    final ip = await info.getWifiIP();

    setState(() {
      wifiName = ssid ?? 'Unavailable';
      wifiBSSID = bssid ?? 'Unavailable';
      wifiIP = ip ?? 'Unavailable';
      isWifiConnected = (ssid != null && ssid != '<unknown ssid>' && ssid.isNotEmpty);
      if (isWifiConnected) selectedTelco = '';
    });
  }

  Future<void> startSpeedTest(BuildContext context) async {
    final speedTest = SpeedTestProvider.of(context);
    final box = Hive.box('history');
    final position = await Geolocator.getCurrentPosition();

    setState(() {
      isTesting = true;
      downloadSpeed = 0.0;
      uploadSpeed = 0.0;
      gaugeValue = 0.0;
      showUploadGauge = false;
    });

    await speedTest.startTest();

    setState(() {
      isTesting = false;
      downloadSpeed = speedTest.results[SpeedTestType.download] ?? 0.0;
      uploadSpeed = speedTest.results[SpeedTestType.upload] ?? 0.0;
      gaugeValue = downloadSpeed;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        showUploadGauge = true;
        gaugeValue = uploadSpeed;
      });
    });

    final wifiLabel = isWifiConnected ? wifiName : selectedTelco;

    try {
      // Upload to Supabase
      await Supabase.instance.client.from('heatmap_points').insert({
        'lat': position.latitude,
        'lng': position.longitude,
        'download': downloadSpeed,
        'upload': uploadSpeed,
        'wifi_name': wifiLabel,
      });

      // Save to Hive
      await box.add({
        'lat': position.latitude,
        'lng': position.longitude,
        'download': downloadSpeed,
        'upload': uploadSpeed,
        'wifi_name': wifiLabel,
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Speed test saved and uploaded')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to upload: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      setState(() => isInitializing = false);
      await _checkAndShowPopup();
    });
  }

  Future<void> _checkAndShowPopup() async {
    final prefs = await SharedPreferences.getInstance();
    final dontShowAgain = prefs.getBool('dontShowPopup') ?? false;

    if (!dontShowAgain && mounted) {
      showDialog(
        context: context,
        builder: (context) {
          bool dontShow = false;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Welcome to WiFi Pulse'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Please scan WiFi info before starting the speed test to ensure accurate results',
                      style: TextStyle(fontSize: 16),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: dontShow,
                          onChanged: (value) {
                            setState(() => dontShow = value ?? false);
                          },
                        ),
                        const Text("Don't show again"),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      if (dontShow) {
                        await prefs.setBool('dontShowPopup', true);
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final speedTest = SpeedTestProvider.of(context);

    if (isInitializing) {
      return const Scaffold(
        backgroundColor: darkBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("WiFi Pulse")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Speed Test", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Card(
            color: Colors.grey[850],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(showUploadGauge ? 'Upload Speed' : 'Download Speed', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 250,
                    width: 250,
                    child: SfRadialGauge(
                      axes: [
                        RadialAxis(
                          minimum: 0,
                          maximum: 120,
                          pointers: [
                            NeedlePointer(value: gaugeValue, enableAnimation: true),
                          ],
                          annotations: [
                            GaugeAnnotation(
                              widget: Text('${gaugeValue.toStringAsFixed(1)} Mbps',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              angle: 90,
                              positionFactor: 0.8,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isTesting ? null : () => startSpeedTest(context),
                    child: Text(isTesting ? 'Testing...' : 'Start Speed Test'),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<ProgressData>(
                    stream: speedTest.progressStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.type != SpeedTestType.ping) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() => gaugeValue = snapshot.data!.speed);
                        });
                        return Text(
                          '${snapshot.data!.type.name.toUpperCase()}: ${snapshot.data!.speed.toStringAsFixed(2)} Mbps',
                          style: const TextStyle(fontSize: 16),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color.fromARGB(255, 48, 48, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ElevatedButton(
                      onPressed: scanWifiInfo,
                      child: const Text('Show WiFi Info'),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text("WiFi Name (SSID): $wifiName", style: const TextStyle(fontSize: 15)),
                  Text("BSSID: $wifiBSSID", style: const TextStyle(fontSize: 15)),
                  Text("IP Address: $wifiIP", style: const TextStyle(fontSize: 15)),
                  if (!isWifiConnected) ...[
                    const SizedBox(height: 10),
                    const Text("Select your mobile network provider:"),
                    DropdownButton<String>(
                      value: selectedTelco.isEmpty ? null : selectedTelco,
                      hint: const Text("Choose Telco"),
                      dropdownColor: Colors.grey[900],
                      items: telcoProviders.map((telco) {
                        return DropdownMenuItem(value: telco, child: Text(telco));
                      }).toList(),
                      onChanged: (value) => setState(() => selectedTelco = value ?? ''),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
