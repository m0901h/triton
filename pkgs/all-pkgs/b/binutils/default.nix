{ stdenv
, bison
, fetchTritonPatch
, fetchurl
, flex
, gnum4

, gmp
, isl
, mpc
, mpfr
, zlib

, bootstrap ? false
}:

# WHEN UPDATING THE ARGUMENT LIST ALSO UPDATE STDENV.

let
  inherit (stdenv.lib)
    elem
    optional
    optionals
    optionalString;

  inherit (stdenv.lib.platforms)
    bit64;

  version = "2.27";
in
stdenv.mkDerivation rec {
  name = "${if bootstrap then "bootstrap-" else ""}binutils-${version}";

  src = fetchurl {
    url = "mirror://gnu/binutils/binutils-${version}.tar.bz2";
    sha256 = "369737ce51587f92466041a97ab7d2358c6d9e1b6490b3940eb09fb0a9a6ac88";
  };

  nativeBuildInputs = [
    bison
    flex
    gnum4
  ];

  buildInputs = [
    gmp
    isl
    mpc
    mpfr
    zlib
  ];

  patches = [
    (fetchTritonPatch {
      rev = "ba6793abd1c302421cc24007bf9e8b026d31d33b";
      file = "b/binutils/always-runpath.patch";
      sha256 = "8144e49930871f6b5c14ba9b4759ba56e873272b34782530df1d7061f77d8ea3";
    })
    (fetchTritonPatch {
      rev = "ba6793abd1c302421cc24007bf9e8b026d31d33b";
      file = "b/binutils/deterministic.patch";
      sha256 = "f215170d3d746ae8d4c3b9e1a56121b6ec2c9036810797a5cf6f2017d8313206";
    })
	];

  postPatch = ''
    # Make sure that we are not missing any determinism flags
    find . -name \*.orig -type f -delete
    if grep -r '& BFD_DETERMINISTIC_OUTPUT'; then
      echo "Found DETERMINISM flags" >&2
      exit 1
    fi
  '' + optionalString (zlib != null) ''
    # We don't want to use the built in zlib
    rm -rf zlib
  '' + ''
    # Use symlinks instead of hard links to save space ("strip" in the
    # fixup phase strips each hard link separately).
    # Also disable documentation generation
    find . -name Makefile.in -exec sed -i {} -e 's,ln ,ln -s ,g' -e 's,\(SUBDIRS.*\) doc,\1,g' \;
  '';

  configureFlags = [
    "--disable-werror"
    "--enable-gold=default"
    "--enable-ld"
    "--enable-compressed-debug-sections=all"
    "--with-sysroot=/no-such-path"
    "--with-lib-path=/no-such-path"
    "--${if !bootstrap then "enable" else "disable"}-shared"
    "--enable-deterministic-archives"
    "--enable-plugins"
  ] ++ optionals (zlib != null) [
    "--with-system-zlib"
  ] ++ optionals (elem stdenv.targetSystem bit64) [
    "--enable-64-bit-archive"
  ];

  preBuild = ''
    makeFlagsArray+=("tooldir=$out")
  '';

  ccFixFlags = !bootstrap;
  dontDisableStatic = bootstrap;

  passthru = {
    inherit version;
  };

  meta = with stdenv.lib; {
    description = "Tools for manipulating binaries (linker, assembler, etc.)";
    homepage = http://www.gnu.org/software/binutils/;
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
