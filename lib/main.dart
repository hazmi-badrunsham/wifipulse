import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_network_speed_test/flutter_network_speed_test.dart';

import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox('history');

  await Supabase.initialize(
    url: 'https://dnuuypmnlkxmodlajtao.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudXV5cG1ubGt4bW9kbGFqdGFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2ODYxNDgsImV4cCI6MjA2NzI2MjE0OH0.YA5eSrICFBNu8gMBuow5uuh1uwE545FLyrPEK1lW35c',
  );

  runApp(
    SpeedTestProvider(
      args: const SpeedTestArgs(duration: Duration(seconds: 10)),
      child: const WiFiPulseApp(),
    ),
  );
}

const darkBackgroundColor = Color(0xFF1E1E1E);

class WiFiPulseApp extends StatelessWidget {
  const WiFiPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: darkBackgroundColor,
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'GreycliffCF'),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF266991),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            textStyle: const TextStyle(
              fontFamily: 'GreycliffCF',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}
