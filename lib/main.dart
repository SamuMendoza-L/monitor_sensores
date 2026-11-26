import 'package:flutter/material.dart';
import 'package:monitor_sensores/screens/login_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
