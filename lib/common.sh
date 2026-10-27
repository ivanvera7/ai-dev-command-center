# shellcheck shell=bash
# Funciones compartidas por install.sh y uninstall.sh. Se carga con `source`.
# Compatible con bash 3.2 (macOS): sin arrays asociativos ni mapfile.

MARK_START='<!-- ai-dev-kit:start -->'
MARK_END='<!-- ai-dev-kit:end -->'
TAB=$(printf '\t')

say()  { printf '%s\n' "$*"; }
warn() { printf 'AVISO: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# Valor obligatorio para opciones con argumento: need_value "--opcion" "$#" "${2:-}"
need_value() { [ "$2" -ge 2 ] && [ -n "$3" ] || die "$1 necesita un valor"; }

sha() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1
  else sha256sum "$1" | cut -d' ' -f1; fi
}

# Resuelve el destino. Requiere MODE (global|project) y PROJECT_DIR.
# Define BASE (carpeta .claude), CLAUDE_MD, STATE, MANIFEST.
resolve_target() {
  if [ "$MODE" = global ]; then
    BASE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
    CLAUDE_MD="$BASE/CLAUDE.md"
  else
    [ -n "$PROJECT_DIR" ] || die "--project necesita una carpeta"
    [ -d "$PROJECT_DIR" ] || die "la carpeta del proyecto no existe: $PROJECT_DIR"
    PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)
    BASE="$PROJECT_DIR/.claude"
    CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
  fi
  STATE="$BASE/.ai-dev-kit"
  MANIFEST="$STATE/manifest"
}

# Una ruta del manifiesto solo es válida dentro de agents/ o skills/ y sin "..".
valid_rel() {
  case "$1" in agents/?*|skills/?*) ;; *) return 1 ;; esac
  case "/$1/" in */../*|*/./*|*//*) return 1 ;; esac
  return 0
}

# Aborta antes de cambiar nada si el manifiesto contiene rutas no válidas
# (un manifiesto versionado en un repo ajeno podría apuntar fuera de .claude).
validate_manifest() {
  [ -f "$MANIFEST" ] || return 0
  [ ! -L "$MANIFEST" ] || die "el manifiesto es un enlace simbólico: $MANIFEST"
  while IFS="$TAB" read -r h rel; do
    [ -z "$h$rel" ] && continue
    valid_rel "$rel" || die "manifiesto inválido (ruta no permitida: '$rel') en $MANIFEST; no se ha cambiado nada"
    case "$h" in *[!0-9a-f]*|'') die "manifiesto inválido (hash no válido) en $MANIFEST" ;; esac
  done < "$MANIFEST"
}

# En modo proyecto el destino puede venir de un repo ajeno: ningún componente entre
# BASE y la ruta puede ser un enlace simbólico (evita escribir o borrar fuera).
check_path() { # $1 = ruta relativa a BASE
  [ "$MODE" = project ] || return 0
  local p="$BASE/$1"
  while [ "$p" != "$BASE" ] && [ "$p" != "/" ]; do
    [ -L "$p" ] && die "enlace simbólico en el destino: $p; no se ha cambiado nada"
    p=$(dirname "$p")
  done
  [ -L "$BASE" ] && die "la carpeta .claude del proyecto es un enlace simbólico: $BASE"
  return 0
}

# En modo proyecto, la carpeta de estado y lo que el instalador escribe en ella
# tampoco pueden ser enlaces simbólicos.
check_state() {
  [ "$MODE" = project ] || return 0
  [ -L "$BASE" ] && die "la carpeta .claude del proyecto es un enlace simbólico: $BASE"
  [ -L "$STATE" ] && die "enlace simbólico en el destino: $STATE; no se ha cambiado nada"
  local f
  for f in manifest VERSION .gitignore claude-md-created claude-md-no-final-newline backups; do
    [ -L "$STATE/$f" ] && die "enlace simbólico en el destino: $STATE/$f; no se ha cambiado nada"
  done
  return 0
}

# Hash registrado en el manifiesto para una ruta relativa (vacío si no consta).
manifest_hash() {
  [ -f "$MANIFEST" ] || return 0
  awk -F'\t' -v p="$1" '$2==p {print $1; exit}' "$MANIFEST"
}

# Borra directorios vacíos que quedan tras retirar un archivo, sin salir nunca de
# agents/ o skills/ (esas dos carpetas y sus superiores no se tocan).
prune_dirs() { # $1 = ruta relativa del archivo retirado
  local d; d=$(dirname "$1")
  while [ "$d" != agents ] && [ "$d" != skills ] && [ "$d" != . ]; do
    rmdir "$BASE/$d" 2>/dev/null || break
    d=$(dirname "$d")
  done
}

# Confirmación interactiva. Sin terminal y sin --yes, sale con código 3.
confirm() {
  [ "${YES:-0}" = 1 ] && return 0
  if [ -t 0 ]; then
    printf '%s [s/N] ' "$1"; read -r ans || ans=""
    case "$ans" in s|S|si|sí|y|Y|yes) return 0 ;; esac
    say "Cancelado. No se ha modificado nada."; exit 0
  fi
  say "Hay cambios que requieren confirmación y no hay terminal interactiva."
  say "Revisa el plan y vuelve a ejecutar con --yes para aplicarlo."
  exit 3
}

backup() { # $1 = ruta absoluta, $2 = ruta relativa dentro del backup
  [ -e "$1" ] || return 0
  mkdir -p "$(dirname "$BACKUP_DIR/$2")"
  cp -p "$1" "$BACKUP_DIR/$2"
}

# Estado del bloque en un CLAUDE.md: none | ok | broken.
# ok = exactamente un marcador de inicio y uno de fin, en ese orden.
block_state() {
  [ -f "$1" ] || { echo none; return; }
  awk -v s="$MARK_START" -v e="$MARK_END" '
    $0==s {ns++; if (!ls) ls=NR}
    $0==e {ne++; if (!le) le=NR}
    END {
      if (!ns && !ne) print "none"
      else if (ns==1 && ne==1 && ls<le) print "ok"
      else print "broken"
    }' "$1"
}

# Imprime el CLAUDE.md sin el bloque del kit ni la línea en blanco que lo precede.
# Solo se llama con block_state = ok.
strip_block() {
  awk -v s="$MARK_START" -v e="$MARK_END" '
    $0==s {skip=1; held=0; next}
    skip && $0==e {skip=0; next}
    skip {next}
    { if (held) print ""; held=0
      if ($0=="") {held=1; next}
      print }
    END { if (held) print "" }' "$1"
}
