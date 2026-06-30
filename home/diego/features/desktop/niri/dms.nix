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
      enableKeybinds = true; # merges DMS IPC binds (launcher, notifications,
      # clipboard, powermenu, lock, volume, brightness…) into our niri config
      enableSpawn = true; # spawns `dms run` at niri startup
      # No `includes`: keep our Nix-managed niri config authoritative (our
      # stylix colors, layout, and curated binds). The DMS shell itself runs
      # via enableSpawn and is independent of niri config includes. This also
      # avoids the imperative `dms setup` step the includes mechanism needs.
      includes.enable = false;
    };
  };

  # Theming: the Stylix DankMaterialShell target generates the Material theme
  # from our base16 colorscheme and sets settings.currentThemeName/customThemeFile
  # automatically — so we deliberately do NOT set a custom theme here.
}

