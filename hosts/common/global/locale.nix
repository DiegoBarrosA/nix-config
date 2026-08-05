{ lib, config, ... }: {
  i18n = {
    defaultLocale = lib.mkDefault "en_US.UTF-8";
    extraLocaleSettings = { LC_TIME = lib.mkDefault "en_US.UTF-8"; };
    supportedLocales =
      lib.mkDefault [ "en_US.UTF-8/UTF-8" "es_CL.UTF-8/UTF-8" ];
  };
  time.timeZone = lib.mkDefault "America/Santiago";
  # Some Electron apps (e.g. personal-assistant) read /etc/timezone directly
  # instead of /etc/localtime or $TZ. NixOS only creates the symlink.
  environment.etc."timezone" = lib.mkIf (config.time.timeZone != null) {
    text = config.time.timeZone;
  };
}
