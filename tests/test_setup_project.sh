#!/usr/bin/env bash
# AC-103, AC-104, AC-105: setup-project.sh, hooks de Git y github-protect.sh --dry-run.
. "$(dirname "$0")/lib.sh"
T=$(sandbox); trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1   # sin hooksPath, gpgsign… del usuario
SETUP="$KIT/skills/sdd-init/scripts/setup-project.sh"
human() { env -u CLAUDECODE "$@"; }        # como lo haría una persona en su terminal
agent() { env CLAUDECODE=1 "$@"; }        # como lo hace Claude Code
tok="ghp""_abcdefghijklmnopqrstuvwxyz0123456789AB"

git init -q --bare -b main "$T/remote.git"
R="$T/repo"; git init -q -b main "$R"; cd "$R" || exit 1
git config user.email t@example.invalid; git config user.name t
git remote add origin "$T/remote.git"
echo base > a.txt; git add a.txt; git commit -qm init; human git push -q -u origin main 2>/dev/null
git remote set-head origin main >/dev/null 2>&1

echo "setup-project.sh (AC-103)"
bash "$SETUP" --dry-run > "$T/dry"; eq "dry-run termina con 0" 0 $?
check "dry-run no crea .sdd" test ! -e .sdd
bash "$SETUP" --ci > "$T/out1"; eq "termina con 0" 0 $?
check ".sdd/preflight.sh" test -x .sdd/preflight.sh
check ".sdd/checks" test -f .sdd/checks
check "hook pre-commit" test -x .git/hooks/pre-commit
check "hook pre-push" test -x .git/hooks/pre-push
check "workflow de CI" test -f .github/workflows/sdd-checks.yml
check ".gitignore protege .env" grep -qxF '.env' .gitignore
check ".gitignore protege settings.local.json" grep -qxF '.claude/settings.local.json' .gitignore
eq "agente por defecto" sdd-orchestrator "$(jq -r .agent .claude/settings.local.json)"
check "avisa de que .sdd/checks está vacío" grep -q 'no tiene comandos' "$T/out1"
check "informa del push automático desactivado" grep -q 'push automático desactivado' "$T/out1"
cp .gitignore "$T/gi1"; bash "$SETUP" --ci > "$T/out2"
check "idempotente: .gitignore sin duplicados" cmp -s "$T/gi1" .gitignore
check "idempotente: hooks al día" grep -q 'hook pre-push al día' "$T/out2"
echo '{"agent":"otro"}' > .claude/settings.local.json; bash "$SETUP" > "$T/out3"
eq "respeta otro agente ya fijado" otro "$(jq -r .agent .claude/settings.local.json)"
echo '{}' > .claude/settings.local.json; bash "$SETUP" > /dev/null
eq "vuelve a fijar el agente si no había ninguno" sdd-orchestrator "$(jq -r .agent .claude/settings.local.json)"
git add .gitignore .sdd .github; human git commit -qm "chore: sdd"

echo "pre-commit (AC-104)"
echo "token = \"$tok\"" > cfg.txt; git add cfg.txt
human git commit -qm secreto > /dev/null 2>&1; check "bloquea un secreto" test $? -ne 0
git reset -q cfg.txt; rm cfg.txt
echo ok > b.txt; git add b.txt; human git commit -qm "feat: b"; check "permite un commit limpio" test $? -eq 0

echo "pre-push (AC-104)"
git switch -q -c feat/x; echo x > x.txt; git add x.txt; git commit -qm "feat: x"
agent git push -q -u origin feat/x 2>/dev/null; check "el agente puede publicar una rama de trabajo" test $? -eq 0
echo y >> x.txt; git commit -qam "feat: y"
agent git push -q origin HEAD:main 2> "$T/e1"; check "el agente no puede hacer push a main" test $? -ne 0
check "…y el motivo es la rama por defecto" grep -q 'rama por defecto' "$T/e1"
human git push -q origin HEAD:main 2>/dev/null; check "una persona sí puede hacer push a main" test $? -eq 0
human git push -q origin feat/x 2>/dev/null
git reset -q --soft HEAD~1; git commit -qm "feat: y reescrito"
human git push -q --force origin feat/x 2> "$T/e2"; check "bloquea push forzado (no fast-forward)" test $? -ne 0
check "…por no ser fast-forward" grep -q 'no fast-forward' "$T/e2"
human git push -q origin --delete feat/x 2> "$T/e3"; check "bloquea borrar una rama remota" test $? -ne 0
check "…por ser un borrado" grep -q 'borrar' "$T/e3"
check "la rama remota sigue existiendo" git ls-remote --exit-code origin refs/heads/feat/x

git switch -q main; git pull -q --ff-only origin main 2>/dev/null
git switch -q -c feat/secreto; echo "k = \"$tok\"" > s.txt; git add s.txt
human git commit -qm s --no-verify   # una persona se lo salta en el commit…
human git push -q -u origin feat/secreto > "$T/e4" 2>&1; check "…pero pre-push detecta el secreto en los commits" test $? -ne 0
check "…e indica archivo:línea" grep -q 's.txt:1' "$T/e4"
bash .sdd/preflight.sh --range deadbeef HEAD > /dev/null 2>&1; eq "--range con una revisión desconocida falla (2)" 2 $?
git switch -q main

echo 'exit 1' > .sdd/checks; git add .sdd/checks; human git commit -qm "chore: check que falla"
git switch -q -c feat/checks
human git push -q -u origin feat/checks 2> "$T/e5"; check "un check fallido bloquea el push" test $? -ne 0
check "…e indica el check" grep -q "falló 'exit 1'" "$T/e5"
echo 'true' > .sdd/checks; git commit -qam "chore: check que pasa"
human git push -q -u origin feat/checks 2>/dev/null; check "con los checks en verde, el push pasa" test $? -eq 0

echo "hooks ajenos y core.hooksPath (AC-103)"
R2="$T/repo2"; git init -q "$R2"; printf '#!/bin/sh\necho mio\n' > "$R2/.git/hooks/pre-commit"
(cd "$R2" && bash "$SETUP" > "$T/out4")
check "no sobrescribe un hook ajeno" grep -q 'echo mio' "$R2/.git/hooks/pre-commit"
check "deja el del kit al lado" test -x "$R2/.git/hooks/pre-commit.ai-dev-kit"
check "lo explica" grep -q 'hook pre-commit ajeno' "$T/out4"
R3="$T/repo3"; git init -q "$R3"; git -C "$R3" config core.hooksPath .husky
(cd "$R3" && bash "$SETUP" > "$T/out5")
check "con core.hooksPath no instala hooks" test ! -e "$R3/.husky/pre-push"
check "con core.hooksPath lo explica" grep -q 'core.hooksPath' "$T/out5"
check "con core.hooksPath deja los hooks en .sdd/git-hooks" test -x "$R3/.sdd/git-hooks/pre-push"
(cd "$T" && bash "$SETUP" > /dev/null 2>&1); check "fuera de un repo git falla" test $? -ne 0

echo "github-protect.sh --dry-run (AC-105)"
mkdir -p "$T/bin"; cat > "$T/bin/gh" <<'GH'
#!/bin/sh
case "$*" in
  "auth status") exit 0 ;;
  "repo view --json nameWithOwner,defaultBranchRef,visibility") echo '{"nameWithOwner":"u/r","defaultBranchRef":{"name":"main"},"visibility":"PUBLIC"}' ;;
  "api repos/u/r/branches/main/protection") echo '{"message":"Branch not protected"}'; exit 1 ;;
  *) echo "LLAMADA INESPERADA: $*" >&2; exit 9 ;;
esac
GH
chmod +x "$T/bin/gh"
out=$(cd "$R" && PATH="$T/bin:$PATH" bash "$KIT/skills/sdd-init/scripts/github-protect.sh" --dry-run 2>&1); rc=$?
eq "termina con 0" 0 "$rc"
for want in '"allow_force_pushes":false' '"allow_deletions":false' '"contexts":["sdd-checks"]' 'secret_scanning_push_protection'; do
  case "$out" in *"$want"*) pass "dry-run muestra $want" ;; *) fail "dry-run muestra $want" ;; esac
done
case "$out" in *INESPERADA*) fail "no hace llamadas de escritura en --dry-run" ;; *) pass "no hace llamadas de escritura en --dry-run" ;; esac
finish
