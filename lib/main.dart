import 'package:flutter/material.dart';
import 'package:monitor_sensores/screens/login_screen.dart';
import 'package:monitor_sensores/theme/app_theme.dart';

void main() {
  runApp(const MonitorSensoresApp());
}

class MonitorSensoresApp extends StatelessWidget {
  const MonitorSensoresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitor IoT Hogar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
