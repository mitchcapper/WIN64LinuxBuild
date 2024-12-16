#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="awk"
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
BLD_CONFIG_GNU_LIBS_USED=0

# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://github.com/onetrueawk/awk .
		git checkout makefile
		sed -i -E 's#^(CC|HOSTCC|CFLAGS) =#\1 :=#g' makefile
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; # Applies from patches folder repo_BUILD_NAME.patch to the sources
	fi

	cd $BLD_CONFIG_SRC_FOLDER
	setup_build_env;
	export HOSTCC="${CC}"
	run_make HOSTCC="$HOSTCC" CFLAGS="$CFLAGS" CC="$CC" PREFIX="${BLD_CONFIG_INSTALL_FOLDER}"
	make_install awk HOSTCC="$HOSTCC" CFLAGS="$CFLAGS" CC="$CC" PREFIX="${BLD_CONFIG_INSTALL_FOLDER}"

	finalcommon;
}
ourmain;
