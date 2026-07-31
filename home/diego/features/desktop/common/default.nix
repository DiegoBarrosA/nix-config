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
    ./firefox
    ./thunderbird
    ./font.nix
    ./stylix.nix # Unified theming (GTK, Qt, cursor, fonts, apps)
    ./playerctl.nix
    ./mime.nix
    ./syncthing.nix
    ./pavucontrol.nix
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
  # Sway only: apply the Stylix (Bibata) cursor. COSMIC keeps its native cursor,
  # so don't reference config.stylix.cursor (which is unset there).
  // lib.optionalAttrs (desktop == "sway") {
    cursor-theme = config.stylix.cursor.name;
  };

}
