#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="make"
BLD_CONFIG_GNU_LIBS_BOOTSTRAP_EXTRAS_ADD="--symlink --without-tests"
BLD_CONFIG_BUILD_ADDL_CFLAGS=( "-D_WIN32" "-D_CRT_SECURE_NO_WARNINGS" "/wd4668" )
BLD_CONFIG_GNU_LIBS_ADDL=( "opendir" "flexmember" "waitpid" "fnmatch-gnu" "glob" "strcasestr" )
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
BLD_CONFIG_CONFIG_CMD_ADDL=( "ac_cv_func_waitpid=yes" "--enable-case-insensitive-file-system" )
BLD_CONFIG_GNU_LIBS_ADD_TO_REPO=1
# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://git.savannah.gnu.org/git/make.git .
	fi
	export GNULIB_SRCDIR="$(convert_to_msys_path "${BLD_CONFIG_SRC_FOLDER}")/gnulib"
	export ACLOCAL_FLAGS="-I gl/m4"
	if [[ -z $SKIP_STEP || $SKIP_STEP == "gnulib_strip" ]]; then
		rm src/w32/include/dirent.h src/w32/compat/dirent.c
		rm gl/lib/*
		rm gl/modules/*
		sed -i -E "s#(make-glob|make-macros)##g" bootstrap.conf
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; # Applies from patches folder repo_BUILD_NAME.patch to the sources
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
