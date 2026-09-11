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
    ./stylix.nix
    ./playerctl.nix
    ./mime.nix
    ./syncthing.nix
    ./pavucontrol.nix
    ./alacritty.nix
    ./obs-studio.nix
    ./mpv.nix
    ./swayimg.nix
    ./udiskie.nix
    ./mobile-automount.nix
  ];
  xdg.enable = true;
  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  home.packages = with pkgs; [
    deploy-rs
    onlyoffice-desktopeditors
  ];

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = lib.mkDefault (
      if config.colorscheme.mode == "light" then "prefer-light" else "prefer-dark"
    );

  }

  // lib.optionalAttrs (desktop == "sway") {
    cursor-theme = config.stylix.cursor.name;
  };

}
