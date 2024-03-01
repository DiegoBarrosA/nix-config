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
    "homebrew/cask-versions"
    "homebrew/cask-fonts"
    "homebrew/services"
    "homebrew/cask"
  ];
  homebrew.brews = [ ];
  homebrew.casks = [

  ];
  homebrew.masApps = { };
}
