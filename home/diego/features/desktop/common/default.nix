{
  pkgs,
  lib,
  outputs,
  config,
  desktop ? null,
  ...
}:
{
  imports = [
    ./chromium
    ./firefox
    ./thunderbird
    ./font.nix
    ./stylix.nix              # Unified theming (GTK, GNOME, cursor, fonts, apps)
    ./qt.nix
    ./playerctl.nix
    ./mime.nix
    ./syncthing.nix
    ./pavucontrol.nix
    ./localsend.nix
    ./alacritty.nix
    ./obs-studio.nix
    ./mpv.nix
    ./swayimg.nix
  ];
  xdg.enable = true;
  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  home.packages = with pkgs; [
    deploy-rs
    onlyoffice-desktopeditors
  ];

  # Also sets org.freedesktop.appearance color-scheme
  # Derived from colorscheme.mode so it follows light/dark specialisations
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = lib.mkDefault (
      if config.colorscheme.mode == "light" then "prefer-light" else "prefer-dark"
    );
    # cursor-size is set by Stylix's GTK module
  }
  # Sway only: apply the Stylix (Bibata) cursor. GNOME/KDE keep their native
  # cursor, so don't reference config.stylix.cursor (which is unset there).
  // lib.optionalAttrs (desktop == "sway") {
    cursor-theme = config.stylix.cursor.name;
  };

}
