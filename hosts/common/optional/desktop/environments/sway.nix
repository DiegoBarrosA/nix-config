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

  # XDG Desktop Portals for wlroots/Sway
  xdg.portal = {
    enable = true;
    wlr = {
      enable = true;
      # The wlr portal needs a "chooser" to pick which output/window to
      # capture. Without it, screencast falls through to uninstalled dmenu
      # programs and reports "no output found", which surfaces in Firefox as
      # `NotAllowedError` on getDisplayMedia(). slurp gives an interactive
      # on-screen output/region selector. This MUST be set here at the NixOS
      # level: xdg.portal.wlr.enable generates the config file and launches
      # the portal with --config=<that file>, which overrides any
      # ~/.config/xdg-desktop-portal-wlr/config from home-manager.
      settings.screencast = {
        chooser_type = "simple";
        chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
        # Cap frame rate; without this the portal may stall on damage-only
        # updates and the consumer sees a frozen stream.
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
