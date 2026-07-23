{
  config,
  lib,
  pkgs,
  ...
}:
let
  # graphify (graphifyy on PyPI) — turns a folder of code/docs/media into a
  # queryable knowledge graph. Provides the `graphify` CLI and bundles the
  # /graphify skill files. Packaged in nixpkgs as `graphify`.
  graphify = pkgs.graphify;

  # The package bundles the canonical skill at
  #   <site-packages>/graphify/skill.md
  # Lay it out as a standard <dir>/<name>/SKILL.md tree so it can be consumed
  # by programs.ai-skills.extraSkillSources (which expects <name>/SKILL.md).
  graphifySkillSrc = pkgs.runCommand "graphify-skill-src" { } ''
    mkdir -p "$out/graphify"
    skill="$(find ${graphify}/lib -type f -name skill.md -path '*/graphify/*' | head -1)"
    if [ -z "$skill" ]; then
      echo "graphify.nix: could not locate bundled skill.md in ${graphify}" >&2
      exit 1
    fi
    cp "$skill" "$out/graphify/SKILL.md"
  '';
in
{
  # CLI on PATH (declarative, immutable via the Nix store).
  home.packages = [ graphify ];

  # Distribute the /graphify skill to all AI tools through the existing
  # ai-skills merged-staging pipeline (opencode + profiles, codex, claude,
  # cursor, antigravity). This survives rebuilds; do NOT use `graphify install`
  # imperatively, as it writes into Nix-managed skill dirs that are wiped and
  # regenerated on every activation.
  programs.ai-skills.extraSkillSources = [ "${graphifySkillSrc}" ];
}
