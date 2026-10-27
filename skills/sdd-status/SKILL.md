---
name: sdd-status
description: Informa del estado real SDD del proyecto - fase de cada feature, tareas pendientes/bloqueadas, validación, estado de git y siguiente paso. Solo lectura. Úsala para /sdd-status o al retomar trabajo en un proyecto SDD.
argument-hint: "[feature-slug]"
allowed-tools: Read Glob Grep Bash(git status:*) Bash(git log:*) Bash(git branch:*) Bash(git remote:*) Bash(git rev-parse:*)
---

# /sdd-status

**Propósito:** saber en qué punto está el proyecto sin cambiar nada.

**Entradas:** `$ARGUMENTS` opcional = una feature concreta.

**Herramientas:** solo lectura (Read, Glob, Grep, git de consulta).

## Procedimiento

1. Git: raíz, rama, remoto (sin credenciales), upstream y adelantos/atrasos, `git status` resumido, último commit.
2. SDD: existe `specs/constitution.md`? `memory.md` y su fecha?
3. Por feature (`specs/*/spec.md`, excluyendo `adr`): estado de la spec, plan sí/no, tareas `[x]/[~]/[ ]/[!]` contadas desde `tasks.md`, AC verificados desde `acceptance.md`.
4. Deduce la fase de cada feature con la tabla del agente `sdd-orchestrator` y el siguiente comando.
5. Señala incoherencias: tareas `[x]` sin evidencia, AC sin verificar, memory.md más antiguo que el último commit de la feature, cambios sin confirmar ajenos.

## Comprobaciones

- No modifica archivos.
- Cada afirmación sale de un archivo o comando leído ahora.

## Finalización

Tabla breve: feature · fase · tareas · AC · siguiente paso. Más estado de git y bloqueos.
