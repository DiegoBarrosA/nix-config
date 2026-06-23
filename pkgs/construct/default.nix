{
  buildPythonPackage,
  fetchPypi,
  lib,
  setuptools,
}:

buildPythonPackage rec {
  pname = "construct";
  version = "2.8.8";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-G4S4FH9v0VvPZLc3w+isUQCBGtgMgwy0slRRQFEcQVc=";
  };

  build-system = [ setuptools ];

  pythonImportsCheck = [ "construct" ];

  meta = {
    description = "Powerful declarative parser (and builder) for binary data";
    homepage = "https://construct.readthedocs.org/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
  };
}
