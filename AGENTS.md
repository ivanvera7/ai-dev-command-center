# Instrucciones para agentes que trabajan en este repositorio

Este repo ES el kit AI Dev Command Center: contiene agentes y skills para Claude Code y su instalador. No es una aplicación.

- Flujo: SDD. Constitución en `specs/constitution.md`, spec del kit en `specs/kit/`, estado en `memory.md`.
- Pruebas: `bash tests/run.sh` (deben pasar antes de cualquier commit). Lint: `shellcheck` en CI.
- `agents/*.md`: un archivo por agente, con las ocho secciones obligatorias.
- `skills/<nombre>/`: `SKILL.md` + recursos; rutas con `${CLAUDE_SKILL_DIR}`.
- `core/CLAUDE.sdd.md`: bloque que el instalador inserta entre marcadores.
- `hooks/ai-dev-kit-guard.sh`: guard PreToolUse; cada patrón nuevo lleva su caso en `tests/test_guard.sh`.
- Scripts en bash 3.2, sin dependencias nuevas.
- Nunca añadas rutas absolutas personales, secretos, configuración personal ni software de terceros.
- No ejecutes `install.sh` contra el `~/.claude` real para probar: usa `HOME` o `CLAUDE_CONFIG_DIR` temporales (así lo hacen las pruebas).
