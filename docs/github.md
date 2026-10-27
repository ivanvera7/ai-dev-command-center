# Git y GitHub

La política vive en [`skills/sdd-release/SKILL.md`](../skills/sdd-release/SKILL.md) y en el bloque SDD de `CLAUDE.md`.

## Tres operaciones distintas

| Operación | Cuándo | Autorización |
|---|---|---|
| Preparar un commit | `git add` por ruta explícita, revisar `git diff --cached`, ejecutar `preflight.sh` | parte del flujo |
| Realizar el commit | tras la puerta de calidad y un preflight sin bloqueos | automática tras la puerta |
| Realizar el push | tras un commit verificado, a la rama de trabajo, con el remoto esperado | solo si activaste `git config --local sdd.autoPush true` en tu clon (se pregunta en `/sdd-init`; no se versiona ni se hereda al clonar) y la constitución no lo prohíbe; nunca a la rama por defecto; `--no-push` la desactiva siempre |

## Antes de empezar

Repo git, rama actual, remoto, `git status`, cambios ajenos (no se tocan ni se descartan), autenticación disponible sin mostrar credenciales, `CONTRIBUTING` y `.github/` del proyecto.

## Puerta de calidad (10 puntos)

1. spec actualizada · 2. tareas completas o excepciones aceptadas · 3. AC verificados · 4. pruebas ejecutadas después del último cambio · 5. tipos, build y lint en verde · 6. revisión de código aprobada · 7. sin hallazgos de seguridad críticos o altos · 8. `memory.md` al día · 9. diff limpio · 10. rama y remoto correctos.

Si un punto falla, se corrige y se repite; si no se puede, la publicación se detiene y se explica el bloqueo.

## Commit

Ramas `feat|fix|chore/<feature>` si la constitución lo pide · `git add` por ruta (nunca `git add .` con cambios ajenos) · Conventional Commits salvo otra convención · nunca `--no-verify`.

## Push

`preflight.sh --push` (exige `sdd.autoPush` y bloquea la rama por defecto) · `git push -u origin <rama>` · nunca `--force` ni `--force-with-lease` · si GitHub rechaza (permisos, protección, revisión obligatoria, conflictos), se detiene y explica la acción necesaria · el push solo se da por hecho cuando `HEAD` coincide con `@{u}`.

## Lo que se hace cumplir sin depender del modelo

- Guard: deniega force push, `--no-verify`, borrar ramas y activar `sdd.autoPush`.
- Hook `pre-push`: bloquea pushes no fast-forward, borrados, secretos, checks fallidos y el push del agente a la rama por defecto.
- GitHub (`github-protect.sh`, con tu autorización): rama por defecto sin force push ni borrado y con `sdd-checks` obligatorio.

## Fuera de la autorización automática

Borrar ramas o repositorios · reescribir historial compartido · publicar secretos · cambiar permisos o protecciones · publicar en un remoto distinto del esperado · desplegar a producción · migraciones destructivas. Todo esto requiere autorización específica.

## PR

`sdd-release` crea un PR con `gh pr create` solo si lo pides o si la constitución lo establece. El merge a la rama principal lo decides tú.
