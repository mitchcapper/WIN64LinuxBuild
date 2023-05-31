#!/bin/bash

OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"

PreInitialize;

BLD_CONFIG_BUILD_NAME="sed";
BLD_CONFIG_CONFIG_CMD_ADDL="" #--disable-nls --enable-static
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
BLD_CONFIG_GNU_LIBS_ADDL=( "getopt-gnu" )

# after including this script have:
BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY=0
function ourmain() {
	startcommon;
if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps"
fi

	git clone --recurse-submodules https://github.com/mirror/sed .
	add_items_to_gitignore;
	gnulib_switch_to_master_and_patch;
	gnulib_add_addl_modules_to_bootstrap;
	cd $BLD_CONFIG_SRC_FOLDER
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

