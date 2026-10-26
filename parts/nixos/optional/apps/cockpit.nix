{ ... }:
{
  flake.modules.nixos.apps-cockpit =
{ config, ... }: {

  services.cockpit = {
    enable = true;
    openFirewall = true;

  };
}
  ;
}
