{
  buildPythonPackage,
  fetchPypi,
  lib,
  poetry-core,
  construct,
}:

buildPythonPackage rec {
  pname = "pymp4";
  version = "1.4.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-vJ53cyqKFD00w4qoYqVBgHFiRpOOS/PgdYXRklK3e7U=";
  };

  build-system = [ poetry-core ];

  dependencies = [ construct ];

  pythonImportsCheck = [ "pymp4" ];

  meta = {
    description = "MP4 file parser";
    homepage = "https://github.com/nicokoch/pymp4";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
  };
}
