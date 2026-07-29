{ config, ... }:
let
  inherit (config.colorscheme) colors;
in
{
  xdg.configFile."tofi/config".text = ''
    font = Jost
    font-size = 14

    anchor = center
    width = 480
    num-results = 8
    result-spacing = 4
    padding-top = 12
    padding-bottom = 12
    padding-left = 16
    padding-right = 16
    corner-radius = 8

    background-color = #${colors.base01}ff
    text-color       = #${colors.base05}
    prompt-color     = #${colors.base0D}
    selection-color      = #${colors.base0D}
    selection-text-color = #${colors.base00}
    outline-color    = #${colors.base0D}
    outline-width    = 2
    border-width     = 0

    fuzzy-match = true
    prompt-text = "  "
    history = true
  '';
}
