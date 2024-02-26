{ pkgs, config, ... }: {
  services.mopidy = {
    enable = true;
    extensionPackages = with pkgs; [
      mopidy-mpris
      mopidy-local
      mopidy-ytmusic
      mopidy-mpd
      mopidy-musicbox-webclient
      python39Packages.ytmusicapi

    ];
    dataDir = "/storage/var/lib/mopidy/";
    configuration = ''
      [file]
      enabled = true

      media_dirs =
      /storage/var/lib/media/Music
      follow_symlinks = true
      [mpd]
      enabled = true
      hostname = 0.0.0.0
      port = 6600
      [ytmusic]
      enabled = true
      [audio]
      output=pulsesink

    '';
  };
}
