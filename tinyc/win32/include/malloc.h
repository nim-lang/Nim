/*
 * malloc.h
 *
 * Support for programs which want to use malloc.h to get memory management
 * functions. Unless you absolutely need some of these functions and they are
 * not in the ANSI headers you should use the ANSI standard header files
 * instead.
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

#ifndef _MALLOC_H_
#define _MALLOC_H_

/* All the headers include this file. */
#include <_mingw.h>

#include <stdlib.h>

#ifndef RC_INVOKED

/*
 * The structure used to walk through the heap with _heapwalk.
 */
typedef	struct _heapinfo
{
	int*	_pentry;
	size_t	_size;
	int	_useflag;
} _HEAPINFO;

/* Values for _heapinfo.useflag */
#define _USEDENTRY 0
#define _FREEENTRY 1

#ifdef	__cplusplus
extern "C" {
#endif
/*
   The _heap* memory allocation functions are supported on NT
   but not W9x. On latter, they always set errno to ENOSYS.
*/
int	_heapwalk (_HEAPINFO*);

#ifndef	_NO_OLDNAMES
int	heapwalk (_HEAPINFO*);
#endif	/* Not _NO_OLDNAMES */

int	_heapchk (void);	/* Verify heap integrety. */
int	_heapmin (void);	/* Return unused heap to the OS. */
int	_heapset (unsigned int);

size_t	_msize (void*);
size_t	_get_sbh_threshold (void); 
int	_set_sbh_threshold (size_t);
void *	_expand (void*, size_t); 

#ifdef __cplusplus
}
#endif

#endif	/* RC_INVOKED */

#endif /* Not _MALLOC_H_ */

#endif /* Not __STRICT_ANSI__ */

