{ stdenv, fetchurl, automake }:

stdenv.mkDerivation (rec {
  name = "pkg-config-0.29";
  
  setupHook = ./setup-hook.sh;
  
  src = fetchurl {
    url = "http://pkgconfig.freedesktop.org/releases/${name}.tar.gz";
    sha256 = "0sq09a39wj4cxf8l2jvkq067g08ywfma4v6nhprnf351s82pfl68";
  };

  configureFlags = [ "--with-internal-glib" ];

  patches = [
    # Process Requires.private properly, see
    # http://bugs.freedesktop.org/show_bug.cgi?id=4738.
    ./requires-private.patch
  ] ++ stdenv.lib.optional stdenv.isCygwin ./2.36.3-not-win32.patch;

  meta = {
    description = "A tool that allows packages to find out information about other packages";
    homepage = http://pkg-config.freedesktop.org/wiki/;
    platforms = stdenv.lib.platforms.all;
  };

}
