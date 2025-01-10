function gnulib_dump_patches(){
	declare -a PATCHES=("${BLD_CONFIG_GNU_LIBS_PATCHES_DEFAULT[@]}" "${BLD_CONFIG_GNU_LIBS_PATCHES_ADDL[@]}")
	STROUT=""
	for patch in "${PATCHES[@]}"; do
		if [[ "$STROUT" ]]; then
			STROUT+=","
		fi
		STROUT+="\"${patch}\""
	done
	echo "ScriptRes=[$STROUT]" >> "$GITHUB_OUTPUT"
}
function gnulib_add_submodule_to_proj() {
	git_submodule_sha=""
	submodule_branch="${BLD_CONFIG_GNU_LIBS_BRANCH}"
	if [[ ${#BLD_CONFIG_GNU_LIBS_BRANCH} -eq 40 ]]; then #its a sha not a branch name so lets do this manually
		git_submodule_sha="$BLD_CONFIG_GNU_LIBS_BRANCH"
		submodule_branch="master"
	fi
	ex git submodule add "${GIT_REF_ARGS[@]}" -b "$submodule_branch" git://git.savannah.gnu.org/gnulib.git "${GNULIB_DIR_NAME}"
	if [[ "$git_submodule_sha" != "" ]]; then
		ex git -C "${GNULIB_DIR_NAME}" checkout --quiet "$git_submodule_sha"
	fi
	if [[ "${BLD_CONFIG_GNU_LIBS_BRANCH}" && "${BLD_CONFIG_GNU_LIBS_BRANCH}" != "master" ]]; then
		git config "submodule.${GNULIB_DIR_NAME}.update" none #required to not switch off BLD_CONFIG_GNU_LIBS_BRANCH
	fi
	#ex git restore --staged "${GNULIB_DIR_NAME}"
	git_staging_add "${GNULIB_DIR_NAME}"
}
function gnulib_switch_to_master_and_patch(){
	CUR_STEP="gnulib"
	cd $BLD_CONFIG_SRC_FOLDER

	#sed -i -E "s#(gnulib_tool=.+gnulib-tool).py\$#\1#" bootstrap

	cd $BLD_CONFIG_SRC_FOLDER/gnulib

	#we do this process to make it easier to tell what changes we have actually made vs what changes were from our patches

	git_stash_cur_work_discard_staged_work
	
	if [[ ! -z "$BLD_CONFIG_GNU_LIBS_BRANCH" ]]; then
		git checkout "$BLD_CONFIG_GNU_LIBS_BRANCH"
	fi
	echo ++++++ Running on GNULIB commit `git rev-parse --abbrev-ref HEAD` `git rev-parse HEAD`
	rm -f build-aux/wrapper_helper.sh build-aux/wrapper_helper.sh build-aux/ld-link #temporary as we add files rn that the normal checkout clean doesn't cleanup
	gnulib_patches;
	git_stash_stage_patches_and_restore_cur_work
	setup_gnulibtool_py_autoconfwrapper;
	
	cd $BLD_CONFIG_SRC_FOLDER
	if [[ -f "Makefile.am" ]]; then
		SUBDIR_REGEX="^\\s*SUBDIRS\\s*="


		ORIG_LINE=`cat Makefile.am | grep "$SUBDIR_REGEX"`


		ORIG_LINE=" $ORIG_LINE "
		FINAL_LINE="$ORIG_LINE"

		if [[ $BLD_CONFIG_CONFIG_NO_TESTS -eq 1 ]]; then
			FINAL_LINE=${FINAL_LINE//" gnulib-tests "/" "}
			sed -E -i 's/\-\-with\-tests/--without-tests/g' bootstrap.conf
			sed -E -i 's/\-\-tests\-base[^ ]+//g' bootstrap.conf
			#if [[ $BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY -eq 1 ]]; then
				#sed -E -i 's#--automake-subdir##g' bootstrap.conf
			#fi
			sed -E -i 's/gnulib\-tests[^s]*//g' configure.ac

			rm -fr gnulib-tests
			#need to remove tests-base as it still trys to include the gunlib test file

		fi
		if [[ $BLD_CONFIG_CONFIG_NO_PO -eq 1 ]]; then
			FINAL_LINE=${FINAL_LINE//" po "/" "}
			FINAL_LINE=${FINAL_LINE//" gnulib_po "/" "}
			if [[ ! -d "build-aux" ]]; then #fixes error: required file 'build-aux/config.rpath' not found    this is a gettext file
				mkdir build-aux
			fi
			echo "" > build-aux/config.rpath
			sed -i -E 's/^[ ]*AM_GNU_GETTEXT/#AM_GNU_GETTEXT/g' configure.ac
			local GREP_LINE_REMOVE="texi2pdf"
			if [[ $BLD_CONFIG_GNU_LIBS_BOOTSTRAP_EXTRAS_ADD != "" ]]; then
				GREP_LINE_REMOVE+=" \| gnulib_tool_option_extras"
			fi
			grep -v "${GREP_LINE_REMOVE}" bootstrap.conf > tmp
			if [[ $BLD_CONFIG_GNU_LIBS_BOOTSTRAP_EXTRAS_ADD != "" ]]; then
				echo "gnulib_tool_option_extras=\" ${BLD_CONFIG_GNU_LIBS_BOOTSTRAP_EXTRAS_ADD}\"" >> tmp
			fi
			mv tmp bootstrap.conf
			if [[ -d "po" ]]; then
				echo "" > po/Makefile.in.in
			fi
		fi

		if [[ $BLD_CONFIG_CONFIG_NO_DOCS -eq 1 ]]; then
			grep -v "help2man" bootstrap.conf > tmp
			mv tmp bootstrap.conf
			FINAL_LINE=${FINAL_LINE//" doc "/" "}
		fi
		sed -E -i "s/${SUBDIR_REGEX}.+/$FINAL_LINE/" Makefile.am
	fi
		#echo "DBGRAN cat Makefile.am | grep $SUBDIR_REGEX ORIG LINE WAS: $ORIG_LINE NOW: $FINAL_LINE final sed cmd was: " sed -i "s/${SUBDIR_REGEX}.+/$FINAL_LINE/g" Makefile.am
	#done
	SKIP_STEP="";CUR_STEP="";
}
function gnulib_ensure_buildaux_scripts_copied(){
	FORCED=0
	if [[ $1 == "--forced" ]]; then
		FORCED=1
	fi
	if [[ -d "${BLD_CONFIG_SRC_FOLDER}/.git" ]]; then #make sure we are a valid checkout before doing this to avoid poluting an empty dir
		if [[ $BLD_CONFIG_GNU_LIBS_USED -eq 1 ]] || [[ $BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED -eq 1 ]]; then
			mkdir -p "$BLD_CONFIG_BUILD_AUX_FOLDER"
			declare -a SCRIPTS_TO_ADD=("${BLD_CONFIG_BUILD_AUX_SCRIPTS_DEFAULT[@]}" "${BLD_CONFIG_BUILD_AUX_SCRIPTS_ADDL[@]}")
			for flf in "${SCRIPTS_TO_ADD[@]}"; do
				local gnu_path=$(convert_to_universal_path "${BLD_CONFIG_BUILD_AUX_FOLDER}/${flf}")
				local SRC_PATH="${BLD_CONFIG_SRC_FOLDER}/gnulib/build-aux/${flf}"
				if [[ ! -e "${gnu_path}" || $FORCED -eq 1 ]]; then
					if [[ -e "${gnu_path}" ]]; then
						rm "${gnu_path}" #remove it as somehow msys cp will override the symlink target???
					fi
					if [[ -e "${SRC_PATH}" ]]; then #we have gnulib the build aux folder and ar-lib so hopefully its our patched version
						cp "${SRC_PATH}" "${gnu_path}"
					else #no gnulib local so lets fetch it from remote
						wget --quiet "https://raw.githubusercontent.com/mitchcapper/gnulib/ours_build_aux_handle_dot_a_libs/build-aux/${flf}" -O "${gnu_path}"
					fi
				fi
			done
		fi
	else
		echo "gnulib_ensure_buildaux_scripts_copied called but no git folder found on build root so skipping, likely an error" 1>&2
	fi
}
function gnulib_bootstrap(){
	declare -a BOOTSTRAP_CMD=("${BLD_CONFIG_GNU_LIBS_BOOTSTRAP_CMD_DEFAULT[@]}" "$@")
	SRC_DIR_ADD="${GNULIB_SRCDIR}"
	if [[ ! "${SRC_DIR_ADD}" || ("$SRC_DIR_ADD" && ! -d $SRC_DIR_ADD) ]]; then
		SRC_DIR_ADD="gnulib"
	fi
	if [[ -d $SRC_DIR_ADD ]]; then
		BOOTSTRAP_CMD+=("--gnulib-srcdir=${SRC_DIR_ADD}")
	fi
	if [[ $BLD_CONFIG_CONFIG_NO_PO -eq 1 ]]; then
		BOOTSTRAP_CMD+=("--skip-po")
	fi
	BOOTSTRAP_CMD+=("${BLD_CONFIG_GNU_LIBS_BOOTSTRAP_CMD_ADDL[@]}")
	PRE_RUN_LIBTOOL_M4_EXIST=0
	if [[ -e "m4/libtool.m4" ]]; then
		PRE_RUN_LIBTOOL_M4_EXIST=1
	fi
	if [[ ! -e "README-hacking" ]]; then
		touch README-hacking
	fi
	ex ./bootstrap "${BOOTSTRAP_CMD[@]}"

	if [[ -e "m4/libtool.m4" && $PRE_RUN_LIBTOOL_M4_EXIST -eq 0 ]]; then # so we have patched the m4 macro for libtool but it didn't exist before autoreconf was run by bootstrap so we need to run it again to get the changes to be taken up
		autoreconf --symlink
	fi
}
function gnulib_add_addl_modules_and_bootstrap(){
	CUR_STEP="bootstrap"
	gnulib_add_addl_modules_to_bootstrap;
	gnulib_bootstrap;
	SKIP_STEP="";CUR_STEP="";
}
function gnulib_add_addl_modules_to_bootstrap(){
	cd $BLD_CONFIG_SRC_FOLDER
	declare -a LIB_ADD=("${BLD_CONFIG_GNU_LIBS_DEFAULT[@]}")
	for i in "${BLD_CONFIG_GNU_LIBS_EXCLUDE[@]}"; do
         LIB_ADD=(${LIB_ADD[@]//*$i*})
	done
	LIB_ADD=("${LIB_ADD[@]} ${BLD_CONFIG_GNU_LIBS_ADDL[@]}")

	CUR_MODULES=""
	BOOT_FILE=""
	INDENT=""
	if [[ -f "gnulib.modules" ]]; then #ie tar style
		CUR_MODULES=`cat gnulib.modules | grep "^[A-Za-z0-9]" | sed 's/^ *//;s/ *$//'`;
		BOOT_FILE=`cat gnulib.modules | grep -v "^[A-Za-z0-9]"`;
	else
		#use \K to get exactly what we want here sed doesn't do \K so will just capture the group and sub that as grep doesnt do that
		
		CUR_MODULES=`grep -Pzo "\n[ \t]*gnulib_modules\s*=\s*[\"'\x5c]+\K[^\"'\x5c]+" bootstrap.conf  | sed 's/^ *//;s/ *$//' | tr -d '\0'`

		BOOT_FILE=`sed -z -E "s#(\n[ \t]*gnulib_modules\s*=\s*['\"]+)[\n\x5c]*[^\"'\x5c]+#\1\nTOREPLACEZSTR\n#" bootstrap.conf  | sed ''`
		INDENT="    "
	fi
	CUR_MODULES=$"${CUR_MODULES}"$'\n'`printf '%s\n' "${LIB_ADD[@]}"`
	CUR_MODULES=`echo "$CUR_MODULES" | sort -u | sed "s#^#${INDENT}#"`

	if [[ -f "gnulib.modules" ]]; then
		BOOT_FILE="$BOOT_FILE"$'\n'"$CUR_MODULES"
		echo "${BOOT_FILE}" > gnulib.modules
	else
		echo "${BOOT_FILE/TOREPLACEZSTR/"$CUR_MODULES"$'\n'}" > bootstrap.conf
	fi
}
		
function libtool_fixes(){
	# even when symlink is used for autotools the m4 macro and the build-aux/ltmain.sh are still copied so fine to edit directly
	# first the newer libtools have more windows support but that makes things actually a bit harder as it has some issues
	# first it puts the export symbol commands in a .exp file but that is used by the compiler too so .expsym is better and used elsewhere
	# Secondly it does -Fe [arg] but it needs to be next to the -Fe[arg]
	# ie libtool_fixes
	# note you must run autoreconf after this if it wont automatically happen.  Sometimes these will not be present until after the first bootstrap though so likely want to run autoreconf ourselves. If using our libtool wrapper it should auto call this.

	for fl in "${BLD_CONFIG_GNU_LIBS_LIBTOOL_FIXES[@]}"; do
		if [[ -e "$fl" ]]; then
			sed -i -E "s/(\\.exp)/\1sym/g;s/expsymsym/expsym/g;s/-Fe /-Fe/g" "${fl}"
			sed -i -E "s/func_convert_core_msys_to_w32 \(/func_convert_core_msys_to_w32  (){ func_convert_core_msys_to_w32_result=\$1; }\\nfunc_convert_core_msys_to_w32_old (/" "${fl}"
			#sed -i -E "s#(gnulib_tool=.+gnulib-tool)\$#\1.py#" bootstrap
		fi
	done
}
function autoreconf_post_run(){
	cd $BLD_CONFIG_SRC_FOLDER
	gnulib_ensure_buildaux_scripts_copied --forced
	libtool_fixes #note if the autoconf hasn't run yet we will likely not have the macro file so even though this will edit the macro file we will likely need to rerun autoreconf again to apply the macro to the output
}
function autoreconf_pre_run(){
	cd $BLD_CONFIG_SRC_FOLDER
	libtool_fixes #note if the 
}
function gnulib_init(){ #called by startcommon
	if [[ -d $BLD_CONFIG_GNU_LIB_SOURCE_DIR ]]; then
		export GNULIB_SRCDIR="${BLD_CONFIG_GNU_LIB_SOURCE_DIR}"
	fi
	if [[ $BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY -eq 1 ]]; then
		export GNULIB_TOOL_IMPL="py"
	else
		export GNULIB_TOOL_IMPL="sh"
	fi

}
function setup_gnulibtool_py_autoconfwrapper(){
	if [[ $BLD_CONFIG_GNU_LIBS_AUTORECONF_WRAPPER -eq 1 ]]; then
		local TARGET_FL="${BLD_CONFIG_BUILD_AUX_FOLDER}/AUTORECONF_prewrapper.sh"
		#For things like coreutils bootstrap will create the mk files we need to fix before it also then runs autoreconf so we will just use our wrapper for autoreconf, call ourselves, then call autoreconf
		if [[ -e "${BLD_CONFIG_SRC_FOLDER}/.git" ]]; then
			if [[ ! -e "$TARGET_FL" ]]; then
				WRAPPER=`cat "${SCRIPT_FOLDER}/AUTORECONF_prewrapper.sh.template"`
				WRAPPER="${WRAPPER//SCRIPT_PATH/"$CALL_SCRIPT_PATH"}"
				mkdir -p "$BLD_CONFIG_BUILD_AUX_FOLDER"
				echo "${WRAPPER}" > "$TARGET_FL"
			fi
			gnulib_ensure_buildaux_scripts_copied; #make sure the helpers also get there
		fi
		export AUTORECONF="$TARGET_FL"
		#gnulib_tool_py_remove_nmd_makefiles;
	fi
	#gnulib_ensure_buildaux_scripts_copied; #this has nothing to do wit autoconf but for some reason can get more failures with debug otherwise.
}
function gnulib_apply_patch(){
	local patch=$1
	local options=$2 #only valid option is skip_fixes right now

	git_apply_patch "$WIN_SCRIPT_FOLDER/patches/patches_GNULIB_${patch}.patch"

}
function gnulib_patches(){
	declare -a PATCHES=("${BLD_CONFIG_GNU_LIBS_PATCHES_DEFAULT[@]}" "${BLD_CONFIG_GNU_LIBS_PATCHES_ADDL[@]}")
	for patch in "${PATCHES[@]}"; do
		gnulib_apply_patch "$patch"
	done
}