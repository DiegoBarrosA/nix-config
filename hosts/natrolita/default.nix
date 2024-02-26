{ inputs, lib, config, pkgs, ... }: {
  imports = [
    #Common
    ../common/global
    ../common/users/diego
    #hardware
    ./hardware-configuration.nix
    ../common/optional/environment.nix
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
    hostName = "natrolita";
    useDHCP = false;
  };
  services.dbus.packages = [ pkgs.gcr ];
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "23.05";
}
