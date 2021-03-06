{ stdenv
, fetchurl
, perl
, python

, apr
, apr-util
, cyrus-sasl
, expat
, file
, serf
, sqlite
, swig
, zlib

, channel
}:

let
  sources = {
    "1.8" = {
      version = "1.8.17";
      sha1Confirm = "0999f5e16b146f824b952a5552826b9cb5c47b13";
      sha256 = "de119538d29a5f2c028984cb54a55a4af3e9c32fa9316331bcbe5719e474a090";
    };
    "1.9" = {
      version = "1.9.5";
      sha1Confirm = "8bd6a44a1aed30c4c6b6b068488dafb44eaa6adf";
      sha256 = "8a4fc68aff1d18dcb4dd9e460648d24d9e98657fbed496c582929c6b3ce555e5";
    };
  };

  source = sources."${channel}";
in
stdenv.mkDerivation rec {
  name = "subversion-${source.version}";

  src = fetchurl {
    url = "mirror://apache/subversion/${name}.tar.bz2";
    hashOutput = false;
    inherit (source) sha256;
  };

  nativeBuildInputs = [
    perl
    python
  ];

  buildInputs = [
    apr
    apr-util
    cyrus-sasl
    expat
    file
    serf
    sqlite
    zlib
  ];

  configureFlags = [
    "--with-berkeley-db"
    "--with-swig=${swig}"
    "--disable-keychain"
    "--with-sasl=${cyrus-sasl}"
    "--with-serf=${serf}"
    "--with-zlib=${zlib}"
    "--with-sqlite=${sqlite}"
  ];

  preBuild = ''
    makeFlagsArray+=(APACHE_LIBEXECDIR=$out/modules)
  '';

  postInstall = ''
    make swig-py swig_pydir=$(toPythonPath $out)/libsvn swig_pydir_extra=$(toPythonPath $out)/svn
    make install-swig-py swig_pydir=$(toPythonPath $out)/libsvn swig_pydir_extra=$(toPythonPath $out)/svn

    make swig-pl-lib
    make install-swig-pl-lib
    pushd subversion/bindings/swig/perl/native
    perl Makefile.PL PREFIX=$out
    make install
    popd

    mkdir -p $out/share/bash-completion/completions
    cp tools/client-side/bash_completion $out/share/bash-completion/completions/subversion
  '';

  # Fix broken package config files
  preFixup = ''
    pcs=($(find "$out"/share/pkgconfig -type f))
    for pc in "''${pcs[@]}"; do
      sed -i 's,[ ]\(-l\|lib\)svn[^ ]*,\0-1,g' "$pc"
      mv "$pc" "''${pc%.pc}-1.pc"
    done
  '';

  # Parallel Building works fine but Parallel Install fails
  parallelInstall = false;

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      pgpKeyFingerprints = [
        "E7B2 A7F4 EC28 BE9F F8B3  8BA4 B64F FF12 09F9 FA74"
        "056F 8016 D9B8 7B1B DE41  7467 99EC 741B 5792 1ACC"
        "BA3C 15B1 337C F0FB 222B  D41A 1BCA 6586 A347 943F"
        "8BC4 DAE0 C5A4 D65F 4044  0107 4F7D BAA9 9A59 B973"
        "3D1D C66D 6D2E 0B90 3952  8138 C4A6 C625 CCC8 E1DF"
      ];
      inherit (src) urls outputHash outputHashAlgo;
      inherit (source) sha1Confirm;
    };
  };

  meta = with stdenv.lib; {
    description = "A version control system intended to be a compelling replacement for CVS in the open source community";
    homepage = http://subversion.apache.org/;
    maintainers = with maintainers; [
      wkennington
    ];
    plaforms = with platforms;
      x86_64-linux;
  };
}
