#!/usr/bin/env bash
# AC-004..AC-008: instalación, dry-run, conflictos, actualización y desinstalación
# en HOME y proyectos temporales. Nunca toca el ~/.claude real.
. "$(dirname "$0")/lib.sh"
T=$(sandbox); trap 'rm -rf "$T"' EXIT
unset CLAUDE_CONFIG_DIR
run() { HOME="$1" bash "$2/install.sh" "${@:3}" < /dev/null; }
unrun() { HOME="$1" bash "$2/uninstall.sh" "${@:3}" < /dev/null; }
snap() { (cd "$1" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 shasum -a 256 2>/dev/null || true) | shasum | cut -c1-16; }
kitcopy() { cp -R "$KIT" "$1"; rm -rf "$1/.git"; }

echo "instalación global inicial (AC-004)"
H1="$T/h1"; mkdir -p "$H1/.claude"; printf 'mis instrucciones\n' > "$H1/.claude/CLAUDE.md"
cp "$H1/.claude/CLAUDE.md" "$T/claude.orig"
run "$H1" "$KIT" --global --yes > "$T/out1"; eq "termina con 0" 0 $?
eq "12 agentes instalados" 12 "$(ls "$H1/.claude/agents" | wc -l | tr -d ' ')"
eq "11 skills instaladas" 11 "$(ls "$H1/.claude/skills" | wc -l | tr -d ' ')"
check "plantillas de sdd-init" test -f "$H1/.claude/skills/sdd-init/templates/memory.md"
check "preflight ejecutable" test -x "$H1/.claude/skills/sdd-release/scripts/preflight.sh"
check "CLAUDE.md conserva el contenido previo" grep -qx 'mis instrucciones' "$H1/.claude/CLAUDE.md"
eq "CLAUDE.md tiene un solo bloque" 1 "$(grep -cx '<!-- ai-dev-kit:start -->' "$H1/.claude/CLAUDE.md")"
check "manifiesto creado" test -s "$H1/.claude/.ai-dev-kit/manifest"
check "las copias de seguridad se ignoran en git" grep -qx 'backups/' "$H1/.claude/.ai-dev-kit/.gitignore"

echo "sin terminal y sin --yes: no aplica cambios con riesgo"
H0="$T/h0"; mkdir -p "$H0/.claude"; echo x > "$H0/.claude/CLAUDE.md"
run "$H0" "$KIT" --global > /dev/null; eq "sale con 3" 3 $?
check "no instala nada" test ! -e "$H0/.claude/agents"

echo "dry-run (AC-005)"
H2="$T/h2"; mkdir -p "$H2"
run "$H2" "$KIT" --global --dry-run > "$T/out2"; eq "termina con 0" 0 $?
check "no crea ~/.claude" test ! -e "$H2/.claude"
check "muestra el plan" grep -q 'Plan:' "$T/out2"

echo "reinstalación detecta la instalación previa (AC-007)"
nb=$(ls "$H1/.claude/.ai-dev-kit/backups" | wc -l | tr -d ' ')
run "$H1" "$KIT" --global --yes > "$T/out3"
check "detecta instalación previa" grep -q 'Instalación previa detectada: versión' "$T/out3"
check "nada que hacer" grep -q 'Nada que hacer' "$T/out3"
eq "no crea copias de seguridad nuevas" "$nb" "$(ls "$H1/.claude/.ai-dev-kit/backups" | wc -l | tr -d ' ')"

echo "actualización (AC-007)"
K2="$T/kit2"; kitcopy "$K2"; echo 9.9.9 > "$K2/VERSION"
echo "# cambio del usuario" >> "$H1/.claude/agents/debugger.md"
echo "# cambio del usuario" >> "$H1/.claude/skills/sdd-status/SKILL.md"
echo "# cambio de la nueva versión" >> "$K2/agents/debugger.md"
echo "# cambio de la nueva versión" >> "$K2/agents/code-reviewer.md"
echo "- regla nueva del bloque" >> "$K2/core/CLAUDE.sdd.md"
rm -rf "$K2/skills/sdd-status" "$K2/skills/sdd-memory"
echo "contenido del usuario tras el bloque" >> "$H1/.claude/CLAUDE.md"
before=$(snap "$H1/.claude")
run "$H1" "$K2" --global --dry-run > "$T/out4a"
eq "dry-run con cambios pendientes no modifica nada" "$before" "$(snap "$H1/.claude")"
HOME="$H1" bash "$K2/update.sh" --global --yes < /dev/null > "$T/out4" 2>&1; eq "update.sh termina con 0" 0 $?
check "conserva la modificación del usuario" grep -qx '# cambio del usuario' "$H1/.claude/agents/debugger.md"
check "actualiza el archivo no modificado" grep -qx '# cambio de la nueva versión' "$H1/.claude/agents/code-reviewer.md"
check "copia de seguridad del actualizado" sh -c "ls '$H1'/.claude/.ai-dev-kit/backups/*/agents/code-reviewer.md"
check "retira la skill que ya no está en el kit" test ! -e "$H1/.claude/skills/sdd-memory"
check "conserva la skill retirada que modificaste" grep -qx '# cambio del usuario' "$H1/.claude/skills/sdd-status/SKILL.md"
check "el manifiesto la sigue registrando" grep -q 'skills/sdd-status/SKILL.md' "$H1/.claude/.ai-dev-kit/manifest"
check "actualiza el bloque (REPLACE)" grep -qx -- '- regla nueva del bloque' "$H1/.claude/CLAUDE.md"
check "conserva el contenido antes del bloque" grep -qx 'mis instrucciones' "$H1/.claude/CLAUDE.md"
check "conserva el contenido tras el bloque" grep -qx 'contenido del usuario tras el bloque' "$H1/.claude/CLAUDE.md"
eq "sigue habiendo un solo bloque" 1 "$(grep -cx '<!-- ai-dev-kit:start -->' "$H1/.claude/CLAUDE.md")"
eq "versión registrada" 9.9.9 "$(cat "$H1/.claude/.ai-dev-kit/VERSION")"
run "$H1" "$K2" --global --yes --force > /dev/null
check "--force sustituye un archivo del kit modificado" sh -c "! grep -qx '# cambio del usuario' '$H1/.claude/agents/debugger.md'"
check "--force guarda copia de la modificación" sh -c "grep -rqx '# cambio del usuario' '$H1'/.claude/.ai-dev-kit/backups/*/agents/"

echo "conflicto con archivos ajenos (AC-006)"
H3="$T/h3"; mkdir -p "$H3/.claude/agents"; echo "mi agente propio" > "$H3/.claude/agents/test-engineer.md"
run "$H3" "$KIT" --global --yes > "$T/out5"; eq "termina con 0" 0 $?
eq "no sobrescribe sin --force" "mi agente propio" "$(cat "$H3/.claude/agents/test-engineer.md")"
check "informa del conflicto" grep -q 'conflicto' "$T/out5"
run "$H3" "$KIT" --global --yes --force > /dev/null
check "--force sustituye" grep -q '^name: test-engineer' "$H3/.claude/agents/test-engineer.md"
check "--force guarda copia" sh -c "grep -rqx 'mi agente propio' '$H3'/.claude/.ai-dev-kit/backups"

echo "--only"
H4="$T/h4"; mkdir -p "$H4"
run "$H4" "$KIT" --global --only skills --yes > /dev/null
check "skills instaladas" test -d "$H4/.claude/skills/sdd-init"
check "sin agentes" test ! -e "$H4/.claude/agents"
check "sin CLAUDE.md" test ! -e "$H4/.claude/CLAUDE.md"
run "$H4" "$KIT" --global --yes > /dev/null
run "$H4" "$KIT" --global --only skills --yes > /dev/null
eq "--only conserva en el manifiesto los demás componentes" 12 "$(grep -c "$(printf '\t')agents/" "$H4/.claude/.ai-dev-kit/manifest")"

echo "desinstalación global (AC-008)"
cp "$H1/.claude/CLAUDE.md" "$T/h1.before"
echo "# vuelve a modificarlo" >> "$H1/.claude/agents/debugger.md"
echo "otro agente" > "$H1/.claude/agents/mio.md"
before=$(snap "$H1/.claude")
unrun "$H1" "$KIT" --dry-run > /dev/null
eq "uninstall --dry-run no modifica nada" "$before" "$(snap "$H1/.claude")"
unrun "$H1" "$KIT" --yes > "$T/out6"; eq "termina con 0" 0 $?
check "CLAUDE.md conserva lo del usuario" grep -qx 'contenido del usuario tras el bloque' "$H1/.claude/CLAUDE.md"
check "CLAUDE.md sin bloque" sh -c "! grep -q 'ai-dev-kit' '$H1/.claude/CLAUDE.md'"
check "conserva agentes ajenos" test -f "$H1/.claude/agents/mio.md"
eq "conserva solo lo ajeno y lo modificado" "debugger.md mio.md" "$(ls "$H1/.claude/agents" | tr '\n' ' ' | sed 's/ $//')"
eq "retira las skills del kit sin tocar la carpeta" "sdd-status" "$(ls "$H1/.claude/skills" | tr '\n' ' ' | sed 's/ $//')"
unrun "$H1" "$KIT" --yes --force > /dev/null
check "uninstall --force retira lo modificado" test ! -e "$H1/.claude/agents/debugger.md"
check "uninstall --force guarda copia" sh -c "grep -rqx '# vuelve a modificarlo' '$H1'/.claude/.ai-dev-kit/backups"

echo "CLAUDE.md: restauración exacta"
H5="$T/h5"; mkdir -p "$H5"; run "$H5" "$KIT" --global --yes > /dev/null; unrun "$H5" "$KIT" --yes > /dev/null
check "borra el CLAUDE.md que creó el kit" test ! -e "$H5/.claude/CLAUDE.md"
H7="$T/h7"; mkdir -p "$H7/.claude/agents"; : > "$H7/.claude/CLAUDE.md"
run "$H7" "$KIT" --global --yes > /dev/null; unrun "$H7" "$KIT" --yes > /dev/null
check "conserva un CLAUDE.md vacío del usuario" test -f "$H7/.claude/CLAUDE.md"
eq "y sigue vacío" 0 "$(wc -c < "$H7/.claude/CLAUDE.md" | tr -d ' ')"
check "conserva la carpeta agents/ que ya existía" test -d "$H7/.claude/agents"
H8="$T/h8"; mkdir -p "$H8/.claude"; printf 'sin salto final' > "$H8/.claude/CLAUDE.md"; cp "$H8/.claude/CLAUDE.md" "$T/nonl.orig"
run "$H8" "$KIT" --global --yes > /dev/null; unrun "$H8" "$KIT" --yes > /dev/null
check "restaura un CLAUDE.md sin salto de línea final" cmp -s "$T/nonl.orig" "$H8/.claude/CLAUDE.md"
H12="$T/h12"; mkdir -p "$H12/.claude"; printf 'x' > "$H12/.claude/CLAUDE.md"
run "$H12" "$KIT" --global --yes > /dev/null; printf 'añadido después\n\n\n' >> "$H12/.claude/CLAUDE.md"
unrun "$H12" "$KIT" --yes > /dev/null
eq "solo quita el salto de línea que añadió el kit" "$(printf 'x\nañadido después\n\n.')" "$(cat "$H12/.claude/CLAUDE.md"; printf '.')"
H9="$T/h9"; mkdir -p "$H9/.claude"; printf 'a\n\nb\n\n' > "$H9/.claude/CLAUDE.md"; cp "$H9/.claude/CLAUDE.md" "$T/blank.orig"
run "$H9" "$KIT" --global --yes > /dev/null; unrun "$H9" "$KIT" --yes > /dev/null
check "restaura líneas en blanco finales" cmp -s "$T/blank.orig" "$H9/.claude/CLAUDE.md"

echo "marcadores rotos: no toca el archivo"
H10="$T/h10"; mkdir -p "$H10"; run "$H10" "$KIT" --global --yes > /dev/null
grep -vx '<!-- ai-dev-kit:end -->' "$H10/.claude/CLAUDE.md" > "$T/broken"; echo "contenido valioso" >> "$T/broken"
cp "$T/broken" "$H10/.claude/CLAUDE.md"
run "$H10" "$KIT" --global --yes > /dev/null 2>&1; check "install falla" test $? -ne 0
check "install no lo modifica" cmp -s "$T/broken" "$H10/.claude/CLAUDE.md"
unrun "$H10" "$KIT" --yes > /dev/null 2>&1; check "uninstall falla" test $? -ne 0
check "uninstall no lo modifica" cmp -s "$T/broken" "$H10/.claude/CLAUDE.md"
check "uninstall no retira agentes" test -f "$H10/.claude/agents/debugger.md"

echo "instalación por proyecto (AC-004, AC-008)"
H6="$T/h6"; mkdir -p "$H6"; P="$T/proyecto con espacios"; mkdir -p "$P"; git -C "$P" init -q
printf '# Proyecto\n\nreglas propias\n' > "$P/CLAUDE.md"; cp "$P/CLAUDE.md" "$T/proj.orig"
run "$H6" "$KIT" --project "$P" --yes > "$T/out7"; eq "termina con 0" 0 $?
check "agentes en el proyecto" test -f "$P/.claude/agents/sdd-orchestrator.md"
check "skills en el proyecto" test -f "$P/.claude/skills/sdd-init/SKILL.md"
check "bloque en el CLAUDE.md del proyecto" grep -qx '<!-- ai-dev-kit:start -->' "$P/CLAUDE.md"
check "no toca el HOME" test ! -e "$H6/.claude"
check "detecta carpeta existente" grep -q 'Proyecto: carpeta existente' "$T/out7"
check "el estado versionable no contiene rutas absolutas" sh -c "! grep -rqF '$T' --exclude-dir=backups '$P/.claude/.ai-dev-kit'"
unrun "$H6" "$KIT" --project "$P" --yes > /dev/null
check "CLAUDE.md del proyecto restaurado" cmp -s "$T/proj.orig" "$P/CLAUDE.md"
check "sin agentes del kit en el proyecto" test -z "$(ls "$P/.claude/agents" 2>/dev/null)"

echo "manifiesto o destino manipulados (repo ajeno)"
P3="$T/p3"; mkdir -p "$P3/.claude/.ai-dev-kit" "$T/victima"; echo dato > "$T/victima/dato.txt"
printf 'deadbeef\tagents/../../../victima/dato.txt\n' > "$P3/.claude/.ai-dev-kit/manifest"
unrun "$H6" "$KIT" --project "$P3" --yes --force > /dev/null 2>&1; check "uninstall rechaza rutas con .." test $? -ne 0
run "$H6" "$KIT" --project "$P3" --yes --force > /dev/null 2>&1; check "install rechaza rutas con .." test $? -ne 0
check "no borra fuera del destino" test -f "$T/victima/dato.txt"
P4="$T/p4"; mkdir -p "$P4/.claude" "$T/fuera"; ln -s "$T/fuera" "$P4/.claude/agents"
run "$H6" "$KIT" --project "$P4" --yes > /dev/null 2>&1; check "install rechaza un destino con enlace simbólico" test $? -ne 0
check "no escribe a través del enlace" test -z "$(ls "$T/fuera")"
P5="$T/p5"; mkdir -p "$P5"; echo original > "$T/fuera/rc"; ln -s "$T/fuera/rc" "$P5/CLAUDE.md"
run "$H6" "$KIT" --project "$P5" --yes > /dev/null 2>&1; check "install rechaza un CLAUDE.md enlazado" test $? -ne 0
eq "no modifica el destino del enlace" original "$(cat "$T/fuera/rc")"

P6="$T/p6"; mkdir -p "$P6/.claude" "$T/fuera2"; echo "del usuario" > "$T/fuera2/VERSION"; ln -s "$T/fuera2" "$P6/.claude/.ai-dev-kit"
run "$H6" "$KIT" --project "$P6" --yes > /dev/null 2>&1; check "install rechaza .ai-dev-kit enlazado" test $? -ne 0
eq "no escribe en el destino del enlace" "del usuario" "$(cat "$T/fuera2/VERSION")"
P7="$T/p7"; mkdir -p "$P7/.claude/.ai-dev-kit"; echo "del usuario" > "$T/fuera2/v2"; ln -s "$T/fuera2/v2" "$P7/.claude/.ai-dev-kit/VERSION"
run "$H6" "$KIT" --project "$P7" --yes > /dev/null 2>&1; check "install rechaza VERSION enlazado" test $? -ne 0
eq "no sobrescribe el destino del enlace" "del usuario" "$(cat "$T/fuera2/v2")"

echo "aviso de skills personales que ocultan las del proyecto"
P2="$T/p2"; mkdir -p "$P2"; H11="$T/h11"; mkdir -p "$H11"
run "$H11" "$KIT" --global --yes > /dev/null
run "$H11" "$KIT" --project "$P2" --dry-run > "$T/out8" 2>&1
check "avisa de la precedencia" grep -q 'skills sdd-\* personales' "$T/out8"

echo "opciones inválidas"
run "$H2" "$KIT" --project "$T/no-existe" --yes > /dev/null 2>&1; check "proyecto inexistente falla" test $? -ne 0
run "$H2" "$KIT" --only nada > /dev/null 2>&1; check "componente desconocido falla" test $? -ne 0
run "$H2" "$KIT" --project > /dev/null 2> "$T/err"; check "--project sin valor falla" test $? -ne 0
check "--project sin valor explica el error" grep -q 'necesita un valor' "$T/err"
unrun "$H2" "$KIT" --yes > /dev/null 2>&1; check "desinstalar sin instalación falla" test $? -ne 0
finish
