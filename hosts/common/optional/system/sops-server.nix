{
  config,
  lib,
  inputs,
  ...
}:

{
  sops.secrets = {

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

    "turn-shared-secret" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

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
