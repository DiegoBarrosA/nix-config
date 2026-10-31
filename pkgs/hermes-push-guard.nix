# Push guardrail for the agents' git credentials. Imported by hermes-agent.nix
# (credential helper and gh wrapper) and parts/checks.nix (the test); it lives
# outside parts/ because import-tree would load every .nix there as a module.
# The allowed list is baked in at build time, not read from the environment.
# This is a guardrail, not a boundary: an agent with a shell could set
# HERMES_PROFILE itself. It stops a card that runs `git push` by habit.
{
  pkgs,
  profiles,
  # Lines of "<host> <owner> <user> <tokenFile>".
  table ? "",
}:
rec {
  # Exit 0 when HERMES_PROFILE is unset or listed. Hermes chat leaves it unset.
  allowed = pkgs.writeShellScript "hermes-git-push-allowed" ''
    case "''${HERMES_PROFILE:-}" in
      ""${pkgs.lib.concatMapStrings (p: "|${pkgs.lib.escapeShellArg p}") profiles}) exit 0 ;;
    esac
    exit 1
  '';
  # Prints "<user> <token>" for a host and owner, or exits 1. Denied profiles get nothing.
  token = pkgs.writeShellScript "hermes-git-token" ''
    ${allowed} || exit 1
    host="$1" owner="''${2,,}"
    while read -r h o u f; do
      [ "$h" = "$host" ] && [ "$o" = "$owner" ] || continue
      # A missing or empty token file means no credential, not a blank password.
      token="$(${pkgs.coreutils}/bin/tr -d '[:space:]' < "$f" 2>/dev/null)" || exit 1
      [ -n "$token" ] || exit 1
      printf '%s %s' "$u" "$token"
      exit 0
    done <<'MAP'
    ${table}
    MAP
    exit 1
  '';
}
