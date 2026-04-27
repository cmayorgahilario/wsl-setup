#!/usr/bin/env bash
# Instala Pencil desde AppImage (se extrae, no corre con FUSE)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

: "${PENCIL_URL:?PENCIL_URL no definido}"

INSTALL_DIR="$HOME/.local/opt/pencil"
BIN_LINK="$HOME/.local/bin/pencil"
DESKTOP_FILE="$HOME/.local/share/applications/pencil.desktop"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$(dirname "$INSTALL_DIR")"

if [[ -x "$BIN_LINK" ]] && [[ -d "$INSTALL_DIR" ]]; then
    echo "[pencil] ya instalado en $INSTALL_DIR"
    echo "[pencil] usa 'pencil-update' para actualizar"
    exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

appimage="$tmp/Pencil.AppImage"
echo "[pencil] descargando AppImage..."
curl -fsSL "$PENCIL_URL" -o "$appimage"
chmod +x "$appimage"

echo "[pencil] extrayendo AppImage..."
(cd "$tmp" && "$appimage" --appimage-extract >/dev/null)

# Limpiar instalación previa
rm -rf "$INSTALL_DIR"
mv "$tmp/squashfs-root" "$INSTALL_DIR"

# Symlink binario
ln -sf "$INSTALL_DIR/AppRun" "$BIN_LINK"

# Asegurar PATH en .bashrc
if ! grep -qs 'HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

# Buscar ícono (si existe en el AppImage)
icon="$(find "$INSTALL_DIR" -maxdepth 2 -type f \( -name '*.png' -o -name '*.svg' \) 2>/dev/null | head -n1 || true)"

# Crear .desktop
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Pencil
Exec=$BIN_LINK %U
Terminal=false
Type=Application
Icon=${icon:-pencil}
Categories=Graphics;Development;
Comment=Pencil design tool
EOF

# Refrescar DB de .desktop si existe el binario
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

echo "[pencil] instalado en $INSTALL_DIR"
echo "[pencil] ejecutable: $BIN_LINK"
echo "[pencil] uso: pencil &"
