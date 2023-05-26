#!/bin/bash

OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"


PreInitialize;


BLD_CONFIG_BUILD_NAME="grep";
BLD_CONFIG_CONFIG_CMD_ADDL="ac_cv_prog_cc_g=no --enable-perl-regexp";
BLD_CONFIG_ADD_WIN_ARGV_LIB=1;
BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY=0
#BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY_ADDL_MK_FILES_FIX=( "lib/gnulib.mk" )
BLD_CONFIG_GNU_LIBS_ADDL=("alloca" "alloca-opt")
function ourmain() {
	startcommon;
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		BLD_CONFIG_CONFIG_CMD_ADDL+=" --enable-static --disable-shared"
	fi
	add_lib_pkg_config "pcre2"

if test 5 -gt 100; then
	echo "Just move the fi down as you want to skip steps"
fi

	git clone --recurse-submodules https://git.savannah.gnu.org/git/grep.git .

	add_items_to_gitignore;
	gnulib_add_addl_modules_to_bootstrap;

	gnulib_switch_to_master_and_patch;
#fi
	cd $BLD_CONFIG_SRC_FOLDER

	setup_gnulibtool_py_autoconfwrapper;
	./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po

	gnulib_ensure_buildaux_scripts_copied;

	configure_fixes;
	configure_run;

	make
	make install

	finalcommon;
}
ourmain;

