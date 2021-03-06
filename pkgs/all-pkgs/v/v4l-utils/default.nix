{ stdenv
, fetchurl
, libjpeg-turbo_1-4

, alsa-lib
, xorg
, qt4

, channel ? null
}:

# TODO: qt5 support

let
  inherit (stdenv.lib)
    any
    optionals
    optionalString;
in

assert any (n: n == channel) [
  "lib"
  "utils"
];

# See libv4l in all-packages.nix for the libs only (overrides alsa, libX11 & QT)

stdenv.mkDerivation rec {
  name = "v4l-utils-1.10.1";

  src = fetchurl {
    url = "https://linuxtv.org/downloads/v4l-utils/${name}.tar.bz2";
    sha256 = "6147ccc29fe7dd3c5c3994d613c4f2a099bac8b44694a96e5cf4d7caca8336c0";
  };

  buildInputs = optionals (channel == "utils") [
    alsa-lib
    xorg.libX11
    qt4
  ] ++ [
    libjpeg-turbo_1-4
  ];

  preConfigure = optionalString (channel == "utils") ''
    configureFlagsArray+=(
      "--with-udevdir=$out/lib/udev"
    )
  '';

  configureFlags = [
    "--enable-libv4l"
  ] ++ (
    if (channel == "utils") then [
    "--enable-v4l-utils"
    "--enable-qv4l2"
  ] else [
    "--without-libudev"
    "--without-udevdir"
    "--disable-v4l-utils"
    "--disable-qv4l2"
  ]);

  postInstall = ''
    # Create symlink for V4l1 compatibility
    ln -sv $out/include/libv4l1-videodev.h $out/include/videodev.h
    mkdir -pv $out/include/linux
    ln -sv $out/include/libv4l1-videodev.h $out/include/linux/videodev.h
  '';

  parallelBuild = false;
  parallelInstall = false;

  meta = with stdenv.lib; {
    description = "V4L utils and libv4l, provide common image formats regardless of the v4l device";
    homepage = http://linuxtv.org/projects.php;
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
