{ pkgs, ... }:
let
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;
    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };
in {
  imports = [
    ./alacritty.nix
    ./mako.nix
    ./zathura.nix
    ./tofi.nix
    ./waybar.nix
    ./cava.nix
    ./transmission-remote.nix
    ./wlsunset.nix
    ./imv.nix
    ./swaylock.nix
    ../.

  ];
  home.packages = with pkgs; [
    dbus-sway-environment
    helvum
    vscodium
    ario
    autotiling
    capitaine-cursors
    clipman
    glib
    grim
    gtk-engine-murrine
    kanshi
    gparted
    mpv
    ani-cli
    papirus-icon-theme
    pavucontrol
    pcmanfm
    libgsf
    ffmpegthumbnailer
    polkit
    polkit_gnome
    slurp
    swayidle
    wl-clipboard
    wlsunset
    xarchiver
    xdg-utils
    gcolor3
    zathura
libappindicator
    android-studio
    libnotify
  ];
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    LIBSEAT_BACKEND = "logind";
    CLUTTER_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";
    QT_QPA_PLATFORM = "wayland";
    BROWSER = "firefox";
    NO_AT_BRIDGE = 1;
    _JAVA_AWT_WM_NONREPARENTING = 1;
    ECORE_EVAS_ENGINE = "wayland_egl";
    ELM_ENGINE = "wayland_egl";
    XDG_SESSION_DESKTOP = "sway";
  };
}
