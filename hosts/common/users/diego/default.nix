{ config, lib, pkgs, outputs, ... }:
let
  ifTheyExist = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = true;
  users.users = {
    diego = {
      isNormalUser = true;
      passwordFile = config.sops.secrets.diego-password.path;
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
      ];
    };
  };
  security.pam.services = { swaylock = { }; };
  services.geoclue2.enable = true;
  sops.secrets.diego-password = {
    sopsFile = ../../secrets.yaml;
    neededForUsers = true;
  };
}
