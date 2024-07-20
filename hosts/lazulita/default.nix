{ config, pkgs, ... }: {
  networking.hostName = "lazulita";
  imports = [ ../common/darwin ];
  programs.zsh = {
    enable = true;
    loginShellInit = "zellij";
  };
  users.users.diego = {
    name = "diego";
    home = "/Users/diego";
  };
  system.defaults = {
    loginwindow = {
      GuestEnabled = false;
      SHOWFULLNAME = false;
    };
  };
  services.tailscale = {
    enable = true;
    overrideLocalDns = true;
  };
  homebrew.enable = true;
  homebrew.casks = [
    "alacritty"
    "citrix-workspace"
    "firefox"
    "flameshot"
    "google-drive"
    "google-chrome"
    "insomnia"
    "logi-options-plus"
    "logitune"
    "microsoft-office-businesspro"
    "microsoft-remote-desktop"
    "monitorcontrol"
    "obsidian"
    "pika"
    "syncthing"
    "vanilla"
    "vscodium"
    "zoom"
    "amethyst"
    "qutebrowser"
  ];

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
    jost
  ];
  system.stateVersion = 4;
  system.defaults.dock.persistent-apps = [
    "${config.homebrew.caskArgs.appdir}/Firefox.app"
    "${config.homebrew.caskArgs.appdir}/Insomnia.app"
    "${config.homebrew.caskArgs.appdir}/Home Manager Apps/Alacritty.app"
  ];
}
