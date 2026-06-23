---
layout: default
title: Installation
nav_order: 3
---

This document provides instructions on how to set up and install this NixOS configuration on a new system.

## Prerequisites

- A machine with NixOS installed.
- An internet connection.
- `git` installed.

## Installation Steps

1. **Clone the repository:**

   ```bash
   git clone https://github.com/DiegoBarrosA/nix-config.git
   cd nix-config
   ```

2. **Configure the host:**

   Copy one of the existing host configurations from the `hosts/` directory to a new directory for your machine. For example, to create a new host named `my-new-machine`:

   ```bash
   cp -r hosts/cobalto hosts/my-new-machine
   ```

   You will need to edit the files in `hosts/my-new-machine/` to match your hardware and preferences. Pay special attention to `hardware-configuration.nix`.

3. **Build and switch to the new configuration:**

   From the root of the repository, run the following command to build and switch to your new configuration. Replace `my-new-machine` with the name of your host.

   ```bash
   sudo nixos-rebuild switch --flake .#my-new-machine
   ```

4. **Install Home Manager:**

   To install the user-specific configuration, run the following command:

   ```bash
   home-manager switch --flake .#diego@my-new-machine
   ```
