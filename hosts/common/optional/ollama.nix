{
  services = {
    ollama = {
      enable = true;
      host = "127.0.0.1";
      port = 11111;
      acceleration = "rocm";
      openFirewall = true;
    };
    nextjs-ollama-llm-ui = {
      enable = true;
      ollamaUrl = "127.0.0.1:111111";

    };
  };
}
