#!/usr/bin/env bash
# Desinstala solo lo que instaló AI Dev Command Center (según su manifiesto).
# Uso: ./uninstall.sh [--global | --project DIR] [--dry-run] [--yes] [--force]
set -euo pipefail

KIT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
. "$KIT_DIR/lib/common.sh"

MODE=global; PROJECT_DIR=""; DRY=0; YES=0; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --global) MODE=global ;;
    --project) need_value "$1" $# "${2:-}"; MODE=project; PROJECT_DIR="$2"; shift ;;
    --dry-run) DRY=1 ;;
    --yes|-y) YES=1 ;;
    --force) FORCE=1 ;;
    -h|--help) sed -n '2,3p' "$0"; say "  --force también retira archivos del kit que modificaste (con copia)."; exit 0 ;;
    *) die "opción desconocida: $1" ;;
  esac
  shift
done

resolve_target
check_state
[ -f "$MANIFEST" ] || die "no hay instalación del kit en $BASE (falta $MANIFEST)"
validate_manifest
if [ "$MODE" = project ] && [ -L "$CLAUDE_MD" ]; then die "CLAUDE.md del proyecto es un enlace simbólico: $CLAUDE_MD"; fi
bstate=$(block_state "$CLAUDE_MD")
[ "$bstate" != broken ] || die "marcadores ai-dev-kit incompletos o duplicados en $CLAUDE_MD; corrígelos a mano (no se ha cambiado nada)"
say "Desinstalando AI Dev Command Center $(cat "$STATE/VERSION" 2>/dev/null) de $BASE"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PLAN="$TMP/plan"; : > "$PLAN"
while IFS="$TAB" read -r m rel; do
  check_path "$rel"
  dst="$BASE/$rel"
  if [ ! -e "$dst" ]; then act=GONE
  elif [ "$(sha "$dst")" = "$m" ]; then act=REMOVE
  elif [ "$FORCE" = 1 ]; then act=REMOVE
  else act=KEEP; fi
  printf '%s\t%s\n' "$act" "$rel" >> "$PLAN"
done < "$MANIFEST"

say ""; say "Plan:"
awk -F'\t' '$1=="REMOVE" {print "  - " $2}' "$PLAN"
awk -F'\t' '$1=="KEEP"   {print "  · se conserva (lo modificaste; --force para retirarlo): " $2}' "$PLAN"
awk -F'\t' '$1=="GONE"   {print "  · ya no existe: " $2}' "$PLAN"
[ "$bstate" = ok ] && say "  - quitar el bloque SDD de $CLAUDE_MD (el resto se conserva)"
SETTINGS="$BASE/settings.json"
guard_on=0
if [ -f "$SETTINGS" ] && grep -q "$GUARD_FILE" "$SETTINGS"; then
  command -v jq >/dev/null 2>&1 || die "el guard está en $SETTINGS y falta jq para quitarlo sin dañar el archivo; instala jq (no se ha cambiado nada)"
  if [ "$MODE" = project ] && [ -L "$SETTINGS" ]; then die "enlace simbólico en el destino: $SETTINGS"; fi
  guard_on=1; say "  - quitar el guard de $SETTINGS (el resto se conserva)"
fi
say "  No se tocan: otros agentes y skills, el resto de settings.json, memoria de proyectos ni specs."

if [ "$DRY" = 1 ]; then say ""; say "--dry-run: no se ha modificado nada."; exit 0; fi
confirm "¿Desinstalar?"

BACKUP_DIR="$STATE/backups/uninstall-$(date +%Y%m%d-%H%M%S)"
while IFS="$TAB" read -r act rel; do
  [ "$act" = REMOVE ] || continue
  backup "$BASE/$rel" "$rel"; rm -f "$BASE/$rel"; prune_dirs "$rel"
done < "$PLAN"

if [ "$bstate" = ok ]; then
  backup "$CLAUDE_MD" "CLAUDE.md"
  strip_block "$CLAUDE_MD" > "$TMP/claude.new"
  if [ -f "$STATE/claude-md-no-final-newline" ]; then
    # Quita exactamente el salto de línea que añadió el kit.
    sz=$(wc -c < "$TMP/claude.new" | tr -d ' ')
    if [ "$sz" -gt 0 ] && [ -z "$(tail -c1 "$TMP/claude.new")" ]; then
      head -c $((sz - 1)) "$TMP/claude.new" > "$TMP/claude.trim" && mv "$TMP/claude.trim" "$TMP/claude.new"
    fi
  fi
  # Solo se borra el archivo si lo creó el kit y no queda nada del usuario.
  if [ -f "$STATE/claude-md-created" ] && [ -z "$(tr -d '[:space:]' < "$TMP/claude.new")" ]; then rm -f "$CLAUDE_MD"
  else cat "$TMP/claude.new" > "$CLAUDE_MD"; fi
fi
rm -f "$STATE/claude-md-created" "$STATE/claude-md-no-final-newline"
if [ "$guard_on" = 1 ]; then
  backup "$SETTINGS" "settings.json"
  settings_without_guard "$SETTINGS" > "$TMP/settings.new" && cat "$TMP/settings.new" > "$SETTINGS"
  # Si el kit creó settings.json y ya no queda nada, se borra.
  if [ -f "$STATE/settings-created" ] && [ "$(jq -c . "$SETTINGS")" = '{}' ]; then rm -f "$SETTINGS"; fi
fi
rm -f "$STATE/settings-created"

kept=$(awk -F'\t' '$1=="KEEP"' "$PLAN" | wc -l | tr -d ' ')
if [ "$kept" = 0 ]; then rm -f "$MANIFEST" "$STATE/VERSION"
else awk -F'\t' 'NR==FNR && $1=="KEEP" {k[$2]=1; next} ($2 in k)' "$PLAN" "$MANIFEST" > "$TMP/m" && cat "$TMP/m" > "$MANIFEST"; fi

say ""; say "Desinstalación terminada."
say "  retirados: $(awk -F'\t' '$1=="REMOVE"' "$PLAN" | wc -l | tr -d ' ') · conservados por modificación: $kept"
if [ -d "$BACKUP_DIR" ]; then say "  copias de seguridad: $BACKUP_DIR"; fi
exit 0
