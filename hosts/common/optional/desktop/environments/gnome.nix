# GNOME desktop — system layer. Barebones: shell + control-center + GDM +
# gnome portal, with default apps stripped. Per-user apps live in the
# matching home module (home/diego/features/desktop/gnome).
{ pkgs, ... }:
{
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # xdg-desktop-portal-gnome is wired automatically by the GNOME module.

  # Strip GNOME's default app set — TUI-first, apps come from common/.
  environment.gnome.excludePackages = with pkgs; [
    gnome-console
    epiphany
    geary
    gnome-tour
    gnome-music
    gnome-maps
    gnome-weather
    gnome-contacts
    totem
    cheese
    simple-scan
    yelp
    gnome-text-editor
    gnome-calculator
    snapshot
    gnome-connections
    gnome-system-monitor
  ];
}
