{
  services.skhd = {
    enable = true;
    skhdConfig = ''
      alt - e : yabai -m window --toggle split
      alt - return : alacritty msg create-window || alacritty
    '';
  };
}
