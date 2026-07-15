# Sway desktop — system layer. Moved out of hosts/rubi/default.nix so the DE
# can be swapped from flake.nix. Behavior is identical to the previous inline
# config: Sway, greetd/tuigreet, gnome-keyring PAM, swaylock PAM, and the
# wlr (screencast/screenshot) + gtk (fallback) portal split.
{ pkgs, ... }:
{
  # Enable Sway (provides system-level support: PAM, setuid wrappers, etc.)
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # GTK apps use correct theming

    # Export Qt env vars so apps launched from Sway keybindings get the Stylix theme
    extraSessionCommands = ''
      export QT_QPA_PLATFORMTHEME="qt5ct"
      export QT_STYLE_OVERRIDE="kvantum"
      export QT_PLUGIN_PATH="$HOME/.nix-profile/lib/qt-5.15.18/plugins:$HOME/.nix-profile/lib/qt-6/plugins"
      export QML2_IMPORT_PATH="$HOME/.nix-profile/lib/qt-5.15.18/qml:$HOME/.nix-profile/lib/qt-6/qml"
    '';
  };

  # greetd + tuigreet display manager (Sway's native TUI greeter)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions /run/current-system/sw/share/wayland-sessions";
        user = "greeter";
      };
    };
  };

  # PAM: unlock gnome-keyring via greetd, allow swaylock
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.swaylock = { };

  # Tell GTK apps and Electron/Chromium to use the XDG portal for file dialogs.
  # Without this, browsers try to spawn a native file chooser which fails on
  # pure Wayland (no X11 fallback), so "Upload file" clicks silently do nothing.
  environment.sessionVariables.GTK_USE_PORTAL = "1";

  # XDG Desktop Portals for wlroots/Sway
  xdg.portal = {
    enable = true;
    wlr = {
      enable = true;
      settings.screencast = {
        chooser_type = "dmenu";
        chooser_cmd = "${pkgs.fuzzel}/bin/fuzzel --dmenu";
        max_fps = 30;
      };
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.sway = {
      default = "gtk";
      "org.freedesktop.impl.portal.ScreenCast" = "wlr";
      "org.freedesktop.impl.portal.Screenshot" = "wlr";
    };
  };
}
