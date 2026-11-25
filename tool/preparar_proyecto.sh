#!/usr/bin/env bash
# Prepara el proyecto Flutter en CI (GitHub Actions):
#  1. Genera las carpetas de plataforma con `flutter create` si no existen.
#  2. Agrega Drift y sus herramientas si el código ya las usa.
#  3. Ejecuta build_runner para generar el código de Drift.
#  4. Descarga sqlite3.wasm y drift_worker.js compatibles para la web.
set -euo pipefail

if [ ! -d android ]; then
  echo ">> Generando carpetas de plataforma"
  flutter create --project-name gestor_tareas_local --org mx.uaa.isc \
    --platforms=android,ios,web,windows,linux,macos .
fi

if grep -rq "package:drift" lib && ! grep -q "^  drift:" pubspec.yaml; then
  echo ">> Agregando dependencias de Drift"
  flutter pub add drift drift_flutter
  flutter pub add --dev drift_dev build_runner
fi

flutter pub get

if grep -rq "part 'app_database.g.dart'" lib; then
  echo ">> Generando código de Drift"
  dart run build_runner build --delete-conflicting-outputs
fi

if grep -q "^  drift:" pubspec.yaml; then
  bash tool/descargar_recursos_web.sh
fi
