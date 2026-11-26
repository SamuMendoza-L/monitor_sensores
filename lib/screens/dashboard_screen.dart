import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:monitor_sensores/screens/login_screen.dart';
import 'package:monitor_sensores/theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  final String nombreUsuario;

  const DashboardScreen({super.key, required this.nombreUsuario});

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

  void _cerrarSesion() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hayPeligro = alertaAgua || alertaGas;

    return Scaffold(
      backgroundColor:
          hayPeligro ? AppColors.dangerLight : AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor:
            hayPeligro ? AppColors.danger : AppColors.primaryDark,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    widget.nombreUsuario,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Indicador de conexión como chip
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: conectado
                  ? AppColors.accent.withValues(alpha: 0.2)
                  : AppColors.warning.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  conectado ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: conectado ? AppColors.light : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  conectado ? 'En línea' : 'Sin señal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: conectado ? AppColors.light : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBannerEstado(hayPeligro),
            const SizedBox(height: 20),
            // Título de sección
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Sensores activos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _buildSensorCard(
              titulo: 'Sensor de Agua / Fugas',
              subtitulo: 'Lectura analógica: $aguaValor / 4095',
              estadoTexto: alertaAgua ? '¡FUGA DETECTADA!' : 'Sin humedad',
              enAlerta: alertaAgua,
              icono: Icons.water_drop,
            ),
            const SizedBox(height: 14),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buscando conexión…',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Verifica que el celular esté en el mismo Wi-Fi del ESP32-C3.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hayPeligro
              ? [AppColors.danger, AppColors.danger.withValues(alpha: 0.85)]
              : [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hayPeligro ? AppColors.danger : AppColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hayPeligro
                  ? Icons.warning_amber_rounded
                  : Icons.verified_user_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              hayPeligro
                  ? '¡ALERTA CRÍTICA ACTIVA!\nRevisa los sensores.'
                  : 'Sistema en línea\nTodo en orden ✓',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: enAlerta ? AppColors.dangerLight : AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: enAlerta
            ? Border.all(color: AppColors.danger.withValues(alpha: 0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: (enAlerta ? AppColors.danger : Colors.black)
                .withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: enAlerta
                    ? AppColors.danger.withValues(alpha: 0.12)
                    : AppColors.surfaceLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icono,
                size: 28,
                color: enAlerta ? AppColors.danger : AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: enAlerta
                          ? AppColors.danger.withValues(alpha: 0.12)
                          : AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      estadoTexto,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: enAlerta ? AppColors.danger : AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
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
