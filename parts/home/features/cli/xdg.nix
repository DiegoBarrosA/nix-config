{ ... }:
{
  flake.modules.homeManager.cli-xdg =
{ config, lib, ... }:
let
  inherit (config.xdg)
    cacheHome
    configHome
    dataHome
    stateHome
    ;
in
{
  programs.gpg.homedir = "${dataHome}/gnupg";

  home.sessionVariables = {
    CARGO_HOME = "${dataHome}/cargo";
    RUSTUP_HOME = "${dataHome}/rustup";

    NODE_REPL_HISTORY = "${stateHome}/node_repl_history";
    NPM_CONFIG_USERCONFIG = "${configHome}/npm/npmrc";
    NPM_CONFIG_INIT_MODULE = "${configHome}/npm/config/npm-init.js";
    NPM_CONFIG_CACHE = "${cacheHome}/npm";
    NPM_CONFIG_PREFIX = "${dataHome}/npm";
    NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";

    HISTFILE = "${stateHome}/bash/history";
    USQL_HISTORY = "${dataHome}/usql/history";
    MPLAYER_HOME = "${configHome}/mplayer";
    WGETRC = "${configHome}/wgetrc";
  };

  home.sessionPath = [ "${dataHome}/npm/bin" ];

  xdg.configFile."wgetrc".text = ''
    hsts-file = ${dataHome}/wget-hsts
  '';

  home.activation.xdgStateDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${stateHome}/bash" "${dataHome}/usql" "${dataHome}/npm" "${configHome}/npm/config"
  '';
}
;
}
