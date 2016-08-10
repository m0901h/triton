{ stdenv
, fetchurl
, file
, python2
, rustc_bootstrap

, jemalloc
, libffi
, llvm
, ncurses
, zlib

, channel ? "stable"
}:

let
  sources = import ./sources.nix {
    inherit fetchurl;
  };

  inherit (sources."${channel}")
    src
    srcVerification
    version;
in
stdenv.mkDerivation {
  name = "rustc-${version}";

  inherit src;

  nativeBuildInputs = [
    file
    python2
  ];

  buildInputs = [
    ncurses
    zlib
  ];

  prePatch = ''
    # Fix not filtering out -L lines from llvm-config
    sed -i '\#if len(lib) == 1#a\        continue\n    if lib[0:2] == "-L":' src/etc/mklldeps.py
  '';

  configureFlags = [
    "--disable-docs"
    "--enable-local-rust"
    "--local-rust-root=${rustc_bootstrap}"
    "--llvm-root=${llvm}"
    "--jemalloc-root=${jemalloc}/lib"
  ];

  # Fix an issues with gcc6
  NIX_CFLAGS_COMPILE = "-Wno-error";

  NIX_LDFLAGS = "-L${libffi}/lib -lffi";

  passthru = {
    inherit srcVerification;
  };

  meta = with stdenv.lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}