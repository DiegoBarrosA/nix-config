{ config, inputs, ... }:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  hermes = config.flake.nixosConfigurations.cobalto.config.services.hermes-agent;
in
{
  # Hermes must have one path for code work: the claude-<name> CLI. A generated
  # AGENTS.md that points at delegate_task caused the failed handover of 2026-10-29.
  flake.checks.x86_64-linux.hermes-agents-md =
    pkgs.runCommand "hermes-agents-md"
      {
        agentsMd = hermes.documents."AGENTS.md";
        disabled = builtins.toJSON hermes.settings.agent.disabled_toolsets;
        passAsFile = [ "agentsMd" ];
      }
      ''
        # Only the "Never use ..." rule may name these tools.
        if grep -nE 'delegate_task|execute_code|acp_command' "$agentsMdPath" | grep -v 'Never use'; then
          echo "AGENTS.md points at delegate_task, execute_code or acp_command for code work" >&2
          exit 1
        fi
        for t in delegation code_execution; do
          echo "$disabled" | grep -q "\"$t\"" || { echo "agent.disabled_toolsets lacks $t" >&2; exit 1; }
        done
        touch $out
      '';

  # Profile names become directory names and CLI arguments, and each soul is
  # copied at boot: a bad name or missing file must fail at build time.
  flake.checks.x86_64-linux.hermes-profiles-names =
    let
      names = builtins.attrNames hermes.profiles;
      bad = builtins.filter (n: builtins.match "[a-z0-9][a-z0-9-]*" n == null) names;
      missing = builtins.filter (n: !builtins.pathExists hermes.profiles.${n}.soul) names;
    in
    assert bad == [ ] || throw "bad hermes profile names: ${toString bad}";
    assert missing == [ ] || throw "hermes profile soul missing: ${toString missing}";
    pkgs.runCommand "hermes-profiles-names" { } "touch $out";

  # A read-only profile must not get a shell or a path to other agents, and only
  # the integrator may carry credentials: both are cheap to break by a config edit.
  flake.checks.x86_64-linux.hermes-profiles-readonly =
    let
      lib = inputs.nixpkgs.lib;
      # Read-only profiles that may still list `terminal` (Task 6 adds "security").
      terminalAllowed = [ ];
      # Every attribute name under a value, at any depth (lists are not walked).
      keys = v: if builtins.isAttrs v then lib.concatLists (lib.mapAttrsToList (k: x: [ k ] ++ keys x) v) else [ ];
      # shortcut: plain attrs only, a key hidden inside a list of attrsets is missed; fine for current settings shape.
      get = p: path: lib.attrByPath path [ ] hermes.profiles.${p}.settings;
      names = builtins.attrNames hermes.profiles;
      ro = builtins.filter (n: hermes.profiles.${n}.readOnly) names;
      errs =
        (map (n: "${n}: readOnly profile lists terminal in platform_toolsets.cli")
          (builtins.filter (n: builtins.elem "terminal" (get n [ "platform_toolsets" "cli" ]) && !builtins.elem n terminalAllowed) ro))
        ++ lib.concatMap (n:
          map (t: "${n}: readOnly profile does not disable ${t}")
            (builtins.filter (t: !builtins.elem t (get n [ "agent" "disabled_toolsets" ])) [ "delegation" "code_execution" ])) ro
        ++ lib.concatMap (n:
          map (k: "${n}: credential-like key '${k}' in settings (only integrator may have one)")
            (builtins.filter (k: lib.hasInfix "credential" (lib.toLower k) || lib.hasInfix "token" (lib.toLower k))
              (keys hermes.profiles.${n}.settings)))
          (builtins.filter (n: n != "integrator") names);
    in
    assert errs == [ ] || throw "hermes-profiles-readonly: ${lib.concatStringsSep "; " errs}";
    pkgs.runCommand "hermes-profiles-readonly" { } "touch $out";
}
