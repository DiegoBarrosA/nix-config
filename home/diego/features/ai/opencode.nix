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
    # ohMyOpencode, opencodeGo/Zen, extraConfig, profiles, secretEnv, skills set per-host
  };
}
