#!/bin/bash
set -e
set -o pipefail
OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"
SKIP_STEP="${CALL_CMD}"

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
#BLD_CONFIG_BUILD_DEBUG=1
#BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1

function ourmain() {
	startcommon;
	#add_lib_pkg_config  "libpsl" "pcre2" "zlib"
	#add_vcpkg_pkg_config  "openssl"
	#export CFLAGS="-DDEC -i/oth $CFLAGS"
	#export LDFLAGS=" $LDFLAGS"

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://github.com/mitchcapper/BUILD_APP_NAME.git .
		add_items_to_gitignore;
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
	#apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and if found applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch
		SKIP_STEP=""
	fi
	
	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq "1" ]]; then
		if [[ -z $SKIP_STEP || $SKIP_STEP == "gnulib" ]]; then
			gnulib_switch_to_master_and_patch;
			gnulib_add_addl_modules_to_bootstrap;
			SKIP_STEP=""
		fi
		cd $BLD_CONFIG_SRC_FOLDER

		if [[ -z $SKIP_STEP || $SKIP_STEP == "bootstrap" ]]; then
			gnulib_ensure_buildaux_scripts_copied;
			setup_gnulibtool_py_autoconfwrapper #needed for generated .mk/.ac files but if just stock then the below line likely works
			./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po
			SKIP_STEP=""
		fi
	fi
	if [[ $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		autoreconf --symlink --verbose --install
		SKIP_STEP="" #to do all the other steps
	fi
	
	if [[ -z $SKIP_STEP || $SKIP_STEP == "vcpkg" ]]; then
		#vcpkg_install_package "openssl"
		SKIP_STEP=""
	fi
	#gnulib_tool_py_remove_nmd_makefiles

	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		configure_fixes;
		configure_run;
		SKIP_STEP="";
	else
		setup_build_env;
	fi

	if [[ $SKIP_STEP == "makefiles" ]]; then #not empty and not setting empty as this is only a skip to step
		./config.status
	fi

	if [[ $SKIP_STEP == "log_make" ]]; then
		echo "RUNNING log_make"
		log_make;  #will log all the commands make would run to a file
	fi

	make -j 8 || make
	make install

	finalcommon;
}
ourmain;

