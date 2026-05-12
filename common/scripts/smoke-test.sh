#!/usr/bin/env sh
set -eu

IMAGE_TYPE="${IMAGE_TYPE:-runtime}"

echo "== Smoke test: Node.js =="
node -v
npm -v

echo "== Smoke test: usuario non-root =="
CURRENT_UID="$(id -u)"
CURRENT_USER="$(id -un || true)"

echo "Usuario actual: ${CURRENT_USER}"
echo "UID actual: ${CURRENT_UID}"

if [ "$CURRENT_UID" = "0" ]; then
  echo "ERROR: la imagen se está ejecutando como root."
  exit 1
fi

echo "== Smoke test: permisos básicos =="
node -e "require('fs').writeFileSync('/tmp/smoke-test.txt', 'ok')"
test -f /tmp/smoke-test.txt
rm -f /tmp/smoke-test.txt

echo "== Smoke test: ejecución básica Node.js =="
node -e "console.log('node runtime ok')"

echo "== Smoke test: validaciones específicas runtime =="

if [ "$IMAGE_TYPE" = "runtime" ]; then
  for bin in gcc g++ make git python python3 pip pip3 curl wget; do
    if command -v "$bin" >/dev/null 2>&1; then
      echo "ERROR: '$bin' no debería estar presente en una imagen runtime."
      exit 1
    fi
  done
fi
