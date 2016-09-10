{ stdenv
, autoconf
, autoconf-archive
, automake
, fetchFromGitHub
, gettext
, intltool
, libtool
, makeWrapper
, pkgconfig

, adwaita-icon-theme
, appstream-glib
, dconf
, gdk-pixbuf
, glib
, gtk3
, libepoxy
, librsvg
, mpv
, python2Packages
, shared_mime_info
, wayland
, xorg
}:

let
  inherit (stdenv.lib)
    boolEn;

  version = "2016-08-31";
in
stdenv.mkDerivation rec {
  name = "gnome-mpv-${version}";

  src = fetchFromGitHub {
    version = 1;
    owner = "gnome-mpv";
    repo = "gnome-mpv";
    rev = "626642745f2da546860c587aea05dfb3ab0e7095";
    sha256 = "d2521c1e57a2d479a31f3d0e32ec8e8a9046f08a46bff7403dd60fd2479c68e9";
  };

  nativeBuildInputs = [
    autoconf
    autoconf-archive
    automake
    gettext
    intltool
    libtool
    makeWrapper
    pkgconfig
  ];

  buildInputs = [
    adwaita-icon-theme
    appstream-glib
    dconf
    gdk-pixbuf
    glib
    gtk3
    libepoxy
    librsvg
    mpv
    python2Packages.youtube-dl
    shared_mime_info
    wayland
    xorg.libX11
  ];

  preConfigure = /* Ignore autogen.sh and run the commands manually */ ''
    aclocal --install -I m4
    intltoolize --copy --automake
    autoreconf --install -Wno-portability
  '';

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-nls"
    "--enable-schemas-compile"
    "--disable-debug"
    "--enable-opencl-cb"
    "--${boolEn (appstream-glib != null)}-appstream-util"
  ];

  preFixup = ''
    wrapProgram $out/bin/gnome-mpv  \
      --set 'GDK_PIXBUF_MODULE_FILE' "$GDK_PIXBUF_MODULE_FILE" \
      --prefix 'GIO_EXTRA_MODULES' : "$GIO_EXTRA_MODULES" \
      --prefix 'XDG_DATA_DIRS' : "$GSETTINGS_SCHEMAS_PATH" \
      --prefix 'XDG_DATA_DIRS' : "$out/share" \
      --prefix 'XDG_DATA_DIRS' : "${shared_mime_info}/share" \
      --prefix 'XDG_DATA_DIRS' : "$XDG_ICON_DIRS"
  '';

  meta = with stdenv.lib; {
    description = "A simple GTK+ frontend for mpv";
    homepage = https://github.com/gnome-mpv/gnome-mpv;
    license = licenses.gpl3;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
