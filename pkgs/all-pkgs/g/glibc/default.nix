{ stdenv
, binutils
, fetchurl
, fetchTritonPatch

, linux-headers

, bootstrap ? false
}:

let
  inherit (stdenv.lib)
    optionals
    optionalString;

  nscdPatch = fetchTritonPatch {
    rev = "7ac98bac3cf181b4823633bfd9ce6ce7f831089e";
    file = "glibc/glibc-remove-datetime-from-nscd.patch";
    sha256 = "72a050d394c9a4785f997b9c853680150996b65646a388e347e51d3dde8790e8";
  };

  version = "2.24";
in
stdenv.mkDerivation rec {
  name = "${if bootstrap then "bootstrap-" else ""}glibc-${version}";

  src = fetchurl {
    url = "mirror://gnu/glibc/glibc-${version}.tar.xz";
    #allowHashOutput = false;
    sha256 = "99d4a3e8efd144d71488e478f62587578c0f4e1fa0b4eed47ee3d4975ebeb5d3";
  };

  patches = [
    /* Have rpcgen(1) look for cpp(1) in $PATH.  */
    (fetchTritonPatch {
      rev = "7ac98bac3cf181b4823633bfd9ce6ce7f831089e";
      file = "glibc/rpcgen-path.patch";
      sha256 = "4f7f58b96098b0ae3e2945481f9007c719c5f56704724a4d36074b76e29bee81";
    })

    /* Allow NixOS and Nix to handle the locale-archive. */
    (fetchTritonPatch {
      rev = "7ac98bac3cf181b4823633bfd9ce6ce7f831089e";
      file = "glibc/nix-locale-archive.patch";
      sha256 = "079f4eb8f051c20291ea8bc133c582bf4e9c743948f5052069cb40fe776eeb79";
    })

    /* Don't use /etc/ld.so.cache, for non-NixOS systems.  */
    (fetchTritonPatch {
      rev = "7ac98bac3cf181b4823633bfd9ce6ce7f831089e";
      file = "glibc/dont-use-system-ld-so-cache.patch";
      sha256 = "c55c79b1f5e41d8331e23801556b90a678803746f92c7cf550c13f3f775dd974";
    })

    /* Don't use /etc/ld.so.preload, but /etc/ld-nix.so.preload.  */
    (fetchTritonPatch {
      rev = "7ac98bac3cf181b4823633bfd9ce6ce7f831089e";
      file = "glibc/dont-use-system-ld-so-preload.patch";
      sha256 = "de897e0f53379f87459f5d350a229768159159f5e44eb7f6bd3050fd416d4aa6";
    })

    /* The command "getconf CS_PATH" returns the default search path
       "/bin:/usr/bin", which is inappropriate on NixOS machines. This
       patch extends the search path by "/run/current-system/sw/bin". */
    (fetchTritonPatch {
      rev = "7ac98bac3cf181b4823633bfd9ce6ce7f831089e";
      file = "glibc/fix_path_attribute_in_getconf.patch";
      sha256 = "d7176285b786c701bd963d97047d845aaf05fdc1e400de3a0526e0cd8ab68047";
    })
  ];

  postPatch = ''
    # Always treat fortify source warnings as errors
    sed -i 's,\(#[ ]*\)warning\( _FORTIFY_SOURCE\),\1error\2,g' include/features.h
  '' + optionalString (!bootstrap) ''
    # nscd needs libgcc, and we don't want it dynamically linked
    # because we don't want it to depend on bootstrap-tools libs.
    echo "LDFLAGS-nscd += -static-libgcc" >> nscd/Makefile

    # Replace the date and time in nscd by a prefix of $out.
    # It is used as a protocol compatibility check.
    # Note: the size of the struct changes, but using only a part
    # would break hash-rewriting. When receiving stats it does check
    # that the struct sizes match and can't cause overflow or something.
    cat ${nscdPatch} | sed "s,@out@,$out," | patch -p1
  '';

  # We must configure and build in a separate directory
  preConfigure = ''
    mkdir "../build"
    cd "../build"
    configureScript="../$sourceRoot/configure"
  '';

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--localedir=/run/current-system/sw/share/locale"
    #"--${if !bootstrap then "enable" else "disable"}-shared"
    "--enable-shared"
    #"--enable-gold"
    "--${if !bootstrap then "enable" else "disable"}-timezone-tools"
    "--${if !bootstrap then "enable" else "disable"}-stackguard-randomization"
    "--${if !bootstrap then "enable" else "disable"}-lock-elision"
    "--${if !bootstrap then "enable" else "disable"}-add-ons"
    "--enable-bind-now"
    "--enable-kernel=3.13"  # Support as old as Ubuntu 14.04
    "--disable-werror"
    "--enable-multi-arch"
    "--${if !bootstrap then "enable" else "disable"}-nss-crypt"
    "--${if !bootstrap then "enable" else "disable"}-obsolete-rpc"
    "--disable-systemtap"
    "--${if !bootstrap then "enable" else "disable"}-build-nscd"
    "--${if !bootstrap then "enable" else "disable"}-pt_chown"
    "--with-headers=${linux-headers}/include"
  ];

  preBuild = ''
    fail() {
      export NIX_DEBUG=1
      rpcgen="$(find . -name cross-rpcgen)"
      rm "$rpcgen"
      make || true
      ldd "$rpcgen" || true
      patchelf --print-interpreter "$rpcgen" || true
      patchelf --print-rpath "$rpcgen" || true
      readelf -a "$rpcgen" || true
      exit 1
    }
    trap fail ERR INT TERM
    export ccStackProtector=0
    echo "build-programs=no" >> configparams
  '';

  postBuild = optionalString (!bootstrap) ''
    export ccStackProtector=1
    sed -i 's,build-programs=no,build-programs=yes,g' configparams
    preBuild=""
    postBuild=""
    buildPhase
  '';

  ccFixFlags = !bootstrap;
  dontPatchShebangs = true;
  dontDisableStatic = true;

  # Glibc cannot have itself in its RPATH.
  NIX_DONT_SET_RPATH = true;
  NIX_NO_SELF_RPATH = true;
  NIX_CFLAGS_LINK = false;
  NIX_LDFLAGS_BEFORE = false;
  patchELFAddRpath = false;

  # Glibc doesn't like gold
  NIX_LD_FORCE_BFD = true;

  # Make sure we don't use the autodetected shell
  BASH_SHELL = "/bin/sh";

  # We shouldn't ever maintainer references from glibc as it will
  # always be a reference to a bootstrap binary
  allowedReferences = [
    linux-headers
  ];

  passthru = {
    srcVerification = fetchurl {
      failEarly = true;
      pgpsigUrls = map (n: "${n}.sig") src.urls;
      pgpKeyFingerprint = "AED6 E2A1 85EE B379 F174  76D2 E012 D07A D0E3 CC30";
      inherit (src) urls outputHash outputHashAlgo;
    };
  };

  meta = with stdenv.lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
