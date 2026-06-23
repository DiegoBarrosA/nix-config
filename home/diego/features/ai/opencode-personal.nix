# Shared "personal" OpenCode definition (Big Pickle + local LLM).
# Imported as data: let personal = import ./opencode-personal.nix; in ...
# rubi overrides title/summary/compaction to local-llm in rubi.nix.
{
  config = {
    model = "opencode/big-pickle";
    small_model = "opencode/big-pickle";
    agent = {
      title.model = "opencode/big-pickle";
      summary.model = "opencode/big-pickle";
      compaction.model = "opencode/big-pickle";
      explore.model = "opencode/big-pickle";
      librarian.model = "opencode/big-pickle";
      oracle.model = "opencode/big-pickle";
      prometheus.model = "opencode/big-pickle";
      metis.model = "opencode/big-pickle";
      momus.model = "opencode/big-pickle";
      plan.model = "opencode/big-pickle";
      build.model = "opencode/big-pickle";
      general.model = "opencode/big-pickle";
    };
  };
}
