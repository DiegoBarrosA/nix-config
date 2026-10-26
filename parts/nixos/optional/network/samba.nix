{ ... }:
{
  # Two non-overlapping shares, login required, read and write as diego.
  # Files are written as media:media so the media services can use them.
  flake.modules.nixos.network-samba =
    { config, pkgs, ... }:
    let
      share = path: comment: {
        inherit path comment;
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "diego";
        "force user" = "media";
        "force group" = "media";
        "create mask" = "0664";
        "directory mask" = "0775";
        "vfs objects" = "fruit acl_xattr";
      };
    in
    {
      services.samba = {
        enable = true;
        openFirewall = true;

        settings = {
          global = {
            "netbios name" = "cobalto";
            workgroup = "MINERALES";
            "server string" = "Cobalto Media Server";

            security = "user";
            # Unknown users are refused instead of being mapped to guest.
            "map to guest" = "never";

            "max connections" = 200;
            "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";

            "log level" = 1;
            "log file" = "/var/log/samba/%m.log";
            "max log size" = 50000;

            "fruit:encoding" = "native";
            "dns proxy" = "no";
          };

          # Library, downloads, Documents, Obsidian, Repos, Pictures and Incoming
          # are all inside this tree, so they are not shared again on their own.
          media = share "/srv/media" "Media library, downloads and synced folders";
          storage = share "/nix/storage" "Service data";
        };
      };

      environment.systemPackages = [ pkgs.cifs-utils ];

      # Samba keeps its password database in /var/lib/samba, which is wiped on
      # boot (impermanence), so set the password from sops on every start.
      sops.secrets."samba-diego-password" = {
        owner = "root";
        group = "root";
        mode = "0400";
      };

      systemd.services.samba-diego-password = {
        description = "Set the Samba password for diego";
        wantedBy = [ "multi-user.target" ];
        before = [ "samba-smbd.service" ];
        wants = [ "sops-install-secrets.service" ];
        after = [ "sops-install-secrets.service" ];
        serviceConfig.Type = "oneshot";
        script = ''
          pw=$(cat ${config.sops.secrets."samba-diego-password".path})
          printf '%s\n%s\n' "$pw" "$pw" | ${config.services.samba.package}/bin/smbpasswd -s -a diego
        '';
      };
    };
}
