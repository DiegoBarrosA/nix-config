{ ... }:
{
  # Bare-minimum Plasma 6 on SDDM (Wayland): shell, Dolphin, Okular, Konsole and Fooyin only.
  flake.modules.nixos.desktop-environments-kde =
    { pkgs, ... }:
    {
      services.desktopManager.plasma6.enable = true;
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };

      environment.systemPackages = with pkgs; [
        kdePackages.okular
        kdePackages.konsole
        fooyin
      ];

      # Konsole is added back explicitly above; drop the other default apps.
      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        kate
        elisa
        khelpcenter
        plasma-browser-integration
        krdp
      ];
    };
}
