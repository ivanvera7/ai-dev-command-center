#!/usr/bin/env bash
# AC-009: doctor.sh informa sin instalar nada. Usa un `claude` simulado para no depender
# de la cuenta ni de los plugins de quien ejecuta las pruebas.
. "$(dirname "$0")/lib.sh"
T=$(sandbox); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/home"
cat > "$T/bin/claude" <<'EOF'
#!/bin/sh
case "$1" in
  --version) echo "0.0.0 (Claude Code simulado)" ;;
  plugin) printf 'Installed plugins:\n\n  ❯ superpowers@claude-plugins-official\n    Version: 1.2.3\n' ;;
esac
EOF
chmod +x "$T/bin/claude"
# PATH hermético: solo las utilidades que usa doctor.sh, para poder simular que falta jq.
for t in git jq uname grep awk cut sort wc tr find head ls cat sed dirname; do
  p=$(command -v "$t") && ln -s "$p" "$T/bin/$t"
done
BASH_BIN=$(command -v bash)
out=$(HOME="$T/home" PATH="$T/bin" "$BASH_BIN" "$KIT/scripts/doctor.sh" 2>&1); rc=$?
eq "termina con 0 si están los requisitos" 0 "$rc"
case "$out" in *"superpowers: v1.2.3"*) pass "detecta un plugin instalado" ;; *) fail "detecta un plugin instalado" ;; esac
case "$out" in *"caveman no detectado"*"JuliusBrussee/caveman"*) pass "indica la fuente oficial de un plugin ausente" ;; *) fail "indica la fuente oficial de un plugin ausente" ;; esac
case "$out" in *"no instalado en $T/home/.claude"*) pass "informa de que el kit no está instalado" ;; *) fail "informa de que el kit no está instalado" ;; esac
check "no crea archivos en HOME" test -z "$(ls -A "$T/home")"

rm "$T/bin/jq"
HOME="$T/home" PATH="$T/bin" "$BASH_BIN" "$KIT/scripts/doctor.sh" > "$T/out" 2>&1; rc=$?
eq "falla si falta un requisito" 1 "$rc"
check "indica que falta jq" grep -q 'falta\] jq' "$T/out"
finish
