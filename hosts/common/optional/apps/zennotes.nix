{ config, lib, pkgs, customPkgs, ... }:

let
  cfg = config.services.zennotes;
  port = 7879;
in
{
  options.services.zennotes = {
    enable = lib.mkEnableOption "ZenNotes web server";

    vaultPath = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/media/Obsidian/obsidiana";
      description = "Path to the default Obsidian vault exposed by ZenNotes.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "diego";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.zennotes = {
      description = "ZenNotes web server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        ZENNOTES_BIND = "127.0.0.1:${toString port}";
        ZENNOTES_CONFIG_PATH = "/var/lib/zennotes/server.json";
        ZENNOTES_DEFAULT_VAULT_PATH = cfg.vaultPath;
        ZENNOTES_BROWSE_ROOTS = cfg.vaultPath;
        ZENNOTES_ALLOWED_ORIGINS = "https://notes.minerales.network";
        # ponytail: no auth token — access is Tailscale-gated via nginx
        ZENNOTES_ALLOW_INSECURE_NOAUTH = "1";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        ExecStart = "${customPkgs.zennotes-server}/bin/zennotes-server";
        StateDirectory = "zennotes";
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };
  };
}
