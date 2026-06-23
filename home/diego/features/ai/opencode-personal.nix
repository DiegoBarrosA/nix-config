# Shared "personal" OpenCode definition (Big Pickle + Groq + agent map).
# Imported as data: let personal = import ./opencode-personal.nix; in ...
{
  config = {
    model = "opencode/big-pickle";
    small_model = "groq/llama-3.1-8b-instant";
    provider.groq = {
      npm = "@ai-sdk/openai-compatible";
      name = "Groq";
      options = {
        baseURL = "https://api.groq.com/openai/v1";
        apiKey = "{env:GROQ_API_KEY}";
      };
      models = {
        "llama-3.3-70b-versatile" = {
          name = "Llama 3.3 70B";
        };
        "llama-3.1-8b-instant" = {
          name = "Llama 3.1 8B Instant";
        };
        "qwen/qwen3-32b" = {
          name = "Qwen 3 32B";
        };
      };
    };
    agent = {
      title.model = "groq/llama-3.1-8b-instant";
      summary.model = "groq/llama-3.1-8b-instant";
      compaction.model = "opencode/big-pickle";
      explore.model = "groq/llama-3.3-70b-versatile";
      librarian.model = "groq/llama-3.3-70b-versatile";
      oracle.model = "groq/llama-3.3-70b-versatile";
      prometheus.model = "groq/llama-3.3-70b-versatile";
      metis.model = "groq/llama-3.3-70b-versatile";
      momus.model = "groq/llama-3.3-70b-versatile";
      plan.model = "opencode/big-pickle";
      build.model = "opencode/big-pickle";
      general.model = "opencode/big-pickle";
    };
  };
}
