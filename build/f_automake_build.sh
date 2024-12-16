#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="automake"
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1

# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	#export CFLAGS="-DDEC -I/oth $CFLAGS"
	#export LDFLAGS=" $LDFLAGS" #for additional libs use CONFIG_ADDL_LIBS
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://github.com/autotools-mirror/automake .
		add_items_to_gitignore;
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then

		apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch

		SKIP_STEP=""
	fi

	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then

		configure_apply_fixes_and_run;

		SKIP_STEP="";
	else
		setup_build_env;
	fi
	cd $BLD_CONFIG_SRC_FOLDER

	run_make
	make_install

	finalcommon;
}
ourmain;
