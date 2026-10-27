# Plan — kit

- Spec: spec.md (FR-001..FR-012, NFR-001..NFR-003)

## Enfoque
Extraer los archivos reales de `~/.claude` al repo, hacerlos portables (`${CLAUDE_SKILL_DIR}` en skills, marcador `<skills>` en agentes), y distribuirlos con un instalador Bash basado en manifiesto. Sin empaquetar como plugin: los plugins prefijan las skills (`/kit:sdd-init`) e ignoran `permissionMode` en subagentes, y el propietario pidió un instalador.

## Módulos
| Módulo | Cambio | Requisitos |
|---|---|---|
| `agents/*.md` | Copias reales reestructuradas con secciones fijas; nuevo `devops-specialist` | FR-001, FR-003 |
| `skills/sdd-*/` | Copias reales con rutas portables | FR-002, FR-003 |
| `core/CLAUDE.sdd.md` | Bloque de instrucciones SDD | FR-009 |
| `install.sh` | Plan, conflictos, manifiesto, copias de seguridad, bloque con marcadores | FR-004..FR-007, FR-009 |
| `uninstall.sh` | Retira solo lo del manifiesto no modificado | FR-008 |
| `update.sh` | `git pull --ff-only` + `install.sh` | FR-007 |
| `scripts/doctor.sh` | Diagnóstico sin instalar | FR-010 |
| `docs/`, `README.md` | Documentación | FR-011 |
| `tests/`, `.github/workflows/ci.yml` | Pruebas y CI | FR-012 |

## Contratos
- `install.sh [--global | --project DIR] [--only agents,skills,instructions] [--dry-run] [--yes] [--force]`
- Manifiesto: `<base>/.ai-dev-kit/manifest`, una línea `sha256<TAB>ruta-relativa-a-base`; `<base>/.ai-dev-kit/VERSION`.
- Copias de seguridad: `<base>/.ai-dev-kit/backups/<timestamp>/<ruta>`.
- Marcadores en CLAUDE.md: `<!-- ai-dev-kit:start -->` / `<!-- ai-dev-kit:end -->`.
- Códigos de salida: 0 ok (los conflictos omitidos se informan, no fallan) · 1 error · 3 hay cambios con riesgo, sin terminal interactiva ni `--yes`.
- Validación: rutas del manifiesto solo bajo `agents/` o `skills/` sin `..`; en modo proyecto, sin enlaces simbólicos; marcadores de `CLAUDE.md` exactamente uno de cada.

## Riesgos
- R-01: sobrescribir configuración del usuario → conflictos omitidos por defecto, `--force` con copia.
- R-02: skills personales con el mismo nombre ocultan las del proyecto → documentado y avisado por el instalador.
- R-03: bash 3.2 → sin arrays asociativos ni `mapfile`.

## Estrategia de pruebas
| AC | Prueba |
|---|---|
| AC-001..AC-003 | `tests/test_content.sh` |
| AC-004..AC-008 | `tests/test_install.sh` (HOME y proyectos temporales) |
| AC-009 | `tests/test_doctor.sh` |
| AC-010 | `tests/run.sh` + `preflight.test.sh` |
| AC-011 | manual: `claude -p` con `CLAUDE_CONFIG_DIR` temporal |
