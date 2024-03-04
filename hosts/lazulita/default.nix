{ config, inputs, home-manager, pkgs, lib, ... }: {
  networking.hostName = "lazulita";
  imports = [ ../common/darwin ];
  programs.zsh = {
    enable = true;
    loginShellInit = "nu";
  };
  users.users.diego = {
    name = "diego";
    shell = "${pkgs.nushell}/bin/nu";
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
    "google-drive"
    "zed"
    "insomnia"
    "microsoft-office"
    "alfred"
    "logi-options-plus"
    "vanilla"
    "monitorcontrol"
    "logitune"
    "firefox"
    "brave"
    "steam"
    "flameshot"
    "citrix-workspace"
  ];

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [ fantasque-sans-mono jost ];
  system.stateVersion = 4;
}
