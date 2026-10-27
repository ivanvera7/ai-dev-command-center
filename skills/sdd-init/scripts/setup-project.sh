#!/usr/bin/env bash
# Configura las salvaguardas de AI Dev Command Center en el repositorio actual.
# Lo ejecuta /sdd-init; es idempotente y se puede repetir para reparar o actualizar.
# Uso: setup-project.sh [--ci] [--dry-run]
#   --ci       crea .github/workflows/sdd-checks.yml si no existe
#   --dry-run  muestra lo que haría sin cambiar nada
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TPL="$HERE/../templates"
PREFLIGHT_SRC="$HERE/../../sdd-release/scripts/preflight.sh"
CI=0; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --ci) CI=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "opción desconocida: $1" >&2; exit 2 ;;
  esac
  shift
done

root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "ERROR: no es un repositorio git (ejecuta git init primero)" >&2; exit 1; }
cd "$root"
[ -f "$PREFLIGHT_SRC" ] || { echo "ERROR: no encuentro preflight.sh del kit en $PREFLIGHT_SRC" >&2; exit 1; }

done_=""; warn_=""
did()  { done_="$done_
  ✓ $*"; }
note() { warn_="$warn_
  ! $*"; }
run()  { if [ "$DRY" = 1 ]; then return 0; fi; "$@"; }

# 1. .sdd/: preflight y comprobaciones de calidad
run mkdir -p .sdd
if [ ! -f .sdd/preflight.sh ]; then run cp "$PREFLIGHT_SRC" .sdd/preflight.sh; did ".sdd/preflight.sh creado"
elif ! cmp -s "$PREFLIGHT_SRC" .sdd/preflight.sh; then run cp "$PREFLIGHT_SRC" .sdd/preflight.sh; did ".sdd/preflight.sh actualizado a la versión del kit"
else did ".sdd/preflight.sh al día"; fi
run chmod +x .sdd/preflight.sh 2>/dev/null || true
if [ ! -f .sdd/checks ]; then
  run cp "$TPL/checks" .sdd/checks; did ".sdd/checks creado"
fi
if ! grep -Evq '^[[:space:]]*(#|$)' .sdd/checks 2>/dev/null; then
  note ".sdd/checks no tiene comandos: añade los de pruebas, tipos y lint del proyecto (los usan pre-push y CI)"
fi

# 2. Hooks de Git (por clon; no se versionan ni se heredan al clonar)
if hp=$(git config --get core.hooksPath); then
  run mkdir -p .sdd/git-hooks
  for h in pre-commit pre-push; do run cp "$TPL/git-hooks/$h" ".sdd/git-hooks/$h"; run chmod +x ".sdd/git-hooks/$h"; done
  note "core.hooksPath='$hp' (husky, lefthook…): no se tocan tus hooks. Llama a los del kit desde los tuyos: 'bash .sdd/git-hooks/pre-commit' en pre-commit y 'bash .sdd/git-hooks/pre-push \"\$@\"' en pre-push"
else
  hooks_dir=$(git rev-parse --git-path hooks)
  run mkdir -p "$hooks_dir"
  for h in pre-commit pre-push; do
    dst="$hooks_dir/$h"
    if [ ! -e "$dst" ]; then
      run cp "$TPL/git-hooks/$h" "$dst"; run chmod +x "$dst"; did "hook $h instalado"
    elif grep -q 'ai-dev-kit:' "$dst" 2>/dev/null; then
      if cmp -s "$TPL/git-hooks/$h" "$dst"; then did "hook $h al día"
      else run cp "$TPL/git-hooks/$h" "$dst"; run chmod +x "$dst"; did "hook $h actualizado"; fi
    else
      run cp "$TPL/git-hooks/$h" "$dst.ai-dev-kit"; run chmod +x "$dst.ai-dev-kit"
      note "ya existe un hook $h ajeno: no se toca. El del kit queda en $dst.ai-dev-kit; llámalo desde el tuyo"
    fi
  done
fi

# 3. .gitignore seguro
ensure_ignore() {
  grep -qxF "$1" .gitignore 2>/dev/null && return 0
  if [ "$DRY" = 0 ]; then
    if [ -s .gitignore ] && [ -n "$(tail -c1 .gitignore)" ]; then printf '\n' >> .gitignore; fi
    grep -qxF '# ai-dev-kit' .gitignore 2>/dev/null || printf '# ai-dev-kit\n' >> .gitignore
    printf '%s\n' "$1" >> .gitignore
  fi
  did ".gitignore: $1"
}
for p in .env '.env.*' '!.env.example' .envrc '*.pem' '*.key' .claude/settings.local.json .claude/.ai-dev-kit/backups/; do ensure_ignore "$p"; done

# 4. Orquestador como agente por defecto de este clon
if command -v jq >/dev/null 2>&1; then
  f=.claude/settings.local.json
  if [ "$DRY" = 0 ]; then
    mkdir -p .claude; [ -s "$f" ] || echo '{}' > "$f"
    jq '.agent //= "sdd-orchestrator"' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    a=$(jq -r .agent "$f")
  else a=$( [ -f "$f" ] && jq -r '.agent // "sdd-orchestrator"' "$f" || echo sdd-orchestrator); fi
  if [ "$a" = sdd-orchestrator ]; then did "claude arranca como sdd-orchestrator en este repo"
  else note "$f ya fija el agente '$a'; no se cambia"; fi
else
  note "falta jq: no se fijó sdd-orchestrator como agente por defecto (usa claude --agent sdd-orchestrator)"
fi

# 5. CI
if [ "$CI" = 1 ]; then
  wf=.github/workflows/sdd-checks.yml
  if [ -e "$wf" ]; then did "$wf ya existe; no se toca"
  else run mkdir -p .github/workflows; run cp "$TPL/sdd-checks.yml" "$wf"; did "$wf creado (añade la preparación del entorno si los checks la necesitan)"; fi
fi

# 6. Push automático: solo informa; activarlo es decisión del usuario
case "$(git config --local --get sdd.autoPush || echo unset)" in
  true) did "push automático ACTIVADO en este clon (sdd.autoPush=true)" ;;
  *) did "push automático desactivado (para activarlo, el usuario escribe: ! git config --local sdd.autoPush true)" ;;
esac

[ "$DRY" = 1 ] && echo "--dry-run: no se ha modificado nada."
echo "Salvaguardas del proyecto en $root:$done_"
[ -z "$warn_" ] || echo "Pendiente:$warn_"
exit 0
