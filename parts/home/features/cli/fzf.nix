{ ... }:
{
  flake.modules.homeManager.cli-fzf =
{
  programs.fzf = {
    enable = true;
    defaultOptions = [ "--color 16" ];
  };
}
;
}
