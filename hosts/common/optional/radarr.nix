{ config, lib, pkgs, ... }:

{
  # Radarr - Movie manager
  
  # Firewall configuration
  networking.firewall.interfaces."enp6s0".allowedTCPPorts = [ 7878 ];
  
  # Native Radarr service
  services.radarr = {
    enable = true;
    openFirewall = true;
    user = "diego";
    group = "media";
  dataDir = "/nix/storage/servarr/radarr"; # Persistent Radarr config
  };
  
  # Ensure media group exists
  users.groups.media = {};
}