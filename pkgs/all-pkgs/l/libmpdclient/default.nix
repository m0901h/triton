{ stdenv
, fetchurl
, doxygen
}:

let
  versionMajor = "2";
  versionMinor = "10";
  version = "${versionMajor}.${versionMinor}";
in
stdenv.mkDerivation rec {
  name = "libmpdclient-${version}";

  src = fetchurl {
    url = "http://www.musicpd.org/download/libmpdclient/${versionMajor}/"
        + "${name}.tar.xz";
    sha256 = "10pzs9z815a8hgbbbiliapyiw82bnplsccj5irgqjw5f5plcs22g";
  };

  nativeBuildInputs = [
    doxygen
  ];

  passthru = {
    inherit
      versionMajor
      versionMinor;
  };

  meta = with stdenv.lib; {
    description = "Client library for MPD (music player daemon)";
    homepage = http://www.musicpd.org/libs/libmpdclient/;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
