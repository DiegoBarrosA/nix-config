{ config, lib, pkgs, ... }:

{
  # Barebones app set: settings, file manager, image viewer, screen mgmt,
  # screenshot. Everything else comes from common/ + TUI tooling.
  home.packages = with pkgs.kdePackages; [
    systemsettings
    dolphin
    gwenview
    kscreen
    spectacle # screenshot (KDE-native)
  ];

  # Alacritty client-side decorations under KDE (title bar + window buttons).
  programs.alacritty.settings.window.decorations = "full";

  home.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "KDE";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
  };

  # Performance tuning for KWin / Plasma. Plasma 6 defaults enable GPU-heavy
  # effects (blur, background contrast) and medium-speed animations that make
  # the desktop feel sluggish, especially on integrated graphics. This trims
  # effects and biases the compositor toward responsiveness.
  #
  # NOTE: programs.plasma (plasma-manager) is only available on the KDE build
  # path, which is exactly where this module is imported — so it's safe here.
  programs.plasma = {
    enable = true;

    # Disable the most expensive compositor effect: translucency blur.
    kwin.effects.blur.enable = false;

    # Low-level KWin / global tweaks that plasma-manager doesn't expose as
    # typed options. Written straight into the relevant config files.
    configFile = {
      kwinrc = {
        # Bias the compositor toward input responsiveness over smoothness.
        # Valid values: ForceSmoothest, Smoothest, Balanced, Low,
        # ForceLowestLatency. "Low" is snappy without fully sacrificing vsync.
        "Compositing"."LatencyPolicy" = "Low";
        # Keep the GL backend (never fall back to software/XRender).
        "Compositing"."Backend" = "OpenGL";
        # Explicitly disable the heavy effects. blurEnabled mirrors the typed
        # option above; contrastEnabled (background contrast) has no typed
        # toggle in plasma-manager.
        "Plugins"."blurEnabled" = false;
        "Plugins"."contrastEnabled" = false;
      };
      # Speed up all Plasma/Qt animations. AnimationDurationFactor scales every
      # animation duration; 0.5 = twice as fast, 0 = instant (no animation).
      # 0.5 keeps a hint of motion while feeling immediate.
      kdeglobals."KDE"."AnimationDurationFactor" = 0.5;
    };
  };
}
