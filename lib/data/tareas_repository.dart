import 'package:drift/drift.dart';

import '../models/tarea.dart';
import '../utils/validaciones.dart';
import 'app_database.dart';

/// Capa intermedia entre la interfaz y SQLite.
///
/// Toda operación CRUD pasa por aquí; la pantalla nunca escribe SQL ni
/// consulta la base dentro de build().
class TareasRepository {
  TareasRepository(this._db);

  final AppDatabase _db;

  // ---------- SELECT ----------

  /// Consulta reactiva: emite la lista completa cada vez que la tabla cambia
  /// (después de INSERT, UPDATE o DELETE), por lo que la UI se actualiza sola.
  Stream<List<Tarea>> observarTareas() {
    final consulta = _db.select(_db.tareas)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return consulta.watch().map((filas) => filas.map(_aModelo).toList());
  }

  /// Consulta puntual (útil para pruebas).
  Future<List<Tarea>> obtenerTareas() async {
    final consulta = _db.select(_db.tareas)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    final filas = await consulta.get();
    return filas.map(_aModelo).toList();
  }

  // ---------- INSERT ----------

  /// Inserta una tarea y devuelve el id generado por SQLite.
  Future<int> agregar(String titulo) {
    final limpio = _validar(titulo);
    return _db.into(_db.tareas).insert(TareasCompanion.insert(titulo: limpio));
  }

  // ---------- UPDATE ----------

  Future<void> editarTitulo(int id, String nuevoTitulo) async {
    final limpio = _validar(nuevoTitulo);
    final afectadas = await (_db.update(_db.tareas)
          ..where((t) => t.id.equals(id)))
        .write(TareasCompanion(titulo: Value(limpio)));
    _verificarExistencia(afectadas, id);
  }

  Future<void> cambiarEstado(int id, bool completada) async {
    final afectadas = await (_db.update(_db.tareas)
          ..where((t) => t.id.equals(id)))
        .write(TareasCompanion(completada: Value(completada)));
    _verificarExistencia(afectadas, id);
  }

  // ---------- DELETE ----------

  Future<void> eliminar(int id) async {
    final afectadas =
        await (_db.delete(_db.tareas)..where((t) => t.id.equals(id))).go();
    _verificarExistencia(afectadas, id);
  }

  // ---------- Auxiliares ----------

  String _validar(String titulo) {
    final error = validarTitulo(titulo);
    if (error != null) throw TituloInvalidoException(error);
    return titulo.trim();
  }

  void _verificarExistencia(int filasAfectadas, int id) {
    if (filasAfectadas == 0) {
      throw StateError('No existe una tarea con id $id.');
    }
  }

  Tarea _aModelo(TareaFila fila) => Tarea(
        id: fila.id,
        titulo: fila.titulo,
        completada: fila.completada,
      );
}
