{ ... }:
{
  flake.modules.homeManager.desktop-common-alacritty =
{ pkgs, ... }:
{
  home.sessionVariables = {
    TERMINAL = "alacritty";
  };

  programs.alacritty = {
    enable = true;
    settings = {

      general = {

        ipc_socket = true;

        live_config_reload = true;
      };

      terminal = {

        shell = {
          program = "${pkgs.nushell}/bin/nu";
          args = [ "--login" ];
        };
      };

      window = {

        padding = {
          x = 15;
          y = 15;
        };
        dynamic_padding = true;
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      cursor = {
        style = {
          shape = "Beam";
          blinking = "On";
        };
        blink_interval = 500;
      };

      mouse = {
        hide_when_typing = true;
      };

      keyboard.bindings = [
        {
          key = "F";
          mods = "Command|Shift";
          action = "ToggleFullscreen";
        }
      ];

      selection.save_to_clipboard = true;
    };
  };
};
}
