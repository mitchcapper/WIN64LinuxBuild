#!/bin/bash

OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"
PreInitialize;


BLD_CONFIG_BUILD_NAME="wget";
BLD_CONFIG_CONFIG_CMD_ADDL="--with-ssl=openssl" #--disable-nls
BLD_CONFIG_ADD_WIN_ARGV_LIB=1

BLD_CONFIG_GNU_LIBS_ADDL=( "pathmax" "ftruncate" "fnmatch-gnu" "fnmatch-h" "xstrndup" )
BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY_ADDL_MK_FILES_FIX=( "lib/gnulib.mk" )
BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY=0
function ourmain() {
	startcommon;
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		BLD_CONFIG_CONFIG_CMD_ADDL+=" --enable-static"
	fi

	add_lib_pkg_config  "libpsl" "pcre2" "zlib"
	add_vcpkg_pkg_config  "openssl"

if test 5 -gt 100
	then
		echo "Just move the fi down as you want to skip steps"
fi
	git clone --recurse-submodules https://git.savannah.gnu.org/git/wget.git .
	apply_our_repo_patch;

	add_items_to_gitignore;

	gnulib_add_addl_modules_to_bootstrap;

	gnulib_switch_to_master_and_patch;

	cd $BLD_CONFIG_SRC_FOLDER

	setup_gnulibtool_py_autoconfwrapper
	./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po
	# while the main configure does detect no unistd.h and properly does not include it, lex does not and when it detects it missing from itself it tries to include the C version so we modify the lex test file to include an option that it doesnt need it and everyone wins
	sed -i -E 's/(cat >conftest.l <<_ACEOF)/\1\n%option nounistd/' configure

	#rm -rf libbin_nettle libbin_gnutls || true
	#wget https://github.com/ShiftMediaProject/nettle/releases/download/nettle_3.8.1_release_20220727/libnettle_nettle_3.8.1_release_20220727_msvc17.zip -O nettle.zip
	#mkdir -p libbin_nettle && cd libbin_nettle && unzip ../nettle.zip
	#cd $BLD_CONFIG_SRC_FOLDER
	#wget https://www.gnupg.org/ftp/gcrypt/gnutls/v3.7/gnutls-3.7.8-w64.zip -O gnutls.zip
	#its naming is weird for things so lets fix it to be somewhat normalized to support #include gnutls/X  and lib as a not dll fake name
	#mkdir -p libbin_gnutls && cd libbin_gnutls && unzip ../gnutls.zip && mv win64-build/lib/includes win64-build/lib/gnutls && mv win64-build/lib/libgnutls.dll.a win64-build/lib/libgnutls.lib
	#this move will fail if run before (well twice before first time just subfolder;0) probably should rm it?


	gnulib_ensure_buildaux_scripts_copied;

	cd $BLD_CONFIG_SRC_FOLDER
	configure_fixes;
#fi
	cd $BLD_CONFIG_SRC_FOLDER
	vcpkg_install_package "openssl"

	cd $BLD_CONFIG_SRC_FOLDER
	configure_run;

	make
	make install

	finalcommon;
}
ourmain;

