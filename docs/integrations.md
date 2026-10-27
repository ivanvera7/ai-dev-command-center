# Integraciones

El kit no copia software de terceros. Cada herramienta se instala desde su fuente oficial; el kit solo contiene las **instrucciones que la conectan con el flujo** (en el bloque de `CLAUDE.md`, en el orquestador y en las skills). Todas son opcionales salvo Claude Code, git y jq.

`scripts/doctor.sh` detecta cada una y muestra el comando de instalación. No instala nada.

| Herramienta | Qué pertenece al kit | Qué pertenece a la herramienta |
|---|---|---|
| Superpowers | reglas: artefactos en `specs/` en vez de `docs/superpowers/`; `sdd-release` sustituye a `finishing-a-development-branch`; qué skill usar en cada fase | el plugin y sus skills |
| Context7 | herramientas `mcp__plugin_context7_context7__*` declaradas en arquitecto y especialistas; regla de no inventar APIs | el plugin y el servidor MCP |
| Caveman | regla: solo afecta al chat, nunca a specs, memoria, commits, avisos de seguridad ni resultados de pruebas | el plugin y sus hooks |
| Ponytail | regla: nunca elimina validación, errores, seguridad, accesibilidad ni pruebas | el plugin y sus hooks |
| RTK | regla: si la salida condensada es inutilizable, `rtk bypass <cmd>`; comprobar códigos de salida | el binario, su hook y `RTK.md` |
| frontend-design | `skills: [frontend-design]` en `frontend-specialist` | la skill |

## Superpowers
- Instalar: `/plugin install superpowers@claude-plugins-official` (marketplace oficial de Anthropic). La marketplace del autor (`obra/superpowers-marketplace`) puede ir por delante en versiones.
- Comprobar: `claude plugin list` muestra `superpowers@…`; las skills `superpowers:*` aparecen en la sesión.
- Sin ella: las skills SDD aplican sus propias reglas (TDD, verificación), sin los procedimientos detallados.

## Context7
- Instalar: `/plugin marketplace add upstash/context7` y `/plugin install context7@context7-marketplace`.
- Autenticación: funciona sin API key con límites de uso; una clave de context7.com amplía los límites. No la guardes en archivos versionados.
- Comprobar: `claude mcp list` muestra `plugin:context7:context7 … Connected`.
- Sin ella: los agentes usan la documentación local del paquete y lo declaran.

## Caveman
- Instalar solo desde la fuente oficial: `/plugin marketplace add JuliusBrussee/caveman` y `/plugin install caveman@caveman`. Existen copias con nombres parecidos que distribuyen ejecutables; no las uses.
- Desactivar en una sesión: "normal mode".

## Ponytail
- Instalar: `/plugin marketplace add DietrichGebert/ponytail` y `/plugin install ponytail@ponytail`.

## RTK (Rust Token Killer)
- Instalar: `brew install rtk-ai/tap/rtk` y `rtk init -g` (añade un hook `PreToolUse` y `RTK.md`). Revisa su README antes: modifica `~/.claude/settings.json`.
- Comprobar: `rtk init -g --show` y `rtk verify`. No basta con que el binario exista.
- Ojo: el paquete `rtk` de otros repositorios puede ser otra herramienta distinta; usa el tap `rtk-ai/tap`.

## frontend-design
- Fuente: skill de Anthropic en [`anthropics/skills`](https://github.com/anthropics/skills). Instalación habitual: `npx skills add anthropics/skills --skill frontend-design`, o como plugin oficial.
- Comprobar: existe `~/.claude/skills/frontend-design/SKILL.md` o aparece en la lista de skills de la sesión.
- Sin ella: `frontend-specialist` trabaja sin la guía y lo declara.

## MCP y hooks
- El kit no añade servidores MCP ni hooks propios. Usa los que aportan los plugins anteriores.
- gh (opcional): `sdd-release` lo usa para consultar la protección de rama y crear PR si se pide.
