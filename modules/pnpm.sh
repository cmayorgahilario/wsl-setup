#!/usr/bin/env bash
# Instala pnpm standalone (sin depender de Node)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

: "${PNPM_VERSION:?PNPM_VERSION no definido}"

export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
export PATH="$PNPM_HOME:$PATH"

if command -v pnpm >/dev/null 2>&1; then
    current="$(pnpm --version)"
    if [[ "$current" == "$PNPM_VERSION" ]]; then
        echo "[pnpm] ya instalado en versión $current"
        exit 0
    fi
    echo "[pnpm] versión actual $current, actualizando a $PNPM_VERSION..."
fi

echo "[pnpm] instalando pnpm $PNPM_VERSION..."
curl -fsSL "https://get.pnpm.io/install.sh" | env PNPM_VERSION="$PNPM_VERSION" sh -

# El instalador añade PNPM_HOME a bashrc por sí mismo, verificar
if ! grep -qs 'PNPM_HOME' "$HOME/.bashrc" 2>/dev/null; then
    {
        echo ''
        echo '# pnpm'
        echo 'export PNPM_HOME="$HOME/.local/share/pnpm"'
        echo 'export PATH="$PNPM_HOME:$PATH"'
    } >> "$HOME/.bashrc"
fi

echo "[pnpm] versión: $("$PNPM_HOME/pnpm" --version 2>/dev/null || echo instalado)"
echo "[pnpm] listo"
