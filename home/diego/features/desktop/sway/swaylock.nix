{ config, pkgs, ... }:
let
  inherit (config.colorscheme) colors;
in
{
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;

    settings = {
      # Behavior
      daemonize = true;

      clock = true;
      color = "${colors.base00}";

      # Clock/date format
      timestr = "%H:%M:%S";
      datestr = "%A, %B %d";

      "text-clear" = "!";
      "text-wrong" = "x";
      "text-ver" = "...";

      # Appearance
      font = "${config.stylix.fonts.sansSerif.name}";
      "font-size" = 64;

      # Inside circle (idle state)
      "inside-color" = "${colors.base00}00";
      "inside-clear-color" = "${colors.base00}00";
      "inside-caps-lock-color" = "${colors.base00}00";
      "inside-ver-color" = "${colors.base00}00";
      "inside-wrong-color" = "${colors.base00}00";

      # Ring colors
      "ring-color" = "${colors.base0D}00";
      "ring-clear-color" = "${colors.base0C}00";
      "ring-caps-lock-color" = "${colors.base0A}00";
      "ring-ver-color" = "${colors.base0E}00";
      "ring-wrong-color" = "${colors.base0F}00";

      # Line (between ring and inside)
      "line-color" = "00000000";
      "line-clear-color" = "00000000";
      "line-caps-lock-color" = "00000000";
      "line-ver-color" = "00000000";
      "line-wrong-color" = "00000000";
      "separator-color" = "00000000";

      # Key highlight
      "key-hl-color" = "${colors.base0B}00";
      "bs-hl-color" = "${colors.base09}00";
      "caps-lock-key-hl-color" = "${colors.base0A}00";
      "caps-lock-bs-hl-color" = "${colors.base09}00";

      # Text colors
      "text-color" = "${colors.base0D}";
      "text-clear-color" = "${colors.base04}";
      "text-caps-lock-color" = "${colors.base0A}00";
      "text-ver-color" = "${colors.base0E}";
      "text-wrong-color" = "${colors.base0F}";

      # Layout text
      "layout-text-color" = "${colors.base04}00";
      "layout-bg-color" = "${colors.base00}00";

      # Indicator
      indicator = true;
      "indicator-radius" = 200;
      "indicator-thickness" = 20;
      "indicator-caps-lock" = true;
      "indicator-idle-visible" = true;
    };
  };
}
