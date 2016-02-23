{ stdenv
, fetchTritonPatch
, fetchurl
, perl

, cryptodevHeaders
, zlib
}:

stdenv.mkDerivation rec {
  name = "openssl-1.0.2f";

  src = fetchurl {
    urls = [
      "http://www.openssl.org/source/${name}.tar.gz"
      "http://openssl.linux-mirror.org/source/${name}.tar.gz"
    ];
    sha256 = "932b4ee4def2b434f85435d9e3e19ca8ba99ce9a065a61524b429a9d5e9b2e9c";
  };

  patches = [
    (fetchTritonPatch {
       rev = "f2bfa2d2db51744e6fcb5677543b3bce8504bf82";
       file = "openssl/use-etc-ssl-certs.patch";
       sha256 = "537e96a5949507706efe3607093f3f8cbfd7e8228a734bb6a766ff828c17117d";
    })
  ];

  nativeBuildInputs = [
    perl
  ];

  buildInputs = [
    cryptodevHeaders
    zlib
  ];

  configureScript = "./config";

  configureFlags = [
    "shared"
    # "sctp"  TODO: Find needed headers
    "zlib"
    "--libdir=lib"
    "--openssldir=/etc/ssl"
    # TODO: Enable krb5
  ];

  preBuild = ''
    # We don't want to build static libraries
    sed -i 's, libcrypto.a,,g; s, libssl.a,,g' Makefile

    makeFlagsArray+=("MANDIR=$out/share/man")
    installFlagsArray+=("OPENSSLDIR=$out/etc/ssl")
  '';

  # Parallel installing is broken in OpenSSL, it creates invaild shared objects.
  parallelInstall = false;

  preFixup = ''
    # remove dependency on Perl at runtime
    rm -r $out/etc/ssl/misc $out/bin/c_rehash

    # Remove unused stuff
    rmdir $out/etc/ssl/{certs,private}
  '';

  disallowedReferences = [ perl ];

  meta = with stdenv.lib; {
    homepage = http://www.openssl.org/;
    description = "A cryptographic library that implements the SSL and TLS protocols";
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}