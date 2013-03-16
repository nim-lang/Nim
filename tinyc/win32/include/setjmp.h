/* 
 * setjmp.h
 *
 * Declarations supporting setjmp and longjump, a method for avoiding
 * the normal function call return sequence. (Bleah!)
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

#ifndef _SETJMP_H_
#define _SETJMP_H_

/* All the headers include this file. */
#include <_mingw.h>

#ifndef RC_INVOKED

#ifdef __cplusplus
extern "C" {
#endif

/*
 * The buffer used by setjmp to store the information used by longjmp
 * to perform it's evil goto-like work. The size of this buffer was
 * determined through experimentation; it's contents are a mystery.
 * NOTE: This was determined on an i386 (actually a Pentium). The
 *       contents could be different on an Alpha or something else.
 */
#define _JBLEN 16
#define _JBTYPE int
typedef _JBTYPE jmp_buf[_JBLEN];

/*
 * The function provided by CRTDLL which appears to do the actual work
 * of setjmp.
 */
int	_setjmp (jmp_buf);

#define	setjmp(x)	_setjmp(x)

/*
 * Return to the last setjmp call and act as if setjmp had returned
 * nVal (which had better be non-zero!).
 */
void	longjmp (jmp_buf, int);

#ifdef __cplusplus
}
#endif

#endif	/* Not RC_INVOKED */

#endif	/* Not _SETJMP_H_ */

