---
layout: default
title: Usage
nav_order: 4
---

This document provides examples of common tasks and workflows within this NixOS configuration project.

## Building a System

To build a system configuration without switching to it, use the `nixos-rebuild build` command:

```bash
nixos-rebuild build --flake .#hostname
```

Replace `hostname` with the name of the host you want to build.

## Switching to a Configuration

To switch to a new configuration, use the `nixos-rebuild switch` command:

```bash
sudo nixos-rebuild switch --flake .#hostname
```

## Updating Flake Inputs

To update all the flake inputs to their latest versions, run:

```bash
nix flake update
```

## Garbage Collection

To clean up unused store paths and free up disk space, run the garbage collector:

```bash
nix-collect-garbage -d
```
