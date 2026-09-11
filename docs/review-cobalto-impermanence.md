You are an expert NixOS reviewer. Your job is to audit the cobalto host definition in this nix-config repository and answer one question:

**After a cold reboot of the cobalto NixOS host (headless server), will any systemd service fail, crash, or lose data due to interaction between (a) the impermanence setup and (b) the disk/LUKS/btrfs mount setup?**

Common causes of exactly this symptom: a service starts before `/nix/persist`, `/nix/storage`, or `/mnt/media` are mounted and writes into an ephemeral mount point (creating state that vanishes on next reboot or shadows the real mount), or impermanence wipes/skips a directory a service needs at boot, or a service requires a path that is only created by a later tmpfiles/activation step, or mount ordering (initrd, `x-initrd.mount`, `neededForBoot`) causes systemd to treat a filesystem as failed and fall back to degraded.

Start by reading the repository layout, then these files in this order:

1. `flake.nix` (top-level: host list, deploy config, inputs)
2. `lib/default.nix` (mkHost helper: what modules/arguments it wires into each host)
3. `hosts/cobalto/default.nix` (host imports; THE import list defines which optional modules exist on this specific host — pay close attention to it)
4. `hosts/cobalto/hardware-configuration.nix` (disko layout: LUKS, btrfs subvolumes, mounts, TPM2/FIDO2 unlock, initrd network)
5. `hosts/cobalto/impermanence.nix` (persistence config, wipe-root initrd service, mount definitions, tmpfiles, ssh key generation, ensure-storage)
6. `hosts/common/optional/system/impermanence.nix` (the shared/global impermanence wiring — compare with cobalto's override)
7. `hosts/common/optional/system/automated-storage.nix` (activation script creating storage dirs)
8. `hosts/common/optional/system/sops-secrets.nix` and `hosts/common/optional/system/sops-base.nix` (secrets timing vs services)
9. `hosts/common/global/` (global modules imported by cobalto — e.g. base impermanence, base mounts)
10. Every module under `hosts/common/optional/` that is imported by cobalto's `default.nix`, especially:
    - `apps/`: home-assistant.nix, matrix-synapse.nix, couchdb.nix, vaultwarden.nix, zennotes.nix, homepage-native.nix, cameras.nix, go2rtc.nix, cockpit.nix, opencode-server.nix
    - `media/`: jellyfin.nix, sonarr.nix, radarr.nix, lidarr.nix, bazarr.nix, prowlarr.nix, lazylibrarian.nix, calibre.nix, transmission.nix, miniflux.nix, music-assistant.nix, snapcast.nix, flaresolverr.nix, po-token-server.nix, media-directories.nix
    - `network/`: samba.nix, pihole.nix, tailscale.nix, syncthing.nix, hosts.nix, minerales-network.nix
    - `ai/`: llama-cpp-server.nix, open-webui.nix, opencode-server.nix
    - `system/`: webtheming.nix, systemdboot.nix, environment.nix, automated-storage.nix
11. `home/diego/cobalto.nix` + `home/diego/features/cli/ssh.nix` and `home/diego/features/desktop/common/syncthing.nix` (home-manager pieces that run on cobalto and could touch mounts)

## What to verify, systematically

For each of the three encrypted volumes and their mounts (`/`, `/nix`, `/nix/persist`, `/nix/storage`, `/mnt/media`, `/.swapvol`, `/partition-root`):

- **Mount ordering.** Which markers does it carry (`neededForBoot`, `x-initrd.mount`)? Is it mounted in initrd or in stage-2? Can any service imported by cobalto start before it is mounted? Check whether the service has implicit ordering (`After=`/`RequiresMountsFor=`) against the path it uses. Flag any service that writes to a directory whose real mount is NOT yet mounted — systemd will then let the service write into the underlying ephemeral `/` directory, and if that directory is created by the service and NOT under a persisted path... document exactly what happens.
- **Service state directories** versus what impermanence persists. For each service state path (e.g. `/var/lib/jellyfin`, `/var/lib/hass`, `/var/lib/postgresql`, `/var/lib/miniflux`, `/var/lib/private/music-assistant`, `/var/lib/containers`, `/nix/storage/servarr/*`, `/mnt/media/...`), confirm that:
  - the path is either explicitly persisted (in `environment.persistence."/nix/persist"`) OR
  - it lives on a mount that survives reboots (`/nix/storage`, `/mnt/media`), OR
  - it is safely regenerated, OR
  - it is a real gap (state lost on reboot or service fails to start over missing dir).
  For every unpersisted-but-needed path, check whether some tmpfiles/activation/oneshot creates it at boot with correct ownership/mode, and whether that runs before the service. Note: the `wipe-root` initrd service wipes `/` each boot, so any needed-on-boot state must come from persist/storage/media/mounts or be recreated.
- **Ownership/permission mismatches.** Persisted dirs are created by tmpfiles with `root` owner (e.g. `/nix/persist/etc/ssh` 0755) vs services needing specific UID/GID (e.g. postgres:postgres, hass:hass, miniflux:miniflux). Flag cases where the running service will fail to write (EPERM / readonly) because the parent came back with wrong ownership or missing directory.
- **The wipe-root service itself** (`hosts/cobalto/impermanence.nix`, `boot.initrd.systemd.services.wipe-root`): check ordering (`before = [ "sysroot.mount" ]`, waits on `dev-mapper-cobalto-root`), the dont-wipe bypass, creation of blank snapshot, `mkdir -p` of persist dirs. Confirm it cannot delete needed data and cannot leave `/` without a root subvolume. Check the analogous service in the shared `impermanence.nix` and whether both get defined for cobalto (double registration / ordering conflict).
- **Bind-mount vs subvolume confusion.** Note which of `/nix/persist`, `/nix`, `/nix/storage` are separate btrfs subvolumes on the underlying device vs bind mounts onto them. Check `steadyState`/`hideMounts` semantics. Confirm a bind mount (e.g. impermanence's `bindMount`.`directories`) never appears where a subvolume mount already is, or vice versa, so the same path isn't double-mounted.
- **sops/secrets timing.** `sops-install-secrets` is conditioned off (`ConditionFileNotEmpty` forced to "") and explicit `OnFailure`/`onFailure` cleared. Check which services depend on sops-managed secret files (e.g. `opencode-server`, tailscale, syncthing, cameras, home-assistant, vaultwarden), whether they `After=`/`Requires=` sops, and whether on a fresh boot (persisted `key.txt` present in `/nix/persist/var/lib/sops-nix`) they decrypt before dependent services. Flag any service that would start with a missing secret file after reboot.
- **SSH / machine-id regeneration.** The `generate-ssh-keys` and `create-machine-id` services: confirm they do not regenerate identities that already persist, and that impermanence's persisted `/etc/ssh/*` files are actually used by openssh (hostKeys pointing into `/nix/persist/etc/ssh/...`).
- **Swap.** `/.swapvol` subvolume with swapfile on the root-mapped device: confirm it mounts before any swap activation and doesn't break boot if the subvolume wipe touches it (wipe-root deletes+recreates only the `root` subvolume, ideally).
- **Containers.** `/var/lib/containers` is persisted. Check the docker/podman/compose services used on cobalto (qbittorrent uses docker; check `media/qbittorrent.nix`, `apps/portainer.nix`, `apps/nextcloud.nix`) for which container storage paths they reference and whether those paths survive reboot (persisted or on storage/media mounts).
- **Systemd unit hardening friction.** None expected, but if any service sets `ReadOnlyPaths`, `ProtectSystem`, `PrivateTmp`, `ReadWritePaths` etc., confirm it doesn't contradict the mount layout above (e.g. services that need to write writable-but-mounted paths).
- **`systemd-tmpfiles` vs persist `hideMounts`.** With `hideMounts = true`, impermanence bind-mounts the persisted tree over and can hide underlying dirs; confirm tmpfiles rules write to the *persisted* location, not the underlying ephemeral location, for anything that must survive.

## Deliverable format

Return a findings report:

```
FINDING n
- File: <repo path>:<line>
- Severity: CRITICAL / HIGH / MEDIUM / LOW / INFO
- Scenario: what dies on reboot, and exactly how (be concrete about order: x-initrd.mount vs service start vs tmpfiles)
- Evidence: quote the relevant nix lines
- Fix: concrete nix change (option + snippet), or "no change needed" if it turns out safe
```

Then a final short list:
- **Services at risk of dying on reboot:** one line each with reason.
- **Survives-unattended conclusion:** one-paragraph verdict for "reboot the headless server and have everything come back clean" — including a note on whether any service depends physically on mounted disks being present (if a disk fails to unlock/unmount).

Do NOT modify any files. Read-only review. If you find something ambiguous (e.g. two impermanence modules both defining wipe-root), trace which definition actually wins for cobalto (`lib.mkForce`, import order, module priority) and state the actual effective config.