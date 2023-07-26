#!/bin/bash
set -eo pipefail -o functrace
shopt -s inherit_errexit
#while we could export SHELLOPTS many scripts dont work well with pipefail enabled

declare -g SKIP_STEP="$1"
declare -g CALL_SCRIPT_PATH="$(readlink -f "$0")"
declare -g SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER:-$(dirname "$(CALL_SCRIPT_PATH)")}"
declare -g LOG_MAKE_RUN=""
declare -g LOG_MAKE_CONTINUE=0

#full allows you to run all the steps including it, or resume earlier through it rather than just it
case "$SKIP_STEP" in
	log_raw_build|log)
		LOG_MAKE_RUN="raw"
		;;
	log_raw_build_full|log_full)
		LOG_MAKE_RUN="raw"
		SKIP_STEP="$2"
		LOG_MAKE_CONTINUE=1
		;;
	log_make)
		LOG_MAKE_RUN="make"
		;;
	log_make_full)
		LOG_MAKE_RUN="make"
		SKIP_STEP="$2"
		;;
esac


#if a env variable is completely undefined our changes wont be picked up unless past directly to the command or exported

pkg_config_manual_add(){
	#pkg-config --list-package-names to get package names
	echo $PKG_CONFIG_PATH
	for VAR in "$@"; do
		pkg-config --print-errors "${VAR}"
		local ADD_LIBS=`pkg-config --libs "${VAR}"`
		local ADD_FLAGS=`pkg-config --cflags "${VAR}"`
		CFLAGS="${CFLAGS} ${ADD_FLAGS}"
		#not everrything pays attention to LIBS=
		LDFLAGS="${LDFLAGS} ${ADD_LIBS}"
	done
}

get_install_prefix_for_pkg(){
	local BLD_NAME=$1
	# cheating rather than actually try to reparse templates
	echo "${BLD_CONFIG_INSTALL_FOLDER/"${BLD_CONFIG_BUILD_FOLDER_NAME}"/"${BLD_NAME}"}"
}
add_lib_pkg_config(){
	local PTH=""
	for var in "$@"; do
		PTH=$(get_install_prefix_for_pkg "${var}")
		PTH=$(convert_to_msys_path "${PTH}")
		if [ ! -d "${PTH}" ]; then
			echo "Error not able to find lib directory to add: ${var} as path does not exist: ${PTH}" 1>&2;
			exit 1
		fi
		PKG_CONFIG_PATH="${PTH}/lib/pkgconfig:${PKG_CONFIG_PATH}";
	done
}
convert_from_msys_path () {
	local WPATH=$1
	if ! [ -z ${MSYS+x} ]; then
		WPATH=`cygpath -m "$WPATH"`
	fi
	echo $WPATH
}
apply_our_repo_patch () {
	local PATCH_NAME="${1:-$BLD_CONFIG_BUILD_NAME}"
	PATCH_PATH="${WIN_SCRIPT_FOLDER}/patches/repo_${PATCH_NAME}.patch"
	if [[ -f "${PATCH_PATH}" ]]; then
		git_apply_patch "${PATCH_PATH}"
	else
		echo "Error apply_our_repo_patch called but can't find patch at: ${PATCH_PATH}" 1>&2;
		exit 1
	fi
}
git_apply_patch () {
	local PATCH=$1
	ex git apply --ignore-space-change --ignore-whitespace "$PATCH"
}
convert_to_msys_path () {
	local WPATH=$1
	WPATH=`cygpath -u "$WPATH"`
	echo $WPATH
}
convert_to_universal_path () {
	local WPATH=$1
	WPATH=`cygpath -m "$WPATH"`
	echo $WPATH
}
WIN_SCRIPT_FOLDER=$(convert_to_universal_path "$SCRIPT_FOLDER")

regex_strip_to_first_match() {
	local REG=$1
	if [[ "$line" =~ $REG ]]; then
		line="${BASH_REMATCH[1]}"
	fi
}

function tee_cmd_outs() {
	CMD=$1
	"$@" > >(tee "${CMD}.stdout") 2> >(tee "${CMD}.stderr" >&2)
}

SetupIgnores(){
	IGNORE_CMDS=("${BLD_CONFIG_LOG_IGNORE_CMDS_EXACT_DEFAULT[@]}" "${BLD_CONFIG_LOG_IGNORE_CMDS_EXACT_ADDL[@]}")
	declare -g -A ignore_map
	for key in "${IGNORE_CMDS[@]}"; do ignore_map["${key,,}"]=1; done
	declare -g -a REGEX_IGNORE_CMDS=("${BLD_CONFIG_LOG_IGNORE_CMDS_REGEX_DEFAULT[@]}" "${BLD_CONFIG_LOG_IGNORE_CMDS_REGEX_ADDL[@]}")
}

PreInitialize(){
	ini_read;
}

function make_install(){
	
	$BLD_CONFIG_BUILD_MAKE_BIN install "$@"
	if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
		mkdir -p "${BLD_CONFIG_INSTALL_FOLDER}/bin"
		find -name "*.pdb" | grep -v vc1 | xargs cp -t "${BLD_CONFIG_INSTALL_FOLDER}/bin" &>/dev/null || true
	fi
}
function copy_pdbs(){
	ex find -name "*.pdb" | grep -v vc1 | xargs cp -t "${BLD_CONFIG_INSTALL_FOLDER}/bin" &>/dev/null || true
}

declare -g ADDL_OUTPUT_MESSAGE=""
function run_logged_make(){
	echo "Starting logged build run sure you have a clean build as any pre-built items are not logged"
	CMD="$BLD_CONFIG_BUILD_MAKE_BIN"
	if [[ $# != 0 ]]; then
		CMD="$1"
		shift 1;
	else
		set - "-j1" "$@"
	fi
	OUTPUT_FILE=""
	if [[ $LOG_MAKE_RUN == "make" || $LOG_MAKE_RUN == "$BLD_CONFIG_BUILD_MAKE_BIN" ]]; then
		OUTPUT_FILE="${BLD_CONFIG_LOG_MAKE_CMD_FILE}"
		"$CMD" --just-print "$@" | tee "${BLD_CONFIG_LOG_MAKE_CMD_FILE}"
	elif [[ $LOG_MAKE_RUN == "raw" ]]; then
		OUTPUT_FILE="${BLD_CONFIG_LOG_RAW_BUILD_FILE}"

		echo "" > "$BLD_CONFIG_LOG_RAW_BUILD_FILE"
		echo -n `pwd` > "$BLD_CONFIG_LOG_RAW_BUILD_FILE".tmpcurdir
		old_GNU_BUILD_WRAPPER_DEBUG="$GNU_BUILD_WRAPPER_DEBUG"
		export GNU_BUILD_WRAPPER_DEBUG=1 GNU_BUILD_CMD_FILE="${BLD_CONFIG_LOG_RAW_BUILD_FILE}"
		ex "$CMD" "$@"
		unset GNU_BUILD_CMD_FILE
		export GNU_BUILD_WRAPPER_DEBUG="$old_GNU_BUILD_WRAPPER_DEBUG"
	else
		echo "Logged make called but the type was not preset????" 1>&2
		exit 1
	fi
	
	ADDL_OUTPUT_MESSAGE="DONE ${COLOR_MINOR}BUILD FILE${COLOR_NONE} to \"${COLOR_MAJOR}${OUTPUT_FILE}${COLOR_NONE}\" suggest also copying the env file: \"${COLOR_MAJOR}${BLD_CONFIG_LOG_CONFIG_ENV_FILE}${COLOR_NONE}\""
	echo -e $ADDL_OUTPUT_MESSAGE
	if [[ $LOG_MAKE_RUN == "raw" ]]; then
		unlink "$BLD_CONFIG_LOG_RAW_BUILD_FILE".tmpcurdir
		unset GNU_BUILD_WRAPPER_DEBUG GNU_BUILD_CMD_FILE
	fi
	if [[ $LOG_MAKE_CONTINUE -eq 0 ]]; then
		exit 0
	fi
}
function configure_run(){
	setup_build_env;
	echo "Running ./configure ${config_cmd}" 1>&2
	#gl_cv_host_operating_system="MSYS2" ac_cv_host="x86_64-w64-msys2" ac_cv_build="x86_64-w64-msys2"
}
declare -g SETUP_BUILD_ENV_RUN=0
function setup_build_env(){
	ADL_LIB_FLAGS=""
	ADL_C_FLAGS=""
	if [[ $SETUP_BUILD_ENV_RUN -eq 1 ]]; then
		echo "setup_build_env() called twice, this would cause some vars to stack to do including the prev value and also break caches" 1>&2
		exit 1
	fi
	LINK_PATH=$(convert_to_universal_path "$VCToolsInstallDir")
	LINK_PATH="${LINK_PATH}bin/HostX64/x64/link.exe"
	SETUP_BUILD_ENV_RUN=1
	CL_PREFIX=""
	USING_GNU_COMPILE_WRAPPER=0
	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq 1 ]] || [[ $BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED -eq 1 ]]; then

		gnulib_ensure_buildaux_scripts_copied
		local gnu_compile_path=$(convert_to_universal_path "${BLD_CONFIG_BUILD_AUX_FOLDER}/compile")
		local gnu_arlib_path=$(convert_to_universal_path "${BLD_CONFIG_BUILD_AUX_FOLDER}/ar-lib")
		local gnu_ldlink_path=$(convert_to_universal_path "${BLD_CONFIG_BUILD_AUX_FOLDER}/ld-link")
		CL_PREFIX="${gnu_compile_path} "
		AR="${gnu_arlib_path} lib"
		export MS_LINK="$LINK_PATH"
		LINK_PATH="${gnu_ldlink_path} "
		USING_GNU_COMPILE_WRAPPER=1
	fi
	XLINKER_CMD="-Xlinker"
	if [[ $BLD_CONFIG_BUILD_WINDOWS_COMPILE_WRAPPERS -eq 1 && $USING_GNU_COMPILE_WRAPPER -eq 0 ]]; then
		XLINKER_CMD=""
	fi
	if [[ $BLD_CONFIG_ADD_WIN_ARGV_LIB -eq 1 ]]; then
		ADL_LIB_FLAGS+=" ${XLINKER_CMD} setargv.obj"
	fi
	
	config_cmd=$"$BLD_CONFIG_CONFIG_CMD_DEFAULT $BLD_CONFIG_CONFIG_CMD_ADDL"
	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq 1 ]]; then
		config_cmd=$"$config_cmd $CONFIG_CMD_GNULIB_ADDL"

	fi
	MSVC_DESIRED_LIB="msvcrt"
	if [[ $BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS -eq 1 ]]; then
		NO_DEFAULT_LIB_ARR=()
		MSVC_RUNTIME="MD"
		if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
			MSVC_DESIRED_LIB="libcmt"
			MSVC_RUNTIME="MT"
		else
			#ADL_C_FLAGS+=" /LD" #passes /dll to linker
			ADL_LIB_FLAGS+=" /DLL"
		fi
		if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
			ADL_C_FLAGS+=" /D_DEBUG ${BLD_CONFIG_BUILD_DEBUG_ADDL_CFLAGS} ${BLD_CONFIG_BUILD_MSVC_CL_DEBUG_OPTS}"
			ADL_LIB_FLAGS+=" /DEBUG"
			if [[ "$BUILD_MSVC_NO_DEFAULT_LIB" == "debug" ]]; then
				NO_DEFAULT_LIB_ARR+=($MSVC_DESIRED_LIB)
			fi
			MSVC_RUNTIME+="d"
			MSVC_DESIRED_LIB+="d"
		else
			ADL_C_FLAGS+=" /DNDEBUG ${BLD_CONFIG_BUILD_MSVC_CL_NDEBUG_OPTS}"
			if [[ "$BUILD_MSVC_NO_DEFAULT_LIB" == "debug" ]]; then
				NO_DEFAULT_LIB_ARR+=("${MSVC_DESIRED_LIB}d")
			fi
		fi
		if [[ "$BUILD_MSVC_NO_DEFAULT_LIB" == "full" ]]; then
			local ALL_LIBS=("libcmt" "libcmtd" "msvcrt" "msvcrtd")
			for lib in "${ALL_LIBS[@]}"; do
				if [[ "$lib" != "$MSVC_DESIRED_LIB" ]]; then
					NO_DEFAULT_LIB_ARR+=($lib)
				fi
			done
		fi
		ADL_C_FLAGS+=" /${MSVC_RUNTIME}"
		for lib in "${NO_DEFAULT_LIB_ARR[@]}"; do
			ADL_C_FLAGS+=" ${XLINKER_CMD} -NODEFAULTLIB:${lib}"
		done
	fi
	for warn in "${BLD_CONFIG_BUILD_MSVC_IGNORE_WARNINGS[@]}"; do
		ADL_C_FLAGS+=" /wd${warn}"
	done
	
	setup_gnulibtool_py_autoconfwrapper
	#not sure how to call two functions with the env vars set without using export
	local STATIC_ADD=" -nologo"
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 && $USING_GNU_COMPILE_WRAPPER -eq 1 ]]; then #if not using compile script this isnt needed as it is just for lib finding assist
		STATIC_ADD+=" -static" #we shouldnt nneed to add -MT here
	fi
	if [[ $BLD_CONFIG_LOG_DEBUG_WRAPPERS -eq 1 ]]; then
		export GNU_BUILD_WRAPPER_DEBUG=1

	fi
	if [[ $BLD_CONFIG_LOG_COLOR_HIGHLIGHT -eq 1 ]]; then
		export GNU_BUILD_WRAPPER_COLOR=1
	fi
	CXX="${CL_PREFIX}cl.exe"
	CL="${CL_PREFIX}cl.exe"
	if [[ $BLD_CONFIG_BUILD_WINDOWS_COMPILE_WRAPPERS -eq 1 && $USING_GNU_COMPILE_WRAPPER -eq 0 ]]; then
		CL="${WIN_SCRIPT_FOLDER}/wraps/cl.bat"
		#LINK_PATH="\"${WIN_SCRIPT_FOLDER}/windows_command_wrapper.bat\" \"${LINK_PATH}\""
		LINK_PATH="${WIN_SCRIPT_FOLDER}/wraps/link.bat"
		#echo "LINK PATH IS: $LINK_PATH"
		AR="${WIN_SCRIPT_FOLDER}/wraps/lib.bat"
		STATIC_ADD="-showIncludes ${STATIC_ADD}"
	fi
	export CXX="${CL}" AR="$AR" CC="${CL}" CYGPATH_W="echo" LDFLAGS="$ADL_LIB_FLAGS ${LDFLAGS}" CFLAGS="${STATIC_ADD} ${ADL_C_FLAGS} ${CFLAGS}" LIBS="${BLD_CONFIG_CONFIG_DEFAULT_WINDOWS_LIBS} ${BLD_CONFIG_CONFIG_ADL_LIBS}" LD="${LINK_PATH}";
	export -p > "$BLD_CONFIG_LOG_CONFIG_ENV_FILE";
}

function msys_bins_move_end_path(){
	local new_path=`echo "$PATH" | sed -E 's#^(([a-z0-9/]{3,}:)+)(/.+)#\3:\1#'`
	local last_char="${new_path: -1}"
	if [ $last_char == ":" ];then
		new_path="${new_path::-1}"
	fi
	PATH="$new_path"
}
function switch_lin_path_to_back(){
	ORIGPATH="$PATH"
	PATH=`echo $PATH | sed -E 's#^((/[^/:]{2,}[^:]+:)*)(.+)#\3\1#'`
}
function restore_orig_path(){
	PATH="$ORIGPATH"
}
function add_items_to_gitignore(){
	cd $BLD_CONFIG_SRC_FOLDER
	declare -a TO_ADD=("${BLD_CONFIG_GIT_IGNORE_DEFAULT[@]}" "${BLD_CONFIG_GIT_IGNORE_DEFAULT[@]}")
	printf '%s\n' "${TO_ADD[@]}" >> .gitignore
	awk -i inplace ' !x[$0]++' .gitignore
}

function configure_fixes(){
	cd $BLD_CONFIG_SRC_FOLDER
	if [[ $BLD_CONFIG_CONFIG_BYPASS_FILESYSTEM_LIST_FAIL -eq 1 ]]; then
		sed -i -E "s/^.+read list of mounted file systems.+$/echo 'Skipping FS Test fail'/" configure
	fi
	if [[ $BLD_CONFIG_CONFIG_GETHOSTNAME_FIX -eq 1 ]]; then
		#so while we will have GETHOSTNAME due to winsock it still wants to use the gnulib module which is fine, but with this set to comment outtrue it only redefined gethostname to use the rpl_gethostname but doesn't include the lib
		sed -i -E "s/GL_COND_OBJ_GETHOSTNAME_TRUE='#'/GL_COND_OBJ_GETHOSTNAME_TRUE=' '/g" configure
	fi


}
function git_settings_to_env(){
	declare -a GIT_SETTINGS=("${BLD_CONFIG_GIT_SETTINGS_DEFAULT[@]}")
	if [[ ${#BLD_CONFIG_GIT_SETTINGS_ADDL[@]} > 0 ]]; then
		GIT_SETTINGS+=("${BLD_CONFIG_GIT_SETTINGS_ADDL[@]}")
	fi
	GIT_SETTING_COUNT=${#GIT_SETTINGS[@]}
	GIT_CONFIG_COUNT=0

	for (( j=0; j<${GIT_SETTING_COUNT}; j++ )); do
		SETTING="${GIT_SETTINGS[$j]}"
		IFS=' ' read -ra KVP <<< "$SETTING"
		NAME="${KVP[0]}"
		VALUE="${KVP[1]}"
		if [[ $name -eq "" ]]; then
			continue;
		fi

		export GIT_CONFIG_KEY_${GIT_CONFIG_COUNT}="$NAME"
		export GIT_CONFIG_VALUE_${GIT_CONFIG_COUNT}="$VALUE"
		(( GIT_CONFIG_COUNT++ ))
	done
	export GIT_CONFIG_COUNT
}
function startcommon(){
	SetupIgnores;
	DoTemplateSubs;
	unset TMP
	unset TEMP
	mkdir -p "$BLD_CONFIG_SRC_FOLDER"
	cd "$BLD_CONFIG_SRC_FOLDER"
	if [[ $BLD_CONFIG_LOG_COLOR_HIGHLIGHT ]]; then
		COLOR_MINOR="${COLOR_MINOR:-\e[2;33m}"
		COLOR_MINOR2="${COLOR_MINOR2:-\e[2;36m}"
		COLOR_MAJOR="${COLOR_MAJOR:-\e[1;32m}"
		COLOR_ERROR="${COLOR_ERROR:-\e[1;31m}"
		COLOR_NONE="${COLOR_NONE:-\e[0m}"
	else
		COLOR_MINOR=""
		COLOR_MINOR2=""
		COLOR_MAJOR=""
		COLOR_ERROR=""
		COLOR_NONE=""	
	fi
	if [[ $SKIP_STEP == "gnulib_dump_patches" ]]; then
		gnulib_dump_patches;
		exit 0;
	fi
	if [[ $SKIP_STEP == "gnulib_tool_py_remove_nmd_makefiles" ]]; then
		gnulib_tool_py_remove_nmd_makefiles;
		exit 0;
	fi
	trace_init;

	#echo DEFAULT GIT SETTINGS ${BLD_CONFIG_GIT_SETTINGS_DEFAULT[@]} and other array: "${BLD_CONFIG_GIT_SETTINGS_ADDL[@]}"

	#echo GIT SSETTINGSS IS:  ${GIT_SETTINGS[@]}

	git_settings_to_env;

	#if [ -d "$BLD_CONFIG_SRC_FOLDER" ]; then
		#cd $BLD_CONFIG_SRC_FOLDER
	#else
		#cd $BLD_CONFIG_BASE_FOLDER
	#fi
	if [[ -n "$BLD_CONFIG_CMAKE_STYLE" ]]; then
		cmake_init;
	fi
}
function exit_ok(){
	trace_final
	exit 0
}
function exit_out(){
	local EXIT_CODE=$1
	local EXIT_MSG=$2
	trace_final
	echo "Exiting out due to: ${EXIT_MSG} with code: ${EXIT_CODE}" 1>&2
	exit $EXIT_CODE
}
function finalcommon(){
	echo -e DONE! ${COLOR_MINOR}Find output binaries${COLOR_NONE} in: ${COLOR_MAJOR}$BLD_CONFIG_INSTALL_FOLDER/bin${COLOR_NONE}
	if [[ -n "${ADDL_OUTPUT_MESSAGE}" ]]; then
		echo -e $ADDL_OUTPUT_MESSAGE
	fi
	if [[ "${LOG_MAKE_RUN}" -eq "raw" && -e "${BLD_CONFIG_LOG_RAW_BUILD_FILE}" ]]; then
		BUILD_OUT="$BLD_CONFIG_INSTALL_FOLDER/build"
		mkdir -p "$BUILD_OUT"
		cp -t "$BUILD_OUT" "${BLD_CONFIG_LOG_RAW_BUILD_FILE}" "${BLD_CONFIG_LOG_CONFIG_ENV_FILE}" &>/dev/null || true
		CFG_PATHS=("config.h" "lib/config.h" "gnulib/config.h" "gl/config.h" "include/config.h")
		for path in "${CFG_PATHS[@]}"; do
			if [[ -e "$path" ]]; then
				cp "$path" "$BUILD_OUT"
				break
			fi
		done
	fi
	trace_final;
	return 0;
}

. "$SCRIPT_FOLDER/helpers_ini.sh"
. "$SCRIPT_FOLDER/helpers_gnu.sh"
. "$SCRIPT_FOLDER/helpers_vcpkg.sh"
. "$SCRIPT_FOLDER/helpers_cmake.sh"
. "$SCRIPT_FOLDER/helpers_bashtrace.sh"
PreInitialize;