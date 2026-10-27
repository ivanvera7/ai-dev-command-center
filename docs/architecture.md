# Arquitectura

## Piezas

```text
                         ┌──────────────────────────────┐
  CLAUDE.md (bloque) ──▶ │       sdd-orchestrator       │ ◀── .claude/settings.local.json
  reglas globales SDD    │  agente principal del repo   │     "agent": "sdd-orchestrator"
                         └──────┬───────────────┬───────┘
                   invoca skills│               │delega (Agent tool)
                                ▼               ▼
   skills/sdd-*  ── procedimientos       agents/*  ── especialistas
   init · spec · clarify · plan · tasks  spec-analyst · architect · planner
   implement · validate · review         frontend · backend · database · devops
   memory · status · release             test-engineer · code-reviewer
        │                                security-reviewer · debugger
        ▼
   sdd-init/templates/*   plantillas de los artefactos
   sdd-init/scripts/setup-project.sh · github-protect.sh   salvaguardas del proyecto
   sdd-release/scripts/preflight.sh   comprobación de secretos, rama y remoto
   hooks/ai-dev-kit-guard.sh          guard (PreToolUse)
        │
        ▼
   Proyecto: specs/constitution.md · specs/<feature>/{spec,plan,tasks,acceptance}.md
             specs/adr/ · memory.md · CLAUDE.md · .sdd/{checks,preflight.sh}
             .git/hooks/{pre-commit,pre-push} · .github/workflows/sdd-checks.yml
```

## Capas

| Capa | Dónde vive | Quién la escribe |
|---|---|---|
| Kit (agentes, skills, bloque de instrucciones) | `~/.claude` o `<proyecto>/.claude` | `install.sh` |
| Herramientas externas | plugins de Claude Code, binarios del sistema | cada herramienta, por separado |
| Configuración personal | `~/.claude/settings.json`, credenciales | tú; el kit no la toca |
| Proyecto | `specs/`, `memory.md`, `CLAUDE.md`, `.claude/settings.local.json` | `/sdd-init` y las demás skills |

## Decisiones

- **Instalador con manifiesto en vez de plugin.** Un plugin de Claude Code prefija las skills (`/plugin:sdd-init`) e ignora `permissionMode` en sus subagentes. El instalador mantiene los nombres cortos y permite instalación global o por proyecto.
- **Rutas portables.** Las skills usan `${CLAUDE_SKILL_DIR}`, que Claude Code sustituye por la carpeta real de la skill, y las rutas entre skills son relativas (`${CLAUDE_SKILL_DIR}/../sdd-init/templates`). Los agentes, que no tienen esa sustitución, usan el marcador `<skills>` explicado en su propio archivo.
- **Orquestador como agente principal.** Un subagente no puede preguntar al usuario; el orquestador sí, porque corre como hilo principal (`agent` en settings o `claude --agent`). Delegar en subagentes está permitido hasta tres niveles por Claude Code.
- **Tres capas que hacen cumplir las reglas.** Guard (hook `PreToolUse` de Claude Code), hooks de Git por clon (`setup-project.sh`) y CI con rama protegida en GitHub. Ver [guardrails.md](guardrails.md).
- **Bash 3.2.** El instalador funciona con el bash que trae macOS, sin dependencias.

## Estado del instalador

`<destino>/.ai-dev-kit/`
- `manifest`: `sha256<TAB>ruta` de cada archivo instalado.
- `VERSION`: versión instalada.
- `claude-md-created`: existe si el kit creó el `CLAUDE.md` (la desinstalación solo lo borra en ese caso).
- `claude-md-no-final-newline`: existe si el `CLAUDE.md` original no terminaba en salto de línea (se restaura igual).
- `.gitignore`: excluye `backups/` para que no se versionen copias personales.
- No se guardan rutas absolutas: el `CLAUDE.md` se deduce del modo (`~/.claude/CLAUDE.md` o `<proyecto>/CLAUDE.md`).
- `backups/<fecha>/`: copias de lo sustituido o retirado.
