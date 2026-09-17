{ config, lib, pkgs, ... }:

{
  services.bazarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
  };
}