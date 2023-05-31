#!/bin/bash

OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"

PreInitialize;


BLD_CONFIG_BUILD_NAME="openssl";
#BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
BLD_CONFIG_CONFIG_CMD_ADDL="" #--disable-nls --enable-static
BLD_CONFIG_ADD_WIN_ARGV_LIB=0
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=0
BLD_CONFIG_BUILD_DEBUG=0

function ourmain() {
	startcommon;
	add_vcpkg_pkg_config  "brotli" "zstd"
if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps"
fi

	git clone --recurse-submodules https://github.com/openssl/openssl .

	mkdir -p nasm && cd nasm
	curl https://www.nasm.us/pub/nasm/releasebuilds/2.16/win64/nasm-2.16-win64.zip -o nasm.zip
	unzip -j nasm.zip
	cd $BLD_CONFIG_SRC_FOLDER
	mkdir -p perl && cd perl #it wants windows native perl with 'proper' path support
	curl https://strawberryperl.com/download/5.32.1.1/strawberry-perl-5.32.1.1-64bit-portable.zip -o perl.zip
	unzip -q perl.zip

	#apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and if found applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch
	add_items_to_gitignore;

	cd $BLD_CONFIG_SRC_FOLDER
	vcpkg_install_package "brotli" "zstd"
#fi
	NASM_PATH=$(convert_to_msys_path "${BLD_CONFIG_SRC_FOLDER}/nasm")
	export PATH="${NASM_PATH}:$PATH"
	BRO_BASE=$(get_install_prefix_for_vcpkg_pkg "brotli")
	ZST_BASE=$(get_install_prefix_for_vcpkg_pkg "zstd")

	ADL_C_FLAGS=""
	ADL_LIB_FLAGS=""
	MSVC_RUNTIME="MD"
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		MSVC_RUNTIME="MT"
	fi
	if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
		sed -i -E "s#NDEBUG#DEBUG#g" src/Makefile extras/tcl/makefile
		ADL_C_FLAGS+=" /DEBUG"
		ADL_LIB_FLAGS+=" /DEBUG" #-ldebug  for the debug lib
		MSVC_RUNTIME+="d"
	fi
	export CFLAGS=" ${ADL_C_FLAGS} /${MSVC_RUNTIME} /Os"
	export LDFLAGS=" ${ADL_LIB_FLAGS}"
	PERL="./perl/perl/bin/perl.exe"
	#-static will break when going to link
	setup_build_env;
	#it wont take most env vars on purpose so need to respec them here per https://github.com/openssl/openssl/blob/4a3b6266604ca447e0b3a14f1dbc8052e1498819/INSTALL.md
	# LDFLAGS=${LDFLAGS}"
	export PERL="$PERL"
	export CPPFLAGS="$CFLAGS"
	cd $BLD_CONFIG_SRC_FOLDER
	$PERL Configure no-dynamic-engine enable-trace no-dso no-fips enable-quic no-pic no-shared enable-weak-ssl-ciphers no-threads no-makedepend enable-comp enable-zstd enable-brotli no-acvp-tests no-buildtest-c++ no-external-tests no-tests no-unit-test -DOPENSSL_SMALL_FOOTPRINT "--with-brotli-include=${BRO_BASE}/include" HASHBANGPERL="$PERL" "--with-brotli-lib=${BRO_BASE}/lib" "--with-zstd-include=${ZST_BASE}/include" "LD=${LD}" "--with-zstd-lib=${ZST_BASE}/lib/zstd.lib"  VC-WIN64A
	$PERL configdata.pm --dump
	sed -i -E "s#lib.(brotli[^ ]+).lib#lib/\1-static.lib#g" makefile
	sed -i -z -E "s#[^\n]+INSTALL_PROGRAMS[^\n]+[\n][^\n]+INSTALL_PROGRAMPDBS[^\n]+[\n][^\n]+##" makefile
	nmake /S
	nmake install "DESTDIR=${BLD_CONFIG_INSTALL_FOLDER}"

	PROGFL_DIR="${BLD_CONFIG_INSTALL_FOLDER}/Program Files"

	mv "${PROGFL_DIR}"/* "${BLD_CONFIG_INSTALL_FOLDER}"
	rmdir "${PROGFL_DIR}"

	BLD_CONFIG_INSTALL_FOLDER="$BLD_CONFIG_INSTALL_FOLDER/openssl" #so the final message is correct
	finalcommon;
}
ourmain;

