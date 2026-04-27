#!/usr/bin/env bash
# Instala Oh My Posh + configura tema en ~/.bashrc
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

: "${OHMYPOSH_INSTALLER:?OHMYPOSH_INSTALLER no definido}"
: "${OHMYPOSH_THEME:?OHMYPOSH_THEME no definido}"

INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

if command -v oh-my-posh >/dev/null 2>&1; then
    echo "[ohmyposh] ya instalado: $(oh-my-posh --version)"
else
    echo "[ohmyposh] instalando..."
    curl -fsSL "$OHMYPOSH_INSTALLER" | bash -s -- -d "$INSTALL_DIR"
fi

# Asegurar PATH
if ! grep -qs 'HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

# Config tema en .bashrc
INIT_LINE='eval "$(oh-my-posh init bash --config "$POSH_THEMES_PATH/'"$OHMYPOSH_THEME"'.omp.json")"'

if grep -qs 'oh-my-posh init' "$HOME/.bashrc"; then
    echo "[ohmyposh] init ya presente en ~/.bashrc (no sobrescribo)"
else
    {
        echo ''
        echo '# Oh My Posh'
        echo "$INIT_LINE"
    } >> "$HOME/.bashrc"
    echo "[ohmyposh] añadido init con tema '$OHMYPOSH_THEME' a ~/.bashrc"
fi

echo "[ohmyposh] recuerda instalar Nerd Font (MesloLGS NF, FiraCode NF) en Windows Terminal"
echo "[ohmyposh] listo"
