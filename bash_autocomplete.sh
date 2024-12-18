#!/bin/bash
set -eo pipefail -o functrace
shopt -s inherit_errexit
for entry in "${WLB_SCRIPT_FOLDER}/build"/f_*; do
	BASE_NAME=$(basename "$entry")
  if [[ $BASE_NAME != "f_TEMPLATE_build.sh" ]]; then
	AUTO_COMP=`${entry} autocomplete`
	complete -W "$AUTO_COMP" "$BASE_NAME"
	#complete -W "$AUTO_COMP" "$entry"
  fi
done