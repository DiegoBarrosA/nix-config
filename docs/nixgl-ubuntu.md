# Using Graphics Apps on Ubuntu (rubi)

## Solution: Native Ubuntu Packages

**Status**: ✅ Implemented

On `rubi`, graphics applications (Sway, Alacritty) are installed via Ubuntu's package manager to avoid glibc vdso conflicts.

```bash
# Already installed:
sudo apt install sway alacritty waybar mako-notifier
```

Verify installation:
```bash
which alacritty  # /usr/bin/alacritty
which sway       # /usr/bin/sway
alacritty --version
sway --version
```

## Why Not Nix for Graphics on Ubuntu?

Nix packages use a different glibc than Ubuntu's system glibc. Wrapping graphics applications with custom `LD_LIBRARY_PATH` causes vdso (virtual dynamic shared object) errors:

```
error while loading shared libraries: __vdso_gettimeofday: invalid mode for dlopen(): Invalid argument
```

This occurs because:
1. Mixing system OpenGL libraries with Nix glibc creates incompatible vdso mappings
2. The nixGL wrapper approach doesn't work reliably on Ubuntu
3. Even basic binaries like bash fail with these wrappers

## Current Configuration

`home/diego/rubi.nix` is configured for CLI tools only:

```nix
imports = [
  ./global
  ./features/cli
  # Desktop features disabled - using Ubuntu packages
];
```

Graphics applications run via Ubuntu's native packages, while Nix provides:
- Shell (fish, nushell)
- CLI tools (ripgrep, fd, etc.)
- Development tools
- Configuration management via Home Manager

## DMS (Dank Material Shell) on rubi

DMS is provided by Nix and the `dms` command is wrapped to run via **nixGL** at runtime so it gets a working OpenGL/EGL stack. Without this you get:

- `EGL not available`
- `Failed to initialize graphics backend for OpenGL`
- `QRhiGles2: Failed to create context`

The wrapper runs `nix run --impure github:nix-community/nixGL -- dms "$@"` (see `home/diego/rubi.nix`). The first time you run `dms run`, Nix may build/download the nixGL flake. If you still see OpenGL errors, try a specific wrapper, e.g. `nix run github:nix-community/nixGL#nixGLIntel -- dms run` (Intel/Mesa) or `#nixGLNvidia` (Nvidia).

## For Other Machines

On NixOS machines (amatista, cobalto, lazulita), the full Sway desktop configuration works perfectly via `./features/desktop/sway` because there are no glibc conflicts.
