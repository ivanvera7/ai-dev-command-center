# Personalización

## Modificar lo instalado

Puedes editar cualquier agente o skill instalado. El instalador lo detecta por su hash y **conserva tu versión** al actualizar (salvo `--force`). Para que tus cambios lleguen a otras máquinas, haz un fork del kit y edita allí.

## Agentes

- Modelo: cambia `model: inherit` por `sonnet`, `opus`, `haiku` o un ID de modelo para abaratar o reforzar un agente.
- Herramientas: ajusta `tools`. Los revisores son de solo lectura a propósito.
- Nuevo especialista: crea `agents/<nombre>.md` con la misma estructura de secciones, añádelo a `Agent(...)` en el frontmatter del orquestador (`tests/test_content.sh` lo comprueba) y a la lista de responsables de `sdd-tasks`.

## Skills

- Mantén las rutas con `${CLAUDE_SKILL_DIR}`; `tests/test_content.sh` verifica que existan.
- Si una skill no debe invocarse sola, añade `disable-model-invocation: true` (dejará de poder precargarse en agentes).

## Plantillas

Edita `skills/sdd-init/templates/*`. Afectan a los artefactos nuevos; los existentes en tus proyectos no cambian.

## Política de Git

Cada proyecto la ajusta en la sección 8 de su `specs/constitution.md` (rama principal, ramas de trabajo, convención de commits, PR). Para cambiarla en todos los proyectos, edita `skills/sdd-release/SKILL.md` y el bloque `core/CLAUDE.sdd.md`.

## Instrucciones globales

El bloque entre `<!-- ai-dev-kit:start -->` y `<!-- ai-dev-kit:end -->` lo gestiona el instalador: tus cambios dentro del bloque se sustituyen al actualizar (con copia). Pon tus reglas fuera del bloque.

## Guard

- Desactivar en una sesión: `AI_DEV_KIT_GUARD=off claude`.
- Quitarlo: `./uninstall.sh` o `./install.sh` sin el componente `guard` y borrar su entrada de `settings.json`.
- Ajustar patrones: edita `hooks/ai-dev-kit-guard.sh` en tu fork y añade el caso a `tests/test_guard.sh`.

## Desactivar el orquestador en un proyecto

Borra la clave `agent` de `.claude/settings.local.json`. Para una sola sesión, `claude --agent <otro>` lo sobrescribe.
