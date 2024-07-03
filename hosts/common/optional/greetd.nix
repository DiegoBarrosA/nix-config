{ pkgs, lib, config, ... }:
let
  sway-kiosk = command:
    "${lib.getExe pkgs.sway} --config ${
      pkgs.writeText "kiosk.config" ''
        output * bg #000000 solid_color
        xwayland disable
        input "type:touchpad" {
          tap enabled
        }
        exec '${command}; ${pkgs.sway}/bin/swaymsg exit'
      ''
    }";
in {
  users.extraUsers.greeter = {
    packages = with pkgs; [
      pantheon.elementary-gtk-theme
      papirus-icon-theme
      capitaine-cursors
      jost
    ];
    # For caching and such
    home = "/tmp/greeter-home";
    createHome = true;
  };
  programs.regreet = {
    enable = true;
    settings = {
      GTK = {
        icon_theme_name = "Papirus";
        theme_name = "Elementary";
        cursor_theme_name = "capitaine-cursors";
        font_name = "Jost* 15";
      };
      appearance = { greeting_msg = "God is dead"; };
      # background = {

      #  path = wallpaper;
      #  fit = "Cover";
      #};
    };
  };
  services.greetd = {
    enable = true;
    settings.default_session.command =
      sway-kiosk (lib.getExe config.programs.regreet.package);
  };
}
