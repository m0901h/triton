{ fetchurl, stdenv, lib, flex, bison, db, iptables, pkgconfig
, enableFan ? false
}:

stdenv.mkDerivation rec {
  name = "iproute2-4.5.0";

  src = fetchurl {
    url = "mirror://kernel/linux/utils/net/iproute2/${name}.tar.xz";
    sha256 = "0jj9phsi8m2sbnz7bbh9cf9vckm67hs62ab5srdwnrg4acpjj59z";
  };

  patches = lib.optionals enableFan [ ./ubuntu-fan.patch ];

  preConfigure = ''
    patchShebangs ./configure
    sed -e '/ARPDDIR/d' -i Makefile
  '';

  makeFlags = [
    "DESTDIR="
    "LIBDIR=$(out)/lib"
    "SBINDIR=$(out)/sbin"
    "MANDIR=$(out)/share/man"
    "DOCDIR=$(TMPDIR)/share/doc/${name}" # Don't install docs
  ];

  buildFlags = [
    "CONFDIR=/etc/iproute2"
  ];

  installFlags = [
    "CONFDIR=$(out)/etc/iproute2"
  ];

  buildInputs = [ db iptables ];
  nativeBuildInputs = [ bison flex pkgconfig ];

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    homepage = http://www.linuxfoundation.org/collaborate/workgroups/networking/iproute2;
    description = "A collection of utilities for controlling TCP/IP networking and traffic control in Linux";
    platforms = platforms.linux;
    license = licenses.gpl2;
    maintainers = with maintainers; [ eelco wkennington ];
  };
}
