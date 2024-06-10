{ pkgs, lib, outputs, config, ... }: {
  imports = [
    ./firefox
    ./font.nix
    ./gtk.nix
    ./qt.nix
    ./keepassxc.nix
    ./signal.nix
    ./kdeconnect.nix
    ./libreoffice.nix
    ./gimp.nix
    ./playerctl.nix
    ./flameshot.nix
    ./mime.nix
    ./mpv.nix
    ./obs.nix
  ];
  xdg.enable = true;
  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;
  home.packages = with pkgs; [ bitwarden solaar ];
}
