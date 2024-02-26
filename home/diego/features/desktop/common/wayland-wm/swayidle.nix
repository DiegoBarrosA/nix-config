{ pkgs, ... }: {
  services.swayidle = {
    enable = true;
    timeouts = [{
      timeout = 20;
      command = "${pkgs.swaylock-effects}/bin/swaylock";
    }];
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock-effects}/bin/swaylock";
      }
      {
        event = "lock";
        command = "${pkgs.swaylock-effects}/bin/swaylock";
      }
    ];
  };

}
