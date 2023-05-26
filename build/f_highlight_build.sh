#!/bin/bash

OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"

PreInitialize;

BLD_CONFIG_BUILD_NAME="highlight";
BLD_CONFIG_CONFIG_CMD_ADDL="" #--disable-nls --enable-static
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1

# after including this script have:
function lua_pkg_config_gen() {
	LUA_VERSION=5.4
	PKG_CFG=`cat "${SCRIPT_FOLDER}/patches/lua.pc.template"`
	LUA_ROOT=$(get_install_prefix_for_vcpkg_pkg "lua")
	LUA_PKG_CONFIG_DIR="${LUA_ROOT}/lib/pkgconfig"
	PKG_CFG="${PKG_CFG/LUA_ROOT/"$LUA_ROOT"}"
	PKG_CFG="${PKG_CFG/LUA_VERSION/"$LUA_VERSION"}"
	mkdir -p "$LUA_PKG_CONFIG_DIR"
	echo "${PKG_CFG}" > "${LUA_PKG_CONFIG_DIR}/lua.pc"
}
function ourmain() {
	startcommon;


	MSVC_RUNTIME="MD"

	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		MSVC_RUNTIME="MT"
	fi

	ADL_C_FLAGS="/wd4710 /wd4711 /wd4820 /wd4626 /wd4061 /wd5027 /wd4365"
	ADL_LIB_FLAGS=""

	add_vcpkg_pkg_config  "lua"

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps"
fi

	git clone --recurse-submodules https://gitlab.com/saalen/highlight.git .

	add_items_to_gitignore;

	cd $BLD_CONFIG_SRC_FOLDER

	vcpkg_install_package "lua" "boost-xpressive"
	cd $BLD_CONFIG_SRC_FOLDER
	lua_pkg_config_gen

	if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
		sed -i -E "s#NDEBUG#DEBUG#g" src/Makefile extras/tcl/makefile
		ADL_C_FLAGS+=" /DEBUG"
		ADL_LIB_FLAGS+=" /DEBUG" #-ldebug  for the debug lib
		MSVC_RUNTIME+="d"
	fi

	#change to windows extensions
	sed -i -E 's/[.]o\b/.obj/g' Makefile src/Makefile
	sed -i -E 's/[.]a\b/.lib/g' Makefile src/Makefile
#fi
	sed -i -E 's/^AR=(ar.*)/AR:=\1/g' Makefile src/Makefile
	sed -i -E "s#PREFIX = .+#PREFIX = $BLD_CONFIG_INSTALL_FOLDER#" Makefile
	sed -i -E "s#-std=c..11 ##g" src/Makefile extras/tcl/makefile

#remove the no debug option

	cd $BLD_CONFIG_SRC_FOLDER
	BOOST_ROOT=$(get_install_prefix_for_vcpkg_pkg "boost-xpressive")
	export CFLAGS="-I${BOOST_ROOT}/include /EHsc ${ADL_C_FLAGS} /${MSVC_RUNTIME} -I./ "
	export LDFLAGS="-L${BOOST_ROOT}/lib ${ADL_LIB_FLAGS} /${MSVC_RUNTIME}"
	# -lboost_exception-vc140-mtd
	setup_build_env
	#log_make cli

	make cli
	make install
	finalcommon;
}
ourmain;

