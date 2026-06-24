# Centralized AI skills sourced from the Obsidian vault.
# Single source of truth: <vaultSkillsDir>/<skill-name>/SKILL.md
# Symlinked into OpenCode + Claude Code (native SKILL.md); derived into
# Cursor rules + Antigravity AGENTS.md (best-effort) at activation time.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.ai-skills;
  coreutils = pkgs.coreutils;
in
{
  options.programs.ai-skills = {
    enable = lib.mkEnableOption "Centralized AI skills sourced from the Obsidian vault";

    vaultSkillsDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Notes/AI/Skills";
      description = "Canonical skills directory. Each skill is <name>/SKILL.md.";
    };

    tools = {
      opencode = lib.mkEnableOption "wire skills into OpenCode" // {
        default = true;
      };
      claude = lib.mkEnableOption "wire skills into Claude Code" // {
        default = true;
      };
      cursor = lib.mkEnableOption "wire skills into Cursor" // {
        default = true;
      };
      antigravity = lib.mkEnableOption "wire skills into Antigravity" // {
        default = true;
      };
    };

    opencodeProfiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "OpenCode profile names whose skills dir should also symlink to the vault.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.aiSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      SRC="${cfg.vaultSkillsDir}"
      if [ ! -d "$SRC" ]; then
        echo "ai-skills: vault skills dir $SRC missing — skipping" >&2
      else
        link_dir() {
          target="$1"
          ${coreutils}/bin/mkdir -p "$(${coreutils}/bin/dirname "$target")"
          if [ -e "$target" ] && [ ! -L "$target" ]; then
            ${coreutils}/bin/mv "$target" "$target.bak" 2>/dev/null || ${coreutils}/bin/rm -rf "$target"
          fi
          ${coreutils}/bin/ln -sfn "$SRC" "$target"
        }
        ${lib.optionalString cfg.tools.opencode ''
          link_dir "$HOME/.config/opencode/skills"
        ''}
        ${lib.concatMapStringsSep "\n" (p: ''
          link_dir "$HOME/.config/opencode-profiles/${p}/opencode/skills"
        '') cfg.opencodeProfiles}
        ${lib.optionalString cfg.tools.claude ''
          link_dir "$HOME/.claude/skills"
        ''}
        ${lib.optionalString cfg.tools.cursor ''
          RULES_DIR="$HOME/.cursor/rules"
          ${coreutils}/bin/mkdir -p "$RULES_DIR"
          for d in "$SRC"/*/; do
            [ -f "$d/SKILL.md" ] || continue
            name="$(${coreutils}/bin/basename "$d")"
            ${coreutils}/bin/cp -f "$d/SKILL.md" "$RULES_DIR/$name.mdc"
          done
        ''}
        ${lib.optionalString cfg.tools.antigravity ''
          AG="$HOME/.gemini/AGENTS.md"
          ${coreutils}/bin/mkdir -p "$(${coreutils}/bin/dirname "$AG")"
          : > "$AG"
          for d in "$SRC"/*/; do
            [ -f "$d/SKILL.md" ] || continue
            name="$(${coreutils}/bin/basename "$d")"
            printf '## %s\n\n' "$name" >> "$AG"
            ${coreutils}/bin/cat "$d/SKILL.md" >> "$AG"
            printf '\n\n' >> "$AG"
          done
        ''}
      fi
    '';
  };
}
