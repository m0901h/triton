{ stdenv
, fetchurl
, intltool
, lib

, glib
, gtk_2
, libxfce4ui
, libxfce4util
, perlPackages
, xorg
}:

let
  inherit (lib)
    boolEn;

  channel = "0.10";
  version = "${channel}.7";
in
stdenv.mkDerivation rec {
  name = "exo-${version}";

  src = fetchurl {
    url = "http://archive.xfce.org/src/xfce/exo/${channel}/${name}.tar.bz2";
    sha256 = "521581481128af93e815f9690020998181f947ac9e9c2b232b1f144d76b1b35c";
  };

  nativeBuildInputs = [
    intltool
  ];

  buildInputs = [
    glib
    gtk_2
    libxfce4ui
    libxfce4util
    perlPackages.URI
    xorg.libX11
    xorg.xproto
  ];

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-nls"
    "--${boolEn (glib != null)}-gio-unix"
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    "--disable-debug"
    #"--disable-linker-opts"
    #"--disable-visibility"
    "--with-x"
  ];

  meta = with lib; {
    description = "Extensions to Xfce by os-cillation";
    homepage = http://www.xfce.org/;
    license = with licenses; [
      gpl2
      lgpl2
    ];
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
