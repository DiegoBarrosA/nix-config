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
  cascadia-code
  font-awesome
  noto-fonts-cjk-sans
  ];
}
