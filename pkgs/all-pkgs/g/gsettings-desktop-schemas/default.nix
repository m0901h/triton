{ stdenv
, fetchurl
, gettext
, intltool

, glib
, gnome-backgrounds
, gobject-introspection

, channel
}:

let
  inherit (stdenv.lib)
    boolEn;

  source = (import ./sources.nix { })."${channel}";
in
stdenv.mkDerivation rec {
  name = "gsettings-desktop-schemas-${source.version}";

  src = fetchurl {
    url = "mirror://gnome/sources/gsettings-desktop-schemas/${channel}/"
      + "${name}.tar.xz";
    hashOutput = false;
    inherit (source) sha256;
  };

  nativeBuildInputs = [
    gettext
    intltool
  ];

  buildInputs = [
    glib
    gobject-introspection
  ];

  postPatch = ''
    sed -i schemas/org.gnome.desktop.{background,screensaver}.gschema.xml.in \
      -e 's|@datadir@|${gnome-backgrounds}/share/|'
  '';

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-schemas-compile"
    "--${boolEn (gobject-introspection != null)}-introspection"
    "--enable-nls"
  ];

  passthru = {
    srcVerification = fetchurl {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      sha256Url = "https://download.gnome.org/sources/"
        + "gsettings-desktop-schemas/${channel}/${name}.sha256sum";
      failEarly = true;
    };
  };

  meta = with stdenv.lib; {
    description = "Collection of GSettings schemas for GNOME desktop";
    homepage = https://git.gnome.org/browse/gsettings-desktop-schemas;
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
