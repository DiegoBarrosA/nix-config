{ ... }:
{
  flake.modules.nixos.desktop-desktop-common = { ... }:
{

  services.gnome.gnome-keyring.enable = true;
};
}
