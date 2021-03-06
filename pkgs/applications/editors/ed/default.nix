{ fetchurl, stdenv }:

stdenv.mkDerivation rec {
  name = "ed-1.13";

  src = fetchurl {
    # gnu only provides *.lz tarball, which is unfriendly for stdenv bootstrapping
    #url = "mirror://gnu/ed/${name}.tar.gz";
    # When updating, please make sure the sources pulled match those upstream by
    # Unpacking both tarballs and running `find . -type f -exec sha256sum \{\} \; | sha256sum`
    # in the resulting directory
    url = "http://fossies.org/linux/privat/${name}.tar.gz";
    sha256 = "03vbhfpg2yr63ql0qbcw13gyrbrp62nnc2b82nrzl57zbp4siqpr";
  };

  /* FIXME: Tests currently fail on Darwin:

       building test scripts for ed-1.5...
       testing ed-1.5...
       *** Output e1.o of script e1.ed is incorrect ***
       *** Output r3.o of script r3.ed is incorrect ***
       make: *** [check] Error 127

    */
  doCheck = true;

  crossAttrs = {
    compileFlags = [ "CC=${stdenv.cross.config}-gcc" ];
  };

  meta = {
    description = "An implementation of the standard Unix editor";
    license = stdenv.lib.licenses.gpl3Plus;
    homepage = http://www.gnu.org/software/ed/;
    maintainers = [ ];
  };
}
