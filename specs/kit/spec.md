# Spec — kit

- Estado: aprobada (petición del propietario del 2026-10-27)
- Relacionado: plan.md · tasks.md · acceptance.md

## Contexto
El propietario configuró en su máquina un sistema SDD global para Claude Code (11 agentes en `~/.claude/agents/`, 11 skills `sdd-*` en `~/.claude/skills/`, una sección SDD en `~/.claude/CLAUDE.md`). Quiere distribuirlo como un kit instalable y publicable en GitHub, con la intención de presentación de `ivanvera7/kit-vibecoding-pro`, sin modificar ni reutilizar ese repositorio.

## Requisitos funcionales
- FR-001: El kit contiene los agentes reales del sistema, cada uno con función, contexto, responsabilidades, procedimiento, límites, condiciones para detenerse, criterios de aceptación y formato de entrega.
- FR-002: El kit contiene las 11 skills `sdd-*` con su contenido funcional, plantillas y scripts.
- FR-003: Ningún archivo del kit depende de rutas absolutas de la máquina del propietario.
- FR-004: `install.sh` instala componentes seleccionables (agentes, skills, instrucciones) en modo global (`~/.claude`) o de proyecto (`<dir>/.claude` y `<dir>/CLAUDE.md`).
- FR-005: El instalador muestra el plan de cambios antes de aplicarlos y ofrece `--dry-run`.
- FR-006: El instalador no sobrescribe en silencio archivos existentes que no instaló él o que el usuario modificó; los trata como conflicto (omitir por defecto, sustituir con copia de seguridad solo con `--force`).
- FR-007: El instalador detecta instalaciones previas mediante un manifiesto y actualiza solo archivos del kit no modificados.
- FR-008: `uninstall.sh` elimina solo archivos registrados en el manifiesto que no fueron modificados y retira el bloque de instrucciones del kit.
- FR-009: Las instrucciones se insertan en `CLAUDE.md` entre marcadores, conservando el resto del archivo.
- FR-010: `scripts/doctor.sh` informa de requisitos y herramientas externas (instaladas o no) y de cómo instalarlas, sin instalarlas.
- FR-011: Documentación: README de producto y guías de instalación, arquitectura, agentes, skills, flujo SDD, integraciones, memoria, seguridad, GitHub, solución de problemas y personalización.
- FR-012: El repositorio incluye pruebas automáticas del instalador y del preflight, y un workflow de CI.

## Requisitos no funcionales
- NFR-001: Scripts compatibles con bash 3.2 (macOS) y Linux.
- NFR-002: Sin secretos, credenciales ni datos personales en el repo.
- NFR-003: El kit funciona sin herramientas opcionales (Superpowers, Context7, Caveman, Ponytail, RTK, frontend-design); solo pierde las capacidades que estas aportan.

## Supuestos
- A-01: Licencia MIT con el mismo titular que el repo de referencia ("Ivan Vera").
- A-02: Documentación en español (como la referencia); versión en inglés fuera de alcance de esta versión.
- A-03: El perfil "integraciones" lo cubre `backend-specialist` y el de "diseño de interfaces" lo cubre `frontend-specialist` con frontend-design; no se crean duplicados. Se añade `devops-specialist` porque ningún agente existente cubre CI/CD ni configuración de despliegue.
- A-04: El kit no incluye hooks propios: el sistema real no tiene ninguno (los hooks presentes pertenecen a RTK, Caveman y pixel-agents).

## Preguntas abiertas
- Q-01 (resuelta 2026-10-27): `ivanvera7/ai-dev-command-center`, público.

## Criterios de aceptación
- AC-001 (FR-001): cada archivo de `agents/` tiene frontmatter `name` y `description` y las secciones exigidas.
- AC-002 (FR-002): existen las 11 skills con `SKILL.md` con frontmatter válido; las plantillas y scripts referenciados existen.
- AC-003 (FR-003, NFR-002): un escaneo no encuentra `/Users/`, `/home/` ni patrones de secretos en el repo.
- AC-004 (FR-004): instalación global en un `HOME` temporal coloca agentes, skills y el bloque en las rutas esperadas; instalación de proyecto lo hace bajo el proyecto.
- AC-005 (FR-005): `--dry-run` no modifica nada.
- AC-006 (FR-006): un archivo preexistente distinto no se sobrescribe sin `--force`; con `--force` se guarda copia.
- AC-007 (FR-007): reinstalar detecta la instalación previa; un archivo del kit modificado por el usuario se conserva en la actualización.
- AC-008 (FR-008, FR-009): la desinstalación deja el `CLAUDE.md` del usuario igual que antes de instalar y conserva archivos ajenos y modificados.
- AC-009 (FR-010): `doctor.sh` termina sin error y lista cada herramienta como encontrada o ausente.
- AC-010 (FR-012): `bash tests/run.sh` pasa en macOS; las pruebas del preflight pasan.
- AC-011 (FR-002): una sesión real de Claude Code con el kit instalado en un `HOME` aislado carga los agentes y las skills SDD.

## Registro de cambios
- 2026-10-27: creación.
