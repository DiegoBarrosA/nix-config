{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.networking.pihole;
in
{
  options.networking.pihole = {
    enable = lib.mkEnableOption "Pi-hole DNS ad blocker";

    upstreamServers = lib.mkOption {
      type = with lib.types; listOf str;
      default = [
        "1.1.1.1"
        "9.9.9.9"
      ];
      description = "Upstream DNS servers";
    };

    webPort = lib.mkOption {
      type = lib.types.port;
      default = 8388;
      description = "Port for the Pi-hole web interface";
    };

    blocklists = lib.mkOption {
      type = with lib.types; listOf (submodule {
        options = {
          url = lib.mkOption {
            type = lib.types.str;
            description = "URL of the blocklist";
          };
          description = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Description";
          };
          enabled = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether this list is enabled";
          };
        };
      });
      default = [
        {
          url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
          description = "StevenBlack Unified";
        }
        {
          url = "https://big.oisd.nl/";
          description = "OISD Big";
        }
        {
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/pro.txt";
          description = "HaGeZi Pro";
        }
        {
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/tif.txt";
          description = "HaGeZi TIF (Threat Intelligence Feeds)";
        }
      ];
      description = "Blocklists to use with Pi-hole";
    };
  };

  config = lib.mkIf cfg.enable {

    services.pihole-ftl = {
      enable = true;
      openFirewallDNS = true;
      openFirewallWebserver = true;
      privacyLevel = 0;

      settings = {
        misc = {
          dnsmasq_lines = [
            "no-hosts"
            "interface=tailscale0"
            "interface=enp7s0"
            "bind-interfaces"
            "address=/minerales.network/${config.networking.warpExit.cobaltoTailscaleIp}"
          ];
        };
        dns = {
          upstreams = cfg.upstreamServers;
        };
        webserver = {
          api.cli_pw = true;
          port = toString cfg.webPort;
        };
      };

      lists = map (list: {
        url = list.url;
        description = list.description;
        enabled = list.enabled;
        type = "block";
      }) cfg.blocklists;

      queryLogDeleter = {
        enable = true;
        age = 90;
      };
    };

    services.pihole-web = {
      enable = true;
      ports = [ cfg.webPort ];
    };

    # The pihole-ftl-setup service is missing PIHOLE_CONFIG in its environment,
    # so getFTLConfigValue returns wrong paths (e.g. /etc/pihole/gravity.db
    # instead of /var/lib/pihole/gravity.db), causing downloads to silently fail.
    # Propagate from the main FTL service.
    systemd.services.pihole-ftl-setup.environment.PIHOLE_CONFIG =
      config.systemd.services.pihole-ftl.environment.PIHOLE_CONFIG;

  };
}
