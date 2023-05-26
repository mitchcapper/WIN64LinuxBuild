#!/bin/bash
OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1" # should be branch or patch or all_patch
PATCH_NAME="$2"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"

PreInitialize;

BLD_CONFIG_BUILD_NAME="gnulib";
BLD_CONFIG_LOG_FILE_AUTOTAIL=0;
function ourmain() {
	startcommon;
	set -e
	git config --global user.email "you@example.com"
  	git config --global user.name "Your Name"
	git clone --quiet https://github.com/mitchcapper/gnulib .
	git remote add upstream https://github.com/coreutils/gnulib.git
	git fetch upstream --quiet
	git checkout master --quiet
	git branch master -u upstream/master
	git pull
	TEST_WHAT="$CALL_CMD"
	BRANCH_NAME="ours_${PATCH_NAME,,}"

	if [[ "$TEST_WHAT" == "patch" ]]; then
		echo "Running patch test"
		gnulib_apply_patch "$PATCH_NAME" "skip_fixes"
	elif [[ "$TEST_WHAT" == "branch" ]]; then
		echo "Running branch test"
		git checkout "$BRANCH_NAME"
		git merge master -m done

		exit_out $? "Merge Done"
	else
		echo "Running all patches test"
		gnulib_patches;
	fi
	finalcommon;
}
ourmain;

