import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:monitor_sensores/screens/dashboard_screen.dart';
import 'package:monitor_sensores/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _pinController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _ocultarPin = true;
  int _intentosFallidos = 0;
  bool _bloqueado = false;
  int _segundosRestantes = 0;
  Timer? _timerBloqueo;

  // Credenciales genéricas temporales
  final Map<String, String> _credenciales = {
    'admin': '1234',
    'samuel': '2026',
  };

  @override
  void dispose() {
    _usuarioController.dispose();
    _pinController.dispose();
    _timerBloqueo?.cancel();
    super.dispose();
  }

  void _iniciarBloqueo() {
    setState(() {
      _bloqueado = true;
      _segundosRestantes = 30;
    });
    _timerBloqueo = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _segundosRestantes--;
      });
      if (_segundosRestantes <= 0) {
        timer.cancel();
        setState(() {
          _bloqueado = false;
          _intentosFallidos = 0;
        });
      }
    });
  }

  void _intentarLogin() {
    if (!_formKey.currentState!.validate()) return;

    final usuario = _usuarioController.text.trim().toLowerCase();
    final pin = _pinController.text.trim();

    if (_credenciales.containsKey(usuario) &&
        _credenciales[usuario] == pin) {
      _navegarAlDashboard(usuario);
    } else {
      setState(() {
        _intentosFallidos++;
      });

      if (_intentosFallidos >= 3) {
        _iniciarBloqueo();
        _mostrarSnackBar(
          'Demasiados intentos fallidos. Espera 30 segundos.',
          AppColors.danger,
        );
      } else {
        _mostrarSnackBar(
          'Credenciales incorrectas. Intento $_intentosFallidos/3.',
          AppColors.warning,
        );
      }
    }
  }

  Future<void> _autenticarBiometria() async {
    try {
      final bool canAuthenticate =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) {
          _mostrarSnackBar(
            'Autenticación biométrica no disponible en este dispositivo.',
            AppColors.warning,
          );
        }
        return;
      }

      final bool autenticado = await _localAuth.authenticate(
        localizedReason:
            'Usa tu huella o biometría para ingresar al panel IoT',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (autenticado && mounted) {
        final nombre = _usuarioController.text.trim().isNotEmpty
            ? _usuarioController.text.trim().toLowerCase()
            : 'usuario';
        _navegarAlDashboard(nombre);
      }
    } on PlatformException catch (e) {
      if (mounted) {
        _mostrarSnackBar(
          'Error biométrico: ${e.message ?? "No disponible"}',
          AppColors.warning,
        );
      }
    }
  }

  void _navegarAlDashboard(String nombreUsuario) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(nombreUsuario: nombreUsuario),
      ),
    );
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Encabezado ──
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    size: 40,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Acceso Seguro — Hogar IoT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Control de seguridad y accesos',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Tarjeta de formulario ──
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 30,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Campo usuario
                          TextFormField(
                            controller: _usuarioController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_outline),
                              labelText: 'Nombre de usuario',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu nombre de usuario';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo PIN
                          TextFormField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: _ocultarPin,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline),
                              labelText: 'PIN de 4 dígitos',
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _ocultarPin
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _ocultarPin = !_ocultarPin;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu PIN';
                              }
                              if (value.length != 4) {
                                return 'El PIN debe tener 4 dígitos';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          // Mensaje de bloqueo
                          if (_bloqueado)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.dangerLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      color: AppColors.danger, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Acceso bloqueado. Intenta de nuevo en $_segundosRestantes s',
                                      style: const TextStyle(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 8),

                          // Botón principal
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _bloqueado ? null : _intentarLogin,
                              child: const Text('Ingresar al Panel'),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Divisor "o ingresa con"
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'o ingresa con',
                                  style: TextStyle(
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Botón biometría
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight
                                  .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed:
                                  _bloqueado ? null : _autenticarBiometria,
                              iconSize: 36,
                              padding: const EdgeInsets.all(14),
                              icon: Icon(
                                Icons.fingerprint,
                                color: _bloqueado
                                    ? AppColors.textSecondary
                                        .withValues(alpha: 0.3)
                                    : AppColors.primaryDark,
                              ),
                              tooltip: 'Autenticación biométrica',
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Huella digital',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
