{
  pkgs,
  ...
}:
{
  # bluetuith: a TUI Bluetooth (and OBEX) manager. Launched on demand from the
  # waybar bluetooth module (see waybar.nix, module "bluetooth" -> on-click),
  # opened in alacritty to match the audio widget's `alacritty -e wiremix`
  # pattern. The waybar module itself provides the bar indicator/status;
  # bluetuith is the full pairing/management UI. Replaces the GTK overskride
  # GUI to keep tooling TUI-first.
  #
  # NOTE: the BlueZ stack (hardware.bluetooth) is enabled at the NixOS level
  # in hosts/rubi/default.nix. This module only adds the user-facing client.
  home.packages = with pkgs; [
    bluetuith
  ];
}
