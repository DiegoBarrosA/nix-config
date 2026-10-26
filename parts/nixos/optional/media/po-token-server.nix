{ ... }:
{
  flake.modules.nixos.media-po-token-server =
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.po-token-server;
in {
  options.services.po-token-server = {
    enable = mkEnableOption "bgutil-ytdlp-pot-provider HTTP server for YouTube Music PO tokens";
    port = mkOption {
      type = types.port;
      default = 4416;
      description = "Port for the PO Token server";
    };
    version = mkOption {
      type = types.str;
      default = "1.2.1";
      description = "Version of bgutil-ytdlp-pot-provider to run";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers = {
      backend = "podman";

      containers.po-token-server = {
        image = "docker.io/brainicism/bgutil-ytdlp-pot-provider:${cfg.version}";
        autoStart = true;
        ports = [ "${toString cfg.port}:4416" ];
      };
    };
  };
}

  ;
}
