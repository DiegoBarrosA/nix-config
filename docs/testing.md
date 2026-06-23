---
layout: default
title: Testing
nav_order: 10
---

This project uses a combination of manual and automated testing.

## Automated Testing

The following checks are run in CI:

- **`nixos-rebuild build`**: Builds all NixOS configurations to ensure they are valid.
- **`home-manager build`**: Builds all Home Manager configurations.
- **`alejandra`**: Checks for code formatting.
- **`statix`**: Lints the Nix code for potential issues.

## Manual Testing

Manual testing is performed on a per-host basis after making changes to a system's configuration.
