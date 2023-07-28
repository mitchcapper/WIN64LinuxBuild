#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="pdcurses";
BLD_CONFIG_CONFIG_CMD_ADDL="" #--disable-nls --enable-static
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
#BLD_CONFIG_BUILD_DEBUG=1
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_CMAKE_STYLE="best"
function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://github.com/Bill-Gray/PDCursesMod .
		add_items_to_gitignore;
		SKIP_STEP=""
	fi
	sed -i -E 's#winspool.lib#winspool.lib user32.lib#g' cmake/project_common.cmake
	local STATIC_ADD=""
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		STATIC_ADD+=" -DPDC_BUILD_SHARED:BOOL=0"
	fi
	if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
		STATIC_ADD+=" -DPDCDEBUG:BOOL=1"
	fi

	setup_build_env;

	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
	#-DCMAKE_STATIC_LINKER_FLAGS:STRING="/machine:x64" 
		cmake_config_run $STATIC_ADD -DPDC_SDL2_DEPS_BUILD:BOOL="0" -DPDC_SDL2_BUILD:BOOL="0" -DPDC_GL_BUILD:BOOL="0" -DPDC_UTF8:BOOL="1" -DPDC_WIDE:BOOL="1"
	fi
	
	cd $BLD_CONFIG_SRC_FOLDER
	cmake_make
	cmake_install

	mv "$BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO/lib" "$BLD_CONFIG_INSTALL_FOLDER/"
	#cant just move the bin folder as the pdb's are already tehre if was debug mode
	mkdir -p "$BLD_CONFIG_INSTALL_FOLDER/bin/"
	mv $BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO/bin/* "$BLD_CONFIG_INSTALL_FOLDER/bin/"
	rmdir "$BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO/bin/" "$BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO"
	INCLUDE_DIR="$BLD_CONFIG_INSTALL_FOLDER/include"
	mkdir -p "$INCLUDE_DIR"
	cp $BLD_CONFIG_SRC_FOLDER/*.h "$INCLUDE_DIR"
	cd "${BLD_CONFIG_CMAKE_BUILD_DIR}"
		copy_pdbs;
	cd ..
	finalcommon;
}
ourmain;

