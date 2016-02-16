{ fetchurl, stdenv, intltool, gettext, glib, libxml2, zlib, bzip2
, python, perl, gdk-pixbuf-core }:

with { inherit (stdenv.lib) optionals; };

stdenv.mkDerivation rec {
  name = "libgsf-1.14.34";

  src = fetchurl {
    url    = "mirror://gnome/sources/libgsf/1.14/${name}.tar.xz";
    sha256 = "f0fea447e0374a73df45b498fd1701393f8e6acb39746119f8a292fb4a0cb528";
  };

  nativeBuildInputs = [ intltool ];

  buildInputs = [ gettext bzip2 zlib python ]
    ++ stdenv.lib.optional doCheck perl;

  propagatedBuildInputs = [ libxml2 glib gdk-pixbuf-core ];

  doCheck = true;
  preCheck = "patchShebangs ./tests/";

  meta = with stdenv.lib; {
    description = "GNOME's Structured File Library";
    homepage    = http://www.gnome.org/projects/libgsf;
    license     = licenses.lgpl2Plus;
    maintainers = with maintainers; [ lovek323 ];
    platforms   = stdenv.lib.platforms.unix;
  };
}
