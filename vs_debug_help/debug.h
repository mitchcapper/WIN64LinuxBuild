#pragma once

#define DBGLOG_LOGGING
#define DBGLOG_TERM_COLOR
#define DBGLOG_PRINT_STDERR



extern void dbgInit(const char * logfile);
extern void launchdebugger();
extern void flagAppend(char* buffer, int bufferLen, int flags, const char* flag_name, int flag_val);



#ifdef  DBGLOG_LOGGING
#define dlog(format, ...) _dbglog( __LINE__,__FILE__,__func__, format, __VA_ARGS__)
extern void _dbglog(int lineno, const char* file, const char* func, const char* format, ...);
#endif //  DBGLOG_LOGGING



