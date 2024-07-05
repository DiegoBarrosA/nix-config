{ config, pkgs, ... }:
let
  ifTheyExist = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = true;
  users.users = {
    diego = {
      isNormalUser = true;
      packages = [ pkgs.home-manager ];
      extraGroups = [ "wheel" "audio" "storage" "input" "video" ]
        ++ ifTheyExist [
          "transmission"
          "syncthing"
          "network"
          "i2c"
          "docker"
          "git"
          "libvirtd"
          "adbusers"
        ];
      shell = pkgs.fish;
      description = "Diego Barros";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXblym20SD75es2z5Qay0mfW+g2zvKPBVMsUFakIyBK diegobarrosaraya@outlook.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpXSRXYbg97jxtfnnitIgNQLvGnLgZBWE9079qD2U4C diego@lazulita"
      ];
    };
  };
  security.pam.services = { swaylock = { }; };
  services.geoclue2.enable = true;
}
