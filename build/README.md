# Summary
This directory contains the build scripts for all the libraries/apps we currently support. See the main README for how to use them.  The rest of this doc covers how they are generated.

While we have extracted as much common code out to the helper scripts there is still a similar pattern for the build script for each specific app/library.  We now use a template generator [BuildScriptGenerator.csx](BuildScriptGenerator.csx) to generate the initial build script from our template [f_TEMPLATE_build.sbn-sh](f_TEMPLATE_build.sbn-sh).  As there may be times we want to re-run the script (say to bulk update the build scripts) below are the commands used to generate the initial template and any custom modifications required.  This also makes it very concise what items we change from the defaults.  Between this and the patch we have for that repo it should be easy to see what if any modifications were made. Note: if defaults are changed in default_config.ini then things make break / additional options passed for some builds.

<!-- MarkdownTOC -->

- [Calling BuildScriptGenerator.csx](#calling-buildscriptgeneratorcsx)
- [Template System](#template-system)
	- [What We Template](#what-we-template)
- [Template Calls for Each Lib/App](#template-calls-for-each-libapp)
	- [grep](#grep)
		- [Template Script Args](#template-script-args)
	- [pcre2](#pcre2)
		- [Template Script Args](#template-script-args-1)
	- [automake](#automake)
		- [Template Script Args](#template-script-args-2)
		- [Modifications](#modifications)
	- [libpsl](#libpsl)
		- [Template Script Args](#template-script-args-3)
		- [Modifications](#modifications-1)
	- [zlib](#zlib)
		- [Template Script Args](#template-script-args-4)
		- [Modifications](#modifications-2)
	- [libhsts](#libhsts)
		- [Template Script Args](#template-script-args-5)
		- [Modifications](#modifications-3)
	- [wolfcrypt](#wolfcrypt)
		- [Template Script Args](#template-script-args-6)
		- [Modifications](#modifications-4)
	- [wget2](#wget2)
		- [Template Script Args](#template-script-args-7)
		- [Modifications](#modifications-5)
	- [Gawk](#gawk)
		- [Template Script Args](#template-script-args-8)
		- [Modifications](#modifications-6)
	- [awk](#awk)
		- [Template Script Args](#template-script-args-9)
		- [Modifications](#modifications-7)
	- [diffutils](#diffutils)
		- [Template Script Args](#template-script-args-10)
	- [which](#which)
		- [Template Script Args](#template-script-args-11)
		- [Modifications](#modifications-8)
	- [sed](#sed)
		- [Template Script Args](#template-script-args-12)
	- [zstd](#zstd)
		- [Template Script Args](#template-script-args-13)
	- [symlinks](#symlinks)
		- [Template Script Args](#template-script-args-14)
	- [tar](#tar)
		- [Template Script Args](#template-script-args-15)
		- [Modifications](#modifications-9)
	- [wget](#wget)
		- [Template Script Args](#template-script-args-16)
	- [openssl](#openssl)
		- [Template Script Args](#template-script-args-17)
		- [Modifications](#modifications-10)
	- [pdcurses](#pdcurses)
		- [Template Script Args](#template-script-args-18)
		- [Modifications](#modifications-11)
	- [highlight](#highlight)
		- [Template Script Args](#template-script-args-19)
		- [Modifications](#modifications-12)
	- [findutils](#findutils)
		- [Template Script Args](#template-script-args-20)
		- [Modifications](#modifications-13)
	- [coreutils](#coreutils)
		- [Template Script Args](#template-script-args-21)
		- [Modifications](#modifications-14)
	- [make](#make)
		- [Template Script Args](#template-script-args-22)
		- [Modifications](#modifications-15)
	- [patch](#patch)
		- [Template Script Args](#template-script-args-23)
	- [gnutls](#gnutls)
		- [Template Script Args](#template-script-args-24)
		- [Modifications](#modifications-16)

<!-- /MarkdownTOC -->


# Calling BuildScriptGenerator.csx
It is meant to be called from powershell.  It is likely most of the calls below would work in a bash shell as well but any powershell escapes (backticks) below would need to be updated.  You can pass `--help` to it to get a brief overview.  It has a few CLI options itself, these are essentially options that don't make sense for us to have in default_config.ini. notably:

- GitRepo - This is the git repo url to clone
- HaveOurPatch - Do we have a patch to apply for the repo

All of the other options it accepts are the variables from default_config.ini.  The ones most commonly used are shown in `--help` but really any option in the ini file can be specified on the CLI.   Not all the common options it shows are used in templating (beyond just setting their values as a convenience).

# Template System
The template system uses [Scriban](https://github.com/scriban/scriban) which uses a similar pattern to [liquid](https://shopify.github.io/liquid/) templates.  We do have a basic templating system in place but it only does simple substitutions and doesn't handle things like conditionals.  The BuildScriptGenerator.csx script specifically doesn't interpret the templates we use in the default_config.ini.  Often we want these substitutions to occur at runtime so want to leave them in place.

## What We Template
While there are many things we could template for the most part we want to only keep it to things a user is unlikely to change while creating the script.  Build scripts often contain custom code so having to regenerate the template is an annoyance to re-add. This means we don't  Things we template include: Does a library use gnulib?, does it use cmake or configure? does it want us to install any vcpkgs for it? We don't template things like what gnulib modules do we need to add, or what vcpkg's to install.  These are items that the developer may need to vary while trying to get the build to work properly. Now we do offer the convenience of specifying the default variables from default_config.ini but the user can always set these themselves in the script easily enough.

# Template Calls for Each Lib/App
Below are the template calls and modifications to the produced build script for each build we offer.  I try to make sure any changes made to the build scripts gets ported back here.

## grep
### Template Script Args
`--BUILD_NAME grep --HaveOurPatch=0 --GitRepo https://git.savannah.gnu.org/git/grep.git --CONFIG_CMD_ADDL "ac_cv_prog_cc_g=no" "--enable-perl-regexp" --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS 1 --ADD_WIN_ARGV_LIB 1 --GNU_LIBS_ADDL "alloca" "alloca-opt" --OUR_LIB_DEPS pcre2`

## pcre2
### Template Script Args
 `--BUILD_NAME pcre2 --HaveOurPatch=0 --GitRepo https://github.com/PCRE2Project/pcre2 --CMAKE_STYLE="best" --GNU_LIBS_USED=0 --CMAKE_CONFIG_CMD_ADDL "-DZLIB_INCLUDE_DIR=/tmp" "-DZLIB_LIBRARY_DEBUG=" "-DZLIB_LIBRARY_RELEASE=" --CMAKE_CONFIG_CMD_ADDL_STATIC "-DPCRE2_STATIC_CFLAG:STRING=-DPCRE2_STATIC" --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS 1`

## automake
### Template Script Args
We force no debug build as it has no advantage and causes build failures as there are files left after clean
`--GitRepo https://github.com/autotools-mirror/automake  --HaveOurPatch=0 --BUILD_NAME automake --GNU_LIBS_USED=0 --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS 1 --BLD_CONFIG_BUILD_DEBUG=0`

### Modifications
After clone step add:
```bash
	PERL_P=$(convert_to_msys_path "${BLD_CONFIG_SRC_FOLDER}/automake-1.16")
	export PERL5LIB="${PERL_P}"
	if [[ -z $SKIP_STEP || $SKIP_STEP == "bootstrap_fix" ]]; then
		attrib -r /s "bin/*"
		attrib -r /s "t/*"
		mv bootstrap bootstrap.in
		head bootstrap.in -n -3 > bootstrap #remove lines that remove the temp dir we need for the perl module
		./bootstrap
		SKIP_STEP=""
	fi
```

## libpsl
### Template Script Args
`--BUILD_NAME libpsl --GitRepo https://github.com/rockdaboot/libpsl --GNU_LIBS_USED=0 --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --BUILD_ADDL_CFLAGS_STATIC -DPSL_STATIC -DU_STATIC_IMPLEMENTATION -DU_IMPORT`

### Modifications	
just doing --enable-static is not enough and -D U_IMPORT is required to override the default dll import as it doesn't check static

## zlib
### Template Script Args
`--BUILD_NAME zlib --GitRepo https://github.com/madler/zlib.git --CMAKE_STYLE="best" --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --GNU_LIBS_USED=0 --GIT_CLONE_BRANCH develop --CMAKE_CONFIG_CMD_ADDL "-DINSTALL_PKGCONFIG_DIR:PATH=[INSTALL_FOLDER]/lib/pkgconfig" "-DENABLE_BINARY_COMPATIBLE_POSIX_API:BOOL=1"`

### Modifications
After apply_our_repo_patch add:
```bash
		if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
			sed -i -E 's/-lz/-lzd/' zlib.pc.cmakein
		fi
		if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
			sed -i -E 's/^sharedlibdir.+//;s/-L\$\{sharedlibdir\}//;s/-lz/-lzlibstatic/' zlib.pc.cmakein
		fi
		sed -i -E 's/if\(MSVC\)/if(MSVC OR NOT MSVC)/' CMakeLists.txt
		git_staging_add zlib.pc.cmakein .gitignore CMakeLists.txt #staging them means if we re-apply our patch they are discarded
```

before cmake make add:
`find -name "flags.make" | xargs sed -i -E 's#(/M[TtDd]{1,2})\s+/M[TtDd]{1,2}\b#\1#g' #not sure where the \MT icomes from but we gotta remove`

## libhsts
### Template Script Args
`--BUILD_NAME libhsts --GitRepo https://gitlab.com/rockdaboot/libhsts --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --GNU_LIBS_USED=0 --BUILD_ADDL_CFLAGS_STATIC -DHSTS_STATIC`

### Modifications
Add autoconf section before configure:
```bash
	if [[ -z $SKIP_STEP || $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		gnulib_ensure_buildaux_scripts_copied
		autoreconf --symlink --verbose --install
		libtool_fixes
		autoreconf --verbose #update for libtool fixes
		SKIP_STEP=""
	fi
```

## wolfcrypt
### Template Script Args
`--BUILD_NAME wolfcrypt --HaveOurPatch=0 --GitRepo https://github.com/wolfSSL/wolfssl.git --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS 1 --GNU_LIBS_USED=0 --CONFIG_CMD_ADDL --disable-makeclean --enable-sessionexport --enable-opensslextra --enable-curl --enable-webclient --enable-curve25519 --enable-ed25519 --enable-dtls --enable-dtls13 --enable-pkcs7 --disable-crypttests --enable-alpn --enable-sni --enable-cryptocb --enable-64bit --enable-ocsp --enable-certgen --enable-keygen --enable-sessioncerts --BUILD_ADDL_CFLAGS -DWOLFSSL_CRYPT_TESTS=no -DSESSION_CERTS -DKEEP_OUR_CERT -DOPENSSL_EXTRA -DSESSION_CERTS -DWOLFSSL_OPENSSLEXTRA -DWOLFSSL_ALT_CERT_CHAINS -DWOLFSSL_DES_ECB -DWOLFSSL_CUSTOM_OID -DHAVE_OID_ENCODING -DWOLFSSL_CERT_GEN -DWOLFSSL_ASN_TEMPLATE -DWOLFSSL_KEY_GEN -DHAVE_PKCS7 -DHAVE_AES_KEYWRAP -DWOLFSSL_AES_DIRECT -DHAVE_X963_KDF --CONFIG_CMD_ADDL_DEBUG --enable-debug --BUILD_ADDL_CFLAGS_DEBUG -DWOLFSSL_DEBUG=yes`

### Modifications
Add autogen/reconf step before configure of:
```bash
if [[ -z $SKIP_STEP ||  $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		sed -i -E 's#(ESTS\],\[test .x)#\1ZZZ#g' configure.ac #disable unit tests that will fail
		sed -i -E 's#autoreconf --install --force#autoreconf --install#g' autogen.sh
		gnulib_ensure_buildaux_scripts_copied;
		./autogen.sh
		libtool_fixes
		autoreconf
		SKIP_STEP=""
	fi
```

## wget2
### Template Script Args
`--BUILD_NAME wget2 --GitRepo https://gitlab.com/gnuwget/wget2.git --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --BUILD_ADDL_CFLAGS -DMSVC_INVALID_PARAMETER_HANDLING=1 -DKEEP_OUR_CERT -DHAVE_SSIZE_T -D_WIN64  --BUILD_ADDL_CFLAGS_STATIC -DDLZMA_API_STATIC -DHSTS_STATIC --CONFIG_CMD_ADDL --without-libidn2 --with-lzma --with-bzip2 --without-libidn --without-libdane --with-ssl=wolfssl --without-gpgme LEX=/usr/bin/flex ac_cv_prog_cc_c99= --GNU_LIBS_ADDL "atexit" "pathmax" "ftruncate" "malloca" "fnmatch-gnu" "fnmatch-h" "xstrndup" --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --CONFIG_CMD_ADDL_DEBUG --enable-assert --OUR_LIB_DEPS "libpsl" "pcre2" "zlib" "libhsts" "wolfcrypt" --VCPKG_DEPS "nghttp2" "zstd" "liblzma" "brotli" "bzip2" --PKG_CONFIG_MANUAL_ADD bzip2 --GIT_NO_RECURSE=1 --GIT_SUBMODULE_INITS gnulib`

### Modifications
tar was only used part of the time i think  --OUR_LIB_BINS_PATH "tar"

before gnulib block:
```bash
	if [[ ! -f "lzip.exe" ]]; then
		wget https://download.savannah.gnu.org/releases/lzip/lzip-1.22-w64.zip -O lzip.zip
		unzip -j lzip.zip
	fi
	export PATH="$PATH:./"
```
	
Right before configure:
	`touch ABOUT-NLS`

## Gawk
### Template Script Args
`--BUILD_NAME gawk --GitRepo https://git.savannah.gnu.org/git/gawk.git --GNU_LIBS_ADD_TO_REPO 1 --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --PREFER_STATIC_LINKING=0 --GNU_LIBS_ADDL "mkstemp" "fts" "sys_socket" "strcasestr" "regex" "random" "flexmember" "setlocale" "locale" "dfa" "sleep" "strsignal" "sys_ioctl" "connect" "listen" "accept" "fnmatch-h" "fnmatch-gnu" "recvfrom" "bind" "setsockopt" "getsockopt" "getopt-gnu" "shutdown" "sys_random" "popen" "pclose" "socket" "strcase" "timegm" "setenv" "unsetenv" "usleep" "fprintf-gnu" --BUILD_MSVC_IGNORE_WARNINGS 4068 --CONFIG_CMD_ADDL "ac_cv_search_dlopen=-luser32" "--enable-extensions" "--enable-threads=windows" "acl_shlibext=dll" "ac_cv_header_dlfcn_h=yes"  --BUILD_MAKE_CMD_ADDL 'DEFPATH="\"./;%%PROGRAMDATA%%/gawk/share\""' 'DEFLIBPATH="\"./;%%PROGRAMDATA%%/gawk/lib\""'`

### Modifications
We specifically set it to not statically link.  It will compile with static linking fine, but extensions are also compiled statically into libs which obviously gawk can't use at runtime then.  The only dependency gawk has when dynamically compiled is the vc runtime.  As for the ac_cv_search_dlopen setting it to something will bypass the check we would fail, but the none-required value no longer works so we just set it to a lib we will include anyway.

In the clone step add
```bash
		cp gnulib/build-aux/bootstrap .
		cp gnulib/build-aux/bootstrap.conf .
		echo "gnulib_tool_option_extras=\" --without-tests --symlink --m4-base=m4 --lib=libgawk --source-base=lib --cache-modules\"" >> bootstrap.conf
		git mv m4 m4_orig
		git rm build-aux/*
		mkdir -p m4
		mkdir -p pc/old
		mv pc/* pc/old/ || true
		pushd m4
		cp -s -t . ../m4_orig/socket.m4 ../m4_orig/arch.m4 ../m4_orig/noreturn.m4 ../m4_orig/pma.m4 ../m4_orig/triplet-transformation.m4
		popd
		echo "EXTRA_DIST = " > m4/Makefile.am
		add_items_to_gitignore;
		git_staging_add bootstrap bootstrap.conf
		git_staging_commit #need to commit it up so that the bootstrap files are avail for our gnulib patching by default all local changes are stashed		
```

Before our patch block add
```bash
if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
		touch .developing
	else
		rm .developing &>/dev/null || true
	fi
```
After configure add:
`echo "#include <osfixes.h>" > "lib/dlfcn.h"`
After install add:
```bash
mkdir -p $BLD_CONFIG_INSTALL_FOLDER/ProgramData/lib $BLD_CONFIG_INSTALL_FOLDER/ProgramData/share $BLD_CONFIG_INSTALL_FOLDER/ProgramData/libexec
	mv $BLD_CONFIG_INSTALL_FOLDER/lib/gawk/* $BLD_CONFIG_INSTALL_FOLDER/ProgramData/lib/
	mv $BLD_CONFIG_INSTALL_FOLDER/libexec/awk/* $BLD_CONFIG_INSTALL_FOLDER/ProgramData/libexec/
	mv $BLD_CONFIG_INSTALL_FOLDER/share/awk/* $BLD_CONFIG_INSTALL_FOLDER/ProgramData/share/
	rmdir $BLD_CONFIG_INSTALL_FOLDER/lib/gawk/ $BLD_CONFIG_INSTALL_FOLDER/libexec/awk/ $BLD_CONFIG_INSTALL_FOLDER/share/awk/ $BLD_CONFIG_INSTALL_FOLDER/lib/ $BLD_CONFIG_INSTALL_FOLDER/libexec/
```
## awk
### Template Script Args
`--BUILD_NAME awk --GitRepo https://github.com/onetrueawk/awk --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --GNU_LIBS_USED=0`

### Modifications
after the clone add:
```bash
		git checkout makefile
		sed -i -E 's#^(CC|HOSTCC|CFLAGS) =#\1 :=#g' makefile
```

before make add: #it has no configure script so we need to manually specify these things
`export HOSTCC="$CC"`

for make add (no normal make):
`make_install awk HOSTCC="$HOSTCC" CFLAGS="$CFLAGS" CC="$CC" PREFIX="${BLD_CONFIG_INSTALL_FOLDER}"`

## diffutils
### Template Script Args
`--BUILD_NAME diffutils --GitRepo https://git.savannah.gnu.org/git/diffutils.git --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --GNU_LIBS_ADDL "signal-h" "getopt-gnu" "sigprocmask" "sigpipe" "stdio" "write" "popen" "pclose"`

## which
### Template Script Args
`--BUILD_NAME which --HaveOurPatch=0 --GitRepo https://github.com/mitchcapper/which.git --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --GNU_LIBS_USED=0 --CONFIG_CMD_ADDL="--enable-maintainer-mode"`

### Modifications
add an autoconf step of:
```bash
	if [[ -z $SKIP_STEP ||  $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		gnulib_ensure_buildaux_scripts_copied;
		echo "" > ChangeLog
		autoreconf --symlink --verbose --install
		SKIP_STEP=""
	fi
```	

## sed
### Template Script Args
`--BUILD_NAME sed --HaveOurPatch=0 --GitRepo https://github.com/mirror/sed --GNU_LIBS_ADDL "getopt-gnu" "alloca" "alloca-opt" --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1`

## zstd
### Template Script Args
`--BUILD_NAME zstd --HaveOurPatch=0 --GitRepo https://github.com/facebook/zstd --CMAKE_STYLE="best" --CMAKE_SRC_DIR="build/cmake" --GNU_LIBS_USED=0 --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --CMAKE_CONFIG_CMD_ADDL_STATIC "-DZSTD_BUILD_SHARED:BOOL=OFF" "-DZSTD_BUILD_STATIC:BOOL=ON" "-DZSTD_USE_STATIC_RUNTIME:BOOL=ON"`

## symlinks
### Template Script Args
`--BUILD_NAME symlinks --HaveOurPatch=0 --GitRepo https://github.com/mitchcapper/symlinks.git --GIT_CLONE_BRANCH=win32_enhancements --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1`


## tar
### Template Script Args
`--BUILD_NAME tar --GitRepo https://git.savannah.gnu.org/git/tar.git --GNU_LIBS_ADDL "lock" "thread" "sigpipe" "glob" "ioctl" "sys_time" "sys_wait" "ftello" "ftruncate" "system-posix" "posix_spawn" "pipe-posix" "close" "fclose" "fopen-gnu" "open" "posix_spawnattr_setsigdefault" "posix_spawnattr_getsigmask" "posix_spawnattr_getflags" "posix_spawnattr_setflags" "posix_spawnattr_setsigmask" "posix_spawnp" "stdio" "nonblocking" "poll" "pipe2" "signal-h" "sys_types" "sys_stat" "fcntl-h" "fcntl" "stdbool-c99" "waitpid" "sys_file" "netdb" "mkdir" "wait-process" "getaddrinfo" --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1`

### Modifications
before bootstrapping add:
```bash
	if [[ -z $SKIP_STEP || $SKIP_STEP == "paxutils" ]]; then
			pushd $BLD_CONFIG_SRC_FOLDER/paxutils
			apply_our_repo_patch "paxutils"

			git checkout bootstrap.conf
			#it doesn't use extras so we can just add ours, they use paxutils to gnulib everyhting
			echo "gnulib_tool_option_extras=\" --without-tests --symlink\"" >> bootstrap.conf
			popd
		fi
	sed -E -i 's/\-\-avoid=lock//;s#m4/lock.m4##' bootstrap.conf; #it has lock in avoid but we actually do need it for
```

## wget
### Template Script Args
`--BUILD_NAME wget --GitRepo https://git.savannah.gnu.org/git/wget.git --OUR_LIB_DEPS "libpsl" "pcre2" "zlib" "openssl" --CONFIG_CMD_ADDL_DEBUG --enable-assert --GNU_LIBS_ADDL "pathmax" "ftruncate" "fnmatch-gnu" "fnmatch-h" "xstrndup" --ADD_WIN_ARGV_LIB=1 --CONFIG_CMD_ADDL "--with-ssl=openssl" --CONFIG_ADDL_LIBS="-lcrypt32" --BUILD_ADDL_CFLAGS_DEBUG "-DDEBUG"  -DENABLE_DEBUG --VCPKG_DEPS "brotli" "zstd"`


## openssl
### Template Script Args
`--BUILD_NAME openssl --GitRepo https://github.com/openssl/openssl --HaveOurPatch=0 --GNU_LIBS_USED=0 --BUILD_WINDOWS_COMPILE_WRAPPERS=1 --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --VCPKG_DEPS "brotli" "zstd" --BUILD_MAKE_CMD_DEFAULT nmake --BUILD_MAKE_CMD_ADDL "/S" --BUILD_MAKE_INSTALL_CMD_ADDL "DESTDIR=[INSTALL_FOLDER]" --GNU_LIBS_BUILD_AUX_ONLY_USED 0 -BUILD_MAKE_JOBS 1`
### Modifications
at the top with our other variable defines:
```bash
		#will look for certs etc in /basedir/ssl/X
		SSL_BASE_DIR="/ProgramData/ssl"
		export CommonProgramW6432="$SSL_BASE_DIR" CommonProgramFiles="$SSL_BASE_DIR" #shoudn't need these due to config line but cant hurt
```

replace the configure block with:
```bash
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
			CONFIG_ADD="-static no-shared"
		fi
		$PERL Configure no-dynamic-engine enable-trace no-dso no-fips $CONFIG_ADD enable-quic no-pic enable-weak-ssl-ciphers no-threads no-makedepend enable-comp enable-zstd enable-brotli no-docs no-acvp-tests no-buildtest-c++ no-external-tests no-tests no-unit-test -DOPENSSL_SMALL_FOOTPRINT "--with-brotli-include=${BRO_BASE}/include" HASHBANGPERL="$PERL" "--with-brotli-lib=${BRO_BASE}/lib" "--with-zstd-include=${ZST_BASE}/include" "LD=${LD}"  "--with-zstd-lib=${ZST_BASE}/lib/zstd.lib"  VC-WIN64A "--openssldir=$SSL_BASE_DIR" "--prefix=$BLD_CONFIG_INSTALL_FOLDER"
		$PERL configdata.pm --dump
		sed -i -z -E "s#[^\n]+INSTALL_PROGRAMS[^\n]+[\n][^\n]+INSTALL_PROGRAMPDBS[^\n]+[\n][^\n]+##" makefile
		sed -i -E 's#=\$\(DESTDIR\)#=#g;s#OPENSSLDIR=\$#OPENSSLDIR=\$(DESTDIR)\$#g' makefile  #this might be needed after make
		SKIP_STEP="";
	fi
```

after make install add:
```bash
	PKGCFG_DIR="${BLD_CONFIG_INSTALL_FOLDER}/lib/pkgconfig"
	mkdir -p "${PKGCFG_DIR}"
	for filename in exporters/*.pc; do
		sed -i -E "s#\\\#/#g;s#/Program Files/OpenSSL##g" "${filename}"
	done
	cp exporters/*.pc "${PKGCFG_DIR}"
```

## pdcurses
### Template Script Args
`--BUILD_NAME pdcurses --GitRepo https://github.com/Bill-Gray/PDCursesMod --HaveOurPatch=0 --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --GNU_LIBS_USED=0 --CMAKE_STYLE="best" --CMAKE_CONFIG_CMD_ADDL "-DPDC_SDL2_DEPS_BUILD:BOOL=0" "-DPDC_SDL2_BUILD:BOOL=0" "-DPDC_GL_BUILD:BOOL=0" "-DPDC_UTF8:BOOL=1" "-DPDC_WIDE:BOOL=1" --CMAKE_CONFIG_CMD_ADDL_DEBUG "-DPDCDEBUG:BOOL=1" --CMAKE_CONFIG_CMD_ADDL_STATIC "-DPDC_BUILD_SHARED:BOOL=0"`

### Modifications
After checkout add:
	`sed -i -E 's#winspool.lib#winspool.lib user32.lib#g' cmake/project_common.cmake`

after make install add:
```bash
	ex mv "$BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO/lib" "$BLD_CONFIG_INSTALL_FOLDER/"
	ex mkdir -p "$BLD_CONFIG_INSTALL_FOLDER/bin/"
	ex mv $BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO/bin/* "$BLD_CONFIG_INSTALL_FOLDER/bin/"
	ex rmdir "$BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO/bin/" "$BLD_CONFIG_INSTALL_FOLDER/$BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO"
	INCLUDE_DIR="$BLD_CONFIG_INSTALL_FOLDER/include"
	ex mkdir -p "$INCLUDE_DIR"
	ex cp $BLD_CONFIG_SRC_FOLDER/*.h "$INCLUDE_DIR
```

## highlight
### Template Script Args
`--BUILD_NAME highlight --GitRepo https://gitlab.com/saalen/highlight.git --HaveOurPatch=0 --VCPKG_DEPS "lua" "boost-xpressive" --PKG_CONFIG_MANUAL_ADD "boost-xpressive" "lua" --GNU_LIBS_USED=0 --BUILD_MSVC_IGNORE_WARNINGS 4710 4711 4820 4626 4061 5027 4365 4514 4668 5267 5204 5026 --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1`

### Modifications
At top before main func add:
```bash	
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
```

In vcpkg install block add:
`lua_pkg_config_gen`


Remove configure block and add:
```bash
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
	BOOST_ROOT=$(get_install_prefix_for_vcpkg_pkg "boost-xpressive")
	export CFLAGS="-I${BOOST_ROOT}/include /EHsc -I./ "
	export LDFLAGS="-L${BOOST_ROOT}/lib"
	setup_build_env
```

after make install add:
```bash	
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		mkdir -p "${BLD_CONFIG_INSTALL_FOLDER}/lib/"
		cp src/libhighlight.lib "${BLD_CONFIG_INSTALL_FOLDER}/lib/"
	fi
```

## findutils
### Template Script Args
`--BUILD_NAME findutils --GitRepo https://git.savannah.gnu.org/git/findutils.git --CONFIG_CMD_ADDL="--disable-nls" --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --GNU_LIBS_ADDL "poll-h" --BUILD_ADDL_CFLAGS_DEBUG=""`

### Modifications
fix our vars at the top for changing it to: `BLD_CONFIG_BUILD_ADDL_CFLAGS_DEBUG=(  )`

## coreutils
### Template Script Args
`--BUILD_NAME coreutils --GitRepo https://github.com/coreutils/coreutils --CONFIG_CMD_ADDL fu_cv_sys_mounted_getfsstat=yes fu_cv_sys_stat_statvfs=yes "--enable-no-install-program=chcon,chgrp,chmod,chown,selinux,runcon,mknod,mkfifo,tty,groups,group-list,id,kill,logname,nohup,ptx,split" --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --ADD_WIN_ARGV_LIB=1 --GNU_LIBS_ADDL "ioctl" "symlink" "unistd" "sigpipe" "fprintf-posix" --OUR_OS_FIXES_APPLY_TO_DBG=1 --OUR_OS_FIXES_COMPILE=1`

### Modifications
after switch to master and patch line (but in that block) add:
```bash	
	if [[ -f "gl/modules/rename-tests.diff" ]]; then
					git rm gl/modules/link-tests.diff gl/modules/rename-tests.diff
			fi
			git checkout src/od.c src/fmt.c
			sed -i -E "s/([ \t,:;]|^)(CHAR|INT|LONG|SHORT)([ \t,:;]|\\$)/\1SS\2\3/g" src/od.c
			#MS defines WORD already so lets change it
			sed -i -E "s/WORD/GNUWORD/g" src/fmt.c
```

## make
### Template Script Args
`--BUILD_NAME make --GitRepo https://git.savannah.gnu.org/git/make.git  --GNU_LIBS_BOOTSTRAP_EXTRAS_ADD "--symlink --without-tests" --BUILD_ADDL_CFLAGS -D_WIN32 -D_CRT_SECURE_NO_WARNINGS /wd4668 --GNU_LIBS_ADDL "opendir" "flexmember" "waitpid" "fnmatch-gnu" "glob" "strcasestr" --GNU_LIBS_ADD_TO_REPO=1 --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1 --CONFIG_CMD_ADDL="ac_cv_func_waitpid=yes" "--enable-case-insensitive-file-system"`

### Modifications
make ships with a bunch of gnulib baked in but doesn't use gnulib proper we change that to get our latest benefits and remove their compat items.  After our clone add section:
```bash
	export GNULIB_SRCDIR="$(convert_to_msys_path "${BLD_CONFIG_SRC_FOLDER}")/gnulib"
	export ACLOCAL_FLAGS="-I gl/m4"
	if [[ -z $SKIP_STEP || $SKIP_STEP == "gnulib_strip" ]]; then
		rm src/w32/include/dirent.h src/w32/compat/dirent.c
		rm gl/lib/*
		rm gl/modules/*
		sed -i -E "s#(make-glob|make-macros)##g" bootstrap.conf
		SKIP_STEP=""
	fi
```

## patch
### Template Script Args
`--BUILD_NAME patch --GitRepo https://github.com/mirror/patch --ADD_WIN_ARGV_LIB=1 --GNU_LIBS_ADDL "sys_resource" --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1`

## gnutls
### Template Script Args
`--BUILD_NAME gnutls --GitRepo https://github.com/gnutls/gnutls.git --GNU_LIBS_ADDL "dirent" "getopt-gnu" --CONFIG_CMD_ADDL "--with-included-unistring"  "--without-p11-kit" --VC_PKGDEPS "gmp" "nettle" "brotli" "zstd"  --PKG_CONFIG_MANUAL_ADD "gmp" --BUILD_ADDL_CFLAGS "-I../gl/" --OUR_LIB_DEPS "libtasn1" --OUR_LIB_BINS_PATH "libtasn1"`

### Modifications
At top after startcommon add: `BLD_CONFIG_GNU_LIBS_EXCLUDE=("${BLD_CONFIG_GNU_LIBS_DEFAULT[@]}")` have to wait until then as otherwise full template sub not done
Would prefer if --with-included-libtasn1 would work but for some reason it doesn't seem to still use it so we compile it ourselves instead.

After switch_to_master_and_patch add:
```bash
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
```

Before configure:
`ensure_perl_installed_set_exports "AS"`

## libtasn1
### Template Script Args
`--BUILD_NAME libtasn1 --GitRepo https://gitlab.com/gnutls/libtasn1.git --HaveOurPatch=0 --BUILD_ADDL_CFLAGS_STATIC -DASN1_STATIC`

### modifications
At top after startcommon add: `BLD_CONFIG_GNU_LIBS_EXCLUDE=("${BLD_CONFIG_GNU_LIBS_DEFAULT[@]}")` have to wait until then as otherwise full template sub not done

After switch_to_master_and_patch add:
```bash
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
```

## p11-kit

### Template Script Args
`--BUILD_NAME p11-kit --GitRepo https://github.com/p11-glue/p11-kit --HaveOurPatch=0  --GNU_LIBS_USED=0`

### modifications
Before configure add:
```bash
	if [[ -z $SKIP_STEP || $SKIP_STEP == "autoconf" ]]; then #not empty allowed as if we bootstrapped above we dont need to run nautoconf
		gnulib_ensure_buildaux_scripts_copied
		autoreconf --symlink --verbose --install
		libtool_fixes
		autoreconf --verbose #update for libtool fixes
		SKIP_STEP=""
	fi
```

## gzip
### Template Script Args
`--BUILD_NAME gzip --HaveOurPatch=0 --GitRepo https://git.savannah.gnu.org/git/gzip.git --BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS=1`

## rsync
### Template Script Args
`--BUILD_NAME rsync --HaveOurPatch=0 --GitRepo https://github.com/WayneD/rsync.git  --GNU_LIBS_ADD_TO_REPO 1  --CONFIG_CMD_ADDL --enable-lz4 --disable-md2man --OUR_LIB_DEPS openssl zstd --VCPKG_DEPS "xxhash" "lz4" --GNU_LIBS_ADDL "getsockopt" "strcase" "strerror" "getaddrinfo" "setsockopt" "sleep" "getsockname" "getpeername" "ioctl" "alloca" "alloca-opt" "socket" "bind" "symlink" "unistd" "fsync" "gettimeofday" "sys_socket" "lock" "flock" "signal-h" "sys_ioctl" "symlink" "symlinkat" "unlinkat" "netinet_in" "arpa_inet" "dirent" "sys_stat" "sys_types" "sys_file" "stdbool" "stat-time" "dirname" "attribute" "dirfd" "dup2" "readlink" "stat-macros" "lstat" "stat-size" "stat-time" "open" "openat" "stdopen" "fcntl" "fcntl-h" "errno"`

after clone
```bash
	cp gnulib/build-aux/bootstrap .
	cp gnulib/build-aux/bootstrap.conf .
	#it doesn't use extras so we can just ad ours, they use paxutils to gnulib everyhting
	echo "gnulib_tool_option_extras=\" --without-tests --symlink\"" >> bootstrap.conf
```