# Impermanence configuration for rubi (desktop system)
# Based on cobalto's pattern but tailored for desktop use
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # Impermanence: define what persists across reboots
  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [
      # System directories
      "/etc/nixos"
      "/etc/ssh"
      "/var/log"
      "/var/lib/systemd/coredump"
      "/var/lib/nixos"
      "/var/lib/sops-nix"

      # NetworkManager (desktop networking)
      "/var/lib/NetworkManager"
      "/etc/NetworkManager/system-connections"

      # Bluetooth
      "/var/lib/bluetooth"

       # Tailscale
       "/var/lib/tailscale"

       # Secure Boot keys (sbctl)
       "/var/lib/sbctl"

      # CUPS printing
      "/var/lib/cups"

      # VPN client state
      "/opt/paloaltonetworks/prismaaccessagent"

      # PipeWire/audio state
      "/var/lib/pipewire"

      # Sunshine game streaming (pairing keys, credentials)
      "/var/lib/sunshine"

      # Flatpak (if used with COSMIC Store)
      "/var/lib/flatpak"

      # libvirt VM state (disks, OVMF nvram, swtpm TPM state)
      "/var/lib/libvirt"

      # llama.cpp model cache (large files, must persist across reboots)
      "/var/lib/llama-cpp"

      # User home directory (persisted entirely)
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
        "Projects"
        "Repositories"
        ".ssh"
        ".config"
        ".local"
        ".cache"

        # COSMIC desktop config
        ".config/cosmic"

        # Browser data
        ".mozilla"
        ".config/chromium"

        # Development
        ".cargo"
        ".rustup"
        ".npm"
        ".node_modules"

        # Misc app data
        ".gnupg"

        # Syncthing (preserve device identity across reboots)
        ".config/syncthing"

        # VPN client user state
        "paloaltonetworks/prismaaccessagent"
      ];

      files = [ ];
    };
  };

  # Filesystem mounts for impermanence
  fileSystems."/nix/persist" = {
    device = "/dev/mapper/rubi-root";
    fsType = "btrfs";
    options = [
      "subvol=persist"
      "compress=zstd"
      "noatime"
    ];
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/rubi-root";
    fsType = "btrfs";
    options = [
      "subvol=nix"
      "compress=zstd"
      "noatime"
    ];
    neededForBoot = lib.mkForce true;
  };

  # Boot configuration for impermanence
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  # Use systemd stage 1 for initrd (required by newer nixpkgs)
  boot.initrd.systemd.enable = true;

  # Reset root subvolume on every boot - converted to systemd service
  boot.initrd.systemd.services.wipe-root = {
    description = "Wipe root subvolume and restore from blank snapshot";
    wantedBy = [ "initrd.target" ];
    after = [ "dev-mapper-rubi\\x2droot.device" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "2min";
      StandardOutput = "null";
      StandardError = "null";
    };
    script = ''
      mkdir -p /tmp
      MNTPOINT=$(mktemp -d)
      (
        mount -t btrfs -o subvol=/ /dev/mapper/rubi-root "$MNTPOINT"
        trap 'umount "$MNTPOINT"' EXIT

        mkdir -p "$MNTPOINT"/persist/var/{log,lib/{nixos,systemd}}
        mkdir -p "$MNTPOINT"/persist/etc/ssh

        if [ -e "$MNTPOINT/persist/dont-wipe" ]; then
          true
        else
          btrfs subvolume delete -R "$MNTPOINT/root" || true

          if [ ! -e "$MNTPOINT/root" ]; then
            btrfs subvolume create "$MNTPOINT/root"
          fi

          if [ ! -e "$MNTPOINT/root-blank" ]; then
            btrfs subvolume snapshot -r "$MNTPOINT/root" "$MNTPOINT/root-blank"
          else
            btrfs subvolume delete -R "$MNTPOINT/root" || true
            btrfs subvolume snapshot "$MNTPOINT/root-blank" "$MNTPOINT/root"
          fi
        fi

        chmod 755 "$MNTPOINT"/persist/etc/ssh || true
      )
    '';
  };

  # Systemd tmpfiles for runtime directories
  systemd.tmpfiles.rules = [
    # Runtime directories
    "d /run/secrets 0755 root root -"

    # Persist directory structure
    "d /nix/persist/etc 0755 root root -"
    "d /nix/persist/etc/ssh 0755 root root -"
    "d /nix/persist/var 0755 root root -"
    "d /nix/persist/var/log 0755 root root -"
    "d /nix/persist/var/lib 0755 root root -"
    "d /nix/persist/var/lib/sops-nix 0700 root root -"
    "d /nix/persist/home 0755 root root -"
    "d /nix/persist/home/diego 0755 diego users -"
  ];

  # SSH host key generation service
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
      StandardOutput = "null";
      StandardError = "null";
    };
    script = ''
      set -e
      PERSIST_DIR="/nix/persist/etc/ssh"
      ETC_SSH="/etc/ssh"

      mkdir -p "$PERSIST_DIR"
      chmod 755 "$PERSIST_DIR"
      mkdir -p "$ETC_SSH"
      chmod 755 "$ETC_SSH"

      if [ ! -f "$PERSIST_DIR/ssh_host_ed25519_key" ]; then
        ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$PERSIST_DIR/ssh_host_ed25519_key" -N "" -C ""
        chmod 600 "$PERSIST_DIR/ssh_host_ed25519_key"
        chmod 644 "$PERSIST_DIR/ssh_host_ed25519_key.pub"
      fi

      if [ ! -f "$PERSIST_DIR/ssh_host_rsa_key" ]; then
        ${pkgs.openssh}/bin/ssh-keygen -t rsa -b 4096 -f "$PERSIST_DIR/ssh_host_rsa_key" -N "" -C ""
        chmod 600 "$PERSIST_DIR/ssh_host_rsa_key"
        chmod 644 "$PERSIST_DIR/ssh_host_rsa_key.pub"
      fi
    '';
  };

  # Machine ID creation service
  systemd.services."create-machine-id" = {
    description = "Create machine ID";
    wantedBy = [ "multi-user.target" ];
    before = [ "systemd-machine-id-commit.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StandardOutput = "null";
      StandardError = "null";
    };
    script = ''
      if [[ ! -f /etc/machine-id ]]; then
        ${pkgs.systemd}/bin/systemd-machine-id-setup
      fi
    '';
  };

  # Security
  security = {
    sudo.wheelNeedsPassword = false;
    protectKernelImage = true;
  };

  # Firewall
  networking.firewall.allowedTCPPorts = [ 22 ];

  # User configuration (needed for impermanence)
  users.users.diego = {
    isNormalUser = true;
  };
}
