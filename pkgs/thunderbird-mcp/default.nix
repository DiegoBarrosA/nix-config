{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
}:

buildNpmPackage (finalAttrs: {
  pname = "thunderbird-mcp";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "TKasperczyk";
    repo = "thunderbird-mcp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-wewuXZV6tjSJ3gjmUkIoRFWwGbqVUc7xxEt1kp9dWSM=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  preInstall = "mkdir node_modules/";
  forceEmptyCache = true;
  dontNpmBuild = true;

  npmDepsHash = "sha256-GB9/6zdgVLrpQS2BXsy/Pkl/cSEBrZVQuT59lh8+yzA=";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "MCP server for Thunderbird - enables AI assistants to access email, contacts, and calendars";
    homepage = "https://github.com/TKasperczyk/thunderbird-mcp";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ drupol ];
    mainProgram = "thunderbird-mcp";
    platforms = lib.platforms.all;
  };
})
