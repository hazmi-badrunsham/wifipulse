import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


/// This function shows the report popup, collects data and submits to Supabase.
Future<void> showReportDialog({
  required BuildContext context,
  required String wifiName,
  required double downloadSpeed,
  required double uploadSpeed,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString('username') ?? 'Anonymous';
  final userId = Supabase.instance.client.auth.currentUser?.id;

  final List<String> reasons = [
    'Inaccurate speed result',
    'Wrong WiFi location',
    'Inappropriate content on map',
  ];
  List<bool> selected = [false, false, false];
  String additionalText = '';

  bool loading = false;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Report Issue'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(reasons.length, (index) {
                return CheckboxListTile(
                  value: selected[index],
                  onChanged: (value) => setState(() => selected[index] = value ?? false),
                  title: Text(reasons[index]),
                );
              }),
              const SizedBox(height: 8),
              TextField(
                onChanged: (value) => additionalText = value,
                decoration: const InputDecoration(
                  hintText: "Additional comments (optional)",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: loading ? const CircularProgressIndicator() : const Text('Submit'),
              onPressed: () async {
                setState(() => loading = true);

                // Get location
                final position = await Geolocator.getCurrentPosition();
                final lat = position.latitude;
                final lng = position.longitude;

                // Get address using OpenStreetMap Nominatim API
                String locationText = await _reverseGeocode(lat, lng);

                // Compile report text
                final selectedReasons = [
                  for (int i = 0; i < reasons.length; i++)
                    if (selected[i]) reasons[i]
                ];

                final fullReport = {
                  'username': username,
                  'user_id': userId,
                  'wifi_name': wifiName,
                  'download': downloadSpeed,
                  'upload': uploadSpeed,
                  'lat': lat,
                  'lng': lng,
                  'location': locationText,
                  'report_reasons': selectedReasons.join(", "),
                  'additional': additionalText,
                  'created_at': DateTime.now().toIso8601String(),
                };

                try {
                  await Supabase.instance.client.from('wifi_reports').insert(fullReport);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Report submitted")),
                  );
                } catch (e) {
                  debugPrint("Error submitting report: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("❌ Failed to submit report")),
                  );
                  setState(() => loading = false);
                }
              },
            ),
          ],
        );
      });
    },
  );
}

/// Reverse geocode using OpenStreetMap Nominatim API
Future<String> _reverseGeocode(double lat, double lng) async {
  final url = Uri.parse(
    'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng',
  );

  final headers = {
    'User-Agent': 'WiFiPulseApp/1.0',
  };

  try {
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['display_name'] ?? 'Unknown location';
    }
  } catch (e) {
    debugPrint('Reverse geocode failed: $e');
  }

  return 'Unknown location';
}
