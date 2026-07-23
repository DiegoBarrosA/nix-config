{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Native Homepage Dashboard with full system integration
  # Shows all services, disks, system stats, and provides unified dashboard

  environment.systemPackages = with pkgs; [
    glances
  ];

  # Glances service for system monitoring
  services.glances = {
    enable = true;
    port = 61208;
    openFirewall = true;
  };

  networking.firewall = {
    allowedTCPPorts = [
      61208 # Glances system monitoring
    ];
  };

  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    allowedHosts = "home.minerales.network";
    listenPort = 8082;

    settings = {
      title = "Cobalto Media Server";
      theme = "dark";
      headerStyle = "boxed";
      layout = "columns";
      customTheme = {
        scheme = "Material Darker";
        author = "Nate Peterson";
        base00 = "212121";
        base01 = "303030";
        base02 = "353535";
        base03 = "4A4A4A";
        base04 = "B2CCD6";
        base05 = "EEFFFF";
        base06 = "EEFFFF";
        base07 = "FFFFFF";
        base08 = "F07178";
        base09 = "F78C6C";
        base0A = "FFCB6B";
        base0B = "C3E88D";
        base0C = "89DDFF";
        base0D = "82AAFF";
        base0E = "C792EA";
        base0F = "FF5370";
      };

      background = "#212121";

      customCSS = ''
        .service-group { margin-bottom: 2rem; }
        .widget-container { backdrop-filter: blur(10px); }
      '';
    };

    services = [
      {
        "Media Services" = [
          {
            "Jellyfin" = {
              icon = "jellyfin.png";
              href = "http://jellyfin.minerales.network";
              description = "Media streaming server";
              widget = {
                type = "jellyfin";
                url = "http://localhost:8096";
                key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
              };
            };
          }
          {
            "Transmission" = {
              icon = "transmission.png";
              href = "http://transmission.minerales.network";
              description = "Native BitTorrent client";
            };
          }
          {
            "Invidious" = {
              icon = "invidious.png";
              href = "http://invidious.minerales.network";
              description = "YouTube frontend";
            };
          }
        ];
      }
      {
        "Servarr Suite" = [
          {
            "Prowlarr" = {
              icon = "prowlarr.png";
              href = "http://prowlarr.minerales.network";
              description = "Indexer manager";
              widget = {
                type = "prowlarr";
                url = "http://localhost:9696";
                key = "{{HOMEPAGE_VAR_PROWLARR_API_KEY}}";
              };
            };
          }
          {
            "Sonarr" = {
              icon = "sonarr.png";
              href = "http://sonarr.minerales.network";
              description = "TV show manager";
              widget = {
                type = "sonarr";
                url = "http://localhost:8989";
                key = "{{HOMEPAGE_VAR_SONARR_API_KEY}}";
              };
            };
          }
          {
            "Radarr" = {
              icon = "radarr.png";
              href = "http://radarr.minerales.network";
              description = "Movie manager";
              widget = {
                type = "radarr";
                url = "http://localhost:7878";
                key = "{{HOMEPAGE_VAR_RADARR_API_KEY}}";
              };
            };
          }
          {
            "Lidarr" = {
              icon = "lidarr.png";
              href = "http://lidarr.minerales.network";
              description = "Music manager";
              widget = {
                type = "lidarr";
                url = "http://localhost:8686";
                key = "{{HOMEPAGE_VAR_LIDARR_API_KEY}}";
              };
            };
          }
          {
            "LazyLibrarian" = {
              icon = "lazylibrarian.png";
              href = "http://lazylibrarian.minerales.network";
              description = "Book automation";
            };
          }
          {
            "Calibre-Web" = {
              icon = "calibre.png";
              href = "http://calibre.minerales.network";
              description = "Ebook library & reader";
            };
          }
          {
            "Bazarr" = {
              icon = "bazarr.png";
              href = "http://bazarr.minerales.network";
              description = "Subtitle manager";
              widget = {
                type = "bazarr";
                url = "http://localhost:6767";
                key = "{{HOMEPAGE_VAR_BAZARR_API_KEY}}";
              };
            };
          }
        ];
      }
      {
        "AI & LLM" = [
          {
            "llama.cpp" = {
              icon = "llama-cpp.png";
              href = "http://localhost:11435";
              description = "Vulkan-accelerated LLM server";
            };
          }
          {
            "Open-WebUI" = {
              icon = "open-webui.png";
              href = "https://llm.minerales.network";
              description = "LLM chat interface";
            };
          }
        ];
      }
      {
        "System Tools" = [
          {
            "Syncthing" = {
              icon = "syncthing.png";
              href = "http://syncthing.minerales.network";
              description = "File synchronization";
              widget = {
                type = "syncthing";
                url = "https://syncthing.minerales.network";
                key = "{{HOMEPAGE_VAR_SYNCTHING_API_KEY}}";
              };
            };
          }
        ];
      }
      {
        "Home Automation" = [
          {
            "Snapcast" = {
              icon = "snapcast.png";
              href = "http://snapcast.minerales.network";
              description = "Multi-room audio server";
            };
          }
        ];
      }
    ];

    widgets = [
      {
        search = {
          provider = "custom";
          url = "https://lite.duckduckgo.com/lite?q=";
          target = "_blank";
        };
      }
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        resources = {
          label = "Storage";
          disk = "/mnt/media";
        };
      }
    ];

    bookmarks = [
      {
        "Development" = [
          {
            "nix-config" = [
              {
                href = "https://github.com/DiegoBarrosA/nix-config";
                description = "NixOS configuration repository";
                icon = "github.png";
              }
            ];
          }
        ];
      }
      {
        "Media" = [
          {
            "YouTube" = [
              {
                href = "https://youtube.com";
                description = "Video streaming";
                icon = "youtube.png";
              }
            ];
          }
          {
            "Spotify" = [
              {
                href = "https://spotify.com";
                description = "Music streaming";
                icon = "spotify.png";
              }
            ];
          }
        ];
      }
    ];
  };

  systemd.services.homepage-secrets = {
    description = "Generate Homepage Dashboard secrets env file";
    before = [ "homepage-dashboard.service" ];
    requiredBy = [ "homepage-dashboard.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /etc/homepage-dashboard
      {
        echo "# Homepage Dashboard API Keys - generated at service start"
        for secret_name in jellyfin-api-key prowlarr-api-key sonarr-api-key radarr-api-key lidarr-api-key bazarr-api-key; do
          env_name="HOMEPAGE_VAR_$(echo "$secret_name" | tr '[:lower:]-' '[:upper:]_')"
          secret_file="/run/secrets/$secret_name"
          if [ -f "$secret_file" ] && [ -s "$secret_file" ]; then
            echo "$env_name=$(cat "$secret_file" | tr -d '\n')"
          else
            echo "$env_name="
          fi
        done
        # Extract Syncthing API key from config.xml (SOPS secret doesn't match runtime key)
        SYNCTHING_CONFIG="/home/diego/.config/syncthing/config.xml"
        if [ -f "$SYNCTHING_CONFIG" ] && [ -s "$SYNCTHING_CONFIG" ]; then
          API_KEY=$(grep '<apikey>' "$SYNCTHING_CONFIG" | sed 's/.*<apikey>\(.*\)<\/apikey>.*/\1/')
          echo "HOMEPAGE_VAR_SYNCTHING_API_KEY=$API_KEY"
        else
          echo "HOMEPAGE_VAR_SYNCTHING_API_KEY="
        fi
      } > /etc/homepage-dashboard/secrets.env
      chmod 600 /etc/homepage-dashboard/secrets.env
    '';
  };

  systemd.services.homepage-dashboard = {
    after = [ "homepage-secrets.service" ];
    serviceConfig.EnvironmentFile = "/etc/homepage-dashboard/secrets.env";
  };

  # Copy homepage configuration files to /nix/storage/homepage as reference backup
  # The actual dashboard config is generated inline above by services.homepage-dashboard
  system.activationScripts.homepage-config = ''
        mkdir -p /nix/storage/homepage

        cat > /nix/storage/homepage/services.yaml << 'HOMEEOF'
    ---
    services:
      - Media:
          - Jellyfin:
              href: https://jellyfin.minerales.network
              description: Media server with hardware acceleration
              icon: jellyfin.png
              widget:
                type: jellyfin
                url: http://localhost:8096
                key: {{HOMEPAGE_VAR_JELLYFIN_API_KEY}}

      - Downloads:
          - Transmission:
              href: https://transmission.minerales.network
              description: Torrent client
              icon: transmission.png
              widget:
                type: transmission
                url: http://localhost:9091

      - Synchronization:
          - Syncthing:
              href: https://syncthing.minerales.network
              description: File synchronization
              icon: syncthing.png
              widget:
                type: syncthing
                url: http://localhost:8384

      - AI/ML:
          - LLM Hub:
              href: https://llm.minerales.network
              description: Large Language Models interface
              icon: openai.png

          - Text Generation:
              href: https://textgen.minerales.network
              description: Advanced text generation WebUI
              icon: huggingface.png

          - Jupyter Lab:
              href: https://jupyter.minerales.network
              description: Machine Learning notebooks
              icon: jupyter.png
    HOMEEOF

        cat > /nix/storage/homepage/settings.yaml << 'HOMEEOF'
    ---
    title: Cobalto Media & AI Server

    theme: dark

    color: Material Darker

    headerStyle: boxed

    layout:
      Media:
        style: row
        columns: 2
      Downloads:
        style: row
        columns: 2
      Synchronization:
        style: row
        columns: 2
      Management:
        style: row
        columns: 3
      AI/ML:
        style: row
        columns: 3

    providers:
      glances: http://localhost:61208

    quicklaunch:
      searchDescriptions: true
      hideInternetSearch: true
      hideVisitURL: true
    HOMEEOF

        cat > /nix/storage/homepage/widgets.yaml << 'HOMEEOF'
    ---
    - resources:
        backend: glances
        expanded: true
        cpu: true
        memory: true
        disk: /

    - search:
        provider: duckduckgo
        target: _blank

    - datetime:
        text_size: xl
        format:
          timeStyle: short
          dateStyle: short
          hourCycle: h23

    - glances:
        url: http://localhost:61208
        version: 4
        metric: info
    HOMEEOF

        cat > /nix/storage/homepage/bookmarks.yaml << 'HOMEEOF'
    ---
    - Development:
        - GitHub:
            - href: https://github.com/DiegoBarrosA/nix-config
              description: This NixOS configuration repository
              icon: github.png

        - NixOS:
            - href: https://nixos.org
              description: NixOS homepage
              icon: nixos.png
            - href: https://search.nixos.org/packages
              description: NixOS package search
              icon: nixos.png

    - Documentation:
        - Services:
            - href: https://jellyfin.org/docs/
              description: Jellyfin documentation
              icon: jellyfin.png
    HOMEEOF

        chown -R 1000:1000 /nix/storage/homepage
        chmod -R 644 /nix/storage/homepage/*.yaml
  '';
}
