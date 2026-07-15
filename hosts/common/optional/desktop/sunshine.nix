# Sunshine game streaming server for Moonlight clients
# Optimized for Wayland/Sway with AMD VA-API hardware encoding
{ config, lib, pkgs, ... }:

{
  # uinput kernel module for virtual input devices (mouse/keyboard/gamepad)
  # Required for Moonlight touch input and virtual keyboard to work
  hardware.uinput.enable = true;

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # Required for KMS/DRM capture on Wayland
    openFirewall = false; # We configure Tailscale-only access below

    settings = {
      # Encoder: AMD VA-API (hardware accelerated via radeonsi)
      encoder = "vaapi";

      # Capture only the virtual headless output for phone streaming
      output_name = "HEADLESS-1";

      # Streaming quality defaults
      min_fps_factor = 1;

      # Network: disable UPnP (we use Tailscale for secure access)
      upnp = "disabled";
    };

    applications = {
      env = {
        PATH = "$(PATH):$(HOME)/.nix-profile/bin:/run/current-system/sw/bin";
      };
      apps = [
        {
          name = "Desktop";
          # Empty cmd = stream current desktop
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

  # Firewall: Only allow Sunshine ports on Tailscale interface
  # This ensures streaming is only accessible via your Tailscale VPN
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [
      47984 # HTTPS (secure control)
      47989 # HTTP (web UI redirect)
      47990 # Web UI
      48010 # RTSP
    ];
    allowedUDPPorts = [
      47998 # Video stream
      47999 # Control
      48000 # Audio stream
      48002 # Mic (input)
      48010 # RTSP
    ];
  };

  # Ensure user can access input devices for KMS capture and uinput
  users.users.diego.extraGroups = lib.mkAfter [
    "input"
    "uinput" # Required for virtual mouse/keyboard (touch input)
  ];
}
