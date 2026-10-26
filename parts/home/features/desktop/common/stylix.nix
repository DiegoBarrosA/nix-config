{ ... }:
{
  flake.modules.homeManager.desktop-common-stylix =
{
  config,
  pkgs,
  lib,
  desktop ? null,
  ...
}:
let
  inherit (config.colorscheme) colors;
  isGnome = desktop == "gnome";
  isKde = desktop == "kde";
in
{

  home.packages = [ pkgs.font-awesome ];
  stylix = {
    enable = true;

    cursor = if isKde then {
      package = pkgs.kdePackages.breeze;
      name = "breeze_cursors";
      size = 24;
    } else if isGnome then {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 24;
    } else {
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
        package = pkgs.nerd-fonts.noto;
        name = "NotoSansM Nerd Font";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
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

    icons = if isKde then {
      enable = false;
    } else if isGnome then {
      enable = true;
      package = pkgs.adwaita-icon-theme;
      dark = "Adwaita";
      light = "Adwaita";
    } else {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };

    opacity.terminal = 1.0;

    polarity = config.colorscheme.mode;

    # GUI apps stay stock; only fonts and terminal/CLI tools are themed.
    autoEnable = false;
    targets = {
      font-packages.enable = true;
      fontconfig.enable = true;
      fuzzel.enable = true;
      gtk.enable = !(isGnome || isKde);
      qt.enable = !(isGnome || isKde);
      helix.enable = true;
      fzf.enable = true;
      btop.enable = true;
      lazygit.enable = true;
      starship.enable = true;
      tmux.enable = true;
      neovim.enable = true;
      nixvim.enable = true;
      nvf.enable = true;
      fish.enable = true;
      nushell.enable = true;
      k9s.enable = true;
      opencode.enable = true;
    };

    overlays.enable = false;
  };
};
}
