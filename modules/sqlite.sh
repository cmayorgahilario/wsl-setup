#!/usr/bin/env bash
# Instala SQLite (CLI + librerías de desarrollo) desde apt.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

if [[ -n "${SQLITE_APT_VERSION:-}" ]]; then
    pkg="sqlite3=${SQLITE_APT_VERSION}"
else
    pkg="sqlite3"
fi

echo "[sqlite] instalando: $pkg libsqlite3-dev"
sudo apt-get install -y "$pkg" libsqlite3-dev

echo "[sqlite] versión: $(sqlite3 --version)"
echo "[sqlite] listo"
