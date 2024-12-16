#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="pdcurses"
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_CMAKE_STYLE="best"
BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL=( "-DPDC_SDL2_DEPS_BUILD:BOOL=0" "-DPDC_SDL2_BUILD:BOOL=0" "-DPDC_GL_BUILD:BOOL=0" "-DPDC_UTF8:BOOL=1" "-DPDC_WIDE:BOOL=1" )
BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL_DEBUG=( "-DPDCDEBUG:BOOL=1" )
BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL_STATIC=( "-DPDC_BUILD_SHARED:BOOL=0" )
BLD_CONFIG_CONFIG_ADDL_LIBS=("-luser32")
BLD_CONFIG_BUILD_ADDL_LDFLAGS=("-luser32")
# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://github.com/Bill-Gray/PDCursesMod .
		sed -i -E 's#winspool.lib#winspool.lib user32.lib#g' cmake/project_common.cmake
	fi

	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		cmake_config_run;
	else
		setup_build_env;
	fi

	cmake_make
	cmake_install
	ex mv "$BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO/lib" "$BLD_CONFIG_INSTALL_FOLDER/"
	ex mkdir -p "$BLD_CONFIG_INSTALL_FOLDER/bin/"
	ex mv $BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO/bin/* "$BLD_CONFIG_INSTALL_FOLDER/bin/"
	ex rmdir "$BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO/bin/" "$BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO"
	INCLUDE_DIR="$BLD_CONFIG_INSTALL_FOLDER/include"
	ex mkdir -p "$INCLUDE_DIR"
	ex cp $BLD_CONFIG_SRC_FOLDER/*.h "$INCLUDE_DIR"

	finalcommon;
}
ourmain;
