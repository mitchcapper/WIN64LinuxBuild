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


BLD_CONFIG_BUILD_NAME="rsync";
BLD_CONFIG_CONFIG_CMD_ADDL="--enable-lz4 --disable-md2man" #--disable-nls --enable-static
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
#BLD_CONFIG_GNU_LIBS_USED=0
#BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1
#BLD_CONFIG_LOG_FILE_AUTOTAIL=0

#BLD_CONFIG_LOG_EXPAND_VARS=1
BLD_CONFIG_GNU_LIBS_ADDL=( "getsockopt" "strcase" "strerror" "getaddrinfo" "setsockopt" "sleep" "getsockname" "getpeername" "ioctl" "alloca" "alloca-opt" "socket" "bind" "symlink" "unistd" "fsync" "gettimeofday" "sys_socket" "lock" "flock" "signal-h" "sys_ioctl" "symlink" "symlinkat" "unlinkat" "netinet_in" "arpa_inet" "dirent" "sys_stat" "sys_types" "sys_file" "stdbool" "stat-time" "dirname" "attribute" "dirfd" "dup2" "readlink" "stat-macros" "lstat" "stat-size" "stat-time" "open" "openat" "stdopen" "fcntl" "fcntl-h" "errno" )

# Set DO_EXPAND_OF_LOGGED_VARS=1 # set this to expand vars in log - so this works well but this is the only way I found to properly log the current command in a reproducible form.  It is exceptionally slow.
# after including this script have:
function ourmain() {
	startcommon;
	#CFLAGS="-I ./lib/"
	add_lib_pkg_config  "zstd"
	add_vcpkg_pkg_config  "openssl" "xxhash" "lz4"
	pkg_config_manual_add "libzstd" "openssl" "libxxhash" "liblz4"

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps"
#fi

	git clone --recurse-submodules https://github.com/WayneD/rsync.git .

	git clone --recurse-submodules https://github.com/coreutils/gnulib
	cp gnulib/build-aux/bootstrap .
	cp gnulib/build-aux/bootstrap.conf .
	#it doesn't use extras so we can just ad ours, they use paxutils to gnulib everyhting
	echo "gnulib_tool_option_extras=\" --without-tests --symlink\"" >> bootstrap.conf
	gnulib_switch_to_master_and_patch;
fi
	gnulib_add_addl_modules_to_bootstrap;

	setup_gnulibtool_py_autoconfwrapper #needed for generated .mk/.ac files but if just stock then the below line likely works
	#gnulib_tool_py_remove_nmd_makefiles;
	./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po --force

	add_items_to_gitignore;

	cd $BLD_CONFIG_SRC_FOLDER
	vcpkg_install_package "openssl" "xxhash" "lz4"
#	pkg_config_manual_add "libzstd" "openssl" "libxxhash" "liblz4"
#fi

#not sure why we have to do this somethinng isnnt autogening right or nwe need lib moved up in the make order
	cp c:/software/gnulib/build-aux/compile "${BLD_CONFIG_BUILD_AUX_FOLDER}/"
	#sometimes runnning make requires re-running make
	#

	cd $BLD_CONFIG_SRC_FOLDER
#fi
	configure_fixes;
	configure_run || (./config.status --recheck && configure_run);


	setup_build_env;
	cd $BLD_CONFIG_SRC_FOLDER/lib && (make || make)
	cd $BLD_CONFIG_SRC_FOLDER
	make
	make install

	finalcommon;
}
ourmain;

