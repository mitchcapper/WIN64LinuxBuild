
cmake_ensure_installed(){
	if [[ "$BLD_CONFIG_CMAKE_STYLE" == "unix-msys" ]]; then
		#echo CHECKING FOR $BLD_CONFIG_CMAKE_MSYS_BIN
		PTH=$(convert_to_msys_path "${BLD_CONFIG_CMAKE_MSYS_DIR}/usr/bin")
		PATH="${PATH}:${PTH}";
		CMAKE_REQUIRES_SUBSHELL_EXECUTE=1 #we need to run all cmake commands in a subshell as no matter what we do it wont pickup dlls next to cmake.exe and while it looks in path that is only path when bash is started
		export PATH
		if [[ -f "${BLD_CONFIG_CMAKE_MSYS_BIN}" ]]; then
			return
		fi
		mkdir -p "${BLD_CONFIG_CMAKE_MSYS_DIR}"
		cd "${BLD_CONFIG_CMAKE_MSYS_DIR}"
		wget "https://mirror.msys2.org/msys/x86_64/${BLD_CONFIG_CMAKE_MSYS_VER}" -O cmake.tar.zst

		for pkg in "${BLD_CONFIG_CMAKE_MSYS_ADDL_PKGS[@]}"; do
			wget "https://mirror.msys2.org/msys/x86_64/${pkg}" -O pkg.tar.zst
			tar -axf pkg.tar.zst
			rm pkg.tar.zst
		done

		#wget "https://mirror.msys2.org/msys/x86_64/${BLD_CONFIG_CMAKE_LIBUV_VER}" -O libuv.tar.zst
		
		tar -axf cmake.tar.zst #  --transform="s,.*/,," cant flatten as it backtracks itself to figure out the path/shared/etc
		#tar -axf libuv.tar.zst
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
	export LD="${CC}"

	CMAKE_TARGET="${BLD_CONFIG_CMAKE_VS_VERSION}"
	CMAKE_CONFIG_BINARY="cmake"
	CMAKE_MAKE_BINARY="cmake"
	CMAKE_MAKE_ADDL="--build ${BLD_CONFIG_CMAKE_BUILD_DIR} --verbose"
	CMAKE_INSTALL_ADDL=" --install ${BLD_CONFIG_CMAKE_BUILD_DIR}"
	CMAKE_PREFIX_DIR="$BLD_CONFIG_INSTALL_FOLDER"
	declare -a -G CMAKE_ADDL_FLAGS=()
	CMAKE_CONFIG_CLI_CFLAGS="${CFLAGS}"
	

	case "$BLD_CONFIG_CMAKE_STYLE" in
	ninja)
		CMAKE_MAKE_BINARY="ninja"
		CMAKE_TARGET="Ninja"
		CMAKE_MAKE_ADDL="-C ${BLD_CONFIG_CMAKE_BUILD_DIR} --verbose"
		CMAKE_INSTALL_ADDL="-C ${BLD_CONFIG_CMAKE_BUILD_DIR} install"
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
		CMAKE_ADDL_FLAGS=( "-DCMAKE_MAKE_PROGRAM=/usr/bin/make" "-DCMAKE_IGNORE_PATH=/usr/bin" "-DCMAKE_LINKER=${LD}"  "-DCMAKE_C_LINK_EXECUTABLE=${LD}" "-DCMAKE_CXX_LINK_EXECUTABLE=${LD}" ) #ignore is to fix link.exe chosen wrong issue
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
		
		#this is to fix the fact some cmake configs will not like AR being set with a space after the command
		
		# we need to condition on which cmakes need this and /tmp/ar needs to be checked to make sure we don't loop ourselves
		#echo "#!/bin/sh" > /tmp/ar.sh
		#echo "$AR \"\$@\"" >> /tmp/ar.sh
		#AR=/tmp/ar.sh


		#unset CC AR
		#AR=$(convert_to_msys_path "${AR}")
		export CXX LD CC AR ASM
		#MSYS_LD=$(convert_to_msys_path "${LD}")
		#  -DCMAKE_C_COMPILER_ID:STRING=GNU
		#  -DCMAKE_C_COMPILER_ID:STRING=MSVC -DCMAKE_C_COMPILER_VERSION:STRING=19.43.34604 
		# --trace  --debug-find
		CMAKE_ADDL_FLAGS=("-DCMAKE_LINKER=${MSYS_LD}" "-DCMAKE_DEBUG_DETECT_COMPILER:BOOL=ON" "-DCMAKE_C_COMPILER_ID:STRING=INVALID")
		#CMAKE_ADDL_FLAGS=""
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
		CMAKE_MAKE_ADDL=""
		CMAKE_INSTALL_ADDL="install"
		;;
	nmake-launchers)
		CMAKE_MAKE_BINARY="nmake"
		unset CC CXX
		export GNU_BUILD_WRAPPER_DEBUG=1
		LAUNCHER="${WIN_SCRIPT_FOLDER}/windows_command_wrapper.bat"
		CMAKE_ADDL_FLAGS=( "-DCMAKE_CXX_LINKER_LAUNCHER=${LAUNCHER}" "-DCMAKE_C_LINKER_LAUNCHER=${LAUNCHER}" "-DCMAKE_C_COMPILER_LAUNCHER=${LAUNCHER}" "-DCMAKE_CXX_COMPILER_LAUNCHER=${LAUNCHER}")
		CMAKE_TARGET="NMake Makefiles"
		CMAKE_MAKE_ADDL=""
		CMAKE_INSTALL_ADDL="install"
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
	# We do upper case them though so PROJNAME_BUILD_DEBUG etc work properly

	
	
	declare -g -a CMAKE_FULL_CONFIG_CMD_ARR=("${BLD_CONFIG_CMAKE_CONFIG_CMD_DEFAULT[@]}")
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq "1" ]]; then
		CMAKE_FULL_CONFIG_CMD_ARR+=( "${BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL_STATIC[@]^^}" )
		ADL_C_FLAGS+=" ${BLD_CONFIG_CMAKE_BUILD_ADDL_CFLAGS_STATIC[*]}"
	else
		CMAKE_FULL_CONFIG_CMD_ARR+=( "${BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL_SHARED[@]^^}" )
	fi;
	if [[ ! $BLD_CONFIG_BUILD_DEBUG ]]; then
		CMAKE_FULL_CONFIG_CMD_ARR+=( "${BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL_DEBUG[@]}" )
	fi
	CMAKE_FULL_CONFIG_CMD_ARR+=("${BLD_CONFIG_CMAKE_CONFIG_CMD_ADDL[@]^^}")
	CMAKE_FULL_CONFIG_CMD_ARR+=("${CMAKE_ADDL_FLAGS[@]}")
	# CMAKE_FULL_CONFIG_CMD_ARR+=("-DCMAKE_C_LINK_EXECUTABLE=${LD}" "-DCMAKE_CXX_LINK_EXECUTABLE=${LD}" ) #this breaks all linking commands for some reason
	CMAKE_FULL_CONFIG_CMD_ARR+=( "-DCMAKE_AR=${AR}" )

	CMAKE_FULL_CONFIG_CMD_ARR+=("-DCMAKE_MSVC_RUNTIME_LIBRARY_DEFAULT=123") #this is to prevent it from adding the wrong flags to the compiler string by default in terms of libs
	

	#  -DCMAKE_C_COMPILER="${CC}" -DCMAKE_CXX_COMPILER="${CXX}" -DCMAKE_AR="${AR}" -DCMAKE_LINKER="${LD}"
	# well it will call these but its calling from win so bash scripts wont work would need them as PS
	# We used to do -G "Visual Studio 17 2022" but that doesn't really work with custom compiler/linker/etc specs as it calls msbuild
	#unix makefiles work

# -DCMAKE_C_COMPILER:FILEPATH="${CC}" -DCMAKE_CXX_COMPILER:FILEPATH="${CXX}" -DCMAKE_AR="${AR}" -DCMAKE_LINKER="${LD}" -DCMAKE_ASM_COMPILER:FILEPATH="${CC}"
#MSYS Makefiles

	cmake_settings_setup;
	
	#debug flags
	#CMAKE_FULL_CONFIG_CMD_ARR+=( "--debug-trycompile" )
	#CMAKE_FULL_CONFIG_CMD_ARR+=( "--debug-output" )
	#CMAKE_FULL_CONFIG_CMD_ARR+=( "--trace" )
	
	
	EXPORT_CMDS=" -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=1" #only works for makefiles and ninja generators for nmake it does get you real names but no linker command, may not work with unix ones
	#export -p > "/tmp/test.sh"
	# -DCMAKE_AR="${AR}"


	
	export CXX LD CC AR ASM
	#  $DEBUG_FLAGS
	
	# IF you find you are getting -MD or -MDd added to the flags it is because CMAKE_MSVC_RUNTIME_LIBRARY_DEFAULT is not set which cauess it to happen something like set(CMAKE_MSVC_RUNTIME_LIBRARY_DEFAULT "MultiThreaded$<$<CONFIG:Debug>:Debug>")
	
	_cmake $CMAKE_CONFIG_BINARY -G "$CMAKE_TARGET" --fresh --install-prefix "$CMAKE_PREFIX_DIR" $EXPORT_CMDS -DCMAKE_C_FLAGS_DEBUG:STRING="${CMAKE_CONFIG_CLI_CFLAGS}" -DCMAKE_C_FLAGS_RELEASE:STRING="${CMAKE_CONFIG_CLI_CFLAGS}" -DCMAKE_C_FLAGS_RELWITHDEBINFO:STRING="${CMAKE_CONFIG_CLI_CFLAGS}"  -DCMAKE_LINKER=${LD} -DCMAKE_C_FLAGS_MINSIZEREL:STRING="${CMAKE_CONFIG_CLI_CFLAGS}" "${CMAKE_FULL_CONFIG_CMD_ARR[@]}" > >(tee "${BLD_CONFIG_LOG_CONFIGURE_FILE}");
	SKIP_STEP="";CUR_STEP="";
}
function cmake_make(){
	CUR_STEP="make"
	cmake_settings_setup;
	CMAKE_MAKE_ADDL+=" ${BLD_CONFIG_BUILD_MAKE_CMD_ADDL[*]}"
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

	if [[ "${CMAKE_REQUIRES_SUBSHELL_EXECUTE}" -eq 1 ]]; then
		# Convert arguments to a properly escaped command string
		cmd_str=$(printf "%q " "$@")
		# Replace original arguments with bash -c and the escaped command
		set -- bash -c "$cmd_str"
	fi
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