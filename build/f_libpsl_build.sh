#!/bin/bash
set -e
OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"

PreInitialize;

BLD_CONFIG_BUILD_NAME="libpsl";
BLD_CONFIG_CONFIG_ADL_LIBS=""
BLD_CONFIG_CONFIG_CMD_ADDL="--disable-runtime --enable-builtin --enable-static --disable-shared" #--disable-nls
#libicu is a PITA and the only binaries they put out are shared not static libs, and its huge af

BLD_CONFIG_ADD_WIN_ARGV_LIB=0
BLD_CONFIG_GNU_LIBS_USED=0
#it actually have native win support and the gnu compat ones break it
function ourmain() {
	set -e
	startcommon;
	ICU_ROOT="${BLD_CONFIG_SRC_FOLDER}/icu"
	CFLAGS="-DPSL_STATIC -DU_STATIC_IMPLEMENTATION -DU_IMPORT" #just doing --enable-static is not enough and -D U_IMPORT is required to override the defualt dll import as it doesnt check static

# note this needs libtool and libunistring   ( pacman -S icu libtool ) you could get around the libtool requirement if you used a libtool release source and build in local folder

if test 5 -gt 100
	then
		echo "Just move the fi down as you want to skip steps"
fi

	git clone --recurse-submodules https://github.com/rockdaboot/libpsl .


	cd $BLD_CONFIG_SRC_FOLDER

	# wget https://github.com/unicode-org/icu/releases/download/release-72-1/icu4c-72_1-Win64-MSVC2019.zip -O icu.zip
	# unzip -j icu.zip
	# mkdir -p "$ICU_ROOT"
	# cd "$ICU_ROOT"
	# unzip ../icu-windows.zip
	# ICU_PKG_CFG=`cat "${SCRIPT_FOLDER}/patches/libpsl-icu-uc.pc.template"`
	# echo "${ICU_PKG_CFG/ICU_ROOT/"$ICU_ROOT"}" > "${ICU_ROOT}/icu-uc.pc"

	add_items_to_gitignore;
	git checkout libpsl.pc.in
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		sed -i -E 's/^(Cflags: )/\1-DPSL_STATIC -DU_STATIC_IMPLEMENTATION -DU_IMPORT /' libpsl.pc.in
	fi
	./autogen.sh

	cd $BLD_CONFIG_SRC_FOLDER

	#sed  -E 's/^(SUBDIRS .+)(tools|fuzz tests|tests)/\1/' Makefile.am
	#local PKG_CFG_PATH=$(convert_to_msys_path "${ICU_ROOT}")
	#export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${PKG_CFG_PATH}"
	configure_run;

	make
	make install

	finalcommon;
}
ourmain;

