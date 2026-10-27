# Agentes

Los doce agentes están en [`agents/`](../agents/), en el formato nativo de Claude Code (Markdown con frontmatter `name`, `description`, `tools`, `model`, `color`; `skills` en frontend-specialist). Todos siguen la misma estructura: **Función · Contexto necesario · Responsabilidades · Procedimiento · Límites · Detente si · Criterios de aceptación · Entrega**.

## Coordinación

| Agente | Herramientas | Resumen |
|---|---|---|
| `sdd-orchestrator` | Agent (solo el equipo SDD + Explore + general-purpose), lectura/escritura, Bash, Skill, AskUserQuestion, web | Detecta la fase, delega con encargos acotados, verifica entregas con el diff y las pruebas, aplica la puerta de calidad y escribe el informe de cierre |
| `sdd-spec-analyst` | lectura/escritura, Bash, Skill | Escribe `spec.md` con IDs estables y preguntas `[BLOQUEA]` / `[NO BLOQUEA]` |
| `sdd-architect` | lectura/escritura, Bash, Skill, WebFetch, Context7 | Escribe `plan.md` y ADR; justifica dependencias nuevas |
| `sdd-planner` | lectura/escritura | Escribe `tasks.md` con dependencias, responsable y cobertura AC → tareas |

## Desarrollo

| Agente | Resumen | Límites clave |
|---|---|---|
| `frontend-specialist` | Interfaces, dirección visual, accesibilidad, estados de UI. Precarga la skill `frontend-design` | No rediseña fuera de la tarea; no afirma revisión visual sin navegador |
| `backend-specialist` | APIs, lógica, validación, auth, errores, integraciones externas | Sin secretos; sin cambios de esquema; sin llamadas reales a servicios en pruebas |
| `database-specialist` | Modelos, migraciones reversibles, integridad, índices | Nada destructivo sobre datos reales sin autorización |
| `devops-specialist` | CI/CD, contenedores, build, entornos | No despliega a producción ni cambia secretos o protecciones |

## Validación

| Agente | Resumen | Solo lectura |
|---|---|:-:|
| `test-engineer` | Mapea AC a pruebas, las ejecuta y registra evidencia en `acceptance.md` | no |
| `code-reviewer` | Revisa frente a spec, plan y convenciones; veredicto `APROBADO` / `CAMBIOS REQUERIDOS` | sí |
| `security-reviewer` | Secretos, auth, inyección, datos, permisos, dependencias; gravedad y escenario | sí |
| `debugger` | Reproduce, causa raíz, prueba de regresión, corrección mínima | no |

## Perfiles cubiertos sin agentes duplicados

| Perfil | Lo cubre |
|---|---|
| Especialista en integraciones | `backend-specialist` (integraciones externas en sus responsabilidades) |
| Especialista en diseño de interfaces | `frontend-specialist` con la skill `frontend-design` |
| Accesibilidad, rendimiento, documentación | el orquestador crea un especialista temporal con `general-purpose` cuando la complejidad lo justifica |

## Reglas comunes

- Los subagentes no pueden preguntar al usuario (Claude Code lo impide); devuelven las preguntas al orquestador.
- Ningún agente declara "pasa" sin haber ejecutado el comando en la sesión.
- Dos agentes no editan los mismos archivos en paralelo.
