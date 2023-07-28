#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="awk";
BLD_CONFIG_CONFIG_CMD_ADDL="" #
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
#BLD_CONFIG_BUILD_DEBUG=1
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1


function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://github.com/onetrueawk/awk .
		add_items_to_gitignore;
		git checkout makefile
		sed -i -E 's#^(CC|HOSTCC|CFLAGS) =#\1 :=#g' makefile
		SKIP_STEP=""
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
			./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po
			SKIP_STEP=""
		fi
	fi
	if [[ $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		autoreconf --symlink --verbose --install
		SKIP_STEP=""
	fi
	
	if [[ -z $SKIP_STEP || $SKIP_STEP == "vcpkg" ]]; then
		
		SKIP_STEP=""
	fi

	cd $BLD_CONFIG_SRC_FOLDER
	setup_build_env;

	export HOSTCC="$CC"
	if [[ $SKIP_STEP == "makefiles" ]]; then #not empty and not setting empty as this is only a skip to step
		./config.status
	fi

	if [[ -n "${LOG_MAKE_RUN}" ]]; then
		run_logged_make make awk HOSTCC="$HOSTCC" CFLAGS="$CFLAGS" CC="$CC"
	fi

	make_install awk HOSTCC="$HOSTCC" CFLAGS="$CFLAGS" CC="$CC" PREFIX="${BLD_CONFIG_INSTALL_FOLDER}"

	finalcommon;
}
ourmain;

