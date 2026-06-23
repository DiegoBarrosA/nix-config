{ config, lib, pkgs, ... }:

{
  imports = [
    ./extensions.nix
    ./dconf.nix
  ];

  home.packages = with pkgs; [
    gnome-tweaks
    gnome-extension-manager
    dconf-editor

    nautilus
    gnome-calculator
    gnome-system-monitor
    gnome-disk-utility
    eog
    gnome-text-editor
    gnome-screenshot
  ];

  home.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "GNOME";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
  };
}
