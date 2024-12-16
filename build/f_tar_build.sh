#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="tar"
BLD_CONFIG_GNU_LIBS_ADDL=( "lock" "thread" "sigpipe" "glob" "ioctl" "sys_time" "sys_wait" "ftello" "ftruncate" "system-posix" "posix_spawn" "pipe-posix" "close" "fclose" "fopen-gnu" "open" "posix_spawnattr_setsigdefault" "posix_spawnattr_getsigmask" "posix_spawnattr_getflags" "posix_spawnattr_setflags" "posix_spawnattr_setsigmask" "posix_spawnp" "stdio" "nonblocking" "poll" "pipe2" "signal-h" "sys_types" "sys_stat" "fcntl-h" "fcntl" "stdbool-c99" "waitpid" "sys_file" "netdb" "mkdir" "wait-process" "getaddrinfo" )
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1

# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://git.savannah.gnu.org/git/tar.git .
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; # Applies from patches folder repo_BUILD_NAME.patch to the sources
		sed -E -i 's/\-\-avoid=lock//;s#m4/lock.m4##' bootstrap.conf; #it has lock in avoid but we actually do need it for
	fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "paxutils" ]]; then
		pushd $BLD_CONFIG_SRC_FOLDER/paxutils
		apply_our_repo_patch "paxutils"

		git checkout bootstrap.conf
		#it doesn't use extras so we can just add ours, they use paxutils to gnulib everyhting
		echo "gnulib_tool_option_extras=\" --without-tests --symlink\"" >> bootstrap.conf
		popd
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

	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		configure_apply_fixes_and_run;
	else
		setup_build_env;
	fi

	run_make
	make_install

	finalcommon;
}
ourmain;
