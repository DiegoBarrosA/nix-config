{ pkgs, ... }:
let
  thunderbird-mcp-extension = pkgs.stdenv.mkDerivation {
    name = "thunderbird-mcp-ext";
    src = "${pkgs.thunderbird-mcp.src}/dist/thunderbird-mcp.xpi";
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
      cp $src "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/thunderbird-mcp@tkasperczyk.dev.xpi"
    '';
  };
in
{
  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird-esr;
    profiles.default = {
      isDefault = true;
      extensions = [ thunderbird-mcp-extension ];
      settings = {
        # Auto-enable extensions without manual intervention
        "extensions.autoDisableScopes" = 0;
        # Allow unsigned extensions (required for experiment_apis used by thunderbird-mcp)
        "xpinstall.signatures.required" = false;
      };
    };
  };

  home.packages = with pkgs; [
    protonmail-bridge
  ];
}
