#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="wget2"
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
BLD_CONFIG_BUILD_ADDL_CFLAGS=( "-DMSVC_INVALID_PARAMETER_HANDLING=1" "-DKEEP_OUR_CERT" "-DHAVE_SSIZE_T" "-D_WIN64" )
BLD_CONFIG_BUILD_ADDL_CFLAGS_STATIC=( "-DDLZMA_API_STATIC" "-DHSTS_STATIC" "-DLIBWGET_STATIC" )
BLD_CONFIG_CONFIG_CMD_ADDL=( "--without-libidn2" "--with-lzma" "--with-bzip2" "--without-libidn" "--without-libdane" "--with-ssl=wolfssl" "--without-gpgme" "LEX=/usr/bin/flex" "ac_cv_prog_cc_c99=" )
BLD_CONFIG_GNU_LIBS_ADDL=( "atexit" "pathmax" "ftruncate" "malloca" "fnmatch-gnu" "fnmatch-h" "xstrndup" "unistd" )
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
BLD_CONFIG_CONFIG_CMD_ADDL_DEBUG=( "--enable-assert" )
BLD_CONFIG_OUR_LIB_DEPS=( "libpsl" "pcre2" "zlib" "libhsts" "wolfcrypt" )
BLD_CONFIG_VCPKG_DEPS=( "nghttp2" "zstd" "liblzma" "brotli" "bzip2" )
BLD_CONFIG_PKG_CONFIG_MANUAL_ADD=( "bzip2" )
BLD_CONFIG_GIT_NO_RECURSE=1
BLD_CONFIG_GIT_SUBMODULE_INITS=( "gnulib" )

# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://gitlab.com/gnuwget/wget2.git .
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; # Applies from patches folder repo_BUILD_NAME.patch to the sources
	fi

	if [[ ! -f "lzip.exe" ]]; then
		wget https://download.savannah.gnu.org/releases/lzip/lzip-1.22-w64.zip -O lzip.zip
		unzip -j lzip.zip
	fi
	export PATH="$PATH:./"

	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq "1" ]]; then
		if [[ -z $SKIP_STEP || $SKIP_STEP == "gnulib" ]]; then
			gnulib_switch_to_master_and_patch;
		fi
		cd $BLD_CONFIG_SRC_FOLDER
		if [[ -z $SKIP_STEP || $SKIP_STEP == "bootstrap" ]]; then
			gnulib_add_addl_modules_and_bootstrap;

		fi
	fi

	if [[ $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run autoconf
		autoreconf --symlink --verbose --install
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "vcpkg" ]]; then
		vcpkg_install_package
	fi

	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		touch ABOUT-NLS
		sed -i -E 's/(cat >conftest.l <<_ACEOF)/\1\n%option nounistd/' configure

		configure_apply_fixes_and_run;
	else
		setup_build_env;
	fi

	run_make
	make_install

	finalcommon;
}
ourmain;
