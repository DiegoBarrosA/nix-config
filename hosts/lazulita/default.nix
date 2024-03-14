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
    "pika"
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
    "steam"
    "citrix-workspace"
    "zoom"
  ];
  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [ fantasque-sans-mono jost ];
  system.stateVersion = 4;

  environment.systemPackages = with pkgs; [ flameshot ];
  system.defaults.dock.persistent-apps = [
    "/Users/diego/Applications/Firefox.app"
    "/Users/diego/Applications/Zed.app"
    "/Users/diego/Applications/Insomnia.app"
    "/Users/diego/Applications/Home Manager Apps/Alacritty.app"
  ];

}
