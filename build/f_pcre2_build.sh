#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="pcre2";
BLD_CONFIG_CONFIG_CMD_ADDL=""
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
#BLD_CONFIG_BUILD_DEBUG=1
BLD_CONFIG_GNU_LIBS_USED=0;
BLD_CONFIG_CMAKE_STYLE="best"
function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then 
		git clone --recurse-submodules https://github.com/PCRE2Project/pcre2 .
		add_items_to_gitignore;
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		#apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and if found applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch
		SKIP_STEP=""
	fi
	
	setup_build_env;
	
	local STATIC_ADD=""
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING ]]; then
		STATIC_ADD='-DPCRE2_STATIC_CFLAG:STRING=-DPCRE2_STATIC'
	fi

	cmake_config_run $STATIC_ADD -DZLIB_INCLUDE_DIR="/tmp" -DZLIB_LIBRARY_DEBUG="" -DZLIB_LIBRARY_RELEASE=""

	cd $BLD_CONFIG_SRC_FOLDER
	cmake_make
	cmake_install
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING ]]; then
		if [[ -e "${BLD_CONFIG_INSTALL_FOLDER}/lib/pcre2-8-static.lib" ]]; then #while this always happens with the VSC build with the cmake unix file build it doesn ot get prefised the same
			sed -i -E 's#-(lpcre2-.)#-\1-static#g' $BLD_CONFIG_INSTALL_FOLDER/lib/pkgconfig/libpcre2-*.pc
		fi
	fi
	finalcommon;
}
ourmain;

