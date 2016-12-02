{ stdenv
, bison
, fetchurl
, gnum4

, bootstrap ? false
}:

let
  version = "2.6.1";
in
stdenv.mkDerivation rec {
  name = "${if bootstrap then "bootstrap-" else ""}flex-${version}";

  src = fetchurl {
    url = "https://github.com/westes/flex/releases/download/v${version}/flex-${version}.tar.xz";
    sha256 = "2c7a412c1640e094cb058d9b2fe39d450186e09574bebb7aa28f783e3799103f";
  };

  nativeBuildInputs = [
    bison
    gnum4
  ];

  # Using static libraries fixes issues with references to
  # yylex in flex 2.6.0
  # This can be tested by building glusterfs
  configureFlags = [
    "--disable-shared"
  ];

  ccFixFlags = !bootstrap;
  dontDisableStatic = true;

  meta = with stdenv.lib; {
    description = "A fast lexical analyser generator";
    homepage = http://flex.sourceforge.net/;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
