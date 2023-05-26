
postcmdlog() {
		DATA=$BASH_COMMAND
		[[ $BLD_CONFIG_LOG_IGNORE_REPEAT_LINES ]] && [[ "${DATA}" == "${TRACE_LAST_LINE}" ]] && return; #not sure if this would screw up with expanded vars in a for loop may want to move lower for expanded varrs
		TRACE_LAST_LINE="$DATA"
#		[[ $DATA  == \(\(*  || $DATA =~ "IFS=' ' read" ]] && return

		[ ${ignore_map["${DATA,,}"]} ] && return

		for regex in "${REGEX_IGNORE_CMDS[@]}"
		do
		:
			if [[ $DATA =~ $regex ]]; then
				return
			fi

		done

		if [ $BLD_CONFIG_LOG_EXPAND_VARS -eq 1 ]
		then
			declare buffer="__dont_give_an_err__"
			declare command="cat <<$buffer"$'\n'"$DATA"$'\n'"$buffer"
			DATA=$(eval "$command")
		fi
		[ ${ignore_map["${DATA,,}"]} ] || echo $DATA >&3
}
LOGON(){
		trap postcmdlog debug
}
LOGOFF(){
		trap - debug
}

function trace_init(){
	exec 3> $BLD_CONFIG_LOG_FILE
	if [[ $BLD_CONFIG_LOG_FILE_AUTOTAIL -eq 1 ]]; then
		tail -n 100 -f "$BLD_CONFIG_LOG_FILE" | uniq -u &
	fi

	echo Started `date` >&3
	declare -g TRACE_LAST_LINE
	declare -g ERRO_LINENO
	trap 'ERRO_LINENO=$LINENO' ERR
	if [ $BLD_CONFIG_STACKTRACE_ON_FAIL -eq 1 ]; then
		trap '_failure' EXIT
	else
		trap "trap - SIGTERM && kill -- -$$" EXIT
	fi;
	trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM #this kills any background prrocesses we also have running wh en we die
	# EXIT
	if [[ $BLD_CONFIG_LOG_ON_AT_INIT -eq 1 ]]; then
		LOGON
	fi
}

function trace_final(){
	if [[ $BLD_CONFIG_LOG_OFF_AT_FINAL -eq 1 ]]; then
		LOGOFF
	fi
	trap - EXIT
	trap - SIGHUP SIGINT SIGQUIT SIGABRT SIGKILL SIGALRM SIGTERM
	trap
	return 0
}

# StackTrace support
# https://opensource.com/article/22/7/print-stack-trace-bash-scripts base++
_failure() {
	ERR_CODE=$? # capture last command exit code
	set +xv # turns off debug logging, just in case
	DBG_OUT_STR="" #we concat onto a string to avoid other input (ie postcmdlog stdouting in the middle of the trace)
	if [[	$- =~ e && ${ERR_CODE} != 0 ]]
	then
		LEN=${#BASH_LINENO[@]}
		LAST_BASH_CMD="$BASH_COMMAND"
		LAST_BASH_CMD_LINE="$ERRO_LINENO"
		# only log stack trace if requested (set -e)
		# and last command failed
		NL=$'\n'
		DBG_OUT_STR+="$NL========= CATASTROPHIC COMMAND FAIL =========$NL$NL"
		CWD=`pwd`
		DBG_OUT_STR+="SCRIPT EXITED ON ERROR CODE: ${ERR_CODE} CWD: ${CWD}$NL$NL"

		for (( INDEX=$LEN-2; INDEX>=0; INDEX-- )); do
			ADD_SPACE=""
			for (( I=0; I<$INDEX; I++ )); do
				ADD_SPACE="  $ADD_SPACE"
			done
			DBG_OUT_STR+="${ADD_SPACE}---$NL"
			DBG_OUT_STR+="${ADD_SPACE}FILE: $(basename ${BASH_SOURCE[${INDEX}+1]})$NL"
			DBG_OUT_STR+="${ADD_SPACE}  FUNCTION: ${FUNCNAME[${INDEX}+1]}$NL"
			if [[ ${INDEX} > 0 ]]
			then
			 # commands in stack trace
				DBG_OUT_STR+="${ADD_SPACE}  COMMAND: ${FUNCNAME[${INDEX}]}$NL"
				DBG_OUT_STR+="${ADD_SPACE}  LINE: ${BASH_LINENO[${INDEX}]}$NL"
			else
				# command that failed
			EXPANDED_COMMAND=""
			if [ $BLD_CONFIG_EXPAND_FAILED_CMD_ON_STACKTRACE -eq 1 ]
			then
				trap _ EXIT
				sleep 0.4 #sleep to make sure any child commands like our tail on the command log can print out the last data before going away
				JOBS=$(jobs -p)
				if [[ ! -z "$JOBS" ]]; then
					kill $JOBS || true
				fi
				declare buffer="__dont_give_an_err__"
				declare command="cat <<$buffer"$'\n'"$LAST_BASH_CMD"$'\n'"$buffer"
				EXPANDED_COMMAND=$(eval "$command")
				if [ "$EXPANDED_COMMAND" == "$LAST_BASH_CMD" ]; then
					EXPANDED_COMMAND=""
				else
					EXPANDED_COMMAND=" => ${EXPANDED_COMMAND}"
				fi
			fi
				DBG_OUT_STR+="  COMMAND : ${LAST_BASH_CMD}${EXPANDED_COMMAND}$NL"
				DBG_OUT_STR+="  LINE: ${LAST_BASH_CMD_LINE}$NL"
			fi
		done
		DBG_OUT_STR+="$NL======= END CATASTROPHIC COMMAND FAIL =======$NL$NL"
		echo "${DBG_OUT_STR}" 1>&2
	fi
	kill -- -$$ || true
}