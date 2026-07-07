{ config, lib, pkgs, ... }:

{
  # Sonarr - TV Show manager
  
  # Firewall configuration
  networking.firewall.interfaces."enp6s0".allowedTCPPorts = [ 8989 ];
  
  # Native Sonarr service
  services.sonarr = {
    enable = true;
    openFirewall = true;
    user = "diego";
    group = "media";
  dataDir = "/nix/storage/servarr/sonarr"; # Persistent Sonarr config
  };
  
  # Ensure media group exists
  users.groups.media = {};
}