{ stdenv
, fetchurl

, glib
, nss
}:

stdenv.mkDerivation rec {
  name = "libcacard-2.5.2";

  src = fetchurl {
    url = "http://www.spice-space.org/download/libcacard/${name}.tar.xz";
    sha256 = "1jsfvz9miyi5s9qczh5qb9df1znwqicgdgz6gsyz6jm68qixaf9f";
  };

  buildInputs = [
    glib
    nss
  ];

  meta = with stdenv.lib; {
    homepage = http://www.spice-space.org/download/libcacard/;
    description = "Spice smart card library";
    license = licenses.gpl2;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
