#!/usr/bin/env bash
# AI Dev Command Center — guard (hook PreToolUse de Claude Code).
# Lee la llamada a la herramienta en JSON por stdin y responde:
#   deny → acción destructiva o que salta las salvaguardas (el humano puede hacerla con "!")
#   ask  → acción con riesgo que requiere confirmación del usuario
#   nada → sigue el flujo normal de permisos
# Heurístico: analiza texto, no ejecuta nada. Desactivar: AI_DEV_KIT_GUARD=off al lanzar claude.
set -uf  # -f: sin expansión de comodines al analizar argumentos

[ "${AI_DEV_KIT_GUARD:-on}" = off ] && exit 0
if ! command -v jq >/dev/null 2>&1; then
  echo "ai-dev-kit guard: falta jq; el guard no puede evaluar comandos" >&2
  exit 0
fi

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$cwd" ] || cwd=$PWD

HINT=" Si de verdad hace falta, pide al usuario que lo ejecute él mismo (prefijo ! en Claude Code o su terminal)."
decide() { # $1 deny|ask, $2 motivo
  jq -n --arg d "$1" --arg r "[ai-dev-kit guard] $2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
  exit 0
}
deny() { decide deny "$1$HINT"; }
ask()  { decide ask "$1"; }

# --- Edit / Write / NotebookEdit ---------------------------------------------
if [ "$tool" != Bash ]; then
  f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
  [ -n "$f" ] || exit 0
  case "$f" in
    */.git/hooks/*|.git/hooks/*) deny "No se editan los hooks de Git: son la puerta de calidad del proyecto." ;;
    */.git/config|.git/config) deny "No se edita .git/config a mano (hooksPath, sdd.autoPush…)." ;;
    *ai-dev-kit-guard.sh) deny "No se edita el guard del kit." ;;
    */.claude/settings.json|*/.claude/settings.local.json|.claude/settings.json|.claude/settings.local.json)
      ask "Vas a modificar la configuración de Claude Code ($f), que incluye permisos y hooks de seguridad." ;;
    */.sdd/*|.sdd/*|*/.github/workflows/*|.github/workflows/*|*/.husky/*|.husky/*|*/lefthook.yml|lefthook.yml|*/CODEOWNERS|CODEOWNERS)
      ask "Vas a modificar una puerta de calidad ($f): comandos de comprobación, escaneo de secretos, CI o hooks." ;;
  esac
  exit 0
fi

# --- Bash ----------------------------------------------------------------------
raw=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
raw=$(printf '%s' "$raw" | tr '\n' ';')   # tras $( ) sin el salto final, que rompería las anclas $
[ -n "$raw" ] || exit 0
# Sin el contenido entre comillas: evita falsos positivos en mensajes y textos.
bare=$(printf '%s' "$raw" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")
# Sin las comillas pero con su contenido: para rutas y argumentos.
unq=$(printf '%s' "$raw" | tr -d "\"'")
# Si el comando lanza otra shell o eval, el texto entre comillas también es código.
texts="$bare"
if printf '%s' "$raw" | grep -Eq '(^|[^A-Za-z0-9_])((ba|z|da|k)?sh[[:space:]]+-[a-z]*c|eval[[:space:]]|xargs[[:space:]])'; then
  texts="$bare
$unq"
fi
has() { printf '%s\n' "$texts" | grep -Eq "$1"; }
hasi() { printf '%s\n' "$raw" | grep -Eiq "$1"; }

W='(^|[^A-Za-z0-9_.-])'    # inicio de palabra de comando (admite /usr/bin/git)
E='([[:space:]=;&|)<>`]|$)' # fin de opción
S='[^;&|]*'                 # resto del mismo comando simple
G="${W}git[[:space:]]${S}"

# Git: saltarse o desactivar salvaguardas
has "${G}--no-verify" && deny "--no-verify salta los hooks de Git (puerta de calidad)."
has "${G}commit([[:space:]]${S})?[[:space:]]-[A-Za-z]*n[A-Za-z]*${E}" && deny "git commit -n salta los hooks de Git."
has "${W}git[[:space:]]+(${S}[[:space:]])?-c[[:space:]]*core\.hooksPath" && deny "Cambiar core.hooksPath desactiva los hooks de Git."
printf '%s\n' "$unq" | grep -Eiq "${W}git[[:space:]]${S}config([[:space:]]${S})?[[:space:]](--unset[[:space:]]+)?core\.hookspath([[:space:]=]+[^-[:space:];&|]|[[:space:]]*$|[[:space:]]*[;&|])" \
  && ! has "${G}config${S}--get" && deny "Cambiar core.hooksPath desactiva los hooks de Git."
printf '%s\n' "$unq" | grep -Eiq "${W}git[[:space:]]${S}config([[:space:]]${S})?[[:space:]]sdd\.autopush([[:space:]]+|=)(true|yes|on|1)${E}" \
  && deny "Solo el usuario puede activar el push automático: debe escribir '! git config --local sdd.autoPush true'."

# No ocultar que el comando lo lanza Claude Code (los hooks de Git lo usan)
printf '%s\n' "$raw" | grep -Eq "(unset[[:space:]]${S}CLAUDECODE|${W}CLAUDECODE=|-u[[:space:]]*CLAUDECODE|${W}env[[:space:]]+(-[A-Za-z]*[[:space:]]+)*-[A-Za-z]*i([[:space:]]|$))" \
  && deny "No se oculta ni se borra CLAUDECODE: los hooks de Git lo usan para aplicar las reglas del agente."

# Git: reescribir o destruir historial y trabajo
has "${G}push([[:space:]]${S})?[[:space:]](--force|--force-with-lease|--force-if-includes|--mirror|--delete|--prune|-[A-Za-z]*[fd][A-Za-z]*|\+[^[:space:]]+|:[^[:space:]]+)${E}" \
  && deny "Push forzado o de borrado: reescribe o elimina historial remoto."
has "${G}reset([[:space:]]${S})?[[:space:]]--hard" && deny "git reset --hard descarta trabajo sin confirmar."
has "${G}clean([[:space:]]${S})?[[:space:]](-[A-Za-z]*f|--force)" && deny "git clean -f borra archivos no rastreados."
if has "${G}(checkout|restore)([[:space:]]${S})?[[:space:]](--[[:space:]]+)?(\.|:/)${E}" \
   && ! { has "${G}restore${S}--staged" && ! has "${G}restore${S}--worktree"; }; then
  deny "Descarta todos los cambios sin confirmar del árbol."
fi
has "${G}(checkout|switch)([[:space:]]${S})?[[:space:]](-f|--force|--discard-changes)${E}" && deny "Cambia de rama descartando cambios sin confirmar."
has "${G}branch([[:space:]]${S})?[[:space:]]-[A-Za-z]*D" && deny "git branch -D borra una rama sin comprobar si está fusionada."
has "${G}branch${S}(--delete|-d)${S}(--force|-f)${E}" && deny "Borra una rama sin comprobar si está fusionada."
has "${G}branch${S}(--force|-f)${S}(--delete|-d)${E}" && deny "Borra una rama sin comprobar si está fusionada."
has "${G}stash[[:space:]]+(drop|clear)" && deny "Borra cambios guardados en el stash."
has "${G}(filter-branch|filter-repo|reflog[[:space:]]+expire|update-ref[[:space:]]+-d)" && deny "Reescribe o elimina historial."
has "${W}gh[[:space:]]${S}(repo[[:space:]]+(delete|archive|rename)|repo[[:space:]]+edit${S}--visibility|release[[:space:]]+delete|secret[[:space:]]+(set|delete)|api${S}(-X|--method)[[:space:]]*DELETE)" \
  && deny "Operación de GitHub irreversible o sobre secretos/visibilidad."

# Hooks de Git y guard: no se modifican desde Bash
if has '\.git/hooks|ai-dev-kit-guard'; then
  has "(>|${W}(rm|mv|cp|chmod|tee|ln|truncate|install)[[:space:]]|sed[[:space:]]+-i)" && deny "No se modifican los hooks de Git ni el guard."
fi

# Escritura por Bash en puertas de calidad o en la configuración de Claude Code
WRITE="(>|${W}(rm|mv|cp|tee|truncate|install|ln)[[:space:]]|sed[[:space:]]+-i|perl[[:space:]]+-[A-Za-z]*i)"
if printf '%s\n' "$unq" | grep -Eq '\.claude/settings[^[:space:]]*\.json'; then
  has "$WRITE" && ask "Modifica la configuración de Claude Code (permisos y hooks de seguridad) desde Bash."
fi
if printf '%s\n' "$unq" | grep -Eq '(^|[^A-Za-z0-9_])(\.sdd/|\.github/workflows|\.husky/|lefthook\.yml)'; then
  has "$WRITE" && ask "Modifica una puerta de calidad (.sdd, CI o hooks) desde Bash."
fi

# Scripts remotos
has "(curl|wget)${S}\|[[:space:]]*(sudo[[:space:]]+)?((ba|z|da)?sh|python3?|node|perl|ruby|php)([[:space:]]|$)" && deny "Ejecutar un script descargado de internet sin revisarlo."
printf '%s' "$raw" | grep -Eq '(ba|z)?sh[[:space:]]+(-c[[:space:]]+)?["]?(<\(|\$\()[[:space:]]*(curl|wget)' && deny "Ejecutar un script descargado de internet sin revisarlo."

# rm recursivo: raíz, home, fuera del proyecto o comodines amplios
rm_check() {
  local seg tok abs
  printf '%s\n' "$unq" | tr ';&|' '\n\n\n' | while IFS= read -r seg; do
    printf '%s\n' "$seg" | grep -Eq "${W}rm[[:space:]]" || continue
    printf '%s\n' "$seg" | grep -Eq "[[:space:]](-[A-Za-z]*[rR][A-Za-z]*|--recursive)([[:space:]]|$)" || continue
    if printf '%s\n' "$seg" | grep -Eq "${W}xargs[[:space:]]"; then echo "rm -r con xargs sobre una variable (rutas que no se ven)"; return; fi
    for tok in $(printf '%s\n' "$seg" | sed -E "s#.*${W}rm[[:space:]]##"); do
      case "$tok" in -*) continue ;; esac
      case "$tok" in
        /|/\*|'~'|'~/'|'~/*'|\$HOME|\$HOME/|\$HOME/\*|\$\{HOME\}|.|./|./\*|\*|..|../|../*|*/..|*/../*) echo "rm -r sobre '$tok'"; return ;;
        .git|.git/|*/.git|*/.git/) echo "rm -r sobre '$tok' (historial y hooks del repositorio)"; return ;;
        \$TMPDIR/?*|\$\{TMPDIR\}/?*) continue ;;
        \$*|*\$*|*\`*) echo "rm -r sobre una variable o un comando ('$tok')"; return ;;
      esac
      case "$tok" in "~/"*) abs="$HOME/${tok#\~/}" ;; /*) abs="$tok" ;; *) continue ;; esac
      case "$abs" in
        "$cwd"/?*|"${CLAUDE_PROJECT_DIR:-/nonexistent}"/?*|/tmp/?*|/private/tmp/?*|/var/folders/?*|/private/var/folders/?*) ;;
        "${TMPDIR:-/nonexistent}"?*) ;;
        *) echo "rm -r fuera del proyecto ('$tok')"; return ;;
      esac
    done
  done
}
r=""
# Solo si hay un rm -r fuera de comillas (evita falsos positivos en textos como echo "rm -rf /").
if printf '%s\n' "$bare" | grep -Eq "${W}rm[[:space:]][^;&|]*(-[A-Za-z]*[rR][A-Za-z]*|--recursive)([[:space:]]|;|$)" \
   || [ "$texts" != "$bare" ]; then r=$(rm_check); fi
# rm -r tras cambiar a la raíz, al home o fuera del proyecto
if [ -z "$r" ] && has "${W}cd[[:space:]]+(/|~|\\\$HOME|\.\.)([[:space:]/;&|]|$)" && has "${W}rm[[:space:]]${S}(-[A-Za-z]*[rR]|--recursive)"; then
  r="rm -r después de cambiar a la raíz, al home o fuera del proyecto"
fi
case "$r" in
  *variable*|*xargs*) ask "$r: comprueba a qué ruta apunta antes de borrar." ;;
  ?*) deny "$r." ;;
esac

# find que borra
if has "${W}find[[:space:]]${S}(-delete|-exec[[:space:]]+rm[[:space:]])"; then
  if has "${W}find[[:space:]]+(/|~|\\\$HOME|\.\.)([[:space:]/]|$)"; then deny "find que borra sobre la raíz, el home o fuera del proyecto."
  else ask "find que borra archivos: comprueba qué rutas encuentra antes."; fi
fi

# Confirmación del usuario: bases de datos
if hasi "${W}(psql|mysql|mariadb|sqlite3|mongosh|mongo|redis-cli|cqlsh|sqlcmd|clickhouse-client)[[:space:]]" \
   && hasi "(drop[[:space:]]+(database|schema|table|collection)|truncate([[:space:]]|$)|delete[[:space:]]+from|flushall|flushdb|dropdatabase)"; then
  ask "Operación destructiva en una base de datos. Confirma que es una base local o de prueba."
fi
has "${W}(dropdb[[:space:]]|prisma[[:space:]]+migrate[[:space:]]+reset|prisma[[:space:]]+db[[:space:]]+push${S}(--force-reset|--accept-data-loss)|(rails|rake)[[:space:]]+db:(drop|reset|purge)|manage\.py[[:space:]]+flush|sequelize[[:space:]]+db:drop)" \
  && ask "Operación destructiva en una base de datos. Confirma que es una base local o de prueba."

# Confirmación del usuario: publicar o desplegar
has "${W}((npm|pnpm|yarn|bun)[[:space:]]+publish|cargo[[:space:]]+publish|twine[[:space:]]+upload|gem[[:space:]]+push|docker[[:space:]]+push|gh[[:space:]]+release[[:space:]]+create|terraform[[:space:]]+(apply|destroy)|pulumi[[:space:]]+(up|destroy)|kubectl[[:space:]]+(apply|delete|replace|scale|rollout|patch)|helm[[:space:]]+(install|upgrade|uninstall|rollback)|(fly|flyctl)[[:space:]]+deploy|vercel${S}--prod|netlify[[:space:]]+deploy${S}--prod|heroku[[:space:]]+(apps:destroy|pg:reset|releases:rollback|config:(set|unset))|firebase[[:space:]]+deploy|serverless[[:space:]]+deploy|sls[[:space:]]+deploy|eb[[:space:]]+deploy)" \
  && ask "Publica o despliega fuera de tu máquina. Confirma destino y versión."

# Confirmación del usuario: dependencias nuevas
DEP="${W}((npm|pnpm|bun)[[:space:]]+(i|install|add)([[:space:]]+-[^[:space:];&|]+)*[[:space:]]+[^-[:space:];&|]|yarn[[:space:]]+(global[[:space:]]+)?add[[:space:]]|pip3?[[:space:]]+install[[:space:]]|uv[[:space:]]+(add|pip[[:space:]]+install|tool[[:space:]]+install)[[:space:]]|poetry[[:space:]]+add[[:space:]]|pipx[[:space:]]+install[[:space:]]|cargo[[:space:]]+(add|install)[[:space:]]|go[[:space:]]+(get|install)[[:space:]]|gem[[:space:]]+install[[:space:]]|brew[[:space:]]+install[[:space:]]|composer[[:space:]]+require[[:space:]]|dotnet[[:space:]]+add${S}package)"
if has "$DEP"; then
  # pip install -r/-e ./. instala lo ya declarado en el proyecto
  if ! has "pip3?[[:space:]]+install[[:space:]]+(-r|--requirement|-e[[:space:]]+\.|\.([[:space:]]|$))" || has "${W}(npm|pnpm|bun|yarn|uv|poetry|cargo|go|gem|brew|composer|dotnet)[[:space:]]"; then
    ask "Añade una dependencia. Antes: comprueba que existe en el registro oficial, quién la mantiene, que no es un nombre parecido a uno conocido, y justifícala en el plan."
  fi
fi

has "${W}((npx|npm[[:space:]]+exec)[[:space:]]+(${S}[[:space:]])?(-y|--yes)${E}|bunx[[:space:]]|uvx[[:space:]]|pipx[[:space:]]+run[[:space:]]|(pnpm|yarn)[[:space:]]+dlx[[:space:]]|(npm|pnpm|yarn|bun)[[:space:]]+create[[:space:]])" \
  && ask "Descarga y ejecuta un paquete que no está en el proyecto. Comprueba que es el paquete oficial."
has "${W}docker[[:space:]]${S}(compose${S}down${S}(-v|--volumes)|volume[[:space:]]+(rm|prune)|system[[:space:]]+prune)" \
  && ask "Borra volúmenes o datos de Docker."
has "${W}sudo[[:space:]]" && ask "Ejecuta con privilegios de administrador."
exit 0
