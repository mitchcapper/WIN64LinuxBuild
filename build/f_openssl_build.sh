#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="openssl";

#BLD_CONFIG_BUILD_DEBUG=1
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_BUILD_WINDOWS_COMPILE_WRAPPERS=1

BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
function ourmain() {
	startcommon;
	add_vcpkg_pkg_config  "brotli" "zstd"

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git clone --recurse-submodules https://github.com/openssl/openssl .
		add_items_to_gitignore;
		SKIP_STEP=""
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "deps" ]]; then
		SKIP_STEP=""
		mkdir -p nasm && cd nasm
		#curl https://www.nasm.us/pub/nasm/releasebuilds/2.16/win64/nasm-2.16-win64.zip -o nasm.zip
		#nasm.us down
		curl -L https://github.com/microsoft/vcpkg/files/12073957/nasm-2.16.01-win64.zip -o nasm.zip
		unzip -j nasm.zip
		cd $BLD_CONFIG_SRC_FOLDER
		mkdir -p perl && cd perl #it wants windows native perl with 'proper' path support
		curl https://strawberryperl.com/download/5.32.1.1/strawberry-perl-5.32.1.1-64bit-portable.zip -o perl.zip
		unzip -q perl.zip
	fi
	
	PERL="./perl/perl/bin/perl.exe"
	if [[ -z $SKIP_STEP || $SKIP_STEP == "our_patch" ]]; then
		#apply_our_repo_patch; #looks in the patches folder for  repo_BUILD_NAME.patch and if found applies it.  Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch
		SKIP_STEP=""
	fi
	
	if [[ -z $SKIP_STEP || $SKIP_STEP == "vcpkg" ]]; then
		vcpkg_install_package "brotli" "zstd"
		SKIP_STEP=""
	fi

	cd $BLD_CONFIG_SRC_FOLDER
	NASM_PATH=$(convert_to_msys_path "${BLD_CONFIG_SRC_FOLDER}/nasm")
	export PATH="${NASM_PATH}:$PATH"
	BRO_BASE=$(get_install_prefix_for_vcpkg_pkg "brotli")
	ZST_BASE=$(get_install_prefix_for_vcpkg_pkg "zstd")

	cd $BLD_CONFIG_SRC_FOLDER
	setup_build_env;

	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		CONFIG_ADD=""
		if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
			CONFIG_ADD="-static no-shared"
		fi
		echo "HI THERE RUNNING: " Configure no-dynamic-engine enable-trace no-dso no-fips $CONFIG_ADD enable-quic no-pic enable-weak-ssl-ciphers no-threads no-makedepend enable-comp enable-zstd enable-brotli no-acvp-tests no-buildtest-c++ no-external-tests no-tests no-unit-test -DOPENSSL_SMALL_FOOTPRINT "--with-brotli-include=${BRO_BASE}/include" HASHBANGPERL="$PERL" "--with-brotli-lib=${BRO_BASE}/lib" "--with-zstd-include=${ZST_BASE}/include" "LD=${LD}" "AR=${AR}" "CC=${CC}" "CXX=${CXX}" "--with-zstd-lib=${ZST_BASE}/lib/zstd.lib"  VC-WIN64A
		env > c:/temp/env.log
		echo "LD IS: $LD"
# 
# "AR=${AR}" "CC=${CC}" "CXX=${CXX}"
		$PERL Configure no-dynamic-engine enable-trace no-dso no-fips $CONFIG_ADD enable-quic no-pic enable-weak-ssl-ciphers no-threads no-makedepend enable-comp enable-zstd enable-brotli no-acvp-tests no-buildtest-c++ no-external-tests no-tests no-unit-test -DOPENSSL_SMALL_FOOTPRINT "--with-brotli-include=${BRO_BASE}/include" HASHBANGPERL="$PERL" "--with-brotli-lib=${BRO_BASE}/lib" "--with-zstd-include=${ZST_BASE}/include" "LD=${LD}"  "--with-zstd-lib=${ZST_BASE}/lib/zstd.lib"  VC-WIN64A
		$PERL configdata.pm --dump
		sed -i -E "s#lib.(brotli[^ ]+).lib#lib/\1-static.lib#g" makefile
		sed -i -z -E "s#[^\n]+INSTALL_PROGRAMS[^\n]+[\n][^\n]+INSTALL_PROGRAMPDBS[^\n]+[\n][^\n]+##" makefile

		SKIP_STEP="";
	fi
	#exit 1

	if [[ $SKIP_STEP == "makefiles" ]]; then #not empty and not setting empty as this is only a skip to step
		./config.status
	fi

	if [[ -n "${LOG_MAKE_RUN}" ]]; then
		run_logged_make nmake /S
	fi

	nmake install "DESTDIR=${BLD_CONFIG_INSTALL_FOLDER}"
	PROGFL_DIR="${BLD_CONFIG_INSTALL_FOLDER}/Program Files"

	mv "${PROGFL_DIR}"/* "${BLD_CONFIG_INSTALL_FOLDER}"
	rmdir "${PROGFL_DIR}"

	BLD_CONFIG_INSTALL_FOLDER="$BLD_CONFIG_INSTALL_FOLDER/openssl" #so the final message is correct

	finalcommon;
}
ourmain;
