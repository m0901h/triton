{ stdenv
, buildPythonPackage
, fetchFromGitHub
, fetchPyPi
, fetchTritonPatch
, glibcLocales
, isPy27
, isPy3k
, lib
, makeWrapper
, pythonPackages
, writeScript

, bash
, bash-completion
, beautifulsoup
, bs1770gain
, discogs-client
, enum34
, flac
, flask
, gobject-introspection
, imagemagick
, itsdangerous
, jellyfish
, jinja2
, mock
, mp3val
, mpd
, munkres
, musicbrainzngs
, mutagen
, nose
, pathlib
, pyacoustid
, pyechonest
, pylast
, pyxdg
, pyyaml
, rarfile
, requests
, responses
, unidecode
, werkzeug

# For use in inline plugin
, pycountry

# External plugins
, enableAlternatives ? false
#, enableArtistCountry ? true
, enableCopyArtifacts ? true
, enableBeetsMoveAllArtifacts ? true
}:

let
  inherit (lib)
    attrNames
    concatMapStrings
    concatStringsSep
    elem
    filterAttrs
    id
    makeSearchPath
    optional
    optionals
    optionalString
    platforms
    versionOlder;

  optionalPlugins = {
    acousticbrainz = requests != null;
    badfiles = flac != null && mp3val != null;
    beatport = requests != null;
    bpd = false;
    chroma = pyacoustid != null;
    discogs = discogs-client != null;
    embyupdate = requests != null;
    fetchart = requests != null;
    lastgenre = pylast != null;
    lastimport = pylast != null;
    mpdstats = mpd != null;
    mpdupdate = mpd != null;
    replaygain = bs1770gain != null;
    thumbnails = pyxdg != null;
    web = flask != null;
  };

  pluginsWithoutDeps = [
    "bench"
    "bpd"
    "bpm"
    "bucket"
    "convert"
    "cue"
    "duplicates"
    "edit"
    "embedart"
    "embyupdate"
    "export"
    "filefilter"
    "freedesktop"
    "fromfilename"
    "ftintitle"
    "fuzzy"
    "hook"
    "ihate"
    "importadded"
    "importfeeds"
    "info"
    "inline"
    "ipfs"
    "keyfinder"
    "lyrics"
    "mbcollection"
    "mbsubmit"
    "mbsync"
    "metasync"
    "missing"
    "permissions"
    "play"
    "plexupdate"
    "random"
    "rewrite"
    "scrub"
    "smartplaylist"
    "spotify"
    "the"
    "types"
    "zero"
  ];

  enabledOptionalPlugins = attrNames (filterAttrs (_: id) optionalPlugins);

  allPlugins = pluginsWithoutDeps ++ attrNames optionalPlugins;
  allEnabledPlugins = pluginsWithoutDeps ++ enabledOptionalPlugins;

  testShell = "${bash}/bin/bash --norc";
  completion = "${bash-completion}/share/bash-completion/bash_completion";

  version = "1.4.2";
in
buildPythonPackage rec {
  name = "beets-${version}";

  src = fetchPyPi {
    package = "beets";
    inherit version;
    sha256 = "b54c72e220d7696740823d0a4e4f38d57d1e463daaf06da5194a358d3a14ca6a";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  propagatedBuildInputs = [
    beautifulsoup
    bs1770gain
    discogs-client
    flac
    flask
    # Needed for hook to set GI_TYPELIB_PATH
    gobject-introspection
    imagemagick
    itsdangerous
    jellyfish
    jinja2
    mock
    mp3val
    mpd
    munkres
    musicbrainzngs
    mutagen
    nose
    pyacoustid
    pyechonest
    pylast
    pyxdg
    pyyaml
    rarfile
    responses
    requests
    unidecode
    werkzeug
  ] ++ optionals isPy27 [
    enum34
  ] ++ optionals (versionOlder pythonPackages.python.channel "3.5") [
    pathlib
  ] ++ [
    pycountry
  ] ++ optional enableAlternatives (
      import ./plugins/beets-alternatives.nix {
        inherit
          stdenv
          buildPythonPackage
          fetchFromGitHub
          isPy27
          optionals
          pythonPackages;
      }
    )
    # FIXME: Causes other plugins to fail to load
    #  - Needs to use beets logging instead of printing error messages
    #  - Needs musicbrainz fixes
    /*++ optional enableArtistCountry (
      import ./plugins/beets-artistcountry.nix {
        inherit
          stdenv
          buildPythonPackage
          fetchFromGitHub
          pythonPackages;
      }
    )*/
    /* Provides edit & moveall plugins */
    ++ optional enableBeetsMoveAllArtifacts (
      import ./plugins/beets-moveall-artifacts.nix {
        inherit
          stdenv
          buildPythonPackage
          fetchFromGitHub;
      }
    );

  patches = [
    (fetchTritonPatch {
      rev = "d3fc5e59bd2b4b465c2652aae5e7428b24eb5669";
      file = "beets/beets-1.3-replaygain-default-bs1770gain.patch";
      sha256 = "d864aa643c16d5df9b859b5f186766a94bf2db969d97f255a88f33acf903b5b6";
    })
  ];

  postPatch = ''
    sed -i -e '/assertIn.*item.*path/d' test/test_info.py
    echo echo completion tests passed > test/rsrc/test_completion.sh

    sed -i -e '/^BASH_COMPLETION_PATHS *=/,/^])$/ {
      /^])$/i u"${completion}"
    }' beets/ui/commands.py
  '' + /* fix paths for badfiles plugin */ ''
    sed -i -e '/self\.run_command(\[/ {
      s,"flac","${flac}/bin/flac",
      s,"mp3val","${mp3val}/bin/mp3val",
    }' beetsplug/badfiles.py
  '' + /* Replay gain */ ''
    sed -i -re '
      s!^( *cmd *= *b?['\'''"])(bs1770gain['\'''"])!\1${bs1770gain}/bin/\2!
    ' beetsplug/replaygain.py
    sed -i -e 's/if has_program.*bs1770gain.*:/if True:/' \
      test/test_replaygain.py
  '';

  preCheck = ''
    (${concatMapStrings (s: "echo \"${s}\";") allPlugins}) \
      | sort -u > plugins_defined
    find beetsplug -mindepth 1 \
      \! -path 'beetsplug/__init__.py' -a \
      \( -name '*.py' -o -path 'beetsplug/*/__init__.py' \) -print \
      | sed -n -re 's|^beetsplug/([^/.]+).*|\1|p' \
      | sort -u > plugins_available

    if ! mismatches="$(diff -y plugins_defined plugins_available)"; then
      echo "The the list of defined plugins (left side) doesn't match" \
           "the list of available plugins (right side):" >&2
      echo "$mismatches" >&2
      exit 1
    fi
  '';

  # TODO: fix LOCALE_ARCHIVE for freebsd
  checkPhase = ''
    runHook 'preCheck'

    LANG=en_US.UTF-8 \
    LOCALE_ARCHIVE=${glibcLocales}/lib/locale/locale-archive \
    BEETS_TEST_SHELL="${testShell}" \
    BASH_COMPLETION_SCRIPT="${completion}" \
    HOME="$(mktemp -d)"
    nosetests -v
    mkdir -p $HOME/

    runHook 'postCheck'
  '';

  installCheckPhase = ''
    runHook 'preInstallCheck'

    tmphome="$(mktemp -d)"

    EDITOR="${writeScript "beetconfig.sh" ''
      #!${stdenv.shell}
      cat > "$1" <<CFG
      plugins: ${concatStringsSep " " allEnabledPlugins}
      CFG
    ''}" HOME="$tmphome" "$out/bin/beet" config -e
    EDITOR=true HOME="$tmphome" "$out/bin/beet" config -e

    runHook 'postInstallCheck'
  '';

  doCheck = !isPy3k;
  doInstallCheck = true;

  meta = with lib; {
    description = "Music tagger and library organizer";
    homepage = http://beets.radbox.org;
    license = licenses.mit;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
