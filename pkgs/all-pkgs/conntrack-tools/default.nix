{ stdenv
, bison
, fetchurl
, flex

, libmnl
, libnetfilter_conntrack
, libnetfilter_cthelper
, libnetfilter_cttimeout
, libnetfilter_queue
, libnfnetlink
}:

stdenv.mkDerivation rec {
  name = "conntrack-tools-1.4.3";

  src = fetchurl {
    url = "http://www.netfilter.org/projects/conntrack-tools/files/${name}.tar.bz2";
    sha1Confirm = "509db30f34b283f4a74a7e638ba0ca713d3fe98c";
    sha256 = "0mrzrzp6y41pmxc6ixc4fkgz6layrpwsmzb522adzzkc6mhcqg5g";
  };

  nativeBuildInputs = [
    bison
    flex
  ];

  buildInputs = [
    libmnl
    libnetfilter_conntrack
    libnetfilter_cthelper
    libnetfilter_cttimeout
    libnetfilter_queue
    libnfnetlink
  ];

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
  ];

  meta = with stdenv.lib; {
    homepage = http://conntrack-tools.netfilter.org/;
    description = "Connection tracking userspace tools";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}