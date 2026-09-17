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
      pkgs.cliairplay
      pkgs.libraop
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
  ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 32768;
      to = 65535;
    }
  ];
}
