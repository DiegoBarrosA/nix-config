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
      ReadWritePaths = [ "/mnt/media/Music" ];
      MemoryDenyWriteExecute = lib.mkForce false;
    };

    environment.PYTHONPATH = lib.mkForce "${config.services.music-assistant.package.pythonPath}:${extraPythonPath}";
  };

  networking.firewall.allowedTCPPorts = [
    7000
    8097
  ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 32768;
      to = 65535;
    }
  ];
}
