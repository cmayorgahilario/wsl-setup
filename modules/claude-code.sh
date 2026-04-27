#!/usr/bin/env bash
# Instala Claude Code CLI vía instalador oficial.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

: "${CLAUDE_CODE_INSTALLER:?CLAUDE_CODE_INSTALLER no definido en versions.conf}"

if command -v claude >/dev/null 2>&1; then
    echo "[claude-code] ya instalado: $(claude --version 2>/dev/null || echo presente)"
    exit 0
fi

echo "[claude-code] ejecutando instalador: $CLAUDE_CODE_INSTALLER"
curl -fsSL "$CLAUDE_CODE_INSTALLER" | bash

echo "[claude-code] listo (reinicia la shell para que 'claude' esté en PATH)"
