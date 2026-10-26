{ ... }:
{
  flake.modules.homeManager.cli-bat =
{
  programs.bat = {
    enable = true;

  };
}
;
}
