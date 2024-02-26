{ pkgs, config, ... }: {
  console = {
    useXkbConfig = true;
  };
  boot = {
    plymouth = {
      enable = true;
      theme = "spinner-monochrome";
      themePackages = [
        (pkgs.plymouth-spinner-monochrome.override {
          inherit (config.boot.plymouth) logo;
        })
      ];
    };
    loader.timeout = 0;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "i915.fastboot=1"
      "loglevel=0"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=0"
      "udev.log_priority=0"
      "vt.global_cursor_default=0"
      "fbcon=nodefer"
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
    initrd.systemd.enable = true;
  };
}
