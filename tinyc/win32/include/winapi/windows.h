/*
	windows.h - main header file for the Win32 API

	Written by Anders Norlander <anorland@hem2.passagen.se>

	This file is part of a free library for the Win32 API.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

*/
#ifndef _WINDOWS_H
#define _WINDOWS_H
#if __GNUC__ >=3
#pragma GCC system_header
#endif

/* translate GCC target defines to MS equivalents. Keep this synchronized
   with winnt.h. */
#if defined(__i686__) && !defined(_M_IX86)
#define _M_IX86 600
#elif defined(__i586__) && !defined(_M_IX86)
#define _M_IX86 500
#elif defined(__i486__) && !defined(_M_IX86)
#define _M_IX86 400
#elif defined(__i386__) && !defined(_M_IX86)
#define _M_IX86 300
#endif
#if defined(_M_IX86) && !defined(_X86_)
#define _X86_
#elif defined(_M_ALPHA) && !defined(_ALPHA_)
#define _ALPHA_
#elif defined(_M_PPC) && !defined(_PPC_)
#define _PPC_
#elif defined(_M_MRX000) && !defined(_MIPS_)
#define _MIPS_
#elif defined(_M_M68K) && !defined(_68K_)
#define _68K_
#endif

#ifdef RC_INVOKED
/* winresrc.h includes the necessary headers */
#include <winresrc.h>
#else

#ifdef __GNUC__
#ifndef NONAMELESSUNION
#if __GNUC__ > 2 || (__GNUC__ == 2 && __GNUC_MINOR__ >= 95) 
#define _ANONYMOUS_UNION __extension__
#define _ANONYMOUS_STRUCT __extension__
#else
#if defined(__cplusplus)
#define _ANONYMOUS_UNION __extension__
#endif /* __cplusplus */
#endif /* __GNUC__ > 2 || (__GNUC__ == 2 && __GNUC_MINOR__ >= 95) */
#endif /* NONAMELESSUNION */
#elif defined(__WATCOMC__)
#define _ANONYMOUS_UNION
#define _ANONYMOUS_STRUCT
#endif /* __GNUC__/__WATCOMC__ */

#ifndef _ANONYMOUS_UNION
#define _ANONYMOUS_UNION
#define _UNION_NAME(x) x
#define DUMMYUNIONNAME	u
#define DUMMYUNIONNAME2	u2
#define DUMMYUNIONNAME3	u3
#define DUMMYUNIONNAME4	u4
#define DUMMYUNIONNAME5	u5
#define DUMMYUNIONNAME6	u6
#define DUMMYUNIONNAME7	u7
#define DUMMYUNIONNAME8	u8
#else
#define _UNION_NAME(x)
#define DUMMYUNIONNAME
#define DUMMYUNIONNAME2
#define DUMMYUNIONNAME3
#define DUMMYUNIONNAME4
#define DUMMYUNIONNAME5
#define DUMMYUNIONNAME6
#define DUMMYUNIONNAME7
#define DUMMYUNIONNAME8
#endif
#ifndef _ANONYMOUS_STRUCT
#define _ANONYMOUS_STRUCT
#define _STRUCT_NAME(x) x
#define DUMMYSTRUCTNAME	s
#define DUMMYSTRUCTNAME2 s2
#define DUMMYSTRUCTNAME3 s3
#else
#define _STRUCT_NAME(x)
#define DUMMYSTRUCTNAME
#define DUMMYSTRUCTNAME2
#define DUMMYSTRUCTNAME3
#endif

#ifndef NO_STRICT
#ifndef STRICT
#define STRICT 1
#endif
#endif

#include <stdarg.h>
#include <windef.h>
#include <wincon.h>
#include <basetyps.h>
#include <excpt.h>
#include <winbase.h>
#ifndef _WINGDI_H
#include <wingdi.h>
#endif
#ifndef _WINUSER_H
#include <winuser.h>
#endif
#ifndef _WINNLS_H
#include <winnls.h>
#endif
#ifndef _WINVER_H
#include <winver.h>
#endif
#ifndef _WINNETWK_H
#include <winnetwk.h>
#endif
#ifndef _WINREG_H
#include <winreg.h>
#endif
#ifndef _WINSVC_H
#include <winsvc.h>
#endif

#ifndef WIN32_LEAN_AND_MEAN
#include <commdlg.h>
#include <cderr.h>
#include <dde.h>
#include <ddeml.h>
#include <dlgs.h>
#include <lzexpand.h>
#include <mmsystem.h>
#include <nb30.h>
#include <rpc.h>
#include <shellapi.h>
#include <winperf.h>
#include <winspool.h>
#if defined(Win32_Winsock)
#warning "The  Win32_Winsock macro name is deprecated.\
    Please use __USE_W32_SOCKETS instead"
#ifndef __USE_W32_SOCKETS
#define __USE_W32_SOCKETS
#endif
#endif
#if defined(__USE_W32_SOCKETS) || !(defined(__CYGWIN__) || defined(__MSYS__) || defined(_UWIN))
#if (_WIN32_WINNT >= 0x0400)
#include <winsock2.h>
/*
 * MS likes to include mswsock.h here as well,
 * but that can cause undefined symbols if
 * winsock2.h is included before windows.h
 */
#else
#include <winsock.h>
#endif /*  (_WIN32_WINNT >= 0x0400) */
#endif
#endif /* WIN32_LEAN_AND_MEAN */

#endif /* RC_INVOKED */

#ifdef __OBJC__
/* FIXME: Not undefining BOOL here causes all BOOLs to be WINBOOL (int),
   but undefining it causes trouble as well if a file is included after
   windows.h
*/
#undef BOOL
#endif

#endif
