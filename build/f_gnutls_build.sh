#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="gnutls"
BLD_CONFIG_GNU_LIBS_ADDL=( "dirent" "getopt-gnu" )
BLD_CONFIG_CONFIG_CMD_ADDL=( "--with-included-unistring" )
BLD_CONFIG_VCPKG_DEPS=( "gmp" "nettle" "brotli" "zstd" )
BLD_CONFIG_PKG_CONFIG_MANUAL_ADD=( "gmp" )
BLD_CONFIG_BUILD_ADDL_CFLAGS=( "-I../gl/" )

# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;
	BLD_CONFIG_GNU_LIBS_EXCLUDE=("${BLD_CONFIG_GNU_LIBS_DEFAULT[@]}")

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://github.com/gnutls/gnutls.git .
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		apply_our_repo_patch; # Applies from patches folder repo_BUILD_NAME.patch to the sources
	fi

	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq "1" ]]; then
		if [[ -z $SKIP_STEP || $SKIP_STEP == "gnulib" ]]; then
			gnulib_switch_to_master_and_patch;
			if [[ $BLD_CONFIG_CONFIG_NO_TESTS -eq 1 ]]; then
				sed -i -E '/SUBDIRS \+= tests/d' Makefile.am
				sed -i -E '/tests\//d;/fuzz\//d;' configure.ac
			fi
			if [[ $BLD_CONFIG_CONFIG_NO_DOCS -eq 1 ]]; then
				sed -i -E '/enable-doc/d;/enable-gtk-doc/d;/SUBDIRS \+= doc/d;' Makefile.am
				sed -i -E '/doc\//d;/GTK_DOC_CHECK/d' configure.ac
			fi
			if [[ $BLD_CONFIG_CONFIG_NO_PO -eq 1 ]]; then
			sed -i -E '/SUBDIRS \+= po/d' Makefile.am
				sed -i -E '/po\//d;' configure.ac
			fi
			if [[ -f "gl/override/doc/gendocs_template.diff" && $BLD_CONFIG_CONFIG_NO_DOCS -eq "1" ]]; then
				git rm "gl/override/doc/gendocs_template.diff"
			fi
		fi
		cd $BLD_CONFIG_SRC_FOLDER
		if [[ -z $SKIP_STEP || $SKIP_STEP == "bootstrap" ]]; then
			gnulib_add_addl_modules_and_bootstrap;
		fi
	fi

	if [[ $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		autoreconf --symlink --verbose --install
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "vcpkg" ]]; then
		vcpkg_install_package
	fi

	cd $BLD_CONFIG_SRC_FOLDER
	ensure_perl_installed_set_exports "AS"
	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		configure_apply_fixes_and_run;
	else
		setup_build_env;
	fi

	run_make
	make_install

	finalcommon;
}
ourmain;
