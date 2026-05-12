#!/bin/bash
# Script para validar el hash SHA256 de un binario descargado
set -e

FILE=$1
EXPECTED_HASH=$2

if [ -z "$FILE" ] || [ -z "$EXPECTED_HASH" ]; then
  echo "Error: Se requieren dos argumentos."
  echo "Uso: $0 <archivo> <hash_esperado>"
  exit 1
fi

echo "Verificando hash SHA256 para: $FILE"

if [ ! -f "$FILE" ]; then
  echo "Error: El archivo $FILE no existe."
  exit 1
fi

ACTUAL_HASH=$(sha256sum "$FILE" | awk '{print $1}')

if [ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]; then
  echo "ERROR CRÍTICO: El hash no coincide."
  echo "Esperado: $EXPECTED_HASH"
  echo "Actual:   $ACTUAL_HASH"
  exit 1
fi

echo "Verificación exitosa. El hash coincide."
exit 0
