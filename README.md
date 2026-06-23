# Personal Nix Config

This repository contains my personal NixOS, nix-darwin, and nix-on-droid configurations, managed with Nix Flakes.

## Documentation

For a complete overview of the project, please see the [documentation](https://diegobarrosa.github.io/nix-config/).

## Quick Start

```bash
# Clone the repository
git clone https://github.com/DiegoBarrosA/nix-config.git
cd nix-config

# Deploy remotely
nix deploy .#hostname -- --impure

# Or manage locally
sudo nixos-rebuild switch --flake .#hostname
```

Replace `hostname` with one of the available hosts. For more details, see the [installation guide](./docs/installation.md).

