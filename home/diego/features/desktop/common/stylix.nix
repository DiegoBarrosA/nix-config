{
  config,
  pkgs,
  lib,
  desktop ? null,
  ...
}:
let
  inherit (config.colorscheme) colors;

  bibataStylix = pkgs.stdenvNoCC.mkDerivation {
    pname = "bibata-cursors-stylix";
    version = "2.0.7";
    buildInputs = [ pkgs.bibata-cursors ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/icons/Bibata-Stylix
      cp -r ${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Classic/* $out/share/icons/Bibata-Stylix/
      substituteInPlace $out/share/icons/Bibata-Stylix/index.theme \
        --replace "Bibata-Modern-Classic" "Bibata-Stylix"
    '';
    meta = {
      description = "Bibata cursor (Modern-Classic variant) for Stylix";
      homepage = "https://github.com/ful1e5/Bibata_Cursor";
      license = pkgs.lib.licenses.gpl3Only;
      platforms = pkgs.lib.platforms.linux;
    };
  };
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

    # Cursor theme - Bibata themed to Stylix scheme.
    # Sway only: GNOME/KDE keep their native cursor (Adwaita/Breeze).
    cursor = lib.mkIf (desktop == "sway") {
      package = bibataStylix;
      name = "Bibata-Stylix";
      size = 28;
    };

    # Fonts configuration
    fonts = {
      monospace = {
        package = pkgs.fantasque-sans-mono;
        name = "Fantasque Sans Mono";
      };
      sansSerif = {
        package = pkgs.jost;
        name = "Jost";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      emoji = {
        package = pkgs.twitter-color-emoji;
        name = "Twitter Color Emoji";
      };
      sizes = {
        applications = 11;
        desktop = 11;
        popups = 11;
        terminal = 12;
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
      # GTK app theming: enabled on Sway/KDE; disabled on GNOME so GTK apps
      # use native Adwaita (per "GNOME native only" — no Stylix gtk/shell).
      gtk = {
        enable = desktop != "gnome";
      };

      # GNOME Shell integration: disabled on GNOME so the shell stays native.
      # (Has effect only under a GNOME session anyway.)
      gnome.enable = desktop != "gnome";

      # Qt theming via Kvantum (generated from base16 colors)
      qt = {
        enable = true;
        # Use xdg-desktop-portal for native file dialogs
        standardDialogs = "xdgdesktopportal";
      };

      # Don't let Stylix manage these since we handle them separately
      alacritty.enable = false;
      waybar.enable = false;
      mako.enable = false;
      swaylock.enable = false;
      fuzzel.enable = false;
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
  };

  home.pointerCursor.enable = lib.mkIf (desktop == "sway") true;

  # Icon theme (Stylix doesn't handle icons)
  # Use Papirus with custom folder color matching our accent (base0D).
  # Sway only: GNOME/KDE keep their native icons (Adwaita/Breeze).
  gtk.iconTheme = lib.mkIf (desktop == "sway") (
    let
      # Map our accent color to closest Papirus folder color
      # base0D = #82aaff (blue) -> "blue" or "indigo"
      # You can change this to: blue, indigo, cyan, teal, violet, etc.
      folderColor = "indigo";
      papirusWithFolders = pkgs.papirus-icon-theme.override {
        color = folderColor;
      };
    in
    {
      name = "Papirus-Dark";
      package = papirusWithFolders;
    }
  );

  # Symlink icon + cursor themes for GTK/Snap/sandboxed apps. Sway only;
  # GNOME/KDE ship their own icon/cursor sets.
  xdg.dataFile = lib.mkIf (desktop == "sway") (
    let
      folderColor = "indigo";
      papirusWithFolders = pkgs.papirus-icon-theme.override {
        color = folderColor;
      };
    in
    {
      "icons/Papirus".source = "${papirusWithFolders}/share/icons/Papirus";
      "icons/Papirus-Dark".source = "${papirusWithFolders}/share/icons/Papirus-Dark";
      "icons/Papirus-Light".source = "${papirusWithFolders}/share/icons/Papirus-Light";
      # Cursor theme for Snap apps and other sandboxed applications
      "icons/Bibata-Stylix".source = "${bibataStylix}/share/icons/Bibata-Stylix";
    }
  );

  # Also symlink to ~/.icons for older apps and Snap compatibility (Sway only)
  home.file.".icons/Bibata-Stylix" = lib.mkIf (desktop == "sway") {
    source = "${bibataStylix}/share/icons/Bibata-Stylix";
  };

  # Propagate GTK theme to apps via XSettings. Needed on Sway/Wayland (GNOME/KDE
  # run their own settings daemon, and this references the Sway-only iconTheme).
  services.xsettingsd = lib.mkIf (desktop == "sway") {
    enable = true;
    settings = {
      "Net/ThemeName" = "${config.gtk.theme.name}";
      "Net/IconThemeName" = "${config.gtk.iconTheme.name}";
    };
  };
}
