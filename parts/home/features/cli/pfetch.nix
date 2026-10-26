{ ... }:
{
  flake.modules.homeManager.cli-pfetch =
{ pkgs, ... }: {
  home = {
    packages = with pkgs; [ pfetch ];
    sessionVariables.PF_INFO =
      "ascii title os kernel uptime shell term desktop scheme palette";
  };
}
;
}
