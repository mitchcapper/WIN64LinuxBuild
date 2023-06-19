#pragma once

#define DBGLOG_LOGGING
#define DBGLOG_TERM_COLOR
#define DBGLOG_PRINT_STDERR
//#define DBGLOG_FILE_COLOR //ansi codes to logfile
#define DBGLOG_ENV_CRT_REPORT_MODE_CNTRL //allows setting env vars _CRT_ASSERT_MODE _CRT_ERROR_MODE _CRT_WARN_MODE to integer values for the mode to set them to on init only applies in debug builds, _CRTDBG_MODE_FILE=1, _CRTDBG_MODE_DEBUG=2,_CRTDBG_MODE_WNDW=4 (can be multiple as well)
#define DBGLOG_SET_CRT_REPORT_FILE_STDERR //sets the file output as stderr
#define DBGLOG_LOG_FILE NULL
//#define DBGLOG_DISABLE_DEBUG_ASSERT_IN_DBGINIT


/// <summary>
/// warning calls during or after calling this may override the returned buffer if you don't have the errcode try errno or WSAGetLastError() (for sockets)
/// </summary>
/// <param name="prefix"></param>
/// <returns></returns>
const char* dbgGetWinErr(const char* prefix, int errcode);

extern void dbgInit(const char* logfile);
extern void launchdebugger();
extern void DisableDebugAssertPopup();
extern void flagAppend(char* buffer, int bufferLen, int flags, const char* flag_name, int flag_val);
int MSVCAssertTmpRestoreAll(int oldMode);
int MSVCAssertTmpSilenceAll();
typedef enum { __DbgLogNorm, __DbgLogFunc, __DbgLogFatal } __DbgLogType_t;//dbglogfunc means we are logging a call we commented out or norm trace


#define dlog(format, ...) _dbglog(0, __DbgLogNorm,  __LINE__,__FILE__,__func__, format, ## __VA_ARGS__)
#define dlogfatal(format, ...) _dbglog(0, __DbgLogFatal,  __LINE__,__FILE__,__func__, format, ## __VA_ARGS__)
#define dcalled(format, ...) _dbglog(-1, __DbgLogFunc,  __LINE__,__FILE__,__func__, format, ##  __VA_ARGS__)
#define dcalledint(retval, format, ...) _dbglog(retval,__DbgLogFunc,  __LINE__,__FILE__,__func__, format, ## __VA_ARGS__)
#define dcalledintMacro(retval, format, func, ...) _dbglog(retval, 1,  __LINE__,__FILE__,func, format, ## __VA_ARGS__)
extern int _dbglog(int retval, __DbgLogType_t LogType, int lineno, const char* file, const char* func, const char* format, ...);


