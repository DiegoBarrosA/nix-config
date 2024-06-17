{ config, pkgs, ... }: {
  networking.hostName = "lazulita";
  imports = [ ../common/darwin ];
  programs.zsh = {
    enable = true;
    loginShellInit = "fish";
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
    "microsoft-remote-desktop"
    "pika"
    "google-drive"
    "insomnia"
    "microsoft-office"
    "alfred"
    "logi-options-plus"
    "vanilla"
    "monitorcontrol"
    "logitune"
    "firefox"
    "citrix-workspace"
    "zoom"
    "obsidian"
    "flameshot"
    "vscodium"
  ];
  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [ fantasque-sans-mono jost ];
  system.stateVersion = 4;
  system.defaults.dock.persistent-apps = [
    "${config.homebrew.caskArgs.appdir}/Firefox.app"
    "${config.homebrew.caskArgs.appdir}/Insomnia.app"
    "${config.homebrew.caskArgs.appdir}/Home Manager Apps/Alacritty.app"
  ];
}
