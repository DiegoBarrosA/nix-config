{
  config,
  lib,
  pkgs,
  inputs,
  self,
  ...
}:

with lib;

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = "${self}/hosts/${config.networking.hostName}/secrets.yaml";
    defaultSopsFormat = "yaml";
    age.keyFile = "/nix/persist/var/lib/sops-nix/key.txt";
    age.generateKey = false;

    secrets."diego-password" = {
      neededForUsers = true;
      owner = "root";
      group = "root";
      mode = "0600";
    };

    secrets."tailscale-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."luks-passphrase" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  systemd.services."sops-install-secrets" = {
    unitConfig.ConditionFileNotEmpty = lib.mkForce "";
    onFailure = lib.mkForce [ ];
  };

  users.users.acme = {
    isSystemUser = true;
    group = "acme";
  };
  users.groups.acme = { };
}
