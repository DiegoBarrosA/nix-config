{
  pkgs,
  ...
}:
{
  system.stateVersion = "24.05";

  # Phone LLM server: llama.cpp (llama-server) with Vulkan + CPU backends,
  # plus tooling for model downloads and debugging.
  environment.packages = [
    pkgs.llama-cpp-vulkan
    pkgs.curl
    pkgs.jq
    pkgs.git
    pkgs.ripgrep
    pkgs.openssh
  ];

  # Minimal home setup: shell env + server wrapper script.
  home-manager.config = { pkgs, ... }:
    let
      serverScript = pkgs.writeShellScriptBin "phone-llm-server" ''
        set -e
        : ''${MODEL_FILE:="$HOME/models/qwen3-8b-instruct-q4_k_m.gguf"}
        : ''${LLM_HOST:="0.0.0.0"}
        : ''${LLM_PORT:="8080"}
        : ''${LLM_CTX:="8192"}
        : ''${LLM_THREADS:="4"}

        if [ ! -f "$MODEL_FILE" ]; then
          echo "model not found: $MODEL_FILE" >&2
          echo "put a GGUF under $HOME/models/ or set MODEL_FILE" >&2
          exit 1
        fi

        exec llama-server \
          -m "$MODEL_FILE" \
          -c "$LLM_CTX" \
          -t "$LLM_THREADS" \
          --host "$LLM_HOST" \
          --port "$LLM_PORT" \
          "$@"
      '';
    in
    {
      home.packages = [ serverScript ];
      home.stateVersion = "24.05";
      # nix-on-droid release-24.05 pins home-manager 24.05 while our flake
      # follows nixos-unstable; the home config here is minimal so the
      # mismatch is harmless.
      home.enableNixpkgsReleaseCheck = false;

      home.sessionVariables = {
        LLM_HOST = "0.0.0.0";
        LLM_PORT = "8080";
      };

      programs.bash.enable = true;
      programs.bash.shellAliases = {
        llm-bench-cpu = "llama-bench -m $HOME/models/qwen3-8b-instruct-q4_k_m.gguf -t 4 -p 512 -n 128";
        llm-bench-gpu = "llama-bench -m $HOME/models/qwen3-8b-instruct-q4_k_m.gguf -ngl 99 -p 512 -n 128";
      };
    };

  # Official Nix-on-Droid binary cache is added by default in this release;
  # nothing extra needed here.
}
