/// Modelo de dominio de una tarea.
///
/// La interfaz trabaja con esta clase y no con las filas generadas por Drift,
/// así la pantalla no depende directamente de la capa de persistencia.
class Tarea {
  final int id;
  final String titulo;
  final bool completada;

  const Tarea({
    required this.id,
    required this.titulo,
    required this.completada,
  });
}
