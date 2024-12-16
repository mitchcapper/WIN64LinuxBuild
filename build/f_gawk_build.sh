#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="gawk"
BLD_CONFIG_GNU_LIBS_ADD_TO_REPO=1
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
BLD_CONFIG_GNU_LIBS_ADDL=( "mkstemp" "fts" "sys_socket" "strcasestr" "regex" "random" "flexmember" "setlocale" "locale" "dfa" "sleep" "strsignal" "sys_ioctl" "connect" "listen" "accept" "fnmatch-h" "fnmatch-gnu" "recvfrom" "bind" "setsockopt" "getsockopt" "getopt-gnu" "shutdown" "sys_random" "popen" "pclose" "socket" "strcase" "timegm" "setenv" "unsetenv" "usleep" "fprintf-gnu" )
BLD_CONFIG_BUILD_MSVC_IGNORE_WARNINGS=( "4068" )
BLD_CONFIG_CONFIG_CMD_ADDL=( "ac_cv_search_dlopen=\"none required\"" "--enable-extensions" "--enable-threads=windows" "acl_shlibext=dll" "ac_cv_header_dlfcn_h=yes" )
BLD_CONFIG_BUILD_MAKE_CMD_ADDL=( "DEFPATH=\"\\\"./;%%PROGRAMDATA%%/gawk/share\\\"\"" "DEFLIBPATH=\"\\\"./;%%PROGRAMDATA%%/gawk/lib\\\"\"" )
BLD_CONFIG_PREFER_STATIC_LINKING=0

# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://git.savannah.gnu.org/git/gawk.git .
		cp gnulib/build-aux/bootstrap .
		cp gnulib/build-aux/bootstrap.conf .
		echo "gnulib_tool_option_extras=\" --without-tests --symlink --m4-base=m4 --lib=libgawk --source-base=lib --cache-modules\"" >> bootstrap.conf
		git mv m4 m4_orig
		git rm build-aux/*
		mkdir -p m4
		mkdir -p pc/old
		mv pc/* pc/old/ || true
		pushd m4
		cp -s -t . ../m4_orig/socket.m4 ../m4_orig/arch.m4 ../m4_orig/noreturn.m4 ../m4_orig/pma.m4 ../m4_orig/triplet-transformation.m4
		popd
		echo "EXTRA_DIST = " > m4/Makefile.am
		add_items_to_gitignore;
		git_staging_add bootstrap bootstrap.conf
		git_staging_commit #need to commit it up so that the bootstrap files are avail for our gnulib patching by default all local changes are stashed	
	fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; # Applies from patches folder repo_BUILD_NAME.patch to the sources
	fi
	if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 && ! -e .developing ]]; then
		touch .developing
	else
		rm .developing &>/dev/null || true
	fi
	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq "1" ]]; then
		if [[ -z $SKIP_STEP || $SKIP_STEP == "gnulib" ]]; then
			gnulib_switch_to_master_and_patch;
		fi
		cd $BLD_CONFIG_SRC_FOLDER
		if [[ -z $SKIP_STEP || $SKIP_STEP == "bootstrap" ]]; then
			gnulib_add_addl_modules_and_bootstrap;
			autoreconf --symlink --verbose --install --force #needed to get libtool
			gnulib_ensure_buildaux_scripts_copied --forced
			libtool_fixes

		fi
	fi

	if [[ $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		autoreconf --symlink --verbose --install
		SKIP_STEP=""
	fi
	gnulib_ensure_buildaux_scripts_copied --forced
	export BLD_CONFIG_GNU_LIBS_AUTORECONF_DISABLE_FORCE=1
	setup_gnulibtool_py_autoconfwrapper
	
	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		configure_apply_fixes_and_run;
		echo "#include <osfixes.h>" > "lib/dlfcn.h"
		sed -i -E 's#"none required"##' Makefile awklib/Makefile
	else
		setup_build_env;
	fi

	run_make
	make_install
	mkdir -p $BLD_CONFIG_INSTALL_FOLDER/ProgramData/lib $BLD_CONFIG_INSTALL_FOLDER/ProgramData/share $BLD_CONFIG_INSTALL_FOLDER/ProgramData/libexec
	mv $BLD_CONFIG_INSTALL_FOLDER/lib/gawk/* $BLD_CONFIG_INSTALL_FOLDER/ProgramData/lib/
	mv $BLD_CONFIG_INSTALL_FOLDER/libexec/awk/* $BLD_CONFIG_INSTALL_FOLDER/ProgramData/libexec/
	mv $BLD_CONFIG_INSTALL_FOLDER/share/awk/* $BLD_CONFIG_INSTALL_FOLDER/ProgramData/share/
	rmdir $BLD_CONFIG_INSTALL_FOLDER/lib/gawk/ $BLD_CONFIG_INSTALL_FOLDER/libexec/awk/ $BLD_CONFIG_INSTALL_FOLDER/share/awk/ $BLD_CONFIG_INSTALL_FOLDER/lib/ $BLD_CONFIG_INSTALL_FOLDER/libexec/
	finalcommon;
}
ourmain;
