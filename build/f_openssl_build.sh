#!/bin/bash
set -e
. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="openssl"
BLD_CONFIG_GNU_LIBS_USED=0
BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=0
BLD_CONFIG_BUILD_MAKE_JOBS=1
BLD_CONFIG_BUILD_WINDOWS_COMPILE_WRAPPERS=1
BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1
BLD_CONFIG_VCPKG_DEPS=( "brotli" "zstd" )
BLD_CONFIG_BUILD_MAKE_CMD_DEFAULT="nmake"
BLD_CONFIG_BUILD_MAKE_CMD_ADDL=( "/S" )
BLD_CONFIG_BUILD_MAKE_INSTALL_CMD_ADDL=( "DESTDIR=[INSTALL_FOLDER]" )
#will look for certs etc in /basedir/ssl/X
SSL_BASE_DIR="/ProgramData/ssl"
export CommonProgramW6432="$SSL_BASE_DIR" CommonProgramFiles="$SSL_BASE_DIR" #shoudn't need these due to config line but cant hurt
# BLD_CONFIG_BUILD_FOLDER_NAME="myapp2"; #if you want it compiling in a diff folder
# BLD_CONFIG_BUILD_DEBUG=1

function ourmain() {
	startcommon;

if test 5 -gt 100; then
		echo "Just move the fi down as you want to skip steps, or pass the step to skip to (per below) as the first arg"
fi
	if [[ -z $SKIP_STEP || $SKIP_STEP == "checkout" ]]; then
		git_clone_and_add_ignore https://github.com/openssl/openssl .
	fi

	if [[ -z $SKIP_STEP || $SKIP_STEP == "vcpkg" ]]; then
		vcpkg_install_package
	fi

	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -z $SKIP_STEP || $SKIP_STEP == "deps" ]]; then
		SKIP_STEP=""
		mkdir -p nasm && pushd nasm
		#curl https://www.nasm.us/pub/nasm/releasebuilds/2.16/win64/nasm-2.16-win64.zip -o nasm.zip
		#nasm.us down
		curl -L https://github.com/microsoft/vcpkg/files/12073957/nasm-2.16.01-win64.zip -o nasm.zip
		unzip -j nasm.zip
		popd
		# this probably isn't strictly necessary but makes the paths more universal as they do end up in the build a few spots
		# sed -i -E 's#return (\$path ne [^;]+;)#my $ret = \1\n\t$ret =~ s/\\/\//g;\n\treturn $ret;#' perl/lib/File/Spec/Win32.pm
	fi
	NASM_PATH=$(convert_to_msys_path "${BLD_CONFIG_SRC_FOLDER}/nasm")
	export PATH="${NASM_PATH}:$PATH"	
	ensure_perl_installed_set_exports
	setup_build_env;

	if [[ -z $SKIP_STEP || $SKIP_STEP == "configure" ]]; then
		CUR_STEP="configure"
		CONFIG_ADD=""
		BRO_BASE=$(get_install_prefix_for_vcpkg_pkg "brotli")
		ZST_BASE=$(get_install_prefix_for_vcpkg_pkg "zstd")

		if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
			CONFIG_ADD+=" -static no-shared"
		fi
		if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
			CONFIG_ADD+=" --debug"
		else
			CONFIG_ADD+=" --release"
		fi
		
		#even with these things we cant quite get MT and such set right but at least ours will override
		
		$PERL Configure no-dynamic-engine enable-trace no-dso no-fips $CONFIG_ADD enable-quic no-pic enable-weak-ssl-ciphers no-threads no-makedepend enable-comp enable-zstd enable-brotli no-docs no-acvp-tests no-buildtest-c++ no-external-tests no-tests no-unit-test -DOPENSSL_SMALL_FOOTPRINT "--with-brotli-include=${BRO_BASE}/include" HASHBANGPERL="$PERL" "--with-brotli-lib=${BRO_BASE}/lib" "--with-zstd-include=${ZST_BASE}/include" "LD=${LD}"  "--with-zstd-lib=${ZST_BASE}/lib/zstd.lib"  VC-WIN64A "--openssldir=$SSL_BASE_DIR" "--prefix=$BLD_CONFIG_INSTALL_FOLDER" bin_cflags="" dso_cflags="" lib_cflags="" bin_cflags=""
		$PERL configdata.pm --dump
		sed -i -z -E "s#[^\n]+INSTALL_PROGRAMS[^\n]+[\n][^\n]+INSTALL_PROGRAMPDBS[^\n]+[\n][^\n]+##" makefile
		sed -i -E 's#=\$\(DESTDIR\)#=#g;s#OPENSSLDIR=\$#OPENSSLDIR=\$(DESTDIR)\$#g' makefile  #this might be needed after make
		SKIP_STEP="";
	fi

	run_make
	make_install
	PKGCFG_DIR="${BLD_CONFIG_INSTALL_FOLDER}/lib/pkgconfig"
	mkdir -p "${PKGCFG_DIR}"
	for filename in exporters/*.pc; do
		sed -i -E "s#\\\#/#g;s#/Program Files/OpenSSL##g" "${filename}"
	done
	cp exporters/*.pc "${PKGCFG_DIR}"

	finalcommon;
}
ourmain;
