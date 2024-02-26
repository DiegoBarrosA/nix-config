{ config, inputs, home-manager, pkgs, lib, ... }: {
  networking.hostName = "lazulita";
  imports = [ ../common/darwin ../common/global/fish.nix ];
  programs.fish = { enable = true; };
  programs.zsh = {
    enable = true; # default shell on catalina
    loginShellInit = "fish";
  };
  users.users.diego = {
    name = "diego";
    shell = pkgs.fish;
    home = "/Users/diego";
  };
  system.defaults = {
    loginwindow = {
      GuestEnabled = false;
      SHOWFULLNAME = false;
    };
  };
  homebrew.enable = true;
  homebrew.casks = [
    "insomnia"
    "obs"
    "microsoft-office"
    "alfred"
    "logi-options-plus"
    "vanilla"
    "monitorcontrol"
    "logitune"
    "firefox"
    "steam"
    "flameshot"
    "zoom"
  ];
  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [ fantasque-sans-mono jost ];
  system.stateVersion = 4;
}
