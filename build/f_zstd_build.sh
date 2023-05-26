#!/bin/bash

OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"


PreInitialize;

BLD_CONFIG_BUILD_NAME="zstd";
BLD_CONFIG_ADD_WIN_ARGV_LIB=0;
BLD_CONFIG_GNU_LIBS_USED=0;
function ourmain() {
	startcommon;


if test 5 -gt 100
	then
		echo "Just move the fi down as you want to skip steps"
fi

	git clone --recurse-submodules https://github.com/facebook/zstd .

	add_items_to_gitignore;
#fi
	cd $BLD_CONFIG_SRC_FOLDER/build/cmake

	local STATIC_ADD=""
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		STATIC_ADD="-DZSTD_BUILD_SHARED:BOOL=OFF -DZSTD_BUILD_STATIC:BOOL=ON -DZSTD_USE_STATIC_RUNTIME:BOOL=ON"
	fi

	cmake --install-prefix "$BLD_CONFIG_INSTALL_FOLDER" $STATIC_ADD -DINSTALL_MSVC_PDB:BOOL=OFF  -DCMAKE_CONFIGURATION_TYPES:STRING=Release  -G "Visual Studio 17 2022" -S . -B winbuild
#fi
	cd $BLD_CONFIG_SRC_FOLDER/build/cmake
	cmake --build winbuild --config release
	cmake --install winbuild

	finalcommon;
}
ourmain;

