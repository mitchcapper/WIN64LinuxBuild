#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="wget2";
BLD_CONFIG_CONFIG_CMD_ADDL=(--without-libidn2 --with-lzma --with-bzip2 --without-libidn --without-libdane --with-ssl=wolfssl --disable-shared --enable-static --without-gpgme LEX=/usr/bin/flex ac_cv_prog_cc_c99=) #wget2 requires c99, msvc supports c11 but not dynamic arrays so lets force it
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
BLD_CONFIG_GNU_LIBS_ADDL=( "atexit" "pathmax" "ftruncate" "malloca" "fnmatch-gnu" "fnmatch-h" "xstrndup" )
BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY_ADDL_MK_FILES_FIX=( "lib/gnulib.mk" )
#BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY=0
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1

function ourmain() {
	if [[ "$BLD_CONFIG_BUILD_DEBUG" -eq "1" ]]; then
		BLD_CONFIG_CONFIG_CMD_ADDL+=("--enable-assert")
	fi
	startcommon;
	add_lib_pkg_config  "libpsl" "pcre2" "zlib" "libhsts" "wolfcrypt"
	# "zlib-ng"
	add_vcpkg_pkg_config  "nghttp2" "zstd" "liblzma" "brotli" "bzip2"

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
	OLDPATH="$PATH"

	if [[ -z $SKIP_STEP || $SKIP_STEP == "vcpkg" ]]; then
		TAR_BASE=$(get_install_prefix_for_pkg "tar")
		TAR_BASE=$(convert_to_msys_path "$TAR_BASE")
		export PATH="$TAR_BASE/bin:$PATH"
		vcpkg_install_package "zlib-ng" "nghttp2" "zstd" "liblzma" "brotli" "bzip2"
		#vcpkg_remove_package "wolfssl";
		#vcpkg_install_package --head fix_wolf_src "wolfssl";
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
	export PATH="$OLDPATH:./"

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

	if [[ -n "${LOG_MAKE_RUN}" ]]; then
		run_logged_make;
	fi

	if [[ $CALL_CMD == "log_undefines" ]]; then
		FL="undefined.txt"
		echo "Logging undefined symbols to ${FL}"
		make | rg --no-line-number -oP "unresolved external symbol.+referenced" | sed -E 's#unresolved external symbol(.+)referenced#\1#g' | sort -u > $FL
		exit 1
	fi
	make -j 8 || make
	make_install

	finalcommon;
}
ourmain;

