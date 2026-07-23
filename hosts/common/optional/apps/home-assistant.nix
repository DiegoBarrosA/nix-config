{
  config,
  lib,
  pkgs,
  ...
}:
{
  # mDNS/Zeroconf for device discovery (Yeelight, Apple TV, HomeKit Bridge/Siri)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish.enable = true;
    publish.addresses = true;
    publish.workstation = true;
  };

  # Matter smart home protocol server
  services.matter-server = {
    enable = true;
  };


  services.home-assistant = {
    enable = true;
    # Bundle Python deps + register config-flow handlers for these components.
    extraComponents = [
      "default_config" # HA default (kept from module default)
      "met"            # HA default
      "esphome"        # HA default
    ];
    extraPackages = ps: with ps; [
      # alexapy              # TEMPORARILY DISABLED: broken on Python 3.14
      music-assistant-client # required by built-in music_assistant integration
      python-miio
      python-otbr-api        # required by homekit_controller integration
      pyatv
      pyswitchbot            # required by switchbot integration (BLE)
      yeelight
      gtts                   # required by google_translate TTS integration
      reolink-aio            # required by reolink integration
    ] ++ [ pkgs.ffmpeg-headless ];
    customComponents = [
      pkgs."home-assistant-custom-components".tuya_local
    ];
    config = {
      default_config = {};

      # Material Darker theme (matches the Stylix/nix-colors "material-darker"
      # scheme used across the flake). Select it per-user in Profile > Themes,
      # or it applies as the default via the dashboard.
      frontend = {
        themes = {
          material-darker = {
            # Base
            primary-color = "#82AAFF";
            accent-color = "#C792EA";
            dark-primary-color = "#82AAFF";
            light-primary-color = "#303030";
            # Text
            primary-text-color = "#EEFFFF";
            secondary-text-color = "#B2CCD6";
            text-primary-color = "#212121";
            disabled-text-color = "#4A4A4A";
            # Backgrounds
            primary-background-color = "#212121";
            secondary-background-color = "#262626";
            divider-color = "#353535";
            # App header / sidebar
            "app-header-background-color" = "#303030";
            "app-header-text-color" = "#EEFFFF";
            "sidebar-background-color" = "#303030";
            "sidebar-icon-color" = "#B2CCD6";
            "sidebar-text-color" = "#EEFFFF";
            "sidebar-selected-icon-color" = "#82AAFF";
            "sidebar-selected-text-color" = "#82AAFF";
            # Cards
            "card-background-color" = "#262626";
            "ha-card-background" = "#262626";
            "ha-card-border-radius" = "10px";
            "paper-card-background-color" = "#262626";
            # States / labels
            "label-badge-background-color" = "#303030";
            "state-icon-color" = "#82AAFF";
            "switch-checked-color" = "#82AAFF";
            # Sensor/graph accents
            "error-color" = "#F07178";
            "warning-color" = "#FFCB6B";
            "success-color" = "#C3E88D";
            "info-color" = "#82AAFF";
          };
        };
      };

      # Cameras — declared against go2rtc (single source), so a rebuild reproduces
      # them with no manual UI configuration. go2rtc serves:
      #   xiaomi_cam  (Xiaomi C200, native xiaomi:// source)
      #   reolink_e1  (Reolink E1 via the neolink RTSP bridge)
      # See go2rtc.nix / cameras.nix. Reolink credentials stay in the neolink sops
      # template; go2rtc only proxies its local RTSP.
      #
      # NOTE: the `generic` camera platform is config-flow only (no YAML). The
      # `ffmpeg` camera platform still supports declarative YAML, so we use it to
      # pull the go2rtc RTSP streams.
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

      # ffmpeg integration — provides the binary used by the ffmpeg camera platform.
      ffmpeg = {
        ffmpeg_bin = "${pkgs.ffmpeg-headless}/bin/ffmpeg";
      };

      # Cameras set up via HA UI:
      #   Reolink E1 → Reolink integration (UI: Settings → Devices → Reolink)
      #   Xiaomi C200 → ONVIF integration (UI: Settings → Devices → ONVIF)

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

      # System monitor — CPU, memory, disk, network, temperature sensors for cobalto
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

      # Jellyfin media server
      jellyfin = {
        host = "127.0.0.1";
        http_port = 8096;
      };

      # Music Assistant
      music_assistant = {};

      # Snapcast multi-room audio
      snapcast = {
        host = "127.0.0.1";
        port = 1705;
      };

      # SwitchBot IoT devices (BLE)
      switchbot = {};

      # Matter smart home protocol (connects to local matter-server)
      matter = {
        url = "http://localhost:5580";
      };

      # Transmission torrent client
      transmission = {
        host = "127.0.0.1";
        port = 9091;
        username = "";
        password = "";
      };

      # Syncthing file sync
      syncthing = {
        url = "http://127.0.0.1:8384";
        api_key = ""; # Set via HA UI or secrets
      };

      # Servarr suite — media management
      sonarr = {
        url = "http://127.0.0.1:8989";
        api_key = ""; # Set via HA UI
      };

      radarr = {
        url = "http://127.0.0.1:7878";
        api_key = ""; # Set via HA UI
      };

      lidarr = {
        url = "http://127.0.0.1:8686";
        api_key = ""; # Set via HA UI
      };

      prowlarr = {
        url = "http://127.0.0.1:9696";
        api_key = ""; # Set via HA UI
      };

      bazarr = {
        url = "http://127.0.0.1:6767";
        api_key = ""; # Set via HA UI
      };

      # Tailscale VPN
      tailscale = {};

      # Amazon Alexa Smart Home Skill — control HA via Alexa voice
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

      # Apple HomeKit / Siri — exposes entities to the Apple Home app
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

  # Declarative Lovelace dashboard (YAML mode).
  #
  # NOTE: Setting lovelaceConfig registers a YAML-mode dashboard named
  # "nixos-lovelace" (this one). It is NOT automatically the panel you land on:
  # Home Assistant's "default dashboard" is a per-user profile setting. To make
  # this your default, once per user go to:
  #   Profile (bottom-left avatar) > Default dashboard > pick "Overview".
  # The UI "Edit Dashboard" button is disabled in YAML mode; edit this file instead.
  #
  # RSS feeds (hackertab.dev-style developer news) are served by Miniflux (see
  # miniflux.nix), themed to the Stylix material-darker palette, and embedded in
  # the "Dev News" tab below via an iframe card.
  services.home-assistant.lovelaceConfig = {
    title = "Cobalto Home";
    # Apply the material-darker theme to this dashboard.
    theme = "material-darker";
    views = [
      # ---------------------------------------------------------------- Home
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
      # ------------------------------------------------------------- Cameras
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
      # -------------------------------------------------------------- Lights
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
      # -------------------------------------------------------------- System
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
      # ------------------------------------------------------------ Dev News
      {
        title = "Dev News";
        path = "dev-news";
        icon = "mdi:rss";
        panel = true; # full-width for the embedded reader
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
