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
      compaction.model = "groq/llama-3.1-8b-instant";
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

  agents = {
    hephaestus = {
      model = "opencode/big-pickle";
      allow_non_gpt_model = true;
    };
    sisyphus = {
      model = "opencode/big-pickle";
      allow_non_gpt_model = true;
    };
    "sisyphus-junior" = {
      model = "groq/llama-3.3-70b-versatile";
      allow_non_gpt_model = true;
    };
    build = {
      model = "opencode/big-pickle";
      allow_non_gpt_model = true;
    };
    plan = {
      model = "opencode/big-pickle";
      allow_non_gpt_model = true;
    };
    "OpenCode-Builder" = {
      model = "opencode/big-pickle";
      allow_non_gpt_model = true;
    };
    prometheus = {
      model = "groq/llama-3.3-70b-versatile";
      allow_non_gpt_model = true;
    };
    metis = {
      model = "groq/llama-3.3-70b-versatile";
      allow_non_gpt_model = true;
    };
    momus = {
      model = "groq/llama-3.3-70b-versatile";
      allow_non_gpt_model = true;
    };
    oracle = {
      model = "groq/llama-3.3-70b-versatile";
      allow_non_gpt_model = true;
    };
  };
}
