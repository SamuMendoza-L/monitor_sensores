import 'package:flutter_test/flutter_test.dart';

import 'package:monitor_sensores/main.dart';

void main() {
  testWidgets('App smoke test - LoginScreen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MonitorSensoresApp());

    // Verifica que la pantalla de login se muestra
    expect(find.text('Acceso Seguro — Hogar IoT'), findsOneWidget);
    expect(find.text('Ingresar al Panel'), findsOneWidget);
  });
}
