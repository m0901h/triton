{ stdenv
, fetchurl

, file
, ncurses
, udev
, pixman
, xorg
}:

stdenv.mkDerivation rec {
  name = "xf86-input-wacom-0.32.0";

  src = fetchurl {
    url = "mirror://sourceforge/linuxwacom/${name}.tar.bz2";
    sha256 = "03c73vi5rrcr92442k82f4kbabp21yqcrqi6ak2afl41zjdar5wc";
  };

  buildInputs = [
    xorg.inputproto
    xorg.libX11
    xorg.libXext
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    ncurses
    xorg.randrproto
    xorg.xorgserver
    xorg.xproto
    udev
    xorg.libXinerama
    pixman
  ];

  preConfigure = ''
    mkdir -p $out/share/X11/xorg.conf.d
    configureFlags="--with-xorg-module-dir=$out/lib/xorg/modules
    --with-sdkdir=$out/include/xorg --with-xorg-conf-dir=$out/share/X11/xorg.conf.d"
  '';

  CFLAGS = "-I${pixman}/include/pixman-1";

  meta = with stdenv.lib; {
    maintainers = [ maintainers.goibhniu maintainers.urkud ];
    description = "Wacom digitizer driver for X11";
    homepage = http://linuxwacom.sourceforge.net;
    license = licenses.gpl2;
    platforms = platforms.linux; # Probably, works with other unices as well
  };
}
