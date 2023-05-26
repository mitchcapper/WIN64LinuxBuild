#!/bin/bash

OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"

set -e
PreInitialize;


BLD_CONFIG_BUILD_NAME="which";
BLD_CONFIG_CONFIG_CMD_ADDL=""
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1
set -e
function ourmain() {
	startcommon;
set -e

if test 5 -gt 100
	then
		echo "Just move the fi down as you want to skip steps"
fi
	git clone --recurse-submodules https://github.com/mitchcapper/which.git .

	add_items_to_gitignore;

#fi

	cd $BLD_CONFIG_SRC_FOLDER
	git clone https://github.com/CarloWood/cwautomacros.git cwautomacros
	cd cwautomacros
	make install

	rm  /usr/share/cwautomacros/scripts/depcomp.sh #we want autogen newer one

	cd $BLD_CONFIG_SRC_FOLDER

	./autogen.sh

	configure_fixes;

	configure_run;

	make
	make install

	finalcommon;
}
ourmain;
