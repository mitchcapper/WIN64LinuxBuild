#!/bin/bash
set -e
set -o pipefail
OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"
SKIP_STEP="${CALL_CMD}"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"

PreInitialize;
#BLD_CONFIG_LOG_ON_AT_INIT=0


BLD_CONFIG_BUILD_NAME="wget2";
#BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
#for bzip2 it doesnt use pkg-config during configure for some reason, we will just tell it we have it.
#ac_cv_search_BZ2_bzDecompress=y 
BLD_CONFIG_CONFIG_CMD_ADDL="--without-libidn2 --with-lzma --with-bzip2 --without-libidn --without-libdane --with-ssl=wolfssl --disable-shared --enable-static --without-gpgme LEX=/usr/bin/flex ac_cv_prog_cc_c99=" #wget2 requires c99, msvc supports c11 but not dynamic arrays so lets force it
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
#BLD_CONFIG_GNU_LIBS_USED=0
#BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1

#BLD_CONFIG_GNU_LIBS_ADDL=( "lock" )
#BLD_CONFIG_LOG_EXPAND_VARS=1  # set this to expand vars in log - so this works well but this is the only way I found to properly log the current command in a reproducible form.  It is exceptionally slow.
BLD_CONFIG_GNU_LIBS_ADDL=( "atexit" "pathmax" "ftruncate" "fnmatch-gnu" "fnmatch-h" "xstrndup" )
BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY_ADDL_MK_FILES_FIX=( "lib/gnulib.mk" )
BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY=1
BLD_CONFIG_BUILD_DEBUG=0
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
#  KEEP_OUR_CERT DEBUG_WOLFSSL
function fix_wolf_src(){
	#We have to use master to get wget2 to not ail on certain domains due to newer sigs, but need to fix this declare.  If they ever fix their compile failure will have to figoure out a better way to edit the portfile.
	## so the macro this is in assigns a suffix we cant double suffix
	sed -i -E 's#(0x[f0]{0,2}f0f0f0f0f0f0f0f0?)U\)#\1)#g' "${BLD_CONFIG_VCPKG_DIR}/buildtrees/wolfssl/src/head/"*"/wolfcrypt/src/aes.c"
	# we also need to fix the fact we need it compiled with KEEP_OUR_CERT
	PORT_FILE="${BLD_CONFIG_VCPKG_DIR}/ports/wolfssl/portfile.cmake"
	sed -i -E 's#-DWOLFSSL_DES_ECB#-DSESSION_CERTS\\ -DDOPENSSL_EXTRA\\ -DKEEP_OUR_CERT\\ -DSESSION_CERTS#g' "$PORT_FILE"
	vcpkg_install_package --head "wolfssl"
	
}
function ourmain() {
	if [[ "$BLD_CONFIG_BUILD_DEBUG" -eq "1" ]]; then
		BLD_CONFIG_CONFIG_CMD_ADDL+=" --enable-assert"
	fi
	startcommon;
	add_lib_pkg_config  "libpsl" "pcre2" "zlib" "libhsts"
	add_vcpkg_pkg_config  "wolfssl" "nghttp2" "zlib-ng" "zstd" "liblzma" "brotli" "bzip2"

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
	#can't recurse as wiki has invalid paths for win 
		git clone https://gitlab.com/gnuwget/wget2.git .
		git submodule init gnulib
		git submodule update gnulib
		add_items_to_gitignore;
		#we really do want symlinks thanks...
		sed -i -E 's#install --copy#install#g' bootstrap
		sed -i -E 's#--force#--symlink#g' bootstrap
		sed -i -E 's#--no-changelog#--symlink#g' bootstrap
		
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and if found applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch
		SKIP_STEP=""
	fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "vcpkg" ]]; then
		vcpkg_install_package "zlib-ng" "nghttp2" "zstd" "liblzma" "brotli" "bzip2"
		vcpkg_remove_package "wolfssl";
		vcpkg_install_package --head fix_wolf_src "wolfssl";
		SKIP_STEP=""
	fi
	BZIP_INCL=`pkg-config -cflags-only-I bzip2`
	BZIP_LIB=`pkg-config --libs-only-L bzip2`
	export CFLAGS="-DLIBWGET_STATIC -DOPENSSL_EXTRA -DHSTS_STATIC -DLZMA_API_STATIC -DKEEP_OUR_CERT -DHAVE_SSIZE_T -D_WIN64 ${BZIP_INCL} $CFLAGS"
	export LDFLAGS="${BZIP_LIB} $LDFLAGS"

	cd $BLD_CONFIG_SRC_FOLDER
	if [[ ! -f "lzip.exe" ]]; then
		wget https://download.savannah.gnu.org/releases/lzip/lzip-1.22-w64.zip -O lzip.zip
		unzip -j lzip.zip
	fi
	export PATH="$PATH:./"

	if [[ $BLD_CONFIG_GNU_LIBS_USED ]]; then
		cd $BLD_CONFIG_SRC_FOLDER
		if [[ -z $SKIP_STEP || $SKIP_STEP == "gnulib" ]]; then
			gnulib_switch_to_master_and_patch;
			gnulib_add_addl_modules_to_bootstrap;
			SKIP_STEP=""
		fi
		cd $BLD_CONFIG_SRC_FOLDER

		if [[ -z $SKIP_STEP || $SKIP_STEP == "bootstrap" ]]; then
			gnulib_ensure_buildaux_scripts_copied;
			setup_gnulibtool_py_autoconfwrapper #needed for generated .mk/.ac files but if just stock then the below line likely works
			./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po
			SKIP_STEP=""
		fi
	fi
	if [[ $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		autoreconf --symlink --verbose --install
		gnulib_ensure_buildaux_scripts_copied;
		SKIP_STEP="" #to do all the other steps
	fi
	#NDEBUG

	cd $BLD_CONFIG_SRC_FOLDER
	touch ABOUT-NLS	
	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		configure_fixes;
		export CPP="./build-aux/compile cl.exe /E"
		sed -i -E 's/(cat >conftest.l <<_ACEOF)/\1\n%option nounistd/' configure
		configure_run;
		SKIP_STEP=""
	else
		setup_build_env;
	fi

	if [[ $SKIP_STEP == "makefiles" ]]; then #not empty and not setting empty as this is only a skip to step
		./config.status
	fi

	if [[ $SKIP_STEP == "log_make" ]]; then
		echo "RUNNING log_make"
		log_make;  #will log all the commands make would run to a file
	fi
	if [[ $CALL_CMD == "log_undefines" ]]; then
		FL="undefined.txt"
		echo "Logging undefined symbols to ${FL}"
		make | rg --no-line-number -oP "unresolved external symbol.+referenced" | sed -E 's#unresolved external symbol(.+)referenced#\1#g' | sort -u > $FL
		exit 1
	fi
	make -j 8 || make
	make install

	finalcommon;
}
ourmain;

