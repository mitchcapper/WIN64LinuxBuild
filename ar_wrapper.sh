#!/bin/bash
set -e
#don't need this if using msys2 ar.exe instead take x86_64-w64-mingw32-ar.exe from https://packages.msys2.org/package/mingw-w64-cross-binutils?repo=msys&variant=x86_64
convert_from_msys_path () {
	local WPATH=$1
	if ! [ -z ${MSYS+x} ]; then
		WPATH=`cygpath -m "$WPATH"`
	fi
	echo $WPATH
}

OPTIONS="$@"
for file in "$@"; do
	[[ $file = /[A-Za-z]/* ]] && file=$(convert_from_msys_path "$file")
    set -- "$@" "$file"
    shift
done
exec ar.exe "$@"

