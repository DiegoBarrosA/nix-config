{ config, pkgs, lib, ... }: {
  users.users.diego.name = "diego";
  imports = [ ../global/darwin.nix ./brew.nix ];
  services = {
    # TODO: testing netbird
    nix-daemon.enable = lib.mkDefault true;
    activate-system.enable = lib.mkDefault true;
  };
  home-manager.useGlobalPkgs = true;
  nix.configureBuildUsers = lib.mkDefault true;
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  security.pam.enableSudoTouchIdAuth = true;
  # fonts = {
  #   fontDir.enable = true;
  #   fonts = with pkgs; [
  #     jost
  #     terminus_font
  #     fantasque-sans-mono
  #     font-awesome
  #     (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
  #   ];
  # };
  # TODO: have to change
  # launchd.user.agents.mailsync = {
  #   serviceConfig.Program = "${pkgs.lnl.letty}/bin/letty-blink";
  #   serviceConfig.WatchPaths = ["/var/mail/lnl"];
  #   serviceConfig.KeepAlive = false;
  #   serviceConfig.ProcessType = "Background";
  # };
  environment.loginShell = "${pkgs.zsh}/bin/zsh";
  environment.shells = [ pkgs.nushell ];
  environment.variables.SHELL = "${pkgs.nushell}/bin/nu";
  environment.variables.LANG = "en_US.UTF-8";
  system.defaults = {
    alf = {
      allowdownloadsignedenabled = 0;
      allowsignedenabled = 1;
      globalstate = 0;
      loggingenabled = 0;
      stealthenabled = 0;
    };
    dock = {
      autohide = false;
      dashboard-in-overlay = false;
      enable-spring-load-actions-on-all-items = true;
      expose-animation-duration = 0.1;
      expose-group-by-app = false;
      launchanim = true;
      mineffect = "genie";
      minimize-to-application = true;
      mouse-over-hilite-stack = true;
      mru-spaces = false;
      orientation = "bottom";
      show-process-indicators = true;
      show-recents = false;
      showhidden = true;
      static-only = false;
      tilesize = 48;
      largesize = 64;
    };
    finder = {
      AppleShowAllExtensions = true;
      CreateDesktop = true;
      FXEnableExtensionChangeWarning = false;
      _FXShowPosixPathInTitle = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    NSGlobalDomain = {
      AppleInterfaceStyleSwitchesAutomatically = false;
      AppleFontSmoothing = 1;
      AppleKeyboardUIMode = 3;
      AppleShowAllExtensions = true;
      AppleShowAllFiles = false;
      InitialKeyRepeat = 17;
      KeyRepeat = 3;
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = true;
      NSAutomaticQuoteSubstitutionEnabled = true;
      NSAutomaticSpellingCorrectionEnabled = true;
      NSDisableAutomaticTermination = true;
      NSDocumentSaveNewDocumentsToCloud = true;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      NSScrollAnimationEnabled = true;
      NSTableViewDefaultSizeMode = 2;
      NSTextShowsControlCharacters = true;
      NSWindowResizeTime = 1.0e-3;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      _HIHideMenuBar = lib.mkDefault false;
      AppleWindowTabbingMode = "always";
      "com.apple.mouse.tapBehavior" = 1;
      "com.apple.keyboard.fnState" = false;
      "com.apple.sound.beep.feedback" = 0;
      "com.apple.springing.delay" = 0.1;
      "com.apple.springing.enabled" = true;
      "com.apple.swipescrolldirection" = true;
      "com.apple.trackpad.enableSecondaryClick" = true;
      "com.apple.trackpad.scaling" = 1.5;
      "com.apple.trackpad.trackpadCornerClickBehavior" = null;
    };
    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = lib.mkDefault true;
  };
}
