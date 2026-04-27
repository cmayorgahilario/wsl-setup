#!/usr/bin/env bash
# Librería compartida para módulos.
# Uso desde un módulo:
#   source "${WSL_SETUP_LIB:-$(dirname "$0")/_lib.sh}"
#
# Provee:
#   download_with_retry URL DEST [retries]
#   verify_sha256 FILE EXPECTED
#   download_verified URL DEST EXPECTED_SHA256
#   apt_update_cached [max_age_seconds]
#   already_installed CMD
#   log/ok/warn/err (heredados o redefinidos si se llama directo)

set -euo pipefail

# Reusa colores si ya existen (definidos por install.sh).
: "${C_BLUE:=}"; : "${C_GREEN:=}"; : "${C_YELLOW:=}"; : "${C_RED:=}"; : "${C_RESET:=}"

if ! declare -F log >/dev/null; then
    log()  { printf '%b[mod]%b %s\n' "$C_BLUE"   "$C_RESET" "$*"; }
    ok()   { printf '%b[ok]%b %s\n'  "$C_GREEN"  "$C_RESET" "$*"; }
    warn() { printf '%b[warn]%b %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
    err()  { printf '%b[err]%b %s\n' "$C_RED"    "$C_RESET" "$*" >&2; }
fi

download_with_retry() {
    local url="$1" dest="$2" retries="${3:-3}"
    local attempt=1
    while (( attempt <= retries )); do
        if curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 15 -o "$dest" "$url"; then
            return 0
        fi
        warn "descarga fallida (intento $attempt/$retries): $url"
        ((attempt++))
        sleep $((attempt * 2))
    done
    err "descarga falló tras $retries intentos: $url"
    return 1
}

verify_sha256() {
    local file="$1" expected="$2"
    if [[ -z "$expected" || "$expected" == "SKIP" ]]; then
        warn "checksum SKIP para $(basename "$file") — recomendado fijar SHA256"
        return 0
    fi
    local actual
    actual="$(sha256sum "$file" | awk '{print $1}')"
    if [[ "$actual" != "$expected" ]]; then
        err "checksum mismatch para $file"
        err "  esperado: $expected"
        err "  obtenido: $actual"
        return 1
    fi
    ok "checksum OK: $(basename "$file")"
}

download_verified() {
    local url="$1" dest="$2" expected="${3:-SKIP}"
    download_with_retry "$url" "$dest"
    verify_sha256 "$dest" "$expected"
}

# apt update con cache. Evita repetir update si fue hace <max_age segundos.
apt_update_cached() {
    local max_age="${1:-300}"
    local stamp="/var/lib/apt/periodic/update-success-stamp"
    local now age
    now=$(date +%s)
    if [[ -f "$stamp" ]]; then
        age=$(( now - $(stat -c %Y "$stamp") ))
        if (( age < max_age )); then
            log "apt update reciente (${age}s), skip"
            return 0
        fi
    fi
    sudo apt-get update -y
}

already_installed() {
    command -v "$1" >/dev/null 2>&1
}
