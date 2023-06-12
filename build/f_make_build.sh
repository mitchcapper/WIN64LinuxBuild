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


BLD_CONFIG_BUILD_NAME="make";
#BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
BLD_CONFIG_CONFIG_CMD_ADDL="ac_cv_func_waitpid=yes" #--disable-nls --enable-static
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
#BLD_CONFIG_GNU_LIBS_USED=0
#BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1

# waitpid
BLD_CONFIG_GNU_LIBS_ADDL=( "opendir" "flexmember" "waitpid" "fnmatch-gnu" "glob" )
#BLD_CONFIG_LOG_EXPAND_VARS=1  # set this to expand vars in log - so this works well but this is the only way I found to properly log the current command in a reproducible form.  It is exceptionally slow.

# after including this script have:
function ourmain() {
	startcommon;
	CFLAGS="-D_WIN32 -D_CRT_SECURE_NO_WARNINGS /wd4668"
	#add_lib_pkg_config  "libpsl" "pcre2" "zlib"
	#add_vcpkg_pkg_config  "openssl"

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps"
fi

	git clone --recurse-submodules https://git.savannah.gnu.org/git/make.git .
	apply_our_repo_patch;
	#it doesn't autolink boostrap does it if it does not
	export GNULIB_SRCDIR="$BLD_CONFIG_SRC_FOLDER/gnulib"
	git clone --recurse-submodules https://github.com/coreutils/gnulib.git

	rm gl/lib/*
	rm gl/modules/*


	add_items_to_gitignore;
	gnulib_switch_to_master_and_patch;
#fi
	gnulib_add_addl_modules_to_bootstrap;


	cd $BLD_CONFIG_SRC_FOLDER
	sed -i -E "s#GNULIB_SRCDIR/gnulib-tool\$#GNULIB_SRCDIR/gnulib-tool.py#g" bootstrap-funclib.sh
	sed -i -E "s#gnulib_tool_option_extras=\$#gnulib_tool_option_extras='--symlink --without-tests'#" bootstrap-funclib.sh
	sed -i -E "s#(make-glob|make-macros)##g" bootstrap.conf

	#vcpkg_install_package "openssl"

	#
	setup_gnulibtool_py_autoconfwrapper
	export ACLOCAL_FLAGS="-I gl/m4"
	./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po
	gnulib_ensure_buildaux_scripts_copied;
	configure_fixes;
	configure_run;

	#setup_build_env;
	#log_make;  #will log all the commands make would run to a file
	rm build-aux/compile
	gnulib_ensure_buildaux_scripts_copied;
	make
	make install

	finalcommon;
}
ourmain;

