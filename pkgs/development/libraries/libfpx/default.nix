{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "libfpx-1.3.1-6";

  src = fetchurl {
    url = "mirror://imagemagick/delegates/${name}.tar.xz";
    sha256 = "150cbdrjvsnnyij0xy81qn3wwx3k7w6plss49656ragiaiadza4f";
  };

  # This dead code causes a duplicate symbol error in Clang so just remove it
  postPatch = stdenv.lib.optionalString stdenv.cc.isClang ''
    substituteInPlace jpeg/ejpeg.h --replace "int No_JPEG_Header_Flag" ""
  '';

  CXXFLAGS = "-std=c++11";

  meta = with stdenv.lib; {
    homepage = http://www.imagemagick.org;
    description = "A library for manipulating FlashPIX images";
    license = "Flashpix";
    platforms = platforms.all;
    maintainers = with maintainers; [ wkennington ];
  };
}
