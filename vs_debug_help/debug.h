#pragma once

#define DBGLOG_LOGGING
#define DBGLOG_TERM_COLOR
#define DBGLOG_PRINT_STDERR
//#define DBGLOG_FILE_COLOR //ansi codes to logfile



extern void dbgInit(const char * logfile);
extern void launchdebugger();
extern void DisableDebugAssertPopup();
extern void flagAppend(char* buffer, int bufferLen, int flags, const char* flag_name, int flag_val);



#ifdef  DBGLOG_LOGGING
#define dlog(format, ...) _dbglog(0, 0,  __LINE__,__FILE__,__func__, format, __VA_ARGS__)
#define dcalled(format, ...) _dbglog(-1, 1,  __LINE__,__FILE__,__func__, format, __VA_ARGS__)
#define dcalledint(retval, format, ...) _dbglog(retval, 1,  __LINE__,__FILE__,__func__, format, __VA_ARGS__)
extern int _dbglog(int retval, int funcLog, int lineno, const char* file, const char* func, const char* format, ...);


#endif //  DBGLOG_LOGGING
