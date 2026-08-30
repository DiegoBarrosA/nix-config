{
  config,
  pkgs,
  lib,
  desktop ? null,
  ...
}:
let
  inherit (config.colorscheme) colors;
in
{

  stylix = {
    enable = true;

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

    cursor =
      lib.mkIf
        (builtins.elem desktop [
          "sway"
          "cosmic"
        ])
        {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 28;
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

    opacity = {
      terminal = 1.0;
      popups = 1.0;
    };

    polarity = config.colorscheme.mode;

    targets = {

      gtk.enable = true;

      qt = {

        standardDialogs = "xdgdesktopportal";
      };

      alacritty.enable = false;
      mako.enable = false;
      swaylock.enable = false;

      waybar.enable = false;
      bat.enable = true;
      helix.enable = true;

      zellij.enable = false;

      yazi.enable = true;
      mpv.enable = true;
      zathura.enable = true;
    };

    overlays.enable = false;
  };

  home.pointerCursor.enable = lib.mkIf (builtins.elem desktop [
    "sway"
    "cosmic"
  ]) true;

  gtk.iconTheme =
    lib.mkIf
      (builtins.elem desktop [
        "sway"
        "cosmic"
      ])
      (
        let

          folderColor = config.colorscheme.iconFolderColor;
          papirusWithFolders = pkgs.papirus-icon-theme.override {
            color = folderColor;
          };
        in
        {
          name = if config.colorscheme.mode == "light" then "Papirus-Light" else "Papirus-Dark";
          package = papirusWithFolders;
        }
      );

  xdg.dataFile =
    lib.mkIf
      (builtins.elem desktop [
        "sway"
        "cosmic"
      ])
      (
        let
          folderColor = config.colorscheme.iconFolderColor;
          papirusWithFolders = pkgs.papirus-icon-theme.override {
            color = folderColor;
          };
        in
        {
          "icons/Papirus".source = "${papirusWithFolders}/share/icons/Papirus";
          "icons/Papirus-Dark".source = "${papirusWithFolders}/share/icons/Papirus-Dark";
          "icons/Papirus-Light".source = "${papirusWithFolders}/share/icons/Papirus-Light";
        }
      );

  services.xsettingsd =
    lib.mkIf
      (builtins.elem desktop [
        "sway"
        "cosmic"
      ])
      {
        enable = true;
        settings = {
          "Net/ThemeName" = "${config.gtk.theme.name}";
          "Net/IconThemeName" = "${config.gtk.iconTheme.name}";
        };
      };
}
