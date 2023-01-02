{ config, pkgs, lib, ... }: {
  users.users.diego.name = "diego";
  imports = [ ../global/darwin.nix ./brew.nix ];
  services = {
    # TODO: testing netbird
    nix-daemon.enable = lib.mkDefault true;
    activate-system.enable = lib.mkDefault true;
  };
  nix.configureBuildUsers = lib.mkDefault true;
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  security.pam.enableSudoTouchIdAuth = true;
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      fantasque-sans-mono
      (nerdfonts.override {
        fonts = [ "FiraCode" "DroidSansMono" "Hack" "JetBrainsMono" ];
      })
    ];
  };
  #TODO: have to change
  # launchd.user.agents.mailsync = {
  #   serviceConfig.Program = "${pkgs.lnl.letty}/bin/letty-blink";
  #   serviceConfig.WatchPaths = ["/var/mail/lnl"];
  #   serviceConfig.KeepAlive = false;
  #   serviceConfig.ProcessType = "Background";
  # };
  environment.loginShell = "${pkgs.fish}/bin/fish";
  #  environment.loginShell = "${pkgs.zsh}/bin/zsh -l";
  environment.variables.SHELL = "${pkgs.fish}/bin/fish";
  #  environment.variables.SHELL = "${pkgs.zsh}/bin/zsh";
  environment.variables.LANG = "en_US.UTF-8";
  environment.systemPackages = with pkgs; [ fish ];
  system.defaults = {
    alf = {
      allowdownloadsignedenabled = 0;
      allowsignedenabled = 1;
      globalstate = 0;
      loggingenabled = 0;
      stealthenabled = 0;
    };
    # networking = {
    #   hostName = "emily";
    # };
    dock = {
      autohide = false;
      #    dashboard-in-overlay = false;
      #    enable-spring-load-actions-on-all-items = true;
      #    expose-animation-duration = 0.1;
      #   expose-group-by-app = false;
      #   launchanim = true;
      mineffect = "genie";
      #   minimize-to-application = true;
      #   mouse-over-hilite-stack = true;
      #   mru-spaces = false;
      orientation = "bottom";
      #   show-process-indicators = true;
      show-recents = false;
      showhidden = true;
      #   static-only = false;
      #   tilesize = 33;
    };

    finder = {
      AppleShowAllExtensions = true;
      CreateDesktop = true;
      FXEnableExtensionChangeWarning = false;
      _FXShowPosixPathInTitle = true;
    };

    #LaunchServices.LSQuarantine = false;

    #NSGlobalDomain = {
    # AppleInterfaceStyleSwitchesAutomatically = false;
    # AppleFontSmoothing = 1;
    # AppleKeyboardUIMode = 3;
    # AppleShowAllExtensions = true;
    # AppleShowAllFiles = true;

    # InitialKeyRepeat = 17;
    # KeyRepeat = 3;

    #NSAutomaticCapitalizationEnabled = true;
    #NSAutomaticDashSubstitutionEnabled = false;
    #NSAutomaticPeriodSubstitutionEnabled = true;
    #NSAutomaticQuoteSubstitutionEnabled = true;
    #      NSAutomaticSpellingCorrectionEnabled = true;

    #     NSDisableAutomaticTermination = true;
    #    NSDocumentSaveNewDocumentsToCloud = true;
    #   NSNavPanelExpandedStateForSaveMode = true;
    #  NSNavPanelExpandedStateForSaveMode2 = true;
    # NSScrollAnimationEnabled = true;
    # NSTableViewDefaultSizeMode = 1;
    #NSTextShowsControlCharacters = true;

    #NSWindowResizeTime = 0.001;
    # PMPrintingExpandedStateForPrint = true;
    # PMPrintingExpandedStateForPrint2 = true;

    #     _HIHideMenuBar = lib.mkDefault true;
    #
    #    "com.apple.keyboard.fnState" = false;
    #   "com.apple.sound.beep.feedback" = 0;
    #  "com.apple.springing.delay" = 0.1;
    # "com.apple.springing.enabled" = true;
    #  "com.apple.swipescrolldirection" = true;
    # "com.apple.trackpad.enableSecondaryClick" = true;
    # "com.apple.trackpad.scaling" = 1.5;
    # "com.apple.trackpad.trackpadCornerClickBehavior" = null;
    #};

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = lib.mkDefault true;
  };
}
