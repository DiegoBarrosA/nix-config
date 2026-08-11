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
  # Enable Stylix for unified theming
  stylix = {
    enable = true;

    # Use colorscheme from nix-colors
    # Stylix uses base16 scheme format which matches nix-colors
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

    # Cursor theme - Bibata Modern Classic (dark).
    # Sway/COSMIC only: a null desktop keeps no cursor override.
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

    # Fonts configuration
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.fantasque-sans-mono;
        name = "FantasqueSansM Nerd Font";
      };
      sansSerif = {
        package = pkgs.ibm-plex;
        name = "IBM Plex Sans";
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
        terminal = 15;
      };
    };

    # Opacity settings
    opacity = {
      terminal = 1.0;
      popups = 1.0;
    };

    # Polarity (dark/light)
    polarity = config.colorscheme.mode;

    # Target-specific settings
    targets = {
      # GTK app theming: enabled on all supported DEs (Sway/COSMIC).
      gtk.enable = true;

      # Qt theming via Kvantum (generated from base16 colors).
      qt = {
        # Use xdg-desktop-portal for native file dialogs
        standardDialogs = "xdgdesktopportal";
      };

      # Don't let Stylix manage these since we handle them separately
      alacritty.enable = false;
      mako.enable = false;
      swaylock.enable = false;
      bat.enable = true;
      helix.enable = true;
      # Zellij themed manually (features/cli/zellij.nix) due to tab-bar
      # green-fallback bug with Stylix's structured theme format
      zellij.enable = false;

      # App targets
      yazi.enable = true;
      mpv.enable = true;
      zathura.enable = true;
    };

    # useGlobalPkgs = true means HM nixpkgs.overlays is unusable; the NixOS
    # Stylix module isn't enabled here so there's no system-level fallback —
    # disable to silence the HM evaluation warning.
    overlays.enable = false;
  };

  home.pointerCursor.enable = lib.mkIf (builtins.elem desktop [
    "sway"
    "cosmic"
  ]) true;

  # Icon theme (Stylix doesn't handle icons)
  # Use Papirus with custom folder color matching our accent (base0D).
  # Sway/COSMIC only: a null desktop keeps no icon override.
  gtk.iconTheme =
    lib.mkIf
      (builtins.elem desktop [
        "sway"
        "cosmic"
      ])
      (
        let
          # Papirus folder colour, paired with the scheme in colors.nix.
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

  # Symlink icon themes for GTK/Snap/sandboxed apps. Sway/COSMIC only;
  # a null desktop ships no desktop icons.
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

  # Propagate GTK theme to apps via XSettings. Needed on Sway/Wayland
  # (COSMIC has its own settings daemon; this references the Sway-only iconTheme).
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
