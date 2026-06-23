{
  config,
  pkgs,
  lib,
  ...
}:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  # Add shells to /etc/shells for compatibility with programs that check it
  # (e.g., GlobalProtect VPN checks SHELL against /etc/shells)
  environment.shells = with pkgs; [ nushell bash fish ];
  
  users.mutableUsers = false;
  users.groups.diego = {};
  users.users = {
    diego = {
      isNormalUser = true;
      group = "diego";
      packages = [ pkgs.home-manager ];
      extraGroups = [
        "wheel"
        "audio"
        "storage"
        "input"
        "video"
      ]
        ++ ifTheyExist [
          "transmission"
          "syncthing"
          "network"
          "networkmanager"
          "i2c"
          "docker"
          "git"
          "libvirtd"
          "adbusers"
        ];
      shell = pkgs.nushell;
      description = "Diego Barros";
      # Password is set from SOPS secret if available
      hashedPasswordFile = "/run/secrets-for-users/diego-password";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXblym20SD75es2z5Qay0mfW+g2zvKPBVMsUFakIyBK diegobarrosaraya@outlook.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpXSRXYbg97jxtfnnitIgNQLvGnLgZBWE9079qD2U4C diego@lazulita"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBM2hEBu4cWTnBMbGdu2bG+sAZu5kBMtc75NFhShmX21"
      ];
    };
  };
}
