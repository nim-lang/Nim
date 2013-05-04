/*
 * dos.h
 *
 * DOS-specific functions and structures.
 *
 * This file is part of the Mingw32 package.
 *
 * Contributors:
 *  Created by J.J. van der Heijden <J.J.vanderHeijden@student.utwente.nl>
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

#ifndef	_DOS_H_
#define	_DOS_H_

/* All the headers include this file. */
#include <_mingw.h>

#define __need_wchar_t
#ifndef RC_INVOKED
#include <stddef.h>
#endif	/* Not RC_INVOKED */

/* For DOS file attributes */
#include <io.h>

#ifndef RC_INVOKED

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __MSVCRT__ /* these are in CRTDLL, but not MSVCRT */
#ifndef __DECLSPEC_SUPPORTED
extern unsigned int *__imp__basemajor_dll;
extern unsigned int *__imp__baseminor_dll;
extern unsigned int *__imp__baseversion_dll;
extern unsigned int *__imp__osmajor_dll;
extern unsigned int *__imp__osminor_dll;
extern unsigned int *__imp__osmode_dll;

#define _basemajor (*__imp__basemajor_dll)
#define _baseminor (*__imp__baseminor_dll)
#define _baseversion (*__imp__baseversion_dll)
#define _osmajor (*__imp__osmajor_dll)
#define _osminor (*__imp__osminor_dll)
#define _osmode (*__imp__osmode_dll)

#else /* __DECLSPEC_SUPPORTED */

__MINGW_IMPORT unsigned int _basemajor_dll;
__MINGW_IMPORT unsigned int _baseminor_dll;
__MINGW_IMPORT unsigned int _baseversion_dll;
__MINGW_IMPORT unsigned int _osmajor_dll;
__MINGW_IMPORT unsigned int _osminor_dll;
__MINGW_IMPORT unsigned int _osmode_dll;

#define _basemajor _basemajor_dll
#define _baseminor _baseminor_dll
#define _baseversion _baseversion_dll
#define _osmajor _osmajor_dll
#define _osminor _osminor_dll
#define _osmode _osmode_dll

#endif /* __DECLSPEC_SUPPORTED */
#endif /* ! __MSVCRT__ */

#ifndef _DISKFREE_T_DEFINED
/* needed by _getdiskfree (also in direct.h) */
struct _diskfree_t {
	unsigned total_clusters;
	unsigned avail_clusters;
	unsigned sectors_per_cluster;
	unsigned bytes_per_sector;
};
#define _DISKFREE_T_DEFINED
#endif  

unsigned _getdiskfree (unsigned, struct _diskfree_t *);

#ifndef	_NO_OLDNAMES
# define diskfree_t _diskfree_t
#endif

#ifdef __cplusplus
}
#endif

#endif	/* Not RC_INVOKED */

#endif	/* Not _DOS_H_ */

#endif	/* Not __STRICT_ANSI__ */

