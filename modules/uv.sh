#!/usr/bin/env bash
# Instala uv (Astral) + Python default
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

: "${UV_VERSION:?UV_VERSION no definido}"
: "${UV_PYTHON_VERSION:?UV_PYTHON_VERSION no definido}"

export PATH="$HOME/.local/bin:$PATH"

if command -v uv >/dev/null 2>&1; then
    current="$(uv --version | awk '{print $2}')"
    if [[ "$current" == "$UV_VERSION" ]]; then
        echo "[uv] ya instalado en versión $current"
    else
        echo "[uv] versión actual $current, reinstalando $UV_VERSION..."
        curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" | sh
    fi
else
    echo "[uv] instalando versión $UV_VERSION..."
    curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" | sh
fi

# PATH en bashrc
if ! grep -qs 'HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

# Instalar Python default
echo "[uv] instalando Python $UV_PYTHON_VERSION..."
"$HOME/.local/bin/uv" python install "$UV_PYTHON_VERSION"

# Habilitar shell completions
if ! grep -qs 'uv generate-shell-completion' "$HOME/.bashrc" 2>/dev/null; then
    {
        echo ''
        echo '# uv completions'
        echo 'eval "$(uv generate-shell-completion bash)"'
        echo 'eval "$(uvx --generate-shell-completion bash)" 2>/dev/null || true'
    } >> "$HOME/.bashrc"
fi

echo "[uv] $("$HOME/.local/bin/uv" --version)"
echo "[uv] Python: $("$HOME/.local/bin/uv" python list --only-installed | head -n1)"
echo "[uv] listo"
