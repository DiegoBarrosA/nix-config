{
  config,
  lib,
  pkgs,
  ...
}:

{
  hardware.uinput.enable = true;
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = false;
    settings = {
      encoder = "vaapi";
      output_name = "HEADLESS-1";
      min_fps_factor = 1;
      upnp = "disabled";
    };
    applications = {
      env = {
        PATH = "$(PATH):$(HOME)/.nix-profile/bin:/run/current-system/sw/bin";
      };
      apps = [
        {
          name = "Desktop";
        }
        {
          name = "Agent Monitor (Workspace 9)";
          prep-cmd = [
            {
              do = "swaymsg 'workspace number 9'";
              undo = "";
            }
          ];
        }
        {
          name = "Terminal";
          cmd = "alacritty";
          auto-detach = "true";
        }
      ];
    };
  };

  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [
      47984
      47989
      47990
      48010
    ];
    allowedUDPPorts = [
      47998
      47999
      48000
      48002
      48010
    ];
  };
  users.users.diego.extraGroups = lib.mkAfter [
    "input"
    "uinput"
  ];
}
