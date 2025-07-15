// lib/services/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://dnuuypmnlkxmodlajtao.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudXV5cG1ubGt4bW9kbGFqdGFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2ODYxNDgsImV4cCI6MjA2NzI2MjE0OH0.YA5eSrICFBNu8gMBuow5uuh1uwE545FLyrPEK1lW35c',
  );
}

final supabase = Supabase.instance.client;
