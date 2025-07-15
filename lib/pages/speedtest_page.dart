import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_network_speed_test/flutter_network_speed_test.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});
  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  String wifiName = "Unknown";
  String wifiBSSID = "Unknown";
  String wifiIP = "Unknown";
  String selectedTelco = '';
  bool isWifiConnected = true;
  bool isTesting = false;
  bool showUploadGauge = false;

  double downloadSpeed = 0.0;
  double uploadSpeed = 0.0;
  double gaugeValue = 0.0;

  String displayName = 'Your';
  int userXP = 0;
  int userLevel = 1;
  double progressPercent = 0.0;

  final List<String> telcoProviders = ['Maxis', 'Celcom', 'UMobile', 'Yes', 'Unifi', 'Digi', 'ONEXOX'];

  Future<void> loadUserXP() async {
    final prefs = await SharedPreferences.getInstance();
    userXP = prefs.getInt('xp') ?? 0;
    displayName = prefs.getString('username') ?? 'Your';
    userLevel = (userXP ~/ 3) + 1;
    progressPercent = (userXP % 3) / 3;
    setState(() {});
  }

  Future<void> incrementXP() async {
    final prefs = await SharedPreferences.getInstance();
    userXP += 1;
    await prefs.setInt('xp', userXP);
    userLevel = (userXP ~/ 3) + 1;
    progressPercent = (userXP % 3) / 3;
    setState(() {});
  }

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
      if (mounted) {
        setState(() {
          showUploadGauge = true;
          gaugeValue = uploadSpeed;
        });
      }
    });

    final wifiLabel = isWifiConnected ? wifiName : selectedTelco;
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'Anonymous';
    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      await Supabase.instance.client.from('heatmap_points').insert({
        'lat': position.latitude,
        'lng': position.longitude,
        'download': downloadSpeed,
        'upload': uploadSpeed,
        'wifi_name': wifiLabel,
        'user_id': userId,
        'username': username,
      });

      await box.add({
        'lat': position.latitude,
        'lng': position.longitude,
        'download': downloadSpeed,
        'upload': uploadSpeed,
        'wifi_name': wifiLabel,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await incrementXP();

      try {
        await Supabase.instance.client.from('user_profiles').upsert({
          'id': userId,
          'username': username,
          'level': userLevel,
        }, onConflict: 'id');
      } catch (e) {
        debugPrint('⚠️ Failed to update user level: $e');
      }

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
    loadUserXP();
    _checkAndShowPopup();
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
                title: const Text('Welcome to WiFiPulse'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("WiFi Pulse", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                  if (!isTesting && (downloadSpeed > 0 || uploadSpeed > 0)) ...[
                    Text('Download: ${downloadSpeed.toStringAsFixed(2)} Mbps'),
                    Text('Upload: ${uploadSpeed.toStringAsFixed(2)} Mbps'),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                      child: const Text('Scan WiFi Info'),
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
          const SizedBox(height: 10),
          Card(
            color: const Color.fromARGB(255, 48, 48, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "$displayName's WiFiPulse Level",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.white70),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Contribution Info",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              content: const Text(
                                "Every time you perform a speed test and upload the result, "
                                "you earn XP.\n\n- 1 speed test = 1 XP\n- Every 3 XP = 1 Level\n\n"
                                "Help others by contributing more tests to improve heatmap accuracy!",
                                style: TextStyle(fontSize: 18),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("Level: $userLevel", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: Colors.grey[700],
                    color: Colors.lightBlueAccent,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 6),
                  Text("XP: $userXP / ${userLevel * 3}",
                      style: const TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
