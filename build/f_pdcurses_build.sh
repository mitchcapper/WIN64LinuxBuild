#!/bin/bash

#works but was rfor twin originally which we dont use
OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"
PreInitialize;


BLD_CONFIG_BUILD_NAME="pdcurses";
BLD_CONFIG_CONFIG_CMD_ADDL=""
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
BLD_CONFIG_GNU_LIBS_USED=0

function ourmain() {
	startcommon;


if test 5 -gt 100
	then
		echo "Just move the fi down as you want to skip steps"
fi

	git clone --recurse-submodules https://github.com/wmcbrine/PDCurses.git .

	add_items_to_gitignore;

	mkdir -p "$BLD_CONFIG_INSTALL_FOLDER" "$BLD_CONFIG_SRC_FOLDER/build"

	cd "$BLD_CONFIG_SRC_FOLDER/build"
	export PDCURSES_SRCDIR="$BLD_CONFIG_SRC_FOLDER"

	# DLL=Y
	nmake -f "${BLD_CONFIG_SRC_FOLDER}/wincon/Makefile.vc" WIDE=Y UTF8=Y
	msys_root=$(convert_to_msys_path "$BLD_CONFIG_SRC_FOLDER")
	cp *.lib "$msys_root"/*.h "$BLD_CONFIG_INSTALL_FOLDER"


	finalcommon;
}
ourmain;

