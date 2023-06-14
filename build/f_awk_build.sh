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


BLD_CONFIG_BUILD_NAME="awk";
#BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
BLD_CONFIG_CONFIG_CMD_ADDL="" #--disable-nls --enable-static
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1

#BLD_CONFIG_GNU_LIBS_ADDL=( "lock" )
#BLD_CONFIG_LOG_EXPAND_VARS=1  # set this to expand vars in log - so this works well but this is the only way I found to properly log the current command in a reproducible form.  It is exceptionally slow.
#BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY=0
#BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY_ADDL_MK_FILES_FIX=( "lib/gnulib.mk" )
#BLD_CONFIG_BUILD_DEBUG=1
#BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://github.com/onetrueawk/awk .
		add_items_to_gitignore;
		git checkout makefile
		sed -i -E 's#^(CC|HOSTCC|CFLAGS) =#\1 :=#g' makefile

		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and if found applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch
		SKIP_STEP=""
	fi
	
	setup_build_env;
	export HOSTCC="$CC"

	if [[ $SKIP_STEP == "log_make" ]]; then
		echo "RUNNING log_make"
		log_make --trace --debug HOSTCC="$HOSTCC" CC="$CC" awk;  #will log all the commands make would run to a file
	fi

	make install awk HOSTCC="$HOSTCC" CFLAGS="$CFLAGS" CC="$CC" PREFIX="${BLD_CONFIG_INSTALL_FOLDER}"
	if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
		cp awk.pdb "$BLD_CONFIG_INSTALL_FOLDER/bin"
	fi

	finalcommon;
}
ourmain;

