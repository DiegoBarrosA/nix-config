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

    # Segmented bar: render each widget as its own rounded "island" instead of
    # one continuous bar background. We must supply the full default bar object
    # because barConfigs is an array (it replaces rather than deep-merges).
    settings.barConfigs = [
      {
        id = "default";
        name = "Main Bar";
        enabled = true;
        position = 0;
        screenPreferences = [ "all" ];
        showOnLastDisplay = true;
        leftWidgets = [
          "launcherButton"
          "workspaceSwitcher"
          "focusedWindow"
        ];
        centerWidgets = [
          "music"
          "clock"
          "weather"
        ];
        rightWidgets = [
          "systemTray"
          "clipboard"
          "cpuUsage"
          "memUsage"
          "notificationButton"
          "battery"
          "controlCenterButton"
        ];
        spacing = 4;
        innerPadding = 4;
        bottomGap = 0;
        transparency = 1.0;
        widgetTransparency = 1.0;
        squareCorners = false; # rounded segments
        noBackground = true; # ← segmented: per-widget islands, no bar slab
        maximizeWidgetIcons = false;
        maximizeWidgetText = false;
        removeWidgetPadding = false;
        widgetPadding = 8;
        gothCornersEnabled = false;
        gothCornerRadiusOverride = false;
        gothCornerRadiusValue = 12;
        borderEnabled = false;
        borderColor = "surfaceText";
        borderOpacity = 1.0;
        borderThickness = 1;
        widgetOutlineEnabled = false;
        widgetOutlineColor = "primary";
        widgetOutlineOpacity = 1.0;
        widgetOutlineThickness = 1;
        fontScale = 1.0;
        iconScale = 1.0;
        autoHide = false;
        autoHideDelay = 250;
        showOnWindowsOpen = false;
        openOnOverview = false;
        visible = true;
        popupGapsAuto = true;
        popupGapsManual = 4;
        maximizeDetection = true;
        scrollEnabled = true;
        scrollXBehavior = "column";
        scrollYBehavior = "workspace";
        shadowIntensity = 0;
        shadowOpacity = 60;
        shadowColorMode = "text";
        shadowCustomColor = "#000000";
        clickThrough = false;
      }
    ];
  };

  # Theming: the Stylix DankMaterialShell target generates the Material theme
  # from our base16 colorscheme and sets settings.currentThemeName/customThemeFile
  # automatically — so we deliberately do NOT set a custom theme here.
}

