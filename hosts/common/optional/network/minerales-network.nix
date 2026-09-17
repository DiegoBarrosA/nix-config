{
  config,
  lib,
  pkgs,
  ...
}:

let

  withSSL =
    domain: vhostConfig:
    vhostConfig
    // {
      forceSSL = true;
      useACMEHost = "minerales.network";
    };

  standardProxy = port: {
    proxyPass = "http://127.0.0.1:${toString port}";
    proxyWebsockets = true;
    extraConfig = ''
      proxy_buffering off;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host $host;
    '';
  };
in
{

  systemd.tmpfiles.rules = [
    "d /var/lib/private 0700 root root -"
  ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "diego@minerales.network";

    certs."minerales.network" = {
      domain = "minerales.network";
      extraDomainNames = [ "*.minerales.network" ];
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      credentialFiles = {
        "CF_DNS_API_TOKEN_FILE" = config.sops.secrets."cloudflare-dns-token".path;
      };

      reloadServices = [ "nginx" ];
    };
  };

  users.users.nginx.extraGroups = [ "acme" ];

  services.nginx = {
    enable = true;

    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    proxyTimeout = "300s";

    clientMaxBodySize = "1g";

    virtualHosts = {

      "_" = {
        forceSSL = true;
        useACMEHost = "minerales.network";
        serverName = "_";
        extraConfig = ''
          ssl_reject_handshake on;
        '';
      };

      "home.minerales.network" = withSSL "home" {
        locations."/" = standardProxy 8082;

        locations."/zennotes-icon.svg" = {
          root = ../../../../assets/homepage;
        };
      };

      "jellyfin.minerales.network" = withSSL "jellyfin" {
        locations."/" = standardProxy 8096;
      };

      "transmission.minerales.network" = withSSL "transmission" {
        locations."/" = {
          proxyPass = "http://localhost:8080";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };

      "jellyseerr.minerales.network" = withSSL "jellyseerr" {
        locations."/" = standardProxy 5055;
      };

      "tdarr.minerales.network" = withSSL "tdarr" {
        locations."/" = standardProxy 8265;
      };

      "aria2.minerales.network" = withSSL "aria2" {
        locations."/" = standardProxy 6800;
        locations."/jsonrpc" = standardProxy 6800;
      };

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

      "llm.minerales.network" = withSSL "llm" {
        locations = {

          "/" = {
            proxyPass = "http://localhost:8080";
            proxyWebsockets = true;
          };

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

      "matrix.minerales.network" = withSSL "matrix" {
        locations = {

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

          "= /.well-known/matrix/client" = {
            extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin *;
              return 200 '{"m.homeserver": {"base_url": "https://matrix.minerales.network"}}';
            '';
          };

          "= /.well-known/matrix/server" = {
            extraConfig = ''
              default_type application/json;
              return 200 '{"m.server": "matrix.minerales.network:443"}';
            '';
          };

          "/" = {
            extraConfig = ''
              default_type text/html;
              return 200 '<html><body><h1>Matrix Homeserver</h1><p>Use a Matrix client like Element to connect.</p></body></html>';
            '';
          };
        };
      };

      "element.minerales.network" = withSSL "element" {
        root = "/var/www/element";
        locations = {
          "/" = {
            index = "index.html";
            tryFiles = "$uri $uri/ /index.html";
          };
        };
      };

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

      "opencode.minerales.network" = withSSL "opencode" {
        locations."/" = standardProxy 4096;
      };

      "notes.minerales.network" = withSSL "notes" {
        locations."/" = standardProxy 7879;
      };

      "yattee.minerales.network" = withSSL "yattee" {
        locations."/" = standardProxy 8085;
      };

      "turn.minerales.network" = withSSL "turn" {
        locations."/" = {
          extraConfig = ''
            default_type text/html;
            return 200 '<html><body><h1>TURN Server</h1><p>This is a TURN/STUN server for voice/video calls.</p></body></html>';
          '';
        };
      };

      "vault.minerales.network" = withSSL "vault" {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8000";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };

    };
  };

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

  services.nginx.appendHttpConfig = ''
    set_real_ip_from 100.64.0.0/10;
    real_ip_header X-Forwarded-For;
  '';

  services.nginx.serverTokens = false;
}
