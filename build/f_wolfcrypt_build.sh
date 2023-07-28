#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="wolfcrypt";

#BLD_CONFIG_BUILD_DEBUG=1
BLD_CONFIG_CONFIG_CMD_ADDL=(--disable-makeclean --enable-sessionexport --enable-opensslextra --enable-curl --enable-webclient --enable-curve25519 --enable-ed25519 --enable-dtls --enable-dtls13 --enable-pkcs7 --disable-crypttests --enable-alpn --enable-sni --enable-cryptocb --enable-64bit --enable-ocsp --enable-certgen --enable-keygen --enable-sessioncerts)
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1

function ourmain() {
	startcommon;
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq "1" ]]; then
		BLD_CONFIG_CONFIG_CMD_ADDL+=("--enable-static" "--disable-shared")
	else
		BLD_CONFIG_CONFIG_CMD_ADDL+=("--disable-static" "--enable-shared")
	fi;
	export CFLAGS="-DWOLFSSL_CRYPT_TESTS=no -DSESSION_CERTS -DKEEP_OUR_CERT -DOPENSSL_EXTRA -DSESSION_CERTS -DWOLFSSL_OPENSSLEXTRA -DWOLFSSL_ALT_CERT_CHAINS -DWOLFSSL_DES_ECB -DWOLFSSL_CUSTOM_OID -DHAVE_OID_ENCODING -DWOLFSSL_CERT_GEN -DWOLFSSL_ASN_TEMPLATE -DWOLFSSL_KEY_GEN -DHAVE_PKCS7 -DHAVE_AES_KEYWRAP -DWOLFSSL_AES_DIRECT -DHAVE_X963_KDF $CFLAGS"
	if [[ $BLD_CONFIG_BUILD_DEBUG -eq "1" ]]; then
		BLD_CONFIG_CONFIG_CMD_ADDL+=" --enable-debug"
		CFLAGS="-DWOLFSSL_DEBUG=yes $CFLAGS"
	fi
if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://github.com/wolfSSL/wolfssl.git .
		add_items_to_gitignore;
		SKIP_STEP=""
	fi


	if [[ -z $SKIP_STEP ||  $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		sed -i -E 's#(ESTS\],\[test .x)#\1ZZZ#g' configure.ac #disable unit tests that will fail
		sed -i -E 's#autoreconf --install --force#autoreconf --install#g' autogen.sh
		gnulib_ensure_buildaux_scripts_copied;
		./autogen.sh
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
