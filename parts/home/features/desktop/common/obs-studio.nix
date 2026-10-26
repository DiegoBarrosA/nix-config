{ ... }:
{
  flake.modules.homeManager.desktop-common-obs-studio =
{ pkgs, ... }: {
  home.packages = with pkgs; [ obs-studio ];
};
}
