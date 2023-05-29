#!/bin/bash

OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"

PreInitialize;


BLD_CONFIG_BUILD_NAME="symlinks";
BLD_CONFIG_ADD_WIN_ARGV_LIB=0

#BLD_CONFIG_GNU_LIBS_ADDL=( "symlink" "symlinkat" "ioctl" "unistd" "dirent" "flexmember" )

# after including this script have:
function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps"
fi
	git clone --recurse-submodules https://github.com/mitchcapper/symlinks.git .
	git checkout win32_enhancements

	gnulib_switch_to_master_and_patch;
	gnulib_add_addl_modules_to_bootstrap;
	setup_gnulibtool_py_autoconfwrapper #needed for generated .mk/.ac files but if just stock then the below line likely works
	./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po --force

	add_items_to_gitignore;


	cd $BLD_CONFIG_SRC_FOLDER

	configure_fixes;
	configure_run;
#	setup_build_env;
	#log_make;  #will log all the commands make would run to a file
	make -j 8 || make
	make install

	finalcommon;
}
ourmain;

