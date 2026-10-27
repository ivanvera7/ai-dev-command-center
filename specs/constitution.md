# Constitución técnica — AI Dev Command Center

> Última revisión: 2026-10-27.

## 1. Objetivo del producto
Kit distribuible que instala en Claude Code un sistema de desarrollo guiado por especificaciones (SDD): un agente orquestador, subagentes especializados, skills `sdd-*` con plantillas, un script de comprobación previa a la publicación y las instrucciones que conectan el flujo con herramientas externas (Superpowers, Context7, Caveman, Ponytail, RTK, frontend-design).
Fuera de alcance: copiar software de terceros, distribuir configuración personal, desplegar aplicaciones.

## 2. Stack y restricciones
- Contenido: Markdown (agentes y skills en el formato nativo de Claude Code).
- Scripts: Bash compatible con bash 3.2 (macOS) y bash 5 (Linux). Utilidades POSIX + git. Sin dependencias de ejecución adicionales para instalar.
- Plataformas: macOS y Linux. Windows solo vía WSL (no probado).

## 3. Arquitectura y convenciones
- `agents/`: un archivo por agente, plano (como `~/.claude/agents/`).
- `skills/<nombre>/SKILL.md` + recursos de la skill. Rutas internas con `${CLAUDE_SKILL_DIR}`; nunca rutas absolutas personales.
- `core/`: bloque de instrucciones que el instalador inserta entre marcadores en `CLAUDE.md`.
- `install.sh` (instalar/actualizar), `uninstall.sh`, `update.sh`, `scripts/doctor.sh`.
- Pruebas en `tests/`, ejecutadas con `bash tests/run.sh`.

## 4. Estándares de calidad
- Pruebas: `bash tests/run.sh`
- Tipos / compilación: no aplica.
- Lint: `shellcheck` en CI (no instalado localmente).

## 5. Seguridad
- Ningún secreto, token, ruta personal ni dato de otros proyectos en el repo; `tests/` incluye un escaneo.
- El instalador nunca pide credenciales, nunca instala herramientas externas, nunca borra archivos del usuario: solo los que registró en su manifiesto y no han sido modificados.

## 6. Pruebas
- Instalador probado en `HOME` y proyectos temporales aislados.
- Cada criterio de aceptación tiene una prueba automática o una verificación manual documentada.

## 7. Política de dependencias
- No se añaden dependencias de ejecución. Herramientas externas se documentan y se comprueban con `scripts/doctor.sh`.

## 8. Git y GitHub
- Rama principal: `main`. Ramas de trabajo `feat/*`, `fix/*`, `docs/*`.
- Conventional Commits.
- Publicación en GitHub solo con autorización explícita del propietario (nombre, cuenta y visibilidad). Nunca force push.

## 9. Criterios para aceptar cambios
Spec y tasks al día · AC verificados · `bash tests/run.sh` en verde · revisión de código sin bloqueantes · sin hallazgos de seguridad críticos o altos · `memory.md` al día · diff limpio.
