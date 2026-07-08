# KDE Plasma 6 desktop — system layer. Barebones: Plasma + systemsettings +
# SDDM + kde portal, with default apps stripped. Per-user apps live in the
# matching home module (home/diego/features/desktop/kde).
{ pkgs, ... }:
{
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # xdg-desktop-portal-kde is wired automatically by the Plasma module.

  # Strip Plasma's default app set — TUI-first, apps come from common/.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    konsole
    ark
    khelpcenter
    elisa
    okular
    plasma-browser-integration
    kate
  ];
}
