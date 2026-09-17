{
  config,
  pkgs,
  ...
}:
let
  inherit (config.colorscheme) colors;
in
{

  home.packages = [ pkgs.font-awesome ];
  stylix = {
    enable = true;

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 28;
    };

    base16Scheme = {
      base00 = colors.base00;
      base01 = colors.base01;
      base02 = colors.base02;
      base03 = colors.base03;
      base04 = colors.base04;
      base05 = colors.base05;
      base06 = colors.base06;
      base07 = colors.base07;
      base08 = colors.base08;
      base09 = colors.base09;
      base0A = colors.base0A;
      base0B = colors.base0B;
      base0C = colors.base0C;
      base0D = colors.base0D;
      base0E = colors.base0E;
      base0F = colors.base0F;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.fantasque-sans-mono;
        name = "FantasqueSansM Nerd Font";
      };
      sansSerif = {
        package = pkgs.jost;
        name = "Jost*";
      };
      serif = {
        package = pkgs.ibm-plex;
        name = "IBM Plex Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-monochrome-emoji;
        name = "Noto Emoji";
      };
      sizes = {
        applications = 15;
        desktop = 15;
        popups = 15;
        terminal = 20;
      };
    };

    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };

    opacity.terminal = 1.0;

    polarity = config.colorscheme.mode;

    targets = {
      gtk.enable = true;
      qt.enable = true;
      alacritty.enable = false;
      mako.enable = false;
      swaylock.enable = false;
      bat.enable = false;
      # helix.enable = false;
      zellij.enable = false;
      yazi.enable = false;
      mpv.enable = false;
      zathura.enable = false;
    };

    overlays.enable = false;
  };
}
