#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="openssl";

#BLD_CONFIG_BUILD_DEBUG=1
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_BUILD_WINDOWS_COMPILE_WRAPPERS=1
#will look for certs etc in /basedir/ssl/X
SSL_BASE_DIR="/ProgramData/ssl"
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
function ourmain() {
	startcommon;
	add_vcpkg_pkg_config  "brotli" "zstd"
	#shoudn't need these due to confi line but cant hurt
	export CommonProgramW6432="$SSL_BASE_DIR" CommonProgramFiles="$SSL_BASE_DIR"

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
		# this probably isn't strictly necessary but makes the paths more universal as they do end up in the build a few spots
		# sed -i -E 's#return (\$path ne [^;]+;)#my $ret = \1\n\t$ret =~ s/\\/\//g;\n\treturn $ret;#' perl/lib/File/Spec/Win32.pm
	fi
	ensure_perl_installed_set_exports
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
#		echo "HI THERE RUNNING: " Configure no-dynamic-engine enable-trace no-dso no-fips $CONFIG_ADD enable-quic no-pic no-docs enable-weak-ssl-ciphers no-threads no-makedepend enable-comp enable-zstd enable-brotli no-acvp-tests no-buildtest-c++ no-external-tests no-tests no-unit-test -DOPENSSL_SMALL_FOOTPRINT "--with-brotli-include=${BRO_BASE}/include" HASHBANGPERL="$PERL" "--with-brotli-lib=${BRO_BASE}/lib" "--with-zstd-include=${ZST_BASE}/include" "LD=${LD}" "AR=${AR}" "CC=${CC}" "CXX=${CXX}" "--with-zstd-lib=${ZST_BASE}/lib/zstd.lib"  VC-WIN64A
		env > c:/temp/env.log
		echo "LD IS: $LD"
# 
# "AR=${AR}" "CC=${CC}" "CXX=${CXX}"
		$PERL Configure no-dynamic-engine enable-trace no-dso no-fips $CONFIG_ADD enable-quic no-pic enable-weak-ssl-ciphers no-threads no-makedepend enable-comp enable-zstd enable-brotli no-docs no-acvp-tests no-buildtest-c++ no-external-tests no-tests no-unit-test -DOPENSSL_SMALL_FOOTPRINT "--with-brotli-include=${BRO_BASE}/include" HASHBANGPERL="$PERL" "--with-brotli-lib=${BRO_BASE}/lib" "--with-zstd-include=${ZST_BASE}/include" "LD=${LD}"  "--with-zstd-lib=${ZST_BASE}/lib/zstd.lib"  VC-WIN64A "--openssldir=$SSL_BASE_DIR" "--prefix=$BLD_CONFIG_INSTALL_FOLDER"
		$PERL configdata.pm --dump
		#sed -i -E "s#lib.(brotli[^ ]+).lib#lib/\1-static.lib#g" makefile #hack no longer needed they properly renamed the lib now
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
	sed -i -E 's#=\$\(DESTDIR\)#=#g;s#OPENSSLDIR=\$#OPENSSLDIR=\$(DESTDIR)\$#g' makefile
	nmake install "DESTDIR=${BLD_CONFIG_INSTALL_FOLDER}"
	PKGCFG_DIR="${BLD_CONFIG_INSTALL_FOLDER}/lib/pkgconfig"
	mkdir -p "${PKGCFG_DIR}"
	for filename in exporters/*.pc; do
		sed -i -E "s#\\\#/#g;s#/Program Files/OpenSSL##g" "${filename}"
	done
	cp exporters/*.pc "${PKGCFG_DIR}"

	finalcommon;
}
ourmain;
