#!/usr/bin/env bash
# Genera clave SSH ed25519 si no existe, arranca ssh-agent, muestra pubkey
set -euo pipefail

KEY_PATH="$HOME/.ssh/id_ed25519"
PUB_PATH="$KEY_PATH.pub"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ -f "$KEY_PATH" ]]; then
    echo "[ssh-key] ya existe: $KEY_PATH"
else
    # Comentario: usa git user.email si existe, sino hostname
    comment="$(git config --global user.email 2>/dev/null || echo "$USER@$(hostname)")"
    echo "[ssh-key] generando ed25519 (comentario: $comment, sin passphrase)"
    ssh-keygen -t ed25519 -C "$comment" -f "$KEY_PATH" -N ""
fi

chmod 600 "$KEY_PATH"
chmod 644 "$PUB_PATH"

# Arrancar ssh-agent y añadir clave
if [[ -z "${SSH_AUTH_SOCK:-}" ]] || ! ssh-add -l >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null
fi
ssh-add "$KEY_PATH" 2>/dev/null || true

# Auto-start agent en bashrc (evita repetir eval manual)
if ! grep -qs 'ssh-agent.*start' "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'EOF'

# Auto-start ssh-agent
if [ -z "$SSH_AUTH_SOCK" ]; then
    if ! pgrep -u "$USER" ssh-agent >/dev/null; then
        ssh-agent -s >"$HOME/.ssh/agent.env"
    fi
    [ -f "$HOME/.ssh/agent.env" ] && . "$HOME/.ssh/agent.env" >/dev/null
fi
EOF
fi

echo ""
echo "[ssh-key] clave pública:"
echo "----------------------------------------------------------------"
cat "$PUB_PATH"
echo "----------------------------------------------------------------"
echo "[ssh-key] copiar a GitHub: https://github.com/settings/ssh/new"
echo "[ssh-key] test: ssh -T git@github.com"
