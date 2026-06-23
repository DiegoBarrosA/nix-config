{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.opencode-config = {
    enable = true;
    channels.telegram.enable = true;
    notifications.telegram = {
      enable = true;
      enableShellHook = false;
    };
    provider.enable = false;
    # opencodeGo/Zen, extraConfig, profiles, secretEnv, skills, agents, commands, references set per-host
  };
}
