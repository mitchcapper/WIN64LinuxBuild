#!/bin/bash

shopt -s inherit_errexit
#while we could export SHELLOPTS many scripts dont work well with pipefail enabled

declare -g SKIP_STEP="$1"
declare -g CUR_STEP=""
declare -g CALL_SCRIPT_PATH="$(readlink -f "$0")"
declare -g SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER:-$(dirname "$(CALL_SCRIPT_PATH)")}"
if [[ $SKIP_STEP == "dep_build" ]]; then
	OLD_ENV_FILE=$(mktemp --suffix _OrigENV.sh)
	export > "$OLD_ENV_FILE"
fi
declare -g LOG_MAKE_RUN=""
declare -g LOG_MAKE_CONTINUE=0

function usage(){
	load_colors;
	declare -A cmds=(
		[export_config]="Export project config to file for DebugProjGen.csx"
		[log_raw_build|log]="Normal full run except create a .bat file for the commands run for the build process"
		[log_raw_build_full|log_full]="Same as above, but can pass an additional step arg after to start at a certain step"
		[log_make|log_make_full]="Similar to raw build above but runs make's dry run and generates that log, _full like on log_raw can start at a certain step"		
		[our_patch]="Apply our patch for this repo"
		[checkout]="Checkout the original repo"
		[gnulib]="checkout gnulib and apply our patches to it"
		[bootstrap]="bootstrap gnulib and related project autoconf files"
		[configure]="configure run (does use cache opt)"
		[make]="make, default that happens if not matched to another arg (but an arg is passed)"
		[make_single]="same as make, but no skip even the first parallel make try (aka -j1)"
		[make_log_undefines]="Try make but capture output and put undefined symbols into undefines.txt"
		[makefiles]="runs ./config.status to regenerate makefile templates from config output before make"
		[dep_print]="Print the other build libs we depend on"
		[dep_build]="Call the build scripts for our deps if their final directory doesn't exist"
		[force_buildaux_install]="Shouldn't be needed but force install our build-aux files and do libtool patching if something happened"
	)
	comp_str=""
	OUR_NAME=$(basename "$0")
	if [[ $SKIP_STEP != "autocomplete" ]]; then
		echo "$OUR_NAME <skip_to_step_or_cmd> - build script, steps: "
	fi
	for key in "${!cmds[@]}"; do
		if [[ $SKIP_STEP != "autocomplete" ]]; then
			echo -e "\t${COLOR_MAJOR}${key}${COLOR_NONE} - ${COLOR_MINOR2}${cmds[$key]}${COLOR_NONE}"
		fi
		IFS='|' read -ra ALL <<< "$key"
		for key in "${ALL[@]}"; do 
			comp_str+="${key} ";
		done
	done
	if [[ $SKIP_STEP == "autocomplete" ]]; then
		echo "$comp_str"
		exit 0
	fi

	exit 1
}
#full allows you to run all the steps including it, or resume earlier through it rather than just it
case "$SKIP_STEP" in
	log_raw_build|log)
		LOG_MAKE_RUN="raw"
		SKIP_STEP=""
		LOG_MAKE_CONTINUE=1
		;;
	log_raw_build_full|log_full)
		LOG_MAKE_RUN="raw"
		SKIP_STEP="$2"
		LOG_MAKE_CONTINUE=1
		;;
	log_make)
		LOG_MAKE_RUN="make"
		SKIP_STEP=""
		;;
	log_make_full)
		LOG_MAKE_RUN="make"
		SKIP_STEP="$2"
		;;
esac

pkg_config_automake_static_fix(){
	#for configure.ac there is PKG_CHECK_MODULES_STATIC but not everything is updated for that for static builds
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 && -e "configure.ac" ]]; then
		sed -i -E "s#PKG_CHECK_MODULES_STATIC#PKG_CHECK_MODULES#g;s#PKG_CHECK_MODULES#PKG_CHECK_MODULES_STATIC#g" configure.ac
	fi

}
#if a env variable is completely undefined our changes wont be picked up unless past directly to the command or exported
pkg_config_manual_add(){
	#pkg-config --list-package-names to get package names
	#echo $PKG_CONFIG_PATH
	for VAR in "$@"; do
		pkg-config --print-errors "${VAR}"
		staticAdd=""
		if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
			staticAdd="--static"
		fi
		local ADD_LIBS=`pkg-config $staticAdd --libs "${VAR}"`
		local ADD_FLAGS=`pkg-config --cflags "${VAR}"`
		if [[ -z "${ADD_LIBS}" && -z "${ADD_LIBS}" ]]; then
			echo "Error Asked to not able to find pkg-config for $VAR but it returned no libs or flags, something probably wrong" 1>&2;
			exit 1
		fi
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
add_lib_bin_to_path(){
	#Adds a library/app we have compiled's final/bin dir to the front of PATH
	local PTH=""
	for var in "$@"; do
		PTH=$(get_install_prefix_for_pkg "${var}")
		PTH=$(convert_to_msys_path "${PTH}")
		PTH+="/bin"
		if [ ! -d "${PTH}" ]; then
			echo "Error not able to find bind directory to add: ${var} as path does not exist: ${PTH}" 1>&2;
			exit 1
		fi
		PATH="${PTH}:${PATH}";
	done
}
add_lib_pkg_config(){
	# Adds a library that we compiled to the pkg-config path
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
	CUR_STEP="our_patch"
	local PATCH_NAME="${1:-$BLD_CONFIG_BUILD_NAME}"
	PATCH_PATH="${WIN_SCRIPT_FOLDER}/patches/repo_${PATCH_NAME}.patch"
	if [[ -f "${PATCH_PATH}" ]]; then
		if git diff --cached --quiet .gitignore; then #we already applied our ignore so we need to undo that and redo after patching to avoid wasting a stage on just that
			git restore .gitignore
			git checkout .gitignore || git clean -f .gitignore
		fi
		git_stash_cur_work_discard_staged_work
		git_apply_patch "${PATCH_PATH}"
		add_items_to_gitignore
		if [[ $BLD_CONFIG_CONFIG_PKG_CONFIG_STATIC_FIX -eq 1 ]]; then
			pkg_config_automake_static_fix
		fi
		git_stash_stage_patches_and_restore_cur_work
	else
		echo "Error apply_our_repo_patch called but can't find patch at: ${PATCH_PATH}" 1>&2;
		exit 1
	fi
	SKIP_STEP=""
}

osfixes_set_locations_dbg_add_to_libs(){
	osfixes_set_locations "$@"
	if [[ ! $BLD_CONFIG_BUILD_DEBUG ]]; then
		return;
	fi
	LDFLAGS+=" -Xlinker $OSFIXES_LIB"
}
osfixes_bare_compile(){
	pushd $OSFIXES_SRC_DST_FLDR
	osfixes_link_in_if_dbg_and_stg
	ex cl.exe -D_DEBUG -DDEBUG /nologo /c /ZI /MTd -DWLB_DISABLE_DEBUG_ASSERT_POPUP_AT_LAUNCH "$OSFIXES_SRC_DST"
	#ex lib.exe /nologo "${OSFIXES_SRC_DST::-1}obj" want to do obj to make sure it is always incldued
	popd
}
osfixes_set_locations(){
	declare -g OSFIXES_HEADER_DST="$BLD_CONFIG_SRC_FOLDER"
	declare -g OSFIXES_SRC_DST_FLDR="$BLD_CONFIG_SRC_FOLDER"
	if [[ "$#" -gt 0 ]]; then
		OSFIXES_HEADER_DST="$1"
		if [[ "$#" -gt 1 ]]; then
			OSFIXES_SRC_DST_FLDR="$2"
		fi
	fi
	declare -g OSFIXES_SRC_DST="${OSFIXES_SRC_DST_FLDR}/osfixes.c"
	OSFIXES_HEADER_DST+="/osfixes.h"
	#declare -g OSFIXES_LIB="${OSFIXES_SRC_DST::-1}lib"
	declare -g OSFIXES_LIB="${OSFIXES_SRC_DST::-1}obj"

}

osfixes_link_in_if_dbg_and_stg() {
	if [[ ! $BLD_CONFIG_BUILD_DEBUG ]]; then
		return;
	fi
	osfixes_link_in_if_needed;
	git_staging_add "$OSFIXES_SRC_DST" "$OSFIXES_HEADER_DST"
}
# first arg is header folder, second arg is c file folder
osfixes_link_in_if_needed()  {
	
	if [[ ! -e "${OSFIXES_SRC_DST}" ]]; then
		ln -s "${WLB_SCRIPT_FOLDER}/osfixes.c" "${OSFIXES_SRC_DST}"
	fi
	if [[ ! -e "${OSFIXES_HEADER_DST}" ]]; then
		ln -s "${WLB_SCRIPT_FOLDER}/osfixes.h" "${OSFIXES_HEADER_DST}"
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

function make_install(){
	
	declare -a INSTALL_ARGS=( "${BLD_CONFIG_BUILD_MAKE_INSTALL_CMD_ADDL[@]}" "$@" )
	ex $BLD_CONFIG_BUILD_MAKE_CMD_DEFAULT install "${INSTALL_ARGS[@]}"
	if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
		mkdir -p "${BLD_CONFIG_INSTALL_FOLDER}/bin"
		copy_pdbs
	fi
}
function copy_pdbs(){
	ex find -name "*.pdb" | grep -v vc1 | xargs cp -t "${BLD_CONFIG_INSTALL_FOLDER}/bin" &>/dev/null || true
}
function run_make(){
	CUR_STEP="make"
	declare -a DEF_MAKE_CMD=( "$BLD_CONFIG_BUILD_MAKE_CMD_DEFAULT" "${BLD_CONFIG_BUILD_MAKE_CMD_ADDL[@]}" "$@" )
	if [[ $SKIP_STEP == "makefiles" ]]; then
		./config.status
		CUR_STEP="";SKIP_STEP="";
	fi
	if [[ -n "${LOG_MAKE_RUN}" ]]; then
		run_logged_make "${DEF_MAKE_CMD[@]}"
	fi
	if [[ $SKIP_STEP == "log_undefines" ]]; then
		FL="undefined.txt"
		echo "Logging undefined symbols to ${FL}"
		ex "${DEF_MAKE_CMD[@]}" | rg --no-line-number -oP "unresolved external symbol.+referenced" | sed -E 's#unresolved external symbol(.+)referenced#\\1#g' | sort -u > $FL
		exit 1
		CUR_STEP="";SKIP_STEP="";
	fi
	if [[ $BLD_CONFIG_BUILD_MAKE_JOBS -gt 1 && $SKIP_STEP != "make_single" ]]; then
		declare -a MULTI_MAKE_CMD=( ${DEF_MAKE_CMD[0]} "-j" $BLD_CONFIG_BUILD_MAKE_JOBS "${DEF_MAKE_CMD[@]:1}" )
		ex "${MULTI_MAKE_CMD[@]}" || ex "${DEF_MAKE_CMD[@]}"
	else
		ex "${DEF_MAKE_CMD[@]}"
	fi
}
declare -g ADDL_OUTPUT_MESSAGE=""
function run_logged_make(){
	echo "Starting logged build run sure you have a clean build as any pre-built items are not logged"
	CMD="$BLD_CONFIG_BUILD_MAKE_CMD_DEFAULT"
	if [[ $# != 0 ]]; then
		CMD="$1"
		shift 1;
	else
		set - "-j1" "$@"
	fi
	OUTPUT_FILE=""
	if [[ $LOG_MAKE_RUN == "make" || $LOG_MAKE_RUN == "$BLD_CONFIG_BUILD_MAKE_CMD_DEFAULT" ]]; then
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
	if [[ $BLD_CONFIG_OUR_OS_FIXES_COMPILE -eq 1 || $BLD_CONFIG_OUR_OS_FIXES_APPLY_TO_DBG -eq 1 ]]; then
		osfixes_bare_compile;
	fi
	setup_build_env "$@";
	#gl_cv_host_operating_system="MSYS2" ac_cv_host="x86_64-w64-msys2" ac_cv_build="x86_64-w64-msys2"
	ex ./configure "${FULL_CONFIG_CMD_ARR[@]}"  > >(tee "${BLD_CONFIG_LOG_CONFIGURE_FILE}");
}
function use_custom_make_and_gsh(){
	BLD_CONFIG_BUILD_MAKE_CMD_DEFAULT="gnumake.exe"
	MAKESHELL="gsh.exe"
	DEFAULTMAKESHELL="$MAKESHELL"
	NOMAKESHELLS="/bin/sh"

	export MAKESHELL DEFAULTMAKESHELL NOMAKESHELLS
}
declare -g SETUP_BUILD_ENV_RUN=0

#sometimes we may update a command args from taking a users string to taking an array to fix escape issues, rather than require all scripts update right away we can use this to convert

function var_is_array(){
	local VAR_NAME=$1
	if [[ ! -v "$VAR_NAME" ]]; then
		echo 0
	fi
	local dec_stmt="$(declare -p $VAR_NAME)"
	[[ "${dec_stmt:0:10}" == 'declare -a' ]] && echo 1 || echo 0;
}

#This function was designed to convert variables we used to keep as strings (say command args) now store as arrays for better quoting support.  Ironically this function is able to break strings up slightly better than the default bash word splitting when passed to a function, so things that previously wouldn't work in a string will work here
function make_array_if_str(){
	local VAR_NAME=$1
	if [[ ! -v "$VAR_NAME" ]]; then
		return;
	fi
	if [[ "$(var_is_array $VAR_NAME)" != "1" ]]; then
		if [[ "${!VAR_NAME}" != "" ]]; then
			eval "array=(${!VAR_NAME})"
		else
			declare -a array=()
		fi
		declare -g $VAR_NAME=""
		declare -g -a $VAR_NAME
		declare -n ref_var="$VAR_NAME"
		ref_var=("${array[@]}")
	fi
}
function setup_build_env(){
	ADL_LIB_FLAGS=""
	ADL_C_FLAGS=""
	if [[ $BLD_CONFIG_GNU_LIBS_AUTORECONF_WRAPPER -eq 1 && $BLD_CONFIG_GNU_LIBS_AUTORECONF_WRAPPER -eq 1 && $BLD_CONFIG_GNU_LIBS_USED -ne 1 ]]; then
		setup_gnulibtool_py_autoconfwrapper; # if we didnt use gnu libs we didnt set this up before as we do it normally after the switch to master step
	fi

	pkg_config_manual_add "${BLD_CONFIG_PKG_CONFIG_MANUAL_ADD[@]}";
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

	declare -g -a FULL_CONFIG_CMD_ARR=("${BLD_CONFIG_CONFIG_CMD_DEFAULT[@]}")
	ADL_C_FLAGS+=" ${BLD_CONFIG_BUILD_ADDL_CFLAGS[*]}"
	ADL_LIB_FLAGS+=" ${BLD_CONFIG_BUILD_ADDL_LDFLAGS[*]}"

	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq "1" ]]; then
		FULL_CONFIG_CMD_ARR+=( "${BLD_CONFIG_CONFIG_CMD_ADDL_STATIC[@]}" )
		ADL_C_FLAGS+=" ${BLD_CONFIG_BUILD_ADDL_CFLAGS_STATIC[*]}"
	else
		FULL_CONFIG_CMD_ARR+=( "${BLD_CONFIG_CONFIG_CMD_ADDL_SHARED[@]}" )
	fi;
	if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
		FULL_CONFIG_CMD_ARR+=( "${BLD_CONFIG_CONFIG_CMD_ADDL_DEBUG[@]}" )
		ADL_C_FLAGS+=" ${BLD_CONFIG_BUILD_ADDL_CFLAGS_DEBUG[*]}"
	fi
	FULL_CONFIG_CMD_ARR+=("${BLD_CONFIG_CONFIG_CMD_ADDL[@]}")
	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq 1 ]]; then
		FULL_CONFIG_CMD_ARR+=("${BLD_CONFIG_CONFIG_CMD_GNULIB_ADDL[@]}")
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
		if [[ ${BLD_CONFIG_BUILD_DEBUG} -eq 1 ]]; then
		#the xlinker debug here is mostly needed for libtool which wont recognize it otherwise
			ADL_C_FLAGS+=" /D_DEBUG ${BLD_CONFIG_BUILD_MSVC_CL_DEBUG_OPTS} ${XLINKER_CMD} /DEBUG ${XLINKER_CMD} -ZI ${XLINKER_CMD} -Zf ${XLINKER_CMD} -FS"
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
	
	#not sure how to call two functions with the env vars set without using export
	local STATIC_ADD=" -nologo"
	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 && $USING_GNU_COMPILE_WRAPPER -eq 1 ]]; then #if not using compile script this isnt needed as it is just for lib finding assist
		STATIC_ADD+=" -static" #we shouldnt nneed to add -MT here
	fi
	CXX="${CL_PREFIX}cl.exe"
	CL="${CL_PREFIX}cl.exe"
	if [[ $BLD_CONFIG_BUILD_WINDOWS_COMPILE_WRAPPERS -eq 1 && $USING_GNU_COMPILE_WRAPPER -eq 0 ]]; then
		CL="${WIN_SCRIPT_FOLDER}/wraps/cl.bat"
		#LINK_PATH="\"${WIN_SCRIPT_FOLDER}/windows_command_wrapper.bat\" \"${LINK_PATH}\""
		LINK_PATH="${WIN_SCRIPT_FOLDER}/wraps/link.bat"
		#echo "LINK PATH IS: $LINK_PATH"
		AR="${WIN_SCRIPT_FOLDER}/wraps/lib.bat"
		STATIC_ADD="${STATIC_ADD}"
	fi
	declare -a LIB_ARR=("${BLD_CONFIG_CONFIG_DEFAULT_WINDOWS_LIBS[@]}" "${BLD_CONFIG_CONFIG_ADDL_LIBS[@]}")
	export CXX="${CL}" AR="$AR" CC="${CL}" CYGPATH_W="echo" LDFLAGS="$ADL_LIB_FLAGS ${LDFLAGS}" CFLAGS="${STATIC_ADD} ${ADL_C_FLAGS} ${CFLAGS}" LIBS="${LIB_ARR[*]}" LD="${LINK_PATH}";
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
function configure_apply_fixes_and_run(){
	CUR_STEP="configure"
	configure_fixes
	configure_run "$@"
	SKIP_STEP="";CUR_STEP="";
}
function configure_fixes(){
	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -e "build-aux/config.guess" ]]; then #while for the most part we can just use configure --host overrides for this, incase somewthing else calls the guess we have this
		echo -e  "#!/bin/sh\necho $BLD_CONFIG_FORCE_BUILD_ID" > build-aux/config.guess
	fi
	if [[ -e configure ]]; then
		cp configure _configure
		if [[ $BLD_CONFIG_CONFIG_BYPASS_FILESYSTEM_LIST_FAIL -eq 1 ]]; then
			sed -i -E "s/^.+read list of mounted file systems.+$/echo 'Skipping FS Test fail'/" _configure
		fi
		if [[ $BLD_CONFIG_CONFIG_GETHOSTNAME_FIX -eq 1 ]]; then
			#so while we will have GETHOSTNAME due to winsock it still wants to use the gnulib module which is fine, but with this set to comment outtrue it only redefined gethostname to use the rpl_gethostname but doesn't include the lib
			sed -i -E "s/GL_COND_OBJ_GETHOSTNAME_TRUE='#'/GL_COND_OBJ_GETHOSTNAME_TRUE=' '/g" _configure
		fi
		if [[ $BLD_CONFIG_CONFIG_FLEX_NO_UNISTD_FIX -eq 1 ]]; then
			sed -i -E 's/(cat >conftest.l <<_ACEOF)/\1\n%option nounistd/' _configure
		fi
		#some things incorrectly harvest strings up to the \n but literally leave a CR bare in the configure file this screws you if you try to edit it at all as many editors will change a bare CR to a CL adding a new line
		sed -i -E 's#\r##g' _configure
		if ! cmp -s "configure" "_configure"; then
			mv _configure configure
		fi
	fi
}
function ensure_perl_installed_set_exports(){
	export PERL="${BLD_CONFIG_PERL_DIR}/perl/bin/perl.exe"
	if [[ $1 == "AS" ]]; then	
		export AS="${BLD_CONFIG_PERL_DIR}/c/bin/as.exe"
	fi
	if [[ ! -f "${PERL}" ]]; then
		mkdir -p "${BLD_CONFIG_PERL_DIR}" && pushd "${BLD_CONFIG_PERL_DIR}"
		curl https://strawberryperl.com/download/5.32.1.1/strawberry-perl-5.32.1.1-64bit-portable.zip -o perl.zip
		unzip -q perl.zip
		popd
	fi
}

function load_colors(){
	COLOR_MINOR="${COLOR_MINOR:-\e[2;33m}"
	COLOR_MINOR2="${COLOR_MINOR2:-\e[2;36m}"
	COLOR_MAJOR="${COLOR_MAJOR:-\e[1;32m}"
	COLOR_ERROR="${COLOR_ERROR:-\e[1;31m}"
	COLOR_NONE="${COLOR_NONE:-\e[0m}"	
}

function startcommon(){
	SetupIgnores;
	DoTemplateSubs;

	unset TMP
	unset TEMP
	mkdir -p "$BLD_CONFIG_SRC_FOLDER"
	cd "$BLD_CONFIG_SRC_FOLDER"
	if [[ $BLD_CONFIG_LOG_COLOR_HIGHLIGHT ]]; then
		load_colors;
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
	if [[ $SKIP_STEP == "autoreconf_pre_run" ]]; then
		autoreconf_pre_run;
		exit 0;
	fi
	if [[ $SKIP_STEP == "autoreconf_post_run" ]]; then
		autoreconf_post_run;
		exit 0;
	fi
	if [[ $SKIP_STEP == "dep_print" ]]; then
		ALL_DEPS=( "${BLD_CONFIG_OUR_LIB_DEPS[@]}" "${BLD_CONFIG_OUR_LIB_BINS_PATH[@]}" )
		echo "Depends on: ${ALL_DEPS[@]}"
		exit 0;
	fi	
	trace_init;
	if [[ $SKIP_STEP == "dep_build" ]]; then
		ALL_DEPS=( "${BLD_CONFIG_OUR_LIB_DEPS[@]}" "${BLD_CONFIG_OUR_LIB_BINS_PATH[@]}" )
		#this is somewhat tricky as we don't want any vars set in this script to effect the next so we will export at start and then start a fresh env and import, we can't just souce it here as any new vars that were set by us would still be set if not originally set
		for dep in "${ALL_DEPS[@]}"; do
			PTH=$(get_install_prefix_for_pkg "${dep}")
			if [[ ! -d "$PTH" ]]; then
				ex env --ignore-environment /bin/bash -c "source \"${OLD_ENV_FILE}\" && rm \"${OLD_ENV_FILE}\" && \"${WLB_SCRIPT_FOLDER}/build/f_${dep}_build.sh\""
			else
				echo "Assuming dep ${dep} complete as final build directory exists"
			fi
			echo "Done with all deps."
		done
		exit 0;
	fi
	if [[ $SKIP_STEP == "force_buildaux_install" ]]; then
		gnulib_ensure_buildaux_scripts_copied --forced
		libtool_fixes
		echo "DONE if libtool fixes were also needed run autoreconf to apply our patches"
		exit 0;
	fi
	

	git_settings_to_env;

	if [[ -n "$BLD_CONFIG_CMAKE_STYLE" ]]; then
		cmake_init;
	fi
	gnulib_init;
	add_lib_pkg_config "${BLD_CONFIG_OUR_LIB_DEPS[@]}";
	add_lib_bin_to_path "${BLD_CONFIG_OUR_LIB_BINS_PATH[@]}";
	add_vcpkg_pkg_config "${BLD_CONFIG_VCPKG_DEPS[@]}";
	setup_gnulibtool_py_autoconfwrapper;
	if [[ $BLD_CONFIG_OUR_OS_FIXES_APPLY_TO_DBG -eq 1 ]]; then
		osfixes_set_locations_dbg_add_to_libs
	fi
	if [[ $BLD_CONFIG_LOG_DEBUG_WRAPPERS -eq 1 ]]; then
		export GNU_BUILD_WRAPPER_DEBUG=1
	fi
	if [[ $BLD_CONFIG_LOG_COLOR_HIGHLIGHT -eq 1 ]]; then
		export GNU_BUILD_WRAPPER_COLOR=1
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
		cp -t "$BUILD_OUT" "${BLD_CONFIG_LOG_RAW_BUILD_FILE}" "${BLD_CONFIG_LOG_FILE}"  &>/dev/null || true
		CFG_PATHS=("config.h" "lib/config.h" "gnulib/config.h" "gl/config.h" "include/config.h" "${BLD_CONFIG_LOG_CONFIG_ENV_FILE}" "config.cache" "config.log" "${BLD_CONFIG_LOG_CONFIGURE_FILE}")
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
. "$SCRIPT_FOLDER/helpers_git.sh"
. "$SCRIPT_FOLDER/helpers_ini.sh"
. "$SCRIPT_FOLDER/helpers_gnu.sh"
. "$SCRIPT_FOLDER/helpers_vcpkg.sh"
. "$SCRIPT_FOLDER/helpers_cmake.sh"
. "$SCRIPT_FOLDER/helpers_bashtrace.sh"
PreInitialize;
if [[ $SKIP_STEP == "-h" || $SKIP_STEP == "--help" || $SKIP_STEP == "help"  || $SKIP_STEP == "autocomplete" ]]; then
	usage;
fi;