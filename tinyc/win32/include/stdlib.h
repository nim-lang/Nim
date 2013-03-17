/*
 * stdlib.h
 *
 * Definitions for common types, variables, and functions.
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

#ifndef _STDLIB_H_
#define _STDLIB_H_

/* All the headers include this file. */
#include <_mingw.h>


#define __need_size_t
#define __need_wchar_t
#define __need_NULL
#ifndef RC_INVOKED
#include <stddef.h>
#endif /* RC_INVOKED */

/*
 * RAND_MAX is the maximum value that may be returned by rand.
 * The minimum is zero.
 */
#define	RAND_MAX	0x7FFF

/*
 * These values may be used as exit status codes.
 */
#define	EXIT_SUCCESS	0
#define	EXIT_FAILURE	1

/*
 * Definitions for path name functions.
 * NOTE: All of these values have simply been chosen to be conservatively high.
 *       Remember that with long file names we can no longer depend on
 *       extensions being short.
 */
#ifndef __STRICT_ANSI__

#ifndef MAX_PATH
#define	MAX_PATH	(260)
#endif

#define	_MAX_PATH	MAX_PATH
#define	_MAX_DRIVE	(3)
#define	_MAX_DIR	256
#define	_MAX_FNAME	256
#define	_MAX_EXT	256

#endif	/* Not __STRICT_ANSI__ */


#ifndef RC_INVOKED

#ifdef __cplusplus
extern "C" {
#endif

/*
 * This seems like a convenient place to declare these variables, which
 * give programs using WinMain (or main for that matter) access to main-ish
 * argc and argv. environ is a pointer to a table of environment variables.
 * NOTE: Strings in _argv and environ are ANSI strings.
 */
extern int	_argc;
extern char**	_argv;

/* imports from runtime dll of the above variables */
#ifdef __MSVCRT__

extern int*     __p___argc(void);
extern char***   __p___argv(void);
extern wchar_t***   __p___wargv(void);

#define __argc (*__p___argc())
#define __argv (*__p___argv())
#define __wargv (*__p___wargv())

#else /* !MSVCRT */

#ifndef __DECLSPEC_SUPPORTED

extern int*    __imp___argc_dll;
extern char***  __imp___argv_dll;
#define __argc (*__imp___argc_dll)
#define __argv (*__imp___argv_dll)

#else /* __DECLSPEC_SUPPORTED */

__MINGW_IMPORT int    __argc_dll;
__MINGW_IMPORT char**  __argv_dll;
#define __argc __argc_dll
#define __argv __argv_dll

#endif /* __DECLSPEC_SUPPORTED */

#endif /* __MSVCRT */

/*
 * Also defined in ctype.h.
 */

#ifndef MB_CUR_MAX
# ifdef __MSVCRT__
#  define MB_CUR_MAX __mb_cur_max
   __MINGW_IMPORT int __mb_cur_max;
# else /* not __MSVCRT */
#  define MB_CUR_MAX __mb_cur_max_dll
   __MINGW_IMPORT int __mb_cur_max_dll;
# endif /* not __MSVCRT */
#endif  /* MB_CUR_MAX */

/* 
 * MS likes to declare errno in stdlib.h as well. 
 */

#ifdef _UWIN
#undef errno
extern int errno;
#else
int*	_errno(void);
#define	errno		(*_errno())
#endif
int*	__doserrno(void);
#define	_doserrno	(*__doserrno())

/*
 * Use environ from the DLL, not as a global. 
 */

#ifdef __MSVCRT__
  extern char *** __p__environ(void);
  extern wchar_t *** __p__wenviron(void);
# define _environ (*__p__environ())
# define _wenviron (*__p__wenviron())
#else /* ! __MSVCRT__ */
# ifndef __DECLSPEC_SUPPORTED
    extern char *** __imp__environ_dll;
#   define _environ (*__imp__environ_dll)
# else /* __DECLSPEC_SUPPORTED */
    __MINGW_IMPORT char ** _environ_dll;
#   define _environ _environ_dll
# endif /* __DECLSPEC_SUPPORTED */
#endif /* ! __MSVCRT__ */

#define environ _environ

#ifdef	__MSVCRT__
/* One of the MSVCRTxx libraries */

#ifndef __DECLSPEC_SUPPORTED
  extern int*	__imp__sys_nerr;
# define	sys_nerr	(*__imp__sys_nerr)
#else /* __DECLSPEC_SUPPORTED */
  __MINGW_IMPORT int	_sys_nerr;
# ifndef _UWIN
#   define	sys_nerr	_sys_nerr
# endif /* _UWIN */
#endif /* __DECLSPEC_SUPPORTED */

#else /* ! __MSVCRT__ */

/* CRTDLL run time library */

#ifndef __DECLSPEC_SUPPORTED
  extern int*	__imp__sys_nerr_dll;
# define sys_nerr	(*__imp__sys_nerr_dll)
#else /* __DECLSPEC_SUPPORTED */
  __MINGW_IMPORT int	_sys_nerr_dll;
# define sys_nerr	_sys_nerr_dll
#endif /* __DECLSPEC_SUPPORTED */

#endif /* ! __MSVCRT__ */

#ifndef __DECLSPEC_SUPPORTED
extern char***	__imp__sys_errlist;
#define	sys_errlist	(*__imp__sys_errlist)
#else /* __DECLSPEC_SUPPORTED */
__MINGW_IMPORT char*	_sys_errlist[];
#ifndef _UWIN
#define	sys_errlist	_sys_errlist
#endif /* _UWIN */
#endif /* __DECLSPEC_SUPPORTED */

/*
 * OS version and such constants.
 */
#ifndef __STRICT_ANSI__

#ifdef	__MSVCRT__
/* msvcrtxx.dll */

extern unsigned int*	__p__osver(void);
extern unsigned int*	__p__winver(void);
extern unsigned int*	__p__winmajor(void);
extern unsigned int*	__p__winminor(void);

#define _osver		(*__p__osver())
#define _winver		(*__p__winver())
#define _winmajor	(*__p__winmajor())
#define _winminor	(*__p__winminor())

#else
/* Not msvcrtxx.dll, thus crtdll.dll */

#ifndef __DECLSPEC_SUPPORTED

extern unsigned int*	_imp___osver_dll;
extern unsigned int*	_imp___winver_dll;
extern unsigned int*	_imp___winmajor_dll;
extern unsigned int*	_imp___winminor_dll;

#define _osver		(*_imp___osver_dll)
#define _winver		(*_imp___winver_dll)
#define _winmajor	(*_imp___winmajor_dll)
#define _winminor	(*_imp___winminor_dll)

#else /* __DECLSPEC_SUPPORTED */

__MINGW_IMPORT unsigned int	_osver_dll;
__MINGW_IMPORT unsigned int	_winver_dll;
__MINGW_IMPORT unsigned int	_winmajor_dll;
__MINGW_IMPORT unsigned int	_winminor_dll;

#define _osver		_osver_dll
#define _winver		_winver_dll
#define _winmajor	_winmajor_dll
#define _winminor	_winminor_dll

#endif /* __DECLSPEC_SUPPORTED */

#endif

#if defined  __MSVCRT__
/* although the _pgmptr is exported as DATA,
 * be safe and use the access function __p__pgmptr() to get it. */
char**  __p__pgmptr(void);
#define _pgmptr     (*__p__pgmptr())
wchar_t**  __p__wpgmptr(void);
#define _wpgmptr    (*__p__wpgmptr())
#else /* ! __MSVCRT__ */
# ifndef __DECLSPEC_SUPPORTED
  extern char** __imp__pgmptr_dll;
# define _pgmptr (*__imp__pgmptr_dll)
# else /* __DECLSPEC_SUPPORTED */
 __MINGW_IMPORT char* _pgmptr_dll;
# define _pgmptr _pgmptr_dll
# endif /* __DECLSPEC_SUPPORTED */
/* no wide version in CRTDLL */
#endif /* __MSVCRT__ */

#endif /* Not __STRICT_ANSI__ */

#ifdef	__GNUC__
#define	_ATTRIB_NORETURN	__attribute__ ((noreturn))
#else	/* Not __GNUC__ */
#define	_ATTRIB_NORETURN
#endif	/* __GNUC__ */

double	atof	(const char*);
int	atoi	(const char*);
long	atol	(const char*);
int	_wtoi (const wchar_t *);
long _wtol (const wchar_t *);

double	strtod	(const char*, char**);
#if !defined __NO_ISOCEXT  /* extern stubs in static libmingwex.a */
extern __inline__ float strtof (const char *nptr, char **endptr)
  { return (strtod (nptr, endptr));}
#endif /* __NO_ISOCEXT */

long	strtol	(const char*, char**, int);
unsigned long	strtoul	(const char*, char**, int);

#ifndef _WSTDLIB_DEFINED
/*  also declared in wchar.h */
double	wcstod	(const wchar_t*, wchar_t**);
#if !defined __NO_ISOCEXT /* extern stub in static libmingwex.a */
extern __inline__ float wcstof( const wchar_t *nptr, wchar_t **endptr)
{  return (wcstod(nptr, endptr)); }
#endif /* __NO_ISOCEXT */

long	wcstol	(const wchar_t*, wchar_t**, int);
unsigned long	wcstoul (const wchar_t*, wchar_t**, int);
#define _WSTDLIB_DEFINED
#endif

size_t	wcstombs	(char*, const wchar_t*, size_t);
int	wctomb		(char*, wchar_t);

int	mblen		(const char*, size_t);
size_t	mbstowcs	(wchar_t*, const char*, size_t);
int	mbtowc		(wchar_t*, const char*, size_t);

int	rand	(void);
void	srand	(unsigned int);

void*	calloc	(size_t, size_t);
void*	malloc	(size_t);
void*	realloc	(void*, size_t);
void	free	(void*);

void	abort	(void) _ATTRIB_NORETURN;
void	exit	(int) _ATTRIB_NORETURN;
int	atexit	(void (*)(void));

int	system	(const char*);
char*	getenv	(const char*);

void*	bsearch	(const void*, const void*, size_t, size_t, 
                 int (*)(const void*, const void*));
void	qsort	(const void*, size_t, size_t,
                 int (*)(const void*, const void*));

int	abs	(int);
long	labs	(long);

/*
 * div_t and ldiv_t are structures used to return the results of div and
 * ldiv.
 *
 * NOTE: div and ldiv appear not to work correctly unless
 *       -fno-pcc-struct-return is specified. This is included in the
 *       mingw32 specs file.
 */
typedef struct { int quot, rem; } div_t;
typedef struct { long quot, rem; } ldiv_t;

div_t	div	(int, int);
ldiv_t	ldiv	(long, long);

#ifndef	__STRICT_ANSI__

/*
 * NOTE: Officially the three following functions are obsolete. The Win32 API
 *       functions SetErrorMode, Beep and Sleep are their replacements.
 */
void	_beep (unsigned int, unsigned int);
void	_seterrormode (int);
void	_sleep (unsigned long);

void	_exit	(int) _ATTRIB_NORETURN;
#if !defined __NO_ISOCEXT /* extern stub in static libmingwex.a */
/* C99 function name */
void _Exit(int) _ATTRIB_NORETURN; /* Declare to get noreturn attribute.  */
extern __inline__ void _Exit(int status)
	{  _exit(status); }
#endif
/* _onexit is MS extension. Use atexit for portability.  */
typedef  int (* _onexit_t)(void); 
_onexit_t _onexit( _onexit_t );

int	_putenv	(const char*);
void	_searchenv (const char*, const char*, char*);


char*	_ecvt (double, int, int*, int*);
char*	_fcvt (double, int, int*, int*);
char*	_gcvt (double, int, char*);

void	_makepath (char*, const char*, const char*, const char*, const char*);
void	_splitpath (const char*, char*, char*, char*, char*);
char*	_fullpath (char*, const char*, size_t);


char*	_itoa (int, char*, int);
char*	_ltoa (long, char*, int);
char*   _ultoa(unsigned long, char*, int);
wchar_t*  _itow (int, wchar_t*, int);
wchar_t*  _ltow (long, wchar_t*, int);
wchar_t*  _ultow (unsigned long, wchar_t*, int);

#ifdef __MSVCRT__
__int64	_atoi64(const char *);
char*	_i64toa(__int64, char *, int);
char*	_ui64toa(unsigned __int64, char *, int);
__int64	_wtoi64(const wchar_t *);
wchar_t* _i64tow(__int64, wchar_t *, int);
wchar_t* _ui64tow(unsigned __int64, wchar_t *, int);

wchar_t* _wgetenv(const wchar_t*);
int	 _wputenv(const wchar_t*);
void	_wsearchenv(const wchar_t*, const wchar_t*, wchar_t*);
void    _wmakepath(wchar_t*, const wchar_t*, const wchar_t*, const wchar_t*, const wchar_t*);
void	_wsplitpath (const wchar_t*, wchar_t*, wchar_t*, wchar_t*, wchar_t*);
wchar_t*    _wfullpath (wchar_t*, const wchar_t*, size_t);
#endif

#ifndef	_NO_OLDNAMES

int	putenv (const char*);
void	searchenv (const char*, const char*, char*);

char*	itoa (int, char*, int);
char*	ltoa (long, char*, int);

#ifndef _UWIN
char*	ecvt (double, int, int*, int*);
char*	fcvt (double, int, int*, int*);
char*	gcvt (double, int, char*);
#endif /* _UWIN */
#endif	/* Not _NO_OLDNAMES */

#endif	/* Not __STRICT_ANSI__ */

/* C99 names */

#if !defined __NO_ISOCEXT /* externs in static libmingwex.a */

typedef struct { long long quot, rem; } lldiv_t;

lldiv_t	lldiv (long long, long long);

extern __inline__ long long llabs(long long _j)
  {return (_j >= 0 ? _j : -_j);}

long long strtoll (const char* __restrict__, char** __restrict, int);
unsigned long long strtoull (const char* __restrict__, char** __restrict__, int);

#if defined (__MSVCRT__) /* these are stubs for MS _i64 versions */ 
long long atoll (const char *);

#if !defined (__STRICT_ANSI__)
long long wtoll(const wchar_t *);
char* lltoa(long long, char *, int);
char* ulltoa(unsigned long long , char *, int);
wchar_t* lltow(long long, wchar_t *, int);
wchar_t* ulltow(unsigned long long, wchar_t *, int);

  /* inline using non-ansi functions */
extern __inline__ long long atoll (const char * _c)
	{ return _atoi64 (_c); }
extern __inline__ char* lltoa(long long _n, char * _c, int _i)
	{ return _i64toa (_n, _c, _i); }
extern __inline__ char* ulltoa(unsigned long long _n, char * _c, int _i)
	{ return _ui64toa (_n, _c, _i); }
extern __inline__ long long wtoll(const wchar_t * _w)
 	{ return _wtoi64 (_w); }
extern __inline__ wchar_t* lltow(long long _n, wchar_t * _w, int _i)
	{ return _i64tow (_n, _w, _i); } 
extern __inline__ wchar_t* ulltow(unsigned long long _n, wchar_t * _w, int _i)
	{ return _ui64tow (_n, _w, _i); } 
#endif /* (__STRICT_ANSI__)  */

#endif /* __MSVCRT__ */

#endif /* !__NO_ISOCEXT */

/*
 * Undefine the no return attribute used in some function definitions
 */
#undef	_ATTRIB_NORETURN

#ifdef __cplusplus
}
#endif

#endif	/* Not RC_INVOKED */

#endif	/* Not _STDLIB_H_ */

