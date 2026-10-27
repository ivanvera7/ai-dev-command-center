# Memoria del proyecto — AI Dev Command Center

> Resumen breve del contexto y estado real. Solo hechos verificados. Sin secretos ni datos personales.
> Última actualización: 2026-10-27

## Stack
- Markdown (agentes y skills en formato nativo de Claude Code) + Bash 3.2 compatible.
- Probado localmente en macOS con bash 3.2.57 y Claude Code 2.1.311. Linux: solo en CI (pendiente del primer run).

## Arquitectura vigente
- `agents/` (12), `skills/sdd-*` (11, con plantillas y `preflight.sh`), `core/CLAUDE.sdd.md`, `install.sh` / `update.sh` / `uninstall.sh` sobre `lib/common.sh`, `scripts/doctor.sh`. Detalle: docs/architecture.md.
- Estado del instalador en `<destino>/.ai-dev-kit/` (manifiesto con sha256, VERSION, backups).

## Convenciones
- Pruebas: `bash tests/run.sh`. Lint: shellcheck en CI (no instalado en local).
- Rutas en skills con `${CLAUDE_SKILL_DIR}`; en agentes, marcador `<skills>`.
- Conventional Commits; ramas `feat/*`, `fix/*`, `docs/*`.

## Decisiones
- Instalador con manifiesto en lugar de plugin (nombres cortos de skills, modos global y proyecto). Ver specs/kit/plan.md.
- Sin hooks propios; garantías de Git en `sdd-release` + `preflight.sh`.
- Perfiles "integraciones" y "diseño de interfaces" cubiertos por backend-specialist y frontend-specialist; se añadió devops-specialist.

## Funcionalidades
| Feature | Estado | Spec |
|---|---|---|
| kit 1.0.0 | implementado y validado en local; pendiente de publicar | specs/kit/spec.md |

## Estado actual
- Versión 1.0.0 lista en local. Origen: configuración SDD real del autor, con rutas portables.
- Revisión de código (2 rondas) y de seguridad (3 rondas) completadas; hallazgos corregidos con pruebas: validación del manifiesto, enlaces simbólicos en modo proyecto, marcadores de CLAUDE.md, preflight (patrones, diff sin textconv, solo archivo:línea), push automático opcional por clon (`git config --local sdd.autoPush true`).

## Errores conocidos
- Sin `origin/HEAD`, `preflight --push` solo reconoce `main` y `master` como rama por defecto.

## Pruebas relevantes
- `bash tests/run.sh`: 202 comprobaciones en verde (2026-10-27, macOS, bash 3.2).
- Sesión real de Claude Code con `CLAUDE_CONFIG_DIR` aislado: carga los 12 agentes y las 11 skills; la ejecución del modelo no es posible en esa configuración sin iniciar sesión.
- `${CLAUDE_SKILL_DIR}` sustituido por la ruta real de la skill (comprobado con una skill desechable).

## Próximos pasos y bloqueos
- Publicar en GitHub: bloqueado hasta autorización del propietario (nombre, cuenta, visibilidad).
- Primer run de CI en Linux y shellcheck.
