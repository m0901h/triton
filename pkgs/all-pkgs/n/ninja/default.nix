{ stdenv
, asciidoc
, fetchurl
, python
, re2c
}:

let
  version = "1.7.2";
in
stdenv.mkDerivation rec {
  name = "ninja-${version}";

  src = fetchurl {
    url = "https://github.com/triton/ninja/releases/download/v${version}/${name}.tar.xz";
    sha256 = "d857f906e37916d2c4cd7d3955a4758c6d2adb7387540e13e6541884c1fd2369";
  };

  nativeBuildInputs = [
    asciidoc
    python
    re2c
  ];

  postPatch = ''
    patchShebangs ./configure.py
  '';

  buildPhase = ''
    runHook 'preBuild'
    ./configure.py '--bootstrap' '--verbose'
    asciidoc doc/manual.asciidoc
    runHook 'postBuild'
  '';

  installPhase = ''
    runHook 'preInstall'
    install -vD 'ninja' "$out/bin/ninja"
    install -vD 'doc/manual.asciidoc' "$out/share/doc/ninja/manual.asciidoc"
    install -vD 'doc/manual.html' "$out/share/doc/ninja/doc/manual.html"
    runHook 'postInstall'
  '';

  setupHook = ./setup-hook.sh;

  meta = with stdenv.lib; {
    description = "Small build system with a focus on speed";
    homepage = http://martine.github.io/ninja/;
    license = licenses.asl20;
    maintainers = with maintainers; [
      codyopel
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
