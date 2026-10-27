#!/usr/bin/env bash
# Instala o actualiza AI Dev Command Center en Claude Code.
# Uso: ./install.sh [--global | --project DIR] [--only agents,skills,instructions]
#                   [--dry-run] [--yes] [--force]
set -euo pipefail

KIT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
. "$KIT_DIR/lib/common.sh"
VERSION=$(cat "$KIT_DIR/VERSION")

usage() {
  cat <<EOF
AI Dev Command Center $VERSION — instalador

  --global            Instala en ~/.claude (o \$CLAUDE_CONFIG_DIR). Por defecto.
  --project DIR       Instala en DIR/.claude y añade el bloque a DIR/CLAUDE.md.
  --only LISTA        Componentes separados por comas: agents, skills, instructions, guard.
  --dry-run           Muestra el plan y no cambia nada.
  --yes               Aplica sin preguntar. Sin terminal interactiva es necesario
                      cuando el plan modifica o retira archivos existentes (si no, código 3).
  --force             Sustituye archivos en conflicto o modificados, guardando copia.
  -h, --help          Esta ayuda.

Nunca instala herramientas externas ni pide credenciales. Ver scripts/doctor.sh.
EOF
}

MODE=global; PROJECT_DIR=""; ONLY="agents,skills,instructions,guard"; DRY=0; YES=0; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --global) MODE=global ;;
    --project) need_value "$1" $# "${2:-}"; MODE=project; PROJECT_DIR="$2"; shift ;;
    --only) need_value "$1" $# "${2:-}"; ONLY="$2"; shift ;;
    --dry-run) DRY=1 ;;
    --yes|-y) YES=1 ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "opción desconocida: $1" ;;
  esac
  shift
done
want() { case ",$ONLY," in *",$1,"*) return 0 ;; esac; return 1; }
for c in $(echo "$ONLY" | tr ',' ' '); do
  case "$c" in agents|skills|instructions|guard) ;; *) die "componente desconocido: $c" ;; esac
done

# --- Requisitos y entorno ---------------------------------------------------
os=$(uname -s)
case "$os" in Darwin|Linux) ;; *) warn "sistema '$os' no probado; usa macOS, Linux o WSL" ;; esac
command -v shasum >/dev/null 2>&1 || command -v sha256sum >/dev/null 2>&1 || die "falta shasum o sha256sum"
for t in git claude jq; do command -v "$t" >/dev/null 2>&1 || warn "'$t' no encontrado (el kit se instala, pero el flujo SDD lo necesita; ver scripts/doctor.sh)"; done

resolve_target
check_state
validate_manifest
say "AI Dev Command Center $VERSION · sistema: $os · modo: $MODE"
say "Destino: $BASE"
[ "$ONLY" = "agents,skills,instructions,guard" ] || say "Componentes: $ONLY"

if [ "$MODE" = project ]; then
  if [ -z "$(ls -A "$PROJECT_DIR" 2>/dev/null)" ]; then say "Proyecto: carpeta vacía"; else say "Proyecto: carpeta existente"; fi
  git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || warn "el proyecto no es un repositorio git; /sdd-init lo pedirá"
  personal="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
  if ls -d "$personal"/sdd-* >/dev/null 2>&1; then
    warn "hay skills sdd-* personales en $personal: Claude Code usa las personales antes que las del proyecto"
  fi
  [ ! -L "$CLAUDE_MD" ] || die "CLAUDE.md del proyecto es un enlace simbólico: $CLAUDE_MD; no se ha cambiado nada"
fi
if [ -f "$MANIFEST" ]; then
  say "Instalación previa detectada: versión $(cat "$STATE/VERSION" 2>/dev/null || echo desconocida)"
else
  say "Sin instalación previa del kit en este destino"
fi

# --- Plan --------------------------------------------------------------------
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PLAN="$TMP/plan"; : > "$PLAN"            # ACCION<TAB>ruta relativa
PAYLOAD="$TMP/payload"; : > "$PAYLOAD"

( cd "$KIT_DIR"
  if want agents; then find agents -type f -name '*.md'; fi
  if want skills; then find skills -type f ! -name '.DS_Store'; fi
  if want guard; then find hooks -type f ! -name '.DS_Store'; fi
) | LC_ALL=C sort > "$PAYLOAD"

while IFS= read -r rel; do
  check_path "$rel"
  src="$KIT_DIR/$rel"; dst="$BASE/$rel"
  if [ ! -e "$dst" ]; then act=ADD
  else
    h=$(sha "$dst"); m=$(manifest_hash "$rel")
    if [ "$h" = "$(sha "$src")" ]; then act=SAME    # idéntico: el kit lo adopta
    elif [ -n "$m" ] && [ "$h" = "$m" ]; then act=UPDATE
    elif [ -n "$m" ]; then act=MODIFIED     # archivo del kit modificado por el usuario
    else act=CONFLICT; fi                   # archivo ajeno con el mismo nombre
  fi
  printf '%s\t%s\n' "$act" "$rel" >> "$PLAN"
done < "$PAYLOAD"

# Archivos del kit que ya no forman parte de esta versión.
if [ -f "$MANIFEST" ]; then
  while IFS="$TAB" read -r m rel; do
    case "$rel" in agents/*) want agents || continue ;; skills/*) want skills || continue ;; hooks/*) want guard || continue ;; *) continue ;; esac
    grep -qxF "$rel" "$PAYLOAD" && continue
    check_path "$rel"
    dst="$BASE/$rel"
    [ -e "$dst" ] || continue
    if [ "$(sha "$dst")" = "$m" ]; then printf 'REMOVE\t%s\n' "$rel" >> "$PLAN"
    else printf 'KEEPOLD\t%s\n' "$rel" >> "$PLAN"; fi
  done < "$MANIFEST"
fi

BLOCK="$TMP/block"
{ echo "$MARK_START"; cat "$KIT_DIR/core/CLAUDE.sdd.md"; echo "$MARK_END"; } > "$BLOCK"
INSTR=""
if want instructions; then
  case "$(block_state "$CLAUDE_MD")" in
    broken) die "marcadores ai-dev-kit incompletos o duplicados en $CLAUDE_MD; corrígelos a mano (no se ha cambiado nada)" ;;
    ok)
      if awk -v s="$MARK_START" -v e="$MARK_END" '$0==s{p=1} p{print} $0==e{p=0}' "$CLAUDE_MD" | cmp -s - "$BLOCK"; then INSTR=SAME; else INSTR=REPLACE; fi ;;
    none) if [ -f "$CLAUDE_MD" ]; then INSTR=APPEND; else INSTR=CREATE; fi ;;
  esac
fi

SETTINGS="$BASE/settings.json"
GUARD=""
if want guard; then
  if [ "$MODE" = project ] && [ -L "$SETTINGS" ]; then die "enlace simbólico en el destino: $SETTINGS; no se ha cambiado nada"; fi
  if ! command -v jq >/dev/null 2>&1; then GUARD=NOJQ
  else
    if [ -e "$SETTINGS" ] && ! jq empty "$SETTINGS" >/dev/null 2>&1; then die "$SETTINGS no es JSON válido; corrígelo antes de instalar el guard (no se ha cambiado nada)"; fi
    settings_with_guard "$SETTINGS" > "$TMP/settings.new" || die "no se pudo preparar $SETTINGS"
    if [ ! -e "$SETTINGS" ]; then GUARD=CREATE
    elif jq -S . "$SETTINGS" | cmp -s - <(jq -S . "$TMP/settings.new"); then GUARD=SAME
    elif has_guard "$SETTINGS"; then GUARD=UPDATE
    else GUARD=ADD; fi
  fi
fi

count() { awk -F'\t' -v a="$1" '$1==a' "$PLAN" | wc -l | tr -d ' '; }
list()  { awk -F'\t' -v a="$1" '$1==a {print "    " $2}' "$PLAN"; }
n_add=$(count ADD); n_same=$(count SAME); n_upd=$(count UPDATE); n_mod=$(count MODIFIED)
n_conf=$(count CONFLICT); n_rm=$(count REMOVE); n_keep=$(count KEEPOLD)

say ""; say "Plan:"
[ "$n_add" = 0 ]  || { say "  + añadir ($n_add):"; list ADD; }
[ "$n_upd" = 0 ]  || { say "  ~ actualizar archivos del kit sin modificar ($n_upd):"; list UPDATE; }
[ "$n_rm" = 0 ]   || { say "  - retirar archivos que ya no forman parte del kit ($n_rm):"; list REMOVE; }
if [ "$n_mod" != 0 ]; then
  if [ "$FORCE" = 1 ]; then say "  ! sustituir archivos del kit que modificaste, con copia ($n_mod):"
  else say "  ! se conservan tus modificaciones en archivos del kit ($n_mod) — usa --force para sustituirlos:"; fi
  list MODIFIED
fi
if [ "$n_conf" != 0 ]; then
  if [ "$FORCE" = 1 ]; then say "  ! sustituir archivos ajenos con el mismo nombre, con copia ($n_conf):"
  else say "  ! conflicto: existen archivos que no instaló el kit ($n_conf) — se omiten; usa --force para sustituirlos:"; fi
  list CONFLICT
fi
[ "$n_keep" = 0 ] || { say "  · archivos retirados del kit que modificaste; se conservan ($n_keep):"; list KEEPOLD; }
[ "$n_same" = 0 ] || say "  = sin cambios: $n_same"
case "$INSTR" in
  CREATE)  say "  + crear $CLAUDE_MD con el bloque SDD" ;;
  APPEND)  say "  ~ añadir el bloque SDD al final de $CLAUDE_MD (tu contenido se conserva)" ;;
  REPLACE) say "  ~ actualizar el bloque SDD de $CLAUDE_MD (entre marcadores ai-dev-kit)" ;;
  SAME)    say "  = bloque SDD de $CLAUDE_MD sin cambios" ;;
esac
case "$GUARD" in
  CREATE) say "  + crear $SETTINGS con el guard (hook PreToolUse)" ;;
  ADD)    say "  ~ añadir el guard (hook PreToolUse) a $SETTINGS; el resto de ajustes y hooks se conserva" ;;
  UPDATE) say "  ~ actualizar la entrada del guard en $SETTINGS" ;;
  SAME)   say "  = guard en $SETTINGS sin cambios" ;;
  NOJQ)   say "  ! guard NO instalado: falta jq (brew install jq · apt install jq)" ;;
esac

if [ "$DRY" = 1 ]; then say ""; say "--dry-run: no se ha modificado nada."; exit 0; fi

risky=$((n_upd + n_rm))
[ "$FORCE" = 1 ] && risky=$((risky + n_mod + n_conf))
case "$INSTR" in APPEND|REPLACE) risky=$((risky + 1)) ;; esac
case "$GUARD" in ADD|UPDATE) risky=$((risky + 1)) ;; esac
changes=$((n_add + risky))
[ "$INSTR" = CREATE ] && changes=$((changes + 1))
[ "$GUARD" = CREATE ] && changes=$((changes + 1))
if [ "$changes" = 0 ]; then
  say ""
  if [ $((n_mod + n_conf)) = 0 ]; then say "Nada que hacer: el kit ya está al día."
  else say "Nada que aplicar sin --force (ver conflictos y modificaciones del plan)."; fi
fi
[ "$risky" = 0 ] || { say ""; confirm "Se modificarán o retirarán archivos existentes (con copia de seguridad). ¿Continuar?"; }

# --- Aplicar -----------------------------------------------------------------
BACKUP_DIR="$STATE/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$STATE"
# Las copias de seguridad son personales: nunca deben versionarse con el proyecto.
[ -f "$STATE/.gitignore" ] || printf 'backups/\n' > "$STATE/.gitignore"
NEWMAN="$TMP/manifest"; : > "$NEWMAN"
install_file() {
  mkdir -p "$(dirname "$BASE/$1")"
  # En proyectos, no escribir a través de un enlace (ya rechazados por check_path).
  # En global se respeta un enlace del usuario (p. ej. a su repo de dotfiles).
  if [ "$MODE" = project ]; then rm -f "$BASE/$1"; fi
  cp "$KIT_DIR/$1" "$BASE/$1"
  if [ -x "$KIT_DIR/$1" ]; then chmod +x "$BASE/$1"; fi
}
while IFS="$TAB" read -r act rel; do
  case "$act" in
    ADD|UPDATE|SAME)
      [ "$act" = UPDATE ] && backup "$BASE/$rel" "$rel"
      [ "$act" = SAME ] || install_file "$rel"
      printf '%s\t%s\n' "$(sha "$KIT_DIR/$rel")" "$rel" >> "$NEWMAN" ;;
    MODIFIED|CONFLICT)
      if [ "$FORCE" = 1 ]; then
        backup "$BASE/$rel" "$rel"; install_file "$rel"
        printf '%s\t%s\n' "$(sha "$KIT_DIR/$rel")" "$rel" >> "$NEWMAN"
      elif [ "$act" = MODIFIED ]; then
        printf '%s\t%s\n' "$(manifest_hash "$rel")" "$rel" >> "$NEWMAN"
      fi ;;
    REMOVE)
      backup "$BASE/$rel" "$rel"; rm -f "$BASE/$rel"; prune_dirs "$rel" ;;
    KEEPOLD)
      printf '%s\t%s\n' "$(manifest_hash "$rel")" "$rel" >> "$NEWMAN" ;;
  esac
done < "$PLAN"

# Conserva las entradas de componentes que no se tocaron en esta ejecución.
if [ -f "$MANIFEST" ]; then
  while IFS="$TAB" read -r m rel; do
    case "$rel" in agents/*) want agents && continue ;; skills/*) want skills && continue ;; hooks/*) want guard && continue ;; esac
    printf '%s\t%s\n' "$m" "$rel" >> "$NEWMAN"
  done < "$MANIFEST"
fi

# Estado del bloque: sin rutas absolutas (el CLAUDE.md se deduce del modo).
case "$INSTR" in
  CREATE)
    cp "$BLOCK" "$CLAUDE_MD"; : > "$STATE/claude-md-created" ;;
  APPEND)
    backup "$CLAUDE_MD" "CLAUDE.md"
    if [ -s "$CLAUDE_MD" ] && [ -n "$(tail -c1 "$CLAUDE_MD")" ]; then
      : > "$STATE/claude-md-no-final-newline"; printf '\n' >> "$CLAUDE_MD"
    fi
    { printf '\n'; cat "$BLOCK"; } >> "$CLAUDE_MD" ;;
  REPLACE)
    backup "$CLAUDE_MD" "CLAUDE.md"
    awk -v s="$MARK_START" -v e="$MARK_END" -v f="$BLOCK" '
      $0==s {while ((getline l < f) > 0) print l; skip=1; next}
      skip && $0==e {skip=0; next}
      !skip {print}' "$CLAUDE_MD" > "$TMP/claude.new"
    cat "$TMP/claude.new" > "$CLAUDE_MD" ;;
esac

case "$GUARD" in
  CREATE) cp "$TMP/settings.new" "$SETTINGS"; : > "$STATE/settings-created" ;;
  ADD|UPDATE) backup "$SETTINGS" "settings.json"; cat "$TMP/settings.new" > "$SETTINGS" ;;
esac

LC_ALL=C sort -t "$TAB" -k2 "$NEWMAN" > "$MANIFEST"
echo "$VERSION" > "$STATE/VERSION"

# --- Informe -----------------------------------------------------------------
say ""; say "Instalación terminada."
say "  añadidos: $n_add · actualizados: $n_upd · retirados: $n_rm · sin cambios: $n_same"
if [ "$FORCE" != 1 ] && [ $((n_conf + n_mod)) != 0 ]; then
  say "  NO instalados por conflicto o modificación local: $((n_conf + n_mod)) (ver plan; --force para sustituir)"
fi
if [ -d "$BACKUP_DIR" ]; then say "  copias de seguridad: $BACKUP_DIR"; fi
say "  manifiesto: $MANIFEST"
[ "$GUARD" = NOJQ ] && say "  guard NO instalado (falta jq)"
case "$GUARD" in CREATE|ADD|UPDATE) say "  guard activo en $SETTINGS (se aplica a las sesiones nuevas de Claude Code)" ;; esac
say ""
say "Siguiente paso: ejecuta scripts/doctor.sh para comprobar las herramientas externas,"
say "y en tu proyecto abre Claude Code y ejecuta /sdd-init."
