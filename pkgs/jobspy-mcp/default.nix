{ pkgs, ... }:

let
  # jobspy metadata check fails under Python 3.14 (importlib.metadata can't
  # find the dist-info). Pin to 3.12 where it builds cleanly.
  python = pkgs.python312.withPackages (ps: [
    (ps.jobspy.overridePythonAttrs (_: {
      pythonRelaxDeps = true;
    }))
  ]);
in
pkgs.stdenv.mkDerivation {
  pname = "jobspy-mcp";
  version = "1.0.0";
  src = ./jobspy_mcp_server.py;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin $out/lib
    cp $src $out/lib/jobspy_mcp_server.py
    chmod +x $out/lib/jobspy_mcp_server.py
    makeWrapper ${python}/bin/python $out/bin/jobspy-mcp \
      --add-flags "$out/lib/jobspy_mcp_server.py"
  '';

  nativeBuildInputs = [ pkgs.makeWrapper ];

  meta = {
    description = "MCP server for job searching via JobSpy (LinkedIn, Indeed, Google Jobs)";
    homepage = "https://github.com/Bunsly/JobSpy";
    license = pkgs.lib.licenses.mit;
    maintainers = [ ];
    platforms = pkgs.lib.platforms.linux;
  };
}
