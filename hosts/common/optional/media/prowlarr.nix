{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Prowlarr - Indexer manager for all Servarr tools
  #
  # Persistence: dataDir is on /nix/storage (separate LUKS disk). The NixOS module
  # bind-mounts it to /var/lib/private/prowlarr. That bind must run *after* the
  # storage disk is mounted, or the source path is missing and data doesn't persist.

  # Firewall configuration
  networking.firewall.interfaces."enp6s0".allowedTCPPorts = [ 9696 ];

  # Native Prowlarr service
  services.prowlarr = {
    enable = true;
    openFirewall = true;
    dataDir = "/nix/storage/servarr/prowlarr"; # Persistent Prowlarr config
  };

  # Ensure media group exists
  users.groups.media = { };

  # Override systemd service to run as diego:media instead of DynamicUser
  # The Prowlarr NixOS module doesn't expose user/group options like Sonarr/Radarr do,
  # so we override the service config directly to match directory ownership (diego:media with 0750)
  systemd.services.prowlarr = lib.mkIf config.services.prowlarr.enable {
    after = [ "nix-storage.mount" ];
    requires = [ "nix-storage.mount" ];
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "diego";
      Group = "media";
      # Override ExecStart to use our dataDir directly (module hardcodes /var/lib/prowlarr)
      ExecStart = lib.mkForce "${pkgs.prowlarr}/bin/Prowlarr -nobrowser -data=${config.services.prowlarr.dataDir}";
      # Clear StateDirectory so systemd doesn't manage /var/lib/prowlarr
      StateDirectory = lib.mkForce "";
      StateDirectoryMode = lib.mkForce "";
    };
  };

  # Fix /var/lib/private permissions for systemd DynamicUser services
  # Without this, services fail to start with "mode 0755 is too permissive (0700 was requested)"
  systemd.tmpfiles.rules = [
    "d /var/lib/private 0700 root root -"
  ];
}
