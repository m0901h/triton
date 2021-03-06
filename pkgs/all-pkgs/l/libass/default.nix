{ stdenv
, fetchurl
, yasm

, fontconfig
, freetype
, fribidi
, harfbuzz

, rasterizerSupport ? true # Internal rasterizer
, largeTilesSupport ? false # Use larger tiles in the rasterizer
}:

let
  inherit (stdenv.lib)
    boolEn;

  version = "0.13.4";
in
stdenv.mkDerivation rec {
  name = "libass-${version}";

  src = fetchurl {
    url = "https://github.com/libass/libass/releases/download/${version}/"
      + "${name}.tar.xz";
    sha256 = "d84a2fc89011b99d87fc47af91906622707c165d1860e9f774825ebbbc9c9fb6";
  };

  nativeBuildInputs = [
    yasm
  ];

  buildInputs = [
    fontconfig
    freetype
    fribidi
    harfbuzz
  ];

  configureFlags = [
    "--${boolEn doCheck}-test"
    "--disable-profile"
    "--${boolEn (fontconfig != null)}-fontconfig"
    "--disable-directwrite" # Windows
    "--disable-coretext" # OSX
    "--enable-require-system-font-provider"
    "--${boolEn (harfbuzz != null)}-harfbuzz"
    "--${boolEn (yasm != null)}-asm"
    "--${boolEn rasterizerSupport}-rasterizer"
    "--${boolEn largeTilesSupport}-large-tiles"
  ];

  doCheck = false;

  meta = with stdenv.lib; {
    description = "Library for SSA/ASS subtitles rendering";
    homepage = https://github.com/libass/libass;
    license = licenses.isc;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
