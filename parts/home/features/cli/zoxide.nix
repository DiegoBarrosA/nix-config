{ ... }:
{
  flake.modules.homeManager.cli-zoxide =
{
  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
    options = [ "--cmd cd" ];
  };

}
;
}
