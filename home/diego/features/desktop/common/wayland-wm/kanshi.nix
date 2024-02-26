{ pkgs, ... }: {
  services.kanshi = {
    enable = true;
    systemdTarget = "graphical-session.target";

    profiles = {
      hydraMain = {

        exec =
          "${pkgs.swaybg}/bin/swaybg -i /storage/home/diego/Pictures/Wallpapers/leaves.jpg -m fill";
        outputs = [
          {
            criteria = "HDMI-A-1";

            position = "0,0";

          }
          {
            criteria = "ViewSonic Corporation VX2239 SERIES S4T103203811";

            transform = "90";
            position = "-1080,-550";
          }

        ];
      };
      verticalSolo = {

        outputs = [{
          criteria = "ViewSonic Corporation VX2239 SERIES S4T103203811";

          transform = "90";
          position = "0,0";
        }

          ];
      };

    };
  };

}
