{
  calibre,
  fetchFromGitLab,
  ffmpeg-headless,
  iso639-lang,
  lib,
  python3Packages,
  calibreSupport ? true,
  ffmpegSupport ? true,
}:
python3Packages.buildPythonApplication {
  pname = "lazylibrarian";
  version = "2025.09.16-unstable-2026-04-30";
  pyproject = true;

  src = fetchFromGitLab {
    owner = "LazyLibrarian";
    repo = "LazyLibrarian";
    rev = "322dba1ebc323274fb4a2a615597dad71d7856af";
    hash = "sha256-Kr6fOkIbQffxH1KDNuYzwB1ZgI8i/tc08gvyyNWRRW4=";
  };

  postPatch = ''
    mkdir -p src
    mv LazyLibrarian.py lazylibrarian lib data src

    cat > MANIFEST.in << 'EOF'
recursive-include src/data *
EOF

    python3 << 'PYEOF'
import re

with open('pyproject.toml', 'r') as f:
    content = f.read()

# Remove ez_setup from requires
content = content.replace('"ez_setup"', "")
content = content.replace(", ,", ",")
content = content.replace("[,", "[")

# Remove [tool.setuptools.packages.find] section
content = re.sub(r'\[tool\.setuptools\.packages\.find\]\nwhere = \["lazylibrarian"\]\n', "", content)

# Fix bs4 → beautifulsoup4
content = content.replace("'bs4'", "'beautifulsoup4'")

# Remove slskd_api line (not packaged in nixpkgs, optional Soulseek support)
content = re.sub(r"\s+'slskd_api',\n", "\n", content)

# iso639-lang stays as-is - provided by our custom package

# Add console_scripts entry point after [project.urls]
content = content.replace(
    "[project.urls]",
    "[project.scripts]\nlazylibrarian = \"LazyLibrarian:main\"\n\n[project.urls]",
    1
)

with open('pyproject.toml', 'w') as f:
    f.write(content)
PYEOF
  '';

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies =
    with python3Packages;
    [
      apprise
      apscheduler
      beautifulsoup4
      cherrypy
      cherrypy-cors
      deluge-client
      html5lib
      httpagentparser
      httplib2
      irc
      lxml
      mako
      pillow
      pyopenssl
      pyparsing
      pypdf
      python-magic
      rapidfuzz
      requests
      tzdata
      urllib3
      webencodings
      xmltodict
    ]
    ++ [ iso639-lang ]
    ++ lib.optionals calibreSupport [ calibre ]
    ++ lib.optionals ffmpegSupport [ ffmpeg-headless ];

  pythonImportsCheck = [
    "lazylibrarian"
  ];

  makeWrapperArgs = [
    "--set" "DOCKER" "1"
    "--add-flags" "--datadir=\\$XDG_DATA_HOME/lazylibrarian"
  ];

  meta = {
    description = "Usenet/BitTorrent ebook, audiobook and magazine downloader";
    homepage = "https://lazylibrarian.gitlab.io/";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "lazylibrarian";
  };
}
