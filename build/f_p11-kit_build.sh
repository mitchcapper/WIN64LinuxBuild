#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="p11-kit"
BLD_CONFIG_OUR_LIB_DEPS=("libtasn1")
BLD_CONFIG_OUR_LIB_BINS_PATH=("libtasn1")
BLD_CONFIG_CONFIG_CMD_ADDL=( "--without-systemd" "--without-trust-paths" "--enable-debug=no" "--without-libffi" ) #for debug wil loverride with addl_debug
BLD_CONFIG_CONFIG_CMD_ADDL_DEBUG=( "--enable-debug=yes" )
BLD_CONFIG_BUILD_ADDL_CFLAGS_STATIC=("-DASN1_STATIC") #doesnt get used as we force static off for now
BLD_CONFIG_GNU_LIBS_ADD_TO_REPO=1
BLD_CONFIG_GNU_LIBS_ADDL=( "ssize_t" "getopt-gnu" )


#BLD_CONFIG_VCPKG_DEPS=( "libffi" )

# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
	BLD_CONFIG_BUILD_ADDL_CFLAGS=( "${BLD_CONFIG_BUILD_ADDL_CFLAGS_STATIC[@]}" ) #need this to still prevent static 
	BLD_CONFIG_PREFER_STATIC_LINKING=0 #they manually prevent static linking due to having to call their init??
fi



function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://github.com/p11-glue/p11-kit .
		#sed -i -E 's#build/##' configure.ac part of our patch now
		#sed -i -E 's#NEED_READPASSPHRASE#!OS_WIN32#' common/Makefile.am #macro only defined is os=unix
	fi
	
	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		if [[ $BLD_CONFIG_GNU_LIBS_ADD_TO_REPO -eq "1" ]]; then
			git restore --staged gnulib .gitmodules #we need to unstage them from our clone
		fi
		apply_our_repo_patch; # Applies from patches folder repo_BUILD_NAME.patch to the sources
		cp gnulib/build-aux/bootstrap .
		cp gnulib/build-aux/bootstrap.conf .
		mkdir -p m4
		cp build/m4/ld-version-script.m4 m4/
		echo "gnulib_tool_option_extras=\" --without-tests --symlink --m4-base=m4 --lib=libp11kit --source-base=lib --cache-modules\"" >> bootstrap.conf
		git_staging_add bootstrap bootstrap.conf 
		if [[ $BLD_CONFIG_GNU_LIBS_ADD_TO_REPO -eq "1" ]]; then
			git_staging_add .gitmodules gnulib
		fi
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
	if [[ -z $SKIP_STEP || $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		gnulib_ensure_buildaux_scripts_copied
		autoreconf --symlink --verbose --install
		libtool_fixes
		autoreconf --verbose #update for libtool fixes
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

	run_make
	make_install

	finalcommon;
}
ourmain;
