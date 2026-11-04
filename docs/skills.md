# Skills

Once skills en [`skills/`](../skills/). Todas se pueden invocar escribiendo `/nombre` o las invoca el orquestador. Cada `SKILL.md` define propósito, entradas, herramientas, procedimiento, comprobaciones y condición de finalización.

| Skill | Argumentos | Delega en | Termina cuando |
|---|---|---|---|
| `sdd-init` | `[descripción del producto]` | — | constitución, `memory.md`, `CLAUDE.md` y el ajuste del orquestador existen |
| `sdd-spec` | `<feature> [petición]` | `sdd-spec-analyst` | spec con AC verificables; aprobada o con preguntas para clarify |
| `sdd-clarify` | `<feature>` | — (pregunta al usuario) | ninguna pregunta `[BLOQUEA]` abierta |
| `sdd-plan` | `<feature>` | `sdd-architect` | `plan.md` trazado a FR y AC |
| `sdd-tasks` | `<feature>` | `sdd-planner` | `tasks.md` con cobertura AC completa |
| `sdd-implement` | `<feature> [T-001 …]` | especialistas, `debugger` | tareas `[x]` con evidencia o `[!]` justificadas |
| `sdd-validate` | `<feature>` | `test-engineer` | todos los AC `pasa` con evidencia |
| `sdd-review` | `<feature> [--security]` | `code-reviewer`, `security-reviewer` | revisión aprobada, sin hallazgos críticos o altos |
| `sdd-memory` | — | — | `memory.md` refleja el estado real |
| `sdd-status` | `[feature]` | — (solo lectura) | informe de fase y siguiente paso |
| `sdd-release` | `<feature> [--no-push] [--docs]` | — | commit verificado; push confirmado por git si está activado; o bloqueo explicado |

## Recursos incluidos

| Recurso | Uso |
|---|---|
| `sdd-init/templates/constitution.md` | constitución técnica del proyecto |
| `sdd-init/templates/spec.md`, `plan.md`, `tasks.md`, `acceptance.md` | artefactos por feature |
| `sdd-init/templates/adr.md` | decisiones de arquitectura |
| `sdd-init/templates/memory.md` | memoria del proyecto |
| `sdd-init/templates/project-CLAUDE.md` | `CLAUDE.md` mínimo del proyecto |
| `sdd-init/scripts/setup-project.sh` | configura `.sdd/`, hooks de Git, `.gitignore`, agente por defecto y CI (ver [guardrails.md](guardrails.md)) |
| `sdd-init/scripts/github-protect.sh` | protege la rama por defecto en GitHub, con autorización del usuario |
| `sdd-init/templates/git-hooks/*`, `checks`, `sdd-checks.yml` | plantillas de hooks, comandos de calidad y CI |
| `sdd-release/scripts/preflight.sh` | comprobación previa al commit (ver [security.md](security.md)) |
| `sdd-release/scripts/preflight.test.sh` | autotest del preflight |

## Dependencias

| Skill | Necesita | Si falta |
|---|---|---|
| `sdd-init` | jq | el paso del orquestador por defecto no se aplica; se informa |
| `sdd-spec` | Superpowers (brainstorming) | se especifica sin la exploración guiada |
| `sdd-implement`, `sdd-validate` | Superpowers (TDD, verification) | se aplican las reglas del propio `SKILL.md` |
| `sdd-review` | Superpowers (receiving-code-review) | se procesan los hallazgos según el `SKILL.md` |
| `sdd-release` | git; gh opcional | sin gh no se consulta la protección de rama ni se crean PR |
