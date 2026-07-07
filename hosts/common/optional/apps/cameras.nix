{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.cameras;
in {
  options.services.cameras = {
    enable = mkEnableOption "Camera proxy services (neolink + micam)";

    reolink = {
      enable = mkEnableOption "neolink RTSP bridge for Reolink E1";
      ip = mkOption {
        type = types.str;
        default = "192.168.1.7";
        description = "Reolink camera IP address";
      };
      rtspPort = mkOption {
        type = types.port;
        default = 8556;
        description = "Port for neolink RTSP server";
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.podman.enable = true;

    sops.secrets = mkIf cfg.reolink.enable {
      "camera-reolink-user" = { };
      "camera-reolink-pass" = { };
    };

    sops.templates."neolink-config" = mkIf cfg.reolink.enable {
      content = ''
        bind = "0.0.0.0"
        port = ${toString cfg.reolink.rtspPort}

        [[cameras]]
        name = "reolink_e1"
        username = "${config.sops.placeholder.camera-reolink-user}"
        password = "${config.sops.placeholder.camera-reolink-pass}"
        address = "${cfg.reolink.ip}"
      '';
    };

    virtualisation.oci-containers = {
      backend = "podman";

      containers.neolink = mkIf cfg.reolink.enable {
        image = "docker.io/quantumentangledandy/neolink:latest";
        autoStart = true;
        extraOptions = [ "--network=host" ];
        volumes = [
          "${config.sops.templates."neolink-config".path}:/etc/neolink.toml:ro"
        ];
        environment = {
          NEO_LINK_MODE = "rtsp";
          NEO_LINK_PORT = toString cfg.reolink.rtspPort;
        };
      };
    };
  };
}
