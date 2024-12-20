#!/bin/bash
PATCH_NAME="$2"

. "${WLB_SCRIPT_FOLDER:-$(dirname "$(readlink -f "$BASH_SOURCE")")}/helpers.sh"

BLD_CONFIG_BUILD_NAME="gnulib";
BLD_CONFIG_GNU_LIBS_USED=1;
BLD_CONFIG_LOG_FILE_AUTOTAIL=0;
function ourmain() {
	startcommon;
	set -e
	git config --global user.email "you@example.com"
  	git config --global user.name "Your Name"
	git_clone --no-checkout --no-recurse-submodules --quiet --use-ref-src https://github.com/coreutils/gnulib.git .
	git remote add ours https://github.com/mitchcapper/gnulib 
	git fetch --quiet --all
	git checkout ours/master --quiet
	git branch -D master
	git checkout -b master ours/master # should do ours/master anyway as its what we are on
	git branch master -u origin/master
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

