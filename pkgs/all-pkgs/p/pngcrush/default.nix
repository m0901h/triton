{ stdenv
, fetchurl

, libpng
, zlib
}:

let
  version = "1.8.10";
in
stdenv.mkDerivation rec {
  name = "pngcrush-${version}";

  src = fetchurl {
    url = "mirror://sourceforge/pmt/pngcrush/${version}/${name}-nolib.tar.xz";
    hashOutput = false;
    sha256 = "8db04792f8912011c9c25caf732894276f16ff0b7612f3365d18971dfb56442b";
  };

  buildInputs = [
    libpng
    zlib
  ];

  postPatch = /* Fix hardcoded install prefix */ ''
    sed -i Makefile \
      -e "s,/usr,$out,"
  '';

  makeFlags = [
    "PNGINC=${libpng}/include"
    "PNGLIB=${libpng}/lib"
    "ZINC=${zlib}/include"
    "ZLIB=${zlib}/lib"
  ];

  passthru = {
    srcVerification = fetchurl rec {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      insecureProtocolDowngrade = true;
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      pgpKeyFingerprint = "8048 643B A2C8 40F4 F92A  195F F549 84BF A16C 640F";
    };
  };

  meta = with stdenv.lib; {
    description = "Portable Network Graphics (PNG) optimizing utility";
    homepage = http://pmt.sourceforge.net/pngcrush;
    license = licenses.free; # pngcrush license
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
