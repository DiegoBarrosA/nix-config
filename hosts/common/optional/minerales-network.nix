{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Helper to add SSL config via ACME to all virtualHosts
  withSSL =
    domain: vhostConfig:
    vhostConfig
    // {
      forceSSL = true;
      useACMEHost = "minerales.network";
    };

  # Standard proxy config (use 127.0.0.1 explicitly to avoid IPv6 resolution issues)
  standardProxy = port: {
    proxyPass = "http://127.0.0.1:${toString port}";
    proxyWebsockets = true;
    extraConfig = ''
      proxy_buffering off;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host $host;
    '';
  };
in
{
  # Private minerales.network subdomains accessible only through Tailscale
  # This configuration assumes:
  # 1. You own minerales.network domain in Cloudflare
  # 2. DNS records point to your Tailscale IP (100.x.x.x)
  # 3. Access is only possible when connected to your Tailscale network
  # 4. Let's Encrypt wildcard cert via Cloudflare DNS challenge

  systemd.tmpfiles.rules = [
    "d /var/lib/private 0700 root root -"
  ];

  # ACME configuration for Let's Encrypt wildcard certificate
  security.acme = {
    acceptTerms = true;
    defaults.email = "diego@minerales.network"; # Change to your email

    certs."minerales.network" = {
      domain = "minerales.network";
      extraDomainNames = [ "*.minerales.network" ];
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      credentialFiles = {
        "CF_DNS_API_TOKEN_FILE" = config.sops.secrets."cloudflare-dns-token".path;
      };
      # Reload nginx when cert is renewed
      reloadServices = [ "nginx" ];
    };
  };

  # Allow nginx to read ACME certs
  users.users.nginx.extraGroups = [ "acme" ];

  services.nginx = {
    enable = true;

    # Recommended settings
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    # Fix proxy_headers_hash warnings
    proxyTimeout = "300s";

    clientMaxBodySize = "1g";

    virtualHosts = {
      # Main server dashboard
      "home.minerales.network" = withSSL "home" {
        locations."/" = standardProxy 8082;
      };

      # Media Services
      "jellyfin.minerales.network" = withSSL "jellyfin" {
        locations."/" = standardProxy 8096;
      };

      "transmission.minerales.network" = withSSL "transmission" {
        locations."/" = {
          proxyPass = "http://localhost:9091";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };

      # Servarr Suite
      "prowlarr.minerales.network" = withSSL "prowlarr" {
        locations."/" = standardProxy 9696;
      };

      "flaresolverr.minerales.network" = withSSL "flaresolverr" {
        locations."/" = standardProxy 8191;
      };

      "sonarr.minerales.network" = withSSL "sonarr" {
        locations."/" = standardProxy 8989;
      };

      "radarr.minerales.network" = withSSL "radarr" {
        locations."/" = {
          proxyPass = "http://localhost:7878/";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
          '';
        };
      };

      "lidarr.minerales.network" = withSSL "lidarr" {
        locations."/" = standardProxy 8686;
      };

      "lazylibrarian.minerales.network" = withSSL "lazylibrarian" {
        locations."/" = standardProxy 5299;
      };

      "calibre.minerales.network" = withSSL "calibre" {
        locations."/" = standardProxy 8083;
      };

      "bazarr.minerales.network" = withSSL "bazarr" {
        locations."/" = standardProxy 6767;
      };

      # Infrastructure Services
      "syncthing.minerales.network" = withSSL "syncthing" {
        locations."/" = {
          proxyPass = "http://localhost:8384";
          proxyWebsockets = true;
          extraConfig = "proxy_buffering off;";
        };
      };

      "cockpit.minerales.network" = withSSL "cockpit" {
        locations."/" = {
          proxyPass = "https://localhost:9090";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
          '';
        };
      };

      "portainer.minerales.network" = withSSL "portainer" {
        locations."/" = standardProxy 8098;
      };

      # AI/LLM Services
      "llm.minerales.network" = withSSL "llm" {
        locations = {
          # Open WebUI chat interface
          "/" = {
            proxyPass = "http://localhost:8080";
            proxyWebsockets = true;
          };
          # llama.cpp OpenAI-compatible API (replaces Ollama)
          "/v1/" = {
            proxyPass = "http://localhost:11435/v1/";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_buffering off;
              proxy_read_timeout 600s;  # Long timeout for LLM generation
            '';
          };
        };
      };

      # Direct access to llama.cpp server API
      "llama.minerales.network" = withSSL "llama" {
        locations."/" = {
          proxyPass = "http://localhost:11435";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
            proxy_read_timeout 600s;  # Long timeout for LLM generation
          '';
        };
      };

      "jupyter.minerales.network" = withSSL "jupyter" {
        locations."/" = standardProxy 8888;
      };

      # Matrix Synapse - Private chat server
      "matrix.minerales.network" = withSSL "matrix" {
        locations = {
          # Client-Server API
          "~* ^(/_matrix|/_synapse/client)" = {
            proxyPass = "http://localhost:8008";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_buffering off;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Host $host;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_read_timeout 600s;
              client_max_body_size 100M;
            '';
          };
          # Well-known for client discovery
          "= /.well-known/matrix/client" = {
            extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin *;
              return 200 '{"m.homeserver": {"base_url": "https://matrix.minerales.network"}}';
            '';
          };
          # Well-known for server discovery (federation)
          "= /.well-known/matrix/server" = {
            extraConfig = ''
              default_type application/json;
              return 200 '{"m.server": "matrix.minerales.network:443"}';
            '';
          };
          # Root - friendly message
          "/" = {
            extraConfig = ''
              default_type text/html;
              return 200 '<html><body><h1>Matrix Homeserver</h1><p>Use a Matrix client like Element to connect.</p></body></html>';
            '';
          };
        };
      };

      # Element Web - Matrix client UI
      "element.minerales.network" = withSSL "element" {
        root = "/var/www/element";
        locations = {
          "/" = {
            index = "index.html";
            tryFiles = "$uri $uri/ /index.html";
          };
        };
      };

      # Obsidian LiveSync - CouchDB sync backend for obsidian-livesync plugin
      # CORS is handled by CouchDB itself (configured in couchdb.nix via extraConfig.cors)
      "sync.minerales.network" = withSSL "sync" {
        locations."/" = {
          proxyPass = "http://localhost:5984";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
            proxy_read_timeout 600s;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
          '';
        };
      };

      # Home Automation
      "homeassistant.minerales.network" = withSSL "homeassistant" {
        locations."/" = {
          proxyPass = "http://localhost:8123";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
          '';
        };
      };

      # Music Assistant
      "ma.minerales.network" = withSSL "ma" {
        locations."/" = {
          proxyPass = "http://localhost:8095";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
          '';
        };
      };

      # Snapcast multi-room audio
      "snapcast.minerales.network" = withSSL "snapcast" {
        root = "${pkgs.snapweb}";
        locations = {
          "/" = {
            tryFiles = "$uri $uri/ /index.html";
            index = "index.html";
          };
          "/jsonrpc" = {
            proxyPass = "http://localhost:1780";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_buffering off;
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Host $host;
            '';
          };
        };
      };

      # OpenCode remote access (API + web UI)
      "opencode.minerales.network" = withSSL "opencode" {
        locations."/" = standardProxy 4096;
      };

      # Invidious - YouTube frontend
      "invidious.minerales.network" = withSSL "invidious" {
        locations."/" = standardProxy 3000;
      };

      # Yattee Server - self-hosted video API (yt-dlp based stream proxy)
      "yattee.minerales.network" = withSSL "yattee" {
        locations."/" = standardProxy 8085;
      };

      # TURN server domain (for TLS TURN connections)
      "turn.minerales.network" = withSSL "turn" {
        locations."/" = {
          extraConfig = ''
            default_type text/html;
            return 200 '<html><body><h1>TURN Server</h1><p>This is a TURN/STUN server for voice/video calls.</p></body></html>';
          '';
        };
      };

    };
  };

  # Firewall configuration for Tailscale access
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    trustedInterfaces = [ "tailscale0" ];
    extraCommands = ''
      iptables -I nixos-fw -i tailscale0 -j nixos-fw-accept
    '';
  };

  # Real IP from Tailscale
  services.nginx.appendHttpConfig = ''
    set_real_ip_from 100.64.0.0/10;
    real_ip_header X-Forwarded-For;
  '';

  services.nginx.serverTokens = false;
}
