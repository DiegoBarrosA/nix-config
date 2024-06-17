{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    caskArgs = { appdir = "~/Applications"; };
    taps =
      [ "homebrew/cask-versions" "homebrew/cask-fonts" "homebrew/services" ];
    brews = [ ];
    casks = [ ];
    masApps = { };
  };
}
