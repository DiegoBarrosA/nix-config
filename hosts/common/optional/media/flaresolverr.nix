{ config, lib, pkgs, ... }:

{
  # FlareSolverr - Cloudflare bypass proxy server
  # Used by Prowlarr/Jackett to bypass Cloudflare protection
  # https://github.com/FlareSolverr/FlareSolverr
  
  services.flaresolverr = {
    enable = true;
    port = 8191;
    openFirewall = true;
  };
}
