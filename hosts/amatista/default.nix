{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd
    #Login manager
    ../common/optional/greetd.nix
    #Sound server
    ../common/optional/pipewire.nix
    ../common/optional/devices.nix
    ../common/optional/syncthing.nix
    ../common/optional/wportals.nix
    ../common/optional/environment.nix

    ../common/optional/nodejs.nix
    ../common/optional/qt.nix

    ../common/users/diego
    ##Boot options
    ../common/optional/systemdboot.nix
    ../common/optional/silentboot.nix
    #Hardware
    ./hardware-configuration.nix
    ../common/global
    ../common/optional/wireless.nix
    ../common/optional/firmware.nix

  ];
  programs.dconf.enable = true;
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
  networking.hostName = "amatista";
  networking.useDHCP = false;
  networking.interfaces.wlp1s0.useDHCP = true;
  boot = { kernelPackages = pkgs.linuxKernel.packages.linux_zen; };

  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };
  hardware = {
    opengl = {
      enable = true;
      extraPackages = with pkgs; [ amdvlk ];
      driSupport = true;
      driSupport32Bit = true;
    };
  };
  powerManagement.powertop.enable = true;
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };
  programs = {
    adb.enable = true;

    light.enable = true;
  };
  boot = { kernelParams = [ "amdgpu" ]; };
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "22.05";

}
