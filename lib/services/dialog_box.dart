import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showWelcomePopupIfNeeded(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final dontShowAgain = prefs.getBool('dontShowPopup') ?? false;

  if (dontShowAgain || !context.mounted) return;

  bool dontShow = false;

  await showDialog(
    context: context,
    builder: (context) {
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
                        setState(() {
                          dontShow = value ?? false;
                        });
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
