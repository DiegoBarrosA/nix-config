{ config, pkgs, ... }: {
  environment.localBinInPath = true;
  environment.sessionVariables = rec {
    #Wayland compliant backend for electron basde apps
    NIXOS_OZONE_WL = "1";
    #XDG compliant directories
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_BIN_HOME = "$HOME/.local/bin";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    PATH = [
      "$XDG_BIN_HOME"
      "$XDG_CONFIG_HOME/emacs/bin"
      "${config.environment.sessionVariables.XDG_DATA_HOME}/npm/bin"
    ];
  };
  ##TODO organze each variable under especific program configurations.
  environment.variables = {
    ANDROID_HOME =
      "${config.environment.sessionVariables.XDG_DATA_HOME}/android";
    GRADLE_USER_HOME =
      "${config.environment.sessionVariables.XDG_DATA_HOME}/gradle";
    NODE_REPL_HISTORY =
      "${config.environment.sessionVariables.XDG_DATA_HOME}/node_repl_history";
    _JAVA_OPTIONS =
      "-Djava.util.prefs.userRoot=${config.environment.sessionVariables.XDG_CONFIG_HOME}/java";
    GNUPGHOME = "${config.environment.sessionVariables.XDG_DATA_HOME}/gnupg";
    HISTFILE =
      "${config.environment.sessionVariables.XDG_STATE_HOME}/bash/history";
    NPM_CONFIG_USERCONFIG =
      "${config.environment.sessionVariables.XDG_CONFIG_HOME}/npm/npmrc";
    ICEAUTHORITY =
      "${config.environment.sessionVariables.XDG_CACHE_HOME}/ICEauthority";
    "RANGER_LOAD_DEFAULT_RC" = "false";

  };
}
