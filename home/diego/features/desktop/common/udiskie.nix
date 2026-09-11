{ pkgs, ... }: {
  xdg.configFile."udiskie/config.yml".text = ''
    program_options:
      automount: true
      notify: true
      tray: false
  '';

  systemd.user.services.udiskie = {
    Unit = {
      Description = "udiskie automounter";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.udiskie}/bin/udiskie";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}