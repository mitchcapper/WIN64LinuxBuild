#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="zlib"
BLD_CONFIG_CMAKE_STYLE="best"
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_GIT_CLONE_BRANCH="develop"
BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL=( "-DINSTALL_PKGCONFIG_DIR:PATH=[INSTALL_FOLDER]/lib/pkgconfig" "-DENABLE_BINARY_COMPATIBLE_POSIX_API:BOOL=1" )



# ninja, nmake (manifest issue?), nmake-launchers, vs  all work msys(general default) does not
BLD_CONFIG_CMAKE_STYLE="vs"

# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://github.com/madler/zlib.git .
	fi
	
	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; # Applies from patches folder repo_BUILD_NAME.patch to the sources
		if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
			sed -i -E 's/-lz/-lzd/' zlib.pc.cmakein
		fi
		if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
			sed -i -E 's/^sharedlibdir.+//;s/-L\$\{sharedlibdir\}//;s/-lz/-lzs/' zlib.pc.cmakein
		fi
		sed -i -E 's/if\(MSVC\)/if(MSVC OR NOT MSVC)/' CMakeLists.txt
		git_staging_add zlib.pc.cmakein .gitignore CMakeLists.txt #staging them means if we re-apply our patch they are discarded
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
