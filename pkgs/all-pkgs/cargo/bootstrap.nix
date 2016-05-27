{ stdenv
, fetchurl
, makeWrapper

, rustc
, zlib
}:

let
  sources = {
    "${stdenv.lib.head stdenv.lib.platforms.x86_64-linux}" = {
      sha1 = "84266cf626ca4fcdc290bca8f1a74e6ad9e8b3d9";
      sha256 = "55ad9a8929303b4e06c18d0dd30b0d6296da784606d9c55cce98d5d7fc39a0b2";
      platform = "x86_64-unknown-linux-gnu";
    };
  };

  date = "2016-03-21";

  inherit (sources."${stdenv.targetSystem}")
    platform
    sha1
    sha256;
in
stdenv.mkDerivation {
  name = "cargo-bootstrap-${date}";

  src = fetchurl {
    url = "https://static.rust-lang.org/cargo-dist/${date}/cargo-nightly-${platform}.tar.gz";
    sha1Confirm = sha1;
    inherit sha256;
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p "$out"
    cp -r cargo/bin "$out/bin"
    patchelf --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" --set-rpath "${stdenv.cc.cc}/lib:${zlib}/lib" $out/bin/*
    wrapProgram $out/bin/cargo --prefix PATH : "${rustc}/bin"

    # Check that we can launch cargo
    $out/bin/cargo --help
  '';

  meta = with stdenv.lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
