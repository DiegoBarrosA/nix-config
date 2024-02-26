{
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
      editor = false;
      graceful = true;
    };
    timeout = 0;
    efi.canTouchEfiVariables = true;
  };
}
