import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart'; // استدعاء شاشة العرض

void main() => runApp(const HotelAutomationApp());

class HotelAutomationApp extends StatelessWidget {
  const HotelAutomationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maestro Automation',
      theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.cyanAccent
      ),
      home: const DashboardScreen(),
    );
  }
}