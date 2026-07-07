# opencode-pixel-office — a pixel-art office dashboard for OpenCode/Claude Code.
# https://github.com/ddx-510/opencode-pixel-office
#
# Upstream ships a CLI installer (`opencode-pixel-office install`) that copies
# files into ~/.opencode and runs `npm install`. We bypass all of that and build
# declaratively instead:
#   * buildNpmPackage fetches deps from the committed package-lock.json,
#   * `npm run build:client` produces the Vite/PixiJS dashboard (client/dist),
#   * esbuild transpiles the single-file TS server to ESM so we can run it with
#     plain node at runtime (no `tsx` dependency in the runtime closure).
#
# Result exposes `bin/pixel-office-server`, which serves the dashboard and the
# /events + /ws endpoints on $PORT (default 5100). The home-manager module
# (pixel-office.nix) wires it up as a systemd user service + an OpenCode plugin.
{ pkgs }:
let
  version = "1.2.1";
in
pkgs.buildNpmPackage {
  pname = "opencode-pixel-office";
  inherit version;

  src = pkgs.fetchFromGitHub {
    owner = "ddx-510";
    repo = "opencode-pixel-office";
    rev = "v${version}";
    hash = "sha256-gCbd0IIuYU2aOyemr5Ve3GZh8kmnRC9SSL0K8yCCYCA=";
  };

  npmDepsHash = "sha256-2RfAY3SzWTjfDUMMlKqGQ14Ug05bmxFlozEgFTqujPM=";

  nativeBuildInputs = [
    pkgs.makeWrapper
    pkgs.esbuild
  ];

  # Vite writes to a cache dir during the build.
  makeCacheWritable = true;

  # `npm run build:client` → client/dist (the prebuilt dashboard).
  npmBuildScript = "build:client";

  # Transpile the single-file TS server to ESM, keeping node_modules imports
  # external so we can run it with plain `node` (no tsx at runtime).
  postBuild = ''
    esbuild server/index.ts --platform=node --format=esm --outfile=server/index.mjs
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/opencode-pixel-office/client
    cp -r server package.json node_modules $out/lib/opencode-pixel-office/
    cp -r client/dist $out/lib/opencode-pixel-office/client/dist

    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/pixel-office-server \
      --chdir $out/lib/opencode-pixel-office \
      --add-flags "$out/lib/opencode-pixel-office/server/index.mjs"

    runHook postInstall
  '';

  meta = {
    description = "Pixel-art office dashboard visualising OpenCode/Claude Code sessions";
    homepage = "https://github.com/ddx-510/opencode-pixel-office";
    license = pkgs.lib.licenses.mit;
    mainProgram = "pixel-office-server";
  };
}
