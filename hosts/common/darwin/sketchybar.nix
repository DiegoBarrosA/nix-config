{ pkgs, ... }: {
  services.sketchybar = {
    extraPackages = [ pkgs.sketchybar-app-font ];
    enable = true;
    config = ''
      sketchybar --bar height=35\
      blur_radius=30            \
      corner_radius=8           \
      position=left             \
      y_offset=5                \
      margin=5                  \
      sticky=off                \
      padding_left=5           \
      padding_right=5          \
      color=0xff333333\
      --add item demo left\
      --set demo label=󰈹\
      --set demo label.font.family="FantasqueSansM Nerd Font Mono"\
      --set demo label.font.size=30\
      --subscribe demo system_woke \
      sketchybar --update\
    '';
  };
}
