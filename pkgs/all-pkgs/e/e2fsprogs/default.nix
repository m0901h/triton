{ stdenv
, fetchurl

, fuse
, util-linux_lib
}:

let
  version = "1.43.3";
in
stdenv.mkDerivation rec {
  name = "e2fsprogs-${version}";

  src = fetchurl {
    url = "mirror://sourceforge/e2fsprogs/e2fsprogs/v${version}/${name}.tar.gz";
    hashOutput = false;
    multihash = "QmTKE4hEyybo8Y36rcKg4DwMhzzoYejoGUSTywV7a3QXP5";
    sha256 = "ce8ef1bbb0d4730f170167284fda156ac9d6bf18db2750eb94af619a81b19927";
  };

  buildInputs = [
    fuse
    util-linux_lib
  ];

  configureFlags = [
    "--enable-symlink-install"
    "--enable-relative-symlinks"
    "--enable-symlink-relative-symlinks"
    "--enable-elf-shlibs"
    "--disable-profile"
    "--disable-gcov"
    "--enable-hardening"
    "--disable-jbd-debug"
    "--disable-blkid-debug"
    "--disable-testio-debug"
    "--disable-libuuid"
    "--disable-libblkid"
    "--disable-backtrace"
    "--disable-debugfs"
    "--enable-imager"
    "--enable-resizer"
    "--enable-defrag"
    "--enable-fsck"
    "--disable-e2initrd-helper"
    "--enable-tls"
    "--disable-uuidd"  # Build is broken in 1.43.1
    "--enable-mmp"
    "--enable-tdb"
    "--enable-bmap-stats"
    "--enable-bmap-stats-ops"
    "--enable-fuse2fs"
  ];

  installFlags = [
    "LN=ln -s"
  ];

  installTargets = [
    "install"
    "install-libs"
  ];

  # Parallel install is broken
  parallelInstall = false;

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      pgpKeyFingerprint = "3AB0 57B7 E78D 945C 8C55  91FB D36F 769B C118 04F0";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    description = "Tools for creating and checking ext2/ext3/ext4 filesystems";
    homepage = http://e2fsprogs.sourceforge.net/;
    license = licenses.gpl2;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
