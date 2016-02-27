{ stdenv
, fetchurl
, gettext
, intltool
, libxslt
, which

, atk
, gdk-pixbuf
, glib
, gnome_doc_utils
, gobject-introspection
, gsettings-desktop-schemas
, gtk3
, isocodes
, itstool
, libxml2
, pango
, python
, wayland
, xorg
}:

with {
  inherit (stdenv.lib)
    enFlag
    wtFlag;
};

assert xorg != null ->
  xorg.libX11 != null
  && xorg.libXext != null
  && xorg.libXrandr != null
  && xorg.randrproto != null
  && xorg.xkeyboardconfig != null
  && xorg.xproto != null;

stdenv.mkDerivation rec {
  name = "gnome-desktop-${version}";
  versionMajor = "3.18";
  versionMinor = "2";
  version = "${versionMajor}.${versionMinor}";

  src = fetchurl {
    url = "mirror://gnome/sources/gnome-desktop/${versionMajor}/${name}.tar.xz";
    sha256 = "0mkv5vg04n2znd031dgjsgari6rgnf97637mf4x58dz15l16vm6x";
  };

  nativeBuildInputs = [
    gettext
    intltool
    itstool
    libxslt
    which
  ];

  buildInputs = [
    atk
    gdk-pixbuf
    glib
    gobject-introspection
    gsettings-desktop-schemas
    gtk3
    isocodes
    libxml2
    pango
    xorg.libX11
    xorg.libXext
    xorg.libxkbfile
    xorg.libXrandr
    xorg.randrproto
    xorg.xkeyboardconfig
    xorg.xproto
  ];

  configureFlags = [
    "--enable-nls"
    "--disable-date-in-gnome-version"
    "--enable-compile-warnings"
    (enFlag "introspection" (gobject-introspection != null) null)
    "--disable-gtk-doc"
    "--disable-gtk-doc-html"
    "--disable-gtk-doc-pdf"
    (wtFlag "x" (xorg != null) null)
  ];

  meta = with stdenv.lib; {
    description = "Libraries for the gnome desktop that are not part of the UI";
    homepage = https://git.gnome.org/browse/gnome-desktop;
    license = with licenses; [
      #fdl11
      gpl2Plus
      lgpl2Plus
    ];
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
