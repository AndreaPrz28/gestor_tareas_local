# Gestor de tareas local (Flutter + SQLite con Drift)

**Alumna:** Andrea Guadalupe Perez Jimenez · ID 530918 · Programación de Dispositivos Móviles

Aplicación Flutter que guarda tareas en una base **SQLite local**, sin servidor ni conexión a internet. Se usa la misma base de código para web, móvil y escritorio.

## Tecnología de persistencia elegida

| Paquete | Para qué se usa |
|---|---|
| `drift` | ORM sobre SQLite con tipos seguros: define tablas en Dart, genera las clases y ofrece consultas reactivas (`watch()`). |
| `drift_flutter` | `driftDatabase()` abre la base en cada plataforma con una sola llamada: archivo SQLite vía FFI en nativo, y SQLite en WebAssembly (OPFS/IndexedDB) en web. |
| `drift_dev` + `build_runner` (dev) | Generan `app_database.g.dart` a partir de la definición de la tabla. |

**Por qué Drift y no `sqflite`:** `sqflite` no funciona en web ni en Windows/Linux sin paquetes extra; Drift + drift_flutter cubre las seis plataformas con el mismo código.

## Estructura

```
lib/
├── main.dart                   # Abre la base una vez y la cierra en dispose()
├── data/
│   ├── app_database.dart       # Tabla `tareas` + apertura multiplataforma
│   ├── app_database.g.dart     # (generado por build_runner)
│   └── tareas_repository.dart  # INSERT / SELECT / UPDATE / DELETE
├── models/tarea.dart           # Modelo de dominio que usa la UI
├── screens/tareas_page.dart    # Interfaz (StreamBuilder, sin SQL en build())
└── utils/validaciones.dart     # Validación del título
web/
├── sqlite3.wasm                # SQLite compilado a WebAssembly
└── drift_worker.js             # Worker de Drift
test/
├── validaciones_test.dart
├── tareas_repository_test.dart
└── widget_test.dart
```

## Esquema de la tabla

| Columna | Tipo SQLite | Restricción |
|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `titulo` | TEXT | NOT NULL, 1–120 caracteres |
| `completada` | INTEGER (0/1) | NOT NULL, DEFAULT 0 |
| `creada_en` | INTEGER (fecha) | NOT NULL, DEFAULT fecha actual |

La UI se actualiza con una **consulta reactiva** (`Stream` de `select(...).watch()`): después de cualquier escritura, Drift vuelve a emitir la lista y `StreamBuilder` redibuja sin recargar a mano.

## Pruébalo sin compilar

- **Web:** https://andreaprz28.github.io/gestor_tareas_local/
- **Windows y Android:** descarga `gestor_tareas_windows.zip` (ejecutar `gestor_tareas_local.exe`) o `gestor_tareas_android.apk` desde [Releases](https://github.com/AndreaPrz28/gestor_tareas_local/releases).

## Cómo ejecutar

Requisitos: Flutter estable (`flutter doctor -v`).

```bash
git clone <URL_DE_ESTE_REPOSITORIO>
cd gestor_tareas_local
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d chrome     # web
flutter run -d windows    # escritorio Windows
flutter run               # Android con un emulador/teléfono conectado
```

### Configuración web

SQLite en el navegador necesita dos archivos dentro de `web/` (ya incluidos en el repositorio; `tool/descargar_recursos_web.sh` los descarga según `pubspec.lock`). Versiones actuales: drift 2.35.4 y sqlite3 3.9.2.

- `sqlite3.wasm`: de las releases de [sqlite3.dart](https://github.com/simolus3/sqlite3.dart/releases), con la misma versión de `sqlite3` que aparece en `pubspec.lock`.
- `drift_worker.js`: de las releases de [drift](https://github.com/simolus3/drift/releases), con la misma versión de `drift` que aparece en `pubspec.lock`.

Si las versiones no coinciden con `pubspec.lock`, la base puede fallar al abrir en el navegador.

## Plataformas

| Plataforma | Estado |
|---|---|
| Web (navegador Chromium en Windows 11, GitHub Pages) | **Verificada** manualmente (P1–P6) |
| Windows 11 (build release) | **Verificada** manualmente (P1–P5) + pruebas automáticas |
| Linux | Pruebas automáticas (`flutter test`) en CI; la app de escritorio no se ejecutó |
| Android | APK compilado en CI; **no se ejecutó** en dispositivo |
| macOS, iOS | Soportadas por el código (drift_flutter), **no compiladas** (requieren Mac) |

## Comprobación técnica (P1–P6)

| ID | Acción | Resultado esperado | Resultado obtenido |
|---|---|---|---|
| P1 | Agregar tres tareas, cerrar la app y abrirla | Permanecen las tres | ✅ Web y Windows |
| P2 | Marcar una como completada y reiniciar | Se conserva el estado | ✅ Web y Windows |
| P3 | Cambiar el título y reiniciar | Aparece el nuevo título | ✅ Web y Windows |
| P4 | Eliminar una tarea y reiniciar | No reaparece | ✅ Web y Windows |
| P5 | Intentar agregar un título vacío | No se registra | ✅ Web y Windows (mensaje “El título no puede estar vacío.”) |
| P6 | Web: recargar y cerrar/abrir la pestaña | Los datos permanecen | ✅ Recargar y cerrar/abrir pestaña |

> Para comprobar la persistencia hay que **cerrar completamente** la app (no basta un hot reload).
>
> En web, Drift eligió `sharedIndexedDb` (base `gestor_tareas` en IndexedDB) porque GitHub Pages no envía los encabezados COOP/COEP que requiere OPFS.

## Pruebas automatizadas

`flutter test`: **15 pruebas, todas pasan** en Linux y Windows (GitHub Actions, `.github/workflows/ci.yml`).

- `validaciones_test.dart`: rechaza títulos vacíos, solo espacios, nulos o demasiado largos.
- `tareas_repository_test.dart`: CRUD completo sobre SQLite en memoria, error con id inexistente, emisión del Stream y **persistencia en un archivo real** (escribir, cerrar la conexión, reabrir y verificar).
- `widget_test.dart`: arranque de la interfaz, rechazo de título vacío desde la UI y alta de una tarea que queda guardada en la base.
