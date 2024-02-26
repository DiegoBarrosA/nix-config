{ pkgs, ... }: {
  fontProfiles = {
    enable = true;
    monospace = {
      family = "Fantasque Sans Mono";
      package = pkgs.fantasque-sans-mono;
    };
    regular = {
      family = "Jost*";
      package = pkgs.jost;
    };
  };
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
    font-awesome
    source-han-mono
    source-han-sans
  ];
}
