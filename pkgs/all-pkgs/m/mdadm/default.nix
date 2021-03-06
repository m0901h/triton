{ stdenv
, fetchurl
, groff
}:

stdenv.mkDerivation rec {
  name = "mdadm-3.3.4";

  src = fetchurl {
    url = "mirror://kernel/linux/utils/raid/mdadm/${name}.tar.xz";
    sha256 = "0s6a4bq7v7zxiqzv6wn06fv9f6g502dp047lj471jwxq0r9z9rca";
  };

  nativeBuildInputs = [
    groff
  ];

  patches = [
    ./no-self-references.patch
  ];

  postPatch = ''
    sed -e 's@/lib/udev@''${out}/lib/udev@' -e 's@ -Werror @ @' -i Makefile
  '';

  preBuild = ''
    makeFlagsArray+=(
      "INSTALL_BINDIR=$out/sbin"
      "MANDIR=$out/share/man"
    )
  '';

  makeFlags = [
    "NIXOS=1"
    "RUN_DIR=/dev/.mdadm"
    "INSTALL=install"
  ];

  # Attempt removing if building with gcc5 when updating
  NIX_CFLAGS_COMPILE = [
    "-std=gnu89"
  ];

  # This is to avoid self-references, which causes the initrd to explode
  # in size and in turn prevents mdraid systems from booting.
  allowedReferences = [
    stdenv.cc.libc
  ];

  meta = with stdenv.lib; {
    description = "Programs for managing RAID arrays under Linux";
    homepage = http://neil.brown.name/blog/mdadm;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
