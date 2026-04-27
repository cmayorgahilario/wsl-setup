#!/usr/bin/env bash
# Instala Bun (versión fijada en versions.conf)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

: "${BUN_VERSION:?BUN_VERSION no definido}"

export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export PATH="$BUN_INSTALL/bin:$PATH"

if command -v bun >/dev/null 2>&1; then
    current="$(bun --version)"
    if [[ "$current" == "$BUN_VERSION" ]]; then
        echo "[bun] ya instalado en versión $current"
        exit 0
    fi
    echo "[bun] versión actual $current, actualizando a $BUN_VERSION..."
fi

echo "[bun] instalando bun $BUN_VERSION..."
curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}"

# PATH en bashrc
if ! grep -qs 'BUN_INSTALL' "$HOME/.bashrc" 2>/dev/null; then
    {
        echo ''
        echo '# Bun'
        echo 'export BUN_INSTALL="$HOME/.bun"'
        echo 'export PATH="$BUN_INSTALL/bin:$PATH"'
    } >> "$HOME/.bashrc"
fi

echo "[bun] versión: $("$BUN_INSTALL/bin/bun" --version)"
echo "[bun] listo"
