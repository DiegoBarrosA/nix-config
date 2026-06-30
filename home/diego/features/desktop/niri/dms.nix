{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
  ];

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
  };

  # Theming: the Stylix DankMaterialShell target generates the Material theme
  # from our base16 colorscheme and sets settings.currentThemeName/customThemeFile
  # automatically — so we deliberately do NOT set a custom theme here.
}

