# Instalación

## Requisitos

| Requisito | Para qué | Comprobación |
|---|---|---|
| Claude Code | Ejecuta agentes y skills | `claude --version` |
| git | Flujo de ramas, commit y push | `git --version` |
| jq | `/sdd-init` lo usa para fijar el orquestador en `.claude/settings.local.json` | `jq --version` |
| bash ≥ 3.2 y `shasum` o `sha256sum` | Instalador | macOS y Linux los traen |

Sistemas: macOS y Linux. Windows solo mediante WSL (sin probar).

`scripts/doctor.sh` comprueba todo lo anterior y las herramientas opcionales. Solo lee: no instala nada.

## Instalar

```bash
git clone https://github.com/ivanvera7/ai-dev-command-center.git
cd ai-dev-command-center
./install.sh --dry-run
./install.sh
```

El instalador:
1. Comprueba requisitos y sistema operativo.
2. Detecta instalaciones previas del kit (manifiesto en `<destino>/.ai-dev-kit/`).
3. Muestra el plan: qué añade, qué actualiza, qué retira y qué conflictos hay.
4. Pide confirmación si va a modificar o retirar algo existente. Sin terminal interactiva, sale con código `3` y no cambia nada hasta que se ejecute con `--yes`.
5. Guarda copia de seguridad de todo lo que sustituye o retira en `<destino>/.ai-dev-kit/backups/<fecha>/`.
6. Escribe el manifiesto y un informe final.

Nunca instala herramientas externas ni pide credenciales. Solo retira archivos registrados en su manifiesto (con copia de seguridad), nunca sale de `agents/` y `skills/` al limpiar carpetas vacías, y aborta sin cambiar nada si el manifiesto contiene rutas fuera de esas carpetas o si los marcadores de `CLAUDE.md` están rotos. En modo proyecto también aborta si encuentra enlaces simbólicos en el destino o en `CLAUDE.md` (un repo ajeno podría usarlos para escribir fuera).

`<destino>/.ai-dev-kit/.gitignore` excluye `backups/` para que las copias de tu `CLAUDE.md` no se versionen. El estado no guarda rutas absolutas.

## Modos

| Modo | Agentes y skills | Instrucciones SDD |
|---|---|---|
| `--global` (por defecto) | `~/.claude/agents/`, `~/.claude/skills/` (o `$CLAUDE_CONFIG_DIR`) | bloque en `~/.claude/CLAUDE.md` |
| `--project DIR` | `DIR/.claude/agents/`, `DIR/.claude/skills/` | bloque en `DIR/CLAUDE.md` |

El modo global sirve para todos tus proyectos. El modo proyecto sirve para compartir el sistema con un equipo versionando `.claude/` en el repo.

Precedencia de Claude Code: si una skill existe como personal (`~/.claude/skills`) y de proyecto, gana la personal. El instalador avisa de ello.

## Opciones

| Opción | Efecto |
|---|---|
| `--only agents,skills,instructions,guard` | Instala solo esos componentes (por defecto, todos) |
| `--dry-run` | Muestra el plan sin cambiar nada |
| `--yes` | Aplica sin preguntar |
| `--force` | Sustituye archivos en conflicto o modificados por ti, con copia de seguridad |

## Componente guard

Copia `hooks/ai-dev-kit-guard.sh` a `<destino>/hooks/` y añade un hook `PreToolUse` a `<destino>/settings.json` con jq, conservando el resto de ajustes y hooks (con copia de seguridad y confirmación). Reinstalar no lo duplica; desinstalar quita solo esa entrada. En modo proyecto el comando usa `$CLAUDE_PROJECT_DIR`, así que `.claude/settings.json` se puede versionar para todo el equipo. Sin jq, el guard no se instala y el informe lo dice. Ver [guardrails.md](guardrails.md).

## Conflictos

| Situación | Por defecto | Con `--force` |
|---|---|---|
| Archivo nuevo | se añade | se añade |
| Archivo del kit sin modificar, con nueva versión | se actualiza (con copia) | igual |
| Archivo del kit que modificaste | se conserva tu versión | se sustituye (con copia) |
| Archivo ajeno con el mismo nombre | se omite y se informa | se sustituye (con copia) |
| Archivo del kit que ya no existe en la nueva versión | se retira si no lo tocaste | igual |
| `CLAUDE.md` | el bloque se añade o actualiza entre `<!-- ai-dev-kit:start -->` y `<!-- ai-dev-kit:end -->`; el resto se conserva | igual |

Si ya tenías el sistema instalado a mano (sin manifiesto): los archivos idénticos a los del kit se adoptan (pasan al manifiesto y se gestionan como propios) y los distintos aparecen como conflicto. Revisa el plan y usa `--force` para que el kit los gestione todos: tus versiones quedan en la copia de seguridad.

## Actualizar

```bash
./update.sh            # mismos argumentos que install.sh
```

Hace `git pull --ff-only` en el repo del kit (se detiene si tiene cambios locales o no puede avanzar) y vuelve a ejecutar el instalador, que actualiza solo lo que no has modificado.

## Desinstalar

```bash
./uninstall.sh --dry-run
./uninstall.sh                       # global
./uninstall.sh --project ../mi-app   # proyecto
```

Retira los archivos del manifiesto que no has modificado, la entrada del guard en `settings.json` (si falta jq, se detiene sin tocar nada) y el bloque de `CLAUDE.md`, que queda como estaba antes de instalar (si el kit creó el archivo y queda vacío, lo borra). Conserva tus modificaciones (salvo `--force`), tus otros agentes y skills, settings, specs y `memory.md` de tus proyectos. Las copias de seguridad quedan en `<destino>/.ai-dev-kit/backups/`.

El ajuste `"agent": "sdd-orchestrator"` que `/sdd-init` escribe en `.claude/settings.local.json` de cada proyecto no lo gestiona el instalador: bórralo a mano si desinstalas.
