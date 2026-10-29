# nix-config

Public flake for Diego's machines: cobalto (server), rubi (desktop), infinix (nix-on-droid). It uses flake-parts
with the dendritic pattern. This file is the source of truth for coding agents. Read it before you change anything.

## Layout

- `flake.nix`: inputs. `parts/*.nix`: flake-parts modules (`hosts/`, `homes.nix`, `deploy.nix`, `packages.nix`, `overlays.nix`).
- `parts/hosts/<host>.nix`: builds `nixosConfigurations.<host>` from `flake.modules.nixos.*`.
- `hosts/<host>/`: per-host sops files (`.sops.yaml`, encrypted `secrets.yaml`, examples), `cobalto/deploy_key.pub` and
  `infinix/nix-on-droid.nix`. It is not a NixOS module tree: NixOS host config lives in `parts/`.
- `parts/nixos/global/`: modules every NixOS host gets.
- `parts/nixos/optional/<area>/<name>.nix`: opt-in modules. Each file defines `flake.modules.nixos.<area>-<name>`.
  A host turns one on by listing its name in `parts/nixos/hosts/<host>/default.nix`.
- `parts/nixos/hosts/<host>/`: host config, including `impermanence.nix` for cobalto and rubi.
- `parts/home/`: home-manager. `features/{ai,audio,cli,desktop}/` hold the modules, `<host>.nix` selects them.
- `docs/`: runbooks. `docs/superpowers/{specs,plans}/`: specs and plans written by coding agents.
  `docs/agents/dev-rules.md`: rules given to Hermes-launched agents.

## Conventions

- Follow the pattern of the file next to the one you edit. Do not add `hosts/common/` or `modules/home-manager/`: they do not exist here.
- A new optional module is one file under `parts/nixos/optional/<area>/`, named like its neighbours, and enabled by name in the host.
  Use `lib.mkEnableOption` only where the neighbouring modules already use options. Many modules here are plain on/off by import.
- Flakes see only tracked files. Run `git add` on new files before any `nix` command.
- Comments explain why, not what. Keep the style of the surrounding file.
- Anything that holds state on cobalto or rubi (impermanence) needs its path in that host's `impermanence.nix`.

## Three repos

- This repo is public. It must not name customers or hold secrets.
- `nix-ai-tooling` (input `ai-tooling`): generic modules for Claude, opencode and the like.
- `nix-private-config` (input `private-config`): customer data, accounts, work secrets. Do not copy its content here.

## Checks

- `nix flake check --no-build` before you say a change is done.
- For a change to a host, also build it: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`.

## Deploy (Diego does this, agents do not)

- cobalto: `nixos-rebuild switch --flake .#cobalto --target-host root@cobalto --build-host root@cobalto`.
- A failed unit during activation rolls back the whole deploy, even if the unit is unrelated.
- Do not move the `nixpkgs` pin on cobalto. It must match the Jellyfin database. Add a second pin for a newer package (see `nixpkgs-acp`).
- A deploy restarts Hermes. Do not deploy while a Hermes task runs.

## Hermes

- Hermes runs on cobalto (`parts/nixos/optional/ai/hermes-agent.nix`). It only dispatches coding agents. It never edits this repo.
- Coding agents work on a branch and open a PR. Diego merges.
