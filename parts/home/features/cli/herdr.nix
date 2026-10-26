{ ... }:
{
  flake.modules.homeManager.cli-herdr =
{ config, ... }:
let
  inherit (config.colorscheme) colors;
in
{
  xdg.configFile."herdr/config.toml".text = ''
    [theme]
    name = "terminal"

    [theme.custom]
    panel_bg = "#${colors.base00}"
    sidebar_bg = "#${colors.base01}"
    active_row_bg = "#${colors.base02}"
    selection_bg = "#${colors.base02}"
    surface0 = "#${colors.base01}"
    surface1 = "#${colors.base02}"
    surface_dim = "#${colors.base00}"
    overlay0 = "#${colors.base03}"
    overlay1 = "#${colors.base04}"
    text = "#${colors.base05}"
    subtext0 = "#${colors.base04}"
    accent = "#${colors.base0D}"
    mauve = "#${colors.base0E}"
    green = "#${colors.base0B}"
    yellow = "#${colors.base0A}"
    red = "#${colors.base08}"
    blue = "#${colors.base0D}"
    teal = "#${colors.base0C}"
    peach = "#${colors.base09}"
  '';
}
;
}
