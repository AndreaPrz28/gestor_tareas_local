import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/main.dart';

/// Base en memoria para pruebas de widgets.
/// closeStreamsSynchronously evita el error "A Timer is still pending".
AppDatabase _baseDePrueba() => AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

  setUp(() => db = _baseDePrueba());
  tearDown(() => db.close());

  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(GestorTareasApp(baseDeDatos: db));
    await tester.pumpAndSettle();
  }

  Future<void> cerrarApp(WidgetTester tester) async {
    // Desmonta la app para cancelar las consultas reactivas antes de cerrar.
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    await abrirApp(tester);
    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);
    await cerrarApp(tester);
  });

  testWidgets('Un título vacío muestra error y no crea tareas (P5)',
      (tester) async {
    await abrirApp(tester);
    await tester.enterText(find.byType(TextField), '    ');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pumpAndSettle();

    expect(find.text('El título no puede estar vacío.'), findsOneWidget);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);
    expect(await db.select(db.tareas).get(), isEmpty);
    await cerrarApp(tester);
  });

  testWidgets('Agregar una tarea la guarda en SQLite y la muestra',
      (tester) async {
    await abrirApp(tester);
    await tester.enterText(find.byType(TextField), 'Repasar Drift');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pumpAndSettle();

    expect(find.text('Repasar Drift'), findsOneWidget);
    final filas = await db.select(db.tareas).get();
    expect(filas.single.titulo, 'Repasar Drift');
    await cerrarApp(tester);
  });
}
