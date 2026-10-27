# Flujo SDD

## Fases

| # | Fase | Skill | Artefacto | Puerta para avanzar |
|---|---|---|---|---|
| 0 | Inicialización y análisis del repo | `/sdd-init` | `specs/constitution.md`, `memory.md`, `CLAUDE.md` | constitución sin `<PENDIENTE>` que bloquee |
| 1 | Especificación | `/sdd-spec` | `specs/<f>/spec.md`, `acceptance.md` | cada FR con AC verificable |
| 2 | Aclaraciones | `/sdd-clarify` | `spec.md` | ninguna pregunta `[BLOQUEA]`; spec aprobada |
| 3 | Arquitectura y plan | `/sdd-plan` | `plan.md`, `specs/adr/NNNN-*.md` | FR → componente, AC → prueba prevista |
| 4 | Tareas | `/sdd-tasks` | `tasks.md` | cobertura AC → tareas completa |
| 5 | Implementación | `/sdd-implement` | código, pruebas, rama `feat/<f>` | tareas `[x]` con evidencia |
| 6 | Pruebas y validación | `/sdd-validate` | `acceptance.md` | todos los AC `pasa`; tipos, lint y build en verde |
| 7 | Revisión | `/sdd-review` | hallazgos resueltos | `APROBADO`; sin seguridad crítica o alta |
| 8 | Memoria | `/sdd-memory` | `memory.md` | refleja el estado real |
| 9 | Entrega | `/sdd-release` | commit (+ push de la rama si está activado) | puerta de calidad de 10 puntos y preflight |

El orquestador decide la fase leyendo los artefactos y git, así que puedes cerrar Claude Code y retomar más tarde (`/sdd-status`).

## Identificadores

`FR-001` requisito funcional · `NFR-001` no funcional · `AC-001` criterio de aceptación · `T-001` tarea · `ADR-0001` decisión · `A-01` supuesto · `Q-01` pregunta. Los IDs no se renumeran nunca; los retirados se marcan `(retirado)`.

## Flujo abreviado

Para cambios triviales (typo, texto, configuración de una línea sin lógica): sin spec ni plan, pero con pruebas afectadas, revisión del diff, escaneo de secretos y `memory.md` si cambia algo relevante. El informe de cierre lo declara.

## Mantenimiento

Si cambia un requisito o la solución prevista resulta incorrecta: se detiene la implementación, se actualiza `spec.md` (registro de cambios), se revisan `plan.md`, `tasks.md`, las pruebas y `acceptance.md`, y se repiten las fases afectadas. La documentación refleja siempre el estado real.

## Cuándo pregunta

Solo cuando una decisión afecta a arquitectura, seguridad, coste, datos o comportamiento visible, y el código o la documentación no la resuelven. Cada pregunta trae opciones y una recomendación.

## Ejemplo

Ver el ejemplo de uso del [README](../README.md#-uso). Este mismo repositorio se construyó con el flujo: [`specs/kit/`](../specs/kit/).
