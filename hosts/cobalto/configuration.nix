{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd
    #Login manager
    ../common/optional/greetd.nix
    #Sound server
    ../common/optional/pipewire.nix

    ../common/optional/print.nix

    

#    ../common/optional/emacs.nix
    ../common/optional/devices.nix
    ../common/optional/syncthing.nix
    ../common/optional/onedrive.nix
    ../common/optional/transmission.nix

    ../common/optional/environment.nix

    ../common/optional/mus.nix
#    ../common/optional/qt.nix
       ../common/optional/nodejs.nix
    ../common/optional/wportals.nix
    ../common/optional/virtmanager.nix
    ../common/optional/droidcam.nix
    ../common/users/diego
    ##Boot options
    ../common/optional/systemdboot.nix
    ../common/optional/silentboot.nix
    #Hardware
    ./hardware-configuration.nix
    ../common/global
  ];
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 80 443  9091];

  allowedUDPPorts = [ 80 443  9091];
};

  services.flatpak.enable = true;
  security.polkit.enable = true;
  services.dbus.enable = true;
  services.greetd.settings.default_session.user = "diego";
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
  networking.hostName = "cobalto";
  networking.useDHCP = false;
  networking.interfaces.enp5s0.useDHCP = true;
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;

    extraModulePackages = [ pkgs.linuxKernel.packages.linux_zen.v4l2loopback ];
    kernelModules = ["vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd"];
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
  boot.extraModprobeConfig ="options vfio-pci ids=10ec:818b";
  hardware.i2c.enable = true;
  hardware.openrgb.enable = true;
  boot = { kernelParams = [ "amdgpu" ]; };
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "22.11";

}
