{ config, lib, pkgs, ... }:

let
  mediaRoot = "/srv/media";
in
{

  users.groups.media = { };

  services.transmission = {
    enable = true;
    user = "media";
    group = "media";

    settings = {
      rpc-bind-address = "0.0.0.0";
      rpc-port = 8080;
      rpc-whitelist-enabled = false;
      rpc-username = "admin";
      download-dir = "${mediaRoot}/downloads/complete";
      incomplete-dir = "${mediaRoot}/downloads/incomplete";
      incomplete-dir-enabled = true;
      peer-port = 51413;
      port-forwarding-enabled = false;
      encryption = 1;
    };

    credentialsFile = config.sops.templates."transmission-credentials.json".path;
  };

  sops.templates."transmission-credentials.json" = {
    content = ''
      {
        "rpc-password": "${config.sops.placeholder."transmission-password"}"
      }
    '';
    owner = "media";
    group = "media";
    mode = "0400";
  };

  systemd.services.transmission-setup = {
    description = "Setup Transmission directories for Servarr integration";
    wantedBy = [ "multi-user.target" ];
    before = [ "transmission.service" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      echo "[transmission] Setting up directories..."

      mkdir -p ${mediaRoot}/downloads/complete/{movies,series,lidarr,lazylibrarian,bazarr}
      mkdir -p ${mediaRoot}/downloads/incomplete

      chown -R media:media ${mediaRoot}/downloads
      chmod -R 755 ${mediaRoot}/downloads

      echo "[transmission] Directories ready:"
      echo "  - Downloads: ${mediaRoot}/downloads/"
      echo "  - Complete:  ${mediaRoot}/downloads/complete/"
      echo "  - Incomplete: ${mediaRoot}/downloads/incomplete/"
    '';
  };

}
