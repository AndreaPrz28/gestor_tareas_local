import 'package:flutter/material.dart';

import '../data/tareas_repository.dart';
import '../models/tarea.dart';
import '../utils/validaciones.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key, required this.repositorio});

  final TareasRepository repositorio;

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();

  /// El Stream se crea UNA vez aquí y no dentro de build(), para no lanzar
  /// una consulta nueva en cada reconstrucción de la interfaz.
  late final Stream<List<Tarea>> _tareasStream;

  String? _errorTitulo;

  @override
  void initState() {
    super.initState();
    _tareasStream = widget.repositorio.observarTareas();
  }

  Future<void> _agregarTarea() async {
    final error = validarTitulo(_tituloController.text);
    if (error != null) {
      setState(() => _errorTitulo = error);
      return;
    }
    setState(() => _errorTitulo = null);

    final ok = await _ejecutar(
      () => widget.repositorio.agregar(_tituloController.text),
      'No se pudo guardar la tarea',
    );
    if (ok) _tituloController.clear();
  }

  void _alternarCompletada(Tarea tarea, bool completada) {
    _mostrarMensaje('Pendiente: actualización de estado');
  }

  void _editarTarea(Tarea tarea) {
    _mostrarMensaje('Pendiente: edición de título');
  }

  void _eliminarTarea(Tarea tarea) {
    _mostrarMensaje('Pendiente: eliminación');
  }

  /// Ejecuta una operación de base de datos y muestra un mensaje comprensible
  /// si falla. Devuelve true si la operación terminó bien.
  Future<bool> _ejecutar(
    Future<Object?> Function() operacion,
    String mensajeError,
  ) async {
    try {
      await operacion();
      return true;
    } on TituloInvalidoException catch (e) {
      _mostrarMensaje(e.mensaje);
    } catch (e) {
      debugPrint('$mensajeError: $e');
      _mostrarMensaje('$mensajeError. Intenta de nuevo.');
    }
    return false;
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              maxLength: kLongitudMaximaTitulo,
              decoration: InputDecoration(
                labelText: 'Nueva tarea',
                border: const OutlineInputBorder(),
                errorText: _errorTitulo,
              ),
              onChanged: (_) {
                if (_errorTitulo != null) setState(() => _errorTitulo = null);
              },
              onSubmitted: (_) => _agregarTarea(),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Tarea>>(
                stream: _tareasStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al leer la base de datos:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tareas = snapshot.data!;
                  if (tareas.isEmpty) {
                    return const Center(
                      child: Text('Todavía no hay tareas guardadas'),
                    );
                  }
                  return ListView.builder(
                    itemCount: tareas.length,
                    itemBuilder: (context, index) {
                      final tarea = tareas[index];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: tarea.completada,
                            onChanged: (valor) {
                              if (valor != null) {
                                _alternarCompletada(tarea, valor);
                              }
                            },
                          ),
                          title: Text(
                            tarea.titulo,
                            style: tarea.completada
                                ? const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                  )
                                : null,
                          ),
                          subtitle: Text(
                            'ID: ${tarea.id} · '
                            '${tarea.completada ? 'Completada' : 'Pendiente'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editarTarea(tarea),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _eliminarTarea(tarea),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
