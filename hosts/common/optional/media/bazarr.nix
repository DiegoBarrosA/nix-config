{ config, lib, pkgs, ... }:

{
  # Bazarr - Subtitle management
  
  # Firewall configuration
  networking.firewall.interfaces."enp6s0".allowedTCPPorts = [ 6767 ];
  
  # Native Bazarr service
  services.bazarr = {
    enable = true;
    openFirewall = true;
  };
}