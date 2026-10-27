#!/usr/bin/env bash
# Actualiza el kit: trae la última versión del repositorio (solo fast-forward)
# y vuelve a ejecutar install.sh con los mismos argumentos.
# Uso: ./update.sh [argumentos de install.sh]
set -euo pipefail
KIT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if git -C "$KIT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ -n "$(git -C "$KIT_DIR" status --porcelain)" ]; then
    echo "ERROR: el repositorio del kit tiene cambios locales; confírmalos o descártalos antes de actualizar." >&2
    exit 1
  fi
  if git -C "$KIT_DIR" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    echo "Trayendo la última versión del kit…"
    git -C "$KIT_DIR" pull --ff-only || { echo "ERROR: no se pudo actualizar con fast-forward; revisa el repositorio del kit." >&2; exit 1; }
  else
    echo "AVISO: la rama del kit no sigue a ningún remoto; se instala la versión local." >&2
  fi
else
  echo "AVISO: $KIT_DIR no es un repositorio git; se instala la versión local." >&2
fi
exec "$KIT_DIR/install.sh" "$@"
