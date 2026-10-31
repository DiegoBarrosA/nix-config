{ ... }:
{
  flake.modules.nixos.media-recyclarr =
{ config, lib, pkgs, ... }:

{

  services.recyclarr = {
    enable = true;
    user = "media";
    schedule = "daily 03:00";
    configuration = {

      sonarr.sonarr-main = {
        base_url = "http://localhost:8989";
        api_key._secret = config.sops.secrets."sonarr-api-key".path;
        quality_profiles = {
          standard = {
            quality = "Plex 1080p";
            min_score = 1000;
            upgrades_allowed = true;
          };
        };
        quality_definition.type = "series";
      };

      radarr.radarr-main = {
        base_url = "http://localhost:7878";
        api_key._secret = config.sops.secrets."radarr-api-key".path;
        quality_profiles = {
          movie = {
            quality = "Plex 1080p";
            min_score = 1000;
            upgrades_allowed = true;
          };
        };
        quality_definition.type = "movie";
      };

    };
  };

}
  ;
}
