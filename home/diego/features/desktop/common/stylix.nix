{
  config,
  pkgs,
  lib,
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
      base0D = colors.base04;
      base0E = colors.base0E;
      base0F = colors.base0F;
    };

    # Cursor theme - Bibata themed to Stylix scheme
    cursor = {
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
      gtk = {
        enable = true;
      };

      # GNOME integration - let Stylix set Adwaita-compatible colors
      gnome.enable = true;

      # Keep Qt using GTK theme (Stylix GNOME target sets this to "gnome")
      qt.enable = false;

      # Don't let Stylix manage these since we handle them separately
      alacritty.enable = false;
      waybar.enable = false;
      mako.enable = false;
      swaylock.enable = false;
      fuzzel.enable = false;
      bat.enable = false;
      helix.enable = true;

      # App targets
      yazi.enable = true;
      mpv.enable = true;
      zathura.enable = true;
    };
  };

  # Icon theme (Stylix doesn't handle icons)
  # Use Papirus with custom folder color matching our accent (base0D)
  gtk.iconTheme =
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
    };

  # Symlink icon themes to ~/.local/share/icons for GTK apps installed via apt
  xdg.dataFile =
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
    };

  # Also symlink to ~/.icons for older apps and Snap compatibility
  home.file.".icons/Bibata-Stylix".source = "${bibataStylix}/share/icons/Bibata-Stylix";

  # Propagate GTK theme to apps via XSettings (needed on Sway/Wayland)
  services.xsettingsd = {
    enable = true;
    settings = {
      "Net/ThemeName" = "${config.gtk.theme.name}";
      "Net/IconThemeName" = "${config.gtk.iconTheme.name}";
    };
  };
}
