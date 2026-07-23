# SOPS secrets configuration for rubi (desktop)
# Minimal secrets needed for a desktop system
{
  config,
  lib,
  pkgs,
  inputs,
  self,
  ...
}:

with lib;

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = "${self}/hosts/${config.networking.hostName}/secrets.yaml";
    defaultSopsFormat = "yaml";
    age.keyFile = "/nix/persist/var/lib/sops-nix/key.txt";
    age.generateKey = false;

    # User password (hashed)
    secrets."diego-password" = {
      neededForUsers = true;
      owner = "root";
      group = "root";
      mode = "0600";
    };

    # Tailscale authentication key
    secrets."tailscale-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # LUKS passphrase (for reference/backup, actual unlock via TPM2/FIDO2)
    secrets."luks-passphrase" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."obsidian-api-key" = {
      owner = "diego";
      group = "users";
      mode = "0400";
    };

    # Work inference and Anthropic (anthropic-api-key) secrets are declared
    # by the customer module (private-config: the active customer's secrets
    # module), imported via nixosModules.work.

    # GitHub token (from private-config)
    secrets."github-token" = {
      owner = "diego";
      group = "users";
      mode = "0400";
      sopsFile = inputs.private-config.secretFiles.githubToken;
      key = "github_token"; # Key in YAML uses underscore
    };

    # CouchDB admin credentials for Obsidian LiveSync (matches cobalto CouchDB server)
    secrets."couchdb-admin-user" = {
      owner = "diego";
      group = "users";
      mode = "0400";
    };

    secrets."couchdb-admin-password" = {
      owner = "diego";
      group = "users";
      mode = "0400";
    };

    # E2EE passphrase for Obsidian LiveSync plugin
    secrets."obsidian-livesync-passphrase" = {
      owner = "diego";
      group = "users";
      mode = "0400";
    };

    # Groq free-tier API key (for personal `opp` profile)
    # Get from: https://console.groq.com/keys
    secrets."groq-api-key" = {
      owner = "diego";
      group = "users";
      mode = "0400";
    };

    # OpenCode API key (single key covers both Zen and Go providers)
    # See: https://opencode.ai/docs/zen — get the key from `opencode auth login opencode`
    # or from the dashboard at auth.opencode.ai
    secrets."opencode-api-key" = {
      owner = "diego";
      group = "users";
      mode = "0400";
    };

    # OpenCode server password for remote Android/web access
    # Used by services.opencode-server for Basic Auth
    secrets."opencode-server-password" = {
      owner = "diego";
      group = "users";
      mode = "0400";
    };
  };

  # Render the GitHub token into a nix.conf-format snippet so the nix daemon
  # can include it. Raw secret is just the token string; nix.conf needs the
  # "access-tokens = github.com=<token>" form.
  sops.templates."nix-github-access-token" = {
    content = "access-tokens = github.com=${config.sops.placeholder."github-token"}";
    path = "/etc/nix/github-access-token.conf";
    owner = "root";
    group = "root";
    mode = "0444";
  };
}
