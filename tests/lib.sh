# shellcheck shell=bash
# Utilidades mínimas de prueba. Se carga con `source`.
KIT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FAILS=0
pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FALLO %s\n' "$1"; FAILS=$((FAILS+1)); }
check() { # check "nombre" comando...
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then pass "$name"; else fail "$name"; fi
}
eq() { # eq "nombre" esperado obtenido
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1 (esperado: '$2', obtenido: '$3')"; fi
}
sandbox() { mktemp -d "${TMPDIR:-/tmp}/aidk-test.XXXXXX"; }
finish() { [ "$FAILS" = 0 ] || { echo "  $FAILS fallo(s)"; exit 1; }; }
