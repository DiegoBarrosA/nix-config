---
layout: default
title: Project Structure
nav_order: 2
---

This document provides a detailed explanation of the file and directory structure of this NixOS configuration repository.

## Root Directory

- `flake.nix`: The entry point for the Nix Flakes configuration. It defines the inputs, outputs, and system configurations.
- `iso.nix`: Configuration for building a NixOS ISO image.
- `README.md`: The main README file for the project.
- `shell.nix`: A shell environment for development, used with `nix-shell`.

## `docs/`

This directory contains all the documentation for the project, including this document. It is designed to be compatible with GitHub Pages.

- `_config.yml`: Jekyll configuration file.
- `_layouts/`: HTML layouts for the documentation pages.

## `home/`

This directory contains the Home Manager configurations for different users and machines.

- `diego/`: Home Manager configuration for the user `diego`.
  - `features/`: Modularized features for the user's environment (e.g., `cli`, `desktop`, `emacs`).
  - `global/`: Global settings for the user.

## `hosts/`

This directory contains the NixOS configurations for each machine.

- `common/`: Common configurations shared across all hosts.
  - `global/`: Global settings for all systems.
  - `optional/`: Optional features that can be enabled on a per-host basis.
- `amatista/`, `cobalto/`, etc.: Host-specific configurations.

## `keys/`

This directory contains public keys for various services and users. Private keys are ignored by Git.

## `modules/`

This directory contains custom NixOS and Home Manager modules.

## `overlays/`

This directory contains Nixpkgs overlays for customizing packages.

## `pkgs/`

This directory contains custom packages that are not available in Nixpkgs.

## `scripts/`

This directory contains various scripts for maintenance, deployment, and other tasks.
