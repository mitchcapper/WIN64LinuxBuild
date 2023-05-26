#!/bin/bash

OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"




PreInitialize;
#recommend having bzip2 gzip zstd etc in path for those just like linux
BLD_CONFIG_BUILD_NAME="tar";
BLD_CONFIG_CONFIG_CMD_ADDL="--enable-threads=windows"
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
BLD_CONFIG_GNU_LIBS_ADDL=( "lock" "thread" "sigpipe" "glob" "ioctl" "symlink" "unistd" "sys_time" "sys_wait" "ftello" "ftruncate" "system-posix" "posix_spawn" "pipe-posix" "close" "fclose" "fopen-gnu" "open" "posix_spawnattr_setsigdefault" "posix_spawnattr_getsigmask" "posix_spawnattr_getflags" "posix_spawnattr_setflags" "posix_spawnattr_setsigmask" "posix_spawnp" "stdio" "nonblocking" "poll" "pipe2" "signal-h" "sys_types" "sys_stat" "fcntl-h" "fcntl" "stdbool-c99" "waitpid" "sys_file" )

function ourmain() {
	startcommon;


if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps"
fi
	git clone --recurse-submodules https://git.savannah.gnu.org/git/tar.git .

	echo "gnulib_tool_option_extras=\" --without-tests --symlink\"" >> bootstrap.conf
	cd $BLD_CONFIG_SRC_FOLDER
	apply_our_repo_patch;
	add_items_to_gitignore;

	cd $BLD_CONFIG_SRC_FOLDER
	gnulib_switch_to_master_and_patch;

	gnulib_add_addl_modules_to_bootstrap;
	cd $BLD_CONFIG_SRC_FOLDER/paxutils
	apply_our_repo_patch "paxutils"

	git checkout bootstrap.conf
	#it doesn't use extras so we can just add ours, they use paxutils to gnulib everyhting
	echo "gnulib_tool_option_extras=\" --without-tests --symlink\"" >> bootstrap.conf
	cd $BLD_CONFIG_SRC_FOLDER
	sed -E -i 's/\-\-avoid=lock//' bootstrap.conf; #it has lock in avoid but we actually do need it for
	sed -E -i 's#m4/lock.m4##' bootstrap.conf; #same;0

	cd $BLD_CONFIG_SRC_FOLDER
	setup_gnulibtool_py_autoconfwrapper; #need this for the autoconf patch
	./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po --gen

	gnulib_ensure_buildaux_scripts_copied;

	configure_fixes;
	configure_run;


	make
	make install

	finalcommon;
}
ourmain;

