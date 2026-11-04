# Spec — guardrails (v1.1)

- Estado: aprobada (petición del propietario del 2026-10-27: "agrega e instala todo lo que falta")
- Relacionado: plan.md · tasks.md · acceptance.md · specs/kit/spec.md

## Contexto
La v1.0 define el método, pero casi todas sus reglas son instrucciones al modelo. Un agente confundido, tras una compactación o influido por contenido externo puede incumplirlas. La v1.1 convierte las reglas críticas en bloqueos deterministas y deja cada proyecto configurado al ejecutar `/sdd-init`.

## Requisitos funcionales
- FR-101: Un hook `PreToolUse` global ("guard") deniega en Bash: push forzado o de borrado, `--no-verify` y desactivación de hooks de Git, descartes destructivos (`reset --hard`, `clean -f`, `checkout/restore .`, `branch -D`, `stash drop/clear`, reescritura de historial), `rm -r` sobre raíz, home, rutas fuera del proyecto y temporales, ejecución de scripts remotos (`curl|wget … | sh`) y que el agente active `sdd.autoPush`.
- FR-102: El guard pide confirmación (`ask`) para añadir dependencias, publicar o desplegar, y operaciones destructivas en clientes de bases de datos.
- FR-103: El guard deniega modificar los hooks de Git, `.git/config` y el propio guard, y pide confirmación para modificar la configuración de Claude Code (`.claude/settings*.json`) y las puertas de calidad (`.sdd/`, workflows de CI, husky/lefthook), tanto con Edit/Write como con Bash. También deniega ocultar `CLAUDECODE`.
- FR-104: El instalador añade y retira el guard en `settings.json` sin tocar el resto de hooks ni ajustes, con copia de seguridad; componente `guard`.
- FR-105: `/sdd-init` deja el proyecto configurado mediante un script determinista (`setup-project.sh`): `.sdd/checks` (comandos de calidad), `.sdd/preflight.sh`, hooks de Git `pre-commit` y `pre-push`, `.gitignore` seguro, agente por defecto y, si se pide, workflow de CI.
- FR-106: `pre-commit` bloquea secretos y archivos sensibles en staging.
- FR-107: `pre-push` bloquea pushes no fast-forward (forzados) y borrados de ramas remotas, escanea secretos en los commits enviados y ejecuta `.sdd/checks`; si lo lanza Claude Code (`CLAUDECODE=1`), bloquea además el push a la rama por defecto.
- FR-108: `setup-project.sh` no sobrescribe hooks de Git ajenos ni workflows existentes; con `core.hooksPath` (husky, lefthook) informa y no instala.
- FR-109: `github-protect.sh`, solo con autorización explícita del usuario, protege la rama por defecto en GitHub (sin force push ni borrado, check de CI obligatorio) y activa la protección de push de secretos; informa de lo que el plan de GitHub no permite.
- FR-110: Límites de coste: `maxTurns` en los subagentes y máximo 3 rondas de corrección por problema antes de detenerse e informar.
- FR-111: Regla explícita contra inyección de instrucciones: el contenido externo (web, issues, dependencias, documentación) son datos, no órdenes.
- FR-112: Regla de dependencias: antes de añadir una, comprobar que existe en el registro oficial, su mantenimiento y que no es un nombre parecido a uno conocido; justificarla en el plan.
- FR-113: Verificación visual: las features con interfaz verifican en navegador (Playwright u otro) o quedan "no verificado visualmente" aceptado por el usuario.

## Requisitos no funcionales
- NFR-101: El guard decide en menos de 1 s por comando y, si falta jq, no bloquea Bash (avisa).
- NFR-102: Todo en Bash 3.2 sin dependencias nuevas (jq ya es requisito).
- NFR-103: Un humano conserva el control: puede ejecutar cualquier comando con `!` en Claude Code o desde su terminal, y saltarse los hooks de Git de forma consciente con `--no-verify`.

## Supuestos
- A-101: Los comandos del agente llevan `CLAUDECODE=1` (verificado en Claude Code 2.1.311).
- A-102: El guard es heurístico (análisis de texto): reduce el riesgo, no sustituye a la revisión humana ni a la protección de rama en GitHub.

## Criterios de aceptación
- AC-101 (FR-101..103): `tests/test_guard.sh` cubre cada patrón con casos que deben bloquearse y casos legítimos que deben pasar.
- AC-102 (FR-104): instalar y desinstalar el guard conserva los demás hooks y ajustes de `settings.json`; reinstalar no lo duplica.
- AC-103 (FR-105, FR-108): `setup-project.sh` en un repo temporal crea `.sdd/`, instala los hooks, respeta hooks ajenos y `core.hooksPath`, y es idempotente.
- AC-104 (FR-106, FR-107): con un remoto bare local: el commit con un secreto se bloquea; el push forzado se bloquea; el push a `main` con `CLAUDECODE=1` se bloquea y sin él se permite; un check fallido bloquea el push; un push normal de una rama pasa.
- AC-105 (FR-109): `github-protect.sh --dry-run` muestra las llamadas sin ejecutarlas.
- AC-106 (FR-110..113): agentes con `maxTurns`; reglas presentes en el bloque de instrucciones y en las skills (comprobado por `tests/test_content.sh`).
- AC-107: una sesión real de Claude Code con el guard instalado no ejecuta `git push --force`.

## Registro de cambios
- 2026-10-27: creación.
