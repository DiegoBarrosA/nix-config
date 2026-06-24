# Server-specific secrets for cobalto (media services, sync, etc.)
{
  config,
  lib,
  inputs,
  ...
}:

{
  sops.secrets = {
    # Cloudflare integration
    "cloudflare-dns-token" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    "cloudflare-zone-token" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    "cloudflare-tunnel-credentials" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # Matrix/TURN server
    "turn-shared-secret" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # Media service API keys (for homepage dashboard widgets)
    "jellyfin-api-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    "prowlarr-api-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    "sonarr-api-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    "radarr-api-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    "lidarr-api-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    "bazarr-api-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # Syncthing
    "syncthing-api-key" = {
      owner = "diego";
      group = "users";
      mode = "0640";
    };
    "syncthing-password" = {
      owner = "root";
      group = "diego";
      mode = "0640";
    };

  };
}
