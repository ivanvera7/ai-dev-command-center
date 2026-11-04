# Aceptación — guardrails (v1.1)

| AC | Verificación | Comando | Resultado | Fecha |
|---|---|---|---|---|
| AC-101 | `tests/test_guard.sh`: cada patrón con casos deny/ask/pass, evasiones reportadas en revisión (separadores, varias líneas, rutas absolutas, mayúsculas, CLAUDECODE), falsos positivos conocidos, sin jq, rendimiento | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-102 | `tests/test_install.sh`: guard creado, conserva hooks y ajustes previos, no se duplica, copia de seguridad, JSON inválido aborta, desinstalar restaura y conserva hooks del usuario en la misma entrada | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-103 | `tests/test_setup_project.sh`: `.sdd/`, hooks, CI, `.gitignore`, agente; idempotente; hooks ajenos; `core.hooksPath`; fuera de git | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-104 | `tests/test_setup_project.sh` con remoto bare: secreto en commit, push del agente a main, push humano a main, force push, borrado, secreto saltándose pre-commit, check fallido y en verde; motivos comprobados | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-105 | `tests/test_setup_project.sh` con `gh` simulado: `--dry-run` muestra las llamadas y no escribe | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-106 | `tests/test_content.sh`: `maxTurns` en 11 agentes; reglas en el bloque de instrucciones; sdd-init y sdd-validate | `bash tests/run.sh` | pasa | 2026-10-27 |
| AC-107 | Sesión real de Claude Code (`claude -p`, con permisos que sí permitían `git *` y `npm *`) en un repo desechable con remoto bare: `git push --force origin main` denegado por el guard; `npm install left-pad` quedó en `ask` y no se ejecutó (nadie podía aprobarlo); el remoto no cambió y no se creó `node_modules` | `claude -p …` | pasa | 2026-10-27 |

## Pendiente
- `/sdd-init` de principio a fin en una sesión real: la prueba headless no pudo ejecutar Bash por permisos (sin aprobación posible). `setup-project.sh` y los hooks están cubiertos por `tests/test_setup_project.sh`. Queda para una sesión interactiva del usuario (T-109).

## Revisiones
| Revisión | Resultado |
|---|---|
| security-reviewer | 1 alta (opciones pegadas a separadores), 6 medias, 11 bajas: corregidas con prueba salvo los límites inherentes documentados en docs/guardrails.md |
| code-reviewer | 2 bloqueantes (mismo de arriba; delimitador de sed en GNU), 6 importantes, 12 menores: corregidos con prueba o documentados |
