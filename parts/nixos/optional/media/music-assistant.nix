{ ... }:
{
  flake.modules.nixos.media-music-assistant =
{ config, pkgs, lib, ... }:
let
  pywidevine = pkgs.python3Packages.pywidevine;
  pycryptodome = pkgs.python3Packages.pycryptodome;
  aiosendspin = pkgs.python3Packages.aiosendspin;
  asyncUpnpClient = pkgs.python3Packages.async-upnp-client;
  pychromecast = pkgs.python3Packages.pychromecast;
  extraPythonPath = pkgs.python3.pkgs.makePythonPath [
    pywidevine
    pycryptodome
    aiosendspin
    asyncUpnpClient
    pychromecast
  ];

  maWithProviders = config.services.music-assistant.package.override {
    inherit (config.services.music-assistant) providers;
  };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      shaka-packager = prev.shaka-packager.overrideAttrs (old: {
        env = (old.env or { }) // { NIX_CFLAGS_COMPILE = "-Wno-error -fno-char8_t"; };
      });
    })
  ];

  services.music-assistant = {
    enable = true;
    providers = [
      "airplay"
      "alexa"
      "apple_music"
      "chromecast"
      "dlna"
      "filesystem_local"
      "hass"
      "sendspin"
      "ytmusic"
    ];
  };

  systemd.services.music-assistant = {
    path = [
      pkgs.deno
      pkgs.ffmpeg-headless
    ];

    serviceConfig = {
      ReadWritePaths = [ "/srv/media/library/music" ];
      MemoryDenyWriteExecute = lib.mkForce false;

      StateDirectory = lib.mkForce [
        "music-assistant"
        "music-assistant/widevine_cdm"
      ];
    };

    environment.PYTHONPATH = lib.mkForce "${maWithProviders.pythonPath}:${extraPythonPath}";
  };

  networking.firewall.allowedTCPPorts = [
    7000
    8095
    8097
    8927 # sendspin server, native clients
  ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 32768;
      to = 65535;
    }
  ];
}

  ;
}
