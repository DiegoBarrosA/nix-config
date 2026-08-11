{ config, ... }:
let
  inherit (config.colorscheme) colors;
in
{
  # Status line for sway's native bar (see `bars` in default.nix). Replaces
  # waybar: plain text, no icons, no tray, no hover drawers — just the core
  # system blocks, colored by state via Stylix's i3status-rust helper.
  programs.i3status-rust = {
    enable = true;

    bars.main = {
      icons = "none";
      theme = "plain";

      settings = {
        theme.overrides = config.lib.stylix.i3status-rust.bar;
      };

      # A few gadgets get their own accent color (idle_fg only, so
      # warning/critical states still take over from the global theme —
      # e.g. battery still turns critical when low).
      blocks = [
        {
          block = "music";
          format = " MUS $combo.str(max_w:40,rot_interval:0.5) ";
          theme_overrides.idle_fg = "#${colors.base0E}";
        }
        {
          block = "cpu";
          interval = 5;
          format = " CPU $utilization ";
          theme_overrides.idle_fg = "#${colors.base08}";
        }
        {
          block = "amd_gpu";
          interval = 5;
          format = " GPU $utilization ";
          theme_overrides.idle_fg = "#${colors.base0C}";
        }
        {
          block = "memory";
          interval = 30;
          format = " MEM $mem_used_percents.eng(w:2) ";
          theme_overrides.idle_fg = "#${colors.base0B}";
        }
        {
          block = "backlight";
          format = " BL $brightness ";
        }
        {
          block = "battery";
          format = " BAT $percentage ";
        }
        {
          block = "sound";
          format = " VOL {$volume|MUTE} ";
        }
        {
          block = "net";
          format = " {$signal_strength $ssid|WIRED} ";
          theme_overrides.idle_fg = "#${colors.base0A}";
        }
        {
          block = "vpn";
          driver = "tailscale";
          interval = 10;
          format_connected = " VPN minerales ";
          format_disconnected = " VPN off ";
          state_connected = "good";
        }
        {
          block = "time";
          interval = 60;
          format = " $timestamp.datetime(f:'%a %b %d  %H:%M') ";
        }
      ];
    };
  };
}
