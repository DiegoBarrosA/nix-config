{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  # Impermanence configuration for stateless system management
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # Enable impermanence
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
      # "/var/lib/private/ollama" # Ollama removed - using llama-cpp-server instead
      "/var/lib/jellyfin"
      "/var/lib/cockpit"

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

        # Container data access
        {
          directory = "media";
          mode = "0755";
        }
      ];

      files = [ ];
    };
  };

  # Root filesystem setup for impermanence - only configure persist mount
  # The root filesystem and /nix/storage are handled by disko configuration
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

  # /nix/storage for service data (Nextcloud, Syncthing, Ollama, etc.)
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

  # Boot configuration for impermanence
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  boot.initrd.postDeviceCommands = lib.mkBefore ''
    mkdir -p /tmp
    MNTPOINT=$(mktemp -d)
    (
      mount -t btrfs -o subvol=/ /dev/mapper/cobalto-root "$MNTPOINT"
      trap 'umount "$MNTPOINT"' EXIT

      echo "Creating needed directories for impermanence"
      mkdir -p "$MNTPOINT"/persist/var/{log,lib/{nixos,systemd}}
      mkdir -p "$MNTPOINT"/persist/etc/ssh
      
      if [ -e "$MNTPOINT/persist/dont-wipe" ]; then
        echo "Skipping wipe"
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
          echo "Restoring blank subvolume"
          btrfs subvolume delete -R "$MNTPOINT/root"
          btrfs subvolume snapshot "$MNTPOINT/root-blank" "$MNTPOINT/root"
        fi
      fi
      
      # Ensure SSH directory is accessible during initrd for key generation
      echo "Setting up SSH directory for persistence"
      chmod 755 "$MNTPOINT"/persist/etc/ssh || true
    )
  '';

  # Systemd service to create necessary runtime directories
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
    "d /mnt/media/Transmission/Incomplete 0775 diego media -" # Note: /mnt/media directories are handled by the actual filesystem mount
    # Media directories are created by hardware-configuration.nix disko setup
  ];

  # Manual cleanup: Remove conflicting files before first boot
  # For now, we'll handle this manually since impermanence activation is tricky

  # SSH host key generation - auto-generate on first boot
  services.openssh = {
    enable = true;
    # Use keys from /nix/persist which is mounted via impermanence
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
    # Additional security settings
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      X11Forwarding = false;
    };
  };

  # Systemd service to generate SSH keys if they don't exist
  # This runs BEFORE sshd and BEFORE sops-nix activation
  # This ensures SSH is available even if SOPS fails during bootstrap
  # Fix for: https://github.com/nix-community/impermanence/issues/192
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
    # This is important during the bootstrap phase (nixos-anywhere)
    "sops-install-secrets" = {
      # Don't require the age key file to exist during boot
      # It will be available after deploy-rs runs
      serviceConfig.ConditionFileNotEmpty = lib.mkForce "";
      # Don't fail the activation if SOPS can't decrypt
      unitConfig.OnFailure = lib.mkForce [ ];
    };
  };

  # Security considerations for impermanence
  security = {
    sudo.wheelNeedsPassword = false; # Needed for remote deployment

    # Protect against accidental deletion of persist
    protectKernelImage = true;
  };

  # Networking for deploy-rs
  networking = {
    firewall = {
      allowedTCPPorts = [ 22 ]; # SSH for deployment
    };
  };

  # User configuration for deploy-rs
  users.users.diego = {
    isNormalUser = true;
  };
}
