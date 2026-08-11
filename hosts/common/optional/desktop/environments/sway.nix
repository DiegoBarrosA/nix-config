{ pkgs, ... }:
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      brightnessctl
      grim
      swayidle
      swaylock
    ];
    extraSessionCommands = ''
      source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    '';
  };
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${pkgs.sway}/share/wayland-sessions";
        user = "greeter";
      };
    };
  };
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.swaylock = { };
  environment.sessionVariables.GTK_USE_PORTAL = "1";
  xdg.portal = {
    enable = true;
    wlr = {
      enable = true;
      settings.screencast = {
        chooser_type = "dmenu";
        chooser_cmd = "${pkgs.tofi}/bin/tofi --prompt-text 'share'";
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
