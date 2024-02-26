{ config, pkgs, inputs, ... }:
let
  inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
in rec {
  gtk = {
    enable = true;
    font = {
      name = config.fontProfiles.regular.family;
      size = 13;
    };
    theme = {
      name = "${config.colorscheme.slug}";
      package = gtkThemeFromScheme { scheme = config.colorscheme; };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
      size = 32;
    };
  };

  services.xsettingsd = {
    enable = true;
    settings = {
      "Net/ThemeName" = "${gtk.theme.name}";
      "Net/IconThemeName" = "${gtk.iconTheme.name}";
    };
  };
}
