#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="libhsts";
BLD_CONFIG_CONFIG_CMD_ADDL="--enable-static --disable-shared"
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
#BLD_CONFIG_BUILD_DEBUG=1
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1

function ourmain() {
	startcommon;
	export CFLAGS="-DHSTS_STATIC $CFLAGS"

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://gitlab.com/rockdaboot/libhsts .
		add_items_to_gitignore;
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and if found applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch
		SKIP_STEP=""
	fi
	sed -i -E 's/^[ ]*AM_GNU_GETTEXT/#AM_GNU_GETTEXT/g' configure.ac

	if [[ -z $SKIP_STEP || $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		gnulib_ensure_buildaux_scripts_copied
		autoreconf --symlink --verbose --install
		libtool_fixes "build-aux/ltmain.sh" "m4/libtool.m4"
		autoreconf --verbose #update for libtool fixes
		SKIP_STEP=""
	fi
	
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

