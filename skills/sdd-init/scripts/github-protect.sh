#!/usr/bin/env bash
# Protege la rama por defecto del repositorio de GitHub actual. Ejecútalo SOLO con
# autorización explícita del usuario: cambia la configuración del repositorio.
# Uso: github-protect.sh [--branch RAMA] [--check NOMBRE] [--no-check] [--replace] [--dry-run]
#   - Prohíbe force push y borrado de la rama.
#   - Exige el check de CI (por defecto "sdd-checks", solo si existe su workflow).
#   - Activa secret scanning y push protection si el plan de GitHub lo permite.
#   - Si la rama ya tiene protección, no la toca salvo --replace (la sustituiría entera).
# No exige revisiones de PR ni se aplica a administradores: un desarrollador solo,
# como admin, puede saltarse el check en un push directo (no el veto a force push).
set -uo pipefail

BRANCH=""; CHECK="sdd-checks"; DRY=0; REPLACE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --branch) BRANCH="${2:-}"; shift ;;
    --check) CHECK="${2:-}"; shift ;;
    --no-check) CHECK="" ;;
    --replace) REPLACE=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "opción desconocida: $1" >&2; exit 2 ;;
  esac
  shift
done

for t in gh jq; do command -v "$t" >/dev/null 2>&1 || { echo "ERROR: falta $t" >&2; exit 1; }; done
gh auth status >/dev/null 2>&1 || { echo "ERROR: gh no está autenticado (gh auth login)" >&2; exit 1; }
info=$(gh repo view --json nameWithOwner,defaultBranchRef,visibility 2>/dev/null) || { echo "ERROR: este directorio no corresponde a un repositorio de GitHub accesible" >&2; exit 1; }
repo=$(printf '%s' "$info" | jq -r .nameWithOwner)
vis=$(printf '%s' "$info" | jq -r .visibility)
[ -n "$BRANCH" ] || BRANCH=$(printf '%s' "$info" | jq -r .defaultBranchRef.name)
branch_uri=$(jq -rn --arg b "$BRANCH" '$b|@uri')

if [ -n "$CHECK" ] && [ "$CHECK" = sdd-checks ] && root=$(git rev-parse --show-toplevel 2>/dev/null) \
   && [ ! -f "$root/.github/workflows/sdd-checks.yml" ]; then
  echo "  · no existe .github/workflows/sdd-checks.yml: no se exige el check (bloquearía los merges)"
  CHECK=""
fi

protection=$(jq -n --arg c "$CHECK" '{
  required_status_checks: (if $c == "" then null else {strict: false, contexts: [$c]} end),
  enforce_admins: false, required_pull_request_reviews: null, restrictions: null,
  allow_force_pushes: false, allow_deletions: false }')
security='{"security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}}'

echo "Repositorio: $repo ($vis) · rama: $BRANCH · check obligatorio: ${CHECK:-ninguno}"
current=$(gh api "repos/$repo/branches/$branch_uri/protection" 2>/dev/null) && has_prot=1 || has_prot=0
if [ "$has_prot" = 1 ]; then
  echo "  · la rama ya tiene protección:"
  printf '%s' "$current" | jq -r '"      force push: \(if .allow_force_pushes.enabled then "permitido" else "prohibido" end) · borrado: \(if .allow_deletions.enabled then "permitido" else "prohibido" end) · revisiones: \(.required_pull_request_reviews.required_approving_review_count // 0) · checks: \([.required_status_checks.contexts[]?] | join(", ") | if . == "" then "ninguno" else . end) · admins incluidos: \(.enforce_admins.enabled // false)"'
fi

if [ "$DRY" = 1 ]; then
  echo "--dry-run: se ejecutaría:"
  if [ "$has_prot" = 1 ] && [ "$REPLACE" = 0 ]; then echo "  (nada en la rama: ya protegida; usa --replace para sustituir su protección)"
  else echo "  gh api -X PUT repos/$repo/branches/$branch_uri/protection --input - <<< '$(printf '%s' "$protection" | jq -c .)'"; fi
  echo "  gh api -X PATCH repos/$repo --input - <<< '$security'"
  exit 0
fi

rc=0
if [ "$has_prot" = 1 ] && [ "$REPLACE" = 0 ]; then
  echo "  · no se cambia la protección existente (se sustituiría entera y podría rebajarla). Usa --replace si quieres la del kit."
elif out=$(printf '%s' "$protection" | gh api -X PUT "repos/$repo/branches/$branch_uri/protection" --input - 2>&1); then
  echo "  ✓ rama $BRANCH protegida: sin force push ni borrado${CHECK:+, check '$CHECK' obligatorio}"
else
  rc=1
  case "$out" in
    *"Upgrade to GitHub Pro"*|*"upgrade"*) echo "  ! no se pudo proteger $BRANCH: GitHub no permite protección de ramas en repos privados con plan gratuito." ;;
    *"403"*|*"404"*) echo "  ! no se pudo proteger $BRANCH: hace falta ser admin del repositorio (o el plan no lo permite)." ;;
    *) echo "  ! no se pudo proteger $BRANCH: $(printf '%s' "$out" | head -1)" ;;
  esac
fi
if out=$(printf '%s' "$security" | gh api -X PATCH "repos/$repo" --input - 2>&1); then
  echo "  ✓ secret scanning y push protection activados"
else
  echo "  ! secret scanning no activado (en repos privados requiere GitHub Advanced Security): $(printf '%s' "$out" | head -1)"
fi
exit $rc
