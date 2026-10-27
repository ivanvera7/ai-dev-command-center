#!/usr/bin/env bash
# AC-001, AC-002, AC-003: contenido de agentes y skills, rutas portables, sin secretos.
. "$(dirname "$0")/lib.sh"
cd "$KIT" || exit 1

fm() { awk 'NR==1 && $0!="---" {exit} NR>1 && $0=="---" {exit} NR>1' "$1"; }

echo "agentes"
n=0
for f in agents/*.md; do
  n=$((n+1)); base=$(basename "$f" .md)
  eq "$f: name coincide con el archivo" "$base" "$(fm "$f" | sed -n 's/^name: *//p')"
  check "$f: tiene description" test -n "$(fm "$f" | sed -n 's/^description: *//p')"
  for s in "Función" "Contexto necesario" "Responsabilidades" "Procedimiento" "Límites" "Detente si" "Criterios de aceptación" "Entrega"; do
    grep -q "^## $s" "$f" || fail "$f: falta la sección '$s'"
  done
done
eq "12 agentes" 12 "$n"

echo "skills"
expected="sdd-clarify sdd-implement sdd-init sdd-memory sdd-plan sdd-release sdd-review sdd-spec sdd-status sdd-tasks sdd-validate"
eq "las 11 skills SDD" "$expected" "$(ls skills | tr '\n' ' ' | sed 's/ $//')"
for d in skills/*/; do
  d=${d%/}; f="$d/SKILL.md"
  check "$f existe" test -f "$f"
  eq "$f: name coincide con la carpeta" "$(basename "$d")" "$(fm "$f" | sed -n 's/^name: *//p')"
  check "$f: tiene description" test -n "$(fm "$f" | sed -n 's/^description: *//p')"
  # Toda ruta ${CLAUDE_SKILL_DIR}/... citada debe existir dentro del kit.
  for ref in $(grep -o '\${CLAUDE_SKILL_DIR}/[A-Za-z0-9._/-]*' "$f" | sort -u); do
    path="$d/${ref#\$\{CLAUDE_SKILL_DIR\}/}"
    path=${path%.}
    check "$f: referencia $ref existe" test -e "$path"
  done
done
for ref in $(grep -oh '<skills>/[A-Za-z0-9._/-]*' agents/*.md | sort -u); do
  check "agentes: referencia $ref existe" test -e "skills/${ref#<skills>/}"
done
check "preflight.sh es ejecutable" test -x skills/sdd-release/scripts/preflight.sh
check "frontend-specialist precarga frontend-design" grep -q '^  - frontend-design$' agents/frontend-specialist.md
orch_tools=$(fm agents/sdd-orchestrator.md | sed -n 's/^tools: *//p')
for f in agents/*.md; do
  a=$(basename "$f" .md); [ "$a" = sdd-orchestrator ] && continue
  case "$orch_tools" in *"$a"*) ;; *) fail "el orquestador no puede delegar en $a" ;; esac
done

echo "portabilidad y secretos"
# find -print0 | xargs -0: seguro con espacios en las rutas.
grepall() { find . -type f ! -path './.git/*' ! -name '.DS_Store' -print0 | xargs -0 grep -nE "$@" 2>/dev/null; }
hits=$(grepall '/Users/[A-Za-z]|/home/[A-Za-z]' | grep -v '^./tests/test_content.sh:' || true)
eq "sin rutas personales absolutas" "" "$hits"
# Patrones construidos por partes para no detectarse a sí mismos.
p1='AKIA''[0-9A-Z]{16}'; p2='gh[pousr]_''[A-Za-z0-9]{36,}'; p3='github_pat_''[A-Za-z0-9_]{40,}'
p4='sk-(ant-|proj-)?''[A-Za-z0-9_-]{20,}'; p5='-----BEGIN [A-Z ]*PRIVATE ''KEY-----'; p6='xox[abpr]-''[A-Za-z0-9-]{10,}'
scan=$(grepall "$p1|$p2|$p3|$p4|$p5|$p6" | grep -vE '^\./skills/sdd-release/scripts/preflight\.sh:' || true)
eq "sin patrones de secretos" "" "$scan"
emails=$(grepall -o '[A-Za-z0-9._%+-]+@(gmail|hotmail|outlook|yahoo|icloud)\.[a-z]+' || true)
eq "sin correos personales" "" "$emails"
if git -C "$KIT" rev-parse --git-dir >/dev/null 2>&1; then
  out=$(cd "$KIT" && bash skills/sdd-release/scripts/preflight.sh --scan-only 2>&1); rc=$?
  eq "el preflight del kit no encuentra secretos en el propio repo" 0 "$rc"
fi
finish
