#!/usr/bin/env bash
# Instala SDKMAN + Java Temurin (versión de versions.conf).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../versions.conf"

: "${JAVA_VERSION:?JAVA_VERSION no definido en versions.conf}"

export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"

# zip/unzip son requeridos por SDKMAN
if ! command -v unzip >/dev/null 2>&1 || ! command -v zip >/dev/null 2>&1; then
    echo "[sdkman] instalando dependencias: zip unzip"
    sudo apt-get install -y zip unzip
fi

if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    echo "[sdkman] ya instalado en $SDKMAN_DIR"
else
    echo "[sdkman] instalando SDKMAN..."
    curl -fsSL "https://get.sdkman.io?rcupdate=true" | bash
fi

# Cargar en esta shell
set +u  # sdkman tiene referencias a variables no seteadas
# shellcheck disable=SC1091
source "$SDKMAN_DIR/bin/sdkman-init.sh"
set -u

# Aceptar selecciones automáticamente
export sdkman_auto_answer=true

if sdk current java 2>/dev/null | grep -q "$JAVA_VERSION"; then
    echo "[sdkman] java $JAVA_VERSION ya activo"
else
    echo "[sdkman] instalando java $JAVA_VERSION..."
    set +u
    sdk install java "$JAVA_VERSION" || true
    sdk default java "$JAVA_VERSION"
    set -u
fi

echo "[sdkman] java: $(java -version 2>&1 | head -n1)"
echo "[sdkman] listo"
