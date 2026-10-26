{ ... }:
{
  flake.modules.nixos.media-qbittorrent =
{ config, lib, pkgs, ... }:

let
  mediaRoot = "/srv/media";
  qbConfigFile = "/nix/storage/qbittorrent/qBittorrent/config/qBittorrent.conf";
in
{

  users.groups.media = { };

  services.qbittorrent = {
    enable = true;
    user = "media";
    group = "media";

    webuiPort = 8080;
    torrentingPort = 51413;
    openFirewall = false;

    profileDir = "/nix/storage/qbittorrent";

    serverConfig = {
      LegalNotice.Accepted = true;

      Preferences = {
        WebUI = {
          Port = 8080;
        };
        "Session\\DefaultSavePath" = "${mediaRoot}/downloads";
        "Session\\TempPath" = "${mediaRoot}/downloads";
        "Downloads\\TempPath" = "${mediaRoot}/downloads";
        "Downloads\\SavePath" = "${mediaRoot}/downloads";
        "Downloads\\TempPathEnabled" = true;
        "Downloads\\UseCategoryFolders" = true;
        General = {
          Locale = "en_US";
        };
      };

    };
  };

  systemd.services.qbittorrent-credentials = {
    description = "Generate qBittorrent credentials from sops secrets";
    wantedBy = [ "multi-user.target" ];
    before = [ "qbittorrent.service" ];
    after = [ "local-fs.target" "sops-install-secrets.service" "qbittorrent-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      USERNAME_FILE="${config.sops.secrets."qbittorrent-username".path}"
      PASSWORD_FILE="${config.sops.secrets."qbittorrent-password".path}"
      CONFIG_FILE="${qbConfigFile}"

      USERNAME=$(cat "$USERNAME_FILE")
      PASSWORD=$(cat "$PASSWORD_FILE")

      mkdir -p "$(dirname "$CONFIG_FILE")"

      PASS_HASH=$(${pkgs.python3}/bin/python3 -c "
      import hashlib, secrets, sys
      password = sys.argv[1]
      salt = secrets.token_bytes(16)
      iterations = 100000
      dk = hashlib.pbkdf2_hmac('sha512', password.encode(), salt, iterations)
      print(f'@ByteArray({salt.hex().upper()}:{dk.hex().upper()}:{iterations})')
      " "$PASSWORD")

      cat > "$CONFIG_FILE" << EOF
      [LegalNotice]
      Accepted=true

      [Preferences]
      WebUI\\Username=$USERNAME
      WebUI\\Password_PBKDF2=$PASS_HASH
      WebUI\\Port=8080
      Session\\DefaultSavePath=${mediaRoot}/downloads
      Session\\TempPath=${mediaRoot}/downloads
      Downloads\\TempPath=${mediaRoot}/downloads
      Downloads\\SavePath=${mediaRoot}/downloads
      Downloads\\TempPathEnabled=true
      Downloads\\UseCategoryFolders=true
      General\\Locale=en_US
      EOF

      chown media:media "$CONFIG_FILE"
    '';
  };

  systemd.services.qbittorrent-setup = {
    description = "Setup qBittorrent directories for Servarr integration";
    wantedBy = [ "multi-user.target" ];
    before = [ "qbittorrent.service" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      echo "[qbittorrent] Setting up directories..."

      mkdir -p ${mediaRoot}/downloads/complete/{movies,series,lidarr,lazylibrarian,bazarr}
      mkdir -p ${mediaRoot}/downloads/incomplete
      mkdir -p /nix/storage/qbittorrent

      chown -R media:media ${mediaRoot}/downloads
      chown -R media:media /nix/storage/qbittorrent
      chmod -R 755 /nix/storage/qbittorrent

      echo "[qbittorrent] Directories ready:"
      echo "  - Downloads: ${mediaRoot}/downloads/"
      echo "  - Complete:  ${mediaRoot}/downloads/complete/"
      echo "  - Categories: movies, series, lidarr, lazylibrarian, bazarr"
    '';
  };

}

  ;
}
