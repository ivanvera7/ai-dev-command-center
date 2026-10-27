# Seguridad

## Qué garantiza el kit

| Riesgo | Control | Dónde |
|---|---|---|
| Publicar secretos | `preflight.sh` escanea staging (y, con `--scan-only`, cambios sin confirmar y archivos no rastreados) | `skills/sdd-release/scripts/preflight.sh` |
| Publicar archivos sensibles | bloquea `.env*` (salvo `.example/.sample/.template`), `.envrc`, claves `.pem/.key/.p12/.pfx/.ppk/.jks/.keystore`, `AuthKey_*.p8`, `id_rsa*`, `credentials.json`, `service-account*.json`, `.npmrc`, `.pypirc`, `.netrc`, `.git-credentials`, `.aws/credentials`, `.docker/config.json`, `*.tfstate`, `*.tfvars`, `.claude/settings.local.json` | idem |
| Publicar en el sitio equivocado | push automático desactivado salvo `git config --local sdd.autoPush true` en tu clon (no viaja con el repo); `--expected-remote`; `--push` bloquea la rama por defecto (`main`, `master`, `origin/HEAD`) | idem + `sdd-release` |
| Ocultar contenido al escaneo | el diff se lee con `--no-ext-diff --no-textconv --text` (ignora `.gitattributes -diff`, textconv y diff externos); los no rastreados se leen también si son binarios | `preflight.sh` |
| Filtrar el secreto al informar | el preflight solo muestra `archivo:línea`, nunca el contenido | `preflight.sh` |
| Código inseguro | `security-reviewer` cuando el diff toca auth, entradas, datos, red, ficheros, despliegue o dependencias; críticos y altos bloquean | `sdd-review` |
| Operaciones destructivas | force push, reescritura de historial, despliegues y migraciones destructivas requieren autorización específica | bloque `CLAUDE.md`, `sdd-release`, agentes |
| Instalador | no pide credenciales ni instala herramientas externas; valida el manifiesto; rechaza enlaces simbólicos en modo proyecto; copia de seguridad antes de sustituir o retirar | `install.sh`, `uninstall.sh`, `lib/common.sh` |

## Guardarraíles deterministas

El guard de Claude Code, los hooks de Git por proyecto y el CI con rama protegida están descritos en [guardrails.md](guardrails.md).

## Patrones de secretos detectados

Claves de AWS (`AKIA…`), tokens de GitHub (`ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`, `github_pat_`), GitLab (`glpat-`), npm (`npm_`), claves `sk-…` (incluidas `sk-ant-` y `sk-proj-`), Stripe (`sk_live_`, `sk_test_`, `rk_live_`), Slack (`xox?-`), Google (`AIza…`), JWT, `Bearer …`, URL con usuario y contraseña, bloques `PRIVATE KEY`, y asignaciones `password|secret|api_key|access_key|token… = valor` de 8 o más caracteres, con o sin comillas. En la regla genérica de asignación, un valor que sea una referencia a variable (`${X}`, `$X`, `process.env`, `os.environ`, `getenv`, `secrets.X`, `<placeholder>`) no cuenta. Los patrones de proveedor (AKIA, ghp_, glpat-, sk-, xox, AIza, JWT, PRIVATE KEY, URL con credenciales…) bloquean siempre, aunque la línea contenga referencias.

Es un filtro heurístico: reduce el riesgo, no lo elimina. Para proyectos con datos sensibles, añade una herramienta dedicada (p. ej. gitleaks) a la constitución y a CI.

## Lo que el kit no hace

- No gestiona tus credenciales ni las de GitHub.
- No sustituye las protecciones de rama de GitHub: actívalas en los repos importantes.
- No audita dependencias por sí mismo: `security-reviewer` ejecuta la auditoría del gestor del proyecto si está disponible y dice cuando no lo está.

## Herramientas de terceros

Instala cada herramienta solo desde su fuente oficial (ver [integrations.md](integrations.md)). Existen repositorios que imitan herramientas populares para distribuir ejecutables.

Para reportar un problema de seguridad del kit, ver [SECURITY.md](../SECURITY.md).
