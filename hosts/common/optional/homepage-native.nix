{ config, lib, pkgs, ... }:

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
      61208  # Glances system monitoring
    ];
  };

  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    allowedHosts = "home.minerales.network" ;
    listenPort = 8082;

    settings = {
      title = "Cobalto Media Server";
      theme = "dark";
      # color = "Material Darker";
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

      background = {
        color = "#212121";
      };

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
              server = "localhost";
              container = "jellyfin";
            };
          }
          {
            "Transmission" = {
              icon = "transmission.png";
              href = "http://transmission.minerales.network";
              description = "Native BitTorrent client";
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
              href = "http://localhost:8080";
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
                url = "http://localhost:8384";
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
      # Developer news feeds (hackertab.dev-style curated sources)
      {
        rss = {
          feedurl = "https://hnrss.org/frontpage";
          name = "Hacker News";
          limit = 6;
        };
      }
      {
        rss = {
          feedurl = "https://lobste.rs/rss";
          name = "Lobsters";
          limit = 6;
        };
      }
      {
        rss = {
          feedurl = "https://dev.to/feed";
          name = "DEV.to";
          limit = 6;
        };
      }
      {
        rss = {
          feedurl = "https://www.freecodecamp.org/news/rss/";
          name = "freeCodeCamp";
          limit = 6;
        };
      }
    ];

    bookmarks = [
      {
        "Development" = [
          {
            "GitHub" = [
              {
                "nix-config" = {
                  href = "https://github.com/DiegoBarrosA/nix-config";
                };
              }
            ];
          }
        ];
      }
      {
        "Media" = [
          {
            "Streaming" = [
              {
                "YouTube" = {
                  href = "https://youtube.com";
                };
              }
              {
                "Spotify" = {
                  href = "https://spotify.com";
                };
              }
            ];
          }
        ];
      }
    ];
  };

# Create an environment file at activation time with SOPS secrets
  # This is read at runtime (not build time) so secrets are available
  system.activationScripts.homepage-secrets = lib.stringAfter ["homepage-config"] ''
    mkdir -p /etc/homepage-dashboard

    # Generate homepage-secrets.env with all API keys
    {
       echo "# Homepage Dashboard API Keys - generated at activation"
       if [ -f "/run/secrets/jellyfin-api-key" ] && [ -s "/run/secrets/jellyfin-api-key" ]; then
         echo "HOMEPAGE_VAR_JELLYFIN_API_KEY=$(cat /run/secrets/jellyfin-api-key | tr -d '\n')"
       else
         echo "HOMEPAGE_VAR_JELLYFIN_API_KEY="
       fi
       if [ -f "/run/secrets/prowlarr-api-key" ] && [ -s "/run/secrets/prowlarr-api-key" ]; then
         echo "HOMEPAGE_VAR_PROWLARR_API_KEY=$(cat /run/secrets/prowlarr-api-key | tr -d '\n')"
       else
         echo "HOMEPAGE_VAR_PROWLARR_API_KEY="
       fi
       if [ -f "/run/secrets/sonarr-api-key" ] && [ -s "/run/secrets/sonarr-api-key" ]; then
         echo "HOMEPAGE_VAR_SONARR_API_KEY=$(cat /run/secrets/sonarr-api-key | tr -d '\n')"
       else
         echo "HOMEPAGE_VAR_SONARR_API_KEY="
       fi
       if [ -f "/run/secrets/radarr-api-key" ] && [ -s "/run/secrets/radarr-api-key" ]; then
         echo "HOMEPAGE_VAR_RADARR_API_KEY=$(cat /run/secrets/radarr-api-key | tr -d '\n')"
       else
         echo "HOMEPAGE_VAR_RADARR_API_KEY="
       fi
       if [ -f "/run/secrets/lidarr-api-key" ] && [ -s "/run/secrets/lidarr-api-key" ]; then
         echo "HOMEPAGE_VAR_LIDARR_API_KEY=$(cat /run/secrets/lidarr-api-key | tr -d '\n')"
       else
         echo "HOMEPAGE_VAR_LIDARR_API_KEY="
       fi
       if [ -f "/run/secrets/bazarr-api-key" ] && [ -s "/run/secrets/bazarr-api-key" ]; then
         echo "HOMEPAGE_VAR_BAZARR_API_KEY=$(cat /run/secrets/bazarr-api-key | tr -d '\n')"
       else
         echo "HOMEPAGE_VAR_BAZARR_API_KEY="
       fi
       if [ -f "/run/secrets/syncthing-api-key" ] && [ -s "/run/secrets/syncthing-api-key" ]; then
         echo "HOMEPAGE_VAR_SYNCTHING_API_KEY=$(cat /run/secrets/syncthing-api-key | tr -d '\n')"
       else
         echo "HOMEPAGE_VAR_SYNCTHING_API_KEY="
       fi
     } > /etc/homepage-dashboard/secrets.env

    chmod 600 /etc/homepage-dashboard/secrets.env
  '';

  # Tell systemd to read the environment file at runtime
  systemd.services.homepage-dashboard.serviceConfig.EnvironmentFile = "/etc/homepage-dashboard/secrets.env";

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