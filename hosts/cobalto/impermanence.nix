# Impermanence configuration for cobalto (server system)
# Uses systemd stage 1 initrd for compatibility with modern NixOS
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # Enable systemd stage 1 initrd (required by modern nixpkgs)
  boot.initrd.systemd.enable = true;
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  # Impermanence: define what persists across reboots
  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [
      # System directories that need to persist
      "/etc/nixos"
      "/etc/ssh"
      "/var/log"
      "/var/lib/systemd/coredump"
      "/var/lib/nixos"
      "/var/lib/sops-nix"
      "/var/lib/bluetooth"
      "/var/lib/NetworkManager"
      "/var/lib/tailscale"

      # Container and service data
      "/var/lib/containers"
      # Note: llama-cpp-server stores models in /nix/storage/llm/models (persistent disk)
      "/var/lib/jellyfin"
      "/var/lib/cockpit"
      "/var/lib/hass"
      "/var/lib/miniflux"
      "/var/lib/postgresql"
      "/var/lib/private/music-assistant"

      # Servarr suite data directories
      "/nix/storage/servarr"
      "/nix/storage/nextcloud"

      # User directories
      {
        directory = "/home/diego";
        user = "diego";
        group = "users";
        mode = "0755";
      }
    ];

    files = [
      # SSH host keys
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"

      # Machine ID
      "/etc/machine-id"
    ];

    users.diego = {
      directories = [
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"
        "nix-config"
        ".ssh"
        ".config"
        ".config/syncthing"
        ".syncthing"
        ".local"
        ".cache"

        # Development directories
        "Repositories"
        "Projects"

        # AI agent state. Claude Code and Codex keep their credentials here
        # (.claude/.credentials.json, .codex/auth.json) and happy keeps the
        # daemon's machine identity + phone pairing in .happy, so without
        # these three every reboot means logging in and re-pairing again.
        {
          directory = ".claude";
          mode = "0700";
        }
        {
          directory = ".codex";
          mode = "0700";
        }
        {
          directory = ".happy";
          mode = "0700";
        }

        # Container data access
        {
          directory = "media";
          mode = "0755";
        }
      ];

      # NB: do not persist ".claude.json" here. impermanence would create it
      # empty, and claude-code-config's activation branches on the file
      # existing and then runs jq over it, so an empty file fails the switch.
      # Losing it per boot only costs Claude Code's onboarding state; the
      # credentials live in .claude/ above.
      files = [ ];
    };
  };

  # Filesystem mounts for impermanence
  fileSystems."/nix/persist" = {
    device = "/dev/mapper/cobalto-root";
    fsType = "btrfs";
    options = [
      "subvol=persist"
      "compress=zstd"
      "noatime"
    ];
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cobalto-root";
    fsType = "btrfs";
    options = [
      "subvol=nix"
      "compress=zstd"
      "noatime"
    ];
    neededForBoot = lib.mkForce true;
  };

  fileSystems."/nix/storage" = {
    device = "/dev/mapper/cobalto-storage";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
    ];
    neededForBoot = lib.mkForce true;
  };

  # Reset root subvolume on every boot - systemd initrd service
  boot.initrd.systemd.services.wipe-root = {
    description = "Wipe root subvolume and restore from blank snapshot";
    wantedBy = [ "initrd.target" ];
    after = [ "dev-mapper-cobalto\\x2droot.device" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "2min";
    };
    script = ''
      mkdir -p /tmp
      MNTPOINT=$(mktemp -d)
      (
        mount -t btrfs -o subvol=/ /dev/mapper/cobalto-root "$MNTPOINT"
        trap 'umount "$MNTPOINT"' EXIT

        echo "Creating needed directories for impermanence"
        mkdir -p "$MNTPOINT"/persist/var/{log,lib/{nixos,systemd}}
        mkdir -p "$MNTPOINT"/persist/etc/ssh

        if [ -e "$MNTPOINT/persist/dont-wipe" ]; then
          echo "Skipping wipe (dont-wipe flag found)"
        else
          echo "Cleaning root subvolume"
          btrfs subvolume delete -R "$MNTPOINT/root" || true

          # Create root subvolume if it doesn't exist
          if [ ! -e "$MNTPOINT/root" ]; then
            echo "Creating root subvolume"
            btrfs subvolume create "$MNTPOINT/root"
          fi

          # Create blank snapshot if it doesn't exist
          if [ ! -e "$MNTPOINT/root-blank" ]; then
            echo "Creating blank root snapshot"
            btrfs subvolume snapshot -r "$MNTPOINT/root" "$MNTPOINT/root-blank"
          else
            echo "Restoring from blank snapshot"
            btrfs subvolume delete -R "$MNTPOINT/root" || true
            btrfs subvolume snapshot "$MNTPOINT/root-blank" "$MNTPOINT/root"
          fi
        fi

        # Ensure SSH directory is accessible
        chmod 755 "$MNTPOINT"/persist/etc/ssh || true
      )
    '';
  };

  # Systemd tmpfiles for runtime directories
  systemd.tmpfiles.rules = [
    # Runtime directories
    "d /run/secrets 0755 root root -"
    "d /run/containers 0755 root root -"
    "d /tmp/containers-diego 0755 diego users -"

    # Ensure persist directory structure for sops-nix
    "d /nix/persist/var/lib/sops-nix 0700 root root -"

    # Ensure other persist directory structure
    "d /nix/persist/etc 0755 root root -"
    "d /nix/persist/etc/ssh 0755 root root -"
    "d /nix/persist/var 0755 root root -"
    "d /nix/persist/var/log 0755 root root -"
    "d /nix/persist/var/lib 0755 root root -"
    "d /nix/persist/home 0755 root root -"
    "d /nix/persist/home/diego 0755 diego users -"
    "d /nix/persist/nix 0755 root root -"
    "d /nix/persist/nix/storage 0755 root root -"

    # Home Assistant directory
    "d /nix/persist/var/lib/hass 0700 hass hass -"

    # Miniflux + PostgreSQL data
    "d /nix/persist/var/lib/miniflux 0750 miniflux miniflux -"
    "d /nix/persist/var/lib/postgresql 0750 postgres postgres -"

    # Servarr suite directories
    "d /nix/storage/servarr 0755 root root -"
    "d /nix/storage/servarr/prowlarr 0755 root root -"
    "d /nix/storage/servarr/sonarr 0755 root root -"
    "d /nix/storage/servarr/radarr 0755 root root -"
    "d /nix/storage/servarr/lidarr 0755 root root -"
    "d /nix/storage/servarr/bazarr 0755 root root -"
    "d /nix/storage/lazylibrarian 0755 root root -"
    # Media mountpoints and directories (library + sync + transmission, capitalized)
    "d /mnt/media 0755 root media -"
    "d /mnt/media/Movies 0755 diego media -"
    "d /mnt/media/Tv 0755 diego media -"
    "d /mnt/media/Music 0755 diego media -"
    "d /mnt/media/Books 0755 diego media -"
    "d /mnt/media/Audiobooks 0755 diego media -"
    "d /mnt/media/Documents 0755 diego media -"
    "d /mnt/media/Obsidian 0755 diego media -"
    "d /mnt/media/Repos 0755 diego media -"
    "d /mnt/media/Archive 0755 diego media -"
    "d /mnt/media/Pictures 0755 diego media -"
    "d /mnt/media/Pictures/Wallpapers 0755 diego media -"
    "d /mnt/media/Pictures/Photos 0755 diego media -"
    "d /mnt/media/Pictures/Screenshots 0755 diego media -"
    "d /mnt/media/Incoming 0755 diego media -"
    "d /mnt/media/Transmission 0775 diego media -"
    "d /mnt/media/Transmission/Downloads 0775 diego media -"
    "d /mnt/media/Transmission/Downloads/complete 0775 diego media -"
    "d /mnt/media/Transmission/Downloads/complete/radarr 0775 diego media -"
    "d /mnt/media/Transmission/Downloads/complete/sonarr 0775 diego media -"
    "d /mnt/media/Transmission/Downloads/complete/lidarr 0775 diego media -"
    "d /mnt/media/Transmission/Downloads/complete/lazylibrarian 0775 diego media -"
    "d /mnt/media/Transmission/Downloads/complete/bazarr 0775 diego media -"
    "d /mnt/media/Transmission/Watch 0775 diego media -"
    "d /mnt/media/Transmission/Incomplete 0775 diego media -"
  ];

  # SSH host key configuration
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/nix/persist/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/nix/persist/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      X11Forwarding = false;
    };
  };

  # Generate SSH keys if missing
  systemd.services."generate-ssh-keys" = {
    description = "Generate SSH host keys if missing";
    wantedBy = [ "multi-user.target" ];
    before = [
      "sshd.service"
      "sops-install-secrets.service"
    ];
    after = [
      "local-fs.target"
      "systemd-tmpfiles-setup.service"
    ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 30;
    };
    script = ''
      set -e

      PERSIST_DIR="/nix/persist/etc/ssh"
      ETC_SSH="/etc/ssh"

      # Ensure persistence directory exists with correct permissions
      mkdir -p "$PERSIST_DIR"
      chmod 755 "$PERSIST_DIR"

      # Ensure /etc/ssh symlink/mount is properly set up
      mkdir -p "$ETC_SSH"
      chmod 755 "$ETC_SSH"

      echo "Checking SSH host keys in $PERSIST_DIR..."

      # Generate ED25519 key if missing
      if [ ! -f "$PERSIST_DIR/ssh_host_ed25519_key" ]; then
        echo "[SSH] Generating ED25519 host key..."
        ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$PERSIST_DIR/ssh_host_ed25519_key" -N "" -C "" 2>&1 | grep -v "overwrite"
        chmod 600 "$PERSIST_DIR/ssh_host_ed25519_key"
        chmod 644 "$PERSIST_DIR/ssh_host_ed25519_key.pub"
      fi

      # Generate RSA key if missing
      if [ ! -f "$PERSIST_DIR/ssh_host_rsa_key" ]; then
        echo "[SSH] Generating RSA host key..."
        ${pkgs.openssh}/bin/ssh-keygen -t rsa -b 4096 -f "$PERSIST_DIR/ssh_host_rsa_key" -N "" -C "" 2>&1 | grep -v "overwrite"
        chmod 600 "$PERSIST_DIR/ssh_host_rsa_key"
        chmod 644 "$PERSIST_DIR/ssh_host_rsa_key.pub"
      fi

      # Verify keys exist and have correct permissions
      echo "[SSH] Verifying SSH keys..."
      ls -la "$PERSIST_DIR"/ssh_host_* 2>/dev/null | head -10

      # Ensure keys are readable from /etc/ssh (should be symlinked or mounted by impermanence)
      if [ -d "$ETC_SSH" ]; then
        for key in "$PERSIST_DIR"/ssh_host_*; do
          if [ -f "$key" ]; then
            basename=$(basename "$key")
            if [ ! -L "$ETC_SSH/$basename" ] && [ ! -f "$ETC_SSH/$basename" ]; then
              echo "[SSH] Linking $basename to /etc/ssh"
              ln -sf "$key" "$ETC_SSH/$basename" 2>/dev/null || true
            fi
          fi
        done
      fi

      echo "[SSH] SSH key generation complete"
    '';
  };

  # Ensure critical services handle impermanence correctly
  systemd.services = {
    # Create machine-id on boot if it doesn't exist
    "create-machine-id" = {
      description = "Create machine ID";
      wantedBy = [ "multi-user.target" ];
      before = [ "systemd-machine-id-commit.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if [[ ! -f /etc/machine-id ]]; then
          ${pkgs.systemd}/bin/systemd-machine-id-setup
        fi
      '';
    };

    # Ensure storage directories exist after impermanence reset
    "ensure-storage" = {
      description = "Ensure storage directories exist";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Ensure all necessary storage directories exist
        mkdir -p /nix/storage/{run/secrets,secrets,llm,syncthing,transmission,jellyfin,homepage,nextcloud}
        mkdir -p /nix/storage/var/lib/vols/{portainer,watchtower}
        # Ensure media mountpoints and transmission folders exist (some systems mount /mnt/media later)
        mkdir -p /mnt/media/{Movies,Tv,Music,Books,Audiobooks,Incoming,Documents,Obsidian,Repos,Archive,Pictures}
        mkdir -p /mnt/media/Pictures/{Wallpapers,Photos,Screenshots}
        mkdir -p /mnt/media/Transmission/{Downloads,Watch,Incomplete}

        # Create category subdirectories for Servarr remote download client mapping
        mkdir -p /mnt/media/Transmission/Downloads/complete/{radarr,sonarr,lidarr,lazylibrarian,bazarr}
        mkdir -p /mnt/media/Transmission/Incomplete/{radarr,sonarr,lidarr,lazylibrarian,bazarr}        # Servarr suite directories
        mkdir -p /nix/storage/servarr/{prowlarr,sonarr,radarr,lidarr,bazarr}
        mkdir -p /nix/storage/lazylibrarian

        # LLM and container directories
        mkdir -p /nix/storage/llm-services/text-generation-webui

        # Set proper permissions on storage directories
        chmod -R 755 /nix/storage/servarr 2>/dev/null || true
        chmod -R 755 /nix/storage/llm-services 2>/dev/null || true

        # Ensure ownership and permisssions so services (native or containers) can access
        chown -R diego:media /mnt/media 2>/dev/null || true
        chmod -R 0755 /mnt/media 2>/dev/null || true

        # Make storage directories accessible to uid 1000 if setfacl is available (backwards compatible)
        if command -v setfacl &> /dev/null; then
          setfacl -R -m u:1000:rwx /nix/storage/servarr 2>/dev/null || true
          setfacl -R -m u:1000:rwx /mnt/media 2>/dev/null || true
        fi

        # Note: /mnt/media permissions are handled by media-stack-native.nix
      '';
    };

    # Ensure sops-nix doesn't fail if age key is not yet available
    "sops-install-secrets" = {
      serviceConfig.ConditionFileNotEmpty = lib.mkForce "";
      unitConfig.OnFailure = lib.mkForce [ ];
    };
  };

  # Security considerations for impermanence
  security = {
    sudo.wheelNeedsPassword = false;
    protectKernelImage = true;
  };

  # Networking for deploy-rs
  networking.firewall.allowedTCPPorts = [ 22 ];

  # User configuration for deploy-rs
  users.users.diego = {
    isNormalUser = true;
  };
}
