#!/usr/bin/env bash
# Ejecuta todas las pruebas del kit. Uso: bash tests/run.sh
cd "$(dirname "$0")/.." || exit 1
status=0
for t in tests/test_*.sh skills/sdd-release/scripts/preflight.test.sh; do
  echo "== $t"
  bash "$t" || status=1
done
echo
if [ "$status" = 0 ]; then echo "TODAS LAS PRUEBAS PASAN"; else echo "HAY PRUEBAS FALLIDAS"; fi
exit $status
