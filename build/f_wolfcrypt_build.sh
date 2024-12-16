#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="wolfcrypt"
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_CONFIG_CMD_ADDL=( "--disable-makeclean" "--enable-sessionexport" "--enable-opensslextra" "--enable-curl" "--enable-webclient" "--enable-curve25519" "--enable-ed25519" "--enable-dtls" "--enable-dtls13" "--enable-pkcs7" "--disable-crypttests" "--enable-alpn" "--enable-sni" "--enable-cryptocb" "--enable-64bit" "--enable-ocsp" "--enable-certgen" "--enable-keygen" "--enable-sessioncerts" )
BLD_CONFIG_BUILD_ADDL_CFLAGS=("-DWOLFSSL_CRYPT_TESTS=no -DKEEP_OUR_CERT")
BLD_CONFIG_CONFIG_CMD_ADDL_DEBUG=( "--enable-debug" )
BLD_CONFIG_BUILD_ADDL_CFLAGS_DEBUG=( "-DWOLFSSL_DEBUG=yes" )

# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://github.com/wolfSSL/wolfssl.git .
	fi

	if [[ -z $SKIP_STEP ||  $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		sed -i -E 's#(ESTS\],\[test .x)#\1ZZZ#g' configure.ac #disable unit tests that will fail
		sed -i -E 's#autoreconf --install --force#autoreconf --install#g' autogen.sh
		gnulib_ensure_buildaux_scripts_copied;
		./autogen.sh
		libtool_fixes "build-aux/ltmain.sh" "m4/libtool.m4"
		autoreconf
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
