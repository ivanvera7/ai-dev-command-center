# Memoria por proyecto

Cada proyecto tiene su propio `memory.md` en la raíz del repositorio, creado por `/sdd-init` desde la plantilla [`skills/sdd-init/templates/memory.md`](../skills/sdd-init/templates/memory.md). Se versiona con el código y pertenece solo a ese repositorio.

## Qué guarda

Objetivo y stack · arquitectura vigente · convenciones y comandos · decisiones (con enlace a ADR) · funcionalidades y su estado · estado actual · errores conocidos · pruebas relevantes y último resultado · próximos pasos y bloqueos.

## Spec frente a memoria

La **spec** dice qué debe hacer el sistema. La **memoria** resume el contexto y el estado real. No se duplican: la memoria enlaza a specs y ADR en lugar de copiarlos.

## Cuándo se actualiza

`/sdd-memory` (o el orquestador antes de `/sdd-release`) la actualiza tras una tarea significativa o al cerrar una sesión de implementación. No se actualiza por cada comando rutinario.

## Reglas

- Solo hechos verificados en la sesión; lo no verificado no entra o se marca.
- Sustituir lo obsoleto, no acumular historial (el historial está en git).
- Breve: idealmente menos de ~150 líneas.
- Nunca secretos, tokens, URLs con credenciales, datos personales sensibles ni conversaciones completas.
- Nunca datos de otros repositorios: la skill comprueba que el archivo está bajo la raíz del repo actual.

## Relación con la memoria de Claude Code

Claude Code tiene su propia memoria automática por usuario (`~/.claude/projects/…`). Es personal y no se versiona. `memory.md` es la memoria del proyecto, compartida con quien clone el repo.
