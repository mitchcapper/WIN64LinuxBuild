#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="rsync"
BLD_CONFIG_GNU_LIBS_ADD_TO_REPO=1
BLD_CONFIG_CONFIG_CMD_ADDL=( "--enable-lz4" "--disable-md2man" )
BLD_CONFIG_OUR_LIB_DEPS=( "openssl" "zstd" )
BLD_CONFIG_VCPKG_DEPS=( "xxhash" "lz4" )
BLD_CONFIG_PKG_CONFIG_MANUAL_ADD=( "libxxhash" "liblz4" "libzstd" "openssl" )
BLD_CONFIG_GNU_LIBS_ADDL=( "connect" "sys_wait" "listen" "accept" "asprintf" "getpass-gnu" "vasprintf-gnu" "getsockopt" "strcase" "strerror" "getaddrinfo" "setsockopt" "sleep" "getsockname" "getpeername" "ioctl" "alloca" "alloca-opt" "socket" "bind" "symlink" "unistd" "fsync" "gettimeofday" "sys_socket" "lock" "flock" "signal-h" "sys_ioctl" "symlinkat" "unlinkat" "netinet_in" "arpa_inet" "dirent" "sys_stat" "sys_types" "sys_file" "stdbool" "stat-time" "dirname" "attribute" "dirfd" "dup2" "readlink" "stat-macros" "lstat" "stat-size" "open" "openat" "stdopen" "fcntl" "fcntl-h" "errno" )

# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://github.com/WayneD/rsync.git .
		cp gnulib/build-aux/bootstrap .
		cp gnulib/build-aux/bootstrap.conf .
		#it doesn't use extras so we can just ad ours, they use paxutils to gnulib everyhting
		echo "gnulib_tool_option_extras=\" --without-tests --symlink\"" >> bootstrap.conf
	fi

	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq "1" ]]; then
		if [[ -z $SKIP_STEP || $SKIP_STEP == "gnulib" ]]; then
			gnulib_switch_to_master_and_patch;
		fi
		cd $BLD_CONFIG_SRC_FOLDER
		if [[ -z $SKIP_STEP || $SKIP_STEP == "bootstrap" ]]; then
			gnulib_add_addl_modules_and_bootstrap;
		fi
	fi

	if [[ $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		autoreconf --symlink --verbose --install
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "vcpkg" ]]; then
		vcpkg_install_package
	fi

	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		configure_apply_fixes_and_run;
	else
		setup_build_env;
	fi
	pushd lib
	make
	popd
	run_make
	make_install

	finalcommon;
}
ourmain;
