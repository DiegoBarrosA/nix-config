{ config, lib, pkgs, ... }:

{
  # Simply install just the packages
  environment.packages = with pkgs;
    [
      # User-facing stuff that you really really want to have
      #vim # or some other editor, e.g. nano or neovim
      ani-cli
      # Some common stuff that people expect to have
      #diffutils
      #findutils
      #utillinux
      #tzdata
      #hostname
      #man
      #gnugrep
      #gnupg
      #gnused
      #gnutar
      #bzip2
      #gzip
      #xz
      #zip
      #unzip
    ];

  # Backup etc files instead of failing to activate generation if a file already exists in /etc
  environment.etcBackupExtension = ".bak";

  # Read the changelog before changing this value
  system.stateVersion = "22.11";

  # Set up nix for flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Set your time zone
  time.timeZone = "America/Santiago";
  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;

    config = { config, lib, pkgs, ... }: {

      imports = [ ../../home/diego/indigo.nix ]; # insert home-manager config
      # Read the changelog before changing this value
    };
  };
}
