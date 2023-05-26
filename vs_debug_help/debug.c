#include "debug.h"
#include "config.h" // we need this if we have replace stdio.h with gnulibs
#include "stdio.h"

//#define _CRT_SECURE_NO_WARNINGS
#define WIN32_LEAN_AND_MEAN
#ifdef _WIN32
#include <windows.h>
#include <Share.h>
#endif

#include <process.h>
//#include <../ucrt/stdio.h>
#include <time.h>
#include <string.h>
#include <stdarg.h>
#include <debugapi.h>

void launchdebugger() {
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
//no reason to actually have this in a header
#ifndef DBGLOG_TERM_COLOR
int COLOR_CONSOLE_MODE_ENABLED = 0;
#else
int COLOR_CONSOLE_MODE_ENABLED = 1;
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


static inline void dbgSetTextColor(int code) {
	if (!COLOR_CONSOLE_MODE_ENABLED)
		return;
	printf("\x1b[%dm", code);
}

static inline void dbgSetTextColorBright(int code) {
	if (!COLOR_CONSOLE_MODE_ENABLED)
		return;

	printf("\x1b[%d;1m", code);
}

static inline void dbgSetBackgroundColor(int code) {
	if (!COLOR_CONSOLE_MODE_ENABLED)
		return;

	printf("\x1b[%dm", code);
}

static inline void dbgSetBackgroundColorBright(int code) {
	if (!COLOR_CONSOLE_MODE_ENABLED)
		return;

	printf("\x1b[%d;1m", code);
}

static inline void dbgResetColor(void) {
	if (!COLOR_CONSOLE_MODE_ENABLED)
		return;

	printf("\x1b[%dm", RESET_COLOR);
}

static inline void dbgClearScreen(void) {
	if (!COLOR_CONSOLE_MODE_ENABLED)
		return;

	printf("\x1b[%dJ", CLEAR_ALL);
}

#endif




static FILE* dbg = 0;
void _dbglog(int lineno, const char* file, const char* func, const char* format, ...) {
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
	sprintf_s(prefix_str, sizeof(prefix_str), "%2d:%02d:%02d %s:%d::%s ", timeinfo.tm_hour, timeinfo.tm_min, timeinfo.tm_sec, file, lineno, func);
#ifdef DBGLOG_PRINT_STDERR
	fputs(prefix_str, stderr);
#ifdef DBGLOG_TERM_COLOR
	dbgSetTextColor(YELLOW_TXT);
#endif
	vfprintf(stderr, format, args);
#ifdef DBGLOG_TERM_COLOR
	dbgResetColor();
#endif
	fputs("\n", stderr);
	fflush(stderr);
#endif // PRINT_STDERR
	if (dbg) {
		fputs(prefix_str, dbg);
		vfprintf(dbg, format, args);
		fputs("\n", dbg);
		fflush(dbg);
	}

	va_end(args);

}


void dbgInit(const char* logfile) {
#ifdef DBGLOG_TERM_COLOR
	dbgSetupConsole();
#endif
#ifdef DBGLOG_LOGGING
	if (logfile)
		dbg = _fsopen(logfile, "w", _SH_DENYNO);
	dlog("Starting our pid is: %d", _getpid());
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
#include <stdio.h>
#include <stdlib.h>



#ifdef _WIN32
// Some old MinGW/CYGWIN distributions don't define this:
#ifndef ENABLE_VIRTUAL_TERMINAL_PROCESSING
#define ENABLE_VIRTUAL_TERMINAL_PROCESSING  0x0004
#endif

static HANDLE stdoutHandle, stdinHandle;
static DWORD outModeInit, inModeInit;

void dbgSetupConsole(void) {
	DWORD outMode = 0, inMode = 0;
	stdoutHandle = GetStdHandle(STD_ERROR_HANDLE);
	stdinHandle = GetStdHandle(STD_INPUT_HANDLE);

	if (stdoutHandle == INVALID_HANDLE_VALUE || stdinHandle == INVALID_HANDLE_VALUE) {
		COLOR_CONSOLE_MODE_ENABLED = 0;
		dlog("Color console mode not enabled last error: %d", GetLastError());
		return;
		//exit(10000 + GetLastError());
	}

	if (!GetConsoleMode(stdoutHandle, &outMode) || !GetConsoleMode(stdinHandle, &inMode)) {
		COLOR_CONSOLE_MODE_ENABLED = 0;
		dlog("Color console mode not enabled last error: %d", GetLastError());
		return;
		//exit(20000 + GetLastError());
	}

	outModeInit = outMode;
	inModeInit = inMode;

	// Enable ANSI escape codes
	outMode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;

	// Set stdin as no echo and unbuffered
	inMode &= ~(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT);

	if (!SetConsoleMode(stdoutHandle, outMode) || !SetConsoleMode(stdinHandle, inMode)) {
		COLOR_CONSOLE_MODE_ENABLED = 0;
		dlog("Color console mode not enabled last error: %d", GetLastError());
		return;
		//exit(30000 + GetLastError());
	}


}

void dbgRestoreConsole(void) {
	if (!COLOR_CONSOLE_MODE_ENABLED)
		return;

	// Reset colors
	printf("\x1b[0m");

	// Reset console mode
	if (!SetConsoleMode(stdoutHandle, outModeInit) || !SetConsoleMode(stdinHandle, inModeInit)) {
		exit(GetLastError());
	}
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
	if ( (flags & flag_val) != flag_val)
		return;
	if (strlen(buffer))
		strcat_s(buffer, bufferLen, " ");
	strcat_s(buffer, bufferLen, flag_name);
}
