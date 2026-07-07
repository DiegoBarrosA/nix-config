# codex-acp 0.16.0 — ACP-compatible Codex agent for Zed.
#
# The nixpkgs codex-acp (0.13.0) bundles codex-core rust-v0.128.0, far behind
# the local `codex` CLI (0.142.x). That stale core doesn't know current models
# (e.g. gpt-5.6-sol) and uses an old auth/WebSocket path that an enterprise
# ChatGPT workspace rejects with 401 "not authorized in this region". This
# builds v0.16.0 (codex-core rust-v0.137.0) which is much closer to the CLI.
#
# Adapted from the upstream nixpkgs derivation (pkgs/by-name/co/codex-acp),
# with version, source hash, cargoHash, codex-core rev/hash, and librusty_v8
# bumped for v0.16.0.
{
  lib,
  stdenv,
  callPackage,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  perl,
  openssl,
  libcap,
  bubblewrap,
  librusty_v8 ? callPackage ./librusty_v8.nix { },
}:
let
  # codex-acp 0.16.0 pins openai/codex rust-v0.137.0 in Cargo.lock.
  codexRev = "f221438b691b8f749d98f22077c93ebe01923fbe";
  codexHash = "sha256-puszZqi1lZeq8iXWAD9U9+WMnNvzMYKf6wVT9mtjSUU=";
  codexSrc = fetchFromGitHub {
    owner = "openai";
    repo = "codex";
    rev = codexRev;
    hash = codexHash;
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "codex-acp";
  version = "0.16.0";

  src = fetchFromGitHub {
    owner = "zed-industries";
    repo = "codex-acp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-LeD3nHvRWX4ZgZ3/fVngDcR6/LtaY4eb2M2WmWaymlY=";
  };

  cargoHash = "sha256-ea3XyOaSshvv3oD4rm37nE76ABTbSv1y/s7HX2fqNRk=";

  # fetchCargoVendor only keeps the individual git crate subtrees. Codex crates
  # include this workspace-root file from codex-core.
  #
  # Also patch the session source: codex-acp passes SessionSource::Unknown to
  # ThreadManager, which makes codex-core send an originator the enterprise
  # ChatGPT workspace rejects (401 "not authorized in this region"). The stock
  # `codex` CLI uses SessionSource::Cli (originator "codex_cli_rs"), which the
  # workspace authorizes — so mirror that. Only the ThreadManager call site
  # (the live session) is rewritten, not the enum-variant references.
  postPatch = ''
    if [ -e ${codexSrc}/codex-rs/node-version.txt ]; then
      cp ${codexSrc}/codex-rs/node-version.txt "$cargoDepsCopy/source-git-0/node-version.txt"
    fi
    # Rewrite ONLY the ThreadManager::new call site (the live session's source)
    # from Unknown -> Cli, so codex-core sends the "codex_cli_rs" originator the
    # enterprise ChatGPT workspace authorizes (fixes 401 "not authorized in this
    # region"). The call site is uniquely identified by the following
    # `environment_manager,` argument; enum-variant references elsewhere are
    # left untouched. Fail loudly if the pattern is missing (upstream drift).
    perl -0777 -i -pe \
      's/SessionSource::Unknown,(\s*\n\s*environment_manager,)/SessionSource::Cli,$1/ or die "codex-acp postPatch: ThreadManager SessionSource pattern not found\n"' \
      src/codex_agent.rs
  '';

  env = {
    RUSTY_V8_ARCHIVE = librusty_v8;
  }
  // lib.optionalAttrs stdenv.hostPlatform.isLinux {
    CODEX_BWRAP_SOURCE_DIR = "${bubblewrap.src}";
  };

  nativeBuildInputs = [
    pkg-config
    perl
  ];

  buildInputs = [
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ libcap ];

  doCheck = false;

  meta = {
    description = "An ACP-compatible coding agent powered by Codex (0.16.0, codex-core rust-v0.137.0)";
    homepage = "https://github.com/zed-industries/codex-acp";
    changelog = "https://github.com/zed-industries/codex-acp/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    mainProgram = "codex-acp";
  };
})
