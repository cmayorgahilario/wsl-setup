#!/usr/bin/env bash
# Instala mkcert (local HTTPS CA + certs firmados)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

: "${MKCERT_VERSION:?MKCERT_VERSION no definido}"

INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# Deps: libnss3-tools para instalar CA en Firefox/Chromium
if ! dpkg -s libnss3-tools >/dev/null 2>&1; then
    echo "[mkcert] instalando libnss3-tools..."
    sudo apt-get install -y libnss3-tools
fi

if command -v mkcert >/dev/null 2>&1; then
    current="$(mkcert -version 2>/dev/null | sed 's/^v//')"
    if [[ "$current" == "$MKCERT_VERSION" ]]; then
        echo "[mkcert] ya instalado en versión $current"
        exit 0
    fi
    echo "[mkcert] versión actual $current, actualizando a $MKCERT_VERSION..."
fi

arch="$(uname -m)"
case "$arch" in
    x86_64)  target="linux-amd64" ;;
    aarch64) target="linux-arm64" ;;
    *) echo "[mkcert] arquitectura no soportada: $arch" >&2; exit 1 ;;
esac

url="https://github.com/FiloSottile/mkcert/releases/download/v${MKCERT_VERSION}/mkcert-v${MKCERT_VERSION}-${target}"

echo "[mkcert] descargando $url"
curl -fsSL "$url" -o "$INSTALL_DIR/mkcert"
chmod +x "$INSTALL_DIR/mkcert"

# PATH en bashrc
if ! grep -qs 'HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

# Instalar root CA local
echo "[mkcert] instalando root CA local..."
"$INSTALL_DIR/mkcert" -install || echo "[mkcert] warn: -install falló (reintenta manual tras abrir navegador)"

echo "[mkcert] versión: $("$INSTALL_DIR/mkcert" -version)"
echo "[mkcert] uso: mkcert example.test localhost 127.0.0.1"
echo "[mkcert] listo"
