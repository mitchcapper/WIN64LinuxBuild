#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="make";

#BLD_CONFIG_BUILD_DEBUG=1
BLD_CONFIG_CONFIG_CMD_ADDL=("ac_cv_func_waitpid=yes" "--enable-case-insensitive-file-system")
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
BLD_CONFIG_GNU_LIBS_ADDL=( "opendir" "flexmember" "waitpid" "fnmatch-gnu" "glob" "strcasestr" )



function ourmain() {
	startcommon;
	CFLAGS="-D_WIN32 -D_CRT_SECURE_NO_WARNINGS /wd4668"
if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://git.savannah.gnu.org/git/make.git .
		add_items_to_gitignore;
		rm src/w32/include/dirent.h src/w32/compat/dirent.c
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and if found applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "gnulib_add" ]]; then
		export GNULIB_SRCDIR="$BLD_CONFIG_SRC_FOLDER/gnulib"
		git clone --recurse-submodules https://github.com/coreutils/gnulib.git

		rm gl/lib/*
		rm gl/modules/*
	fi
	
	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq "1" ]]; then
		if [[ -z $SKIP_STEP || $SKIP_STEP == "gnulib" ]]; then
			gnulib_switch_to_master_and_patch;
			sed -i -E "s#GNULIB_SRCDIR/gnulib-tool\$#GNULIB_SRCDIR/gnulib-tool.py#g" bootstrap-funclib.sh
			sed -i -E "s#gnulib_tool_option_extras=\$#gnulib_tool_option_extras='--symlink --without-tests'#" bootstrap-funclib.sh
			sed -i -E "s#(make-glob|make-macros)##g" bootstrap.conf			
			SKIP_STEP=""
		fi
		cd $BLD_CONFIG_SRC_FOLDER

		export ACLOCAL_FLAGS="-I gl/m4"
		if [[ -z $SKIP_STEP || $SKIP_STEP == "bootstrap" ]]; then
			gnulib_add_addl_modules_to_bootstrap;		
			gnulib_ensure_buildaux_scripts_copied;
			setup_gnulibtool_py_autoconfwrapper #needed for generated .mk/.ac files but if just stock then the below line likely works
			./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po
			SKIP_STEP=""
		fi
	fi
	if [[ $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		autoreconf --symlink --verbose --install
		SKIP_STEP=""
	fi
	
	
	cd $BLD_CONFIG_SRC_FOLDER
	rm build-aux/{compile,ar-lib}
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
