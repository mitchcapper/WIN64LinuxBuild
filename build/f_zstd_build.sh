#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="zstd";
BLD_CONFIG_CONFIG_CMD_ADDL="" 
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
#BLD_CONFIG_BUILD_DEBUG=1
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_CMAKE_SRC_DIR="build/cmake"
BLD_CONFIG_CMAKE_STYLE="best"
function ourmain() {
	startcommon;


if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://github.com/facebook/zstd .
		add_items_to_gitignore;
		SKIP_STEP=""
	fi

	#cd $BLD_CONFIG_SRC_FOLDER/build/cmake
	
	
	setup_build_env;

	local STATIC_ADD=""
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		STATIC_ADD="-DZSTD_BUILD_SHARED:BOOL=OFF -DZSTD_BUILD_STATIC:BOOL=ON -DZSTD_USE_STATIC_RUNTIME:BOOL=ON"
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		cmake_config_run $STATIC_ADD
	fi
	
	cd $BLD_CONFIG_SRC_FOLDER
	cmake_make
	cmake_install

	finalcommon;
}
ourmain;

