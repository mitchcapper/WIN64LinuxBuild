# https://gist.github.com/splaspood/1473761 ++
#declare -A BLD_CONFIG
declare -a TEMPLATE_SUB_ORDER
declare -A OPTION_TYPES
ini_read(){
	LINE_NUM=1
	SET_SHOPT=1
	shopt -p extglob  &>/dev/null || SET_SHOPT=0
	if [[ $SET_SHOPT -eq 1 ]]; then
		shopt -s extglob
	fi
	INI_FILE="$SCRIPT_FOLDER/default_config.ini"
	#INI_FILE="$SCRIPT_FOLDER/test.in"
	#trap 'echo "# $BASH_COMMAND"' DEBUG
	#set -x
	#set -o xtrace


	while read -r line || [ -n "$line" ]
		do

		((LINE_NUM++))


#		regex_strip_to_first_match "(('[^']*'|[^'#;])*)([;#])"
#		regex_strip_to_first_match "((\"[^\"]*\"|[^\"#;])*)([;#])"
		#regex_strip_to_first_match "^[\t ]*(.+)"
		#regex_strip_to_first_match "(.+)[\t ]*$"
		#regex_strip_to_first_match "^([^'\"]*)[#;].*"
		line="${line#"${line%%[![:space:]]*}"}"
		line="${line%"${line##*[![:space:]]}"}"


		if [[ "$line" =~ ^[[:space:]]*([a-zA-Z0-9._]{1,})[[:space:]]*=[[:space:]]*(.+)[[:space:]]*$ ]]; then
			VAR_NAME="${BASH_REMATCH[1]}"
			line="${BASH_REMATCH[2]}"



			local IN_QUOTE_CHAR=""
			local IN_ESCAPE=0
			local CHAR=""
			VAR_VALUE=""
			local IS_ARRAY=0
			if [[ "${line:0:1}" == "("  ]]; then
				IS_ARRAY=1
			fi

			local ALLOW_QUOTE_STR_START=1
			for (( i=0; i<${#line}; i++ )); do
				CHAR="${line:$i:1}"
				#echo ON CHAR $CHAR IN_QUOTE_CHAR: $IN_QUOTE_CHAR IN_ESCAPE: $IN_ESCAPE IS_ARRAY: $IS_ARRAY ALLOW_QUOTE_STR_START: $ALLOW_QUOTE_STR_START
				if [[ $IN_ESCAPE -eq 0 ]]; then

					if [[ "$CHAR" == "\\" ]]; then
						IN_ESCAPE=1
					else
						if [[ -z "$IN_QUOTE_CHAR" ]]; then #not in a quoted string
							if [[ $ALLOW_QUOTE_STR_START -eq 1 ]]; then
								if [[ "$CHAR" == "'" || "$CHAR" == "\"" ]]; then
									IN_QUOTE_CHAR="$CHAR"
									[[ $IS_ARRAY -eq 1 ]] || ALLOW_QUOTE_STR_START=0
								elif [[ "$CHAR" != "(" && "$CHAR" != " " ]]; then  #allow array chars or spaces at start only
									ALLOW_QUOTE_STR_START=0
								fi

							fi
							if [[ "$CHAR" == ";" || "$CHAR" == "#" ]]; then
								break
							fi

						else #in a quoted string
							if [[ "$CHAR" == "$IN_QUOTE_CHAR" ]]; then
								IN_QUOTE_CHAR=""
							fi
						fi
					fi
				else #in an escape sequence
					IN_ESCAPE=0
				fi
				VAR_VALUE="$VAR_VALUE$CHAR"
			done

		else
			regex_strip_to_first_match "^[[:space:]]*[#;].*"
			[ -z "$line" ] || echo "BAD LINE ${LINE_NUM-1}: $line"
			continue
		fi

		line="$VAR_VALUE"
		line="${line#"${line%%[![:space:]]*}"}"
		line="${line%"${line##*[![:space:]]}"}"
		VAR_VALUE="$line"
		if [[ "$VAR_VALUE" == "env" && "$VAR_NAME" =~ ^ENV_.+ ]]; then
			VAR_NAME_NO_ENV="${VAR_NAME:4}"
			VAR_VALUE="${!VAR_NAME_NO_ENV}"
		fi
		if [[ "${VAR_VALUE:0:1}" == "\"" && "${VAR_VALUE:(-1):1}" == "\"" ]]; then
			VAR_VALUE="${VAR_VALUE%\"}"
			VAR_VALUE="${VAR_VALUE#\"}"
		fi
		if [[ "${VAR_VALUE:0:1}" == "\'" && "${VAR_VALUE:(-1):1}" == "\'" ]]; then
			VAR_VALUE="${VAR_VALUE%\'}"
			VAR_VALUE="${VAR_VALUE#\'}"
		fi


		if [[ $IS_ARRAY -eq 1 ]]; then
			OPTION_TYPES["$VAR_NAME"]=1
		else
			OPTION_TYPES["$VAR_NAME"]=0
		fi

		declare -n var="BLD_CONFIG_$VAR_NAME"
		if [[ -z "$var" ]]; then
			var="$VAR_VALUE"
		fi
		TEMPLATE_SUB_ORDER+=("$VAR_NAME")


		#echo $"${VAR_NAME}=>>${VAR_VALUE}|"


		done  <"${INI_FILE}"
	if [ $SET_SHOPT=1 ]
	then
		shopt -u extglob
	fi
}

function _DoTemplateSub(){
	local VAR_NAME="$1"
	declare -n cur_val="$VAR_NAME"
	for sub_value in "${TEMPLATE_SUB_ORDER[@]}"; do
		declare -n replace_with="BLD_CONFIG_$sub_value"
		cur_val=${cur_val//\[$sub_value\]/$replace_with}
	done
}
DoTemplateSubs(){
	INI_OUT=""
	local VAR_ARRAY_START_REGEX="^[ ]*\("	
	TEMPLATE_SUB_ORDER+=("STATIC_RELEASE_TRIPLET_AUTO" "CMAKE_BUILD_TARGET_AUTO")	
	BLD_CONFIG_STATIC_RELEASE_TRIPLET_AUTO=""
	BLD_CONFIG_CMAKE_BUILD_TARGET_AUTO="Release"
	BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO="MinSizeRel"

	if [[ $BLD_CONFIG_PREFER_STATIC_LINKING -eq 1 ]]; then
		BLD_CONFIG_STATIC_RELEASE_TRIPLET_AUTO+="-static"
	fi
	if [[ $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
		BLD_CONFIG_CMAKE_BUILD_TARGET_AUTO="Debug"
		BLD_CONFIG_CMAKE_BUILD_TYPE_AUTO="Debug"
	else
		BLD_CONFIG_STATIC_RELEASE_TRIPLET_AUTO+="-release"
	fi
	
	for value in "${TEMPLATE_SUB_ORDER[@]}"; do
		local var_name="BLD_CONFIG_$value"
		# if [[ (var_is_array "$var_name") ]]; then
		# 	local var_val=
		# 	for i in ${!array[@]}; do
		# 	_DoTemplateSub
		
		# else
		# 	_DoTemplateSub "$var_name"
		# fi
		declare -n cur_val="$var_name"
		local IS_ARRAY="$(var_is_array $var_name)";
		if [[ $IS_ARRAY != "0" || $cur_val == *"["* ]]; then
			for sub_value in "${TEMPLATE_SUB_ORDER[@]}"; do
				declare -n replace_with="BLD_CONFIG_$sub_value"
				if [[ $IS_ARRAY == "0" ]]; then
					cur_val=${cur_val//\[$sub_value\]/$replace_with}
				else
					cur_val=("${cur_val[@]//\[$sub_value\]/$replace_with}")
				fi
			done
		fi
		if [[ ${OPTION_TYPES["$value"]} -eq 1 && $IS_ARRAY == "0" ]]; then #if it is supposed to be an array but isn't quite yet

			if [[ "$cur_val" =~ $VAR_ARRAY_START_REGEX ]]; then #if its a string starting with a parens assuming we can eval to an array
				eval "declare -g -a BLD_CONFIG_$value=$cur_val"
			else #its not an array so transform to an array
				if [[ "$var_name" == "BLD_CONFIG_CONFIG_CMD_DEFAULT" || "$var_name" == "BLD_CONFIG_CONFIG_CMD_ADDL" ]]; then
					make_array_if_str "$var_name"
				else
					echo "Likely an error the variable: $var_name is supposed to be an array but it seeems to be a strin its value is: $cur_val"
					exit 1
				fi
			fi
		fi
	done
	for value in "${TEMPLATE_SUB_ORDER[@]}"; do
		if [[ $BLD_CONFIG_PRINT_VARS_AT_START -eq 1 ]]; then
			echo $"${value}=>>${cur_val}|"
		fi

		if [[ $SKIP_STEP == "export_config" ]]; then
			VAL_TO=`declare -p "BLD_CONFIG_${value}" | sed -E 's/declare \-\- //' | sed -E 's/^BLD_CONFIG_//'`
			if [[ "$VAL_TO" =~ "declare -a" ]]; then
				VAL_TO=`echo "$VAL_TO" | sed -E 's/\[[0-9]{1,2}\]=//g'  | sed -E 's/declare \-a //' | sed -E 's/^BLD_CONFIG_//'`
			fi

			INI_OUT="${INI_OUT}${VAL_TO}"$'\n'
		fi
	done

	if [[ ! -z "$INI_OUT" ]]; then
		local WIN_FOLDER=$(convert_from_msys_path "${SCRIPT_FOLDER}")
		INI_OUT="${INI_OUT}SCRIPT_FOLDER=\"${WIN_FOLDER}\""$'\n'
		echo "${INI_OUT}" > proj_config.ini
		echo "Exported to proj_config.ini"
		exit 0
	fi
}
