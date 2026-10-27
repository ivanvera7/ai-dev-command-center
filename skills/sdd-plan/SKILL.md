---
name: sdd-plan
description: Diseña la solución técnica de una spec SDD aprobada en specs/<feature>/plan.md (módulos, contratos, datos, dependencias, riesgos, estrategia de pruebas) y crea ADR cuando corresponde. Úsala para /sdd-plan.
argument-hint: "<feature-slug>"
---

# /sdd-plan

**Propósito:** decidir CÓMO con la solución más simple que cumple la spec y la constitución.

**Entradas:** `$ARGUMENTS` = feature. Requiere `specs/<feature>/spec.md` aprobada.

**Herramientas:** subagente `sdd-architect`; Context7 (vía el arquitecto) para APIs con versión; plantillas `${CLAUDE_SKILL_DIR}/../sdd-init/templates/plan.md` y `${CLAUDE_SKILL_DIR}/../sdd-init/templates/adr.md`.

## Procedimiento

1. Verifica que la spec no tiene preguntas `[BLOQUEA]`. Si las tiene, `/sdd-clarify` primero.
2. Si `plan.md` existe, actualízalo (fase de mantenimiento) en vez de regenerarlo.
3. Delega a `sdd-architect` con: rutas de spec, constitución, memory.md, ADR existentes y alcance.
4. Revisa la entrega:
   - Cada FR/NFR se traza a un componente; cada AC a una prueba prevista.
   - Dependencias nuevas justificadas frente a la política de dependencias.
   - Sin reestructuración ni abstracciones sin motivo escrito.
   - Riesgos con mitigación; datos con plan de reversión.
5. Si el plan implica una decisión difícil de revertir (nuevo servicio, BD, framework, contrato público), confirma con el usuario antes de seguir.

## Comprobaciones

- Plan coherente con la constitución y con el código real (rutas que existen).
- ADR creado solo cuando la decisión es relevante.

## Finalización

`plan.md` escrito. Siguiente paso: `/sdd-tasks`.
