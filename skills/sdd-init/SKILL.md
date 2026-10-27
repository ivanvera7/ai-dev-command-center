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
   - **Publicación automática:** pregunta siempre al usuario si `/sdd-release` debe hacer push de la rama de trabajo cuando todo pase (recomienda activarlo solo si el repo es suyo y `origin` es el remoto correcto). Si acepta: `git config --local sdd.autoPush true`; si no, `git config --local sdd.autoPush false`. Es un ajuste de este clon, no se versiona. Anota el remoto esperado en la sección 8 de la constitución. Sin respuesta, no lo actives.
5. **memory.md** en la raíz desde la plantilla, solo con hechos verificados (stack, comandos, estado inicial).
6. **CLAUDE.md del proyecto.** Si no existe, créalo desde `project-CLAUDE.md`. Si existe, añade solo una sección corta "SDD" con los enlaces; no reescribas su contenido.
7. **Estructura:** `specs/adr/` (con `.gitkeep` si queda vacía). Las features se crean con `/sdd-spec`.
8. **.gitignore:** comprueba que `.env*` (excepto `.env.example`), claves y artefactos de build estén ignorados, y que `.claude/settings.local.json` también lo esté. Si falta algo, añádelo.
9. **Orquestador por defecto:** fija `"agent": "sdd-orchestrator"` en `.claude/settings.local.json` (personal, no versionado) para que `claude` en este repo arranque como el coordinador SDD. Fusiona con el archivo si ya existe, sin tocar otras claves:
   ```bash
   mkdir -p .claude && f=.claude/settings.local.json; [ -s "$f" ] || echo '{}' > "$f"
   jq '.agent //= "sdd-orchestrator"' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
   jq -r .agent "$f"   # si no imprime sdd-orchestrator, ya había otro agente: avisa al usuario
   ```
   Si `.claude/settings.local.json` ya fija otro `agent`, no lo sustituyas: avisa al usuario. Para desactivarlo basta con borrar la clave `agent`; `claude --agent <otro>` lo sobrescribe en una sesión.
10. **Commit inicial opcional:** solo si el usuario lo pide o la constitución lo establece; usa `/sdd-release` en modo docs.

## Comprobaciones

- Ningún archivo existente sobrescrito sin leerlo y sin conservar su contenido.
- `specs/constitution.md` y `memory.md` existen y no contienen secretos.
- `jq -r .agent .claude/settings.local.json` devuelve `sdd-orchestrator` y `git check-ignore .claude/settings.local.json` confirma que no se versiona.
- Los comandos de calidad anotados existen de verdad (ejecuta al menos `--help`/listado de scripts o la suite si es rápida).

## Finalización

Informa: archivos creados/modificados, stack detectado, comandos de calidad, campos `<PENDIENTE>`, que a partir de la próxima sesión `claude` en este repo arranca con el orquestador, y siguiente paso (`/sdd-spec <feature>`).
