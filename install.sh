#!/usr/bin/env bash
# Orquestador de instalación para WSL Ubuntu.
# Uso:
#   ./install.sh                    # ejecuta todos los módulos en orden
#   ./install.sh rust base          # ejecuta solo los módulos indicados
#   ./install.sh --dry-run          # muestra qué correría sin ejecutar
#   ./install.sh --force            # ignora markers de instalación previa
#   ./install.sh --list             # lista módulos disponibles (parseable)
#   ./install.sh --status           # muestra estado de instalación
#   ./install.sh --uninstall <mod>  # borra marker (no desinstala paquetes)
#   ./install.sh --help             # ayuda
#   ./install.sh --version          # versión

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
CONFIG_FILE="$SCRIPT_DIR/versions.conf"
MARKER_DIR="$SCRIPT_DIR/.installed"
LOG_DIR="$SCRIPT_DIR/.logs"
LOCK_FILE="/tmp/wsl-setup.lock"
LIB_FILE="$MODULES_DIR/_lib.sh"

# Versión del orquestador (git describe si disponible, fallback fijo).
SUITE_VERSION_FALLBACK="0.3.0"
if command -v git >/dev/null 2>&1 && git -C "$SCRIPT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    SUITE_VERSION="$(git -C "$SCRIPT_DIR" describe --tags --always --dirty 2>/dev/null || echo "$SUITE_VERSION_FALLBACK")"
else
    SUITE_VERSION="$SUITE_VERSION_FALLBACK"
fi

# Orden explícito por dependencias. base primero, aliases último.
MODULE_ORDER=(
    base
    rust
    nvm
    bun
    pnpm
    uv
    gh
    sdkman
    sqlite
    mkcert
    gum
    git-cliff
    git-flow
    ffmpeg
    ohmyposh
    ssh-key
    claude-code
    gitkraken
    pencil
    aliases
)

DRY_RUN=0
FORCE=0
ACTION="install"
UNINSTALL_TARGET=""
CURRENT_MODULE=""

if [[ -t 1 ]]; then
    C_BLUE='\033[1;34m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'
    C_RED='\033[1;31m'; C_DIM='\033[2m'; C_RESET='\033[0m'
else
    C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_DIM=''; C_RESET=''
fi

log()  { printf '%b[install]%b %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()   { printf '%b[ ok   ]%b %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%b[warn  ]%b %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
err()  { printf '%b[error ]%b %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
dim()  { printf '%b%s%b\n' "$C_DIM" "$*" "$C_RESET"; }

usage() {
    cat <<EOF
wsl-setup v$SUITE_VERSION — orquestador de instalación

Uso:
  $(basename "$0") [opciones] [módulo...]

Opciones:
  --dry-run         Muestra módulos a ejecutar y sale.
  --force           Reinstala aunque exista marker.
  --list            Lista módulos (parseable, uno por línea).
  --status          Muestra estado de instalación de cada módulo.
  --uninstall MOD   Borra marker del módulo (no remueve paquetes).
  --help, -h        Esta ayuda.
  --version         Muestra versión y sale.

Sin argumentos: ejecuta todos los módulos en orden de dependencias.
Con argumentos: ejecuta solo los módulos indicados (en el orden dado).

Módulos disponibles:
$(printf '  %s\n' "${MODULE_ORDER[@]}")
EOF
}

verify_environment() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
    fi
    if [[ "${ID:-}" != "ubuntu" ]]; then
        err "requiere Ubuntu (detectado: ${ID:-desconocido})"
        exit 1
    fi
    if ! grep -qi microsoft /proc/version 2>/dev/null; then
        warn "no detectado WSL, continuando bajo tu responsabilidad"
    fi
}

load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        err "config no encontrado: $CONFIG_FILE"
        exit 1
    fi
    set -a
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
    set +a
    # Exportar paths útiles a módulos.
    export WSL_SETUP_DIR="$SCRIPT_DIR"
    export WSL_SETUP_LIB="$LIB_FILE"
}

setup_logging() {
    mkdir -p "$LOG_DIR"
    local log_file
    log_file="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
    exec > >(tee -a "$log_file") 2>&1
    log "log: $log_file"
}

acquire_lock() {
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
        err "otra instancia de $(basename "$0") está corriendo (lock: $LOCK_FILE)"
        exit 1
    fi
}

on_error() {
    local exit_code=$?
    local line=$1
    err "fallo (exit=$exit_code) en línea $line — módulo: ${CURRENT_MODULE:-orquestador}"
    exit "$exit_code"
}

validate_modules() {
    local m missing=0
    for m in "$@"; do
        if [[ ! -f "$MODULES_DIR/${m}.sh" ]]; then
            err "módulo no encontrado: $m"
            missing=1
        fi
    done
    [[ $missing -eq 0 ]]
}

check_module_safety() {
    local file="$1"
    if ! head -10 "$file" | grep -q 'set -euo pipefail'; then
        warn "$(basename "$file" .sh): falta 'set -euo pipefail'"
    fi
}

write_marker() {
    local name="$1"
    local marker="$MARKER_DIR/$name"
    mkdir -p "$MARKER_DIR"
    {
        echo "module=$name"
        echo "installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "suite_version=$SUITE_VERSION"
        echo "host=$(hostname)"
    } > "$marker"
}

run_module() {
    local name="$1"
    local idx="$2"
    local total="$3"
    local file="$MODULES_DIR/${name}.sh"
    local marker="$MARKER_DIR/$name"

    if [[ ! -f "$file" ]]; then
        err "módulo no encontrado: $name ($file)"
        return 1
    fi

    if [[ $FORCE -eq 0 && -f "$marker" ]]; then
        ok "[$idx/$total] $name ya instalado, skip"
        return 0
    fi

    check_module_safety "$file"

    CURRENT_MODULE="$name"
    log "[$idx/$total] ejecutando módulo: $name"

    if [[ $DRY_RUN -eq 1 ]]; then
        dim "  [dry-run] no ejecutado"
        CURRENT_MODULE=""
        return 0
    fi

    bash "$file"
    write_marker "$name"
    ok "[$idx/$total] módulo completado: $name"
    CURRENT_MODULE=""
}

shell_hint() {
    local rc
    case "$(basename "${SHELL:-bash}")" in
        zsh)  rc="$HOME/.zshrc" ;;
        fish) rc="$HOME/.config/fish/config.fish" ;;
        *)    rc="$HOME/.bashrc" ;;
    esac
    warn "reinicia la shell (o: source $rc) para cargar los PATH nuevos"
}

cmd_list() {
    printf '%s\n' "${MODULE_ORDER[@]}"
}

cmd_status() {
    local m marker
    printf '%-15s %-12s %s\n' "MÓDULO" "ESTADO" "DETALLES"
    printf '%-15s %-12s %s\n' "------" "------" "--------"
    for m in "${MODULE_ORDER[@]}"; do
        marker="$MARKER_DIR/$m"
        if [[ -f "$marker" ]]; then
            local ts ver
            ts="$(grep -E '^installed_at=' "$marker" | cut -d= -f2 || echo '?')"
            ver="$(grep -E '^suite_version=' "$marker" | cut -d= -f2 || echo '?')"
            printf '%-15s %b%-12s%b %s (suite=%s)\n' "$m" "$C_GREEN" "instalado" "$C_RESET" "$ts" "$ver"
        else
            printf '%-15s %b%-12s%b -\n' "$m" "$C_YELLOW" "pendiente" "$C_RESET"
        fi
    done
}

cmd_uninstall_marker() {
    local name="$1"
    validate_modules "$name" || exit 1
    local marker="$MARKER_DIR/$name"
    if [[ ! -f "$marker" ]]; then
        warn "$name no tenía marker"
        return 0
    fi
    rm -f "$marker"
    ok "marker eliminado: $name"
    warn "no se desinstalaron paquetes; vuelve a ejecutar el módulo o remueve manualmente"
}

main() {
    local positional=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)   DRY_RUN=1; shift ;;
            --force)     FORCE=1; shift ;;
            --list)      ACTION="list"; shift ;;
            --status)    ACTION="status"; shift ;;
            --uninstall) ACTION="uninstall"; UNINSTALL_TARGET="${2:-}"; shift 2 ;;
            --help|-h)   usage; exit 0 ;;
            --version)   echo "wsl-setup v$SUITE_VERSION"; exit 0 ;;
            --)          shift; positional+=("$@"); break ;;
            -*)          err "opción desconocida: $1"; usage; exit 1 ;;
            *)           positional+=("$1"); shift ;;
        esac
    done

    case "$ACTION" in
        list)      cmd_list; exit 0 ;;
        status)    cmd_status; exit 0 ;;
        uninstall)
            [[ -z "$UNINSTALL_TARGET" ]] && { err "--uninstall requiere nombre de módulo"; exit 1; }
            cmd_uninstall_marker "$UNINSTALL_TARGET"
            exit 0
            ;;
    esac

    trap 'on_error $LINENO' ERR

    verify_environment
    load_config
    [[ $DRY_RUN -eq 0 ]] && acquire_lock
    [[ $DRY_RUN -eq 0 ]] && setup_logging

    log "suite: $(basename "$SCRIPT_DIR") v$SUITE_VERSION"
    log "config: $CONFIG_FILE"
    [[ $DRY_RUN -eq 1 ]] && log "modo: DRY-RUN"
    [[ $FORCE -eq 1 ]]   && log "modo: FORCE (ignora markers)"

    local modules=()
    if [[ ${#positional[@]} -eq 0 ]]; then
        modules=("${MODULE_ORDER[@]}")
    else
        validate_modules "${positional[@]}" || exit 1
        modules=("${positional[@]}")
    fi

    log "módulos a ejecutar (${#modules[@]}): ${modules[*]}"

    if [[ $DRY_RUN -eq 1 ]]; then
        local i=1
        for m in "${modules[@]}"; do
            run_module "$m" "$i" "${#modules[@]}"
            ((i++))
        done
        ok "dry-run completo"
        exit 0
    fi

    local i=1
    for m in "${modules[@]}"; do
        run_module "$m" "$i" "${#modules[@]}"
        ((i++))
    done

    ok "instalación completa"
    shell_hint
}

main "$@"
