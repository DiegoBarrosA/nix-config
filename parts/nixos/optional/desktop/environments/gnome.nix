{ ... }:
{
  # Bare-minimum GNOME on GDM: shell, Nautilus and Papers (PDF) only.
  flake.modules.nixos.desktop-environments-gnome =
    { pkgs, ... }:
    {
      services.desktopManager.gnome.enable = true;
      services.displayManager.gdm.enable = true;

      # Remap Caps Lock to Ctrl
      services.xserver.xkb.options = "ctrl:nocaps";

      environment.systemPackages = with pkgs; [
        nautilus
        papers
      ];

      # Drop the default GNOME app set and the welcome tour.
      services.gnome.core-apps.enable = false;
      environment.gnome.excludePackages = [ pkgs.gnome-tour ];
    };
}
