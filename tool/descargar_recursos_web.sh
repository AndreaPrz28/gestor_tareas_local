#!/usr/bin/env bash
# Descarga a web/ las versiones de sqlite3.wasm y drift_worker.js que
# corresponden a las versiones de `sqlite3` y `drift` en pubspec.lock.
# Requiere la CLI `gh` autenticada (GH_TOKEN).
set -euo pipefail

version() {
  awk -v p="  $1:" '$0==p{f=1} f && /version:/{gsub(/"/,"",$2); print $2; exit}' pubspec.lock
}

DRIFT_V=$(version drift)
SQLITE_V=$(version sqlite3)
ESPERADO="drift=$DRIFT_V sqlite3=$SQLITE_V"
echo ">> Versiones en pubspec.lock: $ESPERADO"

if [ -f web/.versiones_web ] && [ "$(cat web/.versiones_web)" = "$ESPERADO" ] \
   && [ -f web/sqlite3.wasm ] && [ -f web/drift_worker.js ]; then
  echo ">> Recursos web ya actualizados"
  exit 0
fi

descargar() { # repo tag asset
  local repo=$1 tag=$2 asset=$3
  if gh release download "$tag" -R "$repo" -p "$asset" -D web --clobber 2>/dev/null; then
    echo ">> $asset descargado de $repo@$tag"
    return 0
  fi
  echo ">> $repo@$tag no tiene $asset; buscando la release más reciente que lo tenga"
  for t in $(gh release list -R "$repo" -L 40 --json tagName -q '.[].tagName'); do
    if gh release download "$t" -R "$repo" -p "$asset" -D web --clobber 2>/dev/null; then
      echo ">> $asset descargado de $repo@$t (respaldo)"
      return 0
    fi
  done
  echo "No se encontró $asset en $repo" >&2
  return 1
}

descargar simolus3/drift "drift-$DRIFT_V" drift_worker.js
descargar simolus3/sqlite3.dart "sqlite3-$SQLITE_V" sqlite3.wasm
echo "$ESPERADO" > web/.versiones_web
