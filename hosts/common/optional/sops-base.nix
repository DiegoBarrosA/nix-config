# Base SOPS configuration shared across all hosts that use sops-nix
# Host-specific secrets are defined in each host's sops.nix file
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

    # Core secrets needed on ALL hosts
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

  # Ensure sops-install-secrets doesn't fail on missing optional secrets
  systemd.services."sops-install-secrets" = {
    unitConfig.ConditionFileNotEmpty = lib.mkForce "";
    onFailure = lib.mkForce [ ];
  };

  # ACME user for certificate management
  users.users.acme = {
    isSystemUser = true;
    group = "acme";
  };
  users.groups.acme = { };
}
