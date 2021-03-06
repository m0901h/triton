{ stdenv
, fetchTritonPatch
, fetchurl

, enableThreading ? true
}:

let
  libc = if stdenv.cc.libc or null != null then stdenv.cc.libc else "/usr";
in

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "perl-5.24.0";

  src = fetchurl {
    url = "mirror://cpan/src/5.0/${name}.tar.xz";
    sha256 = "a9a37c0860380ecd7b23aa06d61c20fc5bc6d95198029f3684c44a9d7e2952f2";
  };

  setupHook = ./setup-hook.sh;

  patches = [
    # Do not look in /usr etc. for dependencies.
    (fetchTritonPatch {
      rev = "07379e549f9dec896b878ccf3aecfea72dbb0d4e";
      file = "perl/no-sys-dirs.patch";
      sha256 = "786d9e1ac449dbe566067f953f0626481ac74f020e8e631e4f905d54a08dfb14";
    })
  ];

  # Build a thread-safe Perl with a dynamic libperls.o.  We need the
  # "installstyle" option to ensure that modules are put under
  # $out/lib/perl5 - this is the general default, but because $out
  # contains the string "perl", Configure would select $out/lib.
  # Miniperl needs -lm. perl needs -lrt.
  configureFlags = [
    "-de"
    "-Dcc=cc"
    "-Uinstallusrbinperl"
    "-Dinstallstyle=lib/perl5"
    "-Duseshrplib"
    "-Dlocincpth=${libc}/include"
    "-Dloclibpth=${libc}/lib"
  ] ++ optional enableThreading "-Dusethreads";

  configureScript = "${stdenv.shell} ./Configure";

  postPatch = ''
    pwd="$(type -P pwd)"
    substituteInPlace dist/PathTools/Cwd.pm \
      --replace "pwd_cmd = 'pwd'" "pwd_cmd = '$pwd'"
  '';

  preConfigure = ''
    configureFlags="$configureFlags -Dprefix=$out -Dman1dir=$out/share/man/man1 -Dman3dir=$out/share/man/man3"
  '' + optionalString (!enableThreading)
  /* We need to do this because the bootstrap doesn't have a
     static libpthread */ ''
    sed -i 's,\(libswanted.*\)pthread,\1,g' Configure
  '';

  preBuild = optionalString (!(stdenv ? cc && stdenv.cc.nativeTools))
    /* Make Cwd work on NixOS (where we don't have a /bin/pwd). */ ''
      substituteInPlace dist/PathTools/Cwd.pm --replace "'/bin/pwd'" "'$(type -tP pwd)'"
    '';

  # Inspired by nuke-references, which I can't depend on because it uses perl. Perhaps it should just use sed :)
  postInstall = ''
    self=$(echo $out | sed -n "s|^$NIX_STORE/\\([a-z0-9]\{32\}\\)-.*|\1|p")

    sed -i "/$self/b; s|$NIX_STORE/[a-z0-9]\{32\}-|$NIX_STORE/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-|g" "$out"/lib/perl5/*/*/Config.pm
    sed -i "/$self/b; s|$NIX_STORE/[a-z0-9]\{32\}-|$NIX_STORE/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-|g" "$out"/lib/perl5/*/*/Config_heavy.pl
  '';

  passthru.libPrefix = "lib/perl5/site_perl";

  outputs = [ "out" "man" ];

  preCheck =
  /* Try and setup a local hosts file */ ''
    if [ -f "${libc}/lib/libnss_files.so" ] ; then
      mkdir $TMPDIR/fakelib
      cp "${libc}/lib/libnss_files.so" $TMPDIR/fakelib
      sed -i 's,/etc/hosts,/dev/fd/3,g' $TMPDIR/fakelib/libnss_files.so
      export LD_LIBRARY_PATH=$TMPDIR/fakelib
    fi
  '';

  postCheck = ''
    unset LD_LIBRARY_PATH
  '';

  dontAddPrefix = true;

  # This is broken with make 4.2 and perl 5.22.1
  parallelInstall = false;

  meta = with stdenv.lib; {
    description = "The Perl 5 programmming language";
    homepage = https://www.perl.org/;
    license = with licenses; [
      artistic1
      gpl1Plus
    ];
    maintainers = with maintainers; [ ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
