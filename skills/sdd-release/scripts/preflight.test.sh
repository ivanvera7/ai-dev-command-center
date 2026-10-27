#!/usr/bin/env bash
# Autotest de preflight.sh en un repo temporal. Uso: preflight.test.sh
# Los secretos de prueba se construyen por partes para que este archivo no se detecte a sí mismo.
set -u
pf="$(cd "$(dirname "$0")" && pwd)/preflight.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cd "$tmp" && git init -q -b feat/x && git config user.email t@example.invalid && git config user.name t
echo base > a.txt && git add a.txt && git commit -qm init
fail=0
check() { # $1 nombre, $2 código esperado, resto comando
  local name="$1" want="$2"; shift 2
  "$@" >/dev/null 2>&1; local got=$?
  if [ "$got" = "$want" ]; then echo "ok   $name"; else echo "FAIL $name (esperado $want, obtenido $got)"; fail=1; fi
}
staged_blocks() { # $1 nombre, $2 archivo, $3 contenido
  printf '%s\n' "$3" > "$2"; git add -f "$2"
  check "$1" 1 bash "$pf"
  git reset -q "$2"; rm -f "$2"
}
gh_tok="ghp""_abcdefghijklmnopqrstuvwxyz0123456789AB"; url_pw="hunter2pass"

echo limpio >> a.txt && git add a.txt
check "cambio limpio pasa" 0 bash "$pf"
check "remoto esperado distinto bloquea" 1 bash "$pf" --expected-remote https://example.com/otro.git
check "--push sin sdd.autoPush bloquea" 1 bash "$pf" --push
git config sdd.autoPush true
check "rama de trabajo con sdd.autoPush permite --push" 0 bash "$pf" --push

staged_blocks "token GitHub bloquea" cfg.txt "token = \"$gh_tok\""
staged_blocks "token GitLab bloquea" cfg.txt "x = glpat""-abcdefghijklmnopqrstuv"
staged_blocks "clave Stripe de test bloquea" cfg.txt "k = sk_""test_abcdefghijklmnopqrstuv"
staged_blocks "contraseña sin comillas bloquea" cfg.env.txt "DB_PASS""WORD=s3cr3tPassw0rd"
staged_blocks "URL con credenciales bloquea" cfg.txt "url: https://user:${url_pw}@db.example.com/x"
staged_blocks "JWT bloquea" cfg.txt "auth: eyJ""hbGciOiJIUzI1NiJ9.eyJ""zdWIiOiIxMjM0NTY3ODkwIn0.abc"
staged_blocks ".git-credentials bloquea" .git-credentials "x"
staged_blocks "terraform.tfstate bloquea" terraform.tfstate "{}"
staged_blocks ".envrc bloquea" .envrc "export X=1"

staged_blocks "token junto a una referencia sigue bloqueando" cfg.txt "curl -H \"Authorization: token $gh_tok\" \$API_URL"
staged_blocks "token en JSON junto a \${} sigue bloqueando" cfg.json "{\"token\": \"$gh_tok\", \"url\": \"\${base}\"}"
staged_blocks "línea añadida que empieza por ++ se escanea" cfg.txt "++ $gh_tok"
printf 'TOKEN=${GITHUB_TOKEN}\napi_key: process.env.API_KEY\n' > ok.txt && git add ok.txt
check "referencias a variables no bloquean" 0 bash "$pf"
git reset -q ok.txt && rm ok.txt

echo "token = \"$gh_tok\"" > hidden.cfg && echo '*.cfg -diff' > .gitattributes && git add hidden.cfg .gitattributes
check "atributo -diff no oculta un secreto" 1 bash "$pf"
out=$(bash "$pf" 2>&1)
case "$out" in *"hidden.cfg:1"*) echo "ok   indica archivo:línea" ;; *) echo "FAIL indica archivo:línea"; fail=1 ;; esac
case "$out" in *abcdefghij*) echo "FAIL no imprime el secreto"; fail=1 ;; *) echo "ok   no imprime el secreto" ;; esac
git reset -q && rm -f hidden.cfg .gitattributes

echo "SECRET=x" > .env && git add -f .env
check ".env bloquea" 1 bash "$pf"
git reset -q .env && rm .env
echo "SECRET=" > .env.example && git add .env.example
check ".env.example permitido" 0 bash "$pf"
printf '%s\n' '-----BEGIN OPENSSH PRIVATE ''KEY-----' > notes.txt
check "secreto no rastreado detectado en --scan-only" 1 bash "$pf" --scan-only
printf 'bin\000 token = "%s"\n' "$gh_tok" > blob.bin
rm notes.txt
check "secreto en archivo binario no rastreado detectado" 1 bash "$pf" --scan-only
rm blob.bin; git reset -q
check "staging vacío bloquea" 1 bash "$pf"
git checkout -q -b main
check "--push en la rama por defecto bloquea" 1 bash "$pf" --push
check "fuera de git devuelve 2" 2 bash -c "cd / && bash '$pf'"
exit $fail
