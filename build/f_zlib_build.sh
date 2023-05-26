#!/bin/bash

OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"

PreInitialize;
#BLD_CONFIG_LOG_ON_AT_INIT=0


BLD_CONFIG_BUILD_NAME="zlib";
#BLD_CONFIG_CONFIG_CMD_ADDL="--static --64" #--disable-nls
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
BLD_CONFIG_GNU_LIBS_USED=0
#BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1

#BLD_CONFIG_GNU_LIBS_ADDL=( "lock" )

# Set DO_EXPAND_OF_LOGGED_VARS=1 # set this to expand vars in log - so this works well but this is the only way I found to properly log the current command in a reproducible form.  It is exceptionally slow.
# after including this script have:
function ourmain() {
	startcommon;


if test 5 -gt 100
	then
		echo "Just move the fi down as you want to skip steps"
fi


	git clone --recurse-submodules https://github.com/madler/zlib.git .
	apply_our_repo_patch;
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		sed -i -E 's/^sharedlibdir.+//' zlib.pc.cmakein
		sed -i -E 's/-L\$\{sharedlibdir\}//' zlib.pc.cmakein
		sed -i -E 's/-lz/-lzlibstatic/' zlib.pc.cmakein
	fi
	add_items_to_gitignore;


	cd $BLD_CONFIG_SRC_FOLDER

	#configure_fixes;
	#configure_run;
#	make
#	make install

	#msys_bins_move_end_path;

	#nmake -f win32/Makefile.msc LOC=-D$BLD_CONFIG_INSTALL_FOLDER

	TMP="" TEMP=""
	#no -DBUILD_STATIC_LIBS:BOOL=ON  just turning shared off

	local STATIC_ADD=""
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		STATIC_ADD="-DBUILD_SHARED_LIBS:BOOL=OFF"
	fi

	cmake --install-prefix "$BLD_CONFIG_INSTALL_FOLDER" -DINSTALL_PKGCONFIG_DIR:PATH="${BLD_CONFIG_INSTALL_FOLDER}/lib/pkgconfig" $STATIC_ADD -DBUILD_TEST:BOOL="0" -DENABLE_BINARY_COMPATIBLE_POSIX_API:BOOL="1"  -DCMAKE_CONFIGURATION_TYPES:STRING=Release   -G "Visual Studio 17 2022" -S . -B winbuild
	cmake --build winbuild --config release --verbose
	cmake --install winbuild
	finalcommon;
}
ourmain;

