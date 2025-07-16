import 'package:shared_preferences/shared_preferences.dart';

  String displayName = 'Your';
  int userXP = 0;
  int userLevel = 1;
  double progressPercent = 0.0;

  
Future<void> loadUserXP() async {
    final prefs = await SharedPreferences.getInstance();
    userXP = prefs.getInt('xp') ?? 0;
    displayName = prefs.getString('username') ?? 'Your';
    userLevel = (userXP ~/ 3) + 1;
    progressPercent = (userXP % 3) / 3;

  }

  Future<void> incrementXP() async {
    final prefs = await SharedPreferences.getInstance();
    userXP += 1;
    await prefs.setInt('xp', userXP);
    userLevel = (userXP ~/ 3) + 1;
    progressPercent = (userXP % 3) / 3;

  }

  