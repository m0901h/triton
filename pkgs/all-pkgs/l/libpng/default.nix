{ stdenv
, fetchurl

, zlib
}:

let
  version = "1.6.26";
in
stdenv.mkDerivation rec {
  name = "libpng-${version}";

  src = fetchurl {
    url = "mirror://sourceforge/libpng/libpng16/${version}/${name}.tar.xz";
    hashOutput = false;
    sha256 = "266743a326986c3dbcee9d89b640595f6b16a293fd02b37d8c91348d317b73f9";
  };

  buildInputs = [
    zlib
  ];

  patches = [
    (fetchurl {
      url = "mirror://sourceforge/libpng-apng/libpng16/1.6.26/libpng-1.6.26-apng.patch.gz";
      sha256 = "01dec904d91ee8c90a9a78f253d01d8fac0e37a3f4beacb60e136ea7c814d72c";
    })
  ];

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrl = map (n: "${n}.asc") src.urls;
      pgpKeyFingerprint = "8048 643B A2C8 40F4 F92A  195F F549 84BF A16C 640F";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    description = "The official reference implementation for the PNG file format with animation patch";
    homepage = http://www.libpng.org/pub/png/libpng.html;
    license = licenses.libpng;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
