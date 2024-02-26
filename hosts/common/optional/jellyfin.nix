{ config, pkgs, ... }:

{
  services.jellyfin = {
    enable = true;
    user = "diego";
    openFirewall = true;

  };
}
