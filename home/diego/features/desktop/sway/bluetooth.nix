{
  pkgs,
  ...
}:
{
  # Overskride: a clean, WM-agnostic GTK4 Bluetooth (and Obex) client.
  # Launched on demand from the waybar bluetooth module (see waybar.nix,
  # module "bluetooth" -> on-click). The waybar module itself provides the
  # bar indicator/status; overskride is the full pairing/management UI.
  #
  # NOTE: the BlueZ stack (hardware.bluetooth) is enabled at the NixOS level
  # in hosts/rubi/default.nix. This module only adds the user-facing GUI.
  home.packages = with pkgs; [
    overskride
  ];
}
