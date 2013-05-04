/*
 * wchar.h
 *
 * Defines of all functions for supporting wide characters. Actually it
 * just includes all those headers, which is not a good thing to do from a
 * processing time point of view, but it does mean that everything will be
 * in sync.
 *
 * This file is part of the Mingw32 package.
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

#ifndef	_WCHAR_H_
#define	_WCHAR_H_

/* All the headers include this file. */
#include <_mingw.h>

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/types.h>

#define __need_size_t
#define __need_wint_t
#define __need_wchar_t
#ifndef RC_INVOKED
#include <stddef.h>
#endif /* Not RC_INVOKED */

#define WCHAR_MIN	0
#define WCHAR_MAX	((wchar_t)-1)

#ifndef RC_INVOKED

#ifdef __cplusplus 
extern "C" {
#endif

#ifndef	__STRICT_ANSI__

#ifndef	_FSIZE_T_DEFINED
typedef	unsigned long	_fsize_t;
#define _FSIZE_T_DEFINED
#endif

#ifndef _WFINDDATA_T_DEFINED
struct _wfinddata_t {
    	unsigned	attrib;
    	time_t		time_create;	/* -1 for FAT file systems */
    	time_t		time_access;	/* -1 for FAT file systems */
    	time_t		time_write;
    	_fsize_t	size;
    	wchar_t		name[FILENAME_MAX];	/* may include spaces. */
};
struct _wfinddatai64_t {
    unsigned    attrib;
    time_t      time_create;
    time_t      time_access;
    time_t      time_write;
    __int64     size;
    wchar_t     name[FILENAME_MAX];
};
#define _WFINDDATA_T_DEFINED
#endif

/* Wide character versions. Also defined in io.h. */
/* CHECK: I believe these only exist in MSVCRT, and not in CRTDLL. Also
   applies to other wide character versions? */
#if !defined (_WIO_DEFINED)
#if defined (__MSVCRT__)
int	 _waccess (const wchar_t*, int);
int	_wchmod (const wchar_t*, int);
int	_wcreat (const wchar_t*, int);
long	_wfindfirst (wchar_t*, struct _wfinddata_t *);
int	_wfindnext (long, struct _wfinddata_t *);
int	_wunlink (const wchar_t*);
int	_wopen (const wchar_t*, int, ...);
int	_wsopen (const wchar_t*, int, int, ...);
wchar_t* _wmktemp (wchar_t*);
long	_wfindfirsti64 (const wchar_t*, struct _wfinddatai64_t*);
int 	_wfindnexti64 (long, struct _wfinddatai64_t*);
#endif /* defined (__MSVCRT__) */
#define _WIO_DEFINED
#endif /* _WIO_DEFINED */

#ifndef _WSTDIO_DEFINED
/* also in stdio.h - keep in sync */
int	fwprintf (FILE*, const wchar_t*, ...);
int	wprintf (const wchar_t*, ...);
int	swprintf (wchar_t*, const wchar_t*, ...);
int	_snwprintf (wchar_t*, size_t, const wchar_t*, ...);
int	vfwprintf (FILE*, const wchar_t*, va_list);
int	vwprintf (const wchar_t*, va_list);
int	vswprintf (wchar_t*, const wchar_t*, va_list);
int	_vsnwprintf (wchar_t*, size_t, const wchar_t*, va_list);
int	fwscanf (FILE*, const wchar_t*, ...);
int	wscanf (const wchar_t*, ...);
int	swscanf (const wchar_t*, const wchar_t*, ...);
wint_t	fgetwc (FILE*);
wint_t	fputwc (wchar_t, FILE*);
wint_t	ungetwc (wchar_t, FILE*);

#ifndef __NO_ISOCEXT  /* externs in libmingwex.a */
int snwprintf(wchar_t* s, size_t n, const wchar_t*  format, ...);
extern inline int vsnwprintf (wchar_t* s, size_t n, const wchar_t* format,
			   va_list arg)
  { return _vsnwprintf ( s, n, format, arg); }
#endif

#ifdef __MSVCRT__ 
wchar_t* fgetws (wchar_t*, int, FILE*);
int	fputws (const wchar_t*, FILE*);
wint_t	getwc (FILE*);
wint_t  getwchar (void);
wchar_t* _getws (wchar_t*);
wint_t	putwc (wint_t, FILE*);
int	_putws (const wchar_t*);
wint_t	putwchar (wint_t);

FILE*	_wfopen (const wchar_t*, const wchar_t*);
FILE*	_wfreopen (const wchar_t*, const wchar_t*, FILE*);
FILE*   _wfsopen (const wchar_t*, const wchar_t*, int);
wchar_t* _wtmpnam (wchar_t*);
wchar_t* _wtempnam (const wchar_t*, const wchar_t*);
int 	_wrename (const wchar_t*, const wchar_t*);
int	_wremove (const wchar_t*)

FILE*	  _wpopen (const wchar_t*, const wchar_t*)
void	  _wperror (const wchar_t*);
#endif	/* __MSVCRT__ */
#define _WSTDIO_DEFINED
#endif /* _WSTDIO_DEFINED */

#ifndef _WDIRECT_DEFINED
/* Also in direct.h */
#ifdef __MSVCRT__ 
int	  _wchdir (const wchar_t*);
wchar_t*  _wgetcwd (wchar_t*, int);
wchar_t*  _wgetdcwd (int, wchar_t*, int);
int	  _wmkdir (const wchar_t*);
int	  _wrmdir (const wchar_t*);
#endif	/* __MSVCRT__ */
#define _WDIRECT_DEFINED
#endif /* _WDIRECT_DEFINED */

#ifndef _STAT_DEFINED
/*
 * The structure manipulated and returned by stat and fstat.
 *
 * NOTE: If called on a directory the values in the time fields are not only
 * invalid, they will cause localtime et. al. to return NULL. And calling
 * asctime with a NULL pointer causes an Invalid Page Fault. So watch it!
 */
struct _stat
{
	_dev_t	st_dev;		/* Equivalent to drive number 0=A 1=B ... */
	_ino_t	st_ino;		/* Always zero ? */
	_mode_t	st_mode;	/* See above constants */
	short	st_nlink;	/* Number of links. */
	short	st_uid;		/* User: Maybe significant on NT ? */
	short	st_gid;		/* Group: Ditto */
	_dev_t	st_rdev;	/* Seems useless (not even filled in) */
	_off_t	st_size;	/* File size in bytes */
	time_t	st_atime;	/* Accessed date (always 00:00 hrs local
				 * on FAT) */
	time_t	st_mtime;	/* Modified time */
	time_t	st_ctime;	/* Creation time */
};

struct stat
{
	_dev_t	st_dev;		/* Equivalent to drive number 0=A 1=B ... */
	_ino_t	st_ino;		/* Always zero ? */
	_mode_t	st_mode;	/* See above constants */
	short	st_nlink;	/* Number of links. */
	short	st_uid;		/* User: Maybe significant on NT ? */
	short	st_gid;		/* Group: Ditto */
	_dev_t	st_rdev;	/* Seems useless (not even filled in) */
	_off_t	st_size;	/* File size in bytes */
	time_t	st_atime;	/* Accessed date (always 00:00 hrs local
				 * on FAT) */
	time_t	st_mtime;	/* Modified time */
	time_t	st_ctime;	/* Creation time */
};
#if defined (__MSVCRT__)
struct _stati64 {
    _dev_t st_dev;
    _ino_t st_ino;
    unsigned short st_mode;
    short st_nlink;
    short st_uid;
    short st_gid;
    _dev_t st_rdev;
    __int64 st_size;
    time_t st_atime;
    time_t st_mtime;
    time_t st_ctime;
    };
#endif  /* __MSVCRT__ */
#define _STAT_DEFINED
#endif /* _STAT_DEFINED */

#if !defined ( _WSTAT_DEFINED)
/* also declared in sys/stat.h */
#if defined __MSVCRT__
int	_wstat (const wchar_t*, struct _stat*);
int	_wstati64 (const wchar_t*, struct _stati64*);
#endif  /* __MSVCRT__ */
#define _WSTAT_DEFINED
#endif /* ! _WSTAT_DEFIND  */

#ifndef _WTIME_DEFINED
#ifdef __MSVCRT__
/* wide function prototypes, also declared in time.h */
wchar_t*	_wasctime (const struct tm*);
wchar_t*	_wctime (const time_t*);
wchar_t*	_wstrdate (wchar_t*);
wchar_t*	_wstrtime (wchar_t*);
#endif /* __MSVCRT__ */
size_t		wcsftime (wchar_t*, size_t, const wchar_t*, const struct tm*);
#define _WTIME_DEFINED
#endif /* _WTIME_DEFINED */ 

#ifndef _WLOCALE_DEFINED  /* also declared in locale.h */
wchar_t* _wsetlocale (int, const wchar_t*);
#define _WLOCALE_DEFINED
#endif

#ifndef _WSTDLIB_DEFINED /* also declared in stdlib.h */
long	wcstol	(const wchar_t*, wchar_t**, int);
unsigned long	wcstoul (const wchar_t*, wchar_t**, int);
double	wcstod	(const wchar_t*, wchar_t**);
#if !defined __NO_ISOCEXT /* extern stub in static libmingwex.a */
extern __inline__ float wcstof( const wchar_t *nptr, wchar_t **endptr)
{  return (wcstod(nptr, endptr)); }
#endif /* __NO_ISOCEXT */
#define  _WSTDLIB_DEFINED
#endif


#ifndef	_NO_OLDNAMES

/* Wide character versions. Also declared in io.h. */
/* CHECK: Are these in the oldnames???  NO! */
#if (0)
int		waccess (const wchar_t *, int);
int		wchmod (const wchar_t *, int);
int		wcreat (const wchar_t *, int);
long		wfindfirst (wchar_t *, struct _wfinddata_t *);
int		wfindnext (long, struct _wfinddata_t *);
int		wunlink (const wchar_t *);
int		wrename (const wchar_t *, const wchar_t *);
int		wremove (const wchar_t *);
int		wopen (const wchar_t *, int, ...);
int		wsopen (const wchar_t *, int, int, ...);
wchar_t*	wmktemp (wchar_t *);
#endif
#endif /* _NO_OLDNAMES */

#endif /* not __STRICT_ANSI__ */

/* These are resolved by -lmsvcp60 */
/* If you don't have msvcp60.dll in your windows system directory, you can
   easily obtain it with a search from your favorite search engine. */
typedef int mbstate_t;
typedef wchar_t _Wint_t;

wint_t  btowc(int);
size_t  mbrlen(const char *, size_t, mbstate_t *);
size_t  mbrtowc(wchar_t *, const char *, size_t, mbstate_t *);
size_t  mbsrtowcs(wchar_t *, const char **, size_t, mbstate_t *);

size_t  wcrtomb(char *, wchar_t, mbstate_t *);
size_t  wcsrtombs(char *, const wchar_t **, size_t, mbstate_t *);
int  	wctob(wint_t);

#ifndef __NO_ISOCEXT /* these need static lib libmingwex.a */
extern inline int fwide(FILE* stream, int mode) {return -1;} /* limited to byte orientation */ 
extern inline int mbsinit(const mbstate_t* ps) {return 1;}
wchar_t* wmemset(wchar_t* s, wchar_t c, size_t n);
wchar_t* wmemchr(const wchar_t* s, wchar_t c, size_t n);
int wmemcmp(const wchar_t* s1, const wchar_t * s2, size_t n);
wchar_t* wmemcpy(wchar_t* __restrict__ s1, const wchar_t* __restrict__ s2,
		 size_t n);
wchar_t* wmemmove(wchar_t* s1, const wchar_t* s2, size_t n);
long long wcstoll(const wchar_t* __restrict__ nptr,
		  wchar_t** __restrict__ endptr, int base);
unsigned long long wcstoull(const wchar_t* __restrict__ nptr,
			    wchar_t ** __restrict__ endptr, int base);

#endif /* __NO_ISOCEXT */


#ifdef __cplusplus
}	/* end of extern "C" */
#endif

#endif /* Not RC_INVOKED */

#endif /* not _WCHAR_H_ */

