{ stdenv
, fetchurl
, intltool
, makeWrapper

, adwaita-icon-theme
, avahi
, dbus-glib
, dconf
, file
, glib
, gnutls
, gtk
, libgcrypt
, libjpeg
, libnotify
, libsecret
, libsoup
, telepathy_glib
, xorg
, zlib

, channel
}:

assert xorg != null ->
  xorg.libICE != null
  && xorg.libSM != null
  && xorg.libX11 != null
  && xorg.libXext != null
  && xorg.libXtst != null
  && xorg.xproto != null;

let
  inherit (stdenv.lib)
    boolWt
    optionals;

  source = (import ./sources.nix { })."${channel}";
in
stdenv.mkDerivation rec {
  name = "vino-${source.version}";

  src = fetchurl {
    url = "mirror://gnome/sources/vino/${channel}/${name}.tar.xz";
    hashOutput = false;
    inherit (source) sha256;
  };

  nativeBuildInputs = [
    intltool
    makeWrapper
  ];

  buildInputs = [
    adwaita-icon-theme
    avahi
    dbus-glib
    dconf
    file
    glib
    gnutls
    gtk
    libgcrypt
    libjpeg
    libnotify
    libsecret
    libsoup
    telepathy_glib
    zlib
  ] ++ optionals (xorg != null) [
    xorg.libICE
    xorg.libSM
    xorg.libX11
    xorg.libXext
    xorg.libXtst
    xorg.xproto
  ];

  configureFlags = [
    "--disable-maintainer-mode"
    "--enable-compile-warnings"
    "--disable-iso-c"
    "--disable-debug"
    "--enable-nls"
    "--enable-ipv6"
    "--enable-schemas-compile"
    "--${boolWt (telepathy_glib != null)}-telepathy"
    "--${boolWt (libsecret != null)}-secret"
    "--${boolWt (xorg != null)}-x"
    "--${boolWt (gnutls != null)}-gnutls"
    "--${boolWt (libgcrypt != null)}-gcrypt"
    "--${boolWt (avahi != null)}-avahi"
    "--${boolWt (zlib != null)}-zlib"
    "--${boolWt (libjpeg != null)}-jpeg"
  ];

  preFixup = ''
    wrapProgram $out/libexec/vino-server \
      --set 'GSETTINGS_BACKEND' 'dconf' \
      --prefix 'GIO_EXTRA_MODULES' : "$GIO_EXTRA_MODULES" \
      --prefix 'XDG_DATA_DIRS' : "$GSETTINGS_SCHEMAS_PATH" \
      --prefix 'XDG_DATA_DIRS' : "$out/share" \
      --prefix 'XDG_DATA_DIRS' : "$XDG_ICON_DIRS"
  '';

  doCheck = true;

  passthru = {
    srcVerification = fetchurl {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      sha256Url = "https://download.gnome.org/sources/vino/${channel}/"
        + "${name}.sha256sum";
      failEarly = true;
    };
  };

  meta = with stdenv.lib; {
    description = "GNOME desktop sharing server";
    homepage = https://wiki.gnome.org/action/show/Projects/Vino;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
