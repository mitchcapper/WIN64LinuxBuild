#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="libpsl";
BLD_CONFIG_CONFIG_CMD_ADDL=("--disable-runtime" "--enable-builtin") #--disable-nls --enable-static
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
#BLD_CONFIG_BUILD_DEBUG=1
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1
BLD_CONFIG_GNU_LIBS_AUTORECONF_WRAPPER=0

function ourmain() {
	startcommon;
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		BLD_CONFIG_CONFIG_CMD_ADDL+=("--enable-static")
	else
		BLD_CONFIG_CONFIG_CMD_ADDL+=("--disable-shared")
	fi

	# ICU_ROOT="${BLD_CONFIG_SRC_FOLDER}/icu"
# wget https://github.com/unicode-org/icu/releases/download/release-72-1/icu4c-72_1-Win64-MSVC2019.zip -O icu.zip
	# unzip -j icu.zip
	# mkdir -p "$ICU_ROOT"
	# cd "$ICU_ROOT"
	# unzip ../icu-windows.zip
	# ICU_PKG_CFG=`cat "${SCRIPT_FOLDER}/patches/libpsl-icu-uc.pc.template"`
	# echo "${ICU_PKG_CFG/ICU_ROOT/"$ICU_ROOT"}" > "${ICU_ROOT}/icu-uc.pc"	
	export CFLAGS="-DPSL_STATIC -DU_STATIC_IMPLEMENTATION -DU_IMPORT" #just doing --enable-static is not enough and -D U_IMPORT is required to override the defualt dll import as it doesnt check static
if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://github.com/rockdaboot/libpsl .
		add_items_to_gitignore;
		SKIP_STEP=""
	fi

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
			libtool_fixes "build-aux/ltmain.sh" "m4/libtool.m4"			
			autoreconf --verbose #update for libtool fixes
			SKIP_STEP=""
		fi
	fi
	if [[ -z $SKIP_STEP ||  $SKIP_STEP == "autoconf" ]]; then
		mkdir -p m4
		gnulib_ensure_buildaux_scripts_copied
		git checkout libpsl.pc.in
		if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
			sed -i -E 's/^(Cflags: )/\1-DPSL_STATIC -DU_STATIC_IMPLEMENTATION -DU_IMPORT /' libpsl.pc.in
		fi
		rm -f gtk-doc.make 2>/dev/null
		echo "EXTRA_DIST =" >gtk-doc.make
		echo "CLEANFILES =" >>gtk-doc.make
		GTKDOCIZE=""
		# BEWARE OF https://ae1020.github.io/undefined-macro-pkg-config/ incase of macro errors
		autoreconf --symlink --verbose --install || autoreconf --symlink --verbose --install #we don't want to use their autogen.sh script it doesnt fail out properly and has no benefits but may needs to pull extra cmds they add to it in future, we do need to run this twice though t oavoid error

		#./autogen.sh
		SKIP_STEP=""
	fi
	
	if [[ -z $SKIP_STEP || $SKIP_STEP == "vcpkg" ]]; then
		
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

