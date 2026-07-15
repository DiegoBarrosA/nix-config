{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Element Web configuration
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
      # Enable widgets and integrations
      enable_widgets = true;
      allow_public_rooms = true;
    }
  );
in
{
  # Matrix Synapse - Private homeserver for Tailscale network
  # Access via matrix.minerales.network (covered by wildcard DNS, Tailscale only)
  # Element Web UI at element.minerales.network
  # Voice/Video calls via coturn TURN server
  #
  # Prerequisites:
  # - Friends need a Tailscale account and must join your tailnet
  # - Wildcard DNS (*.minerales.network) already covers subdomains
  #
  # After deployment:
  # 1. Create secrets file:
  #    echo "registration_shared_secret: $(openssl rand -hex 32)" | sudo tee /nix/storage/matrix-synapse/secrets.yaml
  #    sudo chown matrix-synapse:matrix-synapse /nix/storage/matrix-synapse/secrets.yaml
  #    sudo chmod 600 /nix/storage/matrix-synapse/secrets.yaml
  # 2. Create admin user:
  #    nix-shell -p matrix-synapse --run "register_new_matrix_user -k YOUR_SECRET http://localhost:8008"
  # 3. Access Element Web at: https://element.minerales.network
  # 4. Voice/video calls should work automatically via TURN server

  services.matrix-synapse = {
    enable = true;

    # Use custom data directory for persistence
    dataDir = "/nix/storage/matrix-synapse";

    settings = {
      server_name = "minerales.network";
      public_baseurl = "https://matrix.minerales.network";

      # Listeners
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

      # Media storage
      media_store_path = "/nix/storage/matrix-synapse/media";
      uploads_path = "/nix/storage/matrix-synapse/uploads";

      # Database - SQLite for simplicity
      database = {
        name = "sqlite3";
        args = {
          database = "/nix/storage/matrix-synapse/homeserver.db";
        };
      };

      # Registration - disabled by default (use CLI to create users)
      enable_registration = false;
      enable_registration_without_verification = false;

      # Enable widgets and integrations
      enable_widgets = true;
      allow_embedding_server = true;

      # Federation - disabled for private Tailscale-only setup
      federation_domain_whitelist = [ ];
      allow_public_rooms_over_federation = false;

      # TURN server configuration for voice/video calls
      turn_uris = [
        "turn:turn.minerales.network:3478?transport=udp"
        "turn:turn.minerales.network:3478?transport=tcp"
        "turns:turn.minerales.network:5349?transport=tcp"
      ];
      # Must match the coturn static-auth-secret
      turn_shared_secret = "changeme-turn-secret";
      turn_user_lifetime = "1h";
      turn_allow_guests = false;

      # Privacy & Security
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

      # Rate limiting - relaxed for private network
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

      # VoIP configuration
      # Enable voice/video call support
      voip_over_tcp = true;

      # Logging
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

      # Other settings
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

  # Coturn TURN server for voice/video NAT traversal
  services.coturn = {
    enable = true;

    # Use the same realm as the Matrix server
    realm = "minerales.network";

    # Shared secret for authentication - generate one with: openssl rand -hex 32
    # TODO: Move to SOPS secrets
    static-auth-secret = "changeme-turn-secret";

    # Disable static credentials, use time-limited tokens
    lt-cred-mech = true;
    no-cli = true;

    # Listening ports
    listening-port = 3478;
    tls-listening-port = 5349;

    # Use the ACME certificate for TLS
    cert = "/var/lib/acme/minerales.network/fullchain.pem";
    pkey = "/var/lib/acme/minerales.network/key.pem";

    # Relay ports range
    min-port = 49152;
    max-port = 49252;

    extraConfig = ''
      # Security: deny private IP ranges for relay
      denied-peer-ip=10.0.0.0-10.255.255.255
      denied-peer-ip=192.168.0.0-192.168.255.255
      denied-peer-ip=172.16.0.0-172.31.255.255
      denied-peer-ip=0.0.0.0-0.255.255.255
      denied-peer-ip=127.0.0.0-127.255.255.255

      # Disable multicast peers
      no-multicast-peers

      # Use fingerprint for TURN messages
      fingerprint

      # External IP (Tailscale IP)
      # Uncomment and set to your Tailscale IP if needed:
      # external-ip=100.69.115.53
    '';
  };

  # Allow coturn to read ACME certs
  security.acme.certs."minerales.network".group = "acme";
  users.groups.acme.members = [
    "turnserver"
    "nginx"
  ];

  # Element Web - Matrix client
  # Served as static files via nginx
  systemd.tmpfiles.rules = [
    "d /nix/storage/matrix-synapse 0700 matrix-synapse matrix-synapse -"
    "d /nix/storage/matrix-synapse/media 0700 matrix-synapse matrix-synapse -"
    "d /nix/storage/matrix-synapse/uploads 0700 matrix-synapse matrix-synapse -"
    "d /var/www/element 0755 root root -"
  ];

  # Use a service to set up Element Web (more reliable than activation scripts)
  systemd.services.element-web-setup = {
    description = "Set up Element Web files";
    wantedBy = [ "multi-user.target" ];
    before = [ "nginx.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Copy Element Web files
      rm -rf /var/www/element/*
      cp -r ${pkgs.element-web}/* /var/www/element/

      # Override the config with our custom one
      cp ${elementConfig} /var/www/element/config.json

      # Fix permissions
      chmod -R 755 /var/www/element
    '';
  };

  # NOTE: Maubot is currently broken in nixpkgs (missing base58 dependency)
  # For Jellyfin notifications, use the Jellyfin webhook plugin with a simple
  # Matrix bot script, or wait for maubot to be fixed upstream.
  #
  # Alternative: Use ntfy.sh or a simple webhook receiver container

  # Create the matrix-synapse user/group
  users.users.matrix-synapse = {
    isSystemUser = true;
    group = "matrix-synapse";
    home = "/nix/storage/matrix-synapse";
    description = "Matrix Synapse service user";
  };
  users.groups.matrix-synapse = { };

  # Firewall - open TURN ports
  networking.firewall = {
    allowedTCPPorts = [
      3478 # TURN TCP
      5349 # TURN TLS
    ];
    allowedUDPPorts = [
      3478 # TURN UDP
    ];
    allowedUDPPortRanges = [
      {
        from = 49152;
        to = 49252;
      } # TURN relay ports
    ];
  };
}
