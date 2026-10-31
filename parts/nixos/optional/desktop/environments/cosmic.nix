{ ... }:
{
  flake.modules.nixos.desktop-environments-cosmic = { pkgs, ... }:
{
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  services.desktopManager.cosmic.xwayland.enable = true;

  environment.cosmic.excludePackages = with pkgs; [
    cosmic-edit
    cosmic-player
    cosmic-reader
    cosmic-store
  ];
};
}
