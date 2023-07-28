#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="tar";
BLD_CONFIG_CONFIG_CMD_ADDL="--enable-threads=windows"
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
#BLD_CONFIG_BUILD_DEBUG=1
BLD_CONFIG_GNU_LIBS_ADDL=(  "lock" "thread" "sigpipe" "glob" "ioctl" "sys_time" "sys_wait" "ftello" "ftruncate" "system-posix" "posix_spawn" "pipe-posix" "close" "fclose" "fopen-gnu" "open" "posix_spawnattr_setsigdefault" "posix_spawnattr_getsigmask" "posix_spawnattr_getflags" "posix_spawnattr_setflags" "posix_spawnattr_setsigmask" "posix_spawnp" "stdio" "nonblocking" "poll" "pipe2" "signal-h" "sys_types" "sys_stat" "fcntl-h" "fcntl" "stdbool-c99" "waitpid" "sys_file" )

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://git.savannah.gnu.org/git/tar.git .
		add_items_to_gitignore;
		echo "gnulib_tool_option_extras=\" --without-tests --symlink\"" >> bootstrap.conf
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and if found applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch
		SKIP_STEP=""
	fi
	
	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq "1" ]]; then
		if [[ -z $SKIP_STEP || $SKIP_STEP == "gnulib" ]]; then
			gnulib_switch_to_master_and_patch;
			SKIP_STEP=""
		fi
		cd $BLD_CONFIG_SRC_FOLDER

		if [[ -z $SKIP_STEP || $SKIP_STEP == "paxutils" ]]; then
			cd $BLD_CONFIG_SRC_FOLDER/paxutils
			apply_our_repo_patch "paxutils"

			git checkout bootstrap.conf
			#it doesn't use extras so we can just add ours, they use paxutils to gnulib everyhting
			echo "gnulib_tool_option_extras=\" --without-tests --symlink\"" >> bootstrap.conf
		fi
		cd $BLD_CONFIG_SRC_FOLDER

		if [[ -z $SKIP_STEP || $SKIP_STEP == "bootstrap" ]]; then
			gnulib_add_addl_modules_to_bootstrap;		
			gnulib_ensure_buildaux_scripts_copied;
			setup_gnulibtool_py_autoconfwrapper #needed for generated .mk/.ac files but if just stock then the below line likely works
			sed -E -i 's/\-\-avoid=lock//' bootstrap.conf; #it has lock in avoid but we actually do need it for
			sed -E -i 's#m4/lock.m4##' bootstrap.conf; #same;0
			./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po --gen
			SKIP_STEP=""
		fi
	fi
	if [[ $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		autoreconf --symlink --verbose --install
		SKIP_STEP=""
	fi
	
	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		configure_fixes;
		configure_run;
		SKIP_STEP="";
	else
		setup_build_env;
	fi

	if [[ $SKIP_STEP == "makefiles" ]]; then #not empty and not setting empty as this is only a skip to step
		./config.status
	fi

	if [[ -n "${LOG_MAKE_RUN}" ]]; then
		run_logged_make;
	fi

	make -j 8 || make
	make_install

	finalcommon;
}
ourmain;

