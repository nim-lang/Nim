/* 
 * assert.h
 *
 * Define the assert macro for debug output.
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

#ifndef _ASSERT_H_
#define	_ASSERT_H_

/* All the headers include this file. */
#include <_mingw.h>

#ifndef RC_INVOKED

#ifdef	__cplusplus
extern "C" {
#endif

#ifdef NDEBUG

/*
 * If not debugging, assert does nothing.
 */
#define assert(x)	((void)0)

#else /* debugging enabled */

/*
 * CRTDLL nicely supplies a function which does the actual output and
 * call to abort.
 */
void	_assert (const char*, const char*, int)
#ifdef	__GNUC__
	__attribute__ ((noreturn))
#endif
	;

/*
 * Definition of the assert macro.
 */
#define assert(e)       ((e) ? (void)0 : _assert(#e, __FILE__, __LINE__))
#endif	/* NDEBUG */

#ifdef	__cplusplus
}
#endif

#endif /* Not RC_INVOKED */

#endif /* Not _ASSERT_H_ */

