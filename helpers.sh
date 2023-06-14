#!/bin/bash
set -eo pipefail -o functrace
shopt -s inherit_errexit
#while we could export SHELLOPTS many scripts dont work well with pipefail enabled

CALL_CMD="$1"
CALL_SCRIPT_PATH="$2"
SCRIPT_FOLDER="$(dirname "$(readlink -f "$BASH_SOURCE")")"
#if a env variable is completely undefined our changes wont be picked up unless past directly to the command or exported


vcpkg_ensure_installed(){
	echo CHECKING FOR $BLD_CONFIG_VCPKG_BIN
	if [[ -f "${BLD_CONFIG_VCPKG_BIN}" ]]; then
    	return
	fi
	mkdir -p "${BLD_CONFIG_VCPKG_DIR}"
	cd "${BLD_CONFIG_VCPKG_DIR}"
	git clone https://github.com/microsoft/vcpkg .
	./bootstrap-vcpkg.bat
}

vcpkg_remove_package(){
	vcpkg_ensure_installed
	local TO_INSTALL=""
	for TO_INSTALL in "$@"; do
		mkdir -p "${BLD_CONFIG_VCPKG_BINARY_DIR}"
		export VCPKG_DEFAULT_BINARY_CACHE="${BLD_CONFIG_VCPKG_BINARY_DIR}"
		local INSTALL_ROOT=$(get_install_prefix_for_vcpkg_pkg "${TO_INSTALL}" "no_triplet")
		local INSTALL_TRIPLET=$(get_install_prefix_for_vcpkg_pkg "${TO_INSTALL}" "triplet") #this will have the triplet on it if strip is off
		local INSTALL_TARGET=$(get_install_prefix_for_vcpkg_pkg "${TO_INSTALL}") #triplet included when strip is off
		mkdir -p "${INSTALL_TARGET}"
		if [[ $BLD_CONFIG_VCPKG_STRIP_TRIPLET -eq 1 && ! -e "$INSTALL_TRIPLET" ]]; then
			ln -s "${INSTALL_TARGET}" "$INSTALL_TRIPLET"
		fi

		#host triplet doesnt seem to work 100%
		"${BLD_CONFIG_VCPKG_BIN}" remove "${TO_INSTALL}:${BLD_CONFIG_VCPKG_TRIPLET}" "--x-install-root=${INSTALL_ROOT}"

	done
}


vcpkg_install_package(){ #if the first parameter after optionally --head is a function that function will be called on install failure
	vcpkg_ensure_installed
	local TO_INSTALL=""
	local install_postfix=""
	if [[ "$1" == "--head" ]]; then
		shift;
		install_postfix="--head --editable"
	fi
	local ON_FAIL;
	if [ "$(type -t $1)" = "function" ]; then
		ON_FAIL=$1;
		shift;
	fi
	for TO_INSTALL in "$@"; do
		mkdir -p "${BLD_CONFIG_VCPKG_BINARY_DIR}"
		export VCPKG_DEFAULT_BINARY_CACHE="${BLD_CONFIG_VCPKG_BINARY_DIR}"
		local INSTALL_ROOT=$(get_install_prefix_for_vcpkg_pkg "${TO_INSTALL}" "no_triplet")
		local INSTALL_TRIPLET=$(get_install_prefix_for_vcpkg_pkg "${TO_INSTALL}" "triplet") #this will have the triplet on it if strip is off
		local INSTALL_TARGET=$(get_install_prefix_for_vcpkg_pkg "${TO_INSTALL}") #triplet included when strip is off
		mkdir -p "${INSTALL_TARGET}"
		if [[ $BLD_CONFIG_VCPKG_STRIP_TRIPLET -eq 1 && ! -e "$INSTALL_TRIPLET" ]]; then
			ln -s "${INSTALL_TARGET}" "$INSTALL_TRIPLET" 
		fi

		local RUN_CMD=""
		#host triplet doesnt seem to work 100%
		if [ -z ${ON_FAIL+x} ]; then
			"${BLD_CONFIG_VCPKG_BIN}" install "${TO_INSTALL}:${BLD_CONFIG_VCPKG_TRIPLET}" --host-triplet=${BLD_CONFIG_VCPKG_TRIPLET} --allow-unsupported "--x-install-root=${INSTALL_ROOT}" ${install_postfix}
		else
			"${BLD_CONFIG_VCPKG_BIN}" install "${TO_INSTALL}:${BLD_CONFIG_VCPKG_TRIPLET}" --host-triplet=${BLD_CONFIG_VCPKG_TRIPLET} --allow-unsupported "--x-install-root=${INSTALL_ROOT}" ${install_postfix} || {
				$ON_FAIL
				return;
			}
		fi
		
		local FILES=`find "${INSTALL_TARGET}" -name "*.pc"`
		if [[ "${FILES}" != "" ]]; then
			mapfile -t TO_FIX <<<$FILES
			for fl in "${TO_FIX[@]}"; do
				sed -i -E "s#^prefix=.+#prefix=${INSTALL_TARGET}#" "${fl}"
			done
		fi
		local DEBUG_DIR="${INSTALL_TARGET}/debug"
		if [[ -e "${DEBUG_DIR}" && $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
			if [[ -e "${INSTALL_TARGET}/debug/lib/pkgconfig" && -e "${INSTALL_TARGET}/lib/pkgconfig" ]]; then #assume normal pkg config is fine avoid needing to recurse
				rm -rf "${INSTALL_TARGET}/debug/lib/pkgconfig"
				rmdir --ignore-fail-on-non-empty "${INSTALL_TARGET}/debug/lib"
			fi
			for fl in "$DEBUG_DIR"/*; do
				if [[ -d "${fl}" ]]; then
					local DIR_NAME="${fl##*/}"    # print everything after the final "/"
					mv "${fl}"/* "${INSTALL_TARGET}/${DIR_NAME}/"
					rmdir "${fl}"
				else
					mv "${fl}" "${INSTALL_TARGET}/"
				fi
			done

			rmdir "${DEBUG_DIR}"
		fi
	done
}
get_install_prefix_for_vcpkg_pkg(){
	local BLD_NAME=$1
	local TRIPLET_FORCE=$2
	# cheating rather than actually try to reparse templates
	ADD_TRIPLET=""
	if [[  (! $BLD_CONFIG_VCPKG_STRIP_TRIPLET -eq 1 && ! $TRIPLET_FORCE == "no_triplet") || $TRIPLET_FORCE == "triplet" ]]; then
		ADD_TRIPLET="/${BLD_CONFIG_VCPKG_TRIPLET}"
	fi
	echo "${BLD_CONFIG_VCPKG_INSTALL_TARGET_BASEDIR}/${BLD_NAME}${ADD_TRIPLET}"
}
add_vcpkg_pkg_config(){
	local PTH=""
	#VCPKG_INSTALL_TARGET_BASEDIR
	for var in "$@"; do
		PTH=$(get_install_prefix_for_vcpkg_pkg "${var}")
		PTH=$(convert_to_msys_path "${PTH}")
		PKG_CONFIG_PATH="${PTH}/lib/pkgconfig:${PKG_CONFIG_PATH}";
	done
}
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
		git apply "${PATCH_PATH}"
	else
		echo "Error apply_our_repo_patch called but can't find patch at: ${PATCH_PATH}" 1>&2;
		exit 1
	fi
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



function cmake_config_run(){
	#echo -n "Running: cmake " 1>&2
	#printf "%q " "$@" 1>&2
	#echo $@
	#echo ""
	echo "Running cmake ${*@Q}" 1>&2
	
	#these almost certainly wont work   normally the static and release are prefixed by something
	STATIC_VAL=0
	SHARE_VAL=1
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		STATIC_VAL=1
		SHARE_VAL=0
	fi
	cmake -G "Visual Studio 17 2022" --install-prefix "$BLD_CONFIG_INSTALL_FOLDER" -S . -B winbuild -DCMAKE_C_FLAGS_DEBUG:STRING="${CFLAGS}" -DCMAKE_C_FLAGS_RELEASE:STRING="${CFLAGS}" -DCMAKE_C_FLAGS_RELWITHDEBINFO:STRING="${CFLAGS}" -DCMAKE_C_FLAGS_MINSIZEREL:STRING="${CFLAGS}" -DBUILD_STATIC:BOOL="${STATIC_VAL}" -DBUILD_SHARED:BOOL="${SHARE_VAL}" -DCMAKE_CONFIGURATION_TYPES:STRING="${BLD_CONFIG_CMAKE_BUILD_TARGET_AUTO}" -DCMAKE_BUILD_TYPE:STRING="${BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO}" "$@" > >(tee "${BLD_CONFIG_LOG_CONFIGURE_FILE}");
}
function configure_run(){
	setup_build_env;
	echo "Running ./configure ${config_cmd}" 1>&2
	./configure $config_cmd  > >(tee "${BLD_CONFIG_LOG_CONFIGURE_FILE}");
}
declare -g SETUP_BUILD_ENV_RUN=0
function setup_build_env(){
	ADL_LIB_FLAGS=""
	ADL_C_FLAGS=""
	if [[ $SETUP_BUILD_ENV_RUN -eq 1 ]]; then
		echo "setup_build_env() called twice, this would cause some vars to stack to do including the prev value and also break caches" 1>&2
		exit 1
	fi
	if [[ $BLD_CONFIG_ADD_WIN_ARGV_LIB -eq 1 ]]; then
		ADL_LIB_FLAGS+=" -Xlinker setargv.obj"
	fi
	SETUP_BUILD_ENV_RUN=1
	CL_PREFIX=""
	USING_GNU_COMPILE_WRAPPER=0
	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq 1 ]] || [[ $BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED -eq 1 ]]; then

		gnulib_ensure_buildaux_scripts_copied
		local gnu_compile_path=$(convert_to_universal_path "${BLD_CONFIG_BUILD_AUX_FOLDER}/compile")
		local gnu_arlib_path=$(convert_to_universal_path "${BLD_CONFIG_BUILD_AUX_FOLDER}/ar-lib")
		CL_PREFIX="${gnu_compile_path} "
		AR="${gnu_arlib_path} lib"
		USING_GNU_COMPILE_WRAPPER=1
	fi
	config_cmd=$"--config-cache $BLD_CONFIG_CONFIG_CMD_DEFAULT $BLD_CONFIG_CONFIG_CMD_ADDL"
	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq 1 ]]; then
		config_cmd=$"$config_cmd $CONFIG_CMD_GNULIB_ADDL"

	fi
	
	if [[ $BLD_CONFIG_BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS -eq 1 ]]; then
		MSVC_RUNTIME="MD"
		if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
			MSVC_RUNTIME="MT"
		else
			ADL_C_FLAGS+=" /LD" #passes /dll to linker
			ADL_LIB_FLAGS+=" /DLL"
		fi
		if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
			ADL_C_FLAGS+=" /D_DEBUG -DDEBUG ${BLD_CONFIG_BUILD_MSVC_CL_DEBUG_OPTS}" #DEBUG isn't n actual normal MSVC debug flag but several common repos will use it so might as well declare
			ADL_LIB_FLAGS+=" /DEBUG"
			MSVC_RUNTIME+="d"
		else
			ADL_C_FLAGS+=" /DNDEBUG ${BLD_CONFIG_BUILD_MSVC_CL_NDEBUG_OPTS}"
		fi
		ADL_C_FLAGS+=" /${MSVC_RUNTIME}"
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
		export DEBUG_GNU_COMPILE_WRAPPER=1 DEBUG_GNU_LIB_WRAPPER=1

	fi
	if [[ $BLD_CONFIG_LOG_COLOR_HIGHLIGHT -eq 1 ]]; then
		export COLOR_MINOR='\e[2;33m' COLOR_MINOR2='\e[2;36m' COLOR_MAJOR='\e[1;32m' COLOR_NONE='\e[0m'
	fi
	LINK_PATH=$(convert_to_universal_path "$VCToolsInstallDir")
	LINK_PATH="${LINK_PATH}bin/HostX64/x64/link.exe"
	export CXX="${CL_PREFIX}cl.exe${STATIC_ADD}" AR="$AR" CC="${CL_PREFIX}cl.exe${STATIC_ADD}" CYGPATH_W="echo" LDFLAGS="$ADL_LIB_FLAGS ${LDFLAGS}" CFLAGS="${ADL_C_FLAGS} ${CFLAGS}" LIBS="${BLD_CONFIG_CONFIG_DEFAULT_WINDOWS_LIBS} ${BLD_CONFIG_CONFIG_ADL_LIBS}" LD="${LINK_PATH}";
	export -p > "$BLD_CONFIG_LOG_CONFIG_ENV_FILE";
}
function log_make() {
	make --just-print --always-make "$@" 1> "${BLD_CONFIG_LOG_MAKE_CMD_FILE}"
	echo "Make commands saved to: ${BLD_CONFIG_LOG_MAKE_CMD_FILE}"
}

function msys_bins_move_end_path(){
	local new_path=`echo "$PATH" | sed -E 's#^(([a-z0-9/]{3,}:)+)(/.+)#\3:\1#'`
	local last_char="${new_path: -1}"
	if [ $last_char == ":" ];then
		new_path="${new_path::-1}"
	fi
	PATH="$new_path"
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
	declare -a GIT_SETTINGS=("${BLD_CONFIG_GIT_SETTINGS_DEFAULT[@]}" "${BLD_CONFIG_GIT_SETTINGS_ADDL[@]}")
	GIT_SETTING_COUNT=${#GIT_SETTINGS[@]}
	export GIT_CONFIG_COUNT=$GIT_SETTING_COUNT

	for (( j=0; j<${GIT_CONFIG_COUNT}; j++ ));
	do
		SETTING="${GIT_SETTINGS[$j]}"
		IFS=' ' read -ra KVP <<< "$SETTING"
		NAME="${KVP[0]}"
		VALUE="${KVP[1]}"

		export GIT_CONFIG_KEY_${j}="$NAME"
		export GIT_CONFIG_VALUE_${j}="$VALUE"
	done
}

function startcommon(){
	SetupIgnores;
	DoTemplateSubs;
	unset TMP
	unset TEMP
	mkdir -p "$BLD_CONFIG_SRC_FOLDER"
	cd "$BLD_CONFIG_SRC_FOLDER"
	if [[ $CALL_CMD == "gnulib_dump_patches" ]]; then
		gnulib_dump_patches;
		exit 0;
	fi
	if [[ $CALL_CMD == "gnulib_tool_py_remove_nmd_makefiles" ]]; then
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
	echo DONE! find binaries in: $BLD_CONFIG_INSTALL_FOLDER/bin
	trace_final;
	return 0;
}

. "$SCRIPT_FOLDER/helpers_ini.sh"
. "$SCRIPT_FOLDER/helpers_gnu.sh"
. "$SCRIPT_FOLDER/helpers_bashtrace.sh"
