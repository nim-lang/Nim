/*
 * _mingw.h
 *
 *  This file is for TCC-PE and not part of the Mingw32 package.
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
 */

#ifndef __MINGW_H
#define __MINGW_H

#include <stddef.h>

#define __int64 long long
#define __int32 long
#define __int16 short
#define __int8 char
#define __cdecl __attribute__((__cdecl__))
#define __stdcall __attribute__((__stdcall__))
#define __declspec(x) __attribute__((x))

#define __MINGW32_VERSION 2.0
#define __MINGW32_MAJOR_VERSION 2
#define __MINGW32_MINOR_VERSION 0

#define __MSVCRT__ 1
#define __MINGW_IMPORT extern
#define _CRTIMP
#define __CRT_INLINE extern __inline__

#define WIN32 1

#ifndef _WINT_T
#define _WINT_T
typedef unsigned int wint_t;
#endif

/* for winapi */
#define _ANONYMOUS_UNION
#define _ANONYMOUS_STRUCT
#define DECLSPEC_NORETURN
#define WIN32_LEAN_AND_MEAN
#define DECLARE_STDCALL_P(type) __stdcall type

#endif /* __MINGW_H */
