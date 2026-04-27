#!/usr/bin/env bash
# Instala git-cliff desde release binario de GitHub.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

: "${GIT_CLIFF_VERSION:?GIT_CLIFF_VERSION no definido en versions.conf}"

INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

if command -v git-cliff >/dev/null 2>&1; then
    current="$(git-cliff --version | awk '{print $2}')"
    if [[ "$current" == "$GIT_CLIFF_VERSION" ]]; then
        echo "[git-cliff] ya instalado en versión $current"
        exit 0
    fi
    echo "[git-cliff] versión actual: $current, actualizando a $GIT_CLIFF_VERSION"
fi

arch="$(uname -m)"
case "$arch" in
    x86_64)  target="x86_64-unknown-linux-gnu" ;;
    aarch64) target="aarch64-unknown-linux-gnu" ;;
    *) echo "[git-cliff] arquitectura no soportada: $arch" >&2; exit 1 ;;
esac

tarball="git-cliff-${GIT_CLIFF_VERSION}-${target}.tar.gz"
url="https://github.com/orhun/git-cliff/releases/download/v${GIT_CLIFF_VERSION}/${tarball}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "[git-cliff] descargando $url"
curl -fsSL "$url" -o "$tmp/$tarball"
tar -xzf "$tmp/$tarball" -C "$tmp"

bin="$(find "$tmp" -type f -name git-cliff -perm -u+x | head -n1)"
install -m 0755 "$bin" "$INSTALL_DIR/git-cliff"

# Asegurar ~/.local/bin en PATH vía ~/.bashrc
if ! grep -qs 'HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "[git-cliff] añadido ~/.local/bin al PATH en ~/.bashrc"
fi

echo "[git-cliff] instalado: $("$INSTALL_DIR/git-cliff" --version)"
