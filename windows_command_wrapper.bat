@ECHO OFF
set CMD=%~n1%
set GNU_BUILD_WRAPPER_DEBUG=1
IF "%~n0%"=="windows_command_wrapper"  GOTO notsym

	set CMD=%~n0%.exe
	ECHO "ROBO:  %~n0%   " 1>&2

IF "%GNU_BUILD_WRAPPER_DEBUG%"=="1" ECHO "GNU %CMD% CMD: %CMD% %*" 1>&2
IF "%CMD%" == "link.exe" set CMD="%VCToolsInstallDir%bin/HostX64/x64/link.exe"
	
if not defined GNU_BUILD_CMD_FILE GOTO endif1
	>>"%GNU_BUILD_CMD_FILE%" echo %CMD% %*
	:endif1
	%CMD% %*
	Exit /B %ERRORLEVEL%
goto:eof

:notsym
	IF "%GNU_BUILD_WRAPPER_DEBUG%"=="1" ECHO "GNU2 %CMD% CMD: %*" 1>&2

	if not defined GNU_BUILD_CMD_FILE GOTO endif2
	>>"%GNU_BUILD_CMD_FILE%" echo %*
	:endif2
	%*
	rem Exit 1
	Exit /B %ERRORLEVEL%