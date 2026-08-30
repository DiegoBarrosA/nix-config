{ config, lib, pkgs, ... }:

{

  services.flaresolverr = {
    enable = true;
    port = 8191;
    openFirewall = true;
  };
}
