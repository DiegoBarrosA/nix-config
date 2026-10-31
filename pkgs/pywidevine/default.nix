{
  buildPythonPackage,
  fetchPypi,
  lib,
  poetry-core,
  protobuf6,
  pymp4,
  pycryptodome,
  click,
  requests,
  unidecode,
  pyyaml,
  aiohttp,
  shaka-packager,
  makeWrapper,
  callPackage,
}:

buildPythonPackage rec {
  pname = "pywidevine";
  version = "1.9.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-Z0La9f15fFpIE+sTAO+zGB/83dDIxHjuKMfFNqoOUbI=";
  };

  build-system = [ poetry-core ];

  dependencies = [
    protobuf6
    pymp4
    pycryptodome
    click
    requests
    unidecode
    pyyaml
  ];

  optional-dependencies = {
    serve = [ aiohttp ];
  };

  pythonImportsCheck = [ "pywidevine" ];

  postFixup = ''
    wrapProgram $out/bin/pywidevine --prefix PATH : ${lib.makeBinPath [ shaka-packager ]}
  '';

  meta = {
    description = "Widevine CDM implementation in Python";
    homepage = "https://github.com/devine-dl/pywidevine";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ ];
  };
}
