{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) concatStringsSep mapAttrsToList mkIf;

  # Easy names for each SSH key. Add a new key here and it's wired up
  # everywhere: per-host selection, agent registration at login, and the
  # `ssh-add-all` nu helper. Point these at existing key files; the private
  # keys themselves never live in this repo.
  keys = {
    diego = "~/.ssh/id_ed25519";
    github = "~/.ssh/keys/github_ed25519";
    work = "~/.ssh/keys/work_ed25519";
  };

  hasSystemd = pkgs.stdenv.isLinux && !pkgs.stdenv.hostPlatform.isAndroid;

  # ssh-add every key. Passphrase-protected keys fail silently here (no tty at
  # login); AddKeysToAgent picks them up interactively on first use.
  addAllScript = pkgs.writeShellScript "ssh-add-all" (
    concatStringsSep "\n" (
      mapAttrsToList (name: path: ''
        ${pkgs.openssh}/bin/ssh-add ${path} >/dev/null 2>&1 || true
      '') keys
    )
  );
in
{
  programs.ssh = {
    enable = true;

    # Pull in config fragments managed elsewhere. home-manager only owns
    # ~/.ssh/config; the teleport/omnistation fragments from private-config
    # stay as separate files and are included at the top.
    includes = [ "~/.ssh/omnistation-config" ];

    # The "*" block below replaces the deprecated built-in defaults.
    enableDefaultConfig = false;

    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        IdentitiesOnly = true;
      };

      # Homelab hosts use the personal key
      cobalto = {
        HostName = "100.69.115.53";
        IdentityFile = keys.diego;
      };
      "rubi lonsdaleita *.mineral.network" = {
        IdentityFile = keys.diego;
      };

      "github.com" = {
        User = "git";
        IdentityFile = keys.github;
      };

      # Work / Omnistation teleport clusters use the work key
      "*.teleport.sh" = {
        IdentityFile = keys.work;
      };
    };
  };

  # SSH agent with SSH_AUTH_SOCK exported in nushell (sshAuthSock handles it).
  services.ssh-agent.enable = true;

  # Register all keys into the agent at login (Linux).
  systemd.user.services.ssh-add = mkIf hasSystemd {
    Unit = {
      Description = "Register SSH keys into the agent at login";
      After = [ "ssh-agent.service" ];
      Requires = [ "ssh-agent.service" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
      ExecStart = addAllScript;
    };
  };

  # Same on macOS via launchd.
  launchd.agents.ssh-add = mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      RunAtLoad = true;
      ProgramArguments = [ (toString addAllScript) ];
    };
  };

  # nu helper: re-register all keys on demand (no restart needed).
  programs.nushell.extraConfig = ''
    # Add every SSH key to the agent
    def ssh-add-all [] {
    ${concatStringsSep "\n" (mapAttrsToList (name: path: "    ssh-add ${path}") keys)}
    }
  '';
}
