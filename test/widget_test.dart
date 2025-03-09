// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
// Asegúrate de ajustar la ruta según la estructura de tu proyecto.
import 'package:tarea_7/main.dart';

void main() {
  // Inicializa el binding y configura valores simulados para SharedPreferences.
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('La aplicación se inicia sin errores y muestra el título "Lista de Tareas"', (WidgetTester tester) async {
    // Inicia la aplicación envuelta en el Provider.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TaskProvider(),
        child: MyApp(),
      ),
    );

    // Espera a que se renderice completamente la UI.
    await tester.pumpAndSettle();

    // Verifica que se muestre el título "Lista de Tareas" en la AppBar.
    expect(find.text('Lista de Tareas'), findsOneWidget);
  });
}
