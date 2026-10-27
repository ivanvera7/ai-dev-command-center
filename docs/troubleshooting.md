# Solución de problemas

| Síntoma | Causa probable | Solución |
|---|---|---|
| `install.sh` sale con código 3 | Hay cambios con riesgo y no hay terminal interactiva | Revisa el plan y repite con `--yes` |
| El plan muestra "conflicto" en muchos archivos | Ya tenías el sistema instalado a mano, sin manifiesto (los idénticos se adoptan; los distintos son conflicto) | `./install.sh --force` (tus versiones quedan en la copia de seguridad) |
| `/sdd-*` no aparece | Claude Code no recargó las skills | Reinicia la sesión; comprueba `ls ~/.claude/skills` o `.claude/skills` |
| Se ejecuta una versión antigua de una skill en un proyecto | Hay una skill personal con el mismo nombre; gana la personal | Instala el kit en global o retira la personal |
| `claude` no arranca como orquestador | Falta `"agent": "sdd-orchestrator"` en `.claude/settings.local.json` | Ejecuta `/sdd-init` de nuevo o `claude --agent sdd-orchestrator` |
| `/sdd-init` no fijó el orquestador | Falta jq | Instala jq y repite `/sdd-init` |
| Las skills citan una ruta con `${CLAUDE_SKILL_DIR}` sin sustituir | Versión de Claude Code sin esa sustitución | Actualiza Claude Code |
| `/sdd-release` hace commit pero no push | El push automático no está activado en tu clon | `git config --local sdd.autoPush true` (o vuelve a ejecutar `/sdd-init`) |
| "marcadores ai-dev-kit incompletos o duplicados" | Se borró o duplicó una línea `<!-- ai-dev-kit:… -->` en `CLAUDE.md` | Deja exactamente un marcador de inicio y uno de fin, o quita el bloque entero, y repite |
| "enlace simbólico en el destino" | En modo proyecto, `.claude/`, `agents/`, `skills/` o `CLAUDE.md` es un enlace | Sustitúyelo por una carpeta o archivo real; el instalador no escribe a través de enlaces en proyectos |
| "manifiesto inválido" | `.ai-dev-kit/manifest` contiene rutas fuera de `agents/` o `skills/` | Revisa quién lo modificó; bórralo si no confías en él y reinstala |
| El push se detiene | Permisos, rama protegida, revisión obligatoria o conflictos | Lee el motivo del informe; el kit no fuerza nada |
| `preflight.sh` bloquea por "posible secreto" y es un falso positivo | Patrón heurístico | Revisa la línea; si es seguro, cambia el valor de ejemplo por uno que no parezca un secreto |
| Salida de un comando confusa o vacía | RTK condensa la salida | `rtk bypass <comando>` |
| `doctor.sh` no detecta un plugin instalado | `claude plugin list` no está disponible en tu versión | Compruébalo con `/plugin` dentro de Claude Code |
| Una prueba de interfaz figura "no verificado visualmente" | No hay navegador automatizable | Instala Playwright en el proyecto o verifica a mano con los pasos de `acceptance.md` |
