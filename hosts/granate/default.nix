{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    # Base configuration
    ../common/global
    ../common/users/diego

    # Hardware support
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix

    # Core services
    ../common/optional/tailscale.nix
    ../common/optional/syncthing.nix
    ../common/optional/sops-secrets.nix

    # Backup module
    ../common/optional/rclone-storagebox-backup.nix
    ../common/optional/hetzner-optimizations.nix

    # Boot configuration
    ../common/optional/systemdboot.nix
  ];

  services.rclone-storagebox-backup = {
    enable = true;
    remotePath = "/granate";
    syncPaths = [ "/var/lib/data" ];
  };

  # Basic server configuration
  fileSystems = {
    "/" = {
      device = "/dev/sda1";
      fsType = "ext4";
    };
    "/var/lib/data" = {
      device = "/dev/sdb1";
      fsType = "ext4";
      options = [
        "noatime"
        "nodiratime"
      ];
    };
  };

  networking = {
    hostName = "granate";
    useDHCP = false;
    interfaces = {
      enp1s0 = {
        useDHCP = true;
        ipv4.addresses = [
          {
            address = "204.168.253.49";
            prefixLength = 24;
          }
        ];
      };
    };
    defaultGateway = "204.168.253.1";
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
  };

  # Security
  security.polkit.enable = true;
  services.dbus.enable = true;
  security.sudo.wheelNeedsPassword = false;

  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
  };

  system.stateVersion = "24.11";
}
