{ inputs, lib, config, pkgs, ... }: {
  imports = [
    #Common
    ../common/global
    ../common/users/diego
    #../common/optional/ollama.nix
    #hardware
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix
    ../common/optional/transmission.nix
    ../common/optional/devices.nix
    #../common/optional/print.nix
    #Login manager
    #networking utils
    ../common/optional/tailscale.nix

    ../common/optional/jellyfin.nix

    ../common/optional/homepage.nix
    ../common/optional/hosts.nix
    ../common/optional/cockpit.nix
    #Containers
    ../common/optional/oci
    ../common/optional/syncthing.nix
    ../common/optional/environment.nix
    ../common/optional/virtmanager.nix
    ##Boot options
    ../common/optional/systemdboot.nix

  ];
  security.polkit.enable = true;
  services.dbus.enable = true;
  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}")
      config.nix.registry;
  };
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
  };
  networking = {
    hostName = "cobalto";
    useDHCP = false;

    interfaces = {
      enp7s0 = {
        useDHCP = true;
        ipv4.addresses = [
          {
            address = "10.0.0.1";
            prefixLength = 16;
          }
          {
            address = "192.168.1.85";
            prefixLength = 24;
          }
        ];
      };

    };
  };
  hardware = {
    opengl = {
      enable = true;
      extraPackages = with pkgs; [ amdvlk ];
      driSupport32Bit = true;
    };
  };
  boot.extraModprobeConfig = "options vfio-pci ids=10ec:818b";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
  hardware.openrgb.enable = true;
  boot = { kernelParams = [ "amdgpu" ]; };
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "22.11";
}
