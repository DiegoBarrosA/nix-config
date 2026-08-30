{ config, lib, pkgs, ... }:

{

  networking.firewall.interfaces."enp6s0".allowedTCPPorts = [ 8989 ];

  services.sonarr = {
    enable = true;
    openFirewall = true;
    user = "diego";
    group = "media";
  dataDir = "/nix/storage/servarr/sonarr";
  };

  users.groups.media = {};
}