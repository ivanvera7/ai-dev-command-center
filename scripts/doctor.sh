#!/usr/bin/env bash
# Diagnóstico de AI Dev Command Center. Solo lee: no instala nada ni pide credenciales.
# Uso: scripts/doctor.sh [--project DIR]
set -u  # sin pipefail: grep -q en tuberías daría falsos negativos

PROJECT_DIR=""
[ "${1:-}" = "--project" ] && PROJECT_DIR="${2:-}"
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
missing_req=0

ok()   { printf '  [ok]    %s\n' "$*"; }
no()   { printf '  [falta] %s\n' "$*"; }
opt()  { printf '  [opc.]  %s\n' "$*"; }
hint() { printf '          → %s\n' "$*"; }

echo "Sistema: $(uname -s) $(uname -m) · bash ${BASH_VERSION}"
echo
echo "Requisitos"
if command -v claude >/dev/null 2>&1; then ok "Claude Code $(claude --version 2>/dev/null | head -1)"
else no "Claude Code"; hint "https://code.claude.com/docs (instalación oficial)"; missing_req=1; fi
if command -v git >/dev/null 2>&1; then ok "$(git --version)"; else no "git"; missing_req=1; fi
if command -v jq >/dev/null 2>&1; then ok "jq (usado por /sdd-init para el ajuste del orquestador)"
else no "jq"; hint "brew install jq · apt install jq"; missing_req=1; fi

echo
echo "Componentes del kit"
for scope in "$CFG" ${PROJECT_DIR:+"$PROJECT_DIR/.claude"}; do
  if [ -f "$scope/.ai-dev-kit/manifest" ]; then
    n_a=$(grep -c $'\tagents/' "$scope/.ai-dev-kit/manifest" || true)
    n_s=$(cut -f2 "$scope/.ai-dev-kit/manifest" | awk -F/ '$1=="skills"{print $2}' | sort -u | wc -l | tr -d ' ')
    ok "instalado en $scope (versión $(cat "$scope/.ai-dev-kit/VERSION" 2>/dev/null)): $n_a agentes, $n_s skills"
  elif [ -f "$scope/agents/sdd-orchestrator.md" ]; then
    opt "archivos SDD presentes en $scope sin manifiesto del kit (instalación manual): install.sh adoptará los idénticos y tratará los distintos como conflicto"
  else
    opt "no instalado en $scope"
  fi
done

if command -v jq >/dev/null 2>&1 && [ -s "$CFG/settings.json" ] \
   && jq -e '[.hooks.PreToolUse[]?.hooks[]?.command // ""] | any(contains("ai-dev-kit-guard"))' "$CFG/settings.json" >/dev/null 2>&1; then
  ok "guard activo en $CFG/settings.json"
else
  opt "guard no instalado en $CFG/settings.json"; hint "./install.sh (componente guard)"
fi

repo="${PROJECT_DIR:-.}"
if git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  root=$(git -C "$repo" rev-parse --show-toplevel)
  echo
  echo "Proyecto $root"
  hooks_dir=$(cd "$root" && git rev-parse --git-path hooks)
  case "$hooks_dir" in /*) ;; *) hooks_dir="$root/$hooks_dir" ;; esac
  for h in pre-commit pre-push; do
    if grep -q 'ai-dev-kit:' "$hooks_dir/$h" 2>/dev/null; then ok "hook $h del kit"
    else opt "hook $h del kit no instalado"; hint "/sdd-init (o bash <skills>/sdd-init/scripts/setup-project.sh)"; fi
  done
  if grep -Evq '^[[:space:]]*(#|$)' "$root/.sdd/checks" 2>/dev/null; then ok ".sdd/checks: $(grep -Evc '^[[:space:]]*(#|$)' "$root/.sdd/checks") comando(s)"
  else opt ".sdd/checks vacío o ausente"; fi
  [ -f "$root/.github/workflows/sdd-checks.yml" ] && ok "CI sdd-checks" || opt "sin CI sdd-checks"
  if command -v jq >/dev/null 2>&1 && [ -s "$root/.claude/settings.json" ] \
     && jq -e '[.hooks.PreToolUse[]?.hooks[]?.command // ""] | any(contains("ai-dev-kit-guard"))' "$root/.claude/settings.json" >/dev/null 2>&1; then
    ok "guard del proyecto en .claude/settings.json"
  fi
  if [ "$(git -C "$root" config --local --get sdd.autoPush 2>/dev/null)" = true ]; then ok "push automático activado en este clon"
  else opt "push automático desactivado en este clon"; fi
fi

echo
echo "Herramientas externas (opcionales; el kit funciona sin ellas con menos capacidades)"
plugins=""
command -v claude >/dev/null 2>&1 && plugins=$(claude plugin list 2>/dev/null || true)
plugin() { # $1 nombre, $2 descripción, $3 cómo instalar
  if printf '%s' "$plugins" | grep -q "❯ $1@"; then
    ok "$1: $(printf '%s' "$plugins" | grep -A1 "❯ $1@" | awk '/Version:/ {print "v" $2}') — $2"
  else opt "$1 no detectado — $2"; hint "$3"; fi
}
plugin superpowers "procedimientos: brainstorming, TDD, depuración, revisión" "/plugin install superpowers@claude-plugins-official"
plugin context7 "documentación de librerías por versión (MCP)" "/plugin marketplace add upstash/context7 && /plugin install context7@context7-marketplace"
plugin caveman "respuestas compactas" "/plugin marketplace add JuliusBrussee/caveman && /plugin install caveman@caveman  (solo esta fuente oficial)"
plugin ponytail "cambio mínimo completo" "/plugin marketplace add DietrichGebert/ponytail && /plugin install ponytail@ponytail"

# Se captura la salida antes de grep: con pipefail, grep -q provocaría SIGPIPE.
rtk_help=$(command -v rtk >/dev/null 2>&1 && rtk --help 2>/dev/null || true)
if printf '%s\n' "$rtk_help" | grep -qi 'token'; then
  rtk_show=$(rtk init -g --show 2>/dev/null || true)
  if printf '%s\n' "$rtk_show" | grep -q '\[ok\] Hook'; then ok "RTK $(rtk --version 2>/dev/null | awk '{print $2}') con hook de Claude Code"
  else opt "RTK instalado pero sin hook de Claude Code"; hint "rtk init -g"; fi
else
  opt "RTK no detectado — reduce la salida de comandos"; hint "brew install rtk-ai/tap/rtk && rtk init -g  (ver github.com/rtk-ai/rtk)"
fi

fd=""
for d in "$CFG/skills/frontend-design" ${PROJECT_DIR:+"$PROJECT_DIR/.claude/skills/frontend-design"}; do [ -f "$d/SKILL.md" ] && fd="$d"; done
[ -z "$fd" ] && fd=$(find "$CFG/plugins/cache" -path '*skills/frontend-design/SKILL.md' 2>/dev/null | head -1)
if [ -n "$fd" ]; then ok "frontend-design: ${fd%/SKILL.md}"
else opt "frontend-design no detectado — guía visual de frontend-specialist"; hint "npx skills add anthropics/skills --skill frontend-design  (o el plugin oficial de Anthropic)"; fi

if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then ok "gh autenticado (necesario solo para PR y comprobar protecciones de rama)"
  else opt "gh instalado sin autenticar"; hint "gh auth login"; fi
else opt "gh no detectado — solo para PR y protecciones de rama"; hint "brew install gh"; fi

echo
if [ "$missing_req" = 1 ]; then echo "Faltan requisitos."; exit 1; fi
echo "Requisitos completos."
