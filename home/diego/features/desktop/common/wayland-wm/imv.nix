{ config, lib, pkgs, ... }:

let

  inherit (config.colorscheme) colors;
in {
  home.packages = with pkgs; [ imv ];
  xdg.configFile."imv/config".text = ''
    [options]
    background=${colors.base00}
    overlay=true
    overlay_font=${config.fontProfiles.regular.family}
    overlay_text_color=${colors.base05}
    overlay_background_color=${colors.base00}
    overlay_background_alpha=00
    [binds]
    n=next
    p=prev
    <Ctrl+equal>=zoom 2
    <Ctrl+minus>=zoom -2
  '';

}
