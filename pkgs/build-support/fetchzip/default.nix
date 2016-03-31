# This function downloads and unpacks an archive file, such as a zip
# or tar file. This is primarily useful for dynamically generated
# archives, such as GitHub's /archive URLs, where the unpacked content
# of the zip file doesn't change, but the zip file itself may
# (e.g. due to minor changes in the compression algorithm, or changes
# in timestamps).

{ lib
, fetchurl
, unzip
}:

{ # Optionally move the contents of the unpacked tree up one level.
  stripRoot ? true
, url
, extraPostFetch ? ""
, ... } @ args:

let
  tarball = baseNameOf url;
  name' = args.name or (lib.head (lib.splitString "." tarball));
in
lib.overrideDerivation (fetchurl (rec {
  name = "${name'}.tar.xz";

  downloadToTemp = true;

  postFetch = ''
    export PATH=${unzip}/bin:$PATH

    unpackDir="$TMPDIR/unpack"
    mkdir "$unpackDir"
    cd "$unpackDir"

    mv "$downloadedFile" "$TMPDIR/tmp.${tarball}"
    unpackFile "$TMPDIR/tmp.${tarball}"

    shopt -s dotglob
    mkdir "$TMPDIR/${name'}"
  '' + (if stripRoot then ''
    if [ $(ls "$unpackDir" | wc -l) != 1 ]; then
      echo "error: zip file must contain a single file or directory."
      exit 1
    fi
    fn=$(cd "$unpackDir" && echo *)
    if [ -f "$unpackDir/$fn" ]; then
      mv "$unpackDir/$fn" "$TMPDIR/${name'}"
    else
      mv "$unpackDir/$fn"/* "$TMPDIR/${name'}"
    fi
  '' else ''
    mv "$unpackDir"/* "$TMPDIR/${name'}"
  '') + extraPostFetch + ''
    cd "$TMPDIR"

    echo "Fixing mtime and atimes" >&2
    touch -t 200001010000 "${name'}"
    readarray -t files < <(find "${name'}")
    for file in "''${files[@]}"; do
      touch -h -d "@$(stat -c '%Y' "$file")" "$file"
    done

    echo "Building Archive ${name}" >&2
    tar --sort=name --owner=0 --group=0 --numeric-owner --mode=go=rX,u+rw,a-s -cJf "$out" "${name'}"
  '';
} // removeAttrs args [ "name" "downloadToTemp" "postFetch" "stripRoot" "extraPostFetch" ]))
# Hackety-hack: we actually need unzip hooks, too
(x: {nativeBuildInputs = x.nativeBuildInputs++ [unzip];})
