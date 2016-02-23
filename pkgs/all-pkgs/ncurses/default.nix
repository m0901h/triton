{ stdenv
, fetchurl
, libtool

, gpm

# Extra Options
, threaded ? false # This breaks a lot of libraries because it enables the opaque includes
}:

with stdenv.lib;
stdenv.mkDerivation rec {
  name = "ncurses-6.0";

  src = fetchurl {
    url = "mirror://gnu/ncurses/${name}.tar.gz";
    sha256 = "0q3jck7lna77z5r42f13c4xglc7azd19pxfrjrpgp2yf615w4lgm";
  };

  nativeBuildInputs = [
    libtool
  ];

  buildInputs = [
    gpm
  ];

  configureFlags = [
    (mkWith   false       "ada"            null)
    (mkWith   true        "cxx"            null)
    (mkWith   true        "cxx-binding"    null)
    (mkEnable true        "db-install"     null)
    (mkWith   true        "manpages"       null)
    (mkWith   true        "progs"          null)
    (mkWith   false       "tests"          null)
    (mkWith   true        "curses-h"       null)
    (mkEnable true        "pc-files"       null)
    # With pc-suffix
    (mkEnable true        "mixed-case"     "auto")
    # With install-prefix
    (mkWith   true        "libtool"        null)
    (mkWith   true        "shared"         null)
    (mkWith   true        "normal"         null)
    (mkWith   false       "debug"          null)
    (mkWith   false       "profile"        null)
    (mkWith   true        "cxx-shared"     null)
    (mkWith   false       "termlib"        null)
    (mkWith   false       "ticlib"         null)
    (mkWith   true        "gpm"            null)
    (mkWith   true        "dlsym"          null)
    (mkWith   true        "sysmouse"       "maybe")
    (mkEnable true        "relink"         null)
    # With extra-suffix
    (mkEnable true        "overwrite"      null)
    (mkEnable true        "database"       null)
    (mkWith   false       "hashed-db"      null)
    (mkWith   true        "fallbacks"      "")
    (mkWith   true        "xterm-new"      null)
    # With xterm-kbs
    # With terminfo-dirs
    # With default-terminfo-dir
    # Enable big-core: Autodetected
    # Enable big-strings: Autodetected
    (mkEnable false       "termcap"        null)
    (mkWith   true        "termpath"       "\${out}/share/misc/termcap")
    (mkEnable true        "getcap"         null)
    (mkEnable false       "getcap-cache"   null)
    (mkEnable true        "home-terminfo"  null)
    (mkEnable true        "root-environ"   null)
    (mkEnable true        "symlinks"       null)
    (mkEnable false       "broken-linker"  null)
    (mkEnable false       "bsdpad"         null)
    (mkEnable true        "widec"          null)
    (mkEnable true        "lp64"           null)
    (mkEnable true        "tparm-varargs"  null)
    (mkWith   true        "tic-depends"    null)
    (mkWith   true        "bool"           null)
    # With caps
    # With chtype
    # With ospeed
    # With mmask-t
    # With ccharw-max
    (mkWith   false       "rcs-ids"        null)
    (mkEnable true        "ext-funcs"      null)
    (mkEnable true        "sp-funcs"       null)
    (mkEnable false       "term-driver"    null)  # Breaks htop
    (mkEnable true        "const"          null)
    (mkEnable true        "ext-colors"     null)
    (mkEnable true        "ext-mouse"      null)
    (mkEnable true        "ext-putwin"     null)
    (mkEnable true        "no-padding"     null)
    (mkEnable false       "signed-char"    null)
    (mkEnable true        "sigwinch"       null)
    (mkEnable true        "tcap-names"     null)
    (mkWith   true        "devlop"         null)
    (mkEnable true        "hard-tabs"      null)
    (mkEnable true        "xmc-glitch"     null)
    (mkWith   true        "assumed-color"  null)
    (mkEnable true        "hashmap"        null)
    (mkEnable true        "colorfgbg"      null)
    (mkEnable true        "interop"        null)
    (mkWith   threaded    "pthread"        null)
    (mkEnable threaded    "pthreads-eintr" null)
    (mkEnable false       "weak-symbols"   null)
    (mkEnable threaded    "reentrant"      null)
    # With wrap-prefix
    (mkEnable true        "safe-sprintf"   null)
    (mkEnable true        "scroll-hints"   null)
    (mkEnable false       "wgetch-events"  null)
    (mkEnable true        "echo"           null)
    (mkEnable true        "warnings"       null)
    (mkEnable false       "assertions"     null)
    (mkEnable false       "expanded"       null)
    (mkEnable true        "macros"         null)
    (mkWith   false       "trace"          null)
  ];

  preConfigure = ''
    configureFlagsArray+=("--includedir=$out/include")
    export PKG_CONFIG_LIBDIR="$out/lib/pkgconfig"
    mkdir -p "$PKG_CONFIG_LIBDIR"
    configureFlagsArray+=("--with-pkg-config-libdir=$PKG_CONFIG_LIBDIR")
  '';

  # Fix the path to gpm, this has to happen after configure is run
  postConfigure = ''
    sed -i "s,^\(#define LIBGPM_SONAME\).*,\1 \"${gpm}/lib/libgpm.so\",g" include/ncurses_cfg.h
  '';

  NIX_LDFLAGS = if threaded then "-lpthread" else null;

  # When building a wide-character (Unicode) build, create backward
  # compatibility links from the the "normal" libraries to the
  # wide-character libraries (e.g. libncurses.so to libncursesw.so).
  postInstall = ''
    # Determine what suffixes our libraries have
    suffix="$(awk -F': ' 'f{print $3; f=0} /default library suffix/{f=1}' config.log)"
    libs="$(ls $out/lib/pkgconfig | tr ' ' '\n' | sed "s,\(.*\)$suffix\.pc,\1,g")"
    suffixes="$(echo "$suffix" | awk '{for (i=1; i < length($0); i++) {x=substr($0, i+1, length($0)-i); print x}}')"

    # Get the path to the config util
    cfg=$(basename $out/bin/ncurses*-config)

    # symlink the full suffixed include directory
    ln -svf . $out/include/ncurses$suffix

    for newsuffix in $suffixes ""; do
      # Create a non-abi versioned config util links
      ln -svf $cfg $out/bin/ncurses$newsuffix-config

      # Allow for end users who #include <ncurses?w/*.h>
      ln -svf . $out/include/ncurses$newsuffix

      for lib in $libs; do
        for dylibtype in so dll dylib; do
          if [ -e "$out/lib/lib''${lib}$suffix.$dylibtype" ]; then
            ln -svf lib''${lib}$suffix.$dylibtype $out/lib/lib$lib$newsuffix.$dylibtype
          fi
        done
        for statictype in a dll.a la; do
          if [ -e "$out/lib/lib''${lib}$suffix.$statictype" ]; then
            ln -svf lib''${lib}$suffix.$statictype $out/lib/lib$lib$newsuffix.$statictype
          fi
        done
        ln -svf ''${lib}$suffix.pc $out/lib/pkgconfig/$lib$newsuffix.pc
      done
    done
  '';

  # In the standard environment we don't want to have bootstrap references
  preFixup = ''
    sed -i 's,${stdenv.shell},/bin/sh,g' $out/bin/*-config
  '';

  meta = with stdenv.lib; {
    description = "Free software emulation of curses in SVR4 and more";
    homepage = http://www.gnu.org/software/ncurses/;
    license = licenses.mit;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}