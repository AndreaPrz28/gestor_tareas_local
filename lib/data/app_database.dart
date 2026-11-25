import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// Archivo generado por build_runner:
//   dart run build_runner build --delete-conflicting-outputs
part 'app_database.g.dart';

/// Tabla `tareas` en SQLite.
///
/// Esquema resultante (aprox.):
///   CREATE TABLE tareas (
///     id          INTEGER PRIMARY KEY AUTOINCREMENT,
///     titulo      TEXT    NOT NULL,           -- 1..120 caracteres
///     completada  INTEGER NOT NULL DEFAULT 0, -- booleano (0/1) con CHECK
///     creada_en   INTEGER NOT NULL            -- fecha de creación
///   );
///
/// El nombre de la clase de fila se cambia a `TareaFila` para no chocar con
/// el modelo de dominio `Tarea` (lib/models/tarea.dart).
@DataClassName('TareaFila')
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get titulo =>
      // 120 = kLongitudMaximaTitulo (se escribe literal para el generador).
      text().withLength(min: 1, max: 120)();

  BoolColumn get completada =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get creadaEn =>
      dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  /// Si no se pasa un [executor], se abre la base persistente de la
  /// plataforma actual. En las pruebas se inyecta una base en memoria.
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _abrirConexion());

  @override
  int get schemaVersion => 1;

  /// Un solo punto de apertura para las seis plataformas:
  /// - Android, iOS, Windows, Linux y macOS: archivo `gestor_tareas.sqlite`
  ///   en la carpeta de soporte de la app (path_provider), vía dart:ffi.
  /// - Web: sqlite3 compilado a WebAssembly; el archivo se guarda en OPFS o
  ///   IndexedDB según lo que soporte el navegador.
  static QueryExecutor _abrirConexion() {
    return driftDatabase(
      name: 'gestor_tareas',
      web: DriftWebOptions(
        // Ambos archivos deben estar en la carpeta web/ (ver README).
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
