import 'package:flutter/material.dart';
import 'package:flutter_network_speed_test/flutter_network_speed_test.dart';

import 'pages/login_page.dart';
import 'services/hive_config.dart';
import 'services/supabase_client.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  await initSupabase();

  runApp(
    SpeedTestProvider(
      args: const SpeedTestArgs(duration: Duration(seconds: 10)),
      child: const WiFiPulseApp(),
    ),
  );
}

class WiFiPulseApp extends StatelessWidget {
  const WiFiPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const LoginPage(),
    );
  }
}
