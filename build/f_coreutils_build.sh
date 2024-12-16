#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="coreutils"
BLD_CONFIG_CONFIG_CMD_ADDL=( "fu_cv_sys_mounted_getfsstat=yes" "fu_cv_sys_stat_statvfs=yes" "--enable-no-install-program=chcon,chgrp,chmod,chown,selinux,runcon,mknod,mkfifo,tty,groups,group-list,id,kill,logname,nohup,ptx,split" )
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
BLD_CONFIG_ADD_WIN_ARGV_LIB=1
BLD_CONFIG_GNU_LIBS_ADDL=( "ioctl" "symlink" "unistd" "sigpipe" "fprintf-posix" )
BLD_CONFIG_OUR_OS_FIXES_APPLY_TO_DBG=1
BLD_CONFIG_OUR_OS_FIXES_COMPILE=1

# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://github.com/coreutils/coreutils .
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; # Applies from patches folder repo_BUILD_NAME.patch to the sources
	fi

	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq "1" ]]; then
		if [[ -z $SKIP_STEP || $SKIP_STEP == "gnulib" ]]; then
			gnulib_switch_to_master_and_patch;
			if [[ -f "gl/modules/rename-tests.diff" ]]; then
					git rm gl/modules/link-tests.diff gl/modules/rename-tests.diff
			fi
			git checkout src/od.c src/fmt.c
			sed -i -E "s/([ \t,:;]|^)(CHAR|INT|LONG|SHORT)([ \t,:;]|\\$)/\1SS\2\3/g" src/od.c
			#MS defines WORD already so lets change it
			sed -i -E "s/WORD/GNUWORD/g" src/fmt.c
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
