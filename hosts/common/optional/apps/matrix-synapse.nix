{
  config,
  lib,
  pkgs,
  ...
}:

let

  elementConfig = pkgs.writeText "element-config.json" (
    builtins.toJSON {
      default_server_config = {
        "m.homeserver" = {
          base_url = "https://matrix.minerales.network";
          server_name = "minerales.network";
        };
      };
      disable_custom_urls = false;
      disable_guests = true;
      disable_login_language_selector = false;
      disable_3pid_login = false;
      brand = "Minerales Chat";
      integrations_ui_url = "https://integrations.element.io";
      integrations_rest_url = "https://integrations.element.io";
      integrations_widgets_urls = [ "https://integrations.element.io" ];
      default_theme = "dark";
      room_directory = {
        servers = [ "minerales.network" ];
      };
      features = {
        feature_video_rooms = true;
        feature_group_calls = true;
        feature_element_call_video_rooms = true;
        feature_location_share_geo = true;
      };
      element_call = {
        url = "https://call.element.io";
        use_exclusively = false;
      };
      voip = {
        obey_asserted_identity = true;
      };
      audio_stream_url = "";
      jitsi = {
        preferred_domain = "meet.element.io";
      };

      enable_widgets = true;
      allow_public_rooms = true;
    }
  );
in
{

  services.matrix-synapse = {
    enable = true;

    dataDir = "/nix/storage/matrix-synapse";

    settings = {
      server_name = "minerales.network";
      public_baseurl = "https://matrix.minerales.network";

      listeners = [
        {
          port = 8008;
          bind_addresses = [ "127.0.0.1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = true;
            }
          ];
        }
      ];

      media_store_path = "/nix/storage/matrix-synapse/media";
      uploads_path = "/nix/storage/matrix-synapse/uploads";

      database = {
        name = "sqlite3";
        args = {
          database = "/nix/storage/matrix-synapse/homeserver.db";
        };
      };

      enable_registration = false;
      enable_registration_without_verification = false;

      enable_widgets = true;
      allow_embedding_server = true;

      federation_domain_whitelist = [ ];
      allow_public_rooms_over_federation = false;

      turn_uris = [
        "turn:turn.minerales.network:3478?transport=udp"
        "turn:turn.minerales.network:3478?transport=tcp"
        "turns:turn.minerales.network:5349?transport=tcp"
      ];

      turn_shared_secret = "changeme-turn-secret";
      turn_user_lifetime = "1h";
      turn_allow_guests = false;

      url_preview_enabled = true;
      url_preview_ip_range_blacklist = [
        "127.0.0.0/8"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "100.64.0.0/10"
        "169.254.0.0/16"
        "::1/128"
        "fe80::/10"
        "fc00::/7"
      ];

      rc_message = {
        per_second = 10;
        burst_count = 50;
      };
      rc_registration = {
        per_second = 1;
        burst_count = 5;
      };
      rc_login = {
        address = {
          per_second = 1;
          burst_count = 10;
        };
        account = {
          per_second = 1;
          burst_count = 10;
        };
        failed_attempts = {
          per_second = 1;
          burst_count = 10;
        };
      };

      voip_over_tcp = true;

      log_config = pkgs.writeText "synapse-log-config.yaml" ''
        version: 1
        formatters:
          precise:
            format: '%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(request)s - %(message)s'
        handlers:
          console:
            class: logging.StreamHandler
            formatter: precise
        loggers:
          synapse.storage.SQL:
            level: WARNING
        root:
          level: WARNING
          handlers: [console]
        disable_existing_loggers: false
      '';

      trusted_third_party_id_servers = [ ];
      presence.enabled = true;
      push.include_content = false;
      max_upload_size = "100M";

      retention = {
        enabled = true;
        default_policy = {
          min_lifetime = "1d";
          max_lifetime = "365d";
        };
      };
    };

    extraConfigFiles = [
      "/nix/storage/matrix-synapse/secrets.yaml"
    ];
  };

  services.coturn = {
    enable = true;

    realm = "minerales.network";

    static-auth-secret = "changeme-turn-secret";

    lt-cred-mech = true;
    no-cli = true;

    listening-port = 3478;
    tls-listening-port = 5349;

    cert = "/var/lib/acme/minerales.network/fullchain.pem";
    pkey = "/var/lib/acme/minerales.network/key.pem";

    min-port = 49152;
    max-port = 49252;

    extraConfig = ''
      denied-peer-ip=10.0.0.0-10.255.255.255
      denied-peer-ip=192.168.0.0-192.168.255.255
      denied-peer-ip=172.16.0.0-172.31.255.255
      denied-peer-ip=0.0.0.0-0.255.255.255
      denied-peer-ip=127.0.0.0-127.255.255.255

      no-multicast-peers

      fingerprint

    '';
  };

  security.acme.certs."minerales.network".group = "acme";
  users.groups.acme.members = [
    "turnserver"
    "nginx"
  ];

  systemd.tmpfiles.rules = [
    "d /nix/storage/matrix-synapse 0700 matrix-synapse matrix-synapse -"
    "d /nix/storage/matrix-synapse/media 0700 matrix-synapse matrix-synapse -"
    "d /nix/storage/matrix-synapse/uploads 0700 matrix-synapse matrix-synapse -"
    "d /var/www/element 0755 root root -"
  ];

  systemd.services.element-web-setup = {
    description = "Set up Element Web files";
    wantedBy = [ "multi-user.target" ];
    before = [ "nginx.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''

      rm -rf /var/www/element/*
      cp -r ${pkgs.element-web}/* /var/www/element/

      cp ${elementConfig} /var/www/element/config.json

      chmod -R 755 /var/www/element
    '';
  };

  users.users.matrix-synapse = {
    isSystemUser = true;
    group = "matrix-synapse";
    home = "/nix/storage/matrix-synapse";
    description = "Matrix Synapse service user";
  };
  users.groups.matrix-synapse = { };

  networking.firewall = {
    allowedTCPPorts = [
      3478
      5349
    ];
    allowedUDPPorts = [
      3478
    ];
    allowedUDPPortRanges = [
      {
        from = 49152;
        to = 49252;
      }
    ];
  };

  # dataDir holds the sqlite homeserver.db, the media store, uploads and the
  # signing key. Losing the signing key breaks federation permanently.
  backups.restic.sources = [ "/nix/storage/matrix-synapse" ];
}
