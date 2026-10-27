# Aceptación — kit

| AC | Verificación | Comando | Resultado | Fecha |
|---|---|---|---|---|
| AC-001 | `tests/test_content.sh` (frontmatter y 8 secciones en los 12 agentes) | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-002 | `tests/test_content.sh` (11 skills, frontmatter, referencias `${CLAUDE_SKILL_DIR}` y `<skills>` existentes) | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-003 | `tests/test_content.sh` (sin `/Users/`, `/home/`, patrones de secretos ni correos; preflight `--scan-only` del propio repo) | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-004 | `tests/test_install.sh` (global y proyecto en HOME temporales) | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-005 | `tests/test_install.sh` (dry-run en HOME vacío y sobre instalación con cambios pendientes) | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-006 | `tests/test_install.sh` (conflicto omitido; `--force` con copia) | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-007 | `tests/test_install.sh` (detección, UPDATE, MODIFIED, KEEPOLD, REMOVE, REPLACE del bloque, `update.sh`) | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-008 | `tests/test_install.sh` (CLAUDE.md restaurado byte a byte: con contenido, vacío, sin salto final, con líneas en blanco; ajenos y modificados conservados) | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-009 | `tests/test_doctor.sh` (PATH hermético; requisito ausente → código 1) y ejecución real en macOS | `bash tests/run.sh`, `scripts/doctor.sh` | pasa | 2026-10-27 |
| AC-010 | Suite completa + `preflight.test.sh` | `/bin/bash tests/run.sh` (bash 3.2.57) | pasa (202 comprobaciones) | 2026-10-27 |
| AC-011 | Manual: `install.sh` en `CLAUDE_CONFIG_DIR` temporal + `claude -p` con stream-json: el evento `init` lista los 12 agentes y las 11 skills. Skill desechable de proyecto: `${CLAUDE_SKILL_DIR}/../sdd-init/templates` se sustituye por la ruta real | `CLAUDE_CONFIG_DIR=… claude -p …` | pasa (carga); el modelo no responde en esa configuración porque no tiene sesión iniciada | 2026-10-27 |

## Comprobaciones globales
| Comprobación | Comando | Resultado |
|---|---|---|
| Suite de pruebas | `bash tests/run.sh` | verde en macOS (bash 3.2) |
| Lint | `shellcheck -S error` en CI | pasa (run 40575601797) |
| CI Linux y macOS | GitHub Actions | pasa (run 40575601797) |
| Revisión de código | code-reviewer (2 rondas) | 18 hallazgos + 6 regresiones: corregidos con prueba; sin bloqueantes |
| Revisión de seguridad | security-reviewer (3 rondas) | 8 hallazgos medios/bajos + 2 nuevos: corregidos; sin críticos, altos ni medios abiertos |
| Rendimiento del preflight | diff de 20 000 líneas | 0,2 s |

## Limitaciones
- Flujo SDD completo con el kit instalado desde este repo: probado antes con la instalación manual equivalente (proyecto de prueba `slugify`); no repetido con la instalación gestionada.
