{
  pkgs,
  ...
}:
{
  # bluetuith: a TUI Bluetooth (and OBEX) manager. Launched on demand via
  # Mod4+Shift+u (see default.nix), opened in alacritty to match the audio
  # widget's `alacritty -e wiremix` pattern. Replaces the GTK overskride GUI
  # to keep tooling TUI-first.
  #
  # NOTE: the BlueZ stack (hardware.bluetooth) is enabled at the NixOS level
  # in hosts/rubi/default.nix. This module only adds the user-facing client.
  home.packages = with pkgs; [
    bluetuith
  ];
}
