// lib/utils/theme.dart
import 'package:flutter/material.dart';

const darkBackgroundColor = Color(0xFF1E1E1E);

final appTheme = ThemeData.dark().copyWith(
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
);

ButtonStyle reportButtonStyle = ElevatedButton.styleFrom(
  minimumSize: const Size(100, 30),
  backgroundColor: Colors.redAccent,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(horizontal: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
  ),
  textStyle: const TextStyle(
    fontFamily: 'GreycliffCF',
    fontSize: 14,
    fontWeight: FontWeight.bold,
  ),
);