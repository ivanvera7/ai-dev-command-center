# Contribuir

Este repositorio se desarrolla con su propio flujo SDD.

1. Abre un issue describiendo el problema o la propuesta.
2. Crea una rama `feat/…`, `fix/…` o `docs/…`.
3. Si cambias comportamiento, actualiza o crea la spec en `specs/` (requisitos `FR-…` y criterios `AC-…`).
4. Mantén las reglas del kit:
   - Agentes: frontmatter válido y las ocho secciones (Función, Contexto necesario, Responsabilidades, Procedimiento, Límites, Detente si, Criterios de aceptación, Entrega).
   - Skills: rutas internas con `${CLAUDE_SKILL_DIR}`; nunca rutas absolutas personales.
   - Scripts: compatibles con bash 3.2; sin dependencias nuevas.
   - No incluyas software de terceros, secretos ni configuración personal.
5. Ejecuta `bash tests/run.sh` (y `shellcheck` si lo tienes) antes de abrir el PR.
6. Actualiza `CHANGELOG.md` y, si cambia la versión, `VERSION`.
7. Commits en formato Conventional Commits.
