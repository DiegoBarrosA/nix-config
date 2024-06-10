{ pkgs, ... }: {
  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      config = { common = { default = [ "gtk" ]; }; };
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}

