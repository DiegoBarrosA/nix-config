{ pkgs, lib, outputs, config, ... }: {
  imports = [
    ./firefox.nix
    ./thunderbird.nix
    ./font.nix
    ./gtk.nix
    ./qt.nix
    ./keepassxc.nix
    ./signal.nix
    ./kdeconnect.nix
    ./libreoffice.nix
    ./gimp.nix
    ./playerctl.nix
    ./discord.nix
    ./flameshot.nix
    ./mime.nix
  ];
  xdg.enable = true;
  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;
}
