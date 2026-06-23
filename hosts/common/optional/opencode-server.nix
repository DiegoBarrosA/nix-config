# OpenCode HTTP server
# Provides the OpenCode API server for remote clients (Android app, web UI)
# and the built-in web interface via `opencode web`.
#
# Usage:
#   services.opencode-server = {
#     enable = true;
#     host = "0.0.0.0";   # bind all interfaces (Tailsecured)
#     port = 4096;
#     secretEnv = {
#       OPENCODE_API_KEY = "/run/secrets/opencode-api-key";
#       NVIDIA_API_KEY = "/run/secrets/nvidia-api-key";
#     };
#   };
#
# The server uses Basic Auth via OPENCODE_SERVER_PASSWORD.
# Set passwordFile to a SOPS-managed file containing the password.
#
# API docs: http://<host>:<port>/doc
# Web UI:   http://<host>:<port>
# Android:  https://github.com/giuliastro/opencode-remote-android

{ config, lib, pkgs, ... }:

let
  cfg = config.services.opencode-server;
in
{
  options.services.opencode-server = {
    enable = lib.mkEnableOption "OpenCode HTTP server (API + web UI)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.opencode;
      defaultText = lib.literalExpression "pkgs.opencode";
      description = "The opencode package to use.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address to bind the server to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4096;
      description = "Port for the OpenCode server.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "diego";
      description = "User to run the server as.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall port.";
    };

    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a file containing the OpenCode server password.
        Used as OPENCODE_SERVER_PASSWORD for Basic Auth.
        Typically set to a SOPS secret path like /run/secrets/opencode-server-password.
        The username defaults to "opencode", configurable via OPENCODE_SERVER_USERNAME.
      '';
    };

    secretEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        Map of environment variable names to secret file paths.
        Each file's contents will be exported as the corresponding env var.
        Example: { OPENCODE_API_KEY = "/run/secrets/opencode-api-key"; }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.opencode-server = {
      description = "OpenCode HTTP Server (API + Web UI)";
      after = [ "network.target" "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
      wantedBy = [ "multi-user.target" ];

      path = [ cfg.package ];

      environment = {
        HOME = "/home/${cfg.user}";
        USER = cfg.user;
      };

      script = let
        secretEnvScript = lib.concatMapStringsSep "\n" (name: ''
          if [ -r "${cfg.secretEnv.${name}}" ]; then
            export ${name}="$(cat "${cfg.secretEnv.${name}}")"
          fi
        '') (lib.attrNames cfg.secretEnv);
      in ''
        ${lib.optionalString (cfg.passwordFile != null) ''
          export OPENCODE_SERVER_PASSWORD="$(cat ${cfg.passwordFile})"
        ''}
        ${secretEnvScript}
        exec ${cfg.package}/bin/opencode web \
          --hostname ${cfg.host} \
          --port ${toString cfg.port}
      '';

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        Restart = "on-failure";
        RestartSec = 10;
        WorkingDirectory = "/home/${cfg.user}";
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;
  };
}
