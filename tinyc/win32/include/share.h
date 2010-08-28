/*
 * share.h
 *
 * Constants for file sharing functions.
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

#ifndef	_SHARE_H_
#define	_SHARE_H_

/* All the headers include this file. */
#include <_mingw.h>

#define SH_COMPAT	0x00	/* Compatibility */
#define	SH_DENYRW	0x10	/* Deny read/write */
#define	SH_DENYWR	0x20	/* Deny write */
#define	SH_DENYRD	0x30	/* Deny read */
#define	SH_DENYNO	0x40	/* Deny nothing */

#endif	/* Not _SHARE_H_ */

#endif	/* Not __STRICT_ANSI__ */

