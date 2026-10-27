<h1 align="center">AI Dev Command Center</h1>

<p align="center">
  <b>Un sistema de desarrollo guiado por especificaciones para Claude Code:<br/>un orquestador, doce agentes especializados y once skills que llevan cada funcionalidad de la idea al push verificado.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-agentes_y_skills-ff4fa3?style=flat-square&labelColor=000000" alt="Claude Code" />
  <img src="https://img.shields.io/badge/método-SDD-a1a1a6?style=flat-square&labelColor=000000" alt="SDD" />
  <img src="https://img.shields.io/badge/idioma-español-a1a1a6?style=flat-square&labelColor=000000" alt="Español" />
  <img src="https://img.shields.io/badge/licencia-MIT-a1a1a6?style=flat-square&labelColor=000000" alt="MIT" />
</p>

<p align="center">
  <a href="#-empieza-aquí"><b>Empieza aquí</b></a> ·
  <a href="#-cómo-funciona"><b>Cómo funciona</b></a> ·
  <a href="#-agentes"><b>Agentes</b></a> ·
  <a href="#-skills"><b>Skills</b></a> ·
  <a href="#-documentación"><b>Documentación</b></a>
</p>

> **Tú describes la funcionalidad. El orquestador la especifica, la planifica, la reparte entre especialistas, la prueba, la revisa y la confirma en una rama —y la publica, si lo has activado— solo si todo pasa.**

<br/>

## ◇ Qué problema resuelve

Programar con un agente de IA sin método tiene dos fallos típicos: el agente construye algo distinto de lo que querías, y declara "hecho" sin haberlo probado. Este kit los ataca con **Spec-Driven Development**:

- Antes de escribir código hay una **spec** con requisitos numerados (`FR-001`) y criterios de aceptación verificables (`AC-001`).
- Cada fase deja un **artefacto en el repo** (`spec.md`, `plan.md`, `tasks.md`, `acceptance.md`, `memory.md`), así la siguiente sesión sabe dónde estás.
- Nada se da por terminado sin **evidencia**: pruebas ejecutadas, revisión de código, revisión de seguridad cuando aplica.
- Las reglas críticas **se hacen cumplir**, no solo se piden: un guard en Claude Code, hooks de Git por proyecto y CI con rama protegida ([guardarraíles](docs/guardrails.md)).
- El **commit** es automático, pero solo después de una puerta de calidad de 10 puntos y un escaneo de secretos. El **push** de la rama de trabajo también lo es si lo activas en tu clon (`/sdd-init` lo pregunta; queda en `git config`, no en el repo). Nunca a `main`, nunca con force.

<br/>

## ◇ Empieza aquí

| | Tu situación | Qué hacer | Frecuencia |
|:-:|---|---|---|
| **01** | Instalar el kit en tu máquina | `git clone` + `./install.sh` ([guía](docs/installation.md)) | Una vez por ordenador |
| **02** | Empezar o adoptar un proyecto | Abre `claude` en el repo y ejecuta `/sdd-init`: constitución, memoria, hooks de Git, CI y agente por defecto | Una vez por proyecto (y por clon) |
| **03** | Día a día | Abre `claude` en el repo y describe lo que quieres | Siempre |

```bash
git clone https://github.com/ivanvera7/ai-dev-command-center.git
cd ai-dev-command-center
./install.sh --dry-run     # muestra qué va a añadir o modificar, sin tocar nada
./install.sh               # instala en ~/.claude (pide confirmación si hay riesgo)
scripts/doctor.sh          # comprueba requisitos y herramientas opcionales
```

```text
┌──────────────────────────┐      ┌──────────────────────────┐      ┌──────────────────────────┐
│  01 · MÁQUINA            │      │  02 · PROYECTO           │      │  03 · DÍA A DÍA          │
│  ./install.sh            │ ───▶ │  /sdd-init               │ ───▶ │  "añade login"           │
│  agentes · skills · guard│      │  constitución · hooks    │      │  spec → … → push         │
│  ── una vez ──           │      │  ── una vez ──           │      │  ── sin prompts extra ── │
└──────────────────────────┘      └──────────────────────────┘      └──────────────────────────┘
```

<br/>

## ◇ Cómo funciona

```text
 /sdd-init ──▶ /sdd-spec ──▶ /sdd-clarify ──▶ /sdd-plan ──▶ /sdd-tasks
 constitución   QUÉ (FR/AC)   dudas que        CÓMO          tareas T-001…
 + memory.md                  bloquean         (+ ADR)       con responsable
                                                                   │
   ┌───────────────────────────────────────────────────────────────┘
   ▼
 /sdd-implement ──▶ /sdd-validate ──▶ /sdd-review ──▶ /sdd-memory ──▶ /sdd-release
 especialistas,      pruebas, tipos,    código +         estado real     puerta de calidad,
 TDD, rama feat/*    lint, AC con       seguridad        del proyecto    preflight, commit,
                     evidencia                                           push de la rama
```

Después de `/sdd-init`, `claude` arranca en ese proyecto como **`sdd-orchestrator`**. Detecta en qué fase está cada funcionalidad, elige el **equipo mínimo** de subagentes, verifica sus entregas y solo te pregunta lo que cambia decisiones. Detalle completo en [docs/sdd-workflow.md](docs/sdd-workflow.md).

<br/>

## ◇ Agentes

Doce agentes en el formato nativo de Claude Code ([`agents/`](agents/)). Cada uno tiene función, contexto necesario, responsabilidades, procedimiento, límites, condiciones para detenerse, criterios de aceptación y formato de entrega. Ficha completa en [docs/agents.md](docs/agents.md).

| Grupo | Agente | Para qué | Edita código |
|---|---|---|:-:|
| Coordinación | `sdd-orchestrator` | Lleva el ciclo completo, delega y aplica las puertas | sí |
| | `sdd-spec-analyst` | Petición → `spec.md` con FR/NFR/AC | specs |
| | `sdd-architect` | Spec → `plan.md` y ADR | specs |
| | `sdd-planner` | Plan → `tasks.md` | specs |
| Desarrollo | `frontend-specialist` | Interfaces, diseño visual, accesibilidad (usa frontend-design) | sí |
| | `backend-specialist` | APIs, lógica, validación, auth, integraciones externas | sí |
| | `database-specialist` | Modelos, migraciones reversibles, índices | sí |
| | `devops-specialist` | CI/CD, contenedores, build, entornos (sin desplegar) | sí |
| Validación | `test-engineer` | AC → pruebas, ejecución con evidencia | tests |
| | `code-reviewer` | Revisión frente a spec, plan y convenciones | no |
| | `security-reviewer` | Secretos, auth, inyección, datos, dependencias | no |
| | `debugger` | Reproduce, causa raíz, corrección mínima | sí |

<br/>

## ◇ Skills

Once skills `/sdd-*` ([`skills/`](skills/)), invocables por ti o por el orquestador. Cada una define propósito, entradas, procedimiento, herramientas, comprobaciones y condición de finalización. Ficha en [docs/skills.md](docs/skills.md).

| Skill | Hace | Artefacto |
|---|---|---|
| `/sdd-init` | Prepara el proyecto y fija el orquestador como agente por defecto | `specs/constitution.md`, `memory.md`, `CLAUDE.md` |
| `/sdd-spec` | Especifica una funcionalidad | `specs/<feature>/spec.md`, `acceptance.md` |
| `/sdd-clarify` | Resuelve dudas que bloquean | `spec.md` actualizada |
| `/sdd-plan` | Diseña la solución | `plan.md`, `specs/adr/*` |
| `/sdd-tasks` | Divide en tareas | `tasks.md` |
| `/sdd-implement` | Ejecuta tareas con los especialistas | código + pruebas |
| `/sdd-validate` | Pruebas, tipos, lint, AC con evidencia | `acceptance.md` |
| `/sdd-review` | Revisión de código y de seguridad | hallazgos resueltos |
| `/sdd-memory` | Actualiza el estado del proyecto | `memory.md` |
| `/sdd-status` | Estado real, solo lectura | informe |
| `/sdd-release` | Puerta de calidad, preflight, commit y push (si está activado) | commit en `feat/*` |

<br/>

## ◇ Guardarraíles

| Capa | Dónde | Qué impide |
|---|---|---|
| **Guard** | hook de Claude Code, global | force push, `--no-verify`, `reset --hard`, `rm -rf` fuera del proyecto, `curl \| sh`, activar el push por su cuenta; pide confirmación para dependencias, despliegues y bases de datos |
| **Hooks de Git** | `.git/hooks` de cada clon | commits con secretos; pushes forzados, borrados, con secretos o con checks fallidos; push del agente a `main` |
| **CI + rama protegida** | GitHub | merge sin `sdd-checks` en verde; force push y borrado de la rama principal; secretos (push protection) |

Además: contenido externo tratado como datos, verificación de dependencias, máximo 3 rondas de corrección, `maxTurns` por agente y verificación visual de interfaces. Detalle en [docs/guardrails.md](docs/guardrails.md).

<br/>

## ◇ Herramientas soportadas

El kit **no incluye** software de terceros: se integra con lo que tengas instalado y funciona sin ello, con menos capacidades. `scripts/doctor.sh` te dice qué hay y cómo instalar lo que falte. Detalle en [docs/integrations.md](docs/integrations.md).

| | Herramienta | Qué aporta al flujo | Necesaria |
|:-:|---|---|:-:|
| ⌘ | Claude Code · git · jq | Base del sistema | **sí** |
| ✦ | [Superpowers](https://github.com/obra/superpowers) | Brainstorming, TDD, depuración, verificación | recomendada |
| ◎ | [Context7](https://github.com/upstash/context7) | Documentación de librerías por versión (MCP) | recomendada |
| ◆ | [Ponytail](https://github.com/DietrichGebert/ponytail) | Cambio mínimo completo | opcional |
| ◐ | [Caveman](https://github.com/JuliusBrussee/caveman) | Respuestas compactas en el chat | opcional |
| ⚡ | [RTK](https://github.com/rtk-ai/rtk) | Salida de comandos condensada | opcional |
| ◇ | [frontend-design](https://github.com/anthropics/skills) | Dirección visual para `frontend-specialist` | opcional |
| ⬡ | gh | PR y consulta de protecciones de rama | opcional |

<br/>

## ◇ Uso

```text
$ cd mi-app && claude
> /sdd-init App de reservas para un gimnasio
> quiero que los socios puedan cancelar una reserva hasta 2 horas antes
```

El orquestador crea `specs/cancelar-reserva/spec.md`, te pregunta solo lo que bloquea (p. ej. "¿se devuelve el crédito?"), planifica, delega en `backend-specialist` y `test-engineer`, valida, pide revisión, actualiza `memory.md`, confirma en `feat/cancelar-reserva` y la publica si activaste la publicación automática. Termina con un informe: requisitos cumplidos, pruebas ejecutadas, hash del commit y resultado real del push.

Otros usos: `/sdd-status` para retomar, `/sdd-spec <feature>` para lanzar una fase concreta, o cambios triviales con flujo abreviado.

<br/>

## ◇ Actualizar, personalizar, desinstalar

```bash
./update.sh                 # git pull --ff-only + reinstala; conserva tus modificaciones
./uninstall.sh --dry-run    # muestra qué se retiraría
./uninstall.sh              # retira solo lo que instaló el kit y no has modificado
./install.sh --project ../mi-app   # instalación solo para un proyecto (en mi-app/.claude)
./install.sh --only skills         # solo algunos componentes (agents, skills, instructions, guard)
```

El instalador lleva un **manifiesto con hashes**: sabe qué archivos son suyos, actualiza solo los que no has tocado, no sobrescribe archivos ajenos (salvo `--force`, con copia de seguridad), escribe sus instrucciones en `CLAUDE.md` entre marcadores y, en modo proyecto, rechaza manifiestos manipulados y enlaces simbólicos. Cómo adaptar agentes, skills y plantillas: [docs/customization.md](docs/customization.md).

<br/>

## ◇ Componentes obligatorios y opcionales

- **Obligatorios para el flujo:** las skills `sdd-*`, el agente `sdd-orchestrator` y el bloque de instrucciones. Requisitos: Claude Code, git y jq.
- **Guard:** recomendado (se instala por defecto). Sin él, las reglas de Git y de borrado vuelven a depender solo del modelo.
- **Agentes especialistas:** recomendados. Sin ellos el orquestador hace el trabajo él mismo, sin revisión independiente.
- **Herramientas externas:** opcionales; cada agente sigue funcionando y declara lo que no pudo usar.

<br/>

## ◇ Limitaciones

- Probado en macOS (bash 3.2) con Claude Code 2.1.311. Linux se prueba en CI; Windows solo vía WSL y sin probar.
- La revisión visual de interfaces depende de que haya un navegador automatizable; si no, el agente lo declara como "no verificado visualmente".
- El push automático está desactivado salvo que lo actives en cada clon (`git config --local sdd.autoPush true`), y requiere un remoto y autenticación ya configurados; el kit nunca pide credenciales.
- El escaneo de secretos de `preflight.sh` y el guard son heurísticos (analizan texto): reducen el riesgo, no lo eliminan. La capa que no se puede esquivar es la protección de rama en GitHub.
- Si tienes skills `sdd-*` personales y además instalas el kit en un proyecto, Claude Code usa las personales.
- Documentación solo en español en esta versión.

<br/>

## ◇ Documentación

| Tema | |
|---|---|
| [Instalación](docs/installation.md) | requisitos, modos, opciones, actualización, desinstalación |
| [Arquitectura](docs/architecture.md) | piezas, dónde vive cada una, cómo se conectan |
| [Agentes](docs/agents.md) · [Skills](docs/skills.md) | fichas completas |
| [Flujo SDD](docs/sdd-workflow.md) | fases, artefactos, flujo abreviado, mantenimiento |
| [Integraciones](docs/integrations.md) | Superpowers, Context7, Caveman, Ponytail, RTK, frontend-design, MCP, hooks |
| [Memoria](docs/memory.md) | `memory.md` por proyecto |
| [Guardarraíles](docs/guardrails.md) | guard, hooks de Git, CI y rama protegida |
| [Seguridad](docs/security.md) · [GitHub](docs/github.md) | secretos, preflight, política de publicación |
| [Problemas](docs/troubleshooting.md) · [Personalización](docs/customization.md) | |

<br/>

## ◇ Contribuir

Lee [CONTRIBUTING.md](CONTRIBUTING.md). El propio repo se desarrolla con su flujo SDD (`specs/`, `memory.md`). Problemas de seguridad: [SECURITY.md](SECURITY.md).

<sub>MIT · Inspirado en el método de <a href="https://github.com/ivanvera7/kit-vibecoding-pro">Kit VibeCoding Pro</a>.</sub>
