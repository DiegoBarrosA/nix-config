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
}
