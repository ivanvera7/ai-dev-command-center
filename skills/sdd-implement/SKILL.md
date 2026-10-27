---
name: sdd-implement
description: Ejecuta tareas aprobadas de specs/<feature>/tasks.md mediante los subagentes adecuados, con TDD donde aplique, y verifica cada entrega. Úsala para /sdd-implement.
argument-hint: "<feature-slug> [T-001 T-002 ...]"
---

# /sdd-implement

**Propósito:** implementar exactamente lo aprobado, tarea a tarea, con evidencia.

**Entradas:** `$ARGUMENTS` = feature y, opcionalmente, IDs de tarea. Sin IDs: todas las pendientes cuyo prerrequisito esté hecho.

**Herramientas:** subagentes especialistas; Superpowers: `superpowers:test-driven-development`, `superpowers:subagent-driven-development` (patrón de delegación por tarea), `superpowers:using-git-worktrees` si se necesita aislamiento; Bash para git y pruebas.

## Procedimiento

1. **Git antes de tocar nada:** rama actual, remoto, `git status`. Si hay cambios ajenos sin confirmar, no los toques ni los descartes: anótalos y excluyelos de la tarea. Si la constitución pide rama de trabajo y estás en `main`/`master`, crea `feat/<feature>` (o la convención del repo) desde la rama actual.
2. **Orden:** respeta dependencias de `tasks.md`. Paraleliza solo tareas sin archivos compartidos.
3. **Por tarea:**
   a. Marca `[~]`.
   b. Encarga al responsable: objetivo, FR/AC, archivos previstos, archivos prohibidos, criterio de finalización, comando de prueba.
   c. Lógica no trivial: TDD (prueba roja, código mínimo, verde).
   d. Verifica la entrega tú mismo: `git diff` dentro de alcance, ejecuta el comando de prueba de la tarea y comprueba el código de salida.
   e. Si falla: `debugger` con la evidencia; repite d.
   f. Marca `[x]` y rellena "Evidencia" (comando + resultado resumido). Si no se puede, `[!]` con motivo.
4. **Desviaciones:** si la implementación revela que la spec o el plan son incorrectos, detente y pasa a mantenimiento: actualiza spec/plan/tasks (y confirma con el usuario si cambia comportamiento) antes de seguir.
5. Commits intermedios: opcionales, solo de archivos de la tarea, nunca push sin la puerta de `/sdd-release`.

## Comprobaciones

- Ninguna tarea `[x]` sin evidencia ejecutada en esta sesión.
- Sin archivos fuera del alcance ni secretos (`${CLAUDE_SKILL_DIR}/../sdd-release/scripts/preflight.sh --scan-only`).

## Finalización

Todas las tareas objetivo `[x]` o `[!]` justificadas. Siguiente paso: `/sdd-validate`.
