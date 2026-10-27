# Plan — guardrails (v1.1)

- Spec: spec.md (FR-101..FR-113)

## Enfoque
Tres capas independientes, de la más cercana al agente a la más difícil de esquivar:
1. **Guard** (`hooks/ai-dev-kit-guard.sh`): hook `PreToolUse` de Claude Code, global, instalado por `install.sh` en `settings.json`. Decide `deny` / `ask` / nada analizando el texto del comando (sin el contenido entre comillas, salvo que se lance otra shell) o la ruta editada.
2. **Hooks de Git** por clon (`pre-commit`, `pre-push`), instalados por `/sdd-init` mediante `setup-project.sh`. Usan `.sdd/preflight.sh` y `.sdd/checks`, versionados en el proyecto. `CLAUDECODE=1` distingue al agente.
3. **GitHub**: workflow `sdd-checks` y `github-protect.sh` (con autorización).
Las reglas de comportamiento (contenido externo, dependencias, rondas, UI) van al bloque de `CLAUDE.md`, al orquestador y a las skills.

## Módulos
| Módulo | Cambio | Requisitos |
|---|---|---|
| `hooks/ai-dev-kit-guard.sh` | nuevo | FR-101..103 |
| `lib/common.sh`, `install.sh`, `uninstall.sh` | componente `guard`; merge jq de `settings.json`; `hooks/` en el manifiesto | FR-104 |
| `skills/sdd-init/scripts/setup-project.sh` | nuevo | FR-105, FR-108 |
| `skills/sdd-init/templates/git-hooks/*`, `checks`, `sdd-checks.yml` | nuevos | FR-105..107 |
| `skills/sdd-init/scripts/github-protect.sh` | nuevo | FR-109 |
| `skills/sdd-release/scripts/preflight.sh` | `--staged`, `--range` | FR-106, FR-107 |
| agentes, skills, `core/CLAUDE.sdd.md`, plantilla de constitución | reglas y `maxTurns` | FR-110..113 |
| `scripts/doctor.sh` | estado del guard y del proyecto | — |

## Riesgos
- R-101: falsos positivos del guard que frenen el trabajo → `ask` en lo dudoso, pruebas de casos legítimos, desactivación con `AI_DEV_KIT_GUARD=off`.
- R-102: el guard es textual y esquivable → capas 2 y 3 independientes; documentado como heurístico.
- R-103: romper `settings.json` del usuario → validación JSON previa, merge con jq, copia de seguridad, pruebas de conservación.
- R-104: hooks ajenos (husky) → no se tocan; instrucciones para encadenar.

## Estrategia de pruebas
| AC | Prueba |
|---|---|
| AC-101 | `tests/test_guard.sh` |
| AC-102 | `tests/test_install.sh` (guard) |
| AC-103, AC-104, AC-105 | `tests/test_setup_project.sh` |
| AC-106 | `tests/test_content.sh` |
| AC-107 | manual: sesión real de Claude Code con el guard instalado |
