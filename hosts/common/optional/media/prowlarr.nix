{
  config,
  lib,
  pkgs,
  ...
}:

{

  networking.firewall.interfaces."enp6s0".allowedTCPPorts = [ 9696 ];

  services.prowlarr = {
    enable = true;
    openFirewall = true;
    dataDir = "/nix/storage/servarr/prowlarr";
  };

  users.groups.media = { };

  systemd.services.prowlarr = lib.mkIf config.services.prowlarr.enable {
    after = [ "nix-storage.mount" ];
    requires = [ "nix-storage.mount" ];
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "diego";
      Group = "media";

      ExecStart = lib.mkForce "${pkgs.prowlarr}/bin/Prowlarr -nobrowser -data=${config.services.prowlarr.dataDir}";

      StateDirectory = lib.mkForce "";
      StateDirectoryMode = lib.mkForce "";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/private 0700 root root -"
  ];
}
