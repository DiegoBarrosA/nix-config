{
  config,
  lib,
  pkgs,
  ...
}:
{

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish.enable = true;
    publish.addresses = true;
    publish.workstation = true;
  };

  services.matter-server = {
    enable = true;
  };

  services.home-assistant = {
    enable = true;

    extraComponents = [
      "default_config"
      "met"
      "esphome"
    ];
    extraPackages = ps: with ps; [

      music-assistant-client
      python-miio
      python-otbr-api
      pyatv
      pyswitchbot
      yeelight
      gtts
      reolink-aio
    ] ++ [ pkgs.ffmpeg-headless ];
    customComponents = [
      pkgs."home-assistant-custom-components".tuya_local
    ];
    config = {
      default_config = {};

      frontend = {
        themes = {
          ${config.services.cobaltoTheme.scheme} =
            let
              theme = config.services.cobaltoTheme;
            in
            {
              primary-color = theme.base16Scheme.base0D;
              accent-color = theme.base16Scheme.base0E;
              dark-primary-color = theme.base16Scheme.base0D;
              light-primary-color = theme.base16Scheme.base01;

              primary-text-color = theme.base16Scheme.base05;
              secondary-text-color = theme.base16Scheme.base04;
              text-primary-color = theme.base16Scheme.base00;
              disabled-text-color = theme.base16Scheme.base03;

              primary-background-color = theme.base16Scheme.base00;
              secondary-background-color = theme.surface;
              divider-color = theme.base16Scheme.base02;

              "app-header-background-color" = theme.base16Scheme.base01;
              "app-header-text-color" = theme.base16Scheme.base05;
              "sidebar-background-color" = theme.base16Scheme.base01;
              "sidebar-icon-color" = theme.base16Scheme.base04;
              "sidebar-text-color" = theme.base16Scheme.base05;
              "sidebar-selected-icon-color" = theme.base16Scheme.base0D;
              "sidebar-selected-text-color" = theme.base16Scheme.base0D;

              "card-background-color" = theme.surface;
              "ha-card-background" = theme.surface;
              "ha-card-border-radius" = "10px";
              "paper-card-background-color" = theme.surface;

              "label-badge-background-color" = theme.base16Scheme.base01;
              "state-icon-color" = theme.base16Scheme.base0D;
              "switch-checked-color" = theme.base16Scheme.base0D;

              "error-color" = theme.base16Scheme.base08;
              "warning-color" = theme.base16Scheme.base0A;
              "success-color" = theme.base16Scheme.base0B;
              "info-color" = theme.base16Scheme.base0D;
            };
        };
      };

      camera = [
        {
          platform = "ffmpeg";
          name = "Xiaomi C200";
          input = "rtsp://127.0.0.1:8557/xiaomi_cam";
        }
        {
          platform = "ffmpeg";
          name = "Reolink E1";
          input = "rtsp://127.0.0.1:8557/reolink_e1";
        }
      ];

      ffmpeg = {
        ffmpeg_bin = "${pkgs.ffmpeg-headless}/bin/ffmpeg";
      };

      homeassistant = {
        external_url = "https://homeassistant.minerales.network";
        internal_url = "https://homeassistant.minerales.network";
      };

      http = {
        server_host = "127.0.0.1";
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" "::1" ];
      };

      systemmonitor = {
        resources = [
          { type = "disk_use_percent"; arg = "/"; }
          { type = "disk_use_percent"; arg = "/nix/storage"; }
          { type = "disk_use_percent"; arg = "/srv/media"; }
          { type = "memory_use_percent"; }
          { type = "processor_use"; }
          { type = "processor_temperature"; }
          { type = "network_in"; arg = "enp6s0"; }
          { type = "network_out"; arg = "enp6s0"; }
          { type = "ipv4_address"; arg = "enp6s0"; }
          { type = "last_boot"; }
        ];
      };

      jellyfin = {
        host = "127.0.0.1";
        http_port = 8096;
      };

      music_assistant = {};

      snapcast = {
        host = "127.0.0.1";
        port = 1705;
      };

      switchbot = {};

      matter = {
        url = "http://localhost:5580";
      };

      qbittorrent = {
        host = "127.0.0.1";
        port = 8080;
        username = "admin";
        password = "";
      };

      syncthing = {
        url = "http://127.0.0.1:8384";
        api_key = "";
      };

      sonarr = {
        url = "http://127.0.0.1:8989";
        api_key = "";
      };

      radarr = {
        url = "http://127.0.0.1:7878";
        api_key = "";
      };

      lidarr = {
        url = "http://127.0.0.1:8686";
        api_key = "";
      };

      prowlarr = {
        url = "http://127.0.0.1:9696";
        api_key = "";
      };

      bazarr = {
        url = "http://127.0.0.1:6767";
        api_key = "";
      };

      tailscale = {};

      alexa = {
        smart_home = {
          endpoint = "https://alexa-homeassistant.minerales.network/api/alexa/smart_home";
          filter = {
            include_domains = [
              "alarm_control_panel"
              "binary_sensor"
              "climate"
              "cover"
              "fan"
              "humidifier"
              "light"
              "lock"
              "media_player"
              "sensor"
              "switch"
              "vacuum"
            ];
          };
        };
      };

      homekit = [{
        filter = {
          include_domains = [
            "alarm_control_panel"
            "binary_sensor"
            "climate"
            "cover"
            "fan"
            "humidifier"
            "light"
            "lock"
            "media_player"
            "sensor"
            "switch"
            "vacuum"
          ];
        };
      }];
    };
  };

  services.home-assistant.lovelaceConfig = {
    title = "Cobalto Home";

    theme = config.services.cobaltoTheme.scheme;
    views = [

      {
        title = "Home";
        path = "home";
        icon = "mdi:home";
        cards = [
          {
            type = "weather-forecast";
            entity = "weather.forecast_home";
            show_current = true;
            show_forecast = true;
          }
          {
            type = "glance";
            title = "People";
            entities = [
              "person.diego_barros"
              "person.adriana"
            ];
          }
          {
            type = "entities";
            title = "Lights";
            entities = [
              { entity = "light.192_168_1_49"; name = "Bedroom"; }
              { entity = "light.192_168_1_14"; name = "Office"; }
              { entity = "light.192_168_1_16"; name = "Kitchen"; }
              { entity = "light.192_168_1_15"; name = "Entrada"; }
              { entity = "light.192_168_1_54"; name = "Lamp"; }
            ];
          }
          {
            type = "media-control";
            entity = "media_player.living_room";
          }
        ];
      }

      {
        title = "Cameras";
        path = "cameras";
        icon = "mdi:cctv";
        cards = [
          {
            type = "picture-entity";
            title = "Reolink E1 (Living Room)";
            entity = "camera.reolink_e1";
            camera_view = "live";
          }
          {
            type = "picture-entity";
            title = "Xiaomi C200";
            entity = "camera.xiaomi_c200";
            camera_view = "live";
          }
        ];
      }

      {
        title = "Lights";
        path = "lights";
        icon = "mdi:lightbulb-group";
        cards = [
          {
            type = "light";
            entity = "light.192_168_1_49";
            name = "Bedroom";
          }
          {
            type = "light";
            entity = "light.192_168_1_14";
            name = "Office";
          }
          {
            type = "light";
            entity = "light.192_168_1_16";
            name = "Kitchen";
          }
          {
            type = "light";
            entity = "light.192_168_1_15";
            name = "Entrada";
          }
          {
            type = "light";
            entity = "light.192_168_1_54";
            name = "Lamp";
          }
        ];
      }

      {
        title = "System";
        path = "system";
        icon = "mdi:server";
        cards = [
          {
            type = "gauge";
            name = "CPU";
            entity = "sensor.system_monitor_processor_use";
            unit = "%";
            severity = { green = 0; yellow = 60; red = 85; };
          }
          {
            type = "gauge";
            name = "Memory";
            entity = "sensor.system_monitor_memory_use";
            unit = "%";
            severity = { green = 0; yellow = 70; red = 90; };
          }
          {
            type = "gauge";
            name = "CPU Temp";
            entity = "sensor.system_monitor_processor_temperature";
            unit = "°C";
            severity = { green = 0; yellow = 70; red = 85; };
          }
          {
            type = "entities";
            title = "Storage & Host";
            entities = [
              { entity = "sensor.system_monitor_disk_use_partition_root"; name = "Disk / (root)"; }
              { entity = "sensor.system_monitor_disk_use_srv_media"; name = "Disk /srv/media"; }
              { entity = "sensor.system_monitor_disk_use_nix_storage"; name = "Disk /nix/storage"; }
              { entity = "sensor.system_monitor_load_1_min"; name = "Load (1m)"; }
              { entity = "sensor.system_monitor_last_boot"; name = "Last boot"; }
              { entity = "sensor.system_monitor_ipv4_address_enp7s0"; name = "IPv4"; }
            ];
          }
        ];
      }

      {
        title = "Dev News";
        path = "dev-news";
        icon = "mdi:rss";
        panel = true;
        cards = [
          {
            type = "iframe";
            title = "Dev News";
            url = "https://rss.minerales.network/";
            aspect_ratio = "100%";
          }
        ];
      }
    ];
  };

  # configDir: entity registry, automations, and the recorder database, i.e.
  # every pairing and all history. Not reproducible from this config.
  backups.restic.sources = [ config.services.home-assistant.configDir ];
}
