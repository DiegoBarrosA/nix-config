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
          material-darker = {

            primary-color = "#82AAFF";
            accent-color = "#C792EA";
            dark-primary-color = "#82AAFF";
            light-primary-color = "#303030";

            primary-text-color = "#EEFFFF";
            secondary-text-color = "#B2CCD6";
            text-primary-color = "#212121";
            disabled-text-color = "#4A4A4A";

            primary-background-color = "#212121";
            secondary-background-color = "#262626";
            divider-color = "#353535";

            "app-header-background-color" = "#303030";
            "app-header-text-color" = "#EEFFFF";
            "sidebar-background-color" = "#303030";
            "sidebar-icon-color" = "#B2CCD6";
            "sidebar-text-color" = "#EEFFFF";
            "sidebar-selected-icon-color" = "#82AAFF";
            "sidebar-selected-text-color" = "#82AAFF";

            "card-background-color" = "#262626";
            "ha-card-background" = "#262626";
            "ha-card-border-radius" = "10px";
            "paper-card-background-color" = "#262626";

            "label-badge-background-color" = "#303030";
            "state-icon-color" = "#82AAFF";
            "switch-checked-color" = "#82AAFF";

            "error-color" = "#F07178";
            "warning-color" = "#FFCB6B";
            "success-color" = "#C3E88D";
            "info-color" = "#82AAFF";
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
          { type = "disk_use_percent"; arg = "/mnt/media"; }
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

      transmission = {
        host = "127.0.0.1";
        port = 9091;
        username = "";
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

    theme = "material-darker";
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
              { entity = "sensor.system_monitor_disk_use_mnt_media"; name = "Disk /mnt/media"; }
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
}
