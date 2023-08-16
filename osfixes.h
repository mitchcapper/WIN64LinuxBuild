#pragma once
//shared polyfill library
#ifdef _WIN32
/*
#define WLB_OS_BASIC_TERM
#define WLB_OS_BASIC_TERM_USE_PDCURSES
#define WLB_DL_OPEN
#define WLB_EXEC_ADVANCED //configurable set of classes for workign to replace fork with gnulib's spawn functions
#define WLB_INCLUDE_CONFIG_H
#define WLB_WINSOCK_FIX
#define WLB_PROC_SIG_EXITS
#define WLB_FUNC_NOOPS
#define WLB_INCL_WLB_DEBUG_H
#define WLB_DISABLE_DEBUG_ASSERT_AT_EXIT
#define WLB_CONSTRUCTOR_SUPPORT
*/
extern void DisableDebugAssertAtExit();
#if defined(WLB_DISABLE_DEBUG_ASSERT_AT_EXIT) && ! defined(WLB_CONSTRUCTOR_SUPPORT)
#define WLB_CONSTRUCTOR_SUPPORT

#endif

#ifdef WLB_INCLUDE_CONFIG_H
#include "config.h"
#endif
#ifdef WLB_INCL_WLB_DEBUG_H
#include "wlb_debug.h"
#endif
//with newer windows sdks the wrong header order in some files results in a SocketNotificationRetrieveEvents defined multiple times error, this is the easiest solution ive seen
#ifdef WLB_WINSOCK_FIX
#ifndef WINSOCK_INCLUDED
#define WINSOCK_INCLUDED 1
#include <winsock2.h>
#include <ws2tcpip.h>
#endif
#endif

#ifdef WLB_CONSTRUCTOR_SUPPORT
#ifdef __cplusplus
    #define CONSTRUCTOR(f) \
        static void f(void); \
        struct f##_t_ { f##_t_(void) { f(); } }; static f##_t_ f##_; \
        static void f(void)
#elif defined(_MSC_VER)
//This supports multiple constructor calls per object file, but across libs/object files you must have a unique function name for each

#define WLB_CONCAT_INNER(a, b) a##b
#define WLB_CONCAT(a, b) WLB_CONCAT_INNER(a, b)
#define WLB_STRINGIFY( x ) # x
#define WLB_UNIQUE_NAME(base) WLB_CONCAT(base____, __COUNTER__)
//this undef is needed incase gnulib or something else already redefined read
#if defined(read)
#define ___old_read read
#undef read
#pragma section(".CRT$XCU",read)
#define read ___old_read
#else
#pragma section(".CRT$XCU",read)
#endif


#define WLBCONSTRUCT3_(f,fun,p) \
        static void f(void); \
        __declspec(allocate(".CRT$XCU")) void (*WLB_CONCAT(fun,__constructor__))(void) = f; \
        __pragma(comment(linker,"/include:" p WLB_STRINGIFY(fun) "__constructor__")) \
        static void f(void)

#define WLBCONSTRUCT2_(f,p) WLBCONSTRUCT3_(f,WLB_UNIQUE_NAME(f),p)

#ifdef _WIN64
#define CONSTRUCTOR(f) WLBCONSTRUCT2_(f,"")
#else
#define CONSTRUCTOR(f) WLBCONSTRUCT2_(f,"_")
#endif
#pragma data_seg()
#else
    #define CONSTRUCTOR(f) \
        static void f(void) __attribute__((constructor)); \
        static void f(void)
#endif
#endif


#ifdef WLB_OS_BASIC_TERM

#define TTYSTRUCT struct ttyjunked
#define	TIOCHPCL	_IO('t', 2)		/* hang up on last close */
#define	TIOCGETP	_IOR('t', 8,TTYSTRUCT)/* get parameters -- gtty */
#define	TIOCSETP	_IOW('t', 9,TTYSTRUCT)/* set parameters -- stty */
#define	TIOCSETN	_IOW('t',10,TTYSTRUCT)/* as above, but no flushtty*/
#define	TIOCSETC	_IOW('t',17,struct tchars)/* set special characters */
#define	TIOCGETC	_IOR('t',18,struct tchars)/* get special characters */
#define		TANDEM		0x00000001	/* send stopc on out q full */
#define		CBREAK		0x00000002	/* half-cooked mode */
#define		LCASE		0x00000004	/* simulate lower case */
#define		ECHO		0x00000008	/* enable echoing */
#define		CRMOD		0x00000010	/* map \r to \r\n on output */
#define		RAW		0x00000020	/* no i/o processing */
#define		ODDP		0x00000040	/* get/send odd parity */
#define		EVENP		0x00000080	/* get/send even parity */
#define		ANYP		0x000000c0	/* get any parity/send none */
#define		NLDELAY		0x00000300	/* \n delay */
#define			NL0	0x00000000
#define			NL1	0x00000100	/* tty 37 */
#define			NL2	0x00000200	/* vt05 */
#define			NL3	0x00000300
#define		TBDELAY		0x00000c00	/* horizontal tab delay */
#define			TAB0	0x00000000
#define			TAB1	0x00000400	/* tty 37 */
#define			TAB2	0x00000800
#define		XTABS		0x00000c00	/* expand tabs on output */
#define		CRDELAY		0x00003000	/* \r delay */
#define			CR0	0x00000000
#define			CR1	0x00001000	/* tn 300 */
#define			CR2	0x00002000	/* tty 37 */
#define			CR3	0x00003000	/* concept 100 */
#define		VTDELAY		0x00004000	/* vertical tab delay */
#define			FF0	0x00000000
#define			FF1	0x00004000	/* tty 37 */
#define		BSDELAY		0x00008000	/* \b delay */
#define			BS0	0x00000000
#define			BS1	0x00008000
#define		ALLDELAY	(NLDELAY|TBDELAY|CRDELAY|VTDELAY|BSDELAY)
#define		CRTBS		0x00010000	/* do backspacing for crt */
#define		PRTERA		0x00020000	/* \ ... / erase */
#define		CRTERA		0x00040000	/* " \b " to wipe out char */
#define		TILDE		0x00080000	/* hazeltine tilde kludge */
#define		MDMBUF		0x00100000	/* DTR/DCD hardware flow control */
#define		LITOUT		0x00200000	/* literal output */
#define		TOSTOP		0x00400000	/* stop background jobs on output */
#define		FLUSHO		0x00800000	/* output being flushed (state) */
#define		NOHANG		0x01000000	/* (no-op) was no SIGHUP on carrier drop */
#define		L001000		0x02000000
#define		CRTKIL		0x04000000	/* kill line with " \b " */
#define		PASS8		0x08000000
#define		CTLECH		0x10000000	/* echo control chars as ^X */
#define		PENDIN		0x20000000	/* re-echo input buffer at next read */
#define		DECCTQ		0x40000000	/* only ^Q starts after ^S */
#define		NOFLSH		0x80000000
#ifdef WLB_OS_BASIC_TERM_USE_PDCURSES
#include "term.h"
#else
static int tgetflag (const char *name){
  return -1;
}

static int tgetnum (){
  return -1;
}
static char *tgetstr (){
  return NULL;
}

static int tgetent(char *bp, const char *name){
  return -1;
}
static int tputs(const char *str, int affcnt, int (*putc)(int)){
  return -1;
}
static char *tgoto(const char *cap, int col, int row){
  return NULL;
}
#endif
#if ! defined(tchars)
struct   tchars {
	char t_intrc;     /* interrupt */
	char t_quitc;     /* quit */
	char t_startc; /* start output */
	char t_stopc;     /* stop output */
	char t_eofc;        /* end-of-file */
	char t_brkc;        /* input delimiter (like nl) */
	 };
#endif
#if ! defined(ltchars)
struct ltchars {
	char t_suspc;  /* stop process signal */
	char t_dsuspc; /* delayed stop process signal */
	char t_rprntc; /* reprint line */
	char t_flushc; /*flush output (toggles) */
	char t_werasc; /* word erase */
	char t_lnextc; /* literal next character */
};
#endif
struct ttyjunked {
	char    sg_ispeed;
	char    sg_ospeed;
	char    sg_erase;
	char    sg_kill;
	short   sg_flags;
};
#endif


#ifdef WLB_DL_OPEN
#ifndef DLFCN_H
#define DLFCN_H

#define RTLD_LAZY 1
extern void *dlopen (const char *, int);
extern int   dlclose (void *);
extern void *dlsym (void *, const char *);
extern char *dlerror (void);
#endif	/* DLFCN_H */
#endif

#if ! defined(BOOL)
#define BOOL int
#endif


#define SIGALRM 14
#ifdef WLB_EXEC_ADVANCED
#include <spawn.h>
typedef struct HandleExec {
	BOOL was_async;
	pid_t child_pid;
	char* cmd;
	char** args;
	int fake_exit_status;
	posix_spawn_file_actions_t * actions;
	posix_spawnattr_t* attrp;
	char** envp;
	int ___env_cur;
	int ___env_max;
	BOOL __has_run;
	BOOL __has_forked;
	BOOL __had_fake_exit;

} HandleExec;

HandleExec* ExecGetNew(void);
static char* signal_names[36] = {
	"EXIT",
	"SIGHUP",
	"SIGINT",
	"SIGQUIT",
	"SIGILL",
	"SIGTRAP",
	"SIGABRT",
	"SIGEMT",
	"SIGFPE",
	"SIGKILL",
	"SIGBUS",
	"SIGSEGV",
	"SIGSYS",
	"SIGPIPE",
	"SIGALRM",
	"SIGTERM",
	"SIGURG",
	"SIGSTOP",
	"SIGTSTP",
	"SIGCONT",
	"SIGCHLD",
	"SIGTTIN",
	"SIGTTOU",
	"SIGIO",
	"SIGXCPU",
	"SIGXFSZ",
	"SIGVTALRM",
	"SIGPROF",
	"SIGWINCH",
	"SIGINFO",
	"SIGUSR1",
	"SIGUSR2",
	"DEBUG",
	"ERR",
	"RETURN",
	(char*)0x0
};

void ExecDupeEnvVar(HandleExec* exec, const char* varLine);
static void __DupeOrUpdateEnvVarPair(HandleExec* exec, BOOL CHECK_EXISTING, const char* varName, const char* value);
void ExecDupeEnvVarPair(HandleExec* exec, const char* varName, const char* value);
void ExecDupeOrUpdateEnvVarPair(HandleExec* exec, const char* varName, const char* value);
void ExecDestroy(HandleExec** exec_ptr);
void ExecSetCmdAndArgs(HandleExec* exec, const char* cmd, const char** args);
void ExecSetEnvVar(HandleExec* exec, const char** envp);
BOOL ExecHasFakeExit(HandleExec* exec);
void ExecSetFakeExit(HandleExec* exec, int ExitCode);
int ExecDoSpawn(HandleExec* exec);
#endif


#ifdef WLB_FUNC_NOOPS
int fchmod(int fd, mode_t mode);
unsigned int alarm(unsigned int seconds);
pid_t getpgrp(pid_t pid);
pid_t getppid(void);
#endif

// #if ! defined(GAWK)
// extern char* getenv2(const char* name);
// #undef getenv
// #define getenv getenv2
// #undef _getenv
// #define _getenv _getenv2
// #undef setenv
// #define setenv setenv2
// #undef putenv
// #define putenv putenv2
// #undef unsetenv
// #define unsetenv unsetenv2

// #endif



#ifdef WLB_PROC_SIG_EXITS
#ifndef WIFEXITED
#define WIFEXITED(w)    (((w) & 0xff) == 0)
#endif
#ifndef WIFSIGNALED
#define WIFSIGNALED(w)  (((w) & 0x7f) > 0 && (((w) & 0x7f) < 0x7f))
#endif
#ifndef WIFSTOPPED
#define WIFSTOPPED(w)   (((w) & 0xff) == 0x7f)
#endif
#ifndef WEXITSTATUS
#define WEXITSTATUS(w)  (((w) >> 8) & 0xff)
#endif
#ifndef WTERMSIG
#define WTERMSIG(w)     ((w) & 0x7f)
#endif
#ifndef WSTOPSIG
#define WSTOPSIG        WEXITSTATUS
#endif
pid_t wait(int* wstatus);
int kill(pid_t pid, int sig);
#endif


#endif
