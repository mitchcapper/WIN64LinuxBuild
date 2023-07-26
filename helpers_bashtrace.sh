
postcmdlog() {
	#echo postcmdlog CALLED FOR:  $BASH_COMMAND
	DATA=$BASH_COMMAND
	if [[ $TRACE_ERRTRAP_CALLED -gt 0 ]]; then
		((TRACE_ERRTRAP_CALLED--));
	fi
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
	declare -g TRACE_LAST_LINE TRACE_ERRTRAP_CALLED
	declare -g TRACE_TRAP_CURLINENO TRACE_TRAP_LINENO0 TRACE_TRAP_FUNC0 TRACE_TRAP_FILE0 TRACE_TRAP_LINENO1 TRACE_TRAP_FUNC1 TRACE_TRAP_FILE1

	#See _failure for why we do this
	if [ $BLD_CONFIG_STACKTRACE_ON_FAIL -eq 1 ]; then
		trap 'TRACE_TRAP_CURLINENO="$LINENO";TRACE_TRAP_LINENO0="${BASH_LINENO[0]}";TRACE_TRAP_FUNC0="${FUNCNAME[0]}";TRACE_TRAP_FILE0="${BASH_SOURCE[0]}";TRACE_TRAP_LINENO1="${BASH_LINENO[1]}";TRACE_TRAP_FUNC1="${FUNCNAME[1]}";TRACE_TRAP_FILE1="${BASH_SOURCE[1]}";TRACE_ERRTRAP_CALLED=2' ERR
		set -E
		trap '_failure "$TRACE_ERRTRAP_CALLED"' EXIT
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
	return 0
}










# executes a function while storing some useful info for debug
function ex(){
	local PARAMS=("${@:2}")
	EX_CUR_CMD="$1 ${PARAMS[@]@Q}"
	echo "EX Running $EX_CUR_CMD"
	echo "$EX_CUR_CMD" >&3
	"$@"
	EX_CUR_CMD=""
}
# StackTrace support
_failure() {
	# https://opensource.com/article/22/7/print-stack-trace-bash-scripts base++++++++++++
	ERR_CODE=$? # capture last command exit code
	set +xv # turns off debug logging, just in case
	HAVE_ERR_TRAP="$1"

	# for i in 0 1 2 3 4 5; do
	#  	echo "$i: ${BASH_SOURCE[$i]}:${FUNCNAME[$i]}:${BASH_LINENO[$i]}"
	# done
	DBG_OUT_STR="" #we concat onto a string to avoid other input (ie postcmdlog stdouting in the middle of the trace)
	DBG_OUT_STR_FINAL="" #for color escape needed
	if [[ $- =~ e && ${ERR_CODE} != 0 ]];	then
		STACK_CMD="$BASH_COMMAND" #the actual last command being run			

		declare -a STACK_LINES STACK_FUNCS STACK_FILES
		FUNC_FILE_SKIP_CNT=1 #skipping first element in all these, as first elem is _failure(aka us)
		if [[ $HAVE_ERR_TRAP -eq 1 ]]; then #this should always be valid data so might as well use it
			STACK_LINES+=("$TRACE_TRAP_CURLINENO")
			STACK_LINES+=("$TRACE_TRAP_LINENO0")
			STACK_LINES+=("$TRACE_TRAP_LINENO1")
			STACK_FUNCS+=("$TRACE_TRAP_FUNC0")
			STACK_FUNCS+=("$TRACE_TRAP_FUNC1")
			STACK_FILES+=("$TRACE_TRAP_FILE0")
			STACK_FILES+=("$TRACE_TRAP_FILE1")
			if [[ "${BASH_SOURCE[$FUNC_FILE_SKIP_CNT]}:${FUNCNAME[$FUNC_FILE_SKIP_CNT]}:${BASH_LINENO[$FUNC_FILE_SKIP_CNT]}" == "$TRACE_TRAP_FILE0:$TRACE_TRAP_FUNC0:$TRACE_TRAP_LINENO0" ]]; then
				((FUNC_FILE_SKIP_CNT++));
			fi
			if [[ "${BASH_SOURCE[$FUNC_FILE_SKIP_CNT]}:${FUNCNAME[$FUNC_FILE_SKIP_CNT]}:${BASH_LINENO[$FUNC_FILE_SKIP_CNT]}" == "$TRACE_TRAP_FILE1:$TRACE_TRAP_FUNC1:$TRACE_TRAP_LINENO1" ]]; then
				((FUNC_FILE_SKIP_CNT++));
			fi
		else
			STACK_LINES+=("-1") #as far as I can tell no way to get true line number if we call exit fir the first line
		fi
		
		STACK_LINES+=(${BASH_LINENO[@]:$FUNC_FILE_SKIP_CNT})
		STACK_FUNCS+=(${FUNCNAME[@]:$FUNC_FILE_SKIP_CNT})
		STACK_FILES+=(${BASH_SOURCE[@]:$FUNC_FILE_SKIP_CNT})
		#  echo "OUR REBUILT"
		#  for i in 0 1 2 3 4 5; do
		#  	echo "$i: ${STACK_FILES[$i]}:${STACK_FUNCS[$i]}:${STACK_LINES[$i]}"
		#  done
		# exit 0
		LEN=${#STACK_LINES[@]}-1
		NL=$'\n'
		DBG_OUT_STR+="$NL========= CATASTROPHIC COMMAND FAIL =========$NL"
		CWD=`pwd`

		STACK_END=0 #do we stop at the last item on the stack?

		if [[ "${STACK_FUNCS[$STACK_END]}" == "ex" ]]; then #strip it off
			STACK_END=1
			STACK_CMD="ex called to run: $EX_CUR_CMD"
		fi

		for (( INDEX=$LEN-1; INDEX>=$STACK_END; INDEX-- )); do
			ADD_SPACE=""
			for (( I=$STACK_END; I<$INDEX; I++ )); do
				ADD_SPACE="  $ADD_SPACE"
			done
			DBG_OUT_STR+="${ADD_SPACE}---$NL"
			DBG_OUT_STR+="${ADD_SPACE} $(basename ${STACK_FILES[$INDEX]}):${STACK_FUNCS[$INDEX]}():${STACK_LINES[$INDEX]}"
			if [[ ${INDEX} > $STACK_END ]];	then
				DBG_OUT_STR+=" ${STACK_FUNCS[${INDEX}-1]}$NL" #minus one as the command is really the next function on the stack
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
					declare command="cat <<$buffer"$'\n'"$STACK_CMD"$'\n'"$buffer"
					EXPANDED_COMMAND=$(eval "$command")
					if [ "$EXPANDED_COMMAND" == "$STACK_CMD" ]; then
						EXPANDED_COMMAND=""
					else
						EXPANDED_COMMAND=" => ${EXPANDED_COMMAND}"
					fi
				fi
				DBG_OUT_STR_FINAL+="${NL}${COLOR_MINOR2}Fatal Command${COLOR_NONE}: ${COLOR_ERROR}${STACK_CMD}${EXPANDED_COMMAND}${COLOR_NONE} on line ${COLOR_MINOR}${STACK_LINES[$STACK_END]}${COLOR_NONE} of ${COLOR_MINOR}$(basename ${STACK_FILES[$STACK_END]})${COLOR_NONE}$NL"
				DBG_OUT_STR_FINAL+="Script ${COLOR_MINOR2}EXITED${COLOR_NONE}, Command Exit Code: ${COLOR_ERROR}${ERR_CODE}${COLOR_NONE} Our CWD: ${CWD}$NL"
			fi
		done
		DBG_OUT_STR_FINAL+="$NL======= END CATASTROPHIC COMMAND FAIL =======$NL$NL"
		echo "${DBG_OUT_STR}" 1>&2
		echo -e "${DBG_OUT_STR_FINAL}" 1>&2
	fi
	kill -- -$$ || true
}