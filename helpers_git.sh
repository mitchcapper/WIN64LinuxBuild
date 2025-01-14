function git_stash_number_from_name(){
	local stash_name_startswith=$1
	if [[ -z "$stash_name_startswith" ]]; then
		echo "git_stash_number_from_name: name arg is empty " 1>&2;
		exit 1
	fi
	# cant look for }: to better anchor as sometimes line is like stash@{0}: On master: WLB_TMP_STASH so have to just do :
	STASH_ID=`git stash list | grep --color=never -P "(?<=:\s)${stash_name_startswith}" | grep --color=never -o -P "(?<={)[0-9]+(?=})"`
	if [[ -z "$STASH_ID" ]]; then
		echo "Unable to find stash with a name starting with regex ${stash_name_startswith}" 1>&2;
		exit 1
	fi
	echo $STASH_ID
}
function git_fully_qualify_stash_id(){
	local stash_name_startswith_or_number=$1
	if [[ $stash_name_startswith_or_number =~ ^[0-9]+$ ]]; then
		STASH_ID="$stash_name_startswith_or_number"
	else
		STASH_ID=$(git_stash_number_from_name "${stash_name_startswith_or_number}")
	fi
	stash="stash@{${STASH_ID}}"
	echo "$stash"
}
function git_stash_rename(){
	local stash_name_startswith_or_number=$1
	local stash_new_name=$2
	if [ -z "$stash_name_startswith_or_number" ] || [ -z "$stash_new_name" ]; then
		echo "git_stash_rename: Either old name or new name not passed to call" 1>&2;
		exit 1
	fi
	stash=$(git_fully_qualify_stash_id "${stash_name_startswith_or_number}")
    rev=$(git rev-parse "${stash}")
    git stash drop "${stash}" || exit 1
    git stash store -m "${stash_new_name}" "$rev" || exit 1
    git stash list
}
function git_stash_to_file(){
	local stash_name_startswith_or_number=$1
	local output_filename=$2
	stash=$(git_fully_qualify_stash_id "${stash_name_startswith_or_number}")
	git stash show --include-untracked -p --color=never "--output=$output_filename" "$stash"
}
function git_dump_effective_settings(){
	git config --list --name-only | sort -u | xargs -I{} bash -c "echo -n '{}'= && git config --get '{}'"
}
function git_stash_cur_work_discard_staged_work(){
	if [[ "$BLD_CONFIG_GIT_STASH_STAGE_DEBUG" -eq "1" ]]; then
		git_dump_effective_settings;
	fi
	if [[ $BLD_CONFIG_GIT_STASH_STAGE_AROUND_PATCHES -ne "1" ]]; then
		return
	fi
	# first check if we have a previous stash that didnt get un stashed, if so unstash it
	# Next store any staged changes(should be only items in our patch) to a backup patch file, stash them and then drop them if anyhting was stashed (delete the staged without changing the unstaged)
	git_stash_stage_dbg "will check for existing cur work stash and apply if needed"
	STASH_NAME=`git stash list | grep -o "WLB_TMP_STASH" || true`
	if [[ "$STASH_NAME" != "" ]]; then #we already have stashed work likely failed 
		echo -e "${COLOR_ERROR}Warning found existing temporary stash of work going to unstash it first before restashing cur work${COLOR_NONE}" 1>&2
		#we can't use pop to do by name, but then we can't do the same for drop
		#git stash apply stash^{/$STASH_NAME}
		stash_id=$(git_fully_qualify_stash_id "$STASH_NAME")
		ex git stash pop $stash_id > /dev/null
		echo "####################### just popped the existing one back off"
		git stash list
	fi
	APPEND="$(basename -s .git `git config --get remote.origin.url`)_WLBDISCARD.patch"
	ORIG_STASH_CNT=`git stash list | wc -l`
	TMPFILE=`mktemp --suffix=$APPEND`
	TMPFILE=$(convert_to_universal_path "$TMPFILE")
	git_stash_stage_dbg "Staging our old patch changes we don't care about, these should all be staged"
	ex git stash --staged -m "WLB_STAGEDDROP" || true
	CUR_STASH_CNT=`git stash list | wc -l`
	if [[ "$CUR_STASH_CNT" != "$ORIG_STASH_CNT" ]]; then #if we stashed it
		git_stash_to_file "WLB_STAGEDDROP" "$TMPFILE"
		ex git stash drop
	fi
	STASH_NAME="WLB_TMP_STASH"
	ex git stash --include-untracked -m "${STASH_NAME}" #save anything they may have changed
	git_stash_stage_dbg "Everything should be stashed we should be clean here Stash name for local changes set to (if not empty we did stash): ${STASH_NAME}"
	CUR_STASH_CNT=`git stash list | wc -l`
	if [[ "$CUR_STASH_CNT" == "$ORIG_STASH_CNT" ]]; then #if we didn't stash anything
		STASH_NAME=""
	fi	

	LOCAL_WORK_TMP_FILE=""
	if [[ "$STASH_NAME" != "" ]]; then
		LOCAL_WORK_TMP_FILE=`mktemp --suffix=$APPEND`
		LOCAL_WORK_TMP_FILE=$(convert_to_universal_path "$LOCAL_WORK_TMP_FILE")
		git_stash_to_file "WLB_TMP_STASH" "$LOCAL_WORK_TMP_FILE"
		LOCAL_WORK_TMP_FILE="To backup local work saved to '${LOCAL_WORK_TMP_FILE}' and "
	fi
	echo "${LOCAL_WORK_TMP_FILE}The staged items we don't care about to '${TMPFILE}'"
	#ex git checkout . # should no longer need all items were stashed
}
function git_stash_stage_dbg(){
	if [[ "$BLD_CONFIG_GIT_STASH_STAGE_DEBUG" -ne "1" ]]; then
		return;
	fi
	local msg=$1
	echo -e "${COLOR_MINOR}#### STASHSTAGE DBG ${msg}" 2>&1
	git stash list
	echo -e "${COLOR_NONE}"
	git status
	echo -e "${COLOR_MINOR}"
	echo -e "#### STASHSTAGE DBG output done${COLOR_NONE}"
}
function git_stash_stage_patches_and_restore_cur_work(){
	if [[ $BLD_CONFIG_GIT_STASH_STAGE_AROUND_PATCHES -ne "1" ]]; then
		return
	fi
	git_stash_stage_dbg "Only our patch changes should exist right now (unstaged) will go stage them Stash name set to (if not empty we did stash): ${STASH_NAME}"
	git add . #don't need -u as all untracked items from prior shoudl have been stashed
	git_stash_stage_dbg "Going to restore our local changes nothing should be untracked yet only the staged patch changes"
	if [[ "$STASH_NAME" != "" ]]; then
		stash_id=$(git_fully_qualify_stash_id "$STASH_NAME")
		git stash pop $stash_id > /dev/null
		STASH_NAME=""
	fi
	git_stash_stage_dbg "Done nothing should be stashed and all non local changes should be staged"
}
function git_apply_patch () {
	local PATCH=$1
	ex git apply "${BLD_CONFIG_GIT_PATCH_APPLY_DEFAULT_ARGS[@]}" "$PATCH"
}

function git_clone(){
	CUR_STEP="checkout"
	ADD_BUNDLE=""
	local ARGS_ARR=("$@")
	local LEN=${#ARGS_ARR[@]}
	local USE_REF_SRC_DIR=0
	local ADD_RECURSE=1
	local GNULIB_DIR_NAME="gnulib" #name for gnulib under repos
	local USE_REF_SRC_DIR_ON_INITIAL_CLONE=0 #only done when cloning gnulib itself
	local DO_RECURSIVE_SUBMODULE_INIT=0 #we set this to true when we would normally do a recursive clone but as we are using a reference src repo we can't so after we finish we do initilize and update all modules recursively
	local ONLY_DO_STEP="" # can be set to initial to just do the initial clone, or skip_initial to skip the initial clone.  Can be useful for things that need the gnulib help but need to make modifications after the first clone.
	if [[ "$BLD_CONFIG_GIT_NO_RECURSE" -eq 1 ]]; then
		ADD_RECURSE=0
	fi
	

# bundle support removed didnt work properly with recursive clones
#	if [[ "$BLD_CONFIG_BUNDLE_PATH" != "" && -e "$BLD_CONFIG_BUNDLE_PATH" ]]; then
#		ADD_BUNDLE="--bundle-uri=${BLD_CONFIG_BUNDLE_PATH}"
#	fi
	local GIT_URL=""
	local GIT_DIR=""
	local FINAL_ARR=()
	
	for (( INDEX=0; INDEX<$LEN; INDEX++ )); do
		local VAL="${ARGS_ARR[$INDEX]}"
		case $VAL in
			"--no-recurse-submodules")
				ADD_RECURSE=0
				BLD_CONFIG_GNU_LIB_REFERENCE_SOURCE_DIR="" #prevent us trying to still do so
			;;
			"--no-bundle-uri")
				ADD_BUNDLE=""
			;;
			"--use-ref-src")
				USE_REF_SRC_DIR_ON_INITIAL_CLONE=1
			;;
			"--only-initial-clone")
				ONLY_DO_STEP="initial"
			;;
			"--skip-initial-clone")
				ONLY_DO_STEP="skip_initial"
			;;
			[hH][tT][tT][pP]*://*)
				GIT_URL="$VAL"
			;;
			-*)
				FINAL_ARR+=($VAL)
			;;
			?*)
				if [[ "$GIT_DIR" != "" ]]; then
					echo "Not able to handle that git clone arg for some reason? Think it ( ${VAL} ) is dir when dir is already set to:  ${GIT_DIR}"
					exit 1
				fi
				GIT_DIR="$VAL"
			;;
		esac
	done
	if [[ "$BLD_CONFIG_GNU_LIBS_USED" -eq 1 ]]; then
		if [[ -d "${BLD_CONFIG_GNU_LIB_REFERENCE_SOURCE_DIR}/refs" || -d "${BLD_CONFIG_GNU_LIB_REFERENCE_SOURCE_DIR}/.git" ]]; then
			if [[ "$ADD_RECURSE" -eq 1 ]]; then
				DO_RECURSIVE_SUBMODULE_INIT=1
			fi
			ADD_RECURSE=0
			USE_REF_SRC_DIR=1
		fi
	fi
	if [[ "$ADD_RECURSE" -eq 1 ]]; then
		FINAL_ARR+=("--recurse-submodules")
	fi
	if [[ "$ADD_BUNDLE" != "" ]]; then
		FINAL_ARR+=($ADD_BUNDLE)
	fi
	FINAL_ARR+=($GIT_URL)
	if [[ "$GIT_DIR" != "" ]]; then
		FINAL_ARR+=($GIT_DIR)
	fi
	declare -a GIT_REF_ARGS=()
	if [[ "$USE_REF_SRC_DIR" -eq 1 ]]; then
		GIT_REF_ARGS=( "--dissociate" "--reference" "${BLD_CONFIG_GNU_LIB_REFERENCE_SOURCE_DIR}" )
		if [[ "$USE_REF_SRC_DIR_ON_INITIAL_CLONE" -eq 1 ]]; then
			FINAL_ARR+=("${GIT_REF_ARGS[@]}")
		fi
	fi
	if [[ "$ONLY_DO_STEP" != "skip_initial" ]]; then
	ex git clone "${FINAL_ARR[@]}"
	fi
	if [[ "$BLD_CONFIG_GIT_PRINT_LAST_COMMIT_ON_CLONE" -eq 1 ]]; then
		git log --decorate=full -n 1
	fi
	if [[ "$ONLY_DO_STEP" == "initial" ]]; then
		SKIP_STEP="";CUR_STEP="";
		return
	fi
	if [[ "$USE_REF_SRC_DIR" -eq 1 && -d "${GNULIB_DIR_NAME}" ]]; then
		if [[ "$BLD_CONFIG_GNU_LIB_REFERENCE_MASTER_SHORTCUT" -eq 1 && "$BLD_CONFIG_GNU_LIBS_BRANCH" != "" ]]; then
			ex git rm "${GNULIB_DIR_NAME}"
			gnulib_add_submodule_to_proj
		else
			ex git submodule update --init "${GIT_REF_ARGS[@]}" "${GNULIB_DIR_NAME}"
		fi
	fi
	if [[ "$ADD_RECURSE" -eq "0" ]]; then
		for sub in "${BLD_CONFIG_GIT_SUBMODULE_INITS[@]}"; do
			ex git submodule init "${sub}"
			ex git submodule update "${sub}"
		done
	fi
	if [[ "$DO_RECURSIVE_SUBMODULE_INIT" -eq 1 ]]; then
		ex git submodule update --init --recursive #make sure any other sub modules are inited if we would have done a recursive clone
	fi
	if [[ "$BLD_CONFIG_GNU_LIBS_ADD_TO_REPO" -eq 1 ]]; then
		gnulib_add_submodule_to_proj
	fi
	SKIP_STEP="";CUR_STEP="";
}
# will stage the following files if staging around patches is enabled
function git_staging_add(){
	if [[ "$BLD_CONFIG_GIT_STASH_STAGE_AROUND_PATCHES" -eq 1 ]]; then
		ex git add "$@"
	fi
}
function git_clone_and_add_ignore(){
	git_clone "$@"
	add_items_to_gitignore
}
function add_items_to_gitignore(){
	cd $BLD_CONFIG_SRC_FOLDER
	if ! grep -Fq "${BLD_CONFIG_GIT_IGNORE_DONE_TEST_STR}" ".gitignore"; then
		declare -a TO_ADD=("${BLD_CONFIG_GIT_IGNORE_DEFAULT[@]}" "${BLD_CONFIG_GIT_IGNORE_ADDL[@]}")
		printf '%s\n' "${TO_ADD[@]}" >> .gitignore
		awk -i inplace ' !x[$0]++' .gitignore #remove spaces
		git_staging_add .gitignore
	fi

}
# will commit up staged items if  stage around patches enabled, only used by gawk right now
function git_staging_commit(){
	if [[ "$BLD_CONFIG_GIT_STASH_STAGE_AROUND_PATCHES" -eq 1 ]]; then
		ex git commit -m "FIXME faux required commit of pre-repo build prep"
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
		if [[ "$NAME" == "" ]]; then
			continue;
		fi

		export GIT_CONFIG_KEY_${GIT_CONFIG_COUNT}="$NAME"
		export GIT_CONFIG_VALUE_${GIT_CONFIG_COUNT}="$VALUE"
		(( ++GIT_CONFIG_COUNT ))
	done
	export GIT_CONFIG_COUNT
}