/*
 * utime.h
 *
 * Support for the utime function.
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

#ifndef	_UTIME_H_
#define	_UTIME_H_

/* All the headers include this file. */
#include <_mingw.h>

#define __need_wchar_t
#define __need_size_t
#ifndef RC_INVOKED
#include <stddef.h>
#endif	/* Not RC_INVOKED */
#include <sys/types.h>

#ifndef	RC_INVOKED

/*
 * Structure used by _utime function.
 */
struct _utimbuf
{
	time_t	actime;		/* Access time */
	time_t	modtime;	/* Modification time */
};


#ifndef	_NO_OLDNAMES
/* NOTE: Must be the same as _utimbuf above. */
struct utimbuf
{
	time_t	actime;
	time_t	modtime;
};
#endif	/* Not _NO_OLDNAMES */


#ifdef	__cplusplus
extern "C" {
#endif

int	_utime (const char*, struct _utimbuf*);
int	_futime (int, struct _utimbuf*);

/* The wide character version, only available for MSVCRT versions of the
 * C runtime library. */
#ifdef __MSVCRT__
int	_wutime (const wchar_t*, struct _utimbuf*);
#endif /* MSVCRT runtime */
#ifndef	_NO_OLDNAMES
int	utime (const char*, struct utimbuf*);
#endif	/* Not _NO_OLDNAMES */

#ifdef	__cplusplus
}
#endif

#endif	/* Not RC_INVOKED */

#endif	/* Not _UTIME_H_ */

#endif	/* Not __STRICT_ANSI__ */

