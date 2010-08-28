/* 
 * ctype.h
 *
 * Functions for testing character types and converting characters.
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

#ifndef _CTYPE_H_
#define _CTYPE_H_

/* All the headers include this file. */
#include <_mingw.h>

#define	__need_wchar_t
#define	__need_wint_t
#ifndef RC_INVOKED
#include <stddef.h>
#endif	/* Not RC_INVOKED */


/*
 * The following flags are used to tell iswctype and _isctype what character
 * types you are looking for.
 */
#define	_UPPER		0x0001
#define	_LOWER		0x0002
#define	_DIGIT		0x0004
#define	_SPACE		0x0008 /* HT  LF  VT  FF  CR  SP */
#define	_PUNCT		0x0010
#define	_CONTROL	0x0020
#define	_BLANK		0x0040 /* this is SP only, not SP and HT as in C99  */
#define	_HEX		0x0080
#define	_LEADBYTE	0x8000

#define	_ALPHA		0x0103

#ifndef RC_INVOKED

#ifdef __cplusplus
extern "C" {
#endif

int	isalnum(int);
int	isalpha(int);
int	iscntrl(int);
int	isdigit(int);
int	isgraph(int);
int	islower(int);
int	isprint(int);
int	ispunct(int);
int	isspace(int);
int	isupper(int);
int	isxdigit(int);

#ifndef __STRICT_ANSI__
int	_isctype (int, int);
#endif

/* These are the ANSI versions, with correct checking of argument */
int	tolower(int);
int	toupper(int);

/*
 * NOTE: The above are not old name type wrappers, but functions exported
 * explicitly by MSVCRT/CRTDLL. However, underscored versions are also
 * exported.
 */
#ifndef	__STRICT_ANSI__
/*
 *  These are the cheap non-std versions: The return values are undefined
 *  if the argument is not ASCII char or is not of appropriate case
 */ 
int	_tolower(int);
int	_toupper(int);
#endif

/* Also defined in stdlib.h */
#ifndef MB_CUR_MAX
# ifdef __MSVCRT__
#  define MB_CUR_MAX __mb_cur_max
   __MINGW_IMPORT int __mb_cur_max;
# else /* not __MSVCRT */
#  define MB_CUR_MAX __mb_cur_max_dll
   __MINGW_IMPORT int __mb_cur_max_dll;
# endif /* not __MSVCRT */
#endif  /* MB_CUR_MAX */

__MINGW_IMPORT unsigned short _ctype[];
#ifdef __MSVCRT__
__MINGW_IMPORT unsigned short* _pctype;
#else /* CRTDLL */
__MINGW_IMPORT unsigned short* _pctype_dll;
#define  _pctype _pctype_dll
#endif

/*
 * Use inlines here rather than macros, because macros will upset 
 * C++ usage (eg, ::isalnum), and so usually get undefined
 *
 * According to standard for SB chars, these function are defined only
 * for input values representable by unsigned char or EOF.
 * Thus, there is no range test.
 * This reproduces behaviour of MSVCRT.dll lib implemention for SB chars.
 *
 * If no MB char support is needed, these can be simplified even
 * more by command line define -DMB_CUR_MAX=1.  The compiler will then
 * optimise away the constant condition.			
 */


#if ! (defined (__NO_CTYPE_INLINES) || defined (__STRICT_ANSI__ ))
/* use  simple lookup if SB locale, else  _isctype()  */
#define __ISCTYPE(c, mask)  (MB_CUR_MAX == 1 ? (_pctype[c] & mask) : _isctype(c, mask))
extern __inline__ int isalnum(int c) {return __ISCTYPE(c, (_ALPHA|_DIGIT));}
extern __inline__ int isalpha(int c) {return __ISCTYPE(c, _ALPHA);}
extern __inline__ int iscntrl(int c) {return __ISCTYPE(c, _CONTROL);}
extern __inline__ int isdigit(int c) {return __ISCTYPE(c, _DIGIT);}
extern __inline__ int isgraph(int c) {return __ISCTYPE(c, (_PUNCT|_ALPHA|_DIGIT));}
extern __inline__ int islower(int c) {return __ISCTYPE(c, _LOWER);}
extern __inline__ int isprint(int c) {return __ISCTYPE(c, (_BLANK|_PUNCT|_ALPHA|_DIGIT));}
extern __inline__ int ispunct(int c) {return __ISCTYPE(c, _PUNCT);}
extern __inline__ int isspace(int c) {return __ISCTYPE(c, _SPACE);}
extern __inline__ int isupper(int c) {return __ISCTYPE(c, _UPPER);}
extern __inline__ int isxdigit(int c) {return __ISCTYPE(c, _HEX);}

/* these reproduce behaviour of lib underscored versions  */
extern __inline__ int _tolower(int c) {return ( c -'A'+'a');}
extern __inline__ int _toupper(int c) {return ( c -'a'+'A');}

/* TODO? Is it worth inlining ANSI tolower, toupper? Probably only
   if we only want C-locale. */

#endif /* _NO_CTYPE_INLINES */

/* Wide character equivalents */

#ifndef WEOF
#define	WEOF	(wchar_t)(0xFFFF)
#endif

#ifndef _WCTYPE_T_DEFINED
typedef wchar_t wctype_t;
#define _WCTYPE_T_DEFINED
#endif

int	iswalnum(wint_t);
int	iswalpha(wint_t);
int	iswascii(wint_t);
int	iswcntrl(wint_t);
int	iswctype(wint_t, wctype_t);
int	is_wctype(wint_t, wctype_t);	/* Obsolete! */
int	iswdigit(wint_t);
int	iswgraph(wint_t);
int	iswlower(wint_t);
int	iswprint(wint_t);
int	iswpunct(wint_t);
int	iswspace(wint_t);
int	iswupper(wint_t);
int	iswxdigit(wint_t);

wchar_t	towlower(wchar_t);
wchar_t	towupper(wchar_t);

int	isleadbyte (int);

/* Also in wctype.h */
#if ! (defined(__NO_CTYPE_INLINES) || defined(__WCTYPE_INLINES_DEFINED))
#define __WCTYPE_INLINES_DEFINED
extern __inline__ int iswalnum(wint_t wc) {return (iswctype(wc,_ALPHA|_DIGIT));}
extern __inline__ int iswalpha(wint_t wc) {return (iswctype(wc,_ALPHA));}
extern __inline__ int iswascii(wint_t wc) {return (((unsigned)wc & 0x7F) ==0);}
extern __inline__ int iswcntrl(wint_t wc) {return (iswctype(wc,_CONTROL));}
extern __inline__ int iswdigit(wint_t wc) {return (iswctype(wc,_DIGIT));}
extern __inline__ int iswgraph(wint_t wc) {return (iswctype(wc,_PUNCT|_ALPHA|_DIGIT));}
extern __inline__ int iswlower(wint_t wc) {return (iswctype(wc,_LOWER));}
extern __inline__ int iswprint(wint_t wc) {return (iswctype(wc,_BLANK|_PUNCT|_ALPHA|_DIGIT));}
extern __inline__ int iswpunct(wint_t wc) {return (iswctype(wc,_PUNCT));}
extern __inline__ int iswspace(wint_t wc) {return (iswctype(wc,_SPACE));}
extern __inline__ int iswupper(wint_t wc) {return (iswctype(wc,_UPPER));}
extern __inline__ int iswxdigit(wint_t wc) {return (iswctype(wc,_HEX));}
extern __inline__ int isleadbyte(int c) {return (_pctype[(unsigned char)(c)] & _LEADBYTE);}
#endif /* !(defined(__NO_CTYPE_INLINES) || defined(__WCTYPE_INLINES_DEFINED)) */

#ifndef	__STRICT_ANSI__
int	__isascii (int);
int	__toascii (int);
int	__iscsymf (int);	/* Valid first character in C symbol */
int	__iscsym (int);		/* Valid character in C symbol (after first) */

#ifndef __NO_CTYPE_INLINES
extern __inline__ int __isascii(int c) {return (((unsigned)c & ~0x7F) == 0);} 
extern __inline__ int __toascii(int c) {return (c & 0x7F);}
extern __inline__ int __iscsymf(int c) {return (isalpha(c) || (c == '_'));}
extern __inline__ int __iscsym(int c)  {return  (isalnum(c) || (c == '_'));}
#endif /* __NO_CTYPE_INLINES */

#ifndef	_NO_OLDNAMES
int	isascii (int);
int	toascii (int);
int	iscsymf (int);
int	iscsym (int);
#endif	/* Not _NO_OLDNAMES */

#endif	/* Not __STRICT_ANSI__ */

#ifdef __cplusplus
}
#endif

#endif	/* Not RC_INVOKED */

#endif	/* Not _CTYPE_H_ */

