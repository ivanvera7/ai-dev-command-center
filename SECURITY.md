# Política de seguridad

## Versiones soportadas
Solo la última versión publicada recibe correcciones.

## Reportar una vulnerabilidad
No abras un issue público. Usa el reporte privado de GitHub: pestaña **Security** → **Report a vulnerability** de este repositorio. Incluye pasos para reproducirlo y el impacto.

## Alcance
- `install.sh`, `uninstall.sh`, `update.sh`, `scripts/doctor.sh` y `preflight.sh`.
- Instrucciones de agentes y skills que puedan llevar a publicar secretos, ejecutar operaciones destructivas o saltarse la puerta de calidad.

Las herramientas externas (Superpowers, Context7, Caveman, Ponytail, RTK, frontend-design) tienen sus propios canales de seguridad.

Ver también [docs/security.md](docs/security.md).
