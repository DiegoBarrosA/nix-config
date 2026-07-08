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
}
