{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
  };
  homebrew.taps = [
    "homebrew/cask"
    "homebrew/cask-versions"
    "homebrew/cask-fonts"
  #  "wez/wezterm"
    "homebrew/services"
    "homebrew/core"
  #  "koekeishiya/formulae" # yabai
  #  "FelixKratz/formulae" # sketchybar
  #  "netbirdio/tap"
  ];
  homebrew.brews = [
   # "gnu-sed"
   # "sketchybar" # macos bar alternative
   # "ifstat" # network
   # "yabai" # tiling window manager
   # "skhd" # keybinding manager
  ];
  homebrew.casks = [
    #"keycastr"
    #"netbirdio/tap/netbird-ui"
    #"aldente"
    #"espanso"
    #"neovide"
    #"chatterino"
    #"scroll-reverser"
    #"raycast"
    #"via"
    #"grammarly"
    #"balenaetcher"
    #"hot" #temp in menu
    #"1password-cli"
    #"1password-beta"
    #"plexamp"
    #"lapce"
    #"logseq" #notion, obsidian or whatever
    #"hammerspoon"
    #"gitkraken"
    #"raycast"
    #"plex"
    #"visual-studio-code-insiders"
    #"wezterm-nightly"
    "zoom" # just in case
    #"slack"
    #"lapce"
    #"discord"
    # "font-iosevka"
    #"zoom"
    # "font-jetbrains-mono"
    # "font-hack-nerd-font"
    #"sf-symbols"
    #"wireshark"
    #"iina"
    #"postman"
    "signal"
    #"microsoft-teams"


 "reaper"
 "firefox"
 "keepassxc"
"syncthing"

"visual-studio-code"

  ];
  homebrew.masApps = {};
}
