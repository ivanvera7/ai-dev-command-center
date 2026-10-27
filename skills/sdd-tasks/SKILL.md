---
name: sdd-tasks
description: Genera o actualiza specs/<feature>/tasks.md - tareas pequeñas con ID, requisitos, dependencias, archivos, responsable, criterio de finalización y pruebas. Úsala para /sdd-tasks tras un plan SDD.
argument-hint: "<feature-slug>"
---

# /sdd-tasks

**Propósito:** convertir spec + plan en trabajo ejecutable y verificable.

**Entradas:** `$ARGUMENTS` = feature. Requiere `spec.md` y `plan.md`.

**Herramientas:** subagente `sdd-planner` (o tú mismo si son ≤3 tareas), plantilla `${CLAUDE_SKILL_DIR}/../sdd-init/templates/tasks.md`.

## Procedimiento

1. Si `tasks.md` existe, actualízalo conservando IDs y estados; añade tareas nuevas al final con IDs nuevos.
2. Delega a `sdd-planner` con rutas de spec y plan.
3. Revisa: cada AC cubierto por al menos una tarea; dependencias sin ciclos; tareas que comparten archivos son secuenciales; pruebas de lógica de riesgo antes o junto al código (TDD); responsable válido (`frontend-specialist`, `backend-specialist`, `database-specialist`, `devops-specialist`, `test-engineer`, `debugger`).
4. Presenta al usuario el orden de ejecución en pocas líneas y pide aprobación si la feature es grande o toca datos/seguridad. En features pequeñas la aprobación de la spec basta.

## Comprobaciones

- Tabla de cobertura AC -> tareas completa.
- Ninguna tarea sin criterio de finalización observable.

## Finalización

`tasks.md` aprobado. Siguiente paso: `/sdd-implement`.
