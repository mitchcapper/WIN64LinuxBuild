#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="highlight";

#BLD_CONFIG_BUILD_DEBUG=1
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1
BLD_CONFIG_BUILD_MSVC_IGNORE_WARNINGS=(4710 4711 4820 4626 4061 5027 4365 4514 4668 5267 5204 5026)
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1

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
	add_vcpkg_pkg_config  "lua"

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://gitlab.com/saalen/highlight.git .
		add_items_to_gitignore;
		SKIP_STEP=""
	fi

	cd $BLD_CONFIG_SRC_FOLDER

	if [[ -z $SKIP_STEP || $SKIP_STEP == "vcpkg" ]]; then
		vcpkg_install_package "lua" "boost-xpressive"
		cd $BLD_CONFIG_SRC_FOLDER
		lua_pkg_config_gen
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "makefile_fixes" ]]; then
		if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
			sed -i -E "s#NDEBUG#DEBUG#g" src/Makefile extras/tcl/makefile
		fi
		#change to windows extensions
		sed -i -E 's/[.]o\b/.obj/g' Makefile src/Makefile
		sed -i -E 's/[.]a\b/.lib/g' Makefile src/Makefile
		
		sed -i -E 's/^AR=(ar.*)/AR?=\1/g' Makefile src/Makefile #allow manually specifing AR
		sed -i -E 's/\$\{CXX\} \$\{LDFLAGS\}/${CXX} ${CFLAGS}/g' src/Makefile #this only happens once, and its for linking the main executable, while LD is more on track we need the other translations that compile does so we will use the compiler.  We need to use this over CXX_COMPILE as it has the -c command which forces compile only
		sed -i -E "s#PREFIX = .+#PREFIX = $BLD_CONFIG_INSTALL_FOLDER#" Makefile
		sed -i -E "s#-std=c..11 #-std:c11 #g" src/Makefile extras/tcl/makefile

	fi

	cd $BLD_CONFIG_SRC_FOLDER
	BOOST_ROOT=$(get_install_prefix_for_vcpkg_pkg "boost-xpressive")
	export CFLAGS="-I${BOOST_ROOT}/include /EHsc -I./ "
	export LDFLAGS="-L${BOOST_ROOT}/lib"

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		#apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and if found applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch
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
		vcpkg_install_package "lua" "boost-xpressive"
		cd $BLD_CONFIG_SRC_FOLDER
		lua_pkg_config_gen
		SKIP_STEP=""
	fi

	cd $BLD_CONFIG_SRC_FOLDER
	BOOST_ROOT=$(get_install_prefix_for_vcpkg_pkg "boost-xpressive")
	export CFLAGS="-I${BOOST_ROOT}/include /EHsc -I./ "
	export LDFLAGS="-L${BOOST_ROOT}/lib"
	setup_build_env;


	if [[ $SKIP_STEP == "makefiles" ]]; then #not empty and not setting empty as this is only a skip to step
		./config.status
	fi

	if [[ -n "${LOG_MAKE_RUN}" ]]; then
		run_logged_make;
	fi

	make -j 8 || make
	make_install
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		mkdir -p "${BLD_CONFIG_INSTALL_FOLDER}/lib/"
		cp src/libhighlight.lib "${BLD_CONFIG_INSTALL_FOLDER}/lib/"
	fi

	finalcommon;
}
ourmain;
