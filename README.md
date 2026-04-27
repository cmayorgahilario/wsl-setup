# wsl-setup

Suite de scripts para reinstalar mi entorno WSL Ubuntu tras formatear la PC. Cada módulo instala una herramienta con su versión fijada en `versions.conf`.

## Para qué sirve

- Reinstalar todo mi stack en un solo comando tras formatear Windows / reinstalar WSL.
- Mantener **versiones consistentes** entre máquinas (todas definidas en un único archivo).
- Idempotente: ejecutable múltiples veces sin romper nada.
- Modular: puedes instalar solo lo que necesitas.

## Estructura

```
wsl-setup/
├── install.sh              # orquestador — corre módulos
├── versions.conf           # ÚNICA fuente de verdad para versiones
├── modules/                # cada módulo = 1 herramienta
│   ├── _lib.sh             # helpers compartidos (download_verified, etc.)
│   ├── base.sh             # build-essential, curl, git, libssl-dev, ...
│   ├── aliases.sh          # alias + funciones en ~/.bashrc
│   ├── bun.sh              # Bun runtime JS
│   ├── claude-code.sh      # Claude Code CLI
│   ├── ffmpeg.sh           # ffmpeg (apt)
│   ├── gh.sh               # GitHub CLI
│   ├── git-cliff.sh        # changelog generator
│   ├── git-flow.sh         # git-flow branching model
│   ├── gitkraken.sh        # GitKraken .deb
│   ├── gum.sh              # Charm gum CLI
│   ├── mkcert.sh           # HTTPS local con CA propia
│   ├── nvm.sh              # NVM + Node LTS
│   ├── ohmyposh.sh         # prompt (theme iterm2)
│   ├── pencil.sh           # Pencil design tool (AppImage extraído)
│   ├── pnpm.sh             # pnpm standalone
│   ├── rust.sh             # rustup + toolchain fijado
│   ├── sdkman.sh           # SDKMAN + Java Temurin LTS
│   ├── sqlite.sh           # sqlite3 + libsqlite3-dev
│   ├── ssh-key.sh          # genera ed25519 si no existe
│   └── uv.sh               # uv + Python 3.12
├── tests/
│   └── smoke.sh            # smoke tests (flags + sintaxis módulos)
└── README.md
```

## Uso

### Primera vez tras formatear

```bash
# 1. Clonar repo
git clone <tu-repo> ~/code/tools
cd ~/code/tools/wsl-setup

# 2. Permisos (solo primera vez)
chmod +x install.sh modules/*.sh

# 3. Instalar todo
./install.sh

# 4. Recargar shell
source ~/.bashrc
```

### Módulos selectivos

```bash
./install.sh rust                       # solo Rust
./install.sh nvm bun pnpm               # runtimes JS
./install.sh base aliases ohmyposh      # mínimo + shell
```

### Flags del orquestador

```bash
./install.sh --help              # ayuda
./install.sh --version           # versión (git describe)
./install.sh --list              # lista módulos (parseable)
./install.sh --status            # qué está instalado
./install.sh --dry-run           # simular sin ejecutar
./install.sh --force             # ignorar markers
./install.sh --uninstall <mod>   # borrar marker (no remueve paquetes)
```

### Estado y markers

Tras instalar, cada módulo deja `.installed/<modulo>` con metadata (timestamp, suite version, host). Re-ejecutar saltea módulos ya instalados salvo `--force`.

Logs en `.logs/install-YYYYMMDD-HHMMSS.log`.

## Actualizar versiones

Editar **`versions.conf`** (único lugar). Ejemplo:

```bash
RUST_TOOLCHAIN="1.84.0"      # antes 1.83.0
NODE_VERSION="22.11.0"       # antes "lts"
JAVA_VERSION="25.0.1-tem"    # antes 21.0.5-tem
BUN_VERSION="1.2.0"          # antes 1.1.42
```

Reejecuta solo los módulos cambiados:
```bash
./install.sh rust nvm sdkman bun
```

## Módulos incluidos

| Módulo | Herramienta | Versión | Fuente |
|---|---|---|---|
| `base` | build-essential, curl, git, etc. | apt | Ubuntu repos |
| `rust` | rustup + toolchain | `$RUST_TOOLCHAIN` | rustup.rs |
| `nvm` | NVM + Node | `$NVM_VERSION` / `$NODE_VERSION` | github.com/nvm-sh/nvm |
| `bun` | Bun runtime | `$BUN_VERSION` | bun.sh |
| `pnpm` | pnpm | `$PNPM_VERSION` | get.pnpm.io |
| `uv` | uv + Python | `$UV_VERSION` / `$UV_PYTHON_VERSION` | astral.sh |
| `sdkman` | SDKMAN + Java Temurin | `$JAVA_VERSION` | get.sdkman.io |
| `sqlite` | sqlite3 + dev headers | apt | Ubuntu repos |
| `mkcert` | HTTPS local | `$MKCERT_VERSION` | GitHub releases |
| `gum` | Charm gum CLI | `$GUM_VERSION` | GitHub releases (.deb) |
| `git-cliff` | changelog generator | `$GIT_CLIFF_VERSION` | GitHub releases |
| `git-flow` | git-flow branching | apt | Ubuntu repos |
| `ffmpeg` | ffmpeg | apt | Ubuntu repos |
| `gh` | GitHub CLI | latest | repo oficial |
| `ohmyposh` | Prompt | latest | ohmyposh.dev |
| `ssh-key` | clave ed25519 (si no existe) | — | ssh-keygen |
| `claude-code` | Claude Code CLI | latest | claude.ai/install.sh |
| `gitkraken` | GitKraken GUI | latest active | api.gitkraken.com |
| `pencil` | Pencil design tool | latest | pencil.dev AppImage |
| `aliases` | Alias + funciones shell | — | inline |

## Alias y funciones (módulo `aliases`)

Escritas en `~/.bashrc` entre marcadores `# >>> wsl-setup aliases >>>`. Reescritura idempotente.

### Laravel Sail
```bash
sail            # corre sail local o desde vendor/bin
art             # sail php artisan
vapor           # sail bin vapor
fresh           # sail php artisan migrate:fresh
```

### Git
```bash
nah             # git reset --hard HEAD + clean -fd + rebase abort (con confirmación)
```

### Updates GUI apps
```bash
gitkraken-update    # descarga último .deb, instala, limpia
pencil-update       # descarga AppImage, extrae, reemplaza
```

## Agregar un módulo nuevo

1. Añade variable de versión a `versions.conf`:
   ```bash
   MI_HERRAMIENTA_VERSION="1.2.3"
   ```
2. Crea `modules/mi-herramienta.sh`:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/../versions.conf"
   : "${MI_HERRAMIENTA_VERSION:?no definido}"

   # instalación idempotente aquí
   ```
3. `chmod +x modules/mi-herramienta.sh`
4. Agrega el nombre al array `MODULE_ORDER` en `install.sh` (posición según dependencias).
5. (Opcional) `source "$WSL_SETUP_LIB"` para usar helpers (`download_verified`, `apt_update_cached`, `already_installed`).

## Tests

```bash
bash tests/smoke.sh    # verifica flags y sintaxis de módulos
shellcheck --severity=warning install.sh modules/*.sh tests/*.sh   # lint
```

CI corre ambos en `.github/workflows/lint.yml`.

## Seguridad

Las descargas externas deberían verificarse con SHA256. Estado actual y plan en [`CHECKSUMS.md`](CHECKSUMS.md).

## Requisitos

- WSL2 con Ubuntu (20.04+)
- Usuario con acceso `sudo`
- Conexión a internet
- Windows 11 recomendado (WSLg para apps GUI como Pencil/GitKraken)

## Notas

### Fuentes Nerd Font (para Oh My Posh)
Se instalan en **Windows**, no en WSL. Descarga `MesloLGS NF` desde [nerdfonts.com](https://www.nerdfonts.com/font-downloads), instala en Windows, y configura en Windows Terminal → Settings → perfil WSL → Appearance → Font face.

### GUI apps en WSL
Pencil y GitKraken usan WSLg (Windows 11). Verifica:
```bash
echo $WAYLAND_DISPLAY   # wayland-0 = OK
```
Si vacío → actualiza con `wsl --update` en PowerShell.

### mkcert + Windows
Para que Chrome/Edge/Firefox en **Windows** confíen en el CA:
```bash
explorer.exe "$(wslpath -w "$(mkcert -CAROOT)")"
# Instala rootCA.pem en "Trusted Root Certification Authorities" de Windows
```

### SDKMAN — otras versiones Java
```bash
sdk list java | grep tem        # ver Temurin disponibles
sdk install java 25.0.1-tem
sdk default java 25.0.1-tem
```

## Troubleshooting

- **`oh-my-posh: command not found`** tras instalar → `source ~/.bashrc` o abre nueva terminal.
- **Caracteres raros en prompt** → falta Nerd Font en Windows Terminal.
- **Pencil no abre ventana** → WSLg inactivo. `wsl --update` en PowerShell.
- **`sail` dice Docker no corre** → falta módulo Docker (aún no incluido).
- **Permiso denegado en scripts** → `chmod +x install.sh modules/*.sh`.
