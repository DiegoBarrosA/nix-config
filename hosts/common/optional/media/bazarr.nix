{ config, lib, pkgs, ... }:

{

  networking.firewall.interfaces."enp6s0".allowedTCPPorts = [ 6767 ];

  services.bazarr = {
    enable = true;
    openFirewall = true;
  };
}