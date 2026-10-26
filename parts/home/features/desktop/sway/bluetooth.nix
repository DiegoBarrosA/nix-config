{ ... }:
{
  flake.modules.homeManager.desktop-sway-bluetooth =
{
  pkgs,
  ...
}:
{

  home.packages = with pkgs; [
    bluetuith
  ];
};
}
