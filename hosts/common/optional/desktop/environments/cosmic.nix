# COSMIC desktop — system layer. Barebones: compositor + greeter + xwayland,
# with default apps stripped. Per-user apps live in the matching home module
# (home/diego/features/desktop/cosmic).
{ pkgs, ... }:
{
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # Xwayland for apps that don't yet support native Wayland
  services.desktopManager.cosmic.xwayland.enable = true;

  # xdg-desktop-portal-cosmic is wired automatically by the COSMIC module.

  # Strip COSMIC's default app set — TUI-first, apps come from common/.
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-edit   # text editor  (use helix)
    cosmic-music  # music player (use mpv)
    cosmic-reader # document reader (use zathura)
  ];
}
