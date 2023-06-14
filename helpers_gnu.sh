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
function gnulib_switch_to_master_and_patch(){
	cd $BLD_CONFIG_SRC_FOLDER
	if [[ $BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY -eq 1 ]]; then
		sed -i -E "s#(gnulib_tool=.+gnulib-tool)\$#\1.py#" bootstrap
	else
		sed -i -E "s#(gnulib_tool=.+gnulib-tool).py\$#\1#" bootstrap
	fi
	cd $BLD_CONFIG_SRC_FOLDER/gnulib
	git fetch
	if [[ ! -z "$BLD_CONFIG_GNU_LIBS_BRANCH" ]]; then
		git checkout "$BLD_CONFIG_GNU_LIBS_BRANCH"
	fi
	echo ++++++ Running on GNULIB commit `git rev-parse --abbrev-ref HEAD` `git rev-parse HEAD`
	git checkout .
	gnulib_patches;
	#"gnulib"
#	declare -a dirs=(".")
#	for do_dir in "${dirs[@]}"
#	do
#	:
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
			if [[ $BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY -eq 1 ]]; then
				sed -E -i 's#--automake-subdir##g' bootstrap.conf
			fi
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
			grep -v "texi2pdf" bootstrap.conf > tmp
			mv tmp bootstrap.conf
			if [[ -d "po" ]]; then
				echo "" > po/Makefile.in.in
			fi
		fi

		if [[ $BLD_CONFIG_CONFIG_NO_DOCS -eq 1 ]]; then
			FINAL_LINE=${FINAL_LINE//" doc "/" "}
		fi
		sed -E -i "s/${SUBDIR_REGEX}.+/$FINAL_LINE/" Makefile.am
	fi
		#echo "DBGRAN cat Makefile.am | grep $SUBDIR_REGEX ORIG LINE WAS: $ORIG_LINE NOW: $FINAL_LINE final sed cmd was: " sed -i "s/${SUBDIR_REGEX}.+/$FINAL_LINE/g" Makefile.am
	#done
}
function gnulib_ensure_buildaux_scripts_copied(){
	if [[ $BLD_CONFIG_GNU_LIBS_USED -eq 1 ]] || [[ $BLD_CONFIG_GNU_LIBS_BUILD_AUX_ONLY_USED -eq 1 ]]; then
		mkdir -p "$BLD_CONFIG_BUILD_AUX_FOLDER"
		declare -a SCRIPTS_TO_ADD=("${BLD_CONFIG_BUILD_AUX_SCRIPTS_DEFAULT[@]}" "${BLD_CONFIG_BUILD_AUX_SCRIPTS_ADDL[@]}")
		for flf in "${SCRIPTS_TO_ADD[@]}"; do
			local gnu_path=$(convert_to_universal_path "${BLD_CONFIG_BUILD_AUX_FOLDER}/${flf}")
			local SRC_PATH="${BLD_CONFIG_SRC_FOLDER}/gnulib/build-aux/${flf}"

			if [[ -f "${SRC_PATH}" ]]; then #we have gnulib the build aux folder and ar-lib so hopefully its our patched version
				if [[ ! -f "${gnu_path}" ]]; then
					cp "${SRC_PATH}" "${gnu_path}"
				fi
			else #no gnulib local so lets fetch it from remote
				if [[ ! -f "${SRC_PATH}" ]]; then
					wget --quiet "https://raw.githubusercontent.com/mitchcapper/gnulib/ours_build_aux_handle_dot_a_libs/build-aux/${flf}" -O "${gnu_path}"
				fi
			fi
		done
	fi
}
function gnulib_add_addl_modules_to_bootstrap(){
	cd $BLD_CONFIG_SRC_FOLDER
	declare -a LIB_ADD=("${BLD_CONFIG_GNU_LIBS_DEFAULT[@]}" "${BLD_CONFIG_GNU_LIBS_ADDL[@]}")
	CUR_MODULES=""
	BOOT_FILE=""
	INDENT=""
	if [[ -f "gnulib.modules" ]]; then #ie tar style
		CUR_MODULES=`cat gnulib.modules | grep "^[A-Za-z0-9]" | sed 's/^ *//;s/ *$//'`;
		BOOT_FILE=`cat gnulib.modules | grep -v "^[A-Za-z0-9]"`;
	else
		#use \K to get exactly what we want here sed doesn't do \K so will just capture the group and sub that as grep doesnt do that
		CUR_MODULES=`grep -Pzo "\n[ \t]*gnulib_modules\s*=\s*[\"'\x5c]+\K[^\"'\x5c]+" bootstrap.conf | sed 's/^ *//;s/ *$//'`
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
function setup_gnulibtool_py_autoconfwrapper(){
	if [[ $BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY -eq 1 ]]; then

		#For things like coreutils bootstrap will create the mk files we need to fix before it also then runs autoreconf so we will just use our wrapper for autoreconf, call ourselves, then call autoreconf
		WRAPPER=`cat "${SCRIPT_FOLDER}/AUTORECONF_prewrapper.sh.template"`
		WRAPPER="${WRAPPER/SCRIPT_PATH/"$CALL_SCRIPT_PATH"}"
		mkdir -p "$BLD_CONFIG_BUILD_AUX_FOLDER"
		echo "${WRAPPER}" > "${BLD_CONFIG_BUILD_AUX_FOLDER}/AUTORECONF_prewrapper.sh"
		export AUTORECONF="${BLD_CONFIG_BUILD_AUX_FOLDER}/AUTORECONF_prewrapper.sh"

		gnulib_tool_py_remove_nmd_makefiles;
	fi
	gnulib_ensure_buildaux_scripts_copied; #this has nothing to do wit autoconf but for some readon can get more failures with debug otherwise.
}
function gnulib_tool_py_remove_nmd_makefiles() {
	#this taken from the normal gnulib_tool process, not sure lib/ will exist yet

	#sed_eliminate_NMD='s/@NMD@//;/@!NMD@/d' #this is what is needed for automake subdirs but as that doesn't work with gnulib-tool..py right now no need to worry about it
	sed_eliminate_NMD='/@NMD@/d;s/@!NMD@//'
	local FILES=`find . -maxdepth 3 -name Makefile.am`
	if [[ "${FILES}" != "" ]]; then
		mapfile -t TO_FIX <<<$FILES
		TO_FIX=("${TO_FIX[@]}" "${BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY_ADDL_MK_FILES_FIX[@]}")
		for fl in "${TO_FIX[@]}"; do
			if [[ -f "${fl}" ]]; then
				sed -i -e "$sed_eliminate_NMD" "${fl}"
			fi
		done
	fi
	#sed -i -E '/@NMD@/d;s/@!NMD@//' lib/Makefile.am Makefile.am
	#sed -i -E "s#(gnulib_tool=.+gnulib-tool)\$#\1.py#" bootstrap
}
function gnulib_apply_patch(){
	local patch=$1
	local options=$2 #only valid option is skip_fixes right now

	git apply --ignore-space-change --ignore-whitespace --verbose ${EXTRA} "$WIN_SCRIPT_FOLDER/patches/patches_GNULIB_${patch}.patch"

}
function gnulib_patches(){
	declare -a PATCHES=("${BLD_CONFIG_GNU_LIBS_PATCHES_DEFAULT[@]}" "${BLD_CONFIG_GNU_LIBS_PATCHES_ADDL[@]}")
	for patch in "${PATCHES[@]}"; do
		gnulib_apply_patch "$patch"
	done
}