#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="pcre2"
BLD_CONFIG_CMAKE_STYLE="best"
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL=( "-DZLIB_INCLUDE_DIR=/tmp" "-DZLIB_LIBRARY_DEBUG=" "-DZLIB_LIBRARY_RELEASE=" )
BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL_STATIC=( "-DPCRE2_STATIC_CFLAG:STRING=-DPCRE2_STATIC" )
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1

# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://github.com/PCRE2Project/pcre2 .
	fi

	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		cmake_config_run;
	else
		setup_build_env;
	fi

	cmake_make
	cmake_install

	finalcommon;
}
ourmain;
