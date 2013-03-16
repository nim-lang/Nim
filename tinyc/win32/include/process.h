/* 
 * process.h
 *
 * Function calls for spawning child processes.
 *
 * This file is part of the Mingw32 package.
 *
 * Contributors:
 *  Created by Colin Peters <colin@bird.fu.is.saga-u.ac.jp>
 *
 *  THIS SOFTWARE IS NOT COPYRIGHTED
 *
 *  This source code is offered for use in the public domain. You may
 *  use, modify or distribute it freely.
 *
 *  This code is distributed in the hope that it will be useful but
 *  WITHOUT ANY WARRANTY. ALL WARRANTIES, EXPRESS OR IMPLIED ARE HEREBY
 *  DISCLAIMED. This includes but is not limited to warranties of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * $Revision: 1.2 $
 * $Author: bellard $
 * $Date: 2005/04/17 13:14:29 $
 *
 */

#ifndef	__STRICT_ANSI__

#ifndef	_PROCESS_H_
#define	_PROCESS_H_

/* All the headers include this file. */
#include <_mingw.h>

/* Includes a definition of _pid_t and pid_t */
#include <sys/types.h>

/*
 * Constants for cwait actions.
 * Obsolete for Win32.
 */
#define	_WAIT_CHILD		0
#define	_WAIT_GRANDCHILD	1

#ifndef	_NO_OLDNAMES
#define	WAIT_CHILD		_WAIT_CHILD
#define	WAIT_GRANDCHILD		_WAIT_GRANDCHILD
#endif	/* Not _NO_OLDNAMES */

/*
 * Mode constants for spawn functions.
 */
#define	_P_WAIT		0
#define	_P_NOWAIT	1
#define	_P_OVERLAY	2
#define	_OLD_P_OVERLAY	_P_OVERLAY
#define	_P_NOWAITO	3
#define	_P_DETACH	4

#ifndef	_NO_OLDNAMES
#define	P_WAIT		_P_WAIT
#define	P_NOWAIT	_P_NOWAIT
#define	P_OVERLAY	_P_OVERLAY
#define	OLD_P_OVERLAY	_OLD_P_OVERLAY
#define	P_NOWAITO	_P_NOWAITO
#define	P_DETACH	_P_DETACH
#endif	/* Not _NO_OLDNAMES */


#ifndef RC_INVOKED

#ifdef	__cplusplus
extern "C" {
#endif

void	_cexit(void);
void	_c_exit(void);

int	_cwait (int*, _pid_t, int);

_pid_t	_getpid(void);

int	_execl		(const char*, const char*, ...);
int	_execle		(const char*, const char*, ...);
int	_execlp		(const char*, const char*, ...);
int	_execlpe	(const char*, const char*, ...);
int	_execv		(const char*, char* const*);
int	_execve		(const char*, char* const*, char* const*);
int	_execvp		(const char*, char* const*);
int	_execvpe	(const char*, char* const*, char* const*);

int	_spawnl		(int, const char*, const char*, ...);
int	_spawnle	(int, const char*, const char*, ...);
int	_spawnlp	(int, const char*, const char*, ...);
int	_spawnlpe	(int, const char*, const char*, ...);
int	_spawnv		(int, const char*, char* const*);
int	_spawnve	(int, const char*, char* const*, char* const*);
int	_spawnvp	(int, const char*, char* const*);
int	_spawnvpe	(int, const char*, char* const*, char* const*);

/*
 * The functions _beginthreadex and _endthreadex are not provided by CRTDLL.
 * They are provided by MSVCRT.
 *
 * NOTE: Apparently _endthread calls CloseHandle on the handle of the thread,
 * making for race conditions if you are not careful. Basically you have to
 * make sure that no-one is going to do *anything* with the thread handle
 * after the thread calls _endthread or returns from the thread function.
 *
 * NOTE: No old names for these functions. Use the underscore.
 */
unsigned long
	_beginthread	(void (*)(void *), unsigned, void*);
void	_endthread	(void);

#ifdef	__MSVCRT__
unsigned long
	_beginthreadex	(void *, unsigned, unsigned (__stdcall *) (void *), 
			 void*, unsigned, unsigned*);
void	_endthreadex	(unsigned);
#endif


#ifndef	_NO_OLDNAMES
/*
 * Functions without the leading underscore, for portability. These functions
 * live in liboldnames.a.
 */
int	cwait (int*, pid_t, int);
pid_t	getpid (void);
int	execl (const char*, const char*, ...);
int	execle (const char*, const char*, ...);
int	execlp (const char*, const char*, ...);
int	execlpe (const char*, const char*, ...);
int	execv (const char*, char* const*);
int	execve (const char*, char* const*, char* const*);
int	execvp (const char*, char* const*);
int	execvpe (const char*, char* const*, char* const*);
int	spawnl (int, const char*, const char*, ...);
int	spawnle (int, const char*, const char*, ...);
int	spawnlp (int, const char*, const char*, ...);
int	spawnlpe (int, const char*, const char*, ...);
int	spawnv (int, const char*, char* const*);
int	spawnve (int, const char*, char* const*, char* const*);
int	spawnvp (int, const char*, char* const*);
int	spawnvpe (int, const char*, char* const*, char* const*);
#endif	/* Not _NO_OLDNAMES */

#ifdef	__cplusplus
}
#endif

#endif	/* Not RC_INVOKED */

#endif	/* _PROCESS_H_ not defined */

#endif	/* Not __STRICT_ANSI__ */

