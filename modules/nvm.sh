#!/usr/bin/env bash
# Instala NVM y Node (LTS por defecto).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

: "${NVM_VERSION:?NVM_VERSION no definido en versions.conf}"
: "${NODE_VERSION:?NODE_VERSION no definido en versions.conf (usa 'lts' o una versión)}"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    echo "[nvm] ya instalado en $NVM_DIR"
else
    echo "[nvm] instalando nvm v$NVM_VERSION..."
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
fi

# Cargar nvm en esta shell
# shellcheck disable=SC1091
\. "$NVM_DIR/nvm.sh"

if [[ "$NODE_VERSION" == "lts" ]]; then
    echo "[nvm] instalando Node LTS..."
    nvm install --lts
    nvm alias default 'lts/*'
    nvm use --lts
else
    echo "[nvm] instalando Node $NODE_VERSION..."
    nvm install "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"
    nvm use "$NODE_VERSION"
fi

echo "[nvm] node: $(node --version)"
echo "[nvm] npm:  $(npm --version)"
echo "[nvm] listo"
