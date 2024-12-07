#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_CONFIG_ADDL_LIBS="-lcrypt32"
BLD_CONFIG_BUILD_NAME="wget";
BLD_CONFIG_CONFIG_CMD_ADDL=("--with-ssl=openssl") #--disable-nls
BLD_CONFIG_ADD_WIN_ARGV_LIB=1
BLD_CONFIG_GNU_LIBS_ADDL=( "pathmax" "ftruncate" "fnmatch-gnu" "fnmatch-h" "xstrndup" )
BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY_ADDL_MK_FILES_FIX=( "lib/gnulib.mk" )
#BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY=0
#BLD_CONFIG_BUILD_DEBUG=1
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1

function ourmain() {
	startcommon;
	
	if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then #if switching back they should just regen configure
		BLD_CONFIG_CONFIG_CMD_ADDL+=("--enable-assert")
		export CFLAGS="-DENABLE_DEBUG $CFLAGS"
	fi	
	add_lib_pkg_config  "libpsl" "pcre2" "zlib" "openssl"
	#add_vcpkg_pkg_config  "openssl"

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://git.savannah.gnu.org/git/wget.git .
		add_items_to_gitignore;
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and if found applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch
		if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
			sed -i -E "s#PKG_CHECK_MODULES_STATIC#PKG_CHECK_MODULES#g;s#PKG_CHECK_MODULES#PKG_CHECK_MODULES_STATIC#g" configure.ac
		fi

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
			./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po
			sed -i -E 's/(cat >conftest.l <<_ACEOF)/\1\n%option nounistd/' configure
			SKIP_STEP=""
		fi
	fi
	if [[ $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		autoreconf --symlink --verbose --install
		SKIP_STEP="" #to do all the other steps
	fi
	
	if [[ -z $SKIP_STEP || $SKIP_STEP == "vcpkg" ]]; then
		vcpkg_install_package "brotli" "zstd"
		SKIP_STEP=""
	fi
	#gnulib_tool_py_remove_nmd_makefiles

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

