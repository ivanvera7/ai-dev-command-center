# Constitución técnica — <proyecto>

> Se define una vez y se revisa cuando cambian las condiciones fundamentales. Última revisión: <YYYY-MM-DD>.

## 1. Objetivo del producto
<Qué problema resuelve, para quién, y qué queda fuera de alcance.>

## 2. Stack y restricciones
- Lenguaje(s) y versiones: <detectado de los manifiestos>
- Frameworks y runtime: <...>
- Gestor de paquetes: <npm/pnpm/uv/cargo/...>
- Restricciones (plataformas, rendimiento, coste, licencias): <...>

## 3. Arquitectura y convenciones
- Estructura de carpetas y capas: <...>
- Convenciones de nombres, estilo y formato (herramientas): <...>
- Ubicación de las pruebas: <...>

## 4. Estándares de calidad
- Comandos obligatorios antes de publicar (rellenar con los reales del proyecto):
  - Pruebas: `<cmd>`
  - Tipos / compilación: `<cmd o "no aplica">`
  - Lint / formato: `<cmd o "no aplica">`
- Lógica de riesgo (dinero, seguridad, parsers, datos) se desarrolla con TDD.

## 5. Seguridad
- Secretos solo en variables de entorno; `.env*` en `.gitignore`; `.env.example` sin valores reales.
- Validación de entradas en las fronteras de confianza; autorización en servidor.
- Revisión de seguridad obligatoria cuando el cambio toca auth, datos personales, pagos, ficheros, red o dependencias.

## 6. Pruebas
- Unitarias: <runner>. Integración: <...>. E2E: <... o "no aplica">.
- Cada criterio de aceptación tiene al menos una prueba o una verificación manual documentada en `acceptance.md`.

## 7. Política de dependencias
- Antes de añadir una dependencia: comprobar si el código, la librería estándar o una dependencia instalada ya lo resuelve.
- Toda dependencia nueva se justifica en `plan.md`; si es estructural, ADR.

## 8. Git y GitHub
- Rama principal: <main/master>. Protegida: <sí/no/desconocido>.
- Ramas de trabajo: `<feat|fix|chore>/<feature>` (o la convención del repo).
- Commits: Conventional Commits salvo otra convención del repo.
- Remoto esperado: `<URL de origin o PENDIENTE>`
- Publicación automática: permitida
  (`permitida` = cada persona puede activarla en su clon con `git config --local sdd.autoPush true`; `prohibida` = nunca hay push automático en este repo. El push nunca va a la rama principal.)
- Nunca force push. Merge a la rama principal mediante PR o según indique el usuario.

## 9. Criterios para aceptar cambios
1. Spec y tasks actualizadas. 2. AC verificados con evidencia. 3. Comandos obligatorios en verde. 4. Revisión de código sin bloqueantes. 5. Sin hallazgos de seguridad críticos o altos. 6. `memory.md` al día. 7. Diff limpio (sin cambios ajenos ni secretos).
