{ ... }:
{
  flake.modules.nixos.ai-hermes-tasks =
{ config, lib, pkgs, ... }:

let
  cfg = config.services.hermes-agent;
  vault = "/srv/media/Obsidian/obsidiana";
  scratch = "${vault}/Hermes";
  runner = pkgs.writers.writePython3Bin "hermes-task-run"
    {
      libraries = [ pkgs.python3Packages.pyyaml ];
      # Long lines and compact one-liners are the style of this script.
      flakeIgnore = [ "E501" "E701" "E702" "E731" "W503" "W504" ];
    }
    (builtins.readFile ./hermes_tasks.py);
in
{
  # Runs the task files in Hermes/inbox one step at a time, with no LLM involved.
  # It is a oneshot that a path unit and a timer start. The timer also resumes work
  # after a reboot or power cut and retries tasks that wait for a rate limit.
  systemd.services.hermes-tasks = {
    description = "Run Hermes task files from the inbox";
    unitConfig.RequiresMountsFor = [ cfg.stateDir vault ];
    requires = [ "hermes-vault-access.service" ];
    after = [ "hermes-vault-access.service" "sops-install-secrets.service" ];
    # git, nix, bash and the opencode wrapper (it reads its own key file).
    path = [ "/run/current-system/sw" ];
    environment = {
      HOME = cfg.stateDir;
      HERMES_TASK_ROOT = cfg.workingDirectory;
      HERMES_TASK_INBOX = "${scratch}/inbox";
      HERMES_TASK_STATUS_DIR = scratch;
      # Base for the per-run opencode config. The host config pins every agent to a free model.
      HERMES_OPENCODE_BASE_CONFIG = "${config.home-manager.users.diego.xdg.configFile."opencode/opencode.json".source}";
    };
    # A deploy must not kill a running task. A task that is cut off resumes
    # from its last finished step either way.
    restartIfChanged = false;
    stopIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      User = cfg.user;
      Group = cfg.group;
      UMask = "0007";
      # The runner uses the Telegram token and the keys, and passes the workers
      # only a short list of variables (WORKER_ENV in hermes_tasks.py).
      EnvironmentFile = config.sops.templates."hermes.env".path;
      ExecStart = "${runner}/bin/hermes-task-run";
      TimeoutStartSec = "infinity";
      ProtectSystem = "strict";
      ReadWritePaths = [ cfg.stateDir scratch ];
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  systemd.paths.hermes-tasks = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathChanged = "${scratch}/inbox";
  };

  systemd.timers.hermes-tasks = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitInactiveSec = "10min";
    };
  };
}
  ;
}
