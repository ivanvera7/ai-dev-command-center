---
name: sdd-validate
description: Ejecuta la validación SDD de una feature - pruebas, tipos/build, lint/formato, integración/e2e según alcance, y verificación de cada criterio de aceptación con evidencia en acceptance.md. Úsala para /sdd-validate o antes de declarar una feature terminada.
argument-hint: "<feature-slug>"
---

# /sdd-validate

**Propósito:** demostrar con ejecuciones reales que la feature cumple la spec.

**Entradas:** `$ARGUMENTS` = feature. Comandos de calidad de `specs/constitution.md` / `CLAUDE.md` del proyecto.

**Herramientas:** subagente `test-engineer`; skill `superpowers:verification-before-completion`; `debugger` si algo falla.

## Procedimiento

1. Los comandos obligatorios están en `.sdd/checks` (los mismos que ejecutan el hook pre-push y el CI). Si faltan, detéctalos (scripts del manifiesto, CI), añádelos a `.sdd/checks` y anótalos en la constitución.
2. Delega a `test-engineer`: completar pruebas que falten para AC, ejecutar pruebas de la feature, suite completa, tipos/build y lint/formato. E2E/integración si el plan las prevé y el entorno lo permite.
3. Comprueba tú los resultados: códigos de salida reales; si la salida condensada por RTK es ambigua, `rtk bypass <cmd>`.
4. Si algo falla: `debugger`, corrige, y **repite solo las comprobaciones afectadas más la suite** hasta verde. No desactives ni debilites pruebas para pasar. Máximo 3 rondas por fallo; después detente e informa con la evidencia.
4b. **Interfaz:** cada AC visible en la UI se verifica en un navegador (Playwright del proyecto o la herramienta de navegador disponible) con captura o comprobación del DOM. Si no es posible, márcalo "no verificado visualmente" y pide al usuario que lo acepte.
5. Actualiza `specs/<feature>/acceptance.md`: cada AC con prueba, comando, resultado y fecha; tabla de comprobaciones globales; limitaciones.

## Comprobaciones (todas obligatorias)

- Cada AC: `pasa` con evidencia, o `no verificado` con motivo aceptado explícitamente por el usuario.
- Pruebas, tipos/build y lint en verde (o "no aplica" justificado en la constitución).
- Ninguna prueba saltada (`skip`, `only`, `xit`...) introducida por esta feature.

## Finalización

Validación verde registrada en `acceptance.md`. Siguiente paso: `/sdd-review`. Si no está en verde, la feature NO está terminada: informa el bloqueo.
