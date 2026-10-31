{ inputs, ... }:
{
  flake.modules.nixos.ai-hermes-profiles =
    { config, lib, pkgs, ... }:
    let
      cfg = config.services.hermes-agent;
      # Same deep-merge the Hermes module uses for its own config.yaml: Nix keys
      # win, keys Hermes or the user added stay.
      merge = import "${inputs.hermes-agent}/nix/configMergeScript.nix" { inherit pkgs; };
      home = "${cfg.stateDir}/.hermes";

      script = name: p: ''
        d=${home}/profiles/${name}
        # Create fails if the profile exists or the CLI cannot run yet; neither may fail the deploy
        # (a failed unit rolls it back). install -d then guarantees the layout, and the next run retries create.
        ${cfg.package}/bin/hermes profile create "${name}" --no-skills || true
        install -d -m 0750 "$d"
        install -m 0640 ${p.soul} "$d/SOUL.md"
        ${merge} ${pkgs.writeText "hermes-profile-${name}.json" (builtins.toJSON p.settings)} "$d/config.yaml"
      '';
    in
    {
      options.services.hermes-agent.profiles = lib.mkOption {
        default = { };
        description = "Declarative Hermes profiles: a persona file and config.yaml settings per name.";
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            soul = lib.mkOption { type = lib.types.path; description = "File installed as the profile's SOUL.md."; };
            settings = lib.mkOption { type = lib.types.attrs; default = { }; description = "Deep-merged into the profile's config.yaml."; };
            readOnly = lib.mkOption { type = lib.types.bool; default = false; description = "Marker read by flake checks (not an enforced guard): the profile is meant to be read-only."; };
          };
        });
      };

      # Off until the key exists: a declared sops secret with no key in the file
      # breaks the build. Diego adds the key `hermes-security-terms` to
      # hosts/cobalto/secrets.yaml, then sets this to true.
      options.services.hermes-agent.securityTermsSecret = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Declare the sops secret hermes-security-terms read by the security profile.";
      };

      # The name type is a separate check so a bad name fails with a clear message.
      config = lib.mkIf (cfg.profiles != { }) {
        assertions = lib.mapAttrsToList (n: _: {
          assertion = builtins.match "[a-z0-9][a-z0-9-]*" n != null;
          message = "services.hermes-agent.profiles.${n}: name must match ^[a-z0-9][a-z0-9-]*$";
        }) cfg.profiles;

        sops.secrets.hermes-security-terms = lib.mkIf cfg.securityTermsSecret {
          group = "hermes";
          mode = "0440";
        };

        # Runs before the gateway so profiles exist at start. It only writes SOUL.md
        # and config.yaml, so kanban.db, sessions and memories are never touched.
        systemd.services.hermes-profiles = {
          wantedBy = [ "multi-user.target" ];
          before = [ "hermes-agent.service" ];
          unitConfig.RequiresMountsFor = [ cfg.stateDir ];
          environment.HERMES_HOME = home;
          path = [ pkgs.coreutils ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = cfg.user;
            Group = cfg.group;
          };
          script = lib.concatStringsSep "\n" (lib.mapAttrsToList script cfg.profiles);
        };
      };
    };
}
