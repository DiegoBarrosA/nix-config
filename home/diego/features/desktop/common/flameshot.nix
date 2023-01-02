{ config, ... }:
let inherit (config.colorscheme) colors;
in {
  services.flameshot = {
    enable = true;
    settings = {
      General = {
        disabledTrayIcon = true;
        showStartupLaunchMessage = false;
        startupLaunch = true;
        uiColor = "#${colors.base0D}";
        contrastUiColor = "#${colors.base0C}";
      };
    };
  };

}
