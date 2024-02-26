{ config, ... }:
let inherit (config.colorscheme) colors kind;
in {
  services.mako = {
    enable = true;
    iconPath = if kind == "dark" then
      "${config.gtk.iconTheme.package}/share/icons/Papirus-Dark"
    else
      "${config.gtk.iconTheme.package}/share/icons/Papirus-Light";
    font = "${config.fontProfiles.regular.family} 16";
    padding = "10,20";
    anchor = "top-center";
    width = 400;
    height = 150;
    borderSize = 2;
    defaultTimeout = 12000;
    borderRadius = 10;
    backgroundColor = "#${colors.base00}fe";
    borderColor = "#${colors.base01}fe";
    textColor = "#${colors.base05}fe";
  };
}
