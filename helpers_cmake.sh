
cmake_ensure_installed(){
	if [[ "$BLD_CONFIG_CMAKE_STYLE" == "unix-msys" ]]; then
		echo CHECKING FOR $BLD_CONFIG_CMAKE_MSYS_BIN
		if [[ -f "${BLD_CONFIG_CMAKE_MSYS_BIN}" ]]; then
			return
		fi
		mkdir -p "${BLD_CONFIG_CMAKE_MSYS_DIR}"
		cd "${BLD_CONFIG_CMAKE_MSYS_DIR}"
		wget "https://mirror.msys2.org/msys/x86_64/${BLD_CONFIG_CMAKE_MSYS_VER}" -O cmake.tar.zst
		tar -axf cmake.tar.zst #  --transform="s,.*/,," cant flatten as it backtracks itself to figure out the path/shared/etc
		cd "$BLD_CONFIG_SRC_FOLDER"
	fi
}

function cmake_init(){
	if [[ "$BLD_CONFIG_CMAKE_STYLE" == "best" ]]; then
		BLD_CONFIG_CMAKE_STYLE="$BLD_CONFIG_CMAKE_BEST_STYLE"
	fi;
	if [[ "$BLD_CONFIG_CMAKE_STYLE" == "nmake" || "$BLD_CONFIG_CMAKE_STYLE" == "cmake" || "$BLD_CONFIG_CMAKE_STYLE" == "unix" || "$BLD_CONFIG_CMAKE_STYLE" == "ninja" || "$BLD_CONFIG_CMAKE_STYLE" == "nmake-launchers" ]]; then
		BLD_CONFIG_BUILD_WINDOWS_COMPILE_WRAPPERS=1
		BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=0
	elif [[ "$BLD_CONFIG_CMAKE_STYLE" == "vs" || "$BLD_CONFIG_CMAKE_STYLE" == "vs" ]]; then
		BLD_CONFIG_BUILD_WINDOWS_COMPILE_WRAPPERS=0
		BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=0
	elif [[ "$BLD_CONFIG_CMAKE_STYLE" == "msys" || "$BLD_CONFIG_CMAKE_STYLE" == "unix-msys" || "$BLD_CONFIG_CMAKE_STYLE" == "ninja-msys" ]]; then
		BLD_CONFIG_BUILD_WINDOWS_COMPILE_WRAPPERS=0
		BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED=1
	fi
	if [[ "$BLD_CONFIG_CMAKE_STYLE" == "unix-msys" || "$BLD_CONFIG_CMAKE_STYLE" == "ninja-msys" ]]; then
		cmake_ensure_installed;
	fi
}
#declare -g SETUP_CMAKE_SETTINGS_RUN=0
function cmake_settings_setup(){
	# ok to actually run multiple times and need it for some of the file fixes we run
#	if [[ $SETUP_CMAKE_SETTINGS_RUN -eq 1 ]]; then
		#return
	#fi
#	SETUP_CMAKE_SETTINGS_RUN=1
	CMAKE_TARGET="${BLD_CONFIG_CMAKE_VS_VERSION}"
	CMAKE_CONFIG_BINARY="cmake"
	CMAKE_MAKE_BINARY="cmake"
	CMAKE_MAKE_ADDL="--build ${BLD_CONFIG_CMAKE_BUILD_DIR} --verbose"
	CMAKE_INSTALL_ADDL=" --install ${BLD_CONFIG_CMAKE_BUILD_DIR}"
	CMAKE_PREFIX_DIR="$BLD_CONFIG_INSTALL_FOLDER"
	CMAKE_ADDL_FLAGS=""
	CMAKE_CONFIG_CLI_CFLAGS="${CFLAGS}"
	

	case "$BLD_CONFIG_CMAKE_STYLE" in
	ninja)
		CMAKE_MAKE_BINARY="ninja"
		CMAKE_TARGET="Ninja"
		;;
	ninja-msys)
		CMAKE_MAKE_BINARY="ninja-msys"
		CMAKE_TARGET="Ninja"
		prefix=`cygpath -u "$prefix"`
		CMAKE_CONFIG_BINARY="$BLD_CONFIG_CMAKE_MSYS_BIN"
		CC=`cygpath -u "$CC"`
		LD=`cygpath -u "$LD"`
		CXX="${CC}"
		AR=`cygpath -u "$AR"`
		ASM="${CC}"
		export CXX LD CC AR ASM
		;;

	vs)
		CMAKE_MAKE_ADDL+=" --config $BLD_CONFIG_CMAKE_BUILD_TARGET_AUTO"
		;;
	unix)
		CMAKE_TARGET="Unix Makefiles"
		CMAKE_MAKE_ADDL=""
		CMAKE_MAKE_BINARY="make"
		CMAKE_INSTALL_ADDL="install"
		CMAKE_ADDL_FLAGS="-DCMAKE_MAKE_PROGRAM=/usr/bin/make -DCMAKE_IGNORE_PATH=/usr/bin -DCMAKE_LINKER=${LD}  -DCMAKE_C_LINK_EXECUTABLE=\"${LD}\" -DCMAKE_CXX_LINK_EXECUTABLE=\"${LD}\" " #ignore is to fix link.exe chosen wrong issue
		;;
	msys)
		CMAKE_TARGET="MSYS Makefiles"
		CMAKE_MAKE_ADDL=""
		CMAKE_MAKE_BINARY="make"
		CMAKE_INSTALL_ADDL="install"
		BASH_EXEC=`which bash`
		BASH_EXEC=`cygpath -m $BASH_EXEC`
		#find -name "link.txt" | xargs sed -i -E "s#^\"(.+?)\"#\1#g" || true #first we strip any quotes off the initial param, then we will escape the other quotse before wrapping it in a bash call

		
		find -name "link.txt" | xargs --no-run-if-empty sed -i -E -e '/bash.exe/!s#^\"([^\"]+?)\"#\1#g;/bash.exe/!s/"/\\"/g;/bash.exe/!s#(.+)#ZBASHEXEC -c \"\1\"#' -e "s#ZBASHEXEC#$BASH_EXEC#"
		# || true #first we strip any quotes off the initial param we escape all remaining quotes, then put the everything to a bash -c
		#LD="c:/repo/WIN64LinuxBuild/wraps/link.bat"
		#AR="c:/repo/WIN64LinuxBuild/wraps/lib.bat"
		CMAKE_CONFIG_CLI_CFLAGS="" #will use env ones
		CXX="${CC}"
		ASM="${CC}"
#		AR=`cygpath -u "$AR"`
		export CXX LD CC AR ASM
		CMAKE_ADDL_FLAGS="-DCMAKE_LINKER=${LD}"
		;;
	unix-msys)
		CMAKE_TARGET="Unix Makefiles"	
		CMAKE_MAKE_ADDL=""
		CMAKE_MAKE_BINARY="make"
		CMAKE_INSTALL_ADDL="install"
		#CMAKE_MAKE_BINARY="$BLD_CONFIG_CMAKE_MSYS_BIN"
		find -name "link.txt" | xargs sed -i -E "s#^\"(.+?)\"#\1#g" || true #it hs the linker command in quotes causing an issue we strip them and all is well
		if [[ ! -z "$CMAKE_PREFIX_DIR" ]]; then
			CMAKE_PREFIX_DIR=`cygpath -u "$CMAKE_PREFIX_DIR"`
		fi
		CMAKE_CONFIG_BINARY="$BLD_CONFIG_CMAKE_MSYS_BIN"
		CC=`cygpath -u "$CC"`
		LD=`cygpath -u "$LD"`
		CXX="${CC}"
		AR=`cygpath -u "$AR"`
		ASM="${CC}"
		export CXX LD CC AR ASM
		;;
	nmake)
		CMAKE_MAKE_BINARY="nmake"
		CMAKE_TARGET="NMake Makefiles"
		;;
	nmake-launchers)
		CMAKE_MAKE_BINARY="nmake"
		unset CC CXX
		export GNU_BUILD_WRAPPER_DEBUG=1
		LAUNCHER="${WIN_SCRIPT_FOLDER}/windows_command_wrapper.bat"
		CMAKE_ADDL_FLAGS="-DCMAKE_CXX_LINKER_LAUNCHER=${LAUNCHER} -DCMAKE_C_LINKER_LAUNCHER=${LAUNCHER} -DCMAKE_C_COMPILER_LAUNCHER=${LAUNCHER} -DCMAKE_CXX_COMPILER_LAUNCHER=${LAUNCHER}"
		CMAKE_TARGET="NMake Makefiles"
		;;
	esac
}
function cmake_config_run(){
	CUR_STEP="configure"
	#echo -n "Running: cmake " 1>&2
	#printf "%q " "$@" 1>&2
	#echo $@
	#echo ""
	setup_build_env "$@";
	#these almost certainly wont work   normally the static and release are prefixed by something
	declare -g -a CMAKE_FULL_CONFIG_CMD_ARR=("${BLD_CONFIG_CMAKE_CONFIG_CMD_DEFAULT[@]}")
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq "1" ]]; then
		CMAKE_FULL_CONFIG_CMD_ARR+=( "${BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL_STATIC[@]}" )
		ADL_C_FLAGS+=" ${BLD_CONFIG_CMAKE_BUILD_ADDL_CFLAGS_STATIC[*]}"
	else
		CMAKE_FULL_CONFIG_CMD_ARR+=( "${BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL_SHARED[@]}" )
	fi;
	if [[ ! $BLD_CONFIG_BUILD_DEBUG ]]; then
		CMAKE_FULL_CONFIG_CMD_ARR+=( "${BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL_DEBUG[@]}" )
	fi
	CMAKE_FULL_CONFIG_CMD_ARR+=("${BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL[@]}")

	#  -DCMAKE_C_COMPILER="${CC}" -DCMAKE_CXX_COMPILER="${CXX}" -DCMAKE_AR="${AR}" -DCMAKE_LINKER="${LD}"
	# well it will call these but its calling from win so bash scripts wont work would need them as PS
	# We used to do -G "Visual Studio 17 2022" but that doesn't really work with custom compiler/linker/etc specs as it calls msbuild
	#unix makefiles work

# -DCMAKE_C_COMPILER:FILEPATH="${CC}" -DCMAKE_CXX_COMPILER:FILEPATH="${CXX}" -DCMAKE_AR="${AR}" -DCMAKE_LINKER="${LD}" -DCMAKE_ASM_COMPILER:FILEPATH="${CC}"
#MSYS Makefiles

	cmake_settings_setup;

	EXPORT_CMDS=" -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=1" #only works for makefiles and ninja generators for nmake it does get you real names but no linker command, may not work with unix ones
	export -p > "/tmp/test.sh"
	_cmake $CMAKE_CONFIG_BINARY -G "$CMAKE_TARGET" --install-prefix "$CMAKE_PREFIX_DIR" $CMAKE_ADDL_FLAGS $EXPORT_CMDS -DCMAKE_C_FLAGS_DEBUG:STRING="${CMAKE_CONFIG_CLI_CFLAGS}" -DCMAKE_C_FLAGS_RELEASE:STRING="${CMAKE_CONFIG_CLI_CFLAGS}" -DCMAKE_C_FLAGS_RELWITHDEBINFO:STRING="${CMAKE_CONFIG_CLI_CFLAGS}" -DCMAKE_AR="${AR}" -DCMAKE_C_FLAGS_MINSIZEREL:STRING="${CMAKE_CONFIG_CLI_CFLAGS}" "${CMAKE_FULL_CONFIG_CMD_ARR[@]}" > >(tee "${BLD_CONFIG_LOG_CONFIGURE_FILE}");
	SKIP_STEP="";CUR_STEP="";
	CMAKE_MAKE_ADDL+=" ${BLD_CONFIG_BUILD_MAKE_CMD_ADDL[*]}"
}
function cmake_make(){
	CUR_STEP="make"
	cmake_settings_setup;
	cd $BLD_CONFIG_CMAKE_BUILD_DIR
	if [[ -n "${LOG_MAKE_RUN}" ]]; then
		run_logged_make $CMAKE_MAKE_BINARY $CMAKE_MAKE_ADDL "$@"
	else
		_cmake $CMAKE_MAKE_BINARY $CMAKE_MAKE_ADDL "$@"
	fi
	cd $BLD_CONFIG_SRC_FOLDER
}
function _cmake(){
	 echo "Running ${*@Q}" 1>&2 
	ex "$@"
}
function cmake_install(){
	cmake_settings_setup;
	PDB=1
	if [[ "$1" == "-nopdb" ]]; then
		PDB=0
		shift 1;
	fi
	cd $BLD_CONFIG_CMAKE_BUILD_DIR
	ex $CMAKE_MAKE_BINARY $CMAKE_INSTALL_ADDL  "$@"
	if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
		mkdir -p "${BLD_CONFIG_INSTALL_FOLDER}/bin"
#		cd "${BLD_CONFIG_CMAKE_BUILD_DIR}"
		if [[ $PDB -eq 1 ]]; then
			copy_pdbs;
		fi
		cd ..
	fi
	#need to rename binarys with .exe extenson
	cd $BLD_CONFIG_SRC_FOLDER
}