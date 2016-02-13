{ stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation rec {
  name = "zstd-${version}";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "Cyan4973";
    repo = "zstd";
    rev = "v${version}";
    sha256 = "18jwhvzj3kv8lpr6fgild7a574lsak93fc1z8nvhcdbc1b1n2dsj";
  };

  # Dont do anything in the build phase since the makefile builds during install
  buildPhase = ''
    echo "Build happens during install"
  '';

  preInstall = ''
    installFlagsArray+=("PREFIX=$out")
  '';

  meta = with stdenv.lib; {
    platforms = [
      "x86_64-linux"
      "i686-linux"
    ];
    license = licenses.bsd2;
    maintainers = with maintainers; [
      wkennington
    ];
  };
}