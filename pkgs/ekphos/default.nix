{
  lib,
  pkgs,
  src,
}:
let
  cargoLock = builtins.fromTOML (builtins.readFile "${src}/Cargo.lock");

  cratePackages = builtins.filter (
    p: (p.source or "") == "registry+https://github.com/rust-lang/crates.io-index"
  ) cargoLock.package;

  crates =
    assert lib.all (p: p ? checksum) cratePackages;
    map (p: {
      name = p.name;
      version = p.version;
      checksum = p.checksum;

      tarball = pkgs.fetchurl {
        name = "crate-${p.name}-${p.version}.tar.gz";
        url = "https://static.crates.io/crates/${p.name}/${p.name}-${p.version}.crate";
        sha256 = p.checksum;
      };
    }) cratePackages;

  unpackedCrates = map (c:
    pkgs.runCommand "${c.name}-${c.version}" { } ''
      mkdir "$out"
      tar xf ${c.tarball} -C "$out" --strip-components=1
      printf '{"files":{},"package":"%s"}' "${c.checksum}" > "$out/.cargo-checksum.json"
    ''
  ) crates;

  vendorDir = pkgs.runCommand "ekphos-cargo-vendor-dir-0.25.10" { } ''
    mkdir -p $out/.cargo
    cp ${src}/Cargo.lock $out/Cargo.lock

    cat > $out/.cargo/config.toml <<'EOF'
    [source."crates-io"]
    "replace-with" = "vendored-sources"

    [source."vendored-sources"]
    "directory" = "@vendor@"
    EOF

    for crate in ${toString unpackedCrates}; do
      ln -s "$crate" "$out/$(basename "$crate" | cut -c 34-)"
    done
  '';
in
pkgs.rustPlatform.buildRustPackage {
  pname = "ekphos";
  version = "0.25.10";

  inherit src;

  cargoDeps = vendorDir;

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [

    libxcb
    libx11
    libxcursor
    libxrandr
    libxi
  ];

  meta = with lib; {
    description = "A lightweight, fast, terminal-based markdown research tool";
    homepage = "https://github.com/hanebox/ekphos";
    license = licenses.mit;
    mainProgram = "ekphos";
    platforms = platforms.linux;
  };
}