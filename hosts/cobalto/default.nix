{ inputs, lib, config, pkgs, ... }: {
  imports = [
    #Common
    ../common/global
    ../common/users/diego
    #hardware
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix
    ../common/optional/devices.nix
    ../common/optional/pipewire.nix
    ../common/optional/print.nix
    ../common/optional/droidcam.nix
    #Login manager
    ../common/optional/greetd.nix
    #networking utils
    #    ../common/optional/tailscale.nix
    ../common/optional/hosts.nix
    #Containers
    #   ../common/optional/oci

    #   ../common/optional/jellyfin.nix 
    #  ../common/optional/syncthing.nix
    ../common/optional/environment.nix
    # ../common/optional/nodejs.nix
    ../common/optional/wportals.nix
    ../common/optional/virtmanager.nix

    ##Boot options
    ../common/optional/systemdboot.nix
    ../common/optional/silentboot.nix

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
    interfaces.enp5s0 = {
      useDHCP = true;
      wakeOnLan.enable = true;

    };
  };
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    extraModulePackages = [ pkgs.linuxKernel.packages.linux_zen.v4l2loopback ];
    kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
  };
  hardware = {
    opengl = {
      enable = true;
      extraPackages = with pkgs; [ amdvlk ];
      driSupport = true;
      driSupport32Bit = true;
    };
  };
  programs = {
    gamemode = {
      enable = true;
      settings.gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
    kdeconnect.enable = true;
    dconf.enable = true;
    adb.enable = true;
  };
  services.dbus.packages = [ pkgs.gcr ];
  boot.extraModprobeConfig = "options vfio-pci ids=10ec:818b";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
  hardware.openrgb.enable = true;
  boot = { kernelParams = [ "amdgpu" ]; };
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "22.11";

}
