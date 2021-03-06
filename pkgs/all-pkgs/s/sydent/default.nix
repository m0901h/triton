{ stdenv
, buildPythonPackage
, fetchFromGitHub

, daemonize
, funcsigs
, mock
, pathlib2
, pbr
, pyasn1
, pynacl
, service-identity
, setuptools-trial
, signedjson
, six
, twisted
, unpaddedbase64
}:

buildPythonPackage {
  name = "sydent-2016-11-03";

  src = fetchFromGitHub {
    version = 2;
    owner = "matrix-org";
    repo = "sydent";
    rev = "188fbf6794d437e57d9a47e9ea4111b31e4cfdb4";
    sha256 = "6b4d7899f3f101cd1d24ec2664fb7bdb8882093fe6df165baea02600ba1ca587";
  };

  buildInputs = [
    mock
  ];

  propagatedBuildInputs = [
    daemonize
    funcsigs
    pathlib2
    pbr
    pyasn1
    pynacl
    service-identity
    setuptools-trial
    signedjson
    six
    twisted
    unpaddedbase64
  ];

  postInstall = ''
    mkdir -p $out/bin
    echo '#!/bin/sh' >> "$out/bin/sydent"
    echo "export PYTHONPATH='$PYTHONPATH'" >> "$out/bin/sydent"
    echo "$(command -v python) -m sydent.sydent \"\$@\"" >> "$out/bin/sydent"
    chmod +x "$out/bin/sydent"
  '';

  meta = with stdenv.lib; {
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
