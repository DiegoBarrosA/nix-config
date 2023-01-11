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
  (nerdfonts.override { fonts = [ "FantasqueSansMono"]; })
  cascadia-code
  font-awesome
  noto-fonts-cjk-sans
  ];
}
