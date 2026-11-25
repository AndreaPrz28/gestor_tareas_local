# Gestor de tareas local (Flutter + SQLite)

Práctica de Programación de Dispositivos Móviles: gestor de tareas con persistencia **SQLite local**, sin servidor.

## Tecnología de persistencia elegida

Se usará **Drift** con **drift_flutter**:

- `drift` define la tabla en Dart y genera las clases con `build_runner`; ofrece consultas reactivas (`Stream`).
- `drift_flutter` abre la base con una sola función (`driftDatabase`) en Android, iOS, Windows, Linux, macOS y web (en web mediante SQLite en WebAssembly).
- Se descartó `sqflite` porque no soporta web ni escritorio sin paquetes adicionales.

## Diseño de la tabla `tareas`

| Columna | Tipo | Notas |
|---|---|---|
| `id` | INTEGER | Llave primaria autoincremental (identifica cada registro) |
| `titulo` | TEXT | No nulo, no vacío |
| `completada` | INTEGER (0/1) | Booleano, falso por defecto |
| `creada_en` | INTEGER (fecha) | Fecha de creación |

## Avance

- [x] Apertura de la base persistente (`lib/data/app_database.dart`)
- [x] Alta y consulta reactiva de tareas (`lib/data/tareas_repository.dart`)
- [ ] Edición, cambio de estado y eliminación
