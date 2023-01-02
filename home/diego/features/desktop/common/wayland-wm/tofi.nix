{ config, lib, pkgs, ... }:
let
  inherit (config.colorscheme) colors;
  tofi-powermenu = pkgs.writeTextFile {
    name = "tofi-powermenu";
    destination = "/bin/tofi-powermenu";
    executable = true;
    text = ''
       #!/bin/sh

      case "$(
              echo -e ' Shutdown\n Restart\n Logout\n Suspend\n Lock' | tofi --prompt-text=' Power:'
      )" in
              \ Shutdown) exec systemctl poweroff ;;
              \ Restart) exec systemctl reboot ;;
              \ Logout) exec loginctl terminate-session  $XDG_SESSION_ID ;;
              \ Suspend) exec systemctl suspend ;;
              \ Lock) exec swaylock ;;
      esac
    '';
  };

in {
  home.packages = with pkgs; [ tofi tofi-powermenu ];
  xdg.configFile."tofi/config".text = ''
    selection-color=#${colors.base0D}
    font="Jost*, Font Awesome 6 Free Solid"
    font-size=26
    hide-cursor=true
    background-color=#${colors.base00}ee
    drun-launch=true
    history=true
    border-width=0px
    width = 100%
    height = 100%
    border-width = 0
    outline-width = 0
    padding-left = 35%
    padding-top = 35%
    result-spacing = 25
    num-results = 5
  '';
}
