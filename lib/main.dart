import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Cambia esta IP por la que te mostró el Monitor Serie del ESP32
  final String esp32Url = 'http://192.168.4.1/api/sensores';

  int aguaValor = 4095;
  bool alertaAgua = false;
  bool alertaGas = false;
  bool conectado = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _consultarSensores();
    // Consulta el ESP32 cada 2 segundos
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _consultarSensores();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _consultarSensores() async {
    try {
      final response = await http
          .get(Uri.parse(esp32Url))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          aguaValor = data['agua_valor'] ?? 4095;
          alertaAgua = data['alerta_agua'] ?? false;
          alertaGas = data['alerta_gas'] ?? false;
          conectado = true;
        });
      }
    } catch (_) {
      setState(() {
        conectado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hayPeligro = alertaAgua || alertaGas;

    return Scaffold(
      backgroundColor: hayPeligro ? Colors.red.shade50 : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Monitor de Seguridad IoT'),
        backgroundColor: hayPeligro ? Colors.red.shade700 : Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              conectado ? Icons.wifi : Icons.wifi_off,
              color: conectado ? Colors.lightGreenAccent : Colors.amber,
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBannerEstado(hayPeligro),
            const SizedBox(height: 24),
            _buildSensorCard(
              titulo: 'Sensor de Agua / Fugas',
              subtitulo: 'Lectura analógica: $aguaValor / 4095',
              estadoTexto: alertaAgua ? '¡FUGA DETECTADA!' : 'Sin humedad',
              enAlerta: alertaAgua,
              icono: Icons.water_drop,
            ),
            const SizedBox(height: 16),
            _buildSensorCard(
              titulo: 'Sensor de Gas (FC-22)',
              subtitulo: 'Detección digital por umbral',
              estadoTexto: alertaGas ? '¡GAS DETECTADO!' : 'Ambiente seguro',
              enAlerta: alertaGas,
              icono: Icons.air,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerEstado(bool hayPeligro) {
    if (!conectado) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade700),
        ),
        child: const Text(
          'Buscando conexión con el ESP32-C3...\nVerifica que el celular esté en el mismo Wi-Fi.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hayPeligro ? Colors.red.shade600 : Colors.teal.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hayPeligro
            ? '⚠️ ¡ALERTA CRÍTICA ACTIVA! Revisa los sensores.'
            : '✅ Sistema en línea — Todo en orden',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required String titulo,
    required String subtitulo,
    required String estadoTexto,
    required bool enAlerta,
    required IconData icono,
  }) {
    return Card(
      elevation: 3,
      color: enAlerta ? Colors.red.shade100 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: enAlerta ? Colors.red : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  enAlerta ? Colors.red.shade700 : Colors.teal.shade100,
              child: Icon(
                icono,
                size: 30,
                color: enAlerta ? Colors.white : Colors.teal.shade800,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    estadoTexto,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: enAlerta ? Colors.red.shade900 : Colors.teal.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}