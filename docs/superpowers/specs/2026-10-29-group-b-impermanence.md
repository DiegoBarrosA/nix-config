# Group B: impermanence and persistence fixes

Date: 2026-10-29
Status: draft, waiting for approval

## Intent

The CLAUDE.md audit found that some state on cobalto and rubi is wiped on every boot, and that one dead module contradicts the live host config. CLAUDE.md says anything that holds state on cobalto or rubi needs its path in that host's `impermanence.nix`. This spec fixes four findings in one PR.

## Goals

1. Transmission keeps its settings, resume data and torrent list across reboots on cobalto.
2. ZenNotes keeps its server config across reboots on cobalto.
3. Docker keeps images, containers and volumes across reboots on rubi.
4. The repo has one impermanence definition per host and no dead copy.

## Non-goals

- No change to which services run.
- No change to the `/nix/storage` layout or to the servarr/nextcloud approach.
- No migration of existing data. See "Deploy notes".
- No fixes for other audit groups.

## Findings and changes

### 1. Transmission on cobalto

`parts/nixos/optional/media/transmission.nix` enables `services.transmission` as user `media`, group `media`. The module sets no `home`, so the NixOS default `/var/lib/transmission` applies. It holds `settings.json`, resume data and torrent files. Nothing persists it. The `media` user has `home = "/var/empty"` (`media-user.nix`), so the user home does not cover it either. Downloads live in `/srv/media/downloads` and are not affected.

Change: add to `environment.persistence."/nix/persist".directories` in `parts/nixos/hosts/cobalto/impermanence.nix`:

```nix
{
  directory = "/var/lib/transmission";
  user = "media";
  group = "media";
  mode = "0700";
}
```

Use the attrset form. Impermanence would otherwise create the bind target as `root:root`. Place it next to the other service state directories, before the `/var/backup/postgresql` entry.

Open point for the builder: check how the nixpkgs revision pinned on cobalto creates this directory. If it uses `StateDirectory` or tmpfiles with a different mode, match that mode instead of `0700`. Report what you found.

### 2. ZenNotes on cobalto

`parts/nixos/optional/apps/zennotes.nix` sets `StateDirectory = "zennotes"` and `ZENNOTES_CONFIG_PATH = "/var/lib/zennotes/server.json"`. The service runs as `cfg.user` (default `diego`, group `users`). Cobalto does not override `user`. `/var/lib/zennotes` is wiped on every boot.

Change: add to the same `directories` list:

```nix
{
  directory = "/var/lib/zennotes";
  user = "diego";
  group = "users";
  mode = "0755";
}
```

The module sets `Group = "users"` and does not set `StateDirectoryMode`, so the systemd default `0755` applies. Hardcode `diego`: this matches the neighbouring `/home/diego` entry, and the host does not change the option. Do not wire `config.services.zennotes.user` into the host impermanence file.

### 3. Docker on rubi

`parts/nixos/hosts/rubi/default.nix` enables `virtualisation.docker` with `enableOnBoot = false`. It sets no `data-root`, so state is in `/var/lib/docker`. Rubi wipes root on boot, so images, containers and volumes vanish.

Change: add `"/var/lib/docker"` as a plain string to `directories` in `parts/nixos/hosts/rubi/impermanence.nix`, after `/var/lib/cups`. Docker runs as root and manages the mode itself, so no attrset is needed.

Caveat: if docker fails to start on rubi after deploy because of the storage driver on the btrfs bind mount, report it. Do not change the storage driver in this PR.

### 4. Dead module `parts/nixos/optional/system/impermanence.nix`

The file defines `flake.modules.nixos.system-impermanence`. A grep for `system-impermanence` finds only the definition. Cobalto and rubi use their own `cobalto-impermanence` and `rubi-impermanence`. The file also persists `/nix/storage/servarr`. The cobalto comment says servarr must not be persisted, because it would force `/nix/storage` to be `neededForBoot` and deadlock the boot. Anyone who imports this module recreates that bug.

Change: delete the file with `git rm`. Grep `system-impermanence` and `optional/system/impermanence` to confirm nothing else refers to it. The only hit outside the file is `docs/superpowers/specs/2026-10-29-group-a-layout-docs.md`, which mentions a different path (`hosts/common/optional/system/impermanence.nix`) that does not exist. Leave it.

## Constraints

- Stage any changed file with `git add` before running `nix`.
- Follow the formatting of the surrounding file. The two impermanence files have odd indentation inside the module body. Do not reformat them.
- Add a one-line why comment only where the reason is not obvious.
- One commit per finding, conventional messages, for example `fix(cobalto): persist transmission state`.

## Verification

1. `nix flake check --no-build`.
2. `nix build .#nixosConfigurations.cobalto.config.system.build.toplevel`.
3. `nix build .#nixosConfigurations.rubi.config.system.build.toplevel`.
4. Evaluate the persisted directory lists and show the new entries. Check that `/var/lib/transmission` and `/var/lib/zennotes` appear on cobalto and `/var/lib/docker` on rubi.
5. `grep -rn system-impermanence parts flake.nix` returns nothing.

Put the real command output in the PR description. If a build cannot run, say why.

## Deploy notes (Diego does this)

- Impermanence bind-mounts the persist path over the live path. An empty persist directory hides the current contents. Before the deploy, copy any state you want to keep from the running root into `/nix/persist/var/lib/<name>`.
- Transmission starts with default settings plus the options declared in the module if you skip the copy. It loses its torrent list.
- A deploy restarts Hermes. Do not deploy while a Hermes task runs.

## Open questions for Diego

1. Docker on rubi: is `/var/lib/docker` enough, or do you also use `/var/lib/containerd`? My default: only `/var/lib/docker`.
2. Transmission mode: my default is `0700` for `media:media`. Say so if other services need to read that directory.
