#!/bin/bash

OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"

PreInitialize;

BLD_CONFIG_BUILD_NAME="pcre2";
BLD_CONFIG_GNU_LIBS_USED=0;
BLD_CONFIG_ADD_WIN_ARGV_LIB=0;
BLD_CONFIG_GNU_LIBS_USED=0;

function ourmain() {
	startcommon;


if test 5 -gt 100
	then
		echo "Just move the fi down as you want to skip steps"
fi

	git clone https://github.com/PCRE2Project/pcre2 .

	add_items_to_gitignore;

	cd $BLD_CONFIG_SRC_FOLDER

	local STATIC_ADD=""
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING ]]; then
		STATIC_ADD='-DPCRE2_STATIC_CFLAG:STRING=-DPCRE2_STATIC'
	fi
	cmake --install-prefix "$BLD_CONFIG_INSTALL_FOLDER" ${STATIC_ADD} -DBUILD_SHARED_LIBS:BOOL=OFF -DBUILD_STATIC_LIBS:BOOL=ON -DINSTALL_MSVC_PDB:BOOL=OFF -DPCRE2_BUILD_PCRE2GREP:BOOL=OFF -DPCRE2_BUILD_PCRE2_16:BOOL=OFF -DCMAKE_CONFIGURATION_TYPES:STRING=Release -DPCRE2_BUILD_PCRE2_32:BOOL=OFF -DPCRE2_BUILD_PCRE2_8:BOOL=ON -DPCRE2_BUILD_TESTS:BOOL=OFF -DPCRE2_DEBUG:BOOL=OFF -DPCRE2_REBUILD_CHARTABLES:BOOL=OFF -DPCRE2_SHOW_REPORT:BOOL=ON -DPCRE2_STATIC_PIC:BOOL=ON -DPCRE2_STATIC_RUNTIME:BOOL=ON -DPCRE2_SUPPORT_BSR_ANYCRLF:BOOL=ON -DPCRE2_SUPPORT_JIT:BOOL=ON -DPCRE2_SUPPORT_UNICODE:BOOL=ON -DPCRE2_SUPPORT_VALGRIND:BOOL=OFF  -G "Visual Studio 17 2022" -S . -B winbuild
	cmake --build winbuild --config release
	cmake --install winbuild
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING ]]; then
		sed -i -E 's#-lpcre2-8#-lpcre2-8-static#g' $BLD_CONFIG_INSTALL_FOLDER/lib/pkgconfig/libpcre2-8.pc
	fi
	finalcommon;
}
ourmain;

