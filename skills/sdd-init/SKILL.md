---
name: sdd-init
description: Inicializa Spec-Driven Development en el repositorio actual - constitución técnica, memory.md, CLAUDE.md del proyecto y estructura specs/. Úsala cuando el usuario pida /sdd-init o empiece SDD en un proyecto sin specs/constitution.md.
argument-hint: "[descripción breve del producto]"
---

# /sdd-init

**Propósito:** preparar un proyecto para SDD sin duplicar documentos existentes. Se ejecuta una vez por proyecto; repetirla solo revisa y completa.

**Entradas:** `$ARGUMENTS` (descripción opcional del producto), el repositorio actual.

**Herramientas:** Bash (git, lectura de manifiestos), Read, Write, Edit, AskUserQuestion. Plantillas en `${CLAUDE_SKILL_DIR}/templates/`.

## Procedimiento

1. **Estado real.** Raíz del repo (`git rev-parse --show-toplevel`; si no es repo git, pregunta antes de `git init`). Rama, remoto, `git status`. Lista lo que ya existe: `CLAUDE.md`, `AGENTS.md`, `README`, `CONTRIBUTING`, `docs/`, `specs/`, `memory.md`, ADR, `.gitignore`, CI.
2. **Detecta el stack** de los manifiestos reales (`package.json`, lockfiles, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, `pom.xml`, `Makefile`, CI). Extrae los comandos reales de pruebas, tipos, lint y build. No asumas un stack ni un gestor de paquetes.
3. **Equivalentes.** Si ya hay documentos equivalentes (p. ej. `docs/adr/`, `docs/specs/`, un `ARCHITECTURE.md`), reutilízalos y anota su ruta en la constitución en vez de crear copias.
4. **Constitución** `specs/constitution.md` desde la plantilla. Rellena con hechos detectados. Lo que no puedas inferir (objetivo del producto, protección de rama) márcalo `<PENDIENTE>` y pregunta solo lo que cambie decisiones. Usa `$ARGUMENTS` como objetivo si se dio.
5. **memory.md** en la raíz desde la plantilla, solo con hechos verificados (stack, comandos, estado inicial).
6. **CLAUDE.md del proyecto.** Si no existe, créalo desde `project-CLAUDE.md`. Si existe, añade solo una sección corta "SDD" con los enlaces; no reescribas su contenido.
7. **Estructura:** `specs/adr/` (con `.gitkeep` si queda vacía). Las features se crean con `/sdd-spec`.
8. **Comandos de calidad:** escribe en `.sdd/checks` los comandos reales detectados en el paso 2 (uno por línea: pruebas, tipos, lint). Si ya existe, actualízalo sin borrar líneas del usuario. Enséñaselos al usuario: el hook pre-push y el CI los ejecutarán.
9. **Salvaguardas (determinista):** ejecuta
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/setup-project.sh [--ci]
   ```
   Crea o repara `.sdd/preflight.sh`, los hooks de Git `pre-commit` (secretos) y `pre-push` (sin force push ni borrados, secretos en los commits, `.sdd/checks`, y sin push del agente a la rama por defecto), un `.gitignore` seguro y el ajuste `"agent": "sdd-orchestrator"` en `.claude/settings.local.json`. Es idempotente: repítelo para reparar o actualizar. No sobrescribe hooks ajenos ni actúa con `core.hooksPath` (husky, lefthook): en ese caso explica al usuario cómo encadenarlos.
   - Pasa `--ci` si el repo está en GitHub (o lo estará) y no tiene ya un workflow equivalente; después añade al workflow la preparación del entorno que necesiten los comandos de `.sdd/checks` (setup-node, setup-python, instalación de dependencias).
10. **Preguntas al usuario** (una sola ronda, con AskUserQuestion; recomienda la primera opción):
    - **Push automático** de la rama de trabajo cuando todo pase. Solo lo activa el usuario: si quiere, que escriba `! git config --local sdd.autoPush true` (el guard impide que lo hagas tú). Recomiéndalo solo si el repo es suyo y `origin` es el remoto correcto. Anota el remoto esperado en la sección 8 de la constitución.
    - **Proteger la rama por defecto en GitHub** (sin force push ni borrado, check `sdd-checks` obligatorio, secret scanning y push protection). Si acepta: `bash ${CLAUDE_SKILL_DIR}/scripts/github-protect.sh` (prueba antes con `--dry-run` y enséñale el resultado). Informa de lo que su plan de GitHub no permita.
    - Si el repo es de terceros (el dueño de `origin` no es el usuario de `gh`), recomienda trabajar con `/sandbox` o en un devcontainer.
11. **Commit inicial opcional:** solo si el usuario lo pide o la constitución lo establece; usa `/sdd-release` en modo docs.

## Comprobaciones

- Ningún archivo existente sobrescrito sin leerlo y sin conservar su contenido.
- `specs/constitution.md` y `memory.md` existen y no contienen secretos.
- La salida de `setup-project.sh` no tiene pendientes sin explicar al usuario; `.sdd/checks` tiene al menos el comando de pruebas.
- `git check-ignore .claude/settings.local.json` confirma que no se versiona.
- Los comandos de calidad anotados existen de verdad (ejecuta al menos `--help`/listado de scripts o la suite si es rápida).

## Finalización

Informa: archivos creados/modificados, stack detectado, comandos de `.sdd/checks`, salvaguardas activas (hooks, CI, protección de GitHub, push automático sí/no), campos `<PENDIENTE>`, que a partir de la próxima sesión `claude` en este repo arranca con el orquestador, y siguiente paso (`/sdd-spec <feature>`).
