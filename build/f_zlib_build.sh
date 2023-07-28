#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="zlib";
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
		git clone  --branch develop --recurse-submodules https://github.com/madler/zlib.git .
		add_items_to_gitignore;
		#echo -e 'set(CMAKE_DEBUG_POSTFIX "d")\nadd_definitions(-D_CRT_SECURE_NO_DEPRECATE)\nadd_definitions(-D_CRT_NONSTDC_NO_DEPRECATE)' >> CMakeLists.txt		
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and if found applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch
		if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
			sed -i -E 's/^sharedlibdir.+//' zlib.pc.cmakein
			sed -i -E 's/-L\$\{sharedlibdir\}//' zlib.pc.cmakein
			sed -i -E 's/-lz/-lzlibstatic/' zlib.pc.cmakein
		fi
		sed -i -E 's/if\(MSVC\)/if(MSVC OR NOT MSVC)/' CMakeLists.txt
		SKIP_STEP=""
	fi
	
	
	setup_build_env;



#	sed -i -E 's/ \\M[TD]//g' CMakeLists.txt #we will add our own flags	
	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		cmake_config_run -DINSTALL_PKGCONFIG_DIR:PATH="${BLD_CONFIG_INSTALL_FOLDER}/lib/pkgconfig" -DENABLE_BINARY_COMPATIBLE_POSIX_API:BOOL="1"
	fi
	find -name "flags.make" | xargs sed -i -E 's#(/M[TtDd]{1,2})\s+/M[TtDd]{1,2}\b#\1#g' #not sure where the \MT icomes from but we gotta remove
	cmake_make
	cmake_install

	finalcommon;
}
ourmain;

