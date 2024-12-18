#!/bin/bash
#set -e
#shopt -s inherit_errexit
START_AT="$1"
SKIP_TO=""
if [[ "$START_AT" == *_build.sh ]]; then
  SKIP_TO="$START_AT"
  shift;
fi
declare -a MAKE_ARGS=( "$@" )
pushd $WLB_SCRIPT_FOLDER/build
COLOR_MAJOR="${COLOR_MAJOR:-\e[1;32m}"
COLOR_NONE="${COLOR_NONE:-\e[0m}"
declare -a FAILED_ITEMS=()
EXIT_CODE=0
declare -i cntr=0
declare -a build_scripts=( f_*.sh )
for file in "${build_scripts[@]}"; do
  cntr+=1
  if [[ "$SKIP_TO" != "" ]]; then
    if [[ "$file" == "$SKIP_TO" ]]; then
      SKIP_TO=""
    else
      continue;
    fi
  fi
  echo "Starting deps build for ${file}"
  ./${file} dep_build
  
  res=$?
  if [[ $res -ne 0 ]]; then
	FAILED_ITEMS+=("Deps of ${file}")
  EXIT_CODE=2
	continue;
  fi
  echo -e "##### Starting build ${COLOR_MAJOR}(${cntr} / ${#build_scripts[@]}) for ${file}${COLOR_NONE} #####"
  ./${file} "${MAKE_ARGS[@]}"
  res=$?
  if [[ $res -ne 0 ]]; then
	FAILED_ITEMS+=("${file}")
  EXIT_CODE=1
	continue;
  fi
  echo -e "##### Successfully built ${COLOR_MAJOR}${file}${COLOR_NONE} #####"
done
echo -e "\n\nFailed Build Items ${#FAILED_ITEMS[@]}:\n"

printf '\t%s\n' "${FAILED_ITEMS[@]}"
popd
exit $EXIT_CODE