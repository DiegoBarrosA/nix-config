{ config, inputs, ... }:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  lib = inputs.nixpkgs.lib;
  hermes = config.flake.nixosConfigurations.cobalto.config.services.hermes-agent;
  # Closed list of team roles: later tasks declare the rest.
  roles = [ "planner" "coder-light" "coder-heavy" "reviewer" "tester" "security" "integrator" ];
in
{
  # Hermes must have one path for code work: the claude-<name> CLI. A generated
  # AGENTS.md that points at delegate_task caused the failed handover of 2026-10-29.
  flake.checks.x86_64-linux.hermes-agents-md =
    pkgs.runCommand "hermes-agents-md"
      {
        agentsMd = hermes.documents."AGENTS.md";
        disabled = builtins.toJSON hermes.settings.agent.disabled_toolsets;
        declared = lib.concatStringsSep "\n" (builtins.attrNames hermes.profiles);
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
        # A role named in backticks that no profile declares sends a card to nobody.
        for r in ${lib.concatStringsSep " " roles}; do
          if grep -q "\`$r\`" "$agentsMdPath" && ! echo "$declared" | grep -qx "$r"; then
            echo "AGENTS.md mentions role $r, which is not a declared profile" >&2
            exit 1
          fi
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
      # Read-only profiles that may still list `terminal`: security runs gitleaks and grep,
      # and its prompt limits it to those two. The missing-cli rule still applies.
      terminalAllowed = [ "security" ];
      # Every attribute name under a value, at any depth, through lists too (fallback_providers is a list of attrsets).
      keys = v:
        if builtins.isAttrs v then lib.concatLists (lib.mapAttrsToList (k: x: [ k ] ++ keys x) v)
        else if builtins.isList v then lib.concatMap keys v
        else [ ];
      get = p: path: lib.attrByPath path [ ] hermes.profiles.${p}.settings;
      names = builtins.attrNames hermes.profiles;
      ro = builtins.filter (n: hermes.profiles.${n}.readOnly) names;
      # An unset cli list falls back to Hermes's hermes-cli preset, which includes terminal.
      cliOk = n: builtins.isList (lib.attrByPath [ "platform_toolsets" "cli" ] null hermes.profiles.${n}.settings);
      errs =
        (map (n: "${n}: readOnly profile must set platform_toolsets.cli to a list (the default preset includes terminal)")
          (builtins.filter (n: !cliOk n) ro))
        ++ (map (n: "${n}: readOnly profile lists terminal in platform_toolsets.cli")
          (builtins.filter (n: cliOk n && builtins.elem "terminal" (get n [ "platform_toolsets" "cli" ]) && !builtins.elem n terminalAllowed) ro))
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

  # The security gate is a script because a weak model cannot be trusted to run
  # shell pipelines. Synthetic terms only: no real term may appear in the repo.
  flake.checks.x86_64-linux.hermes-security-scan =
    pkgs.runCommand "hermes-security-scan"
      { nativeBuildInputs = [ pkgs.git pkgs.gitleaks (import ../pkgs/hermes-security-scan.nix pkgs) ]; }
      ''
        export HOME=$PWD GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
        git init -q repo && cd repo
        printf "hello\n" > a.txt
        git add a.txt && git commit -qm base && git tag base
        printf "world\n" >> a.txt
        git commit -qam clean
        printf "ZZZ-fake-term-one\r\nYYY-fake-term-two\r\n" > ../terms
        export HERMES_SECURITY_TERMS=$PWD/../terms

        # run NAME EXPECTED_RC ARGS...: output lands in ../out
        run() {
          want=$1; shift
          set +e; hermes-security-scan "$@" > ../out 2>&1; rc=$?; set -e
          [ "$rc" = "$want" ] || { echo "FAIL: $* gave $rc, wanted $want"; cat ../out; exit 1; }
        }

        run 0 diff base
        grep -q "terms=2 matches=0" ../out

        printf "x\nzzz-FAKE-term-ONE here\n" >> a.txt
        git commit -qam dirty
        run 1 diff base
        grep -q "^a.txt:4\$" ../out
        if grep -qi "fake-term" ../out; then echo "FAIL: term text printed"; exit 1; fi

        # CRLF term (the second one) still matches
        printf "yyy-fake-TERM-two\n" > b.txt
        git add b.txt && git commit -qm crlf
        run 1 diff base
        grep -q "^b.txt:1\$" ../out
        run 1 history
        if grep -qi "fake-term" ../out; then echo "FAIL: term text printed"; exit 1; fi

        run 3 diff no-such-ref
        HERMES_SECURITY_TERMS=/nonexistent run 3 diff base
        printf "\n  \r\n\n" > ../blank
        HERMES_SECURITY_TERMS=$PWD/../blank run 3 diff base
        touch $out
      '';
}
