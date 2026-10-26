{ ... }:
{
  flake.modules.homeManager.cli-teams-calls-fetch =
{
  pkgs,
  lib,
  customPkgs ? { },
  ...
}:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  hasFetcher = customPkgs ? teams-calls-fetcher;
in
{
  # ponytail: one service chaining fetch+extract instead of two coordinated units
  systemd.user.services = lib.mkIf (isLinux && hasFetcher) {
    teams-calls-fetch = {
      Unit.Description = "Fetch Teams transcripts and extract Diego's action items";
      Service = {
        Type = "oneshot";
        Environment = "PATH=${
          lib.makeBinPath [
            customPkgs.teams-calls-fetcher
            pkgs.claude-code
          ]
        }";
        ExecStart = pkgs.writeShellScript "teams-calls-fetch-extract" ''
          teams-calls fetch --days 2
          teams-calls extract
        '';
      };
    };
  };

  systemd.user.timers = lib.mkIf (isLinux && hasFetcher) {
    teams-calls-fetch = {
      Unit.Description = "Daily Teams transcript fetch + action-item extraction";
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
;
}
