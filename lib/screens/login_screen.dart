import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:monitor_sensores/screens/dashboard_screen.dart';

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
          Colors.red,
        );
      } else {
        _mostrarSnackBar(
          'Credenciales incorrectas. Intento $_intentosFallidos/3.',
          Colors.orange.shade800,
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
            Colors.orange.shade800,
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
          Colors.orange.shade800,
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
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Encabezado ──
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(
                    Icons.home_work_rounded,
                    size: 42,
                    color: Colors.teal.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Acceso Seguro — Hogar IoT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Control de seguridad y accesos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Tarjeta de formulario ──
                Card(
                  elevation: 3,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Campo usuario
                          TextFormField(
                            controller: _usuarioController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person_outline),
                              labelText: 'Nombre de usuario',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _ocultarPin
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
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
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Acceso bloqueado. Intenta de nuevo en $_segundosRestantes s',
                                      style: const TextStyle(
                                        color: Colors.red,
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
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _bloqueado ? null : _intentarLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade400,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Ingresar al Panel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Divisor "o ingresa con"
                          Row(
                            children: [
                              Expanded(
                                  child:
                                      Divider(color: Colors.grey.shade300)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'o ingresa con',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                  child:
                                      Divider(color: Colors.grey.shade300)),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Botón biometría
                          IconButton(
                            onPressed:
                                _bloqueado ? null : _autenticarBiometria,
                            icon: Icon(
                              Icons.fingerprint,
                              size: 36,
                              color: _bloqueado
                                  ? Colors.grey.shade400
                                  : Colors.teal.shade700,
                            ),
                            tooltip: 'Autenticación biométrica',
                          ),
                          Text(
                            'Huella digital',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
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
