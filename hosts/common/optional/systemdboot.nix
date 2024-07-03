{
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
      editor = false;
      graceful = false;
    };
    timeout = 0;
    efi.canTouchEfiVariables = true;
  };
}
