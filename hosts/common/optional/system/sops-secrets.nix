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
    useSystemdActivation = true;

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

    secrets."cloudflare-dns-token" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."cloudflare-zone-token" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."luks-passphrase" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."turn-shared-secret" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."jellyfin-api-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    secrets."prowlarr-api-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    secrets."sonarr-api-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    secrets."radarr-api-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    secrets."lidarr-api-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    secrets."bazarr-api-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."nextauth-secret" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    secrets."syncthing-api-key" = {
      owner = "diego";
      group = "users";
      mode = "0640";
    };

    secrets."syncthing-password" = {
      owner = "root";
      group = "diego";
      mode = "0640";
    };

    secrets."obsidian-api-key" = {
      owner = "diego";
      group = "users";
      mode = "0400";
    };

    secrets."opencode-server-password" = {
      owner = "diego";
      group = "users";
      mode = "0400";
    };

    secrets."vaultwarden-admin-token" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."aria2-rpc-secret" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."tdarr-server-env" = {
      owner = "media";
      group = "media";
      mode = "0400";
    };

    secrets."tdarr-node-env" = {
      owner = "media";
      group = "media";
      mode = "0400";
    };

    secrets."resend-api-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."restic-local-password" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."restic-remote-password" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."r2-access-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."r2-secret-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."r2-account-id" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    templates."restic.env" = {
      content = ''
        RESTIC_LOCAL_PASSWORD=${config.sops.placeholder."restic-local-password"}
        RESTIC_REMOTE_PASSWORD=${config.sops.placeholder."restic-remote-password"}
        RESTIC_S3_ENDPOINT=https://${config.sops.placeholder."r2-account-id"}.r2.cloudflarestorage.com
        AWS_ACCESS_KEY_ID=${config.sops.placeholder."r2-access-key"}
        AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."r2-secret-key"}
      '';
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
