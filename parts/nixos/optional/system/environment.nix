{ ... }:
{
  flake.modules.nixos.system-environment = { config, pkgs, ... }:
{
  environment.localBinInPath = true;
  environment.sessionVariables = rec {

    NIXOS_OZONE_WL = "1";

    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_BIN_HOME = "$HOME/.local/bin";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    PATH = "$XDG_BIN_HOME:${XDG_DATA_HOME}/npm/bin";

  };

  environment.variables = {
    ANDROID_HOME = "${config.environment.sessionVariables.XDG_DATA_HOME}/android";
    GRADLE_USER_HOME = "${config.environment.sessionVariables.XDG_DATA_HOME}/gradle";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.environment.sessionVariables.XDG_CONFIG_HOME}/java";
    ICEAUTHORITY = "${config.environment.sessionVariables.XDG_CACHE_HOME}/ICEauthority";
    "RANGER_LOAD_DEFAULT_RC" = "false";

  };
};
}
