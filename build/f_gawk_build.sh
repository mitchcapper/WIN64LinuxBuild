#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="gawk";

#BLD_CONFIG_BUILD_DEBUG=1
BUILD_MSVC_IGNORE_WARNINGS=(4068)
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
BLD_CONFIG_GNU_LIBS_ADDL=( "mkstemp" "fts" "sys_socket" "strcasestr" "regex" "random" "flexmember" "setlocale" "locale" "dfa" "sleep" "strsignal" "sys_ioctl" "connect" "listen" "accept" "fnmatch-h" "fnmatch-gnu" "recvfrom" "bind" "setsockopt" "getsockopt" "getopt-gnu" "shutdown" "sys_random" "popen" "pclose" "socket" "strcase" "timegm" "setenv" "unsetenv" "usleep" "fprintf-gnu" )

BLD_CONFIG_CONFIG_CMD_ADDL=(ac_cv_search_dlopen="none required" "--enable-extensions" "--enable-threads=windows" "acl_shlibext=dll" "ac_cv_header_dlfcn_h=yes")
BLD_CONFIG_PREFER_STATIC_LINKING=0 #we need shared for extension dlls not sure if we can build both at once
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
function ourmain() {
	startcommon;
	 if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
	 	BLD_CONFIG_CONFIG_CMD_ADDL+=("--enable-static" "--disable-shared")
	 else
	 	BLD_CONFIG_CONFIG_CMD_ADDL+=("--disable-static" "--enable-shared")
	 fi
if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://git.savannah.gnu.org/git/gawk.git .
		git submodule add https://github.com/coreutils/gnulib
		cp gnulib/build-aux/bootstrap .
		cp gnulib/build-aux/bootstrap.conf .
		echo "gnulib_tool_option_extras=\" --without-tests --symlink --m4-base=m4 --lib=libgawk --source-base=lib --cache-modules\"" >> bootstrap.conf
		git mv m4 m4_orig
		mkdir -p m4
		mkdir -p pc/old
		mv pc/* pc/old/ || true
		pushd m4
		cp -s -t . ../m4_orig/socket.m4 ../m4_orig/arch.m4 ../m4_orig/noreturn.m4 ../m4_orig/pma.m4 ../m4_orig/triplet-transformation.m4
		popd
		echo "EXTRA_DIST = " > m4/Makefile.am
		add_items_to_gitignore;
		SKIP_STEP=""
	fi
	if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
		touch .developing
	else
		rm .developing &>/dev/null || true
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

		if [[ -z $SKIP_STEP || $SKIP_STEP == "bootstrap" ]]; then
			gnulib_add_addl_modules_to_bootstrap;		
			gnulib_ensure_buildaux_scripts_copied;
			setup_gnulibtool_py_autoconfwrapper #needed for generated .mk/.ac files but if just stock then the below line likely works
			./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po --force
			gnulib_ensure_buildaux_scripts_copied --forced;
			SKIP_STEP=""
		fi
	fi

	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		configure_fixes;
		configure_run;
		echo "#include <osfixes.h>" > "lib/dlfcn.h"
		SKIP_STEP="";
	else
		setup_build_env;
	fi

	if [[ $SKIP_STEP == "makefiles" ]]; then #not empty and not setting empty as this is only a skip to step
		./config.status
	fi
	MAKE_ADD=('DEFPATH="\"./;%%PROGRAMDATA%%/gawk/share\""' 'DEFLIBPATH="\"./;%%PROGRAMDATA%%/gawk/lib\""')
	if [[ -n "${LOG_MAKE_RUN}" ]]; then
		run_logged_make $BLD_CONFIG_BUILD_MAKE_BIN "${MAKE_ADD[@]}";
	fi
	ex $BLD_CONFIG_BUILD_MAKE_BIN "${MAKE_ADD[@]}" -j 8 ||  ex $BLD_CONFIG_BUILD_MAKE_BIN "${MAKE_ADD[@]}"
	make_install "${MAKE_ADD[@]}"
	mkdir -p $BLD_CONFIG_INSTALL_FOLDER/ProgramData/lib $BLD_CONFIG_INSTALL_FOLDER/ProgramData/share $BLD_CONFIG_INSTALL_FOLDER/ProgramData/libexec
	mv $BLD_CONFIG_INSTALL_FOLDER/lib/gawk/* $BLD_CONFIG_INSTALL_FOLDER/ProgramData/lib/
	mv $BLD_CONFIG_INSTALL_FOLDER/libexec/awk/* $BLD_CONFIG_INSTALL_FOLDER/ProgramData/libexec/
	mv $BLD_CONFIG_INSTALL_FOLDER/share/awk/* $BLD_CONFIG_INSTALL_FOLDER/ProgramData/share/
	rmdir $BLD_CONFIG_INSTALL_FOLDER/lib/gawk/ $BLD_CONFIG_INSTALL_FOLDER/libexec/awk/ $BLD_CONFIG_INSTALL_FOLDER/share/awk/ $BLD_CONFIG_INSTALL_FOLDER/lib/ $BLD_CONFIG_INSTALL_FOLDER/libexec/

	finalcommon;
}
ourmain;
