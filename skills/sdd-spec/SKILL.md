---
name: sdd-spec
description: Crea o actualiza specs/<feature>/spec.md con requisitos FR/NFR con IDs estables, casos límite, supuestos, preguntas y criterios de aceptación verificables. Úsala para /sdd-spec o cuando en un proyecto SDD llega una funcionalidad o cambio de requisito nuevo.
argument-hint: "<feature-slug> [descripción de la petición]"
---

# /sdd-spec

**Propósito:** fijar QUÉ debe hacer el sistema antes de decidir CÓMO.

**Entradas:** `$ARGUMENTS` = slug de la feature (kebab-case) y descripción. Si falta el slug, derívalo de la descripción.

**Herramientas:** subagente `sdd-spec-analyst` (o tú mismo si la feature es pequeña), skill `superpowers:brainstorming` para explorar la intención cuando la petición es vaga, Read/Write/Edit.

## Procedimiento

1. Comprueba que existe `specs/constitution.md`; si no, ejecuta primero `/sdd-init`.
2. Busca specs existentes que cubran lo mismo (`specs/*/spec.md`, grep por términos clave). Si existe, **actualiza** esa spec: conserva IDs, añade nuevos, marca retirados, añade entrada al registro de cambios.
3. Petición vaga o con varias interpretaciones: usa `superpowers:brainstorming` para explorar con el usuario. Su artefacto final es esta spec en `specs/<feature>/spec.md`, no `docs/superpowers/specs/`.
4. Delega a `sdd-spec-analyst` con: slug, petición literal del usuario, specs relacionadas, plantilla `${CLAUDE_SKILL_DIR}/../sdd-init/templates/spec.md`.
5. Revisa la entrega: cada AC es verificable y referencia un FR/NFR; preguntas marcadas `[BLOQUEA]`/`[NO BLOQUEA]`.
6. Crea `specs/<feature>/acceptance.md` desde `${CLAUDE_SKILL_DIR}/../sdd-init/templates/acceptance.md` con una fila por AC (estado "no verificado").

## Comprobaciones

- IDs únicos y estables; ningún AC sin requisito ni requisito funcional sin AC.
- Sin decisiones de implementación en la spec (van al plan).

## Finalización

Spec en estado `borrador` o `aprobada`. Si hay preguntas `[BLOQUEA]`, siguiente paso `/sdd-clarify`; si no, pide aprobación breve al usuario y sigue con `/sdd-plan`.
