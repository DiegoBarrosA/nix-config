{ pkgs, config, ... }:
let
  droidcamCli = pkgs.droidcam.overrideAttrs (old: {
    # ponytail: droidcam and droidcam-cli ship in one output; strip the GTK
    # GUI + its desktop entry post-install so the GTK3 stack drops out of
    # the closure. Revisit if upstream ever splits the outputs.
    postInstall = (old.postInstall or "") + ''
      rm -f $out/bin/droidcam
      rm -rf $out/share/applications $out/share/icons $out/share/pixmaps
    '';
  });
in
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      brightnessctl
      grim
      swayidle
      swaylock
    ];
    extraSessionCommands = ''
      source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    '';
  };
  environment.systemPackages = [ droidcamCli ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [
    "v4l2loopback"
    "snd-aloop"
  ];
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${pkgs.sway}/share/wayland-sessions";
        user = "greeter";
      };
    };
  };
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.swaylock = { };
  environment.sessionVariables.GTK_USE_PORTAL = "1";
  xdg.portal = {
    enable = true;
    wlr = {
      enable = true;
      settings.screencast = {
        chooser_type = "dmenu";
        chooser_cmd = "${pkgs.tofi}/bin/tofi --prompt-text 'share'";
        max_fps = 30;
      };
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.sway = {
      default = "gtk";
      "org.freedesktop.impl.portal.ScreenCast" = "wlr";
      "org.freedesktop.impl.portal.Screenshot" = "wlr";
    };
  };
}
