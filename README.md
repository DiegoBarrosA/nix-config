# Personal Nix Config

This repository contains my personal NixOS configurations, managed with Nix Flakes.

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

Replace `hostname` with one of the available hosts.

