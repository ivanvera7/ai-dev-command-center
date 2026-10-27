# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/); versiones [SemVer](https://semver.org/lang/es/).

## [1.0.0] - 2026-10-27

### Añadido
- 12 agentes: `sdd-orchestrator`, `sdd-spec-analyst`, `sdd-architect`, `sdd-planner`, `frontend-specialist`, `backend-specialist`, `database-specialist`, `devops-specialist`, `test-engineer`, `code-reviewer`, `security-reviewer`, `debugger`.
- 11 skills: `sdd-init`, `sdd-spec`, `sdd-clarify`, `sdd-plan`, `sdd-tasks`, `sdd-implement`, `sdd-validate`, `sdd-review`, `sdd-memory`, `sdd-status`, `sdd-release`, con plantillas y `preflight.sh`.
- `/sdd-init` fija `sdd-orchestrator` como agente por defecto del proyecto (`.claude/settings.local.json`).
- `install.sh`, `update.sh`, `uninstall.sh` con manifiesto, plan previo, conflictos y copias de seguridad; modos global y proyecto.
- `scripts/doctor.sh` para requisitos y herramientas externas.
- Push automático opcional por clon (`git config --local sdd.autoPush true`, preguntado en `/sdd-init`); nunca a la rama por defecto.
- `preflight.sh`: diff sin textconv ni diff externo, más patrones de secretos y archivos sensibles, informe solo con `archivo:línea`, `--push`.
- Pruebas (`tests/run.sh`) y CI en macOS y Linux.
