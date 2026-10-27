---
name: sdd-review
description: Revisión independiente SDD de una feature - código frente a spec, plan y convenciones (code-reviewer) y seguridad según el riesgo (security-reviewer). Úsala para /sdd-review o tras /sdd-validate.
argument-hint: "<feature-slug> [--security]"
---

# /sdd-review

**Propósito:** encontrar defectos antes de publicar, con revisores que no escribieron el código.

**Entradas:** `$ARGUMENTS` = feature; `--security` fuerza revisión de seguridad. Base del diff: rama de la que salió la rama de trabajo (`git merge-base HEAD <rama-principal>`), más cambios sin confirmar.

**Herramientas:** subagentes `code-reviewer` y `security-reviewer` (solo lectura); skill `superpowers:receiving-code-review` para procesar los hallazgos.

## Procedimiento

1. Determina la base y lista los archivos del diff.
2. `code-reviewer` siempre, con rutas de spec, plan, tasks y la base del diff.
3. `security-reviewer` si se pasa `--security` o si el diff toca: autenticación/autorización, entrada de usuario, SQL/comandos/ficheros/red, datos personales, pagos, criptografía, configuración de despliegue, permisos, o dependencias. Si no aplica, anota "no requerida: <motivo>".
4. Ejecuta ambos en paralelo (son solo lectura).
5. Procesa hallazgos con `superpowers:receiving-code-review`: verifica cada uno contra el código; no aceptes ni rechaces a ciegas.
6. Corrige BLOQUEANTE y seguridad crítica/alta mediante el especialista o `debugger`; vuelve a ejecutar `/sdd-validate` para las partes afectadas y una nueva revisión del diff corregido.
7. IMPORTANTE/MENOR: corrige si es barato y está en alcance; si no, regístralo en `memory.md` (errores conocidos) o como tarea nueva.

## Comprobaciones

- Veredicto de `code-reviewer`: APROBADO.
- Sin hallazgos de seguridad críticos o altos abiertos.
- Resultado anotado en `acceptance.md` (comprobaciones globales).

## Finalización

Revisión aprobada. Siguiente paso: `/sdd-memory` y `/sdd-release`.
