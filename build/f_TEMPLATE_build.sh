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


BLD_CONFIG_BUILD_NAME="BUILD_APP_NAME";
#BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
BLD_CONFIG_CONFIG_CMD_ADDL="" #--disable-nls --enable-static
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
#BLD_CONFIG_GNU_LIBS_USED=0
#BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1

#BLD_CONFIG_GNU_LIBS_ADDL=( "lock" )
#BLD_CONFIG_LOG_EXPAND_VARS=1  # set this to expand vars in log - so this works well but this is the only way I found to properly log the current command in a reproducible form.  It is exceptionally slow.
#BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY=0
#BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY_ADDL_MK_FILES_FIX=( "lib/gnulib.mk" )

function ourmain() {
	startcommon;
	#add_lib_pkg_config  "libpsl" "pcre2" "zlib"
	#add_vcpkg_pkg_config  "openssl"

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps"
fi

	git clone --recurse-submodules https://github.com/mitchcapper/BUILD_APP_NAME.git .

	#apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and if found applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch
	add_items_to_gitignore;
	gnulib_switch_to_master_and_patch;
	gnulib_add_addl_modules_to_bootstrap;

	cd $BLD_CONFIG_SRC_FOLDER
	#vcpkg_install_package "openssl"

	#gnulib_tool_py_remove_nmd_makefiles
	setup_gnulibtool_py_autoconfwrapper #needed for generated .mk/.ac files but if just stock then the below line likely works
	./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po

	gnulib_ensure_buildaux_scripts_copied;
	configure_fixes;
	configure_run;
	#setup_build_env;
	#log_make;  #will log all the commands make would run to a file
	make -j 8 || make
	make install

	finalcommon;
}
ourmain;

