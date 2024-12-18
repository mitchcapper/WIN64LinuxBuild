#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="libtasn1"
BLD_CONFIG_BUILD_ADDL_CFLAGS_STATIC=("-DASN1_STATIC")
BLD_CONFIG_CONFIG_CMD_ADDL=("--disable-fuzzing")
BLD_CONFIG_CONFIG_CMD_ADDL_STATIC=("--enable-static") #removing the disable shared
# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;
	BLD_CONFIG_GNU_LIBS_EXCLUDE=("${BLD_CONFIG_GNU_LIBS_DEFAULT[@]}")
if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://github.com/gnutls/libtasn1 .
	fi

	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq "1" ]]; then
		if [[ -z $SKIP_STEP || $SKIP_STEP == "gnulib" ]]; then
			gnulib_switch_to_master_and_patch;
			if [[ $BLD_CONFIG_CONFIG_NO_TESTS -eq 1 ]]; then
				sed -i -E '/SUBDIRS \+= tests/d;s#fuzz tests##' Makefile.am #when fuzz tests dont appear next to each other on the subdirs line we will need ot do something else
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
			if [[ -f "lib/gl/top/README-release.diff" ]]; then
					git rm lib/gl/top/README-release.diff lib/gl/doc/gendocs_template.diff
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

	cd $BLD_CONFIG_SRC_FOLDER
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
