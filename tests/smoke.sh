#!/usr/bin/env bash
# Smoke tests del orquestador. No instala nada; solo verifica flags y validaciones.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="$SCRIPT_DIR/install.sh"

pass=0
fail=0

assert() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "  ✓ $desc"
        pass=$((pass + 1))
    else
        echo "  ✗ $desc"
        fail=$((fail + 1))
    fi
}

assert_fails() {
    local desc="$1"; shift
    if ! "$@" >/dev/null 2>&1; then
        echo "  ✓ $desc"
        pass=$((pass + 1))
    else
        echo "  ✗ $desc (debió fallar)"
        fail=$((fail + 1))
    fi
}

echo "Smoke tests: $INSTALL"

assert "syntax check"             bash -n "$INSTALL"
assert "--version sale 0"         "$INSTALL" --version
assert "--help sale 0"            "$INSTALL" --help
assert "--list sale 0"            "$INSTALL" --list
assert_fails "flag desconocida falla" "$INSTALL" --bogus
assert_fails "módulo inexistente falla" "$INSTALL" no-existe-modulo

# --list debe imprimir al menos 10 módulos.
count=$("$INSTALL" --list | wc -l)
if (( count >= 10 )); then
    echo "  ✓ --list imprime $count módulos"
    pass=$((pass + 1))
else
    echo "  ✗ --list imprime solo $count módulos"
    fail=$((fail + 1))
fi

# Sintaxis de cada módulo.
for f in "$SCRIPT_DIR"/modules/*.sh; do
    assert "syntax: $(basename "$f")" bash -n "$f"
done

echo
echo "Resultado: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
