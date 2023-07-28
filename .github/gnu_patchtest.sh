#!/bin/bash
PATCH_NAME="$2"

. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

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
	TEST_WHAT="$SKIP_STEP"
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

