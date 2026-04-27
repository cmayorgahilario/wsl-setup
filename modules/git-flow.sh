#!/usr/bin/env bash
# Instala git-flow (extensión git para modelo de branching)
set -euo pipefail

if command -v git-flow >/dev/null 2>&1; then
    echo "[git-flow] ya instalado: $(git flow version)"
    exit 0
fi

echo "[git-flow] instalando desde apt..."
sudo apt-get install -y git-flow

echo "[git-flow] versión: $(git flow version)"
echo "[git-flow] init en un repo: git flow init"
echo "[git-flow] listo"
