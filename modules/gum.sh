#!/usr/bin/env bash
# Instala gum (Charm CLI) desde .deb oficial
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

: "${GUM_VERSION:?GUM_VERSION no definido}"

if command -v gum >/dev/null 2>&1; then
    current="$(gum --version | awk '{print $3}' | sed 's/^v//')"
    if [[ "$current" == "$GUM_VERSION" ]]; then
        echo "[gum] ya instalado en versión $current"
        exit 0
    fi
    echo "[gum] versión actual $current, actualizando a $GUM_VERSION..."
fi

arch="$(dpkg --print-architecture)"
case "$arch" in
    amd64) target="amd64" ;;
    arm64) target="arm64" ;;
    *) echo "[gum] arquitectura no soportada: $arch" >&2; exit 1 ;;
esac

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

deb="$tmp/gum.deb"
url="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_${target}.deb"

echo "[gum] descargando $url"
curl -fsSL "$url" -o "$deb"

echo "[gum] instalando .deb..."
sudo apt-get install -y "$deb"

echo "[gum] versión: $(gum --version)"
echo "[gum] listo"
