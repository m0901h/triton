{ stdenv
, autoconf
, automake
, fetchurl
, docbook2x
, docbook_xml_dtd_45
, python3Packages

, cgmanager
, dbus
, gnutls
, libcap
, libnih
, libselinux
, libseccomp
}:

let
  version = "2.0.6";
in
stdenv.mkDerivation rec {
  name = "lxc-${version}";

  src = fetchurl {
    url = "https://linuxcontainers.org/downloads/lxc/lxc-${version}.tar.gz";
    hashOutput = false;
    sha256 = "7c292cd0055dac1a0e6fbb6a7740fd12b6ffb204603c198faf37c11c9d6dcd7a";
  };

  nativeBuildInputs = [
    autoconf
    automake
    docbook2x
    python3Packages.python
  ];

  buildInputs = [
    cgmanager
    dbus
    gnutls
    libcap
    libnih
    libseccomp
    libselinux
  ];

  XML_CATALOG_FILES = "${docbook_xml_dtd_45}/xml/dtd/docbook/catalog.xml";

  patches = [
    ./support-db2x.patch
  ];

  configureFlags = [
    "--localstatedir=/var"
    "--sysconfdir=/etc"
    "--enable-doc"
    "--disable-api-docs"
    "--with-init-script=none"
    "--with-distro=nixos" # just to be sure it is "unknown"
    # "--enable-apparmor"
    "--enable-selinux"
    "--enable-seccomp"
    "--enable-capabilities"
    "--disable-examples"
    "--enable-python"
    # "--enable-lua"
    "--enable-bash"
    "--disable-tests"
    "--with-rootfs-path=/var/lib/lxc/rootfs"
  ];

  installFlags = [
    "localstatedir=\${TMPDIR}"
    "sysconfdir=\${out}/etc"
    "sysconfigdir=\${out}/etc/default"
    "bashcompdir=\${out}/share/bash_completion.d" # FIXME
    "READMEdir=\${TMPDIR}/var/lib/lxc/rootfs"
    "LXCPATH=\${TMPDIR}/var/lib/lxc"
  ];

  passthru = {
    srcVerification = fetchurl rec {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      pgpKeyFingerprint = "602F 5676 63E5 93BC BD14  F338 C638 974D 6479 2D67";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    homepage = "http://lxc.sourceforge.net";
    description = "userspace tools for Linux Containers, a lightweight virtualization system";
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
