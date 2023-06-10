#pragma once

#define DBGLOG_LOGGING
#define DBGLOG_TERM_COLOR
#define DBGLOG_PRINT_STDERR
//#define DBGLOG_FILE_COLOR //ansi codes to logfile



extern void dbgInit(const char* logfile);
extern void launchdebugger();
extern void DisableDebugAssertPopup();
extern void flagAppend(char* buffer, int bufferLen, int flags, const char* flag_name, int flag_val);

typedef enum { __DbgLogNorm, __DbgLogFunc, __DbgLogFatal } __DbgLogType_t;//dbglogfunc means we are logging a call we commented out or norm trace

#ifdef  DBGLOG_LOGGING
#define dlog(format, ...) _dbglog(0, __DbgLogNorm,  __LINE__,__FILE__,__func__, format, ## __VA_ARGS__)
#define dlogfatal(format, ...) _dbglog(0, __DbgLogFatal,  __LINE__,__FILE__,__func__, format, ## __VA_ARGS__)
#define dcalled(format, ...) _dbglog(-1, __DbgLogFunc,  __LINE__,__FILE__,__func__, format, ##  __VA_ARGS__)
#define dcalledint(retval, format, ...) _dbglog(retval,__DbgLogFunc,  __LINE__,__FILE__,__func__, format, ## __VA_ARGS__)
#define dcalledintMacro(retval, format, func, ...) _dbglog(retval, 1,  __LINE__,__FILE__,func, format, ## __VA_ARGS__)
extern int _dbglog(int retval, __DbgLogType_t LogType, int lineno, const char* file, const char* func, const char* format, ...);


#endif //  DBGLOG_LOGGING
