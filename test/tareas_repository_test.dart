import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/tareas_repository.dart';
import 'package:gestor_tareas_local/utils/validaciones.dart';

/// Pruebas de la capa de almacenamiento con SQLite real (sqlite3 vía FFI).
/// Se ejecutan con `flutter test` en el equipo de desarrollo.
void main() {
  // Evita la advertencia de Drift por abrir varias bases en la misma prueba.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('CRUD en base en memoria', () {
    late AppDatabase db;
    late TareasRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = TareasRepository(db);
    });

    tearDown(() => db.close());

    test('INSERT + SELECT: agrega tareas y las devuelve en orden', () async {
      await repo.agregar('Uno');
      await repo.agregar('  Dos  '); // se guarda sin espacios extremos
      final tareas = await repo.obtenerTareas();

      expect(tareas.map((t) => t.titulo), ['Uno', 'Dos']);
      expect(tareas.every((t) => !t.completada), isTrue);
      expect(tareas[0].id, isNot(tareas[1].id));
    });

    test('no guarda títulos vacíos (P5)', () async {
      expect(() => repo.agregar('   '), throwsA(isA<TituloInvalidoException>()));
      expect(await repo.obtenerTareas(), isEmpty);
    });

    test('UPDATE: edita título y cambia estado', () async {
      final id = await repo.agregar('Original');
      await repo.editarTitulo(id, 'Editado');
      await repo.cambiarEstado(id, true);

      final tarea = (await repo.obtenerTareas()).single;
      expect(tarea.titulo, 'Editado');
      expect(tarea.completada, isTrue);

      await repo.cambiarEstado(id, false);
      expect((await repo.obtenerTareas()).single.completada, isFalse);
    });

    test('DELETE: elimina por id solo la tarea indicada', () async {
      final a = await repo.agregar('A');
      await repo.agregar('B');
      await repo.eliminar(a);

      final tareas = await repo.obtenerTareas();
      expect(tareas.map((t) => t.titulo), ['B']);
    });

    test('operar sobre un id inexistente lanza error', () async {
      await expectLater(repo.eliminar(999), throwsStateError);
      await expectLater(repo.cambiarEstado(999, true), throwsStateError);
    });

    test('el Stream emite de nuevo después de una escritura', () async {
      final emisiones = repo.observarTareas().map((l) => l.length);
      final esperado = expectLater(emisiones, emitsInOrder([0, 1]));
      await Future<void>.delayed(Duration.zero);
      await repo.agregar('Reactiva');
      await esperado;
    });
  });

  test('persistencia: los datos sobreviven al cerrar y reabrir el archivo (P1–P4)',
      () async {
    final dir = await Directory.systemTemp.createTemp('gestor_tareas_test');
    final archivo = File('${dir.path}/tareas.sqlite');

    // Primera "ejecución" de la app.
    var db = AppDatabase(NativeDatabase(archivo));
    var repo = TareasRepository(db);
    final id1 = await repo.agregar('Tarea 1');
    final id2 = await repo.agregar('Tarea 2');
    final id3 = await repo.agregar('Tarea 3');
    await repo.cambiarEstado(id1, true);
    await repo.editarTitulo(id2, 'Tarea 2 editada');
    await repo.eliminar(id3);
    await db.close();

    // Segunda "ejecución": nueva conexión al mismo archivo.
    db = AppDatabase(NativeDatabase(archivo));
    repo = TareasRepository(db);
    final tareas = await repo.obtenerTareas();
    await db.close();
    await dir.delete(recursive: true);

    expect(tareas.length, 2);
    expect(tareas[0].completada, isTrue);
    expect(tareas[1].titulo, 'Tarea 2 editada');
    expect(tareas.any((t) => t.id == id3), isFalse);
  });
}
