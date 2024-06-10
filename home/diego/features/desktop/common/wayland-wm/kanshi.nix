{ pkgs, ... }:
let
  wallpaper = builtins.fetchurl {
    url =
      "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-nineish.png";
    sha256 = "059hjcnpy7jj8bijs2xbjmwfc41dxy4pl801nkhblrdxiny21s0h";
  };
in {
  services.kanshi = {
    enable = true;
    systemdTarget = "graphical-session.target";
    settings = [
      {
        profile.name = "dual-head";
        profile.exec = "${pkgs.swaybg}/bin/swaybg -c '7f9ed4'";
        profile.outputs = [
          {
            criteria = "Samsung Electric Company LS27A600U HCJW500005";
            position = "0,0";
          }
          {
            criteria = "LG Electronics LG ULTRAWIDE 0x0002A4C3";
            transform = "90";
            position = "-1080,-600";
          }
        ];
      }
      {
        profile.name = "single-head";
        profile.exec = "${pkgs.swaybg}/bin/swaybg -c '#82AAFF'";
        profile.outputs = [{
          criteria = "LG Electronics LG ULTRAWIDE 0x0002A4C3";
          transform = "90";
        }];
      }

    ];
  };

}
