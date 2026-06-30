{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (config.colorscheme) colors;
  hex = c: "#${c}";

  # Map the active base16 scheme to DankMaterialShell's Material-You roles.
  # scheme-monochrome suits the near-monochrome black-metal-venom palette.
  theme = {
    name = config.colorscheme.type or "base16";
    matugen_type = "scheme-monochrome";

    background = hex colors.base00;
    backgroundText = hex colors.base05;

    surface = hex colors.base01;
    surfaceText = hex colors.base05;
    surfaceVariant = hex colors.base02;
    surfaceVariantText = hex colors.base04;
    surfaceContainer = hex colors.base02;
    surfaceContainerHigh = hex colors.base02;
    surfaceContainerHighest = hex colors.base03;
    surfaceTint = hex colors.base08;

    primary = hex colors.base08;
    primaryText = hex colors.base00;
    primaryContainer = hex colors.base08;

    secondary = hex colors.base0D;

    outline = hex colors.base03;

    error = hex colors.base0A;
    warning = hex colors.base09;
    info = hex colors.base08;
  };
in
{
  imports = [ inputs.dms.homeModules.dank-material-shell ];

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;

    # Feature toggles
    enableSystemMonitoring = true; # dgop CPU/RAM/GPU widgets
    enableVPN = true; # NetworkManager VPN widget
    enableDynamicTheming = false; # keep our base16 scheme (no Matugen)
    enableAudioWavelength = true; # cava visualizer
    enableCalendarEvents = true; # khal calendar integration
    enableClipboardPaste = true; # wtype paste from clipboard history

    # niri integration
    niri = {
      enableKeybinds = true;
      enableSpawn = true;
      includes = {
        enable = true;
        # Drop "outputs" and "wpblur": DMS must NOT manage wallpaper/outputs,
        # since awww/swaybg (see nasa-wallpaper.nix) own the wallpaper + overview blur.
        filesToInclude = [
          "binds"
          "colors"
          "layout"
          "alttab"
        ];
      };
    };

    # Select our generated custom theme.
    settings = {
      currentThemeName = "custom";
      customThemeFile = "${config.xdg.configHome}/DankMaterialShell/themes/base16-scheme.json";
    };
  };

  # Generated theme tracks config.colorscheme automatically.
  xdg.configFile."DankMaterialShell/themes/base16-scheme.json".text = builtins.toJSON theme;
}
