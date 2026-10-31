{ ... }:
{
  flake.modules.homeManager.desktop-sway-i3status-rust =
    { config, ... }:
    let
      inherit (config.colorscheme) colors;
      inherit (config.stylix) fonts;

      c = n: "#${colors.${n}}";
    in
    {
      programs.i3status-rust = {
        enable = true;

        bars.top = {
          icons = "material-nf";

          settings.theme = {
            theme = "slick";
            overrides = {
              # Quiet by default: only warning and critical use colour.
              idle_bg = c "base01";
              idle_fg = c "base05";
              good_bg = c "base01";
              good_fg = c "base05";
              info_bg = c "base01";
              info_fg = c "base05";
              warning_bg = c "base01";
              warning_fg = c "base09";
              critical_bg = c "base01";
              critical_fg = c "base08";
              separator = " ";
              separator_bg = c "base00";
              separator_fg = c "base00";
            };
          };

          blocks = [
            {
              block = "net";
              format = " $icon {$ssid|} ";
              format_alt = " $icon $ip $speed_down.eng(prefix:K) $speed_up.eng(prefix:K) ";
            }
            {
              block = "temperature";
              format = " $icon $max ";
              chip = "*-isa-*";
              good = 60;
              idle = 75;
              info = 80;
              warning = 88;
            }
            {
              block = "cpu";
              interval = 5;
              format = " $icon $utilization ";
              info_cpu = 60;
              warning_cpu = 80;
              critical_cpu = 95;
            }
            {
              block = "memory";
              interval = 5;
              format = " $icon $mem_used_percents ";
              warning_mem = 75;
              critical_mem = 90;
            }
            {
              block = "sound";
              format = " $icon {$volume|muted} ";
              click = [
                {
                  button = "left";
                  cmd = "alacritty -e wiremix";
                }
              ];
            }
            {
              block = "battery";
              format = " $icon $percentage ";
              missing_format = "";
            }
            {
              block = "time";
              interval = 30;
              format = " $icon $timestamp.datetime(f:'%a %d %b  %H:%M') ";
            }
          ];
        };
      };

      wayland.windowManager.sway.config.bars = [
        {
          position = "top";
          # Main display only (Samsung when docked, laptop panel otherwise).
          extraConfig = ''
            output eDP-1
            output DP-10
            height 28
          '';
          statusCommand = "i3status-rs config-top.toml";
          fonts = {
            names = [ fonts.monospace.name ];
            size = fonts.sizes.desktop * 1.0;
          };
          colors = {
            background = c "base00";
            statusline = c "base05";
            separator = c "base00";
            focusedWorkspace = {
              border = c "base0D";
              background = c "base0D";
              text = c "base00";
            };
            activeWorkspace = {
              border = c "base01";
              background = c "base01";
              text = c "base05";
            };
            inactiveWorkspace = {
              border = c "base00";
              background = c "base00";
              text = c "base04";
            };
            urgentWorkspace = {
              border = c "base08";
              background = c "base08";
              text = c "base00";
            };
          };
        }
      ];
    };
}
