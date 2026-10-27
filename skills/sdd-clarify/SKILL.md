---
name: sdd-clarify
description: Resuelve preguntas abiertas, contradicciones y supuestos peligrosos de una spec SDD antes de planificar. Úsala para /sdd-clarify o cuando una spec tiene preguntas [BLOQUEA].
argument-hint: "<feature-slug>"
---

# /sdd-clarify

**Propósito:** no avanzar hacia decisiones irreversibles apoyadas en supuestos importantes.

**Entradas:** `$ARGUMENTS` = feature. Lee `specs/<feature>/spec.md`, constitución y memory.md.

**Herramientas:** Read, Edit, AskUserQuestion, Grep (para contrastar con el código).

## Procedimiento

1. Recorre la spec y detecta: preguntas `[BLOQUEA]`, contradicciones entre requisitos o con la constitución, supuestos que afectan arquitectura, seguridad, coste, datos o comportamiento visible, y AC no verificables.
2. Resuelve tú lo que el código o la documentación ya responden (cita el archivo). No preguntes lo que puedes comprobar.
3. Pregunta al usuario solo lo restante: máximo 4 preguntas por ronda, cada una con 2-4 opciones y tu recomendación primero.
4. Registra cada respuesta en la spec: mueve la pregunta a "Supuestos" o a requisitos como decisión, con fecha. Actualiza AC afectados.
5. Las preguntas `[NO BLOQUEA]` se quedan con su supuesto por defecto, visible en la spec.

## Comprobaciones

- Ninguna pregunta `[BLOQUEA]` sin resolver.
- La spec no se contradice a sí misma ni a la constitución.

## Finalización

Spec en estado `aprobada` (con confirmación del usuario). Siguiente paso: `/sdd-plan`.
