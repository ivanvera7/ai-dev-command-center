---
name: sdd-memory
description: Actualiza memory.md del proyecto con hechos verificados tras una tarea significativa o al cerrar una sesión de implementación - stack, arquitectura, decisiones, features, estado, errores conocidos, pruebas y próximos pasos. Úsala para /sdd-memory.
---

# /sdd-memory

**Propósito:** que la siguiente sesión arranque con el contexto real del proyecto en un archivo breve.

**Entradas:** `memory.md` en la raíz del repo, diff de la sesión (`git diff`, `git log` reciente), specs y ADR tocados, `acceptance.md`.

**Herramientas:** Read, Edit, Bash (git).

## Cuándo

- Tras completar una feature o tarea significativa, cambiar arquitectura/ADR, descubrir un error relevante o cambiar comandos/stack.
- Al final de cada sesión de implementación.
- No por comandos rutinarios ni cambios triviales sin efecto en el contexto.

## Procedimiento

1. Si `memory.md` no existe, créalo desde `${CLAUDE_SKILL_DIR}/../sdd-init/templates/memory.md`.
2. Compara el contenido actual con los hechos de la sesión. Identifica qué cambió.
3. Edita solo las secciones afectadas: **sustituye** lo obsoleto, no acumules historial (el historial está en git).
4. Referencia specs y ADR por ruta en vez de copiar su contenido.
5. Solo hechos verificados (ejecutados o leídos en esta sesión). Lo no verificado no entra o se marca "sin verificar".
6. Actualiza la fecha de "Última actualización".

## Comprobaciones

- Sin secretos, tokens, claves, URLs con credenciales ni datos personales sensibles.
- Breve: idealmente menos de ~150 líneas. Si crece, condensa.
- No duplica la spec: la spec dice qué debe hacer el sistema; la memoria resume contexto y estado.
- Pertenece a ESTE repo (la ruta está bajo `git rev-parse --show-toplevel`).

## Finalización

`memory.md` refleja el estado real. Informa qué secciones cambiaron.
