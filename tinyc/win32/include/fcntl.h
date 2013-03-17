/*
 * fcntl.h
 *
 * Access constants for _open. Note that the permissions constants are
 * in sys/stat.h (ick).
 *
 * This code is part of the Mingw32 package.
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

#ifndef __STRICT_ANSI__

#ifndef _FCNTL_H_
#define _FCNTL_H_

/* All the headers include this file. */
#include <_mingw.h>

/*
 * It appears that fcntl.h should include io.h for compatibility...
 */
#include <io.h>

/* Specifiy one of these flags to define the access mode. */
#define	_O_RDONLY	0
#define _O_WRONLY	1
#define _O_RDWR		2

/* Mask for access mode bits in the _open flags. */
#define _O_ACCMODE	(_O_RDONLY|_O_WRONLY|_O_RDWR)

#define	_O_APPEND	0x0008	/* Writes will add to the end of the file. */

#define	_O_RANDOM	0x0010
#define	_O_SEQUENTIAL	0x0020
#define	_O_TEMPORARY	0x0040	/* Make the file dissappear after closing.
				 * WARNING: Even if not created by _open! */
#define	_O_NOINHERIT	0x0080

#define	_O_CREAT	0x0100	/* Create the file if it does not exist. */
#define	_O_TRUNC	0x0200	/* Truncate the file if it does exist. */
#define	_O_EXCL		0x0400	/* Open only if the file does not exist. */

/* NOTE: Text is the default even if the given _O_TEXT bit is not on. */
#define	_O_TEXT		0x4000	/* CR-LF in file becomes LF in memory. */
#define	_O_BINARY	0x8000	/* Input and output is not translated. */
#define	_O_RAW		_O_BINARY

#ifndef	_NO_OLDNAMES

/* POSIX/Non-ANSI names for increased portability */
#define	O_RDONLY	_O_RDONLY
#define O_WRONLY	_O_WRONLY
#define O_RDWR		_O_RDWR
#define O_ACCMODE	_O_ACCMODE
#define	O_APPEND	_O_APPEND
#define	O_CREAT		_O_CREAT
#define	O_TRUNC		_O_TRUNC
#define	O_EXCL		_O_EXCL
#define	O_TEXT		_O_TEXT
#define	O_BINARY	_O_BINARY
#define	O_TEMPORARY	_O_TEMPORARY
#define O_NOINHERIT	_O_NOINHERIT
#define O_SEQENTIAL	_O_SEQUENTIAL
#define	O_RANDOM	_O_RANDOM

#endif	/* Not _NO_OLDNAMES */


#ifndef RC_INVOKED

/*
 * This variable determines the default file mode.
 * TODO: Which flags work?
 */
#ifndef __DECLSPEC_SUPPORTED

#ifdef __MSVCRT__
extern unsigned int* __imp__fmode;
#define	_fmode	(*__imp__fmode)
#else
/* CRTDLL */
extern unsigned int* __imp__fmode_dll;
#define	_fmode	(*__imp__fmode_dll)
#endif

#else /* __DECLSPEC_SUPPORTED */

#ifdef __MSVCRT__
__MINGW_IMPORT unsigned int _fmode;
#else /* ! __MSVCRT__ */
__MINGW_IMPORT unsigned int _fmode_dll;
#define	_fmode	_fmode_dll
#endif /* ! __MSVCRT__ */

#endif /* __DECLSPEC_SUPPORTED */


#ifdef	__cplusplus
extern "C" {
#endif

int	_setmode (int, int);

#ifndef	_NO_OLDNAMES
int	setmode (int, int);
#endif	/* Not _NO_OLDNAMES */

#ifdef	__cplusplus
}
#endif

#endif	/* Not RC_INVOKED */

#endif	/* Not _FCNTL_H_ */

#endif	/* Not __STRICT_ANSI__ */

