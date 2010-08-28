/* 
 * io.h
 *
 * System level I/O functions and types.
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

#ifndef	_IO_H_
#define	_IO_H_

/* All the headers include this file. */
#include <_mingw.h>

/* We need the definition of FILE anyway... */
#include <stdio.h>

/* MSVC's io.h contains the stuff from dir.h, so I will too.
 * NOTE: This also defines off_t, the file offset type, through
 *       an inclusion of sys/types.h */
#ifndef __STRICT_ANSI__

#include <sys/types.h>	/* To get time_t. */

/*
 * Attributes of files as returned by _findfirst et al.
 */
#define	_A_NORMAL	0x00000000
#define	_A_RDONLY	0x00000001
#define	_A_HIDDEN	0x00000002
#define	_A_SYSTEM	0x00000004
#define	_A_VOLID	0x00000008
#define	_A_SUBDIR	0x00000010
#define	_A_ARCH		0x00000020


#ifndef RC_INVOKED

#ifndef	_FSIZE_T_DEFINED
typedef	unsigned long	_fsize_t;
#define _FSIZE_T_DEFINED
#endif

/*
 * The following structure is filled in by _findfirst or _findnext when
 * they succeed in finding a match.
 */
struct _finddata_t
{
	unsigned	attrib;		/* Attributes, see constants above. */
	time_t		time_create;
	time_t		time_access;	/* always midnight local time */
	time_t		time_write;
	_fsize_t	size;
	char		name[FILENAME_MAX];	/* may include spaces. */
};

struct _finddatai64_t {
    unsigned    attrib;
    time_t      time_create;
    time_t      time_access;
    time_t      time_write;
    __int64     size;
    char        name[FILENAME_MAX];
};


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

#ifdef	__cplusplus
extern "C" {
#endif

/*
 * Functions for searching for files. _findfirst returns -1 if no match
 * is found. Otherwise it returns a handle to be used in _findnext and
 * _findclose calls. _findnext also returns -1 if no match could be found,
 * and 0 if a match was found. Call _findclose when you are finished.
 */
int	_findfirst (const char*, struct _finddata_t*);
int	_findnext (int, struct _finddata_t*);
int	_findclose (int);

int	_chdir (const char*);
char*	_getcwd (char*, int);
int	_mkdir (const char*);
char*	_mktemp (char*);
int	_rmdir (const char*);


#ifdef __MSVCRT__
__int64  _filelengthi64(int);
long _findfirsti64(const char*, struct _finddatai64_t*);
int _findnexti64(long, struct _finddatai64_t*);
__int64  _lseeki64(int, __int64, int);
__int64  _telli64(int);
#endif /* __MSVCRT__ */


#ifndef _NO_OLDNAMES

#ifndef _UWIN
int	chdir (const char*);
char*	getcwd (char*, int);
int	mkdir (const char*);
char*	mktemp (char*);
int	rmdir (const char*);
#endif /* _UWIN */

#endif /* Not _NO_OLDNAMES */

#ifdef	__cplusplus
}
#endif

#endif	/* Not RC_INVOKED */

#endif	/* Not __STRICT_ANSI__ */

/* TODO: Maximum number of open handles has not been tested, I just set
 * it the same as FOPEN_MAX. */
#define	HANDLE_MAX	FOPEN_MAX


/* Some defines for _access nAccessMode (MS doesn't define them, but
 * it doesn't seem to hurt to add them). */
#define	F_OK	0	/* Check for file existence */
#define	X_OK	1	/* Check for execute permission. */
#define	W_OK	2	/* Check for write permission */
#define	R_OK	4	/* Check for read permission */

#ifndef RC_INVOKED

#ifdef	__cplusplus
extern "C" {
#endif

int		_access (const char*, int);
int		_chsize (int, long);
int		_close (int);
int		_commit(int);

/* NOTE: The only significant bit in unPermissions appears to be bit 7 (0x80),
 *       the "owner write permission" bit (on FAT). */
int		_creat (const char*, unsigned);

int		_dup (int);
int		_dup2 (int, int);
long		_filelength (int);
int		_fileno (FILE*);
long		_get_osfhandle (int);
int		_isatty (int);

/* In a very odd turn of events this function is excluded from those
 * files which define _STREAM_COMPAT. This is required in order to
 * build GNU libio because of a conflict with _eof in streambuf.h
 * line 107. Actually I might just be able to change the name of
 * the enum member in streambuf.h... we'll see. TODO */
#ifndef	_STREAM_COMPAT
int		_eof (int);
#endif

/* LK_... locking commands defined in sys/locking.h. */
int		_locking (int, int, long);

long		_lseek (int, long, int);

/* Optional third argument is unsigned unPermissions. */
int		_open (const char*, int, ...);

int		_open_osfhandle (long, int);
int		_pipe (int *, unsigned int, int);
int		_read (int, void*, unsigned int);

/* SH_... flags for nShFlags defined in share.h
 * Optional fourth argument is unsigned unPermissions */
int		_sopen (const char*, int, int, ...);

long		_tell (int);
/* Should umask be in sys/stat.h and/or sys/types.h instead? */
int		_umask (int);
int		_unlink (const char*);
int		_write (int, const void*, unsigned int);

/* Wide character versions. Also declared in wchar.h. */
/* Not in crtdll.dll */
#if !defined (_WIO_DEFINED)
#if defined (__MSVCRT__)
int 		_waccess(const wchar_t*, int);
int 		_wchmod(const wchar_t*, int);
int 		_wcreat(const wchar_t*, int);
long 		_wfindfirst(wchar_t*, struct _wfinddata_t*);
int 		_wfindnext(long, struct _wfinddata_t *);
int 		_wunlink(const wchar_t*);
int 		_wopen(const wchar_t*, int, ...);
int 		_wsopen(const wchar_t*, int, int, ...);
wchar_t * 	_wmktemp(wchar_t*);
long  _wfindfirsti64(const wchar_t*, struct _wfinddatai64_t*);
int  _wfindnexti64(long, struct _wfinddatai64_t*);
#endif /* defined (__MSVCRT__) */
#define _WIO_DEFINED
#endif /* _WIO_DEFINED */

#ifndef	_NO_OLDNAMES
/*
 * Non-underscored versions of non-ANSI functions to improve portability.
 * These functions live in libmoldname.a.
 */

#ifndef _UWIN
int		access (const char*, int);
int		chsize (int, long );
int		close (int);
int		creat (const char*, int);
int		dup (int);
int		dup2 (int, int);
int		eof (int);
long		filelength (int);
int		fileno (FILE*);
int		isatty (int);
long		lseek (int, long, int);
int		open (const char*, int, ...);
int		read (int, void*, unsigned int);
int		sopen (const char*, int, int, ...);
long		tell (int);
int		umask (int);
int		unlink (const char*);
int		write (int, const void*, unsigned int);
#endif /* _UWIN */

/* Wide character versions. Also declared in wchar.h. */
/* Where do these live? Not in libmoldname.a nor in libmsvcrt.a */
#if 0
int 		waccess(const wchar_t *, int);
int 		wchmod(const wchar_t *, int);
int 		wcreat(const wchar_t *, int);
long 		wfindfirst(wchar_t *, struct _wfinddata_t *);
int 		wfindnext(long, struct _wfinddata_t *);
int 		wunlink(const wchar_t *);
int 		wrename(const wchar_t *, const wchar_t *);
int 		wopen(const wchar_t *, int, ...);
int 		wsopen(const wchar_t *, int, int, ...);
wchar_t * 	wmktemp(wchar_t *);
#endif

#endif	/* Not _NO_OLDNAMES */

#ifdef	__cplusplus
}
#endif

#endif	/* Not RC_INVOKED */

#endif	/* _IO_H_ not defined */

#endif	/* Not strict ANSI */

