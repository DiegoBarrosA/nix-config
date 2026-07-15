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
  # SOPS secrets management

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

    secrets."cloudflare-tunnel-credentials" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."luks-passphrase" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # TURN server shared secret for Matrix voice/video calls
    secrets."turn-shared-secret" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # Matrix music bot password - disabled (bot disabled due to registry rate limiting)
    # secrets."matrix-music-bot-password" = {
    #   owner = "root";
    #   group = "root";
    #   mode = "0400";
    # };

    # Homepage dashboard API keys (used by widgets)
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
    secrets."syncthing-api-key" = {
      owner = "diego";
      group = "users";
      mode = "0640";
    };

    # Syncthing GUI password (readable by diego for syncthing-init)
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

    # secrets."deepseek-api-key" = {
    #   owner = "diego";
    #   group = "users";
    #   mode = "0400";
    # };
    # secrets."github-token" = {
    #   owner = "diego";
    #   group = "users";
    #   mode = "0400";
    # };

    # OpenCode Go and Zen API keys (optional - add these to secrets.yaml when you have the keys)
    # See: https://opencode.ai/docs/go and https://opencode.ai/docs/zen
    # To add: decrypt secrets with sops, add the keys, then re-encrypt
    # secrets."opencode-go-api-key" = {
    #   owner = "diego";
    #   group = "users";
    #   mode = "0400";
    # };
    # 
    # secrets."opencode-zen-api-key" = {
    #   owner = "diego";
    #   group = "users";
    #   mode = "0400";
    # };

    # Proton VPN WireGuard private key for exit node
    secrets."protonvpn-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # OpenCode server password for remote Android/web access
    # Used by services.opencode-server for Basic Auth
    secrets."opencode-server-password" = {
      owner = "diego";
      group = "users";
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
