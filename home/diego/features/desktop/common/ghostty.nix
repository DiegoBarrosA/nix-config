{ config, pkgs, lib, ... }:
let
  inherit (config.colorscheme) colors;
  inherit (config) fontProfiles;
in
{
  home.sessionVariables = {
    TERMINAL = "ghostty";
  };

  home.packages = [ pkgs.ghostty ];

  xdg.configFile."ghostty/config".text = ''
    font-family = ${fontProfiles.monospace.family}
    font-size = 12

    shell = ${pkgs.nushell}/bin/nu
    shell-integration = fish
    shell-integration-features = cursor,sudo,title

    window-decoration = true
    window-padding-x = 8
    window-padding-y = 8

    copy-on-select = true
    confirm-close-surface = false

    gtk-single-instance = true

    background = #${colors.base00}
    foreground = #${colors.base05}

    palette = 0=#${colors.base00}
    palette = 1=#${colors.base08}
    palette = 2=#${colors.base0B}
    palette = 3=#${colors.base0A}
    palette = 4=#${colors.base0D}
    palette = 5=#${colors.base0E}
    palette = 6=#${colors.base0C}
    palette = 7=#${colors.base05}

    palette = 8=#${colors.base03}
    palette = 9=#${colors.base08}
    palette = 10=#${colors.base0B}
    palette = 11=#${colors.base0A}
    palette = 12=#${colors.base0D}
    palette = 13=#${colors.base0E}
    palette = 14=#${colors.base0C}
    palette = 15=#${colors.base07}

    cursor-color = #${colors.base05}
    cursor-text = #${colors.base00}

    selection-background = #${colors.base02}
    selection-foreground = #${colors.base05}
  '';
}
