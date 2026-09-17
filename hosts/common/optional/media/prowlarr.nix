{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.prowlarr = {
    enable = true;
    openFirewall = false;
    dataDir = "/nix/storage/servarr/prowlarr";
  };

  systemd.services.prowlarr = lib.mkIf config.services.prowlarr.enable {
    after = [ "nix-storage.mount" ];
    requires = [ "nix-storage.mount" ];
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "media";
      Group = "media";

      ExecStart = lib.mkForce "${pkgs.prowlarr}/bin/Prowlarr -nobrowser -data=${config.services.prowlarr.dataDir}";

      StateDirectory = lib.mkForce "";
      StateDirectoryMode = lib.mkForce "";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/private 0700 root root -"
  ];

  systemd.tmpfiles.settings = lib.mkIf config.services.prowlarr.enable {
    "10-prowlarr" = lib.mkForce {
      ${config.services.prowlarr.dataDir}.d = {
        user = "media";
        group = "media";
        mode = "0700";
      };
    };
  };

  backups.restic.sources = lib.mkIf config.services.prowlarr.enable [ config.services.prowlarr.dataDir ];
}