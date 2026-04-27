#!/usr/bin/env bash
# Paquetes base del sistema.
set -euo pipefail

PACKAGES=(
    build-essential
    curl
    wget
    git
    unzip
    ca-certificates
    pkg-config
    libssl-dev
)

echo "[base] actualizando índices de apt..."
sudo apt-get update -y

echo "[base] instalando: ${PACKAGES[*]}"
sudo apt-get install -y "${PACKAGES[@]}"

echo "[base] listo"
