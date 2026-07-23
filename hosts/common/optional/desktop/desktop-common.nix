# System-level bits shared by every graphical desktop environment.
# Imported by select.nix whenever a `desktop` is selected. Contains NO
# display manager (each environment owns its native DM).
{ ... }:
{
  # Secret store used across all DEs (unlocked via PAM at login).
  services.gnome.gnome-keyring.enable = true;
}
