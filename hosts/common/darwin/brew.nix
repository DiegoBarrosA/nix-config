{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    caskArgs = {
      appdir = "~/Applications";
      require_sha = true;
    };

    taps = [
      "homebrew/cask-versions"
      "homebrew/cask-fonts"
      "homebrew/services"
      "homebrew/cask"
    ];

    brews = [ ];
    casks = [

    ];
    masApps = { };
  };
}
