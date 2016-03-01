{ stdenv, fetchurl, unzip, libunwind }:

stdenv.mkDerivation rec {
  name = "gperftools-2.4";

  src = fetchurl {
    url = "https://googledrive.com/host/0B6NtGsLhIcf7MWxMMF9JdTN3UVk/gperftools-2.4.tar.gz";
    sha256 = "0b8aqgch8dyapzw2zd9g89x6gsnm2ml0gf169rql0bxldqi3falq";
  };

  buildInputs = [ libunwind ];

  # some packages want to link to the static tcmalloc_minimal
  # to drop the runtime dependency on gperftools
  dontDisableStatic = true;

  meta = with stdenv.lib; {
    homepage = https://code.google.com/p/gperftools/;
    description = "Fast, multi-threaded malloc() and nifty performance analysis tools";
    platforms = with platforms; linux;
    license = licenses.bsd3;
    maintainers = with maintainers; [ wkennington ];
  };
}
