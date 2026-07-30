{ config, ... }:
let
  inherit (config.colorscheme) colors;
in
{
  xdg.configFile."fsel/config.toml".text = ''
    highlight_color = "#${colors.base0D}"
    cursor = "█"
    terminal_launcher = "alacritty -e"
    pin_color = "rgb(255,165,0)"
    pin_icon = " "

    [app_launcher]
    filter_desktop = true
    filter_actions = false
    match_mode = "fuzzy"
    ranking_mode = "frecency"

    [dmenu]
    match_mode = "fuzzy"
  '';
}
