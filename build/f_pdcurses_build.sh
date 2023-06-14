#!/bin/bash

#works but was rfor twin originally which we dont use
OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"
SKIP_STEP="${CALL_CMD}"

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
BLD_CONFIG_BUILD_DEBUG=0
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1

function ourmain() {
	startcommon;


if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://github.com/Bill-Gray/PDCursesMod .
		add_items_to_gitignore;
	fi
	cd $BLD_CONFIG_SRC_FOLDER
	setup_build_env;
	cmake_config_run -DPDC_SDL2_DEPS_BUILD:BOOL="0" -DPDC_SDL2_BUILD:BOOL="0" -DPDC_GL_BUILD:BOOL="0" -DCMAKE_STATIC_LINKER_FLAGS:STRING="/machine:x64" -DPDC_UTF8:BOOL="1" -DPDC_WIDE:BOOL="1"
	#can't do target as install wont work
	#cmake --build winbuild --config release --target wincon_pdcursesstatic
	cmake --build winbuild --config $BLD_CONFIG_CMAKE_BUILD_TARGET_AUTO
	if [[ -d "$BLD_CONFIG_INSTALL_FOLDER" ]]; then
		rm -rf "$BLD_CONFIG_INSTALL_FOLDER"
	fi
	cmake --install winbuild
	
	mv "$BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO/lib" "$BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO/bin" "$BLD_CONFIG_INSTALL_FOLDER/"
	rmdir "$BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO"
	INCLUDE_DIR="$BLD_CONFIG_INSTALL_FOLDER/include"
	mkdir -p "$INCLUDE_DIR"
	cp $BLD_CONFIG_SRC_FOLDER/*.h "$INCLUDE_DIR"

	# git clone --recurse-submodules https://github.com/wmcbrine/PDCurses.git .

	# add_items_to_gitignore;

	# mkdir -p "$BLD_CONFIG_INSTALL_FOLDER" "$BLD_CONFIG_SRC_FOLDER/build"

	# cd "$BLD_CONFIG_SRC_FOLDER/build"
	# export PDCURSES_SRCDIR="$BLD_CONFIG_SRC_FOLDER"

	# # DLL=Y
	# nmake -f "${BLD_CONFIG_SRC_FOLDER}/wincon/Makefile.vc" WIDE=Y UTF8=Y
	# msys_root=$(convert_to_msys_path "$BLD_CONFIG_SRC_FOLDER")
	# cp *.lib "$msys_root"/*.h "$BLD_CONFIG_INSTALL_FOLDER"


	finalcommon;
}
ourmain;

