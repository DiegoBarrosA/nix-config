{
  buildPythonPackage,
  fetchurl,
  lib,
  setuptools,
}:

buildPythonPackage rec {
  pname = "iso639-lang";
  version = "2.6.3";
  pyproject = true;

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/9b/5a/49bbf16d155192255e7bb37e403b2ac360144992d0d112a865afc62e457f/iso639_lang-${version}.tar.gz";
    hash = "sha256-B43bfNAYLcwENnaRrMgCLd9xWLbLCfCPeYr4I/qGQmU=";
  };

  build-system = [ setuptools ];

  pythonImportsCheck = [ "iso639" ];

  meta = {
    description = "ISO 639 language codes";
    homepage = "https://github.com/laurentb/iso639-lang";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
  };
}
