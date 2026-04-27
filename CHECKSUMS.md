# Checksums de descargas externas

Tabla de SHA256 esperados para descargas binarias. Mitiga MITM y supply-chain.

## Formato

| Recurso | Versión | URL/source | SHA256 |
|---------|---------|------------|--------|
| ejemplo | 1.0.0 | https://... | `abc123...` |

## Estado actual

| Recurso | Versión (`versions.conf`) | SHA256 | Notas |
|---------|---------------------------|--------|-------|
| `git-cliff`     | `GIT_CLIFF_VERSION`     | `SKIP` | Pin desde release oficial GitHub. Calcular en máquina limpia. |
| `gum`           | `GUM_VERSION`           | `SKIP` | .deb desde charmbracelet/gum releases. |
| `mkcert`        | `MKCERT_VERSION`        | `SKIP` | Binario desde FiloSottile/mkcert. |
| `bun`           | `BUN_VERSION`           | `SKIP` | Instalador `bun.sh`. |
| `pnpm`          | `PNPM_VERSION`          | `SKIP` | Standalone binary. |
| `nvm`           | `NVM_VERSION`           | `SKIP` | Script desde nvm-sh/nvm. |
| `gitkraken`     | (rolling)               | `SKIP` | URL `active` cambia → checksum dinámico, no fijable. |
| `pencil`        | (AppImage)              | `SKIP` | URL latest, mismo problema. |
| `ohmyposh`      | (latest)                | `SKIP` | Instalador rolling. |
| `claude-code`   | (latest)                | `SKIP` | Instalador rolling. |
| `sdkman`        | (latest)                | `SKIP` | Instalador rolling. |
| `rust`          | `RUST_TOOLCHAIN`        | `SKIP` | rustup verifica internamente. |
| `uv`            | `UV_VERSION`            | `SKIP` | Instalador astral-sh. |

## Cómo calcular un SHA256 nuevo

```bash
curl -fsSL <URL> -o /tmp/file
sha256sum /tmp/file
```

Pegar resultado en la tabla. Luego `versions.conf` agrega:

```bash
GIT_CLIFF_SHA256="abc123..."
```

Y en el módulo:

```bash
source "$WSL_SETUP_LIB"
download_verified "$URL" "$DEST" "$GIT_CLIFF_SHA256"
```

## Recursos rolling (sin pin posible)

GitKraken `active`, Pencil `latest`, Oh My Posh installer, Claude Code installer, SDKMAN installer.

Opciones:
1. Cambiar a versión específica donde el upstream lo permita.
2. Aceptar `SKIP` pero documentar el riesgo aquí.
3. Self-host mirror con SHA fijo.

Decisión actual: **opción 2** para todos los rolling. Refactor futuro a opción 1 donde sea factible.
