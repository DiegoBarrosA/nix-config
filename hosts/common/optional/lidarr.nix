{ config, lib, pkgs, ... }:

{
  # Lidarr - Music manager
  
  # Firewall configuration
  networking.firewall.interfaces."enp6s0".allowedTCPPorts = [ 8686 ];
  
  # Native Lidarr service
  services.lidarr = {
    enable = true;
    openFirewall = true;
    user = "diego";
    group = "media";
  dataDir = "/nix/storage/servarr/lidarr"; # Persistent Lidarr config
  };
  
  # Ensure media group exists
  users.groups.media = {};
}