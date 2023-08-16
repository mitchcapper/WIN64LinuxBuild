#include "wlb_debug.h"
#include "config.h" // we need this if we have replace stdio.h with gnulibs
#include "stdio.h"

//#define _CRT_SECURE_NO_WARNINGS
#define WIN32_LEAN_AND_MEAN
#ifdef _WIN32
#include <windows.h>
#include <crtdbg.h>
#include <Share.h>
#endif

#include <process.h>
//#include <../ucrt/stdio.h>
#include <time.h>
#include <string.h>
#include <stdarg.h>
#include <debugapi.h>
void DisableDebugAssertPopup(void) {
	_CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE | _CRTDBG_MODE_DEBUG);
}
void EnableDebugAssertPopup() {
	_CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE | _CRTDBG_MODE_DEBUG | _CRTDBG_MODE_WNDW);
}
int MSVCAssertTmpSilenceAll() {
	return _CrtSetReportMode(_CRT_ASSERT, 0);
}
int MSVCAssertTmpRestoreAll(int oldMode) {
	return _CrtSetReportMode(_CRT_ASSERT, oldMode);
}

void launchdebugger() {
	if (IsDebuggerPresent()) {
		DebugBreak();
		return;
	}
	char cmd[1024];
	int pid = _getpid();
	char spid[50];
	sprintf_s(spid, sizeof(spid), "%d", pid);
	strcpy_s(cmd, sizeof(cmd), "C:/Windows/System32/vsjitdebugger.exe -p ");
	strcat_s(cmd, sizeof(cmd), spid);

	FILE* output = _popen(cmd, "r");
	while (!IsDebuggerPresent()) Sleep(50);
	DebugBreak();

}
struct DbgCfg {
	BOOL logging;
	BOOL stderr_color;
	BOOL file_color;
	BOOL stderr_log_target;
	FILE* logfile;
} dbgcfg = {
#ifdef DBGLOG_LOGGING
#ifdef DBGLOG_FILE_COLOR	
	.file_color = TRUE,
#endif	
#ifdef DBGLOG_PRINT_STDERR
	.stderr_log_target = TRUE,
#endif
#ifdef DBGLOG_TERM_COLOR
	.stderr_color = TRUE,
#endif
	.logging = TRUE
#else
	.logging = FALSE
#endif
};
//no reason to actually have this in a header

//https://solarianprogrammer.com/2019/04/08/c-programming-ansi-escape-codes-windows-macos-linux-terminals/
#include <stdio.h>
enum DbgColors {
	RESET_COLOR,
	BLACK_TXT = 30,
	RED_TXT,
	GREEN_TXT,
	YELLOW_TXT,
	BLUE_TXT,
	MAGENTA_TXT,
	CYAN_TXT,
	WHITE_TXT,

	BLACK_BKG = 40,
	RED_BKG,
	GREEN_BKG,
	YELLOW_BKG,
	BLUE_BKG,
	MAGENTA_BKG,
	CYAN_BKG,
	WHITE_BKG
};

enum DbgClearCodes {
	CLEAR_FROM_CURSOR_TO_END,
	CLEAR_FROM_CURSOR_TO_BEGIN,
	CLEAR_ALL
};

void dbgSetupConsole(void);
void dbgRestoreConsole(void);


static inline void fdbgSetTextColor(FILE* f, int code) {
	fprintf(f, "\x1b[%dm", code);
}


static inline void dbgSetTextColor(int code) {
	if (!dbgcfg.stderr_color)
		return;
	fdbgSetTextColor(stderr, code);
}

static inline void fdbgSetTextColorBright(FILE* f, int code) {
	fprintf(f, "\x1b[%d;1m", code);
}
static inline void dbgSetTextColorBright(int code) {
	if (!dbgcfg.stderr_color)
		return;

	fdbgSetTextColorBright(stderr, code);
}

static inline void fdbgSetBackgroundColor(FILE* f, int code) {
	fprintf(f, "\x1b[%dm", code);
}
static inline void dbgSetBackgroundColor(int code) {
	if (!dbgcfg.stderr_color)
		return;

	fdbgSetBackgroundColor(stderr, code);
}

static inline void fdbgSetBackgroundColorBright(FILE* f, int code) {
	fprintf(f, "\x1b[%d;1m", code);
}
static inline void dbgSetBackgroundColorBright(int code) {
	if (!dbgcfg.stderr_color)
		return;

	fdbgSetBackgroundColorBright(stderr, code);
}

static inline void fdbgResetColor(FILE* f) {
	fprintf(f, "\x1b[%dm", RESET_COLOR);
}
static inline void dbgResetColor(void) {
	if (!dbgcfg.stderr_color)
		return;

	fdbgResetColor(stderr);
}

static inline void dbgClearScreen(void) {
	if (!dbgcfg.stderr_color)
		return;
	printf("\x1b[%dJ", CLEAR_ALL);
}
void _fdbglog_help(FILE* f, const char* prefix_str, int use_color, const char* format, va_list args) {
	fputs(prefix_str, f);
	if (use_color)
		fdbgSetTextColor(f, YELLOW_TXT);
	vfprintf(f, format, args);
	if (use_color)
		fdbgResetColor(f);
	fputs("\n", f);
	fflush(f);

}
void _fdbglog_msg(const char* prefix_str, const char* format, va_list args) {
	char buffer[1024];
	OutputDebugString(prefix_str);
	vsprintf_s(buffer, sizeof(buffer), format, args);
	OutputDebugString(buffer);
	OutputDebugString("\n");
}

#ifdef _WIN32
#define THREAD_LOCAL static __declspec( thread )
#else
#define THREAD_LOCAL static thread_local
#endif
/// <summary>
/// warning calls during or after calling this may override the returned buffer if you don't have the errcode try errno or WSAGetLastError() (for sockets)
/// </summary>
/// <param name="prefix"></param>
/// <returns></returns>
const char* dbgGetWinErr(const char* prefix, int errcode) {
	THREAD_LOCAL char errstr[1024] = { "" };
	if (prefix)
		strcpy_s(errstr, sizeof(errstr), prefix);
	int offset = strlen(errstr);
	if (!FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,   // flags
		NULL,                // lpsource
		errcode,                 // message id
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),    // languageid
		errstr + offset,              // output buffer
		sizeof(errstr) - offset,     // size of msgbuf, bytes
		NULL))               // va_list of arguments
		sprintf_s(errstr + strlen(errstr), sizeof(errstr) - strlen(errstr), " FormatMessage unable to find error code: 0x%x", errcode);
	return errstr;
}

int _dbglog(int retval, __DbgLogType_t LogType, int lineno, const char* file, const char* func, const char* format, ...) {
#ifdef DBGLOG_LOGGING
	va_list args;
	va_start(args, format);
	time_t rawtime;
	struct tm timeinfo;
	const char* file_end = strrchr(file, '\\');
	if (file_end != NULL)
		file = file_end + 1;

	time(&rawtime);
	localtime_s(&timeinfo, &rawtime);
	char prefix_str[150];
	sprintf_s(prefix_str, sizeof(prefix_str), "%2d:%02d:%02d %s:%d::%s %s", timeinfo.tm_hour, timeinfo.tm_min, timeinfo.tm_sec, file, lineno, func, LogType == __DbgLogFatal ? "FLOG " : "");
	if (dbgcfg.stderr_log_target || LogType == __DbgLogFatal)
		_fdbglog_help(stderr, prefix_str, dbgcfg.stderr_color, format, args);
	if (dbgcfg.logfile)
		_fdbglog_help(dbgcfg.logfile, prefix_str, dbgcfg.file_color, format, args);
	_fdbglog_msg(prefix_str, format, args);
	//DbgPrint();
	va_end(args);
	if (LogType == __DbgLogFatal)
		exit(-99);
	return retval;
#else
	return retval;
#endif // !1
}

#include <stdlib.h>
#define CRT_REPORT_MODE_NOTSET -999
static int GetCrtReportMode(const char* env_name) {
	const char * str = getenv(env_name);
	if (!str)
		return CRT_REPORT_MODE_NOTSET;
	errno = 0;
	long parsed = strtol(str, NULL, 0);
	if (parsed == 0 && errno)
		return CRT_REPORT_MODE_NOTSET;
	return (int)parsed;
}
void dbgInit(const char* logfile) {
#ifdef DBGLOG_TERM_COLOR
	dbgSetupConsole();
#endif
#ifdef DBGLOG_LOGGING
	if (logfile)
		dbgcfg.logfile = _fsopen(logfile, "w", _SH_DENYNO);
	dlog("Starting our pid is: %d", _getpid());
#endif
#ifdef _DEBUG
#ifdef DBGLOG_DISABLE_DEBUG_ASSERT_IN_DBGINIT
	DisableDebugAssertPopup();
#else
	EnableDebugAssertPopup();
#endif
#ifdef DBGLOG_SET_CRT_REPORT_FILE_STDERR
	_CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
	_CrtSetReportFile(_CRT_ERROR, _CRTDBG_FILE_STDERR);
	_CrtSetReportFile(_CRT_WARN, _CRTDBG_FILE_STDERR);
#endif
#ifdef DBGLOG_ENV_CRT_REPORT_MODE_CNTRL
	int mode;
	if ((mode = GetCrtReportMode("_CRT_ASSERT_MODE")) != CRT_REPORT_MODE_NOTSET)
		_CrtSetReportMode(_CRT_ASSERT, mode);
	if ((mode = GetCrtReportMode("_CRT_ERROR_MODE")) != CRT_REPORT_MODE_NOTSET)
		_CrtSetReportMode(_CRT_ERROR, mode);
	if ((mode = GetCrtReportMode("_CRT_WARN_MODE")) != CRT_REPORT_MODE_NOTSET)
		_CrtSetReportMode(_CRT_WARN, mode);
#endif
#endif
}
#ifdef DBGLOG_TERM_COLOR
//https://solarianprogrammer.com/2019/04/08/c-programming-ansi-escape-codes-windows-macos-linux-terminals/
#ifdef _WIN32
#include <windows.h>
#else
#include <termios.h>
#include <unistd.h>
#endif



#ifdef _WIN32
// Some old MinGW/CYGWIN distributions don't define this:
#ifndef ENABLE_VIRTUAL_TERMINAL_PROCESSING
#define ENABLE_VIRTUAL_TERMINAL_PROCESSING  0x0004
#endif

static DWORD errModeInit, outModeInit, inModeInit;

DWORD SetupConsoleHandle(BOOL is_input, HANDLE handle) {
	DWORD mode = 0;
	if (handle == INVALID_HANDLE_VALUE)
		return mode;
	if (!GetConsoleMode(handle, &mode))
		return mode;
	DWORD orig=mode;
	if (is_input) {
		mode &= ~(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT); // Set stdin as no echo and unbuffered
		mode |= ENABLE_VIRTUAL_TERMINAL_INPUT;
	}
	else
		mode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
	
	SetConsoleMode(handle, mode);
	return orig;
}

void dbgSetupConsole(void) {
	errModeInit=SetupConsoleHandle(FALSE, GetStdHandle(STD_ERROR_HANDLE));
	outModeInit=SetupConsoleHandle(FALSE, GetStdHandle(STD_OUTPUT_HANDLE));
	inModeInit=SetupConsoleHandle(TRUE, GetStdHandle(STD_INPUT_HANDLE));
}

void dbgRestoreConsole(void) {
	if (!dbgcfg.stderr_color)
		return;

	// Reset colors
	if (outModeInit)
		printf("\x1b[0m");

	// Reset console mode
	if (inModeInit)
		SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), inModeInit);
	if (errModeInit)
		SetConsoleMode(GetStdHandle(STD_ERROR_HANDLE), errModeInit);
	if (outModeInit)
		SetConsoleMode(GetStdHandle(STD_OUTPUT_HANDLE), outModeInit);		
}
#else

static struct termios orig_term;
static struct termios new_term;

void dbgSetupConsole(void) {
	tcgetattr(STDIN_FILENO, &orig_term);
	new_term = orig_term;

	new_term.c_lflag &= ~(ICANON | ECHO);

	tcsetattr(STDIN_FILENO, TCSANOW, &new_term);
}

void dbgRestoreConsole(void) {
	// Reset colors
	printf("\x1b[0m");

	// Reset console mode
	tcsetattr(STDIN_FILENO, TCSANOW, &orig_term);
}
#endif
#endif

void flagAppend(char* buffer, int bufferLen, int flags, const char* flag_name, int flag_val) {
	if ((flags & flag_val) != flag_val)
		return;
	if (strlen(buffer))
		strcat_s(buffer, bufferLen, " ");
	strcat_s(buffer, bufferLen, flag_name);
}
