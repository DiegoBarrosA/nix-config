{ ... }:
{
  flake.modules.homeManager.desktop-common-pavucontrol =
{ pkgs, ... }: {
  home.packages = with pkgs; [ wiremix ];
};
}
