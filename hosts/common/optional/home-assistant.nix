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
    extraPackages = ps: with ps; [
      alexapy              # required by alexa_devices integration
      music-assistant-client # required by built-in music_assistant integration
      python-miio
      python-otbr-api        # required by homekit_controller integration
      pyatv
      pyswitchbot            # required by switchbot integration (BLE)
      yeelight
      gtts                   # required by google_translate TTS integration
    ] ++ [ pkgs.ffmpeg-headless ];
    customComponents = [
      pkgs."home-assistant-custom-components".tuya_local
    ];
    config = {
      default_config = {};

      camera = [
        {
          platform = "generic";
          name = "Reolink E1";
          stream_source = "rtsp://127.0.0.1:8554/reolink_e1";
          verify_ssl = false;
        }
        {
          platform = "generic";
          name = "Xiaomi Camera";
          stream_source = "rtsp://127.0.0.1:8554/xiaomi_cam";
          verify_ssl = false;
        }
      ];

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
}
