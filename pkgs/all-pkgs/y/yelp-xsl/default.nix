{ stdenv
, fetchurl
, gawk
, gettext
, intltool
, itstool

, libxml2
, libxslt

, channel
}:

let
  source = (import ./sources.nix { })."${channel}";
in
stdenv.mkDerivation rec {
  name = "yelp-xsl-${source.version}";

  src = fetchurl {
    url = "mirror://gnome/sources/yelp-xsl/${channel}/${name}.tar.xz";
    hashOutput = false;
    inherit (source) sha256;
  };

  nativeBuildInputs = [
    gawk
    gettext
    intltool
    itstool
  ];

  buildInputs = [
    libxml2
    libxslt
  ];

  configureFlags = [
    "--enable-nls"
    "--disable-doc"
  ];

  passthru = {
    srcVerification = fetchurl {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      sha256Url = "https://download.gnome.org/sources/yelp-xsl/${channel}/"
        + "${name}.sha256sum";
      failEarly = true;
    };
  };

  meta = with stdenv.lib; {
    description = "XSL stylesheets for yelp";
    homepage = https://git.gnome.org/browse/yelp-xsl;
    license = with licenses; [
      fdl11
      gpl2Plus
      lgpl21Plus
      mit
    ];
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
