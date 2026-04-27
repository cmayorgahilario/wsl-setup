#!/usr/bin/env bash
# Descarga e instala GitKraken desde el .deb oficial y limpia el archivo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

: "${GITKRAKEN_URL:?GITKRAKEN_URL no definido en versions.conf}"

if command -v gitkraken >/dev/null 2>&1; then
    echo "[gitkraken] ya instalado: $(gitkraken --version 2>/dev/null || echo presente)"
    echo "[gitkraken] (para forzar reinstalación: sudo apt remove gitkraken && reejecutar)"
    exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

deb="$tmp/gitkraken-amd64.deb"
echo "[gitkraken] descargando $GITKRAKEN_URL"
curl -fsSL "$GITKRAKEN_URL" -o "$deb"

echo "[gitkraken] instalando .deb..."
sudo apt-get install -y "$deb"

echo "[gitkraken] eliminando .deb descargado (lo hace trap al salir)"
echo "[gitkraken] listo"
