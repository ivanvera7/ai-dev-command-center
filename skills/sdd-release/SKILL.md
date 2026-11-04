---
name: sdd-release
description: Cierre y publicación SDD - aplica la puerta de calidad, prepara un commit solo con los archivos de la tarea, comprueba secretos, rama y remoto, hace commit, y push de la rama de trabajo solo si este clon lo tiene activado (nunca force ni a la rama por defecto), y genera el informe de cierre. Úsala para /sdd-release o automáticamente cuando una feature SDD ha superado validate y review.
argument-hint: "<feature-slug> [--no-push] [--docs]"
---

# /sdd-release

**Propósito:** publicar el trabajo terminado sin depender de que el usuario lo recuerde, y sin publicar nada que no haya pasado la puerta.

**Autorización:**
- **Commit** (local): automático cuando la tarea SDD supera esta puerta.
- **Push**: automático solo si la persona lo activó en este clon con `git config --local sdd.autoPush true` (el usuario lo activa escribiendo `! git config --local sdd.autoPush true`; el guard impide que lo haga el agente) y la constitución no lo prohíbe, y solo a una rama de trabajo, nunca a la rama por defecto (`main`, `master` o `origin/HEAD`) aunque no esté protegida. El ajuste es local: no se versiona ni se hereda al clonar. Sin él, el comportamiento es `--no-push`: el commit queda local y se informa. Nunca cambies `sdd.autoPush` sin que el usuario lo pida.
- Ninguna autorización cubre: borrar ramas o repos, reescribir historial compartido, force push, publicar secretos, cambiar permisos o protecciones de GitHub, publicar en un remoto distinto del esperado, desplegar a producción ni ejecutar migraciones destructivas. Todo eso requiere autorización específica.

**Entradas:** `$ARGUMENTS` = feature; `--no-push` deja el commit local; `--docs` = cierre de solo documentación (puerta reducida: puntos 1, 8, 9, 10).

**Herramientas:** Bash (git, gh), `scripts/preflight.sh` (en el directorio de esta skill), Read.

## A. Inspección

1. `git rev-parse --show-toplevel`, rama, `git remote -v` (no muestres credenciales), upstream, `git status`.
2. Lee `CONTRIBUTING*`, `.github/` (plantillas de PR, workflows) y la sección Git de la constitución.
3. Protección de rama: si hay `gh` autenticado y remoto GitHub, `gh api repos/{owner}/{repo}/branches/<rama>/protection` (un 404 significa sin protección o sin permiso para verla; trátalo como desconocido en `main`/`master`).

## B. Puerta de calidad (todas obligatorias)

1. `spec.md` actualizada con lo implementado.
2. `tasks.md`: todas `[x]` o `[!]` con excepción justificada y aceptada.
3. `acceptance.md`: todos los AC `pasa` (o `no verificado` aceptado por el usuario).
4. Pruebas pertinentes ejecutadas en esta sesión DESPUÉS del último cambio de código.
5. Tipos/build y lint en verde (o "no aplica" en la constitución).
6. `code-reviewer`: APROBADO.
7. Seguridad: sin hallazgos críticos/altos abiertos (o "no requerida" justificado).
8. `memory.md` actualizado (`/sdd-memory`).
9. Diff limpio: solo archivos de la tarea, sin artefactos de build, temporales ni secretos.
10. Rama y remoto correctos.

Si un punto falla: corrige y repite las comprobaciones afectadas. Si no puedes, DETENTE y comunica el bloqueo. Nunca omitas pruebas críticas para cerrar.

## C. Commit

1. Si estás en `main`/`master` o rama protegida y la constitución pide ramas de trabajo: crea `<tipo>/<feature>` desde el HEAD actual antes de confirmar.
2. Añade archivos **por ruta explícita** (código, pruebas, `specs/<feature>/`, ADR nuevos, `memory.md`). Nunca `git add .`/`-A` si hay cambios ajenos.
3. `git diff --cached --stat` y revisa la lista.
4. Ejecuta `bash ${CLAUDE_SKILL_DIR}/scripts/preflight.sh` (añade `--expected-remote <url>` cuando el remoto esperado esté en la constitución). Código distinto de 0: corrige, no continúes. El script solo muestra `archivo:línea` de un posible secreto; no copies su contenido en el chat.
5. Mensaje: Conventional Commits salvo convención del repo (`feat(<scope>): <qué>` + cuerpo con IDs FR/AC y feature). Respeta las líneas de atribución que indique el entorno.
6. `git commit` (nunca `--no-verify`; el guard lo impide). El hook `pre-commit` del proyecto vuelve a escanear secretos; si bloquea, corrige la causa. Comprueba `git log -1 --stat`.

## D. Push

1. Si `--no-push`, `git config --local --get sdd.autoPush` no es `true`, la constitución dice `Publicación automática: prohibida`, no hay `origin`, o no hay autenticación: no hagas push; deja el commit local y explica qué falta.
2. Ejecuta `bash ${CLAUDE_SKILL_DIR}/scripts/preflight.sh --push` (con `--expected-remote` si procede). Bloquea si `sdd.autoPush` no está activado o si la rama es la rama por defecto: el push automático nunca va a `main`/`master`/`origin/HEAD` ni a ramas protegidas; para eso hace falta autorización específica del usuario.
3. `git push -u origin <rama>` la primera vez, `git push` después. **Nunca** `--force` ni `--force-with-lease` (el guard lo deniega). El hook `pre-push` bloquea pushes forzados, borrados, secretos en los commits, fallos de `.sdd/checks` y el push del agente a la rama por defecto: si bloquea, corrige la causa e informa.
4. Rechazo (non-fast-forward, permisos, protección, revisión obligatoria): DETENTE. No hagas rebase/merge automático de trabajo ajeno sin autorización; explica la acción necesaria.
5. Confirma con git: `git status -sb` (sin `ahead`) y `git rev-parse HEAD` == `git rev-parse @{u}`.
6. PR: si el repo trabaja con PR y el usuario lo ha pedido o la constitución lo establece, `gh pr create` con plantilla del repo; si no, indica el enlace que imprime git.

## E. Informe de cierre

Requisitos cumplidos · tareas completadas · archivos modificados · pruebas (comando + resultado) · revisión de código y seguridad · memory.md · commit (hash) · push (rama, remoto, resultado real) · bloqueos y limitaciones. No afirmes push sin la confirmación del punto D.5.
