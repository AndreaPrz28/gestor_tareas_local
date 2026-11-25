import 'package:flutter/material.dart';

import 'data/app_database.dart';
import 'data/tareas_repository.dart';
import 'screens/tareas_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GestorTareasApp());
}

/// Punto de entrada de la aplicación.
///
/// Es dueña de la base de datos: la abre una sola vez y la cierra en dispose().
/// En pruebas se puede inyectar una [AppDatabase] en memoria.
class GestorTareasApp extends StatefulWidget {
  const GestorTareasApp({super.key, this.baseDeDatos});

  final AppDatabase? baseDeDatos;

  @override
  State<GestorTareasApp> createState() => _GestorTareasAppState();
}

class _GestorTareasAppState extends State<GestorTareasApp> {
  late final AppDatabase _db;
  late final TareasRepository _repositorio;
  late final bool _esPropia;

  @override
  void initState() {
    super.initState();
    _esPropia = widget.baseDeDatos == null;
    _db = widget.baseDeDatos ?? AppDatabase();
    _repositorio = TareasRepository(_db);
  }

  @override
  void dispose() {
    // Liberar el recurso solo si esta clase lo creó.
    if (_esPropia) _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: TareasPage(repositorio: _repositorio),
    );
  }
}
