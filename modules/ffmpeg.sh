#!/usr/bin/env bash
# Instala ffmpeg desde apt
set -euo pipefail

if command -v ffmpeg >/dev/null 2>&1; then
    echo "[ffmpeg] ya instalado: $(ffmpeg -version | head -n1)"
    exit 0
fi

echo "[ffmpeg] instalando desde apt..."
sudo apt-get install -y ffmpeg

echo "[ffmpeg] versión: $(ffmpeg -version | head -n1)"
echo "[ffmpeg] listo"
