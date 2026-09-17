{ config, lib, pkgs, ... }:

{

  virtualisation.oci-containers = {
    backend = "podman";
    containers.jellyseerr = {
      # Fully qualified: podman has no unqualified-search registries configured,
      # so a bare "fallenbagel/..." short name fails to resolve on pull.
      image = "docker.io/fallenbagel/jellyseerr:latest";
      autoStart = true;
      extraOptions = [ "--network=host" ];
      volumes = [
        "/nix/storage/jellyseerr:/app/config"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /nix/storage/jellyseerr 0770 media media -"
  ];

  # settings.json holds the jellyfin/*arr wiring and db/ holds users and the
  # request history. None of that is reproducible declaratively (library ids,
  # quality profile ids and the sqlite db are all runtime state), so back it up.
  backups.restic.sources = [ "/nix/storage/jellyseerr" ];

  # Seed for a from-scratch rebuild where there is no backup to restore. Only
  # the fields that are genuinely static live here; jellyfin.libraries,
  # jellyfin.serverId and the radarr/sonarr entries are all discovered at
  # runtime (they reference ids that exist inside those servers), so they are
  # deliberately left out and still have to be picked once in the UI.
  # main.apiKey is omitted so jellyseerr generates its own.
  sops.templates."jellyseerr-settings.json" = {
    owner = "media";
    group = "media";
    mode = "0640";
    content = builtins.toJSON {
      main = {
        applicationTitle = "Jellyseerr";
        applicationUrl = "https://jellyseerr.minerales.network";
        # jellyseerr MediaServerType: 1=plex 2=jellyfin 3=emby 4=not configured
        mediaServerType = 2;
        localLogin = true;
        mediaServerLogin = true;
      };
      jellyfin = {
        name = "cobalto";
        ip = "127.0.0.1";
        port = 8096;
        useSsl = false;
        apiKey = config.sops.placeholder."jellyfin-api-key";
      };
    };
  };

  # ConditionPathExists=! means this only ever fires when settings.json is
  # absent, so it can never clobber the file jellyseerr owns at runtime.
  systemd.services.jellyseerr-seed-settings = {
    description = "Seed jellyseerr settings.json on first run";
    wantedBy = [ "multi-user.target" ];
    before = [ "podman-jellyseerr.service" ];
    after = [ "sops-install-secrets.service" ];
    unitConfig = {
      ConditionPathExists = "!/nix/storage/jellyseerr/settings.json";
      RequiresMountsFor = "/nix/storage";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      install -D -o media -g media -m 0640 \
        ${config.sops.templates."jellyseerr-settings.json".path} \
        /nix/storage/jellyseerr/settings.json
    '';
  };

}
