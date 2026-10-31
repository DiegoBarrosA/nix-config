{ ... }:
{
  flake.modules.homeManager.desktop-common-playerctl =
{ pkgs, ... }: {
  home.packages = with pkgs; [ playerctl lyrics ];
  services.playerctld = { enable = true; };
};
}
