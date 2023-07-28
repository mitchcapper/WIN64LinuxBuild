#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="automake";

BLD_CONFIG_BUILD_DEBUG=0 #never use debug we dont have an advantage and it leaves artifacts it then compalins about
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://github.com/autotools-mirror/automake .
		add_items_to_gitignore;
		SKIP_STEP=""
	fi
	
	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -z $SKIP_STEP || $SKIP_STEP == "bootstrap_fix" ]]; then
		attrib -r /s "bin/*"
		attrib -r /s "t/*"
		mv bootstrap bootstrap.in
		head bootstrap.in -n -3 > bootstrap #remove lines that remove the temp dir we need for the perl module
		./bootstrap
	fi
	PERL_P=$(convert_to_msys_path "${BLD_CONFIG_SRC_FOLDER}/automake-1.16")
	export PERL5LIB="${PERL_P}"

	cd $BLD_CONFIG_SRC_FOLDER
	if [[ $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		autoreconf --symlink --verbose --install --force
		SKIP_STEP=""
	fi
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
