import 'package:flutter/material.dart';
import '../../utils/theme.dart'; // For darkBackgroundColor
import '../pages/speedtest_page.dart';
import '../pages/history.dart';
import '../pages/heatmap.dart';
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1;

  final List<Widget> _pages = [
    const HistoryPage(),
    const SpeedTestPage(),
    const IIUMStudentHeatmapPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color.fromARGB(255, 64, 196, 255),
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
