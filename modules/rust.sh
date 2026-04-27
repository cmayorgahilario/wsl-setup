#!/usr/bin/env bash
# Instala rustup + toolchain fijo (lee RUST_TOOLCHAIN de versions.conf).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

: "${RUST_TOOLCHAIN:?RUST_TOOLCHAIN no está definido en versions.conf}"

export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
export PATH="$CARGO_HOME/bin:$PATH"

if ! command -v rustup >/dev/null 2>&1; then
    echo "[rust] instalando rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --no-modify-path --default-toolchain "$RUST_TOOLCHAIN"
else
    echo "[rust] rustup ya presente"
fi

echo "[rust] asegurando toolchain $RUST_TOOLCHAIN como default..."
rustup toolchain install "$RUST_TOOLCHAIN"
rustup default "$RUST_TOOLCHAIN"

# Componentes útiles.
rustup component add rustfmt clippy --toolchain "$RUST_TOOLCHAIN"

echo "[rust] versión instalada: $(rustc --version)"
echo "[rust] listo"

# Sugerir añadir cargo al PATH si la shell actual no lo tiene en el rc.
if ! grep -qs 'cargo/env' "$HOME/.bashrc" 2>/dev/null; then
    echo '. "$HOME/.cargo/env"' >> "$HOME/.bashrc"
    echo "[rust] añadido source de cargo/env a ~/.bashrc"
fi
