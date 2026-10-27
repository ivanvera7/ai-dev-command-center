#!/usr/bin/env bash
# SDD release preflight: comprobaciones deterministas antes de commit/push.
# Uso:
#   preflight.sh                       # revisa lo que está en staging + rama/remoto
#   preflight.sh --scan-only           # solo escanea secretos en staging, cambios sin confirmar y no rastreados
#   preflight.sh --expected-remote URL # además exige que origin apunte a URL
#   preflight.sh --push                # además exige `git config sdd.autoPush true` y bloquea la rama por defecto
# Salida: 0 = sin bloqueos, 1 = bloqueos, 2 = no es un repo git o argumento inválido.
# Nunca imprime el contenido de un posible secreto: solo archivo:línea.
set -uo pipefail

scan_only=0; expected_remote=""; for_push=0
while [ $# -gt 0 ]; do
  case "$1" in
    --scan-only) scan_only=1 ;;
    --push) for_push=1 ;;
    --expected-remote) expected_remote="${2:-}"; [ -n "$expected_remote" ] || { echo "falta la URL de --expected-remote" >&2; exit 2; }; shift ;;
    *) echo "argumento desconocido: $1" >&2; exit 2 ;;
  esac
  shift
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "BLOQUEO: no es un repositorio git"; exit 2; }

blocks=0
block() { echo "BLOQUEO: $*"; blocks=$((blocks+1)); }
warn()  { echo "AVISO: $*"; }

# Nombres de archivo que nunca deben versionarse.
bad_name='(^|/)(\.env(\.[^/]*)?|\.envrc|id_(rsa|dsa|ecdsa|ed25519)|[^/]*\.(pem|key|p12|pfx|keystore|jks|ppk|tfstate|tfstate\.backup|tfvars)|AuthKey_[^/]*\.p8|credentials\.json|service-account[^/]*\.json|\.npmrc|\.pypirc|\.netrc|\.git-credentials|\.aws/credentials|\.docker/config\.json|\.claude/settings\.local\.json)$'
allowed_name='(^|/)(\.env\.(example|sample|template)|[^/]*\.tfvars\.(example|sample))$'
# Patrones de proveedor: bloquean siempre, aunque la línea contenga otras cosas.
provider_re='AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{40,}|glpat-[A-Za-z0-9_-]{20,}|npm_[A-Za-z0-9]{36}|sk-(ant-|proj-)?[A-Za-z0-9_-]{20,}|[sr]k_(live|test)_[A-Za-z0-9]{20,}|xox[abpr]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.|[Bb]earer [A-Za-z0-9._~+/-]{20,}|[a-zA-Z][a-zA-Z0-9+.-]*://[^/:@[:space:]]+:[^/@[:space:]$]+@'
# Regla genérica de asignación (sin distinguir mayúsculas): clave sensible = valor de 8+ caracteres.
generic_re='(password|passwd|pwd|secret|api[_-]?key|access[_-]?key|token)[a-z0-9_]*["'"'"']?[[:space:]]*[:=][[:space:]]*(["'"'"'][^"'"'"'[:space:]]{8,}["'"'"']|[A-Za-z0-9_+/=.-]{8,}([[:space:]]|$))'
# Si el VALOR asignado es una referencia a una variable, no es un secreto.
ref_re='process\.env|os\.environ|getenv|ENV\[|\$\{|\$[A-Za-z_]|secrets\.|<[A-Za-z_-]+>'

# Diff sin conversiones: ni textconv, ni diff externo, ni atributos -diff ocultan contenido.
plain_diff() { git -c core.quotepath=off diff --no-ext-diff --no-textconv --text --no-color -U0 "$@"; }

# Líneas añadidas como "archivo:línea<TAB>contenido". Sigue el estado de cada hunk
# para no confundir una línea añadida que empiece por "++" con una cabecera.
added_lines() {
  plain_diff "$@" | awk '
    function cnt(x,  a) { if (split(x, a, ",") < 2) return 1; return a[2] + 0 }
    left_old > 0 || left_new > 0 {
      c = substr($0, 1, 1)
      if (c == "-") { left_old--; next }
      if (c == "+") { print f ":" n "\t" substr($0, 2); n++; left_new--; next }
      if (c == "\\") next
    }
    /^\+\+\+ / { f = substr($0, 5); sub(/^b\//, "", f); sub(/\t$/, "", f); next }
    /^@@ / {
      o = $2; sub(/^-/, "", o); left_old = cnt(o)
      s = $3; sub(/^\+/, "", s); left_new = cnt(s); split(s, a, ","); n = a[1]
      next
    }'
}

# Lee "ubicación<TAB>contenido" y escribe la ubicación de cada línea sospechosa.
# Un grep sobre todo el flujo; solo las pocas candidatas a la regla genérica se miran una a una.
detect() {
  local buf loc line m
  buf=$(mktemp)
  cat > "$buf"
  {
    grep -Ea "$provider_re" "$buf" | cut -f1
    grep -Eai "$generic_re" "$buf" | while IFS="$(printf '\t')" read -r loc line; do
      m=$(printf '%s\n' "$line" | grep -Eaio "$generic_re" | grep -Eaiv "$ref_re" || true)
      [ -n "$m" ] && echo "$loc"
    done
  } | awk '!seen[$0]++'
  rm -f "$buf"
  return 0
}

scan() { # $1 = etiqueta, resto = argumentos de git diff
  local label="$1"; shift
  local f hits
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if echo "$f" | grep -Eq "$bad_name" && ! echo "$f" | grep -Eq "$allowed_name"; then
      block "$label: archivo sensible '$f'"
    fi
  done <<< "$(git -c core.quotepath=off diff "$@" --name-only --diff-filter=ACMR)"
  hits=$(added_lines "$@" | detect)
  [ -n "$hits" ] && block "$label: posible secreto en:"$'\n'"$(echo "$hits" | sed 's/^/    /')"
}

scan "staging" --cached
if [ "$scan_only" = 1 ]; then
  git rev-parse --verify -q HEAD >/dev/null && scan "sin confirmar" HEAD
  # Archivos no rastreados (respetando .gitignore): nombre y contenido, también binarios.
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if echo "$f" | grep -Eq "$bad_name" && ! echo "$f" | grep -Eq "$allowed_name"; then block "no rastreado: archivo sensible '$f'"; fi
    if [ -f "$f" ]; then
      # tr: un byte NUL cortaría la línea en awk y ocultaría lo que viene después.
      h=$(tr '\000' ' ' < "$f" 2>/dev/null | awk '{print NR "\t" $0}' | detect | head -5 | tr '\n' ',' | sed 's/,$//')
      [ -n "$h" ] && block "no rastreado: posible secreto en '$f' (líneas $h)"
    fi
  done <<< "$(git -c core.quotepath=off ls-files --others --exclude-standard)"
  [ "$blocks" -eq 0 ] && echo "OK: sin secretos detectados" && exit 0
  exit 1
fi

branch=$(git symbolic-ref --short -q HEAD || true)
[ -z "$branch" ] && block "HEAD desacoplado; cambia a una rama de trabajo"
echo "rama: ${branch:-<detached>}"

remote_url=$(git remote get-url origin 2>/dev/null || true)
if [ -z "$remote_url" ]; then
  warn "no hay remoto 'origin': el push no es posible; se puede dejar el commit local"
  [ -n "$expected_remote" ] && block "se esperaba el remoto indicado pero no existe 'origin'"
else
  echo "origin: $(echo "$remote_url" | sed -E 's#://[^@/]*@#://[credenciales]@#')"
  if [ -n "$expected_remote" ] && [ "$remote_url" != "$expected_remote" ]; then
    block "origin no coincide con el remoto esperado"
  fi
fi

upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
echo "upstream: ${upstream:-<ninguno; el primer push usará -u origin $branch>}"

if [ "$for_push" = 1 ] && [ "$(git config --local --get sdd.autoPush || true)" != true ]; then
  block "push automático no activado en este clon (git config --local sdd.autoPush true lo activa; /sdd-init lo pregunta)"
fi
default_branch=$(git symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
case "$branch" in
  main|master|"$default_branch")
    if [ "$for_push" = 1 ]; then block "rama '$branch' es la rama por defecto: el push automático solo se hace a ramas de trabajo"
    else warn "rama '$branch' es la rama por defecto; publica desde una rama de trabajo"; fi ;;
  develop|production|prod|release|release/*)
    warn "rama '$branch' suele estar protegida" ;;
esac

staged=$(git diff --cached --name-only)
if [ -z "$staged" ]; then
  if [ "$for_push" = 1 ]; then echo "staging vacío (comprobación de push)"; else block "staging vacío"; fi
else echo "en staging:"; echo "$staged" | sed 's/^/  /'; fi

leftover=$(git status --porcelain | grep -Ev '^[MADRC] ' || true)
[ -n "$leftover" ] && echo "fuera del commit (no se incluirán):" && echo "$leftover" | sed 's/^/  /'

if [ "$blocks" -eq 0 ]; then echo "PREFLIGHT OK"; exit 0; fi
echo "PREFLIGHT FALLIDO: $blocks bloqueo(s)"; exit 1
