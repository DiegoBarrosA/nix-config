{ config, lib, pkgs, ... }:

{
  imports = [
    ./extensions.nix
    ./dconf.nix
  ];

  # Barebones app set: settings, file manager, image viewer, disks, screenshot.
  # Everything else (browser, terminal, editor, media) comes from common/ + TUI.
  home.packages = with pkgs; [
    gnome-control-center
    nautilus
    loupe
    gnome-disk-utility
    gradia # screenshot annotate/share (GNOME-native)
  ];

  # Alacritty client-side decorations under GNOME (title bar + window buttons).
  programs.alacritty.settings.window.decorations = "full";

  home.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "GNOME";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
  };
}
