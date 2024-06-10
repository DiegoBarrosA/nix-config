{ pkgs, ... }: {
  imports = [
    ../alacritty.nix
    ./wpaperd.nix
    ./mako.nix
    ./zathura.nix
    ./tofi.nix
    ./waybar.nix
    ./cava.nix
    ./transmission-remote.nix
    ./gammastep.nix
    ./imv.nix
    ./xdg.nix
    # ./swaylock.nix
    # ./swayidle.nix
    ./kanshi.nix
    ../.
  ];
  home.packages = with pkgs; [
    waynergy
    helvum
    android-studio
    solaar
    scrcpy
    swaybg
    vscodium
    ario
    autotiling
    capitaine-cursors
    glib
    grim
    gtk-engine-murrine
    kanshi
    ani-cli
    papirus-icon-theme
    pavucontrol
    pcmanfm
    libgsf
    ffmpegthumbnailer
    polkit
    clipman
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
    libnotify
    swayimg
  ];
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    LIBSEAT_BACKEND = "logind";
    CLUTTER_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    BROWSER = "firefox";
    NO_AT_BRIDGE = 1;
    _JAVA_AWT_WM_NONREPARENTING = 1;
    ECORE_EVAS_ENGINE = "wayland_egl";
    ELM_ENGINE = "wayland_egl";
    XDG_SESSION_DESKTOP = "sway";
  };
}
