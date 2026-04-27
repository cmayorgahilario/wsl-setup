#!/usr/bin/env bash
# Añade alias personales a ~/.bashrc (idempotente)
set -euo pipefail

MARKER_START="# >>> wsl-setup aliases >>>"
MARKER_END="# <<< wsl-setup aliases <<<"

read -r -d '' ALIASES <<'EOF' || true
# Laravel Sail Shortcuts
alias sail='[ -f sail ] && sh sail || sh vendor/bin/sail'
alias art='sail php artisan'
alias vapor='sail bin vapor'
alias fresh='sail php artisan migrate:fresh'

# Helper: confirma con gum si está disponible, sino fallback a read
_confirm() {
    local msg="${1:-Continuar?}"
    if command -v gum >/dev/null 2>&1; then
        gum confirm "$msg"
    else
        printf '%s (yes/no): ' "$msg"
        read -r r
        [ "$r" = "yes" ]
    fi
}

# Helper: mensaje estilizado con gum si hay, sino echo
_say() {
    if command -v gum >/dev/null 2>&1; then
        gum style --foreground 212 "$@"
    else
        echo "$@"
    fi
}

# Pencil update (descarga AppImage, extrae, reemplaza instalación)
pencil-update() {
    local url="https://www.pencil.dev/download/Pencil-linux-x86_64.AppImage"
    local install_dir="$HOME/.local/opt/pencil"
    local bin_link="$HOME/.local/bin/pencil"
    local tmp
    tmp="$(mktemp -d)"
    _say "⬇️  Descargando Pencil..."
    if command -v gum >/dev/null 2>&1; then
        gum spin --spinner dot --title "Descargando Pencil..." -- \
            curl -fsSL "$url" -o "$tmp/Pencil.AppImage" || { rm -rf "$tmp"; return 1; }
    else
        curl -fsSL "$url" -o "$tmp/Pencil.AppImage" || { rm -rf "$tmp"; return 1; }
    fi
    chmod +x "$tmp/Pencil.AppImage"
    _say "📦 Extrayendo..."
    (cd "$tmp" && ./Pencil.AppImage --appimage-extract >/dev/null) || { rm -rf "$tmp"; return 1; }
    rm -rf "$install_dir"
    mkdir -p "$(dirname "$install_dir")"
    mv "$tmp/squashfs-root" "$install_dir"
    ln -sf "$install_dir/AppRun" "$bin_link"
    rm -rf "$tmp"
    _say "✅ Pencil actualizado"
}

# GitKraken update (descarga último .deb, instala, limpia)
gitkraken-update() {
    local url="https://api.gitkraken.com/releases/production/linux/x64/active/gitkraken-amd64.deb"
    local tmp
    tmp="$(mktemp -d)"
    if command -v gum >/dev/null 2>&1; then
        gum spin --spinner dot --title "Descargando GitKraken..." -- \
            curl -fsSL "$url" -o "$tmp/gitkraken-amd64.deb" || { rm -rf "$tmp"; return 1; }
    else
        echo "⬇️  Descargando GitKraken..."
        curl -fsSL "$url" -o "$tmp/gitkraken-amd64.deb" || { rm -rf "$tmp"; return 1; }
    fi
    _say "📦 Instalando..."
    sudo apt-get install -y "$tmp/gitkraken-amd64.deb"
    rm -rf "$tmp"
    _say "✅ GitKraken actualizado"
}

# Git Hard Reset
nah() {
    if _confirm "⚠️  HARD RESET git (reset --hard + clean -fd + rebase abort)?"; then
        _say "🧹 Nuclear cleanup initiated..."
        git reset --hard HEAD
        git clean -fd
        if [ -d ".git/rebase-apply" ] || [ -d ".git/rebase-merge" ]; then
            git rebase --abort
        fi
        _say "✅ Repository sterilized"
    else
        _say "🚫 Mission aborted"
    fi
}
EOF

BLOCK="$MARKER_START
$ALIASES
$MARKER_END"

RC="$HOME/.bashrc"
touch "$RC"

if grep -q "$MARKER_START" "$RC"; then
    echo "[aliases] bloque ya existe, reemplazando..."
    # Borra bloque entre marcadores
    sed -i "/$MARKER_START/,/$MARKER_END/d" "$RC"
fi

{
    echo ''
    echo "$BLOCK"
} >> "$RC"

echo "[aliases] alias escritos en $RC"
echo "[aliases] source ~/.bashrc para cargar"
