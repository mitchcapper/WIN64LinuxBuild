#!/bin/bash

OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"

PreInitialize;

BLD_CONFIG_BUILD_NAME="automake";
BLD_CONFIG_CONFIG_CMD_ADDL="" #--disable-nls --enable-static
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps"
fi

	git clone --recurse-submodules https://github.com/autotools-mirror/automake .

	add_items_to_gitignore;
	cd $BLD_CONFIG_SRC_FOLDER

	attrib -r /s "bin/*"
  	attrib -r /s "t/*"
	mv bootstrap bootstrap.in
	head bootstrap.in -n -3 > bootstrap #remove linse that remove the temp dir we need for the perl module
	./bootstrap
	PERL_P=$(convert_to_msys_path "${BLD_CONFIG_SRC_FOLDER}/automake-1.16")
	export PERL5LIB="${PERL_P}"
	configure_fixes;
	configure_run;
	#setup_build_env;
	#log_make;  #will log all the commands make would run to a file
	make -j 8 || make
	make install

	finalcommon;
}
ourmain;

