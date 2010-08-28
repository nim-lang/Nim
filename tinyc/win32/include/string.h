/*
 * string.h
 *
 * Definitions for memory and string functions.
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

#ifndef _STRING_H_
#define	_STRING_H_

/* All the headers include this file. */
#include <_mingw.h>

/*
 * Define size_t, wchar_t and NULL
 */
#define __need_size_t
#define __need_wchar_t
#define	__need_NULL
#ifndef RC_INVOKED
#include <stddef.h>
#endif	/* Not RC_INVOKED */

#ifndef RC_INVOKED

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Prototypes of the ANSI Standard C library string functions.
 */
void*	memchr (const void*, int, size_t);
int 	memcmp (const void*, const void*, size_t);
void* 	memcpy (void*, const void*, size_t);
void*	memmove (void*, const void*, size_t);
void*	memset (void*, int, size_t);
char*	strcat (char*, const char*);
char*	strchr (const char*, int);
int	strcmp (const char*, const char*);
int	strcoll (const char*, const char*);	/* Compare using locale */
char*	strcpy (char*, const char*);
size_t	strcspn (const char*, const char*);
char*	strerror (int); /* NOTE: NOT an old name wrapper. */
char*	_strerror (const char *);
size_t	strlen (const char*);
char*	strncat (char*, const char*, size_t);
int	strncmp (const char*, const char*, size_t);
char*	strncpy (char*, const char*, size_t);
char*	strpbrk (const char*, const char*);
char*	strrchr (const char*, int);
size_t	strspn (const char*, const char*);
char*	strstr (const char*, const char*);
char*	strtok (char*, const char*);
size_t	strxfrm (char*, const char*, size_t);

#ifndef __STRICT_ANSI__
/*
 * Extra non-ANSI functions provided by the CRTDLL library
 */
void*	_memccpy (void*, const void*, int, size_t);
int 	_memicmp (const void*, const void*, size_t);
char* 	_strdup (const char*);
int	_strcmpi (const char*, const char*);
int	_stricmp (const char*, const char*);
int	_stricoll (const char*, const char*);
char*	_strlwr (char*);
int	_strnicmp (const char*, const char*, size_t);
char*	_strnset (char*, int, size_t);
char*	_strrev (char*);
char*	_strset (char*, int);
char*	_strupr (char*);
void	_swab (const char*, char*, size_t);

/*
 * Multi-byte character functions
 */
unsigned char*	_mbschr (unsigned char*, unsigned char*);
unsigned char*	_mbsncat (unsigned char*, const unsigned char*, size_t);
unsigned char*	_mbstok (unsigned char*, unsigned char*);

#ifdef __MSVCRT__
int  _strncoll(const char*, const char*, size_t);
int  _strnicoll(const char*, const char*, size_t);
#endif

#endif	/* Not __STRICT_ANSI__ */

/*
 * Unicode versions of the standard calls.
 */
wchar_t* wcscat (wchar_t*, const wchar_t*);
wchar_t* wcschr (const wchar_t*, wchar_t);
int	wcscmp (const wchar_t*, const wchar_t*);
int	wcscoll (const wchar_t*, const wchar_t*);
wchar_t* wcscpy (wchar_t*, const wchar_t*);
size_t	wcscspn (const wchar_t*, const wchar_t*);
/* Note: No wcserror in CRTDLL. */
size_t	wcslen (const wchar_t*);
wchar_t* wcsncat (wchar_t*, const wchar_t*, size_t);
int	wcsncmp(const wchar_t*, const wchar_t*, size_t);
wchar_t* wcsncpy(wchar_t*, const wchar_t*, size_t);
wchar_t* wcspbrk(const wchar_t*, const wchar_t*);
wchar_t* wcsrchr(const wchar_t*, wchar_t);
size_t	wcsspn(const wchar_t*, const wchar_t*);
wchar_t* wcsstr(const wchar_t*, const wchar_t*);
wchar_t* wcstok(wchar_t*, const wchar_t*);
size_t	wcsxfrm(wchar_t*, const wchar_t*, size_t);

#ifndef	__STRICT_ANSI__
/*
 * Unicode versions of non-ANSI functions provided by CRTDLL.
 */

/* NOTE: _wcscmpi not provided by CRTDLL, this define is for portability */
#define		_wcscmpi	_wcsicmp

wchar_t* _wcsdup (wchar_t*);
int	_wcsicmp (const wchar_t*, const wchar_t*);
int	_wcsicoll (const wchar_t*, const wchar_t*);
wchar_t* _wcslwr (wchar_t*);
int	_wcsnicmp (const wchar_t*, const wchar_t*, size_t);
wchar_t* _wcsnset (wchar_t*, wchar_t, size_t);
wchar_t* _wcsrev (wchar_t*);
wchar_t* _wcsset (wchar_t*, wchar_t);
wchar_t* _wcsupr (wchar_t*);

#ifdef __MSVCRT__
int  _wcsncoll(const wchar_t*, const wchar_t*, size_t);
int  _wcsnicoll(const wchar_t*, const wchar_t*, size_t);
#endif


#endif	/* Not __STRICT_ANSI__ */


#ifndef	__STRICT_ANSI__
#ifndef	_NO_OLDNAMES

/*
 * Non-underscored versions of non-ANSI functions. They live in liboldnames.a
 * and provide a little extra portability. Also a few extra UNIX-isms like
 * strcasecmp.
 */

void*	memccpy (void*, const void*, int, size_t);
int	memicmp (const void*, const void*, size_t);
char*	strdup (const char*);
int	strcmpi (const char*, const char*);
int	stricmp (const char*, const char*);
int	strcasecmp (const char*, const char*);
int	stricoll (const char*, const char*);
char*	strlwr (char*);
int	strnicmp (const char*, const char*, size_t);
int	strncasecmp (const char*, const char*, size_t);
char*	strnset (char*, int, size_t);
char*	strrev (char*);
char*	strset (char*, int);
char*	strupr (char*);
#ifndef _UWIN
void	swab (const char*, char*, size_t);
#endif /* _UWIN */

/* NOTE: There is no _wcscmpi, but this is for compatibility. */
int	wcscmpi	(const wchar_t*, const wchar_t*);
wchar_t* wcsdup (wchar_t*);
int	wcsicmp (const wchar_t*, const wchar_t*);
int	wcsicoll (const wchar_t*, const wchar_t*);
wchar_t* wcslwr (wchar_t*);
int	wcsnicmp (const wchar_t*, const wchar_t*, size_t);
wchar_t* wcsnset (wchar_t*, wchar_t, size_t);
wchar_t* wcsrev (wchar_t*);
wchar_t* wcsset (wchar_t*, wchar_t);
wchar_t* wcsupr (wchar_t*);

#endif	/* Not _NO_OLDNAMES */
#endif	/* Not strict ANSI */


#ifdef __cplusplus
}
#endif

#endif	/* Not RC_INVOKED */

#endif	/* Not _STRING_H_ */

