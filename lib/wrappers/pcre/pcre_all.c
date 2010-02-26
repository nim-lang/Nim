/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* This file is automatically written by the dftables auxiliary
program. If you edit it by hand, you might like to edit the Makefile to
prevent its ever being regenerated.

This file contains the default tables for characters with codes less than
128 (ASCII characters). These tables are used when no external tables are
passed to PCRE. */

const unsigned char _pcre_default_tables[] = {

/* This table is a lower casing table. */

    0,  1,  2,  3,  4,  5,  6,  7,
    8,  9, 10, 11, 12, 13, 14, 15,
   16, 17, 18, 19, 20, 21, 22, 23,
   24, 25, 26, 27, 28, 29, 30, 31,
   32, 33, 34, 35, 36, 37, 38, 39,
   40, 41, 42, 43, 44, 45, 46, 47,
   48, 49, 50, 51, 52, 53, 54, 55,
   56, 57, 58, 59, 60, 61, 62, 63,
   64, 97, 98, 99,100,101,102,103,
  104,105,106,107,108,109,110,111,
  112,113,114,115,116,117,118,119,
  120,121,122, 91, 92, 93, 94, 95,
   96, 97, 98, 99,100,101,102,103,
  104,105,106,107,108,109,110,111,
  112,113,114,115,116,117,118,119,
  120,121,122,123,124,125,126,127,
  128,129,130,131,132,133,134,135,
  136,137,138,139,140,141,142,143,
  144,145,146,147,148,149,150,151,
  152,153,154,155,156,157,158,159,
  160,161,162,163,164,165,166,167,
  168,169,170,171,172,173,174,175,
  176,177,178,179,180,181,182,183,
  184,185,186,187,188,189,190,191,
  192,193,194,195,196,197,198,199,
  200,201,202,203,204,205,206,207,
  208,209,210,211,212,213,214,215,
  216,217,218,219,220,221,222,223,
  224,225,226,227,228,229,230,231,
  232,233,234,235,236,237,238,239,
  240,241,242,243,244,245,246,247,
  248,249,250,251,252,253,254,255,

/* This table is a case flipping table. */

    0,  1,  2,  3,  4,  5,  6,  7,
    8,  9, 10, 11, 12, 13, 14, 15,
   16, 17, 18, 19, 20, 21, 22, 23,
   24, 25, 26, 27, 28, 29, 30, 31,
   32, 33, 34, 35, 36, 37, 38, 39,
   40, 41, 42, 43, 44, 45, 46, 47,
   48, 49, 50, 51, 52, 53, 54, 55,
   56, 57, 58, 59, 60, 61, 62, 63,
   64, 97, 98, 99,100,101,102,103,
  104,105,106,107,108,109,110,111,
  112,113,114,115,116,117,118,119,
  120,121,122, 91, 92, 93, 94, 95,
   96, 65, 66, 67, 68, 69, 70, 71,
   72, 73, 74, 75, 76, 77, 78, 79,
   80, 81, 82, 83, 84, 85, 86, 87,
   88, 89, 90,123,124,125,126,127,
  128,129,130,131,132,133,134,135,
  136,137,138,139,140,141,142,143,
  144,145,146,147,148,149,150,151,
  152,153,154,155,156,157,158,159,
  160,161,162,163,164,165,166,167,
  168,169,170,171,172,173,174,175,
  176,177,178,179,180,181,182,183,
  184,185,186,187,188,189,190,191,
  192,193,194,195,196,197,198,199,
  200,201,202,203,204,205,206,207,
  208,209,210,211,212,213,214,215,
  216,217,218,219,220,221,222,223,
  224,225,226,227,228,229,230,231,
  232,233,234,235,236,237,238,239,
  240,241,242,243,244,245,246,247,
  248,249,250,251,252,253,254,255,

/* This table contains bit maps for various character classes.
Each map is 32 bytes long and the bits run from the least
significant end of each byte. The classes that have their own
maps are: space, xdigit, digit, upper, lower, word, graph
print, punct, and cntrl. Other classes are built from combinations. */

  0x00,0x3e,0x00,0x00,0x01,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

  0x00,0x00,0x00,0x00,0x00,0x00,0xff,0x03,
  0x7e,0x00,0x00,0x00,0x7e,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

  0x00,0x00,0x00,0x00,0x00,0x00,0xff,0x03,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0xfe,0xff,0xff,0x07,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0xfe,0xff,0xff,0x07,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

  0x00,0x00,0x00,0x00,0x00,0x00,0xff,0x03,
  0xfe,0xff,0xff,0x87,0xfe,0xff,0xff,0x07,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

  0x00,0x00,0x00,0x00,0xfe,0xff,0xff,0xff,
  0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x7f,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

  0x00,0x00,0x00,0x00,0xff,0xff,0xff,0xff,
  0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x7f,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

  0x00,0x00,0x00,0x00,0xfe,0xff,0x00,0xfc,
  0x01,0x00,0x00,0xf8,0x01,0x00,0x00,0x78,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

  0xff,0xff,0xff,0xff,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

/* This table identifies various classes of character by individual bits:
  0x01   white space character
  0x02   letter
  0x04   decimal digit
  0x08   hexadecimal digit
  0x10   alphanumeric or '_'
  0x80   regular expression metacharacter or binary zero
*/

  0x80,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*   0-  7 */
  0x00,0x01,0x01,0x00,0x01,0x01,0x00,0x00, /*   8- 15 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  16- 23 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  24- 31 */
  0x01,0x00,0x00,0x00,0x80,0x00,0x00,0x00, /*    - '  */
  0x80,0x80,0x80,0x80,0x00,0x00,0x80,0x00, /*  ( - /  */
  0x1c,0x1c,0x1c,0x1c,0x1c,0x1c,0x1c,0x1c, /*  0 - 7  */
  0x1c,0x1c,0x00,0x00,0x00,0x00,0x00,0x80, /*  8 - ?  */
  0x00,0x1a,0x1a,0x1a,0x1a,0x1a,0x1a,0x12, /*  @ - G  */
  0x12,0x12,0x12,0x12,0x12,0x12,0x12,0x12, /*  H - O  */
  0x12,0x12,0x12,0x12,0x12,0x12,0x12,0x12, /*  P - W  */
  0x12,0x12,0x12,0x80,0x00,0x00,0x80,0x10, /*  X - _  */
  0x00,0x1a,0x1a,0x1a,0x1a,0x1a,0x1a,0x12, /*  ` - g  */
  0x12,0x12,0x12,0x12,0x12,0x12,0x12,0x12, /*  h - o  */
  0x12,0x12,0x12,0x12,0x12,0x12,0x12,0x12, /*  p - w  */
  0x12,0x12,0x12,0x80,0x80,0x00,0x00,0x00, /*  x -127 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 128-135 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 136-143 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 144-151 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 152-159 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 160-167 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 168-175 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 176-183 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 184-191 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 192-199 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 200-207 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 208-215 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 216-223 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 224-231 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 232-239 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 240-247 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};/* 248-255 */

/* End of chartables.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains the external function pcre_compile(), along with
supporting internal functions that are not used by other modules. */


/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/


/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/

/* This header contains definitions that are shared between the different
modules, but which are not relevant to the exported API. This includes some
functions whose names all begin with "_pcre_". */


/* Define DEBUG to get debugging output on stdout. */

/****
#define DEBUG
****/

/* Use a macro for debugging printing, 'cause that eliminates the use of #ifdef
inline, and there are *still* stupid compilers about that don't like indented
pre-processor statements, or at least there were when I first wrote this. After
all, it had only been about 10 years then... */

#ifdef DEBUG
#define DPRINTF(p) printf p
#else
#define DPRINTF(p) /*nothing*/
#endif


/* Get the definitions provided by running "configure" */


/* On Unix systems config.in is converted by configure into config.h. PCRE is
written in Standard C, but there are a few non-standard things it can cope
with, allowing it to run on SunOS4 and other "close to standard" systems.

On a non-Unix system you should just copy this file into config.h, and set up
the macros the way you need them. You should normally change the definitions of
HAVE_STRERROR and HAVE_MEMMOVE to 1. Unfortunately, because of the way autoconf
works, these cannot be made the defaults. If your system has bcopy() and not
memmove(), change the definition of HAVE_BCOPY instead of HAVE_MEMMOVE. If your
system has neither bcopy() nor memmove(), leave them both as 0; an emulation
function will be used. */

/* If you are compiling for a system that uses EBCDIC instead of ASCII
character codes, define this macro as 1. On systems that can use "configure",
this can be done via --enable-ebcdic. */

#ifndef EBCDIC
#define EBCDIC 0
#endif

/* If you are compiling for a system that needs some magic to be inserted
before the definition of an exported function, define this macro to contain the
relevant magic. It apears at the start of every exported function. */

#define EXPORT

/* Define to empty if the "const" keyword does not work. */

#undef const

/* Define to "unsigned" if <stddef.h> doesn't define size_t. */

#undef size_t

/* The following two definitions are mainly for the benefit of SunOS4, which
doesn't have the strerror() or memmove() functions that should be present in
all Standard C libraries. The macros HAVE_STRERROR and HAVE_MEMMOVE should
normally be defined with the value 1 for other systems, but unfortunately we
can't make this the default because "configure" files generated by autoconf
will only change 0 to 1; they won't change 1 to 0 if the functions are not
found. */

#define HAVE_STRERROR 1
#define HAVE_MEMMOVE  1

/* There are some non-Unix systems that don't even have bcopy(). If this macro
is false, an emulation is used. If HAVE_MEMMOVE is set to 1, the value of
HAVE_BCOPY is not relevant. */

#define HAVE_BCOPY    0

/* The value of NEWLINE determines the newline character. The default is to
leave it up to the compiler, but some sites want to force a particular value.
On Unix systems, "configure" can be used to override this default. */

#ifndef NEWLINE
#define NEWLINE '\n'
#endif

/* The value of LINK_SIZE determines the number of bytes used to store
links as offsets within the compiled regex. The default is 2, which allows for
compiled patterns up to 64K long. This covers the vast majority of cases.
However, PCRE can also be compiled to use 3 or 4 bytes instead. This allows for
longer patterns in extreme cases. On Unix systems, "configure" can be used to
override this default. */

#ifndef LINK_SIZE
#define LINK_SIZE   2
#endif

/* The value of MATCH_LIMIT determines the default number of times the match()
function can be called during a single execution of pcre_exec(). (There is a
runtime method of setting a different limit.) The limit exists in order to
catch runaway regular expressions that take for ever to determine that they do
not match. The default is set very large so that it does not accidentally catch
legitimate cases. On Unix systems, "configure" can be used to override this
default default. */

#ifndef MATCH_LIMIT
#define MATCH_LIMIT 10000000
#endif

/* When calling PCRE via the POSIX interface, additional working storage is
required for holding the pointers to capturing substrings because PCRE requires
three integers per substring, whereas the POSIX interface provides only two. If
the number of expected substrings is small, the wrapper function uses space on
the stack, because this is faster than using malloc() for each call. The
threshold above which the stack is no longer use is defined by POSIX_MALLOC_
THRESHOLD. On Unix systems, "configure" can be used to override this default.
*/

#ifndef POSIX_MALLOC_THRESHOLD
#define POSIX_MALLOC_THRESHOLD 10
#endif

/* PCRE uses recursive function calls to handle backtracking while matching.
This can sometimes be a problem on systems that have stacks of limited size.
Define NO_RECURSE to get a version that doesn't use recursion in the match()
function; instead it creates its own stack by steam using pcre_recurse_malloc
to get memory. For more detail, see comments and other stuff just above the
match() function. On Unix systems, "configure" can be used to set this in the
Makefile (use --disable-stack-for-recursion). */

/* #define NO_RECURSE */

/* End */

/* Standard C headers plus the external interface definition. The only time
setjmp and stdarg are used is when NO_RECURSE is set. */

#include <ctype.h>
#include <limits.h>
#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef PCRE_SPY
#define PCRE_DEFINITION       /* Win32 __declspec(export) trigger for .dll */
#endif

/* We need to have types that specify unsigned 16-bit and 32-bit integers. We
cannot determine these outside the compilation (e.g. by running a program as
part of "configure") because PCRE is often cross-compiled for use on other
systems. Instead we make use of the maximum sizes that are available at
preprocessor time in standard C environments. */

#if USHRT_MAX == 65535
  typedef unsigned short pcre_uint16;
#elif UINT_MAX == 65535
  typedef unsigned int pcre_uint16;
#else
  #error Cannot determine a type for 16-bit unsigned integers
#endif

#if UINT_MAX == 4294967295
  typedef unsigned int pcre_uint32;
#elif ULONG_MAX == 4294967295
  typedef unsigned long int pcre_uint32;
#else
  #error Cannot determine a type for 32-bit unsigned integers
#endif

/* All character handling must be done as unsigned characters. Otherwise there
are problems with top-bit-set characters and functions such as isspace().
However, we leave the interface to the outside world as char *, because that
should make things easier for callers. We define a short type for unsigned char
to save lots of typing. I tried "uchar", but it causes problems on Digital
Unix, where it is defined in sys/types, so use "uschar" instead. */

typedef unsigned char uschar;

/* Include the public PCRE header */

/*************************************************
*       Perl-Compatible Regular Expressions      *
*************************************************/

/* In its original form, this is the .in file that is transformed by
"configure" into pcre.h.

           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/

#ifndef _PCRE_H
#define _PCRE_H

/* The file pcre.h is build by "configure". Do not edit it; instead
make changes to pcre.in. */

#define PCRE_MAJOR          6
#define PCRE_MINOR          3
#define PCRE_DATE           "2005/11/29"

/* For other operating systems, we use the standard "extern". */

#ifndef PCRE_DATA_SCOPE
#  ifdef __cplusplus
#    define PCRE_DATA_SCOPE     extern "C"
#  else
#    define PCRE_DATA_SCOPE     extern
#  endif
#endif

/* Have to include stdlib.h in order to ensure that size_t is defined;
it is needed here for malloc. */

#include <stdlib.h>

/* Allow for C++ users */

#ifdef __cplusplus
extern "C" {
#endif

/* Options */

#define PCRE_CASELESS           0x00000001
#define PCRE_MULTILINE          0x00000002
#define PCRE_DOTALL             0x00000004
#define PCRE_EXTENDED           0x00000008
#define PCRE_ANCHORED           0x00000010
#define PCRE_DOLLAR_ENDONLY     0x00000020
#define PCRE_EXTRA              0x00000040
#define PCRE_NOTBOL             0x00000080
#define PCRE_NOTEOL             0x00000100
#define PCRE_UNGREEDY           0x00000200
#define PCRE_NOTEMPTY           0x00000400
#define PCRE_UTF8               0x00000800
#define PCRE_NO_AUTO_CAPTURE    0x00001000
#define PCRE_NO_UTF8_CHECK      0x00002000
#define PCRE_AUTO_CALLOUT       0x00004000
#define PCRE_PARTIAL            0x00008000
#define PCRE_DFA_SHORTEST       0x00010000
#define PCRE_DFA_RESTART        0x00020000
#define PCRE_FIRSTLINE          0x00040000

/* Exec-time and get/set-time error codes */

#define PCRE_ERROR_NOMATCH         (-1)
#define PCRE_ERROR_NULL            (-2)
#define PCRE_ERROR_BADOPTION       (-3)
#define PCRE_ERROR_BADMAGIC        (-4)
#define PCRE_ERROR_UNKNOWN_NODE    (-5)
#define PCRE_ERROR_NOMEMORY        (-6)
#define PCRE_ERROR_NOSUBSTRING     (-7)
#define PCRE_ERROR_MATCHLIMIT      (-8)
#define PCRE_ERROR_CALLOUT         (-9)  /* Never used by PCRE itself */
#define PCRE_ERROR_BADUTF8        (-10)
#define PCRE_ERROR_BADUTF8_OFFSET (-11)
#define PCRE_ERROR_PARTIAL        (-12)
#define PCRE_ERROR_BADPARTIAL     (-13)
#define PCRE_ERROR_INTERNAL       (-14)
#define PCRE_ERROR_BADCOUNT       (-15)
#define PCRE_ERROR_DFA_UITEM      (-16)
#define PCRE_ERROR_DFA_UCOND      (-17)
#define PCRE_ERROR_DFA_UMLIMIT    (-18)
#define PCRE_ERROR_DFA_WSSIZE     (-19)
#define PCRE_ERROR_DFA_RECURSE    (-20)

/* Request types for pcre_fullinfo() */

#define PCRE_INFO_OPTIONS            0
#define PCRE_INFO_SIZE               1
#define PCRE_INFO_CAPTURECOUNT       2
#define PCRE_INFO_BACKREFMAX         3
#define PCRE_INFO_FIRSTBYTE          4
#define PCRE_INFO_FIRSTCHAR          4  /* For backwards compatibility */
#define PCRE_INFO_FIRSTTABLE         5
#define PCRE_INFO_LASTLITERAL        6
#define PCRE_INFO_NAMEENTRYSIZE      7
#define PCRE_INFO_NAMECOUNT          8
#define PCRE_INFO_NAMETABLE          9
#define PCRE_INFO_STUDYSIZE         10
#define PCRE_INFO_DEFAULT_TABLES    11

/* Request types for pcre_config() */

#define PCRE_CONFIG_UTF8                    0
#define PCRE_CONFIG_NEWLINE                 1
#define PCRE_CONFIG_LINK_SIZE               2
#define PCRE_CONFIG_POSIX_MALLOC_THRESHOLD  3
#define PCRE_CONFIG_MATCH_LIMIT             4
#define PCRE_CONFIG_STACKRECURSE            5
#define PCRE_CONFIG_UNICODE_PROPERTIES      6

/* Bit flags for the pcre_extra structure */

#define PCRE_EXTRA_STUDY_DATA          0x0001
#define PCRE_EXTRA_MATCH_LIMIT         0x0002
#define PCRE_EXTRA_CALLOUT_DATA        0x0004
#define PCRE_EXTRA_TABLES              0x0008

/* Types */

struct real_pcre;                 /* declaration; the definition is private  */
typedef struct real_pcre pcre;

/* The structure for passing additional data to pcre_exec(). This is defined in
such as way as to be extensible. Always add new fields at the end, in order to
remain compatible. */

typedef struct pcre_extra {
  unsigned long int flags;        /* Bits for which fields are set */
  void *study_data;               /* Opaque data from pcre_study() */
  unsigned long int match_limit;  /* Maximum number of calls to match() */
  void *callout_data;             /* Data passed back in callouts */
  const unsigned char *tables;    /* Pointer to character tables */
} pcre_extra;

/* The structure for passing out data via the pcre_callout_function. We use a
structure so that new fields can be added on the end in future versions,
without changing the API of the function, thereby allowing old clients to work
without modification. */

typedef struct pcre_callout_block {
  int          version;           /* Identifies version of block */
  /* ------------------------ Version 0 ------------------------------- */
  int          callout_number;    /* Number compiled into pattern */
  int         *offset_vector;     /* The offset vector */
  const char  *subject;           /* The subject being matched */
  int          subject_length;    /* The length of the subject */
  int          start_match;       /* Offset to start of this match attempt */
  int          current_position;  /* Where we currently are in the subject */
  int          capture_top;       /* Max current capture */
  int          capture_last;      /* Most recently closed capture */
  void        *callout_data;      /* Data passed in with the call */
  /* ------------------- Added for Version 1 -------------------------- */
  int          pattern_position;  /* Offset to next item in the pattern */
  int          next_item_length;  /* Length of next item in the pattern */
  /* ------------------------------------------------------------------ */
} pcre_callout_block;

/* Indirection for store get and free functions. These can be set to
alternative malloc/free functions if required. Special ones are used in the
non-recursive case for "frames". There is also an optional callout function
that is triggered by the (?) regex item. For Virtual Pascal, these definitions
have to take another form. */

#ifndef VPCOMPAT
PCRE_DATA_SCOPE void *(*pcre_malloc)(size_t);
PCRE_DATA_SCOPE void  (*pcre_free)(void *);
PCRE_DATA_SCOPE void *(*pcre_stack_malloc)(size_t);
PCRE_DATA_SCOPE void  (*pcre_stack_free)(void *);
PCRE_DATA_SCOPE int   (*pcre_callout)(pcre_callout_block *);
#else   /* VPCOMPAT */
PCRE_DATA_SCOPE void *pcre_malloc(size_t);
PCRE_DATA_SCOPE void  pcre_free(void *);
PCRE_DATA_SCOPE void *pcre_stack_malloc(size_t);
PCRE_DATA_SCOPE void  pcre_stack_free(void *);
PCRE_DATA_SCOPE int   pcre_callout(pcre_callout_block *);
#endif  /* VPCOMPAT */

/* Exported PCRE functions */

PCRE_DATA_SCOPE pcre *pcre_compile(const char *, int, const char **, int *,
                  const unsigned char *);
PCRE_DATA_SCOPE pcre *pcre_compile2(const char *, int, int *, const char **,
                  int *, const unsigned char *);
PCRE_DATA_SCOPE int  pcre_config(int, void *);
PCRE_DATA_SCOPE int  pcre_copy_named_substring(const pcre *, const char *,
                  int *, int, const char *, char *, int);
PCRE_DATA_SCOPE int  pcre_copy_substring(const char *, int *, int, int, char *,
                  int);
PCRE_DATA_SCOPE int  pcre_dfa_exec(const pcre *, const pcre_extra *,
                  const char *, int, int, int, int *, int , int *, int);
PCRE_DATA_SCOPE int  pcre_exec(const pcre *, const pcre_extra *, const char *,
                   int, int, int, int *, int);
PCRE_DATA_SCOPE void pcre_free_substring(const char *);
PCRE_DATA_SCOPE void pcre_free_substring_list(const char **);
PCRE_DATA_SCOPE int  pcre_fullinfo(const pcre *, const pcre_extra *, int,
                  void *);
PCRE_DATA_SCOPE int  pcre_get_named_substring(const pcre *, const char *,
                  int *, int, const char *, const char **);
PCRE_DATA_SCOPE int  pcre_get_stringnumber(const pcre *, const char *);
PCRE_DATA_SCOPE int  pcre_get_substring(const char *, int *, int, int,
                  const char **);
PCRE_DATA_SCOPE int  pcre_get_substring_list(const char *, int *, int,
                  const char ***);
PCRE_DATA_SCOPE int  pcre_info(const pcre *, int *, int *);
PCRE_DATA_SCOPE const unsigned char *pcre_maketables(void);
PCRE_DATA_SCOPE int  pcre_refcount(pcre *, int);
PCRE_DATA_SCOPE pcre_extra *pcre_study(const pcre *, int, const char **);
PCRE_DATA_SCOPE const char *pcre_version(void);

#ifdef __cplusplus
}  /* extern "C" */
#endif

#endif /* End of pcre.h */

/* Include the (copy of) the public ucp header, changing the external name into
a private one. This does no harm, even if we aren't compiling UCP support. */

#define ucp_findchar _pcre_ucp_findchar
/*************************************************
*     libucp - Unicode Property Table handler    *
*************************************************/


#ifndef _UCP_H
#define _UCP_H

/* These are the character categories that are returned by ucp_findchar */

enum {
  ucp_C,     /* Other */
  ucp_L,     /* Letter */
  ucp_M,     /* Mark */
  ucp_N,     /* Number */
  ucp_P,     /* Punctuation */
  ucp_S,     /* Symbol */
  ucp_Z      /* Separator */
};

/* These are the detailed character types that are returned by ucp_findchar */

enum {
  ucp_Cc,    /* Control */
  ucp_Cf,    /* Format */
  ucp_Cn,    /* Unassigned */
  ucp_Co,    /* Private use */
  ucp_Cs,    /* Surrogate */
  ucp_Ll,    /* Lower case letter */
  ucp_Lm,    /* Modifier letter */
  ucp_Lo,    /* Other letter */
  ucp_Lt,    /* Title case letter */
  ucp_Lu,    /* Upper case letter */
  ucp_Mc,    /* Spacing mark */
  ucp_Me,    /* Enclosing mark */
  ucp_Mn,    /* Non-spacing mark */
  ucp_Nd,    /* Decimal number */
  ucp_Nl,    /* Letter number */
  ucp_No,    /* Other number */
  ucp_Pc,    /* Connector punctuation */
  ucp_Pd,    /* Dash punctuation */
  ucp_Pe,    /* Close punctuation */
  ucp_Pf,    /* Final punctuation */
  ucp_Pi,    /* Initial punctuation */
  ucp_Po,    /* Other punctuation */
  ucp_Ps,    /* Open punctuation */
  ucp_Sc,    /* Currency symbol */
  ucp_Sk,    /* Modifier symbol */
  ucp_Sm,    /* Mathematical symbol */
  ucp_So,    /* Other symbol */
  ucp_Zl,    /* Line separator */
  ucp_Zp,    /* Paragraph separator */
  ucp_Zs     /* Space separator */
};

extern int ucp_findchar(const int, int *, int *);

#endif

/* End of ucp.h */

/* When compiling for use with the Virtual Pascal compiler, these functions
need to have their names changed. PCRE must be compiled with the -DVPCOMPAT
option on the command line. */

#ifdef VPCOMPAT
#define strncmp(s1,s2,m) _strncmp(s1,s2,m)
#define memcpy(d,s,n)    _memcpy(d,s,n)
#define memmove(d,s,n)   _memmove(d,s,n)
#define memset(s,c,n)    _memset(s,c,n)
#else  /* VPCOMPAT */

/* To cope with SunOS4 and other systems that lack memmove() but have bcopy(),
define a macro for memmove() if HAVE_MEMMOVE is false, provided that HAVE_BCOPY
is set. Otherwise, include an emulating function for those systems that have
neither (there some non-Unix environments where this is the case). This assumes
that all calls to memmove are moving strings upwards in store, which is the
case in PCRE. */

#if ! HAVE_MEMMOVE
#undef  memmove        /* some systems may have a macro */
#if HAVE_BCOPY
#define memmove(a, b, c) bcopy(b, a, c)
#else  /* HAVE_BCOPY */
void *
pcre_memmove(unsigned char *dest, const unsigned char *src, size_t n)
{
int i;
dest += n;
src += n;
for (i = 0; i < n; ++i) *(--dest) =  *(--src);
}
#define memmove(a, b, c) pcre_memmove(a, b, c)
#endif   /* not HAVE_BCOPY */
#endif   /* not HAVE_MEMMOVE */
#endif   /* not VPCOMPAT */


/* PCRE keeps offsets in its compiled code as 2-byte quantities (always stored
in big-endian order) by default. These are used, for example, to link from the
start of a subpattern to its alternatives and its end. The use of 2 bytes per
offset limits the size of the compiled regex to around 64K, which is big enough
for almost everybody. However, I received a request for an even bigger limit.
For this reason, and also to make the code easier to maintain, the storing and
loading of offsets from the byte string is now handled by the macros that are
defined here.

The macros are controlled by the value of LINK_SIZE. This defaults to 2 in
the config.h file, but can be overridden by using -D on the command line. This
is automated on Unix systems via the "configure" command. */

#if LINK_SIZE == 2

#define PUT(a,n,d)   \
  (a[n] = (d) >> 8), \
  (a[(n)+1] = (d) & 255)

#define GET(a,n) \
  (((a)[n] << 8) | (a)[(n)+1])

#define MAX_PATTERN_SIZE (1 << 16)


#elif LINK_SIZE == 3

#define PUT(a,n,d)       \
  (a[n] = (d) >> 16),    \
  (a[(n)+1] = (d) >> 8), \
  (a[(n)+2] = (d) & 255)

#define GET(a,n) \
  (((a)[n] << 16) | ((a)[(n)+1] << 8) | (a)[(n)+2])

#define MAX_PATTERN_SIZE (1 << 24)


#elif LINK_SIZE == 4

#define PUT(a,n,d)        \
  (a[n] = (d) >> 24),     \
  (a[(n)+1] = (d) >> 16), \
  (a[(n)+2] = (d) >> 8),  \
  (a[(n)+3] = (d) & 255)

#define GET(a,n) \
  (((a)[n] << 24) | ((a)[(n)+1] << 16) | ((a)[(n)+2] << 8) | (a)[(n)+3])

#define MAX_PATTERN_SIZE (1 << 30)   /* Keep it positive */


#else
#error LINK_SIZE must be either 2, 3, or 4
#endif


/* Convenience macro defined in terms of the others */

#define PUTINC(a,n,d)   PUT(a,n,d), a += LINK_SIZE


/* PCRE uses some other 2-byte quantities that do not change when the size of
offsets changes. There are used for repeat counts and for other things such as
capturing parenthesis numbers in back references. */

#define PUT2(a,n,d)   \
  a[n] = (d) >> 8; \
  a[(n)+1] = (d) & 255

#define GET2(a,n) \
  (((a)[n] << 8) | (a)[(n)+1])

#define PUT2INC(a,n,d)  PUT2(a,n,d), a += 2


/* When UTF-8 encoding is being used, a character is no longer just a single
byte. The macros for character handling generate simple sequences when used in
byte-mode, and more complicated ones for UTF-8 characters. */

#ifndef SUPPORT_UTF8
#define GETCHAR(c, eptr) c = *eptr;
#define GETCHARTEST(c, eptr) c = *eptr;
#define GETCHARINC(c, eptr) c = *eptr++;
#define GETCHARINCTEST(c, eptr) c = *eptr++;
#define GETCHARLEN(c, eptr, len) c = *eptr;
#define BACKCHAR(eptr)

#else   /* SUPPORT_UTF8 */

/* Get the next UTF-8 character, not advancing the pointer. This is called when
we know we are in UTF-8 mode. */

#define GETCHAR(c, eptr) \
  c = *eptr; \
  if ((c & 0xc0) == 0xc0) \
    { \
    int gcii; \
    int gcaa = _pcre_utf8_table4[c & 0x3f];  /* Number of additional bytes */ \
    int gcss = 6*gcaa; \
    c = (c & _pcre_utf8_table3[gcaa]) << gcss; \
    for (gcii = 1; gcii <= gcaa; gcii++) \
      { \
      gcss -= 6; \
      c |= (eptr[gcii] & 0x3f) << gcss; \
      } \
    }

/* Get the next UTF-8 character, testing for UTF-8 mode, and not advancing the
pointer. */

#define GETCHARTEST(c, eptr) \
  c = *eptr; \
  if (utf8 && (c & 0xc0) == 0xc0) \
    { \
    int gcii; \
    int gcaa = _pcre_utf8_table4[c & 0x3f];  /* Number of additional bytes */ \
    int gcss = 6*gcaa; \
    c = (c & _pcre_utf8_table3[gcaa]) << gcss; \
    for (gcii = 1; gcii <= gcaa; gcii++) \
      { \
      gcss -= 6; \
      c |= (eptr[gcii] & 0x3f) << gcss; \
      } \
    }

/* Get the next UTF-8 character, advancing the pointer. This is called when we
know we are in UTF-8 mode. */

#define GETCHARINC(c, eptr) \
  c = *eptr++; \
  if ((c & 0xc0) == 0xc0) \
    { \
    int gcaa = _pcre_utf8_table4[c & 0x3f];  /* Number of additional bytes */ \
    int gcss = 6*gcaa; \
    c = (c & _pcre_utf8_table3[gcaa]) << gcss; \
    while (gcaa-- > 0) \
      { \
      gcss -= 6; \
      c |= (*eptr++ & 0x3f) << gcss; \
      } \
    }

/* Get the next character, testing for UTF-8 mode, and advancing the pointer */

#define GETCHARINCTEST(c, eptr) \
  c = *eptr++; \
  if (utf8 && (c & 0xc0) == 0xc0) \
    { \
    int gcaa = _pcre_utf8_table4[c & 0x3f];  /* Number of additional bytes */ \
    int gcss = 6*gcaa; \
    c = (c & _pcre_utf8_table3[gcaa]) << gcss; \
    while (gcaa-- > 0) \
      { \
      gcss -= 6; \
      c |= (*eptr++ & 0x3f) << gcss; \
      } \
    }

/* Get the next UTF-8 character, not advancing the pointer, incrementing length
if there are extra bytes. This is called when we know we are in UTF-8 mode. */

#define GETCHARLEN(c, eptr, len) \
  c = *eptr; \
  if ((c & 0xc0) == 0xc0) \
    { \
    int gcii; \
    int gcaa = _pcre_utf8_table4[c & 0x3f];  /* Number of additional bytes */ \
    int gcss = 6*gcaa; \
    c = (c & _pcre_utf8_table3[gcaa]) << gcss; \
    for (gcii = 1; gcii <= gcaa; gcii++) \
      { \
      gcss -= 6; \
      c |= (eptr[gcii] & 0x3f) << gcss; \
      } \
    len += gcaa; \
    }

/* If the pointer is not at the start of a character, move it back until
it is. Called only in UTF-8 mode. */

#define BACKCHAR(eptr) while((*eptr & 0xc0) == 0x80) eptr--;

#endif


/* In case there is no definition of offsetof() provided - though any proper
Standard C system should have one. */

#ifndef offsetof
#define offsetof(p_type,field) ((size_t)&(((p_type *)0)->field))
#endif


/* These are the public options that can change during matching. */

#define PCRE_IMS (PCRE_CASELESS|PCRE_MULTILINE|PCRE_DOTALL)

/* Private options flags start at the most significant end of the four bytes,
but skip the top bit so we can use ints for convenience without getting tangled
with negative values. The public options defined in pcre.h start at the least
significant end. Make sure they don't overlap! */

#define PCRE_FIRSTSET      0x40000000  /* first_byte is set */
#define PCRE_REQCHSET      0x20000000  /* req_byte is set */
#define PCRE_STARTLINE     0x10000000  /* start after \n for multiline */
#define PCRE_ICHANGED      0x08000000  /* i option changes within regex */
#define PCRE_NOPARTIAL     0x04000000  /* can't use partial with this regex */

/* Options for the "extra" block produced by pcre_study(). */

#define PCRE_STUDY_MAPPED   0x01     /* a map of starting chars exists */

/* Masks for identifying the public options that are permitted at compile
time, run time, or study time, respectively. */

#define PUBLIC_OPTIONS \
  (PCRE_CASELESS|PCRE_EXTENDED|PCRE_ANCHORED|PCRE_MULTILINE| \
   PCRE_DOTALL|PCRE_DOLLAR_ENDONLY|PCRE_EXTRA|PCRE_UNGREEDY|PCRE_UTF8| \
   PCRE_NO_AUTO_CAPTURE|PCRE_NO_UTF8_CHECK|PCRE_AUTO_CALLOUT|PCRE_FIRSTLINE)

#define PUBLIC_EXEC_OPTIONS \
  (PCRE_ANCHORED|PCRE_NOTBOL|PCRE_NOTEOL|PCRE_NOTEMPTY|PCRE_NO_UTF8_CHECK| \
   PCRE_PARTIAL)

#define PUBLIC_DFA_EXEC_OPTIONS \
  (PCRE_ANCHORED|PCRE_NOTBOL|PCRE_NOTEOL|PCRE_NOTEMPTY|PCRE_NO_UTF8_CHECK| \
   PCRE_PARTIAL|PCRE_DFA_SHORTEST|PCRE_DFA_RESTART)

#define PUBLIC_STUDY_OPTIONS 0   /* None defined */

/* Magic number to provide a small check against being handed junk. Also used
to detect whether a pattern was compiled on a host of different endianness. */

#define MAGIC_NUMBER  0x50435245UL   /* 'PCRE' */

/* Negative values for the firstchar and reqchar variables */

#define REQ_UNSET (-2)
#define REQ_NONE  (-1)

/* The maximum remaining length of subject we are prepared to search for a
req_byte match. */

#define REQ_BYTE_MAX 1000

/* Flags added to firstbyte or reqbyte; a "non-literal" item is either a
variable-length repeat, or a anything other than literal characters. */

#define REQ_CASELESS 0x0100    /* indicates caselessness */
#define REQ_VARY     0x0200    /* reqbyte followed non-literal item */

/* Miscellaneous definitions */

typedef int BOOL;

#define FALSE   0
#define TRUE    1

/* Escape items that are just an encoding of a particular data value. Note that
ESC_n is defined as yet another macro, which is set in config.h to either \n
(the default) or \r (which some people want). */

#ifndef ESC_e
#define ESC_e 27
#endif

#ifndef ESC_f
#define ESC_f '\f'
#endif

#ifndef ESC_n
#define ESC_n NEWLINE
#endif

#ifndef ESC_r
#define ESC_r '\r'
#endif

/* We can't officially use ESC_t because it is a POSIX reserved identifier
(presumably because of all the others like size_t). */

#ifndef ESC_tee
#define ESC_tee '\t'
#endif

/* These are escaped items that aren't just an encoding of a particular data
value such as \n. They must have non-zero values, as check_escape() returns
their negation. Also, they must appear in the same order as in the opcode
definitions below, up to ESC_z. There's a dummy for OP_ANY because it
corresponds to "." rather than an escape sequence. The final one must be
ESC_REF as subsequent values are used for \1, \2, \3, etc. There is are two
tests in the code for an escape greater than ESC_b and less than ESC_Z to
detect the types that may be repeated. These are the types that consume
characters. If any new escapes are put in between that don't consume a
character, that code will have to change. */

enum { ESC_A = 1, ESC_G, ESC_B, ESC_b, ESC_D, ESC_d, ESC_S, ESC_s, ESC_W,
       ESC_w, ESC_dum1, ESC_C, ESC_P, ESC_p, ESC_X, ESC_Z, ESC_z, ESC_E,
       ESC_Q, ESC_REF };

/* Flag bits and data types for the extended class (OP_XCLASS) for classes that
contain UTF-8 characters with values greater than 255. */

#define XCL_NOT    0x01    /* Flag: this is a negative class */
#define XCL_MAP    0x02    /* Flag: a 32-byte map is present */

#define XCL_END       0    /* Marks end of individual items */
#define XCL_SINGLE    1    /* Single item (one multibyte char) follows */
#define XCL_RANGE     2    /* A range (two multibyte chars) follows */
#define XCL_PROP      3    /* Unicode property (one property code) follows */
#define XCL_NOTPROP   4    /* Unicode inverted property (ditto) */


/* Opcode table: OP_BRA must be last, as all values >= it are used for brackets
that extract substrings. Starting from 1 (i.e. after OP_END), the values up to
OP_EOD must correspond in order to the list of escapes immediately above.
Note that whenever this list is updated, the two macro definitions that follow
must also be updated to match. */

enum {
  OP_END,            /* 0 End of pattern */

  /* Values corresponding to backslashed metacharacters */

  OP_SOD,            /* 1 Start of data: \A */
  OP_SOM,            /* 2 Start of match (subject + offset): \G */
  OP_NOT_WORD_BOUNDARY,  /*  3 \B */
  OP_WORD_BOUNDARY,      /*  4 \b */
  OP_NOT_DIGIT,          /*  5 \D */
  OP_DIGIT,              /*  6 \d */
  OP_NOT_WHITESPACE,     /*  7 \S */
  OP_WHITESPACE,         /*  8 \s */
  OP_NOT_WORDCHAR,       /*  9 \W */
  OP_WORDCHAR,           /* 10 \w */
  OP_ANY,            /* 11 Match any character */
  OP_ANYBYTE,        /* 12 Match any byte (\C); different to OP_ANY for UTF-8 */
  OP_NOTPROP,        /* 13 \P (not Unicode property) */
  OP_PROP,           /* 14 \p (Unicode property) */
  OP_EXTUNI,         /* 15 \X (extended Unicode sequence */
  OP_EODN,           /* 16 End of data or \n at end of data: \Z. */
  OP_EOD,            /* 17 End of data: \z */

  OP_OPT,            /* 18 Set runtime options */
  OP_CIRC,           /* 19 Start of line - varies with multiline switch */
  OP_DOLL,           /* 20 End of line - varies with multiline switch */
  OP_CHAR,           /* 21 Match one character, casefully */
  OP_CHARNC,         /* 22 Match one character, caselessly */
  OP_NOT,            /* 23 Match anything but the following char */

  OP_STAR,           /* 24 The maximizing and minimizing versions of */
  OP_MINSTAR,        /* 25 all these opcodes must come in pairs, with */
  OP_PLUS,           /* 26 the minimizing one second. */
  OP_MINPLUS,        /* 27 This first set applies to single characters */
  OP_QUERY,          /* 28 */
  OP_MINQUERY,       /* 29 */
  OP_UPTO,           /* 30 From 0 to n matches */
  OP_MINUPTO,        /* 31 */
  OP_EXACT,          /* 32 Exactly n matches */

  OP_NOTSTAR,        /* 33 The maximizing and minimizing versions of */
  OP_NOTMINSTAR,     /* 34 all these opcodes must come in pairs, with */
  OP_NOTPLUS,        /* 35 the minimizing one second. */
  OP_NOTMINPLUS,     /* 36 This set applies to "not" single characters */
  OP_NOTQUERY,       /* 37 */
  OP_NOTMINQUERY,    /* 38 */
  OP_NOTUPTO,        /* 39 From 0 to n matches */
  OP_NOTMINUPTO,     /* 40 */
  OP_NOTEXACT,       /* 41 Exactly n matches */

  OP_TYPESTAR,       /* 42 The maximizing and minimizing versions of */
  OP_TYPEMINSTAR,    /* 43 all these opcodes must come in pairs, with */
  OP_TYPEPLUS,       /* 44 the minimizing one second. These codes must */
  OP_TYPEMINPLUS,    /* 45 be in exactly the same order as those above. */
  OP_TYPEQUERY,      /* 46 This set applies to character types such as \d */
  OP_TYPEMINQUERY,   /* 47 */
  OP_TYPEUPTO,       /* 48 From 0 to n matches */
  OP_TYPEMINUPTO,    /* 49 */
  OP_TYPEEXACT,      /* 50 Exactly n matches */

  OP_CRSTAR,         /* 51 The maximizing and minimizing versions of */
  OP_CRMINSTAR,      /* 52 all these opcodes must come in pairs, with */
  OP_CRPLUS,         /* 53 the minimizing one second. These codes must */
  OP_CRMINPLUS,      /* 54 be in exactly the same order as those above. */
  OP_CRQUERY,        /* 55 These are for character classes and back refs */
  OP_CRMINQUERY,     /* 56 */
  OP_CRRANGE,        /* 57 These are different to the three sets above. */
  OP_CRMINRANGE,     /* 58 */

  OP_CLASS,          /* 59 Match a character class, chars < 256 only */
  OP_NCLASS,         /* 60 Same, but the bitmap was created from a negative
                           class - the difference is relevant only when a UTF-8
                           character > 255 is encountered. */

  OP_XCLASS,         /* 61 Extended class for handling UTF-8 chars within the
                           class. This does both positive and negative. */

  OP_REF,            /* 62 Match a back reference */
  OP_RECURSE,        /* 63 Match a numbered subpattern (possibly recursive) */
  OP_CALLOUT,        /* 64 Call out to external function if provided */

  OP_ALT,            /* 65 Start of alternation */
  OP_KET,            /* 66 End of group that doesn't have an unbounded repeat */
  OP_KETRMAX,        /* 67 These two must remain together and in this */
  OP_KETRMIN,        /* 68 order. They are for groups the repeat for ever. */

  /* The assertions must come before ONCE and COND */

  OP_ASSERT,         /* 69 Positive lookahead */
  OP_ASSERT_NOT,     /* 70 Negative lookahead */
  OP_ASSERTBACK,     /* 71 Positive lookbehind */
  OP_ASSERTBACK_NOT, /* 72 Negative lookbehind */
  OP_REVERSE,        /* 73 Move pointer back - used in lookbehind assertions */

  /* ONCE and COND must come after the assertions, with ONCE first, as there's
  a test for >= ONCE for a subpattern that isn't an assertion. */

  OP_ONCE,           /* 74 Once matched, don't back up into the subpattern */
  OP_COND,           /* 75 Conditional group */
  OP_CREF,           /* 76 Used to hold an extraction string number (cond ref) */

  OP_BRAZERO,        /* 77 These two must remain together and in this */
  OP_BRAMINZERO,     /* 78 order. */

  OP_BRANUMBER,      /* 79 Used for extracting brackets whose number is greater
                           than can fit into an opcode. */

  OP_BRA             /* 80 This and greater values are used for brackets that
                           extract substrings up to EXTRACT_BASIC_MAX. After
                           that, use is made of OP_BRANUMBER. */
};

/* WARNING WARNING WARNING: There is an implicit assumption in pcre.c and
study.c that all opcodes are less than 128 in value. This makes handling UTF-8
character sequences easier. */

/* The highest extraction number before we have to start using additional
bytes. (Originally PCRE didn't have support for extraction counts highter than
this number.) The value is limited by the number of opcodes left after OP_BRA,
i.e. 255 - OP_BRA. We actually set it a bit lower to leave room for additional
opcodes. */

#define EXTRACT_BASIC_MAX  100


/* This macro defines textual names for all the opcodes. These are used only
for debugging. The macro is referenced only in pcre_printint.c. */

#define OP_NAME_LIST \
  "End", "\\A", "\\G", "\\B", "\\b", "\\D", "\\d",                \
  "\\S", "\\s", "\\W", "\\w", "Any", "Anybyte",                   \
  "notprop", "prop", "extuni",                                    \
  "\\Z", "\\z",                                                   \
  "Opt", "^", "$", "char", "charnc", "not",                       \
  "*", "*?", "+", "+?", "?", "??", "{", "{", "{",                 \
  "*", "*?", "+", "+?", "?", "??", "{", "{", "{",                 \
  "*", "*?", "+", "+?", "?", "??", "{", "{", "{",                 \
  "*", "*?", "+", "+?", "?", "??", "{", "{",                      \
  "class", "nclass", "xclass", "Ref", "Recurse", "Callout",       \
  "Alt", "Ket", "KetRmax", "KetRmin", "Assert", "Assert not",     \
  "AssertB", "AssertB not", "Reverse", "Once", "Cond", "Cond ref",\
  "Brazero", "Braminzero", "Branumber", "Bra"


/* This macro defines the length of fixed length operations in the compiled
regex. The lengths are used when searching for specific things, and also in the
debugging printing of a compiled regex. We use a macro so that it can be
defined close to the definitions of the opcodes themselves.

As things have been extended, some of these are no longer fixed lenths, but are
minima instead. For example, the length of a single-character repeat may vary
in UTF-8 mode. The code that uses this table must know about such things. */

#define OP_LENGTHS \
  1,                             /* End                                    */ \
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  /* \A, \G, \B, \B, \D, \d, \S, \s, \W, \w */ \
  1, 1,                          /* Any, Anybyte                           */ \
  2, 2, 1,                       /* NOTPROP, PROP, EXTUNI                  */ \
  1, 1, 2, 1, 1,                 /* \Z, \z, Opt, ^, $                      */ \
  2,                             /* Char  - the minimum length             */ \
  2,                             /* Charnc  - the minimum length           */ \
  2,                             /* not                                    */ \
  /* Positive single-char repeats                            ** These are  */ \
  2, 2, 2, 2, 2, 2,              /* *, *?, +, +?, ?, ??      ** minima in  */ \
  4, 4, 4,                       /* upto, minupto, exact     ** UTF-8 mode */ \
  /* Negative single-char repeats - only for chars < 256                   */ \
  2, 2, 2, 2, 2, 2,              /* NOT *, *?, +, +?, ?, ??                */ \
  4, 4, 4,                       /* NOT upto, minupto, exact               */ \
  /* Positive type repeats                                                 */ \
  2, 2, 2, 2, 2, 2,              /* Type *, *?, +, +?, ?, ??               */ \
  4, 4, 4,                       /* Type upto, minupto, exact              */ \
  /* Character class & ref repeats                                         */ \
  1, 1, 1, 1, 1, 1,              /* *, *?, +, +?, ?, ??                    */ \
  5, 5,                          /* CRRANGE, CRMINRANGE                    */ \
 33,                             /* CLASS                                  */ \
 33,                             /* NCLASS                                 */ \
  0,                             /* XCLASS - variable length               */ \
  3,                             /* REF                                    */ \
  1+LINK_SIZE,                   /* RECURSE                                */ \
  2+2*LINK_SIZE,                 /* CALLOUT                                */ \
  1+LINK_SIZE,                   /* Alt                                    */ \
  1+LINK_SIZE,                   /* Ket                                    */ \
  1+LINK_SIZE,                   /* KetRmax                                */ \
  1+LINK_SIZE,                   /* KetRmin                                */ \
  1+LINK_SIZE,                   /* Assert                                 */ \
  1+LINK_SIZE,                   /* Assert not                             */ \
  1+LINK_SIZE,                   /* Assert behind                          */ \
  1+LINK_SIZE,                   /* Assert behind not                      */ \
  1+LINK_SIZE,                   /* Reverse                                */ \
  1+LINK_SIZE,                   /* Once                                   */ \
  1+LINK_SIZE,                   /* COND                                   */ \
  3,                             /* CREF                                   */ \
  1, 1,                          /* BRAZERO, BRAMINZERO                    */ \
  3,                             /* BRANUMBER                              */ \
  1+LINK_SIZE                    /* BRA                                    */ \


/* A magic value for OP_CREF to indicate the "in recursion" condition. */

#define CREF_RECURSE  0xffff

/* Error code numbers. They are given names so that they can more easily be
tracked. */

enum { ERR0,  ERR1,  ERR2,  ERR3,  ERR4,  ERR5,  ERR6,  ERR7,  ERR8,  ERR9,
       ERR10, ERR11, ERR12, ERR13, ERR14, ERR15, ERR16, ERR17, ERR18, ERR19,
       ERR20, ERR21, ERR22, ERR23, ERR24, ERR25, ERR26, ERR27, ERR28, ERR29,
       ERR30, ERR31, ERR32, ERR33, ERR34, ERR35, ERR36, ERR37, ERR38, ERR39,
       ERR40, ERR41, ERR42, ERR43, ERR44, ERR45, ERR46, ERR47 };

/* The real format of the start of the pcre block; the index of names and the
code vector run on as long as necessary after the end. We store an explicit
offset to the name table so that if a regex is compiled on one host, saved, and
then run on another where the size of pointers is different, all might still
be well. For the case of compiled-on-4 and run-on-8, we include an extra
pointer that is always NULL. For future-proofing, a few dummy fields were
originally included - even though you can never get this planning right - but
there is only one left now.

NOTE NOTE NOTE:
Because people can now save and re-use compiled patterns, any additions to this
structure should be made at the end, and something earlier (e.g. a new
flag in the options or one of the dummy fields) should indicate that the new
fields are present. Currently PCRE always sets the dummy fields to zero.
NOTE NOTE NOTE:
*/

typedef struct real_pcre {
  pcre_uint32 magic_number;
  pcre_uint32 size;               /* Total that was malloced */
  pcre_uint32 options;
  pcre_uint32 dummy1;             /* For future use, maybe */

  pcre_uint16 top_bracket;
  pcre_uint16 top_backref;
  pcre_uint16 first_byte;
  pcre_uint16 req_byte;
  pcre_uint16 name_table_offset;  /* Offset to name table that follows */
  pcre_uint16 name_entry_size;    /* Size of any name items */
  pcre_uint16 name_count;         /* Number of name items */
  pcre_uint16 ref_count;          /* Reference count */

  const unsigned char *tables;    /* Pointer to tables or NULL for std */
  const unsigned char *nullpad;   /* NULL padding */
} real_pcre;

/* The format of the block used to store data from pcre_study(). The same
remark (see NOTE above) about extending this structure applies. */

typedef struct pcre_study_data {
  pcre_uint32 size;               /* Total that was malloced */
  pcre_uint32 options;
  uschar start_bits[32];
} pcre_study_data;

/* Structure for passing "static" information around between the functions
doing the compiling, so that they are thread-safe. */

typedef struct compile_data {
  const uschar *lcc;            /* Points to lower casing table */
  const uschar *fcc;            /* Points to case-flipping table */
  const uschar *cbits;          /* Points to character type table */
  const uschar *ctypes;         /* Points to table of type maps */
  const uschar *start_code;     /* The start of the compiled code */
  const uschar *start_pattern;  /* The start of the pattern */
  uschar *name_table;           /* The name/number table */
  int  names_found;             /* Number of entries so far */
  int  name_entry_size;         /* Size of each entry */
  int  top_backref;             /* Maximum back reference */
  unsigned int backref_map;     /* Bitmap of low back refs */
  int  req_varyopt;             /* "After variable item" flag for reqbyte */
  BOOL nopartial;               /* Set TRUE if partial won't work */
} compile_data;

/* Structure for maintaining a chain of pointers to the currently incomplete
branches, for testing for left recursion. */

typedef struct branch_chain {
  struct branch_chain *outer;
  uschar *current;
} branch_chain;

/* Structure for items in a linked list that represents an explicit recursive
call within the pattern. */

typedef struct recursion_info {
  struct recursion_info *prevrec; /* Previous recursion record (or NULL) */
  int group_num;                /* Number of group that was called */
  const uschar *after_call;     /* "Return value": points after the call in the expr */
  const uschar *save_start;     /* Old value of md->start_match */
  int *offset_save;             /* Pointer to start of saved offsets */
  int saved_max;                /* Number of saved offsets */
} recursion_info;

/* When compiling in a mode that doesn't use recursive calls to match(),
a structure is used to remember local variables on the heap. It is defined in
pcre.c, close to the match() function, so that it is easy to keep it in step
with any changes of local variable. However, the pointer to the current frame
must be saved in some "static" place over a longjmp(). We declare the
structure here so that we can put a pointer in the match_data structure.
NOTE: This isn't used for a "normal" compilation of pcre. */

struct heapframe;

/* Structure for passing "static" information around between the functions
doing traditional NFA matching, so that they are thread-safe. */

typedef struct match_data {
  unsigned long int match_call_count; /* As it says */
  unsigned long int match_limit;/* As it says */
  int   *offset_vector;         /* Offset vector */
  int    offset_end;            /* One past the end */
  int    offset_max;            /* The maximum usable for return data */
  const uschar *lcc;            /* Points to lower casing table */
  const uschar *ctypes;         /* Points to table of type maps */
  BOOL   offset_overflow;       /* Set if too many extractions */
  BOOL   notbol;                /* NOTBOL flag */
  BOOL   noteol;                /* NOTEOL flag */
  BOOL   utf8;                  /* UTF8 flag */
  BOOL   endonly;               /* Dollar not before final \n */
  BOOL   notempty;              /* Empty string match not wanted */
  BOOL   partial;               /* PARTIAL flag */
  BOOL   hitend;                /* Hit the end of the subject at some point */
  const uschar *start_code;     /* For use when recursing */
  const uschar *start_subject;  /* Start of the subject string */
  const uschar *end_subject;    /* End of the subject string */
  const uschar *start_match;    /* Start of this match attempt */
  const uschar *end_match_ptr;  /* Subject position at end match */
  int    end_offset_top;        /* Highwater mark at end of match */
  int    capture_last;          /* Most recent capture number */
  int    start_offset;          /* The start offset value */
  recursion_info *recursive;    /* Linked list of recursion data */
  void  *callout_data;          /* To pass back to callouts */
  struct heapframe *thisframe;  /* Used only when compiling for no recursion */
} match_data;

/* A similar structure is used for the same purpose by the DFA matching
functions. */

typedef struct dfa_match_data {
  const uschar *start_code;     /* Start of the compiled pattern */
  const uschar *start_subject;  /* Start of the subject string */
  const uschar *end_subject;    /* End of subject string */
  const uschar *tables;         /* Character tables */
  int   moptions;               /* Match options */
  int   poptions;               /* Pattern options */
  void  *callout_data;          /* To pass back to callouts */
} dfa_match_data;

/* Bit definitions for entries in the pcre_ctypes table. */

#define ctype_space   0x01
#define ctype_letter  0x02
#define ctype_digit   0x04
#define ctype_xdigit  0x08
#define ctype_word    0x10   /* alphameric or '_' */
#define ctype_meta    0x80   /* regexp meta char or zero (end pattern) */

/* Offsets for the bitmap tables in pcre_cbits. Each table contains a set
of bits for a class map. Some classes are built by combining these tables. */

#define cbit_space     0      /* [:space:] or \s */
#define cbit_xdigit   32      /* [:xdigit:] */
#define cbit_digit    64      /* [:digit:] or \d */
#define cbit_upper    96      /* [:upper:] */
#define cbit_lower   128      /* [:lower:] */
#define cbit_word    160      /* [:word:] or \w */
#define cbit_graph   192      /* [:graph:] */
#define cbit_print   224      /* [:print:] */
#define cbit_punct   256      /* [:punct:] */
#define cbit_cntrl   288      /* [:cntrl:] */
#define cbit_length  320      /* Length of the cbits table */

/* Offsets of the various tables from the base tables pointer, and
total length. */

#define lcc_offset      0
#define fcc_offset    256
#define cbits_offset  512
#define ctypes_offset (cbits_offset + cbit_length)
#define tables_length (ctypes_offset + 256)

/* Layout of the UCP type table that translates property names into codes for
ucp_findchar(). */

typedef struct {
  const char *name;
  int value;
} ucp_type_table;


/* Internal shared data tables. These are tables that are used by more than one
of the exported public functions. They have to be "external" in the C sense,
but are not part of the PCRE public API. The data for these tables is in the
pcre_tables.c module. */

extern const int    _pcre_utf8_table1[];
extern const int    _pcre_utf8_table2[];
extern const int    _pcre_utf8_table3[];
extern const uschar _pcre_utf8_table4[];

extern const int    _pcre_utf8_table1_size;

extern const ucp_type_table _pcre_utt[];
extern const int _pcre_utt_size;

extern const uschar _pcre_default_tables[];

extern const uschar _pcre_OP_lengths[];


/* Internal shared functions. These are functions that are used by more than
one of the exported public functions. They have to be "external" in the C
sense, but are not part of the PCRE public API. */

extern int         _pcre_ord2utf8(int, uschar *);
extern void        _pcre_printint(pcre *, FILE *);
extern real_pcre * _pcre_try_flipped(const real_pcre *, real_pcre *,
                     const pcre_study_data *, pcre_study_data *);
extern int         _pcre_ucp_findchar(const int, int *, int *);
extern int         _pcre_valid_utf8(const uschar *, int);
extern BOOL        _pcre_xclass(int, const uschar *);

/* End of pcre_internal.h */


/*************************************************
*      Code parameters and static tables         *
*************************************************/

/* Maximum number of items on the nested bracket stacks at compile time. This
applies to the nesting of all kinds of parentheses. It does not limit
un-nested, non-capturing parentheses. This number can be made bigger if
necessary - it is used to dimension one int and one unsigned char vector at
compile time. */

#define BRASTACK_SIZE 200


/* Table for handling escaped characters in the range '0'-'z'. Positive returns
are simple data values; negative values are for special things like \d and so
on. Zero means further processing is needed (for things like \x), or the escape
is invalid. */

#if !EBCDIC   /* This is the "normal" table for ASCII systems */
static const short int escapes[] = {
     0,      0,      0,      0,      0,      0,      0,      0,   /* 0 - 7 */
     0,      0,    ':',    ';',    '<',    '=',    '>',    '?',   /* 8 - ? */
   '@', -ESC_A, -ESC_B, -ESC_C, -ESC_D, -ESC_E,      0, -ESC_G,   /* @ - G */
     0,      0,      0,      0,      0,      0,      0,      0,   /* H - O */
-ESC_P, -ESC_Q,      0, -ESC_S,      0,      0,      0, -ESC_W,   /* P - W */
-ESC_X,      0, -ESC_Z,    '[',   '\\',    ']',    '^',    '_',   /* X - _ */
   '`',      7, -ESC_b,      0, -ESC_d,  ESC_e,  ESC_f,      0,   /* ` - g */
     0,      0,      0,      0,      0,      0,  ESC_n,      0,   /* h - o */
-ESC_p,      0,  ESC_r, -ESC_s,  ESC_tee,    0,      0, -ESC_w,   /* p - w */
     0,      0, -ESC_z                                            /* x - z */
};

#else         /* This is the "abnormal" table for EBCDIC systems */
static const short int escapes[] = {
/*  48 */     0,     0,      0,     '.',    '<',   '(',    '+',    '|',
/*  50 */   '&',     0,      0,       0,      0,     0,      0,      0,
/*  58 */     0,     0,    '!',     '$',    '*',   ')',    ';',    '~',
/*  60 */   '-',   '/',      0,       0,      0,     0,      0,      0,
/*  68 */     0,     0,    '|',     ',',    '%',   '_',    '>',    '?',
/*  70 */     0,     0,      0,       0,      0,     0,      0,      0,
/*  78 */     0,   '`',    ':',     '#',    '@',  '\'',    '=',    '"',
/*  80 */     0,     7, -ESC_b,       0, -ESC_d, ESC_e,  ESC_f,      0,
/*  88 */     0,     0,      0,     '{',      0,     0,      0,      0,
/*  90 */     0,     0,      0,     'l',      0, ESC_n,      0, -ESC_p,
/*  98 */     0, ESC_r,      0,     '}',      0,     0,      0,      0,
/*  A0 */     0,   '~', -ESC_s, ESC_tee,      0,     0, -ESC_w,      0,
/*  A8 */     0,-ESC_z,      0,       0,      0,   '[',      0,      0,
/*  B0 */     0,     0,      0,       0,      0,     0,      0,      0,
/*  B8 */     0,     0,      0,       0,      0,   ']',    '=',    '-',
/*  C0 */   '{',-ESC_A, -ESC_B,  -ESC_C, -ESC_D,-ESC_E,      0, -ESC_G,
/*  C8 */     0,     0,      0,       0,      0,     0,      0,      0,
/*  D0 */   '}',     0,      0,       0,      0,     0,      0, -ESC_P,
/*  D8 */-ESC_Q,     0,      0,       0,      0,     0,      0,      0,
/*  E0 */  '\\',     0, -ESC_S,       0,      0,     0, -ESC_W, -ESC_X,
/*  E8 */     0,-ESC_Z,      0,       0,      0,     0,      0,      0,
/*  F0 */     0,     0,      0,       0,      0,     0,      0,      0,
/*  F8 */     0,     0,      0,       0,      0,     0,      0,      0
};
#endif


/* Tables of names of POSIX character classes and their lengths. The list is
terminated by a zero length entry. The first three must be alpha, upper, lower,
as this is assumed for handling case independence. */

static const char *const posix_names[] = {
  "alpha", "lower", "upper",
  "alnum", "ascii", "blank", "cntrl", "digit", "graph",
  "print", "punct", "space", "word",  "xdigit" };

static const uschar posix_name_lengths[] = {
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 6, 0 };

/* Table of class bit maps for each POSIX class; up to three may be combined
to form the class. The table for [:blank:] is dynamically modified to remove
the vertical space characters. */

static const int posix_class_maps[] = {
  cbit_lower, cbit_upper, -1,             /* alpha */
  cbit_lower, -1,         -1,             /* lower */
  cbit_upper, -1,         -1,             /* upper */
  cbit_digit, cbit_lower, cbit_upper,     /* alnum */
  cbit_print, cbit_cntrl, -1,             /* ascii */
  cbit_space, -1,         -1,             /* blank - a GNU extension */
  cbit_cntrl, -1,         -1,             /* cntrl */
  cbit_digit, -1,         -1,             /* digit */
  cbit_graph, -1,         -1,             /* graph */
  cbit_print, -1,         -1,             /* print */
  cbit_punct, -1,         -1,             /* punct */
  cbit_space, -1,         -1,             /* space */
  cbit_word,  -1,         -1,             /* word - a Perl extension */
  cbit_xdigit,-1,         -1              /* xdigit */
};


/* The texts of compile-time error messages. These are "char *" because they
are passed to the outside world. */

static const char *error_texts[] = {
  "no error",
  "\\ at end of pattern",
  "\\c at end of pattern",
  "unrecognized character follows \\",
  "numbers out of order in {} quantifier",
  /* 5 */
  "number too big in {} quantifier",
  "missing terminating ] for character class",
  "invalid escape sequence in character class",
  "range out of order in character class",
  "nothing to repeat",
  /* 10 */
  "operand of unlimited repeat could match the empty string",
  "internal error: unexpected repeat",
  "unrecognized character after (?",
  "POSIX named classes are supported only within a class",
  "missing )",
  /* 15 */
  "reference to non-existent subpattern",
  "erroffset passed as NULL",
  "unknown option bit(s) set",
  "missing ) after comment",
  "parentheses nested too deeply",
  /* 20 */
  "regular expression too large",
  "failed to get memory",
  "unmatched parentheses",
  "internal error: code overflow",
  "unrecognized character after (?<",
  /* 25 */
  "lookbehind assertion is not fixed length",
  "malformed number after (?(",
  "conditional group contains more than two branches",
  "assertion expected after (?(",
  "(?R or (?digits must be followed by )",
  /* 30 */
  "unknown POSIX class name",
  "POSIX collating elements are not supported",
  "this version of PCRE is not compiled with PCRE_UTF8 support",
  "spare error",
  "character value in \\x{...} sequence is too large",
  /* 35 */
  "invalid condition (?(0)",
  "\\C not allowed in lookbehind assertion",
  "PCRE does not support \\L, \\l, \\N, \\U, or \\u",
  "number after (?C is > 255",
  "closing ) for (?C expected",
  /* 40 */
  "recursive call could loop indefinitely",
  "unrecognized character after (?P",
  "syntax error after (?P",
  "two named groups have the same name",
  "invalid UTF-8 string",
  /* 45 */
  "support for \\P, \\p, and \\X has not been compiled",
  "malformed \\P or \\p sequence",
  "unknown property name after \\P or \\p"
};


/* Table to identify digits and hex digits. This is used when compiling
patterns. Note that the tables in chartables are dependent on the locale, and
may mark arbitrary characters as digits - but the PCRE compiling code expects
to handle only 0-9, a-z, and A-Z as digits when compiling. That is why we have
a private table here. It costs 256 bytes, but it is a lot faster than doing
character value tests (at least in some simple cases I timed), and in some
applications one wants PCRE to compile efficiently as well as match
efficiently.

For convenience, we use the same bit definitions as in chartables:

  0x04   decimal digit
  0x08   hexadecimal digit

Then we can use ctype_digit and ctype_xdigit in the code. */

#if !EBCDIC    /* This is the "normal" case, for ASCII systems */
static const unsigned char digitab[] =
  {
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*   0-  7 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*   8- 15 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  16- 23 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  24- 31 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*    - '  */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  ( - /  */
  0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c, /*  0 - 7  */
  0x0c,0x0c,0x00,0x00,0x00,0x00,0x00,0x00, /*  8 - ?  */
  0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x00, /*  @ - G  */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  H - O  */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  P - W  */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  X - _  */
  0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x00, /*  ` - g  */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  h - o  */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  p - w  */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  x -127 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 128-135 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 136-143 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 144-151 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 152-159 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 160-167 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 168-175 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 176-183 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 184-191 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 192-199 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 200-207 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 208-215 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 216-223 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 224-231 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 232-239 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 240-247 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};/* 248-255 */

#else          /* This is the "abnormal" case, for EBCDIC systems */
static const unsigned char digitab[] =
  {
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*   0-  7  0 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*   8- 15    */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  16- 23 10 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  24- 31    */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  32- 39 20 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  40- 47    */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  48- 55 30 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  56- 63    */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*    - 71 40 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  72- |     */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  & - 87 50 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  88- ¬     */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  - -103 60 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 104- ?     */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 112-119 70 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 120- "     */
  0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x00, /* 128- g  80 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  h -143    */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 144- p  90 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  q -159    */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 160- x  A0 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  y -175    */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  ^ -183 B0 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 184-191    */
  0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x00, /*  { - G  C0 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  H -207    */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  } - P  D0 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  Q -223    */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  \ - X  E0 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  Y -239    */
  0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c, /*  0 - 7  F0 */
  0x0c,0x0c,0x00,0x00,0x00,0x00,0x00,0x00};/*  8 -255    */

static const unsigned char ebcdic_chartab[] = { /* chartable partial dup */
  0x80,0x00,0x00,0x00,0x00,0x01,0x00,0x00, /*   0-  7 */
  0x00,0x00,0x00,0x00,0x01,0x01,0x00,0x00, /*   8- 15 */
  0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00, /*  16- 23 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  24- 31 */
  0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00, /*  32- 39 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  40- 47 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  48- 55 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  56- 63 */
  0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*    - 71 */
  0x00,0x00,0x00,0x80,0x00,0x80,0x80,0x80, /*  72- |  */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  & - 87 */
  0x00,0x00,0x00,0x80,0x80,0x80,0x00,0x00, /*  88- ¬  */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  - -103 */
  0x00,0x00,0x00,0x00,0x00,0x10,0x00,0x80, /* 104- ?  */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 112-119 */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /* 120- "  */
  0x00,0x1a,0x1a,0x1a,0x1a,0x1a,0x1a,0x12, /* 128- g  */
  0x12,0x12,0x00,0x00,0x00,0x00,0x00,0x00, /*  h -143 */
  0x00,0x12,0x12,0x12,0x12,0x12,0x12,0x12, /* 144- p  */
  0x12,0x12,0x00,0x00,0x00,0x00,0x00,0x00, /*  q -159 */
  0x00,0x00,0x12,0x12,0x12,0x12,0x12,0x12, /* 160- x  */
  0x12,0x12,0x00,0x00,0x00,0x00,0x00,0x00, /*  y -175 */
  0x80,0x00,0x00,0x00,0x00,0x00,0x00,0x00, /*  ^ -183 */
  0x00,0x00,0x80,0x00,0x00,0x00,0x00,0x00, /* 184-191 */
  0x80,0x1a,0x1a,0x1a,0x1a,0x1a,0x1a,0x12, /*  { - G  */
  0x12,0x12,0x00,0x00,0x00,0x00,0x00,0x00, /*  H -207 */
  0x00,0x12,0x12,0x12,0x12,0x12,0x12,0x12, /*  } - P  */
  0x12,0x12,0x00,0x00,0x00,0x00,0x00,0x00, /*  Q -223 */
  0x00,0x00,0x12,0x12,0x12,0x12,0x12,0x12, /*  \ - X  */
  0x12,0x12,0x00,0x00,0x00,0x00,0x00,0x00, /*  Y -239 */
  0x1c,0x1c,0x1c,0x1c,0x1c,0x1c,0x1c,0x1c, /*  0 - 7  */
  0x1c,0x1c,0x00,0x00,0x00,0x00,0x00,0x00};/*  8 -255 */
#endif


/* Definition to allow mutual recursion */

static BOOL
  compile_regex(int, int, int *, uschar **, const uschar **, int *, BOOL, int,
    int *, int *, branch_chain *, compile_data *);



/*************************************************
*            Handle escapes                      *
*************************************************/

/* This function is called when a \ has been encountered. It either returns a
positive value for a simple escape such as \n, or a negative value which
encodes one of the more complicated things such as \d. When UTF-8 is enabled,
a positive value greater than 255 may be returned. On entry, ptr is pointing at
the \. On exit, it is on the final character of the escape sequence.

Arguments:
  ptrptr         points to the pattern position pointer
  errorcodeptr   points to the errorcode variable
  bracount       number of previous extracting brackets
  options        the options bits
  isclass        TRUE if inside a character class

Returns:         zero or positive => a data character
                 negative => a special escape sequence
                 on error, errorptr is set
*/

static int
check_escape(const uschar **ptrptr, int *errorcodeptr, int bracount,
  int options, BOOL isclass)
{
const uschar *ptr = *ptrptr;
int c, i;

/* If backslash is at the end of the pattern, it's an error. */

c = *(++ptr);
if (c == 0) *errorcodeptr = ERR1;

/* Non-alphamerics are literals. For digits or letters, do an initial lookup in
a table. A non-zero result is something that can be returned immediately.
Otherwise further processing may be required. */

#if !EBCDIC    /* ASCII coding */
else if (c < '0' || c > 'z') {}                           /* Not alphameric */
else if ((i = escapes[c - '0']) != 0) c = i;

#else          /* EBCDIC coding */
else if (c < 'a' || (ebcdic_chartab[c] & 0x0E) == 0) {}   /* Not alphameric */
else if ((i = escapes[c - 0x48]) != 0)  c = i;
#endif

/* Escapes that need further processing, or are illegal. */

else
  {
  const uschar *oldptr;
  switch (c)
    {
    /* A number of Perl escapes are not handled by PCRE. We give an explicit
    error. */

    case 'l':
    case 'L':
    case 'N':
    case 'u':
    case 'U':
    *errorcodeptr = ERR37;
    break;

    /* The handling of escape sequences consisting of a string of digits
    starting with one that is not zero is not straightforward. By experiment,
    the way Perl works seems to be as follows:

    Outside a character class, the digits are read as a decimal number. If the
    number is less than 10, or if there are that many previous extracting
    left brackets, then it is a back reference. Otherwise, up to three octal
    digits are read to form an escaped byte. Thus \123 is likely to be octal
    123 (cf \0123, which is octal 012 followed by the literal 3). If the octal
    value is greater than 377, the least significant 8 bits are taken. Inside a
    character class, \ followed by a digit is always an octal number. */

    case '1': case '2': case '3': case '4': case '5':
    case '6': case '7': case '8': case '9':

    if (!isclass)
      {
      oldptr = ptr;
      c -= '0';
      while ((digitab[ptr[1]] & ctype_digit) != 0)
        c = c * 10 + *(++ptr) - '0';
      if (c < 10 || c <= bracount)
        {
        c = -(ESC_REF + c);
        break;
        }
      ptr = oldptr;      /* Put the pointer back and fall through */
      }

    /* Handle an octal number following \. If the first digit is 8 or 9, Perl
    generates a binary zero byte and treats the digit as a following literal.
    Thus we have to pull back the pointer by one. */

    if ((c = *ptr) >= '8')
      {
      ptr--;
      c = 0;
      break;
      }

    /* \0 always starts an octal number, but we may drop through to here with a
    larger first octal digit. */

    case '0':
    c -= '0';
    while(i++ < 2 && ptr[1] >= '0' && ptr[1] <= '7')
        c = c * 8 + *(++ptr) - '0';
    c &= 255;     /* Take least significant 8 bits */
    break;

    /* \x is complicated when UTF-8 is enabled. \x{ddd} is a character number
    which can be greater than 0xff, but only if the ddd are hex digits. */

    case 'x':
#ifdef SUPPORT_UTF8
    if (ptr[1] == '{' && (options & PCRE_UTF8) != 0)
      {
      const uschar *pt = ptr + 2;
      register int count = 0;
      c = 0;
      while ((digitab[*pt] & ctype_xdigit) != 0)
        {
        int cc = *pt++;
        count++;
#if !EBCDIC    /* ASCII coding */
        if (cc >= 'a') cc -= 32;               /* Convert to upper case */
        c = c * 16 + cc - ((cc < 'A')? '0' : ('A' - 10));
#else          /* EBCDIC coding */
        if (cc >= 'a' && cc <= 'z') cc += 64;  /* Convert to upper case */
        c = c * 16 + cc - ((cc >= '0')? '0' : ('A' - 10));
#endif
        }
      if (*pt == '}')
        {
        if (c < 0 || count > 8) *errorcodeptr = ERR34;
        ptr = pt;
        break;
        }
      /* If the sequence of hex digits does not end with '}', then we don't
      recognize this construct; fall through to the normal \x handling. */
      }
#endif

    /* Read just a single hex char */

    c = 0;
    while (i++ < 2 && (digitab[ptr[1]] & ctype_xdigit) != 0)
      {
      int cc;                               /* Some compilers don't like ++ */
      cc = *(++ptr);                        /* in initializers */
#if !EBCDIC    /* ASCII coding */
      if (cc >= 'a') cc -= 32;              /* Convert to upper case */
      c = c * 16 + cc - ((cc < 'A')? '0' : ('A' - 10));
#else          /* EBCDIC coding */
      if (cc <= 'z') cc += 64;              /* Convert to upper case */
      c = c * 16 + cc - ((cc >= '0')? '0' : ('A' - 10));
#endif
      }
    break;

    /* Other special escapes not starting with a digit are straightforward */

    case 'c':
    c = *(++ptr);
    if (c == 0)
      {
      *errorcodeptr = ERR2;
      return 0;
      }

    /* A letter is upper-cased; then the 0x40 bit is flipped. This coding
    is ASCII-specific, but then the whole concept of \cx is ASCII-specific.
    (However, an EBCDIC equivalent has now been added.) */

#if !EBCDIC    /* ASCII coding */
    if (c >= 'a' && c <= 'z') c -= 32;
    c ^= 0x40;
#else          /* EBCDIC coding */
    if (c >= 'a' && c <= 'z') c += 64;
    c ^= 0xC0;
#endif
    break;

    /* PCRE_EXTRA enables extensions to Perl in the matter of escapes. Any
    other alphameric following \ is an error if PCRE_EXTRA was set; otherwise,
    for Perl compatibility, it is a literal. This code looks a bit odd, but
    there used to be some cases other than the default, and there may be again
    in future, so I haven't "optimized" it. */

    default:
    if ((options & PCRE_EXTRA) != 0) switch(c)
      {
      default:
      *errorcodeptr = ERR3;
      break;
      }
    break;
    }
  }

*ptrptr = ptr;
return c;
}



#ifdef SUPPORT_UCP
/*************************************************
*               Handle \P and \p                 *
*************************************************/

/* This function is called after \P or \p has been encountered, provided that
PCRE is compiled with support for Unicode properties. On entry, ptrptr is
pointing at the P or p. On exit, it is pointing at the final character of the
escape sequence.

Argument:
  ptrptr         points to the pattern position pointer
  negptr         points to a boolean that is set TRUE for negation else FALSE
  errorcodeptr   points to the error code variable

Returns:     value from ucp_type_table, or -1 for an invalid type
*/

static int
get_ucp(const uschar **ptrptr, BOOL *negptr, int *errorcodeptr)
{
int c, i, bot, top;
const uschar *ptr = *ptrptr;
char name[4];

c = *(++ptr);
if (c == 0) goto ERROR_RETURN;

*negptr = FALSE;

/* \P or \p can be followed by a one- or two-character name in {}, optionally
preceded by ^ for negation. */

if (c == '{')
  {
  if (ptr[1] == '^')
    {
    *negptr = TRUE;
    ptr++;
    }
  for (i = 0; i <= 2; i++)
    {
    c = *(++ptr);
    if (c == 0) goto ERROR_RETURN;
    if (c == '}') break;
    name[i] = c;
    }
  if (c !='}')   /* Try to distinguish error cases */
    {
    while (*(++ptr) != 0 && *ptr != '}');
    if (*ptr == '}') goto UNKNOWN_RETURN; else goto ERROR_RETURN;
    }
  name[i] = 0;
  }

/* Otherwise there is just one following character */

else
  {
  name[0] = c;
  name[1] = 0;
  }

*ptrptr = ptr;

/* Search for a recognized property name using binary chop */

bot = 0;
top = _pcre_utt_size;

while (bot < top)
  {
  i = (bot + top)/2;
  c = strcmp(name, _pcre_utt[i].name);
  if (c == 0) return _pcre_utt[i].value;
  if (c > 0) bot = i + 1; else top = i;
  }

UNKNOWN_RETURN:
*errorcodeptr = ERR47;
*ptrptr = ptr;
return -1;

ERROR_RETURN:
*errorcodeptr = ERR46;
*ptrptr = ptr;
return -1;
}
#endif




/*************************************************
*            Check for counted repeat            *
*************************************************/

/* This function is called when a '{' is encountered in a place where it might
start a quantifier. It looks ahead to see if it really is a quantifier or not.
It is only a quantifier if it is one of the forms {ddd} {ddd,} or {ddd,ddd}
where the ddds are digits.

Arguments:
  p         pointer to the first char after '{'

Returns:    TRUE or FALSE
*/

static BOOL
is_counted_repeat(const uschar *p)
{
if ((digitab[*p++] & ctype_digit) == 0) return FALSE;
while ((digitab[*p] & ctype_digit) != 0) p++;
if (*p == '}') return TRUE;

if (*p++ != ',') return FALSE;
if (*p == '}') return TRUE;

if ((digitab[*p++] & ctype_digit) == 0) return FALSE;
while ((digitab[*p] & ctype_digit) != 0) p++;

return (*p == '}');
}



/*************************************************
*         Read repeat counts                     *
*************************************************/

/* Read an item of the form {n,m} and return the values. This is called only
after is_counted_repeat() has confirmed that a repeat-count quantifier exists,
so the syntax is guaranteed to be correct, but we need to check the values.

Arguments:
  p              pointer to first char after '{'
  minp           pointer to int for min
  maxp           pointer to int for max
                 returned as -1 if no max
  errorcodeptr   points to error code variable

Returns:         pointer to '}' on success;
                 current ptr on error, with errorcodeptr set non-zero
*/

static const uschar *
read_repeat_counts(const uschar *p, int *minp, int *maxp, int *errorcodeptr)
{
int min = 0;
int max = -1;

/* Read the minimum value and do a paranoid check: a negative value indicates
an integer overflow. */

while ((digitab[*p] & ctype_digit) != 0) min = min * 10 + *p++ - '0';
if (min < 0 || min > 65535)
  {
  *errorcodeptr = ERR5;
  return p;
  }

/* Read the maximum value if there is one, and again do a paranoid on its size.
Also, max must not be less than min. */

if (*p == '}') max = min; else
  {
  if (*(++p) != '}')
    {
    max = 0;
    while((digitab[*p] & ctype_digit) != 0) max = max * 10 + *p++ - '0';
    if (max < 0 || max > 65535)
      {
      *errorcodeptr = ERR5;
      return p;
      }
    if (max < min)
      {
      *errorcodeptr = ERR4;
      return p;
      }
    }
  }

/* Fill in the required variables, and pass back the pointer to the terminating
'}'. */

*minp = min;
*maxp = max;
return p;
}



/*************************************************
*      Find first significant op code            *
*************************************************/

/* This is called by several functions that scan a compiled expression looking
for a fixed first character, or an anchoring op code etc. It skips over things
that do not influence this. For some calls, a change of option is important.
For some calls, it makes sense to skip negative forward and all backward
assertions, and also the \b assertion; for others it does not.

Arguments:
  code         pointer to the start of the group
  options      pointer to external options
  optbit       the option bit whose changing is significant, or
                 zero if none are
  skipassert   TRUE if certain assertions are to be skipped

Returns:       pointer to the first significant opcode
*/

static const uschar*
first_significant_code(const uschar *code, int *options, int optbit,
  BOOL skipassert)
{
for (;;)
  {
  switch ((int)*code)
    {
    case OP_OPT:
    if (optbit > 0 && ((int)code[1] & optbit) != (*options & optbit))
      *options = (int)code[1];
    code += 2;
    break;

    case OP_ASSERT_NOT:
    case OP_ASSERTBACK:
    case OP_ASSERTBACK_NOT:
    if (!skipassert) return code;
    do code += GET(code, 1); while (*code == OP_ALT);
    code += _pcre_OP_lengths[*code];
    break;

    case OP_WORD_BOUNDARY:
    case OP_NOT_WORD_BOUNDARY:
    if (!skipassert) return code;
    /* Fall through */

    case OP_CALLOUT:
    case OP_CREF:
    case OP_BRANUMBER:
    code += _pcre_OP_lengths[*code];
    break;

    default:
    return code;
    }
  }
/* Control never reaches here */
}




/*************************************************
*        Find the fixed length of a pattern      *
*************************************************/

/* Scan a pattern and compute the fixed length of subject that will match it,
if the length is fixed. This is needed for dealing with backward assertions.
In UTF8 mode, the result is in characters rather than bytes.

Arguments:
  code     points to the start of the pattern (the bracket)
  options  the compiling options

Returns:   the fixed length, or -1 if there is no fixed length,
             or -2 if \C was encountered
*/

static int
find_fixedlength(uschar *code, int options)
{
int length = -1;

register int branchlength = 0;
register uschar *cc = code + 1 + LINK_SIZE;

/* Scan along the opcodes for this branch. If we get to the end of the
branch, check the length against that of the other branches. */

for (;;)
  {
  int d;
  register int op = *cc;
  if (op >= OP_BRA) op = OP_BRA;

  switch (op)
    {
    case OP_BRA:
    case OP_ONCE:
    case OP_COND:
    d = find_fixedlength(cc, options);
    if (d < 0) return d;
    branchlength += d;
    do cc += GET(cc, 1); while (*cc == OP_ALT);
    cc += 1 + LINK_SIZE;
    break;

    /* Reached end of a branch; if it's a ket it is the end of a nested
    call. If it's ALT it is an alternation in a nested call. If it is
    END it's the end of the outer call. All can be handled by the same code. */

    case OP_ALT:
    case OP_KET:
    case OP_KETRMAX:
    case OP_KETRMIN:
    case OP_END:
    if (length < 0) length = branchlength;
      else if (length != branchlength) return -1;
    if (*cc != OP_ALT) return length;
    cc += 1 + LINK_SIZE;
    branchlength = 0;
    break;

    /* Skip over assertive subpatterns */

    case OP_ASSERT:
    case OP_ASSERT_NOT:
    case OP_ASSERTBACK:
    case OP_ASSERTBACK_NOT:
    do cc += GET(cc, 1); while (*cc == OP_ALT);
    /* Fall through */

    /* Skip over things that don't match chars */

    case OP_REVERSE:
    case OP_BRANUMBER:
    case OP_CREF:
    case OP_OPT:
    case OP_CALLOUT:
    case OP_SOD:
    case OP_SOM:
    case OP_EOD:
    case OP_EODN:
    case OP_CIRC:
    case OP_DOLL:
    case OP_NOT_WORD_BOUNDARY:
    case OP_WORD_BOUNDARY:
    cc += _pcre_OP_lengths[*cc];
    break;

    /* Handle literal characters */

    case OP_CHAR:
    case OP_CHARNC:
    branchlength++;
    cc += 2;
#ifdef SUPPORT_UTF8
    if ((options & PCRE_UTF8) != 0)
      {
      while ((*cc & 0xc0) == 0x80) cc++;
      }
#endif
    break;

    /* Handle exact repetitions. The count is already in characters, but we
    need to skip over a multibyte character in UTF8 mode.  */

    case OP_EXACT:
    branchlength += GET2(cc,1);
    cc += 4;
#ifdef SUPPORT_UTF8
    if ((options & PCRE_UTF8) != 0)
      {
      while((*cc & 0x80) == 0x80) cc++;
      }
#endif
    break;

    case OP_TYPEEXACT:
    branchlength += GET2(cc,1);
    cc += 4;
    break;

    /* Handle single-char matchers */

    case OP_PROP:
    case OP_NOTPROP:
    cc++;
    /* Fall through */

    case OP_NOT_DIGIT:
    case OP_DIGIT:
    case OP_NOT_WHITESPACE:
    case OP_WHITESPACE:
    case OP_NOT_WORDCHAR:
    case OP_WORDCHAR:
    case OP_ANY:
    branchlength++;
    cc++;
    break;

    /* The single-byte matcher isn't allowed */

    case OP_ANYBYTE:
    return -2;

    /* Check a class for variable quantification */

#ifdef SUPPORT_UTF8
    case OP_XCLASS:
    cc += GET(cc, 1) - 33;
    /* Fall through */
#endif

    case OP_CLASS:
    case OP_NCLASS:
    cc += 33;

    switch (*cc)
      {
      case OP_CRSTAR:
      case OP_CRMINSTAR:
      case OP_CRQUERY:
      case OP_CRMINQUERY:
      return -1;

      case OP_CRRANGE:
      case OP_CRMINRANGE:
      if (GET2(cc,1) != GET2(cc,3)) return -1;
      branchlength += GET2(cc,1);
      cc += 5;
      break;

      default:
      branchlength++;
      }
    break;

    /* Anything else is variable length */

    default:
    return -1;
    }
  }
/* Control never gets here */
}




/*************************************************
*    Scan compiled regex for numbered bracket    *
*************************************************/

/* This little function scans through a compiled pattern until it finds a
capturing bracket with the given number.

Arguments:
  code        points to start of expression
  utf8        TRUE in UTF-8 mode
  number      the required bracket number

Returns:      pointer to the opcode for the bracket, or NULL if not found
*/

static const uschar *
find_bracket(const uschar *code, BOOL utf8, int number)
{
#ifndef SUPPORT_UTF8
utf8 = utf8;               /* Stop pedantic compilers complaining */
#endif

for (;;)
  {
  register int c = *code;
  if (c == OP_END) return NULL;
  else if (c > OP_BRA)
    {
    int n = c - OP_BRA;
    if (n > EXTRACT_BASIC_MAX) n = GET2(code, 2+LINK_SIZE);
    if (n == number) return (uschar *)code;
    code += _pcre_OP_lengths[OP_BRA];
    }
  else
    {
    code += _pcre_OP_lengths[c];

#ifdef SUPPORT_UTF8

    /* In UTF-8 mode, opcodes that are followed by a character may be followed
    by a multi-byte character. The length in the table is a minimum, so we have
    to scan along to skip the extra bytes. All opcodes are less than 128, so we
    can use relatively efficient code. */

    if (utf8) switch(c)
      {
      case OP_CHAR:
      case OP_CHARNC:
      case OP_EXACT:
      case OP_UPTO:
      case OP_MINUPTO:
      case OP_STAR:
      case OP_MINSTAR:
      case OP_PLUS:
      case OP_MINPLUS:
      case OP_QUERY:
      case OP_MINQUERY:
      while ((*code & 0xc0) == 0x80) code++;
      break;

      /* XCLASS is used for classes that cannot be represented just by a bit
      map. This includes negated single high-valued characters. The length in
      the table is zero; the actual length is stored in the compiled code. */

      case OP_XCLASS:
      code += GET(code, 1) + 1;
      break;
      }
#endif
    }
  }
}



/*************************************************
*   Scan compiled regex for recursion reference  *
*************************************************/

/* This little function scans through a compiled pattern until it finds an
instance of OP_RECURSE.

Arguments:
  code        points to start of expression
  utf8        TRUE in UTF-8 mode

Returns:      pointer to the opcode for OP_RECURSE, or NULL if not found
*/

static const uschar *
find_recurse(const uschar *code, BOOL utf8)
{
#ifndef SUPPORT_UTF8
utf8 = utf8;               /* Stop pedantic compilers complaining */
#endif

for (;;)
  {
  register int c = *code;
  if (c == OP_END) return NULL;
  else if (c == OP_RECURSE) return code;
  else if (c > OP_BRA)
    {
    code += _pcre_OP_lengths[OP_BRA];
    }
  else
    {
    code += _pcre_OP_lengths[c];

#ifdef SUPPORT_UTF8

    /* In UTF-8 mode, opcodes that are followed by a character may be followed
    by a multi-byte character. The length in the table is a minimum, so we have
    to scan along to skip the extra bytes. All opcodes are less than 128, so we
    can use relatively efficient code. */

    if (utf8) switch(c)
      {
      case OP_CHAR:
      case OP_CHARNC:
      case OP_EXACT:
      case OP_UPTO:
      case OP_MINUPTO:
      case OP_STAR:
      case OP_MINSTAR:
      case OP_PLUS:
      case OP_MINPLUS:
      case OP_QUERY:
      case OP_MINQUERY:
      while ((*code & 0xc0) == 0x80) code++;
      break;

      /* XCLASS is used for classes that cannot be represented just by a bit
      map. This includes negated single high-valued characters. The length in
      the table is zero; the actual length is stored in the compiled code. */

      case OP_XCLASS:
      code += GET(code, 1) + 1;
      break;
      }
#endif
    }
  }
}



/*************************************************
*    Scan compiled branch for non-emptiness      *
*************************************************/

/* This function scans through a branch of a compiled pattern to see whether it
can match the empty string or not. It is called only from could_be_empty()
below. Note that first_significant_code() skips over assertions. If we hit an
unclosed bracket, we return "empty" - this means we've struck an inner bracket
whose current branch will already have been scanned.

Arguments:
  code        points to start of search
  endcode     points to where to stop
  utf8        TRUE if in UTF8 mode

Returns:      TRUE if what is matched could be empty
*/

static BOOL
could_be_empty_branch(const uschar *code, const uschar *endcode, BOOL utf8)
{
register int c;
for (code = first_significant_code(code + 1 + LINK_SIZE, NULL, 0, TRUE);
     code < endcode;
     code = first_significant_code(code + _pcre_OP_lengths[c], NULL, 0, TRUE))
  {
  const uschar *ccode;

  c = *code;

  if (c >= OP_BRA)
    {
    BOOL empty_branch;
    if (GET(code, 1) == 0) return TRUE;    /* Hit unclosed bracket */

    /* Scan a closed bracket */

    empty_branch = FALSE;
    do
      {
      if (!empty_branch && could_be_empty_branch(code, endcode, utf8))
        empty_branch = TRUE;
      code += GET(code, 1);
      }
    while (*code == OP_ALT);
    if (!empty_branch) return FALSE;   /* All branches are non-empty */
    code += 1 + LINK_SIZE;
    c = *code;
    }

  else switch (c)
    {
    /* Check for quantifiers after a class */

#ifdef SUPPORT_UTF8
    case OP_XCLASS:
    ccode = code + GET(code, 1);
    goto CHECK_CLASS_REPEAT;
#endif

    case OP_CLASS:
    case OP_NCLASS:
    ccode = code + 33;

#ifdef SUPPORT_UTF8
    CHECK_CLASS_REPEAT:
#endif

    switch (*ccode)
      {
      case OP_CRSTAR:            /* These could be empty; continue */
      case OP_CRMINSTAR:
      case OP_CRQUERY:
      case OP_CRMINQUERY:
      break;

      default:                   /* Non-repeat => class must match */
      case OP_CRPLUS:            /* These repeats aren't empty */
      case OP_CRMINPLUS:
      return FALSE;

      case OP_CRRANGE:
      case OP_CRMINRANGE:
      if (GET2(ccode, 1) > 0) return FALSE;  /* Minimum > 0 */
      break;
      }
    break;

    /* Opcodes that must match a character */

    case OP_PROP:
    case OP_NOTPROP:
    case OP_EXTUNI:
    case OP_NOT_DIGIT:
    case OP_DIGIT:
    case OP_NOT_WHITESPACE:
    case OP_WHITESPACE:
    case OP_NOT_WORDCHAR:
    case OP_WORDCHAR:
    case OP_ANY:
    case OP_ANYBYTE:
    case OP_CHAR:
    case OP_CHARNC:
    case OP_NOT:
    case OP_PLUS:
    case OP_MINPLUS:
    case OP_EXACT:
    case OP_NOTPLUS:
    case OP_NOTMINPLUS:
    case OP_NOTEXACT:
    case OP_TYPEPLUS:
    case OP_TYPEMINPLUS:
    case OP_TYPEEXACT:
    return FALSE;

    /* End of branch */

    case OP_KET:
    case OP_KETRMAX:
    case OP_KETRMIN:
    case OP_ALT:
    return TRUE;

    /* In UTF-8 mode, STAR, MINSTAR, QUERY, MINQUERY, UPTO, and MINUPTO  may be
    followed by a multibyte character */

#ifdef SUPPORT_UTF8
    case OP_STAR:
    case OP_MINSTAR:
    case OP_QUERY:
    case OP_MINQUERY:
    case OP_UPTO:
    case OP_MINUPTO:
    if (utf8) while ((code[2] & 0xc0) == 0x80) code++;
    break;
#endif
    }
  }

return TRUE;
}



/*************************************************
*    Scan compiled regex for non-emptiness       *
*************************************************/

/* This function is called to check for left recursive calls. We want to check
the current branch of the current pattern to see if it could match the empty
string. If it could, we must look outwards for branches at other levels,
stopping when we pass beyond the bracket which is the subject of the recursion.

Arguments:
  code        points to start of the recursion
  endcode     points to where to stop (current RECURSE item)
  bcptr       points to the chain of current (unclosed) branch starts
  utf8        TRUE if in UTF-8 mode

Returns:      TRUE if what is matched could be empty
*/

static BOOL
could_be_empty(const uschar *code, const uschar *endcode, branch_chain *bcptr,
  BOOL utf8)
{
while (bcptr != NULL && bcptr->current >= code)
  {
  if (!could_be_empty_branch(bcptr->current, endcode, utf8)) return FALSE;
  bcptr = bcptr->outer;
  }
return TRUE;
}



/*************************************************
*           Check for POSIX class syntax         *
*************************************************/

/* This function is called when the sequence "[:" or "[." or "[=" is
encountered in a character class. It checks whether this is followed by an
optional ^ and then a sequence of letters, terminated by a matching ":]" or
".]" or "=]".

Argument:
  ptr      pointer to the initial [
  endptr   where to return the end pointer
  cd       pointer to compile data

Returns:   TRUE or FALSE
*/

static BOOL
check_posix_syntax(const uschar *ptr, const uschar **endptr, compile_data *cd)
{
int terminator;          /* Don't combine these lines; the Solaris cc */
terminator = *(++ptr);   /* compiler warns about "non-constant" initializer. */
if (*(++ptr) == '^') ptr++;
while ((cd->ctypes[*ptr] & ctype_letter) != 0) ptr++;
if (*ptr == terminator && ptr[1] == ']')
  {
  *endptr = ptr;
  return TRUE;
  }
return FALSE;
}




/*************************************************
*          Check POSIX class name                *
*************************************************/

/* This function is called to check the name given in a POSIX-style class entry
such as [:alnum:].

Arguments:
  ptr        points to the first letter
  len        the length of the name

Returns:     a value representing the name, or -1 if unknown
*/

static int
check_posix_name(const uschar *ptr, int len)
{
register int yield = 0;
while (posix_name_lengths[yield] != 0)
  {
  if (len == posix_name_lengths[yield] &&
    strncmp((const char *)ptr, posix_names[yield], len) == 0) return yield;
  yield++;
  }
return -1;
}


/*************************************************
*    Adjust OP_RECURSE items in repeated group   *
*************************************************/

/* OP_RECURSE items contain an offset from the start of the regex to the group
that is referenced. This means that groups can be replicated for fixed
repetition simply by copying (because the recursion is allowed to refer to
earlier groups that are outside the current group). However, when a group is
optional (i.e. the minimum quantifier is zero), OP_BRAZERO is inserted before
it, after it has been compiled. This means that any OP_RECURSE items within it
that refer to the group itself or any contained groups have to have their
offsets adjusted. That is the job of this function. Before it is called, the
partially compiled regex must be temporarily terminated with OP_END.

Arguments:
  group      points to the start of the group
  adjust     the amount by which the group is to be moved
  utf8       TRUE in UTF-8 mode
  cd         contains pointers to tables etc.

Returns:     nothing
*/

static void
adjust_recurse(uschar *group, int adjust, BOOL utf8, compile_data *cd)
{
uschar *ptr = group;
while ((ptr = (uschar *)find_recurse(ptr, utf8)) != NULL)
  {
  int offset = GET(ptr, 1);
  if (cd->start_code + offset >= group) PUT(ptr, 1, offset + adjust);
  ptr += 1 + LINK_SIZE;
  }
}



/*************************************************
*        Insert an automatic callout point       *
*************************************************/

/* This function is called when the PCRE_AUTO_CALLOUT option is set, to insert
callout points before each pattern item.

Arguments:
  code           current code pointer
  ptr            current pattern pointer
  cd             pointers to tables etc

Returns:         new code pointer
*/

static uschar *
auto_callout(uschar *code, const uschar *ptr, compile_data *cd)
{
*code++ = OP_CALLOUT;
*code++ = 255;
PUT(code, 0, ptr - cd->start_pattern);  /* Pattern offset */
PUT(code, LINK_SIZE, 0);                /* Default length */
return code + 2*LINK_SIZE;
}



/*************************************************
*         Complete a callout item                *
*************************************************/

/* A callout item contains the length of the next item in the pattern, which
we can't fill in till after we have reached the relevant point. This is used
for both automatic and manual callouts.

Arguments:
  previous_callout   points to previous callout item
  ptr                current pattern pointer
  cd                 pointers to tables etc

Returns:             nothing
*/

static void
complete_callout(uschar *previous_callout, const uschar *ptr, compile_data *cd)
{
int length = ptr - cd->start_pattern - GET(previous_callout, 2);
PUT(previous_callout, 2 + LINK_SIZE, length);
}



#ifdef SUPPORT_UCP
/*************************************************
*           Get othercase range                  *
*************************************************/

/* This function is passed the start and end of a class range, in UTF-8 mode
with UCP support. It searches up the characters, looking for internal ranges of
characters in the "other" case. Each call returns the next one, updating the
start address.

Arguments:
  cptr        points to starting character value; updated
  d           end value
  ocptr       where to put start of othercase range
  odptr       where to put end of othercase range

Yield:        TRUE when range returned; FALSE when no more
*/

static BOOL
get_othercase_range(int *cptr, int d, int *ocptr, int *odptr)
{
int c, chartype, othercase, next;

for (c = *cptr; c <= d; c++)
  {
  if (_pcre_ucp_findchar(c, &chartype, &othercase) == ucp_L && othercase != 0)
    break;
  }

if (c > d) return FALSE;

*ocptr = othercase;
next = othercase + 1;

for (++c; c <= d; c++)
  {
  if (_pcre_ucp_findchar(c, &chartype, &othercase) != ucp_L ||
        othercase != next)
    break;
  next++;
  }

*odptr = next - 1;
*cptr = c;

return TRUE;
}
#endif  /* SUPPORT_UCP */


/*************************************************
*           Compile one branch                   *
*************************************************/

/* Scan the pattern, compiling it into the code vector. If the options are
changed during the branch, the pointer is used to change the external options
bits.

Arguments:
  optionsptr     pointer to the option bits
  brackets       points to number of extracting brackets used
  codeptr        points to the pointer to the current code point
  ptrptr         points to the current pattern pointer
  errorcodeptr   points to error code variable
  firstbyteptr   set to initial literal character, or < 0 (REQ_UNSET, REQ_NONE)
  reqbyteptr     set to the last literal character required, else < 0
  bcptr          points to current branch chain
  cd             contains pointers to tables etc.

Returns:         TRUE on success
                 FALSE, with *errorcodeptr set non-zero on error
*/

static BOOL
compile_branch(int *optionsptr, int *brackets, uschar **codeptr,
  const uschar **ptrptr, int *errorcodeptr, int *firstbyteptr,
  int *reqbyteptr, branch_chain *bcptr, compile_data *cd)
{
int repeat_type, op_type;
int repeat_min = 0, repeat_max = 0;      /* To please picky compilers */
int bravalue = 0;
int greedy_default, greedy_non_default;
int firstbyte, reqbyte;
int zeroreqbyte, zerofirstbyte;
int req_caseopt, reqvary, tempreqvary;
int condcount = 0;
int options = *optionsptr;
int after_manual_callout = 0;
register int c;
register uschar *code = *codeptr;
uschar *tempcode;
BOOL inescq = FALSE;
BOOL groupsetfirstbyte = FALSE;
const uschar *ptr = *ptrptr;
const uschar *tempptr;
uschar *previous = NULL;
uschar *previous_callout = NULL;
uschar classbits[32];

#ifdef SUPPORT_UTF8
BOOL class_utf8;
BOOL utf8 = (options & PCRE_UTF8) != 0;
uschar *class_utf8data;
uschar utf8_char[6];
#else
BOOL utf8 = FALSE;
#endif

/* Set up the default and non-default settings for greediness */

greedy_default = ((options & PCRE_UNGREEDY) != 0);
greedy_non_default = greedy_default ^ 1;

/* Initialize no first byte, no required byte. REQ_UNSET means "no char
matching encountered yet". It gets changed to REQ_NONE if we hit something that
matches a non-fixed char first char; reqbyte just remains unset if we never
find one.

When we hit a repeat whose minimum is zero, we may have to adjust these values
to take the zero repeat into account. This is implemented by setting them to
zerofirstbyte and zeroreqbyte when such a repeat is encountered. The individual
item types that can be repeated set these backoff variables appropriately. */

firstbyte = reqbyte = zerofirstbyte = zeroreqbyte = REQ_UNSET;

/* The variable req_caseopt contains either the REQ_CASELESS value or zero,
according to the current setting of the caseless flag. REQ_CASELESS is a bit
value > 255. It is added into the firstbyte or reqbyte variables to record the
case status of the value. This is used only for ASCII characters. */

req_caseopt = ((options & PCRE_CASELESS) != 0)? REQ_CASELESS : 0;

/* Switch on next character until the end of the branch */

for (;; ptr++)
  {
  BOOL negate_class;
  BOOL possessive_quantifier;
  BOOL is_quantifier;
  int class_charcount;
  int class_lastchar;
  int newoptions;
  int recno;
  int skipbytes;
  int subreqbyte;
  int subfirstbyte;
  int mclength;
  uschar mcbuffer[8];

  /* Next byte in the pattern */

  c = *ptr;

  /* If in \Q...\E, check for the end; if not, we have a literal */

  if (inescq && c != 0)
    {
    if (c == '\\' && ptr[1] == 'E')
      {
      inescq = FALSE;
      ptr++;
      continue;
      }
    else
      {
      if (previous_callout != NULL)
        {
        complete_callout(previous_callout, ptr, cd);
        previous_callout = NULL;
        }
      if ((options & PCRE_AUTO_CALLOUT) != 0)
        {
        previous_callout = code;
        code = auto_callout(code, ptr, cd);
        }
      goto NORMAL_CHAR;
      }
    }

  /* Fill in length of a previous callout, except when the next thing is
  a quantifier. */

  is_quantifier = c == '*' || c == '+' || c == '?' ||
    (c == '{' && is_counted_repeat(ptr+1));

  if (!is_quantifier && previous_callout != NULL &&
       after_manual_callout-- <= 0)
    {
    complete_callout(previous_callout, ptr, cd);
    previous_callout = NULL;
    }

  /* In extended mode, skip white space and comments */

  if ((options & PCRE_EXTENDED) != 0)
    {
    if ((cd->ctypes[c] & ctype_space) != 0) continue;
    if (c == '#')
      {
      /* The space before the ; is to avoid a warning on a silly compiler
      on the Macintosh. */
      while ((c = *(++ptr)) != 0 && c != NEWLINE) ;
      if (c != 0) continue;   /* Else fall through to handle end of string */
      }
    }

  /* No auto callout for quantifiers. */

  if ((options & PCRE_AUTO_CALLOUT) != 0 && !is_quantifier)
    {
    previous_callout = code;
    code = auto_callout(code, ptr, cd);
    }

  switch(c)
    {
    /* The branch terminates at end of string, |, or ). */

    case 0:
    case '|':
    case ')':
    *firstbyteptr = firstbyte;
    *reqbyteptr = reqbyte;
    *codeptr = code;
    *ptrptr = ptr;
    return TRUE;

    /* Handle single-character metacharacters. In multiline mode, ^ disables
    the setting of any following char as a first character. */

    case '^':
    if ((options & PCRE_MULTILINE) != 0)
      {
      if (firstbyte == REQ_UNSET) firstbyte = REQ_NONE;
      }
    previous = NULL;
    *code++ = OP_CIRC;
    break;

    case '$':
    previous = NULL;
    *code++ = OP_DOLL;
    break;

    /* There can never be a first char if '.' is first, whatever happens about
    repeats. The value of reqbyte doesn't change either. */

    case '.':
    if (firstbyte == REQ_UNSET) firstbyte = REQ_NONE;
    zerofirstbyte = firstbyte;
    zeroreqbyte = reqbyte;
    previous = code;
    *code++ = OP_ANY;
    break;

    /* Character classes. If the included characters are all < 255 in value, we
    build a 32-byte bitmap of the permitted characters, except in the special
    case where there is only one such character. For negated classes, we build
    the map as usual, then invert it at the end. However, we use a different
    opcode so that data characters > 255 can be handled correctly.

    If the class contains characters outside the 0-255 range, a different
    opcode is compiled. It may optionally have a bit map for characters < 256,
    but those above are are explicitly listed afterwards. A flag byte tells
    whether the bitmap is present, and whether this is a negated class or not.
    */

    case '[':
    previous = code;

    /* PCRE supports POSIX class stuff inside a class. Perl gives an error if
    they are encountered at the top level, so we'll do that too. */

    if ((ptr[1] == ':' || ptr[1] == '.' || ptr[1] == '=') &&
        check_posix_syntax(ptr, &tempptr, cd))
      {
      *errorcodeptr = (ptr[1] == ':')? ERR13 : ERR31;
      goto FAILED;
      }

    /* If the first character is '^', set the negation flag and skip it. */

    if ((c = *(++ptr)) == '^')
      {
      negate_class = TRUE;
      c = *(++ptr);
      }
    else
      {
      negate_class = FALSE;
      }

    /* Keep a count of chars with values < 256 so that we can optimize the case
    of just a single character (as long as it's < 256). For higher valued UTF-8
    characters, we don't yet do any optimization. */

    class_charcount = 0;
    class_lastchar = -1;

#ifdef SUPPORT_UTF8
    class_utf8 = FALSE;                       /* No chars >= 256 */
    class_utf8data = code + LINK_SIZE + 34;   /* For UTF-8 items */
#endif

    /* Initialize the 32-char bit map to all zeros. We have to build the
    map in a temporary bit of store, in case the class contains only 1
    character (< 256), because in that case the compiled code doesn't use the
    bit map. */

    memset(classbits, 0, 32 * sizeof(uschar));

    /* Process characters until ] is reached. By writing this as a "do" it
    means that an initial ] is taken as a data character. The first pass
    through the regex checked the overall syntax, so we don't need to be very
    strict here. At the start of the loop, c contains the first byte of the
    character. */

    do
      {
#ifdef SUPPORT_UTF8
      if (utf8 && c > 127)
        {                           /* Braces are required because the */
        GETCHARLEN(c, ptr, ptr);    /* macro generates multiple statements */
        }
#endif

      /* Inside \Q...\E everything is literal except \E */

      if (inescq)
        {
        if (c == '\\' && ptr[1] == 'E')
          {
          inescq = FALSE;
          ptr++;
          continue;
          }
        else goto LONE_SINGLE_CHARACTER;
        }

      /* Handle POSIX class names. Perl allows a negation extension of the
      form [:^name:]. A square bracket that doesn't match the syntax is
      treated as a literal. We also recognize the POSIX constructions
      [.ch.] and [=ch=] ("collating elements") and fault them, as Perl
      5.6 and 5.8 do. */

      if (c == '[' &&
          (ptr[1] == ':' || ptr[1] == '.' || ptr[1] == '=') &&
          check_posix_syntax(ptr, &tempptr, cd))
        {
        BOOL local_negate = FALSE;
        int posix_class, i;
        register const uschar *cbits = cd->cbits;

        if (ptr[1] != ':')
          {
          *errorcodeptr = ERR31;
          goto FAILED;
          }

        ptr += 2;
        if (*ptr == '^')
          {
          local_negate = TRUE;
          ptr++;
          }

        posix_class = check_posix_name(ptr, tempptr - ptr);
        if (posix_class < 0)
          {
          *errorcodeptr = ERR30;
          goto FAILED;
          }

        /* If matching is caseless, upper and lower are converted to
        alpha. This relies on the fact that the class table starts with
        alpha, lower, upper as the first 3 entries. */

        if ((options & PCRE_CASELESS) != 0 && posix_class <= 2)
          posix_class = 0;

        /* Or into the map we are building up to 3 of the static class
        tables, or their negations. The [:blank:] class sets up the same
        chars as the [:space:] class (all white space). We remove the vertical
        white space chars afterwards. */

        posix_class *= 3;
        for (i = 0; i < 3; i++)
          {
          BOOL blankclass = strncmp((char *)ptr, "blank", 5) == 0;
          int taboffset = posix_class_maps[posix_class + i];
          if (taboffset < 0) break;
          if (local_negate)
            {
            if (i == 0)
              for (c = 0; c < 32; c++) classbits[c] |= ~cbits[c+taboffset];
            else
              for (c = 0; c < 32; c++) classbits[c] &= ~cbits[c+taboffset];
            if (blankclass) classbits[1] |= 0x3c;
            }
          else
            {
            for (c = 0; c < 32; c++) classbits[c] |= cbits[c+taboffset];
            if (blankclass) classbits[1] &= ~0x3c;
            }
          }

        ptr = tempptr + 1;
        class_charcount = 10;  /* Set > 1; assumes more than 1 per class */
        continue;    /* End of POSIX syntax handling */
        }

      /* Backslash may introduce a single character, or it may introduce one
      of the specials, which just set a flag. Escaped items are checked for
      validity in the pre-compiling pass. The sequence \b is a special case.
      Inside a class (and only there) it is treated as backspace. Elsewhere
      it marks a word boundary. Other escapes have preset maps ready to
      or into the one we are building. We assume they have more than one
      character in them, so set class_charcount bigger than one. */

      if (c == '\\')
        {
        c = check_escape(&ptr, errorcodeptr, *brackets, options, TRUE);

        if (-c == ESC_b) c = '\b';       /* \b is backslash in a class */
        else if (-c == ESC_X) c = 'X';   /* \X is literal X in a class */
        else if (-c == ESC_Q)            /* Handle start of quoted string */
          {
          if (ptr[1] == '\\' && ptr[2] == 'E')
            {
            ptr += 2; /* avoid empty string */
            }
          else inescq = TRUE;
          continue;
          }

        if (c < 0)
          {
          register const uschar *cbits = cd->cbits;
          class_charcount += 2;     /* Greater than 1 is what matters */
          switch (-c)
            {
            case ESC_d:
            for (c = 0; c < 32; c++) classbits[c] |= cbits[c+cbit_digit];
            continue;

            case ESC_D:
            for (c = 0; c < 32; c++) classbits[c] |= ~cbits[c+cbit_digit];
            continue;

            case ESC_w:
            for (c = 0; c < 32; c++) classbits[c] |= cbits[c+cbit_word];
            continue;

            case ESC_W:
            for (c = 0; c < 32; c++) classbits[c] |= ~cbits[c+cbit_word];
            continue;

            case ESC_s:
            for (c = 0; c < 32; c++) classbits[c] |= cbits[c+cbit_space];
            classbits[1] &= ~0x08;   /* Perl 5.004 onwards omits VT from \s */
            continue;

            case ESC_S:
            for (c = 0; c < 32; c++) classbits[c] |= ~cbits[c+cbit_space];
            classbits[1] |= 0x08;    /* Perl 5.004 onwards omits VT from \s */
            continue;

#ifdef SUPPORT_UCP
            case ESC_p:
            case ESC_P:
              {
              BOOL negated;
              int property = get_ucp(&ptr, &negated, errorcodeptr);
              if (property < 0) goto FAILED;
              class_utf8 = TRUE;
              *class_utf8data++ = ((-c == ESC_p) != negated)?
                XCL_PROP : XCL_NOTPROP;
              *class_utf8data++ = property;
              class_charcount -= 2;   /* Not a < 256 character */
              }
            continue;
#endif

            /* Unrecognized escapes are faulted if PCRE is running in its
            strict mode. By default, for compatibility with Perl, they are
            treated as literals. */

            default:
            if ((options & PCRE_EXTRA) != 0)
              {
              *errorcodeptr = ERR7;
              goto FAILED;
              }
            c = *ptr;              /* The final character */
            class_charcount -= 2;  /* Undo the default count from above */
            }
          }

        /* Fall through if we have a single character (c >= 0). This may be
        > 256 in UTF-8 mode. */

        }   /* End of backslash handling */

      /* A single character may be followed by '-' to form a range. However,
      Perl does not permit ']' to be the end of the range. A '-' character
      here is treated as a literal. */

      if (ptr[1] == '-' && ptr[2] != ']')
        {
        int d;
        ptr += 2;

#ifdef SUPPORT_UTF8
        if (utf8)
          {                           /* Braces are required because the */
          GETCHARLEN(d, ptr, ptr);    /* macro generates multiple statements */
          }
        else
#endif
        d = *ptr;  /* Not UTF-8 mode */

        /* The second part of a range can be a single-character escape, but
        not any of the other escapes. Perl 5.6 treats a hyphen as a literal
        in such circumstances. */

        if (d == '\\')
          {
          const uschar *oldptr = ptr;
          d = check_escape(&ptr, errorcodeptr, *brackets, options, TRUE);

          /* \b is backslash; \X is literal X; any other special means the '-'
          was literal */

          if (d < 0)
            {
            if (d == -ESC_b) d = '\b';
            else if (d == -ESC_X) d = 'X'; else
              {
              ptr = oldptr - 2;
              goto LONE_SINGLE_CHARACTER;  /* A few lines below */
              }
            }
          }

        /* The check that the two values are in the correct order happens in
        the pre-pass. Optimize one-character ranges */

        if (d == c) goto LONE_SINGLE_CHARACTER;  /* A few lines below */

        /* In UTF-8 mode, if the upper limit is > 255, or > 127 for caseless
        matching, we have to use an XCLASS with extra data items. Caseless
        matching for characters > 127 is available only if UCP support is
        available. */

#ifdef SUPPORT_UTF8
        if (utf8 && (d > 255 || ((options & PCRE_CASELESS) != 0 && d > 127)))
          {
          class_utf8 = TRUE;

          /* With UCP support, we can find the other case equivalents of
          the relevant characters. There may be several ranges. Optimize how
          they fit with the basic range. */

#ifdef SUPPORT_UCP
          if ((options & PCRE_CASELESS) != 0)
            {
            int occ, ocd;
            int cc = c;
            int origd = d;
            while (get_othercase_range(&cc, origd, &occ, &ocd))
              {
              if (occ >= c && ocd <= d) continue;  /* Skip embedded ranges */

              if (occ < c  && ocd >= c - 1)        /* Extend the basic range */
                {                                  /* if there is overlap,   */
                c = occ;                           /* noting that if occ < c */
                continue;                          /* we can't have ocd > d  */
                }                                  /* because a subrange is  */
              if (ocd > d && occ <= d + 1)         /* always shorter than    */
                {                                  /* the basic range.       */
                d = ocd;
                continue;
                }

              if (occ == ocd)
                {
                *class_utf8data++ = XCL_SINGLE;
                }
              else
                {
                *class_utf8data++ = XCL_RANGE;
                class_utf8data += _pcre_ord2utf8(occ, class_utf8data);
                }
              class_utf8data += _pcre_ord2utf8(ocd, class_utf8data);
              }
            }
#endif  /* SUPPORT_UCP */

          /* Now record the original range, possibly modified for UCP caseless
          overlapping ranges. */

          *class_utf8data++ = XCL_RANGE;
          class_utf8data += _pcre_ord2utf8(c, class_utf8data);
          class_utf8data += _pcre_ord2utf8(d, class_utf8data);

          /* With UCP support, we are done. Without UCP support, there is no
          caseless matching for UTF-8 characters > 127; we can use the bit map
          for the smaller ones. */

#ifdef SUPPORT_UCP
          continue;    /* With next character in the class */
#else
          if ((options & PCRE_CASELESS) == 0 || c > 127) continue;

          /* Adjust upper limit and fall through to set up the map */

          d = 127;

#endif  /* SUPPORT_UCP */
          }
#endif  /* SUPPORT_UTF8 */

        /* We use the bit map for all cases when not in UTF-8 mode; else
        ranges that lie entirely within 0-127 when there is UCP support; else
        for partial ranges without UCP support. */

        for (; c <= d; c++)
          {
          classbits[c/8] |= (1 << (c&7));
          if ((options & PCRE_CASELESS) != 0)
            {
            int uc = cd->fcc[c];           /* flip case */
            classbits[uc/8] |= (1 << (uc&7));
            }
          class_charcount++;                /* in case a one-char range */
          class_lastchar = c;
          }

        continue;   /* Go get the next char in the class */
        }

      /* Handle a lone single character - we can get here for a normal
      non-escape char, or after \ that introduces a single character or for an
      apparent range that isn't. */

      LONE_SINGLE_CHARACTER:

      /* Handle a character that cannot go in the bit map */

#ifdef SUPPORT_UTF8
      if (utf8 && (c > 255 || ((options & PCRE_CASELESS) != 0 && c > 127)))
        {
        class_utf8 = TRUE;
        *class_utf8data++ = XCL_SINGLE;
        class_utf8data += _pcre_ord2utf8(c, class_utf8data);

#ifdef SUPPORT_UCP
        if ((options & PCRE_CASELESS) != 0)
          {
          int chartype;
          int othercase;
          if (_pcre_ucp_findchar(c, &chartype, &othercase) >= 0 &&
               othercase > 0)
            {
            *class_utf8data++ = XCL_SINGLE;
            class_utf8data += _pcre_ord2utf8(othercase, class_utf8data);
            }
          }
#endif  /* SUPPORT_UCP */

        }
      else
#endif  /* SUPPORT_UTF8 */

      /* Handle a single-byte character */
        {
        classbits[c/8] |= (1 << (c&7));
        if ((options & PCRE_CASELESS) != 0)
          {
          c = cd->fcc[c];   /* flip case */
          classbits[c/8] |= (1 << (c&7));
          }
        class_charcount++;
        class_lastchar = c;
        }
      }

    /* Loop until ']' reached; the check for end of string happens inside the
    loop. This "while" is the end of the "do" above. */

    while ((c = *(++ptr)) != ']' || inescq);

    /* If class_charcount is 1, we saw precisely one character whose value is
    less than 256. In non-UTF-8 mode we can always optimize. In UTF-8 mode, we
    can optimize the negative case only if there were no characters >= 128
    because OP_NOT and the related opcodes like OP_NOTSTAR operate on
    single-bytes only. This is an historical hangover. Maybe one day we can
    tidy these opcodes to handle multi-byte characters.

    The optimization throws away the bit map. We turn the item into a
    1-character OP_CHAR[NC] if it's positive, or OP_NOT if it's negative. Note
    that OP_NOT does not support multibyte characters. In the positive case, it
    can cause firstbyte to be set. Otherwise, there can be no first char if
    this item is first, whatever repeat count may follow. In the case of
    reqbyte, save the previous value for reinstating. */

#ifdef SUPPORT_UTF8
    if (class_charcount == 1 &&
          (!utf8 ||
          (!class_utf8 && (!negate_class || class_lastchar < 128))))

#else
    if (class_charcount == 1)
#endif
      {
      zeroreqbyte = reqbyte;

      /* The OP_NOT opcode works on one-byte characters only. */

      if (negate_class)
        {
        if (firstbyte == REQ_UNSET) firstbyte = REQ_NONE;
        zerofirstbyte = firstbyte;
        *code++ = OP_NOT;
        *code++ = class_lastchar;
        break;
        }

      /* For a single, positive character, get the value into mcbuffer, and
      then we can handle this with the normal one-character code. */

#ifdef SUPPORT_UTF8
      if (utf8 && class_lastchar > 127)
        mclength = _pcre_ord2utf8(class_lastchar, mcbuffer);
      else
#endif
        {
        mcbuffer[0] = class_lastchar;
        mclength = 1;
        }
      goto ONE_CHAR;
      }       /* End of 1-char optimization */

    /* The general case - not the one-char optimization. If this is the first
    thing in the branch, there can be no first char setting, whatever the
    repeat count. Any reqbyte setting must remain unchanged after any kind of
    repeat. */

    if (firstbyte == REQ_UNSET) firstbyte = REQ_NONE;
    zerofirstbyte = firstbyte;
    zeroreqbyte = reqbyte;

    /* If there are characters with values > 255, we have to compile an
    extended class, with its own opcode. If there are no characters < 256,
    we can omit the bitmap. */

#ifdef SUPPORT_UTF8
    if (class_utf8)
      {
      *class_utf8data++ = XCL_END;    /* Marks the end of extra data */
      *code++ = OP_XCLASS;
      code += LINK_SIZE;
      *code = negate_class? XCL_NOT : 0;

      /* If the map is required, install it, and move on to the end of
      the extra data */

      if (class_charcount > 0)
        {
        *code++ |= XCL_MAP;
        memcpy(code, classbits, 32);
        code = class_utf8data;
        }

      /* If the map is not required, slide down the extra data. */

      else
        {
        int len = class_utf8data - (code + 33);
        memmove(code + 1, code + 33, len);
        code += len + 1;
        }

      /* Now fill in the complete length of the item */

      PUT(previous, 1, code - previous);
      break;   /* End of class handling */
      }
#endif

    /* If there are no characters > 255, negate the 32-byte map if necessary,
    and copy it into the code vector. If this is the first thing in the branch,
    there can be no first char setting, whatever the repeat count. Any reqbyte
    setting must remain unchanged after any kind of repeat. */

    if (negate_class)
      {
      *code++ = OP_NCLASS;
      for (c = 0; c < 32; c++) code[c] = ~classbits[c];
      }
    else
      {
      *code++ = OP_CLASS;
      memcpy(code, classbits, 32);
      }
    code += 32;
    break;

    /* Various kinds of repeat; '{' is not necessarily a quantifier, but this
    has been tested above. */

    case '{':
    if (!is_quantifier) goto NORMAL_CHAR;
    ptr = read_repeat_counts(ptr+1, &repeat_min, &repeat_max, errorcodeptr);
    if (*errorcodeptr != 0) goto FAILED;
    goto REPEAT;

    case '*':
    repeat_min = 0;
    repeat_max = -1;
    goto REPEAT;

    case '+':
    repeat_min = 1;
    repeat_max = -1;
    goto REPEAT;

    case '?':
    repeat_min = 0;
    repeat_max = 1;

    REPEAT:
    if (previous == NULL)
      {
      *errorcodeptr = ERR9;
      goto FAILED;
      }

    if (repeat_min == 0)
      {
      firstbyte = zerofirstbyte;    /* Adjust for zero repeat */
      reqbyte = zeroreqbyte;        /* Ditto */
      }

    /* Remember whether this is a variable length repeat */

    reqvary = (repeat_min == repeat_max)? 0 : REQ_VARY;

    op_type = 0;                    /* Default single-char op codes */
    possessive_quantifier = FALSE;  /* Default not possessive quantifier */

    /* Save start of previous item, in case we have to move it up to make space
    for an inserted OP_ONCE for the additional '+' extension. */

    tempcode = previous;

    /* If the next character is '+', we have a possessive quantifier. This
    implies greediness, whatever the setting of the PCRE_UNGREEDY option.
    If the next character is '?' this is a minimizing repeat, by default,
    but if PCRE_UNGREEDY is set, it works the other way round. We change the
    repeat type to the non-default. */

    if (ptr[1] == '+')
      {
      repeat_type = 0;                  /* Force greedy */
      possessive_quantifier = TRUE;
      ptr++;
      }
    else if (ptr[1] == '?')
      {
      repeat_type = greedy_non_default;
      ptr++;
      }
    else repeat_type = greedy_default;

    /* If previous was a recursion, we need to wrap it inside brackets so that
    it can be replicated if necessary. */

    if (*previous == OP_RECURSE)
      {
      memmove(previous + 1 + LINK_SIZE, previous, 1 + LINK_SIZE);
      code += 1 + LINK_SIZE;
      *previous = OP_BRA;
      PUT(previous, 1, code - previous);
      *code = OP_KET;
      PUT(code, 1, code - previous);
      code += 1 + LINK_SIZE;
      }

    /* If previous was a character match, abolish the item and generate a
    repeat item instead. If a char item has a minumum of more than one, ensure
    that it is set in reqbyte - it might not be if a sequence such as x{3} is
    the first thing in a branch because the x will have gone into firstbyte
    instead.  */

    if (*previous == OP_CHAR || *previous == OP_CHARNC)
      {
      /* Deal with UTF-8 characters that take up more than one byte. It's
      easier to write this out separately than try to macrify it. Use c to
      hold the length of the character in bytes, plus 0x80 to flag that it's a
      length rather than a small character. */

#ifdef SUPPORT_UTF8
      if (utf8 && (code[-1] & 0x80) != 0)
        {
        uschar *lastchar = code - 1;
        while((*lastchar & 0xc0) == 0x80) lastchar--;
        c = code - lastchar;            /* Length of UTF-8 character */
        memcpy(utf8_char, lastchar, c); /* Save the char */
        c |= 0x80;                      /* Flag c as a length */
        }
      else
#endif

      /* Handle the case of a single byte - either with no UTF8 support, or
      with UTF-8 disabled, or for a UTF-8 character < 128. */

        {
        c = code[-1];
        if (repeat_min > 1) reqbyte = c | req_caseopt | cd->req_varyopt;
        }

      goto OUTPUT_SINGLE_REPEAT;   /* Code shared with single character types */
      }

    /* If previous was a single negated character ([^a] or similar), we use
    one of the special opcodes, replacing it. The code is shared with single-
    character repeats by setting opt_type to add a suitable offset into
    repeat_type. OP_NOT is currently used only for single-byte chars. */

    else if (*previous == OP_NOT)
      {
      op_type = OP_NOTSTAR - OP_STAR;  /* Use "not" opcodes */
      c = previous[1];
      goto OUTPUT_SINGLE_REPEAT;
      }

    /* If previous was a character type match (\d or similar), abolish it and
    create a suitable repeat item. The code is shared with single-character
    repeats by setting op_type to add a suitable offset into repeat_type. Note
    the the Unicode property types will be present only when SUPPORT_UCP is
    defined, but we don't wrap the little bits of code here because it just
    makes it horribly messy. */

    else if (*previous < OP_EODN)
      {
      uschar *oldcode;
      int prop_type;
      op_type = OP_TYPESTAR - OP_STAR;  /* Use type opcodes */
      c = *previous;

      OUTPUT_SINGLE_REPEAT:
      prop_type = (*previous == OP_PROP || *previous == OP_NOTPROP)?
        previous[1] : -1;

      oldcode = code;
      code = previous;                  /* Usually overwrite previous item */

      /* If the maximum is zero then the minimum must also be zero; Perl allows
      this case, so we do too - by simply omitting the item altogether. */

      if (repeat_max == 0) goto END_REPEAT;

      /* All real repeats make it impossible to handle partial matching (maybe
      one day we will be able to remove this restriction). */

      if (repeat_max != 1) cd->nopartial = TRUE;

      /* Combine the op_type with the repeat_type */

      repeat_type += op_type;

      /* A minimum of zero is handled either as the special case * or ?, or as
      an UPTO, with the maximum given. */

      if (repeat_min == 0)
        {
        if (repeat_max == -1) *code++ = OP_STAR + repeat_type;
          else if (repeat_max == 1) *code++ = OP_QUERY + repeat_type;
        else
          {
          *code++ = OP_UPTO + repeat_type;
          PUT2INC(code, 0, repeat_max);
          }
        }

      /* A repeat minimum of 1 is optimized into some special cases. If the
      maximum is unlimited, we use OP_PLUS. Otherwise, the original item it
      left in place and, if the maximum is greater than 1, we use OP_UPTO with
      one less than the maximum. */

      else if (repeat_min == 1)
        {
        if (repeat_max == -1)
          *code++ = OP_PLUS + repeat_type;
        else
          {
          code = oldcode;                 /* leave previous item in place */
          if (repeat_max == 1) goto END_REPEAT;
          *code++ = OP_UPTO + repeat_type;
          PUT2INC(code, 0, repeat_max - 1);
          }
        }

      /* The case {n,n} is just an EXACT, while the general case {n,m} is
      handled as an EXACT followed by an UPTO. */

      else
        {
        *code++ = OP_EXACT + op_type;  /* NB EXACT doesn't have repeat_type */
        PUT2INC(code, 0, repeat_min);

        /* If the maximum is unlimited, insert an OP_STAR. Before doing so,
        we have to insert the character for the previous code. For a repeated
        Unicode property match, there is an extra byte that defines the
        required property. In UTF-8 mode, long characters have their length in
        c, with the 0x80 bit as a flag. */

        if (repeat_max < 0)
          {
#ifdef SUPPORT_UTF8
          if (utf8 && c >= 128)
            {
            memcpy(code, utf8_char, c & 7);
            code += c & 7;
            }
          else
#endif
            {
            *code++ = c;
            if (prop_type >= 0) *code++ = prop_type;
            }
          *code++ = OP_STAR + repeat_type;
          }

        /* Else insert an UPTO if the max is greater than the min, again
        preceded by the character, for the previously inserted code. */

        else if (repeat_max != repeat_min)
          {
#ifdef SUPPORT_UTF8
          if (utf8 && c >= 128)
            {
            memcpy(code, utf8_char, c & 7);
            code += c & 7;
            }
          else
#endif
          *code++ = c;
          if (prop_type >= 0) *code++ = prop_type;
          repeat_max -= repeat_min;
          *code++ = OP_UPTO + repeat_type;
          PUT2INC(code, 0, repeat_max);
          }
        }

      /* The character or character type itself comes last in all cases. */

#ifdef SUPPORT_UTF8
      if (utf8 && c >= 128)
        {
        memcpy(code, utf8_char, c & 7);
        code += c & 7;
        }
      else
#endif
      *code++ = c;

      /* For a repeated Unicode property match, there is an extra byte that
      defines the required property. */

#ifdef SUPPORT_UCP
      if (prop_type >= 0) *code++ = prop_type;
#endif
      }

    /* If previous was a character class or a back reference, we put the repeat
    stuff after it, but just skip the item if the repeat was {0,0}. */

    else if (*previous == OP_CLASS ||
             *previous == OP_NCLASS ||
#ifdef SUPPORT_UTF8
             *previous == OP_XCLASS ||
#endif
             *previous == OP_REF)
      {
      if (repeat_max == 0)
        {
        code = previous;
        goto END_REPEAT;
        }

      /* All real repeats make it impossible to handle partial matching (maybe
      one day we will be able to remove this restriction). */

      if (repeat_max != 1) cd->nopartial = TRUE;

      if (repeat_min == 0 && repeat_max == -1)
        *code++ = OP_CRSTAR + repeat_type;
      else if (repeat_min == 1 && repeat_max == -1)
        *code++ = OP_CRPLUS + repeat_type;
      else if (repeat_min == 0 && repeat_max == 1)
        *code++ = OP_CRQUERY + repeat_type;
      else
        {
        *code++ = OP_CRRANGE + repeat_type;
        PUT2INC(code, 0, repeat_min);
        if (repeat_max == -1) repeat_max = 0;  /* 2-byte encoding for max */
        PUT2INC(code, 0, repeat_max);
        }
      }

    /* If previous was a bracket group, we may have to replicate it in certain
    cases. */

    else if (*previous >= OP_BRA || *previous == OP_ONCE ||
             *previous == OP_COND)
      {
      register int i;
      int ketoffset = 0;
      int len = code - previous;
      uschar *bralink = NULL;

      /* If the maximum repeat count is unlimited, find the end of the bracket
      by scanning through from the start, and compute the offset back to it
      from the current code pointer. There may be an OP_OPT setting following
      the final KET, so we can't find the end just by going back from the code
      pointer. */

      if (repeat_max == -1)
        {
        register uschar *ket = previous;
        do ket += GET(ket, 1); while (*ket != OP_KET);
        ketoffset = code - ket;
        }

      /* The case of a zero minimum is special because of the need to stick
      OP_BRAZERO in front of it, and because the group appears once in the
      data, whereas in other cases it appears the minimum number of times. For
      this reason, it is simplest to treat this case separately, as otherwise
      the code gets far too messy. There are several special subcases when the
      minimum is zero. */

      if (repeat_min == 0)
        {
        /* If the maximum is also zero, we just omit the group from the output
        altogether. */

        if (repeat_max == 0)
          {
          code = previous;
          goto END_REPEAT;
          }

        /* If the maximum is 1 or unlimited, we just have to stick in the
        BRAZERO and do no more at this point. However, we do need to adjust
        any OP_RECURSE calls inside the group that refer to the group itself or
        any internal group, because the offset is from the start of the whole
        regex. Temporarily terminate the pattern while doing this. */

        if (repeat_max <= 1)
          {
          *code = OP_END;
          adjust_recurse(previous, 1, utf8, cd);
          memmove(previous+1, previous, len);
          code++;
          *previous++ = OP_BRAZERO + repeat_type;
          }

        /* If the maximum is greater than 1 and limited, we have to replicate
        in a nested fashion, sticking OP_BRAZERO before each set of brackets.
        The first one has to be handled carefully because it's the original
        copy, which has to be moved up. The remainder can be handled by code
        that is common with the non-zero minimum case below. We have to
        adjust the value or repeat_max, since one less copy is required. Once
        again, we may have to adjust any OP_RECURSE calls inside the group. */

        else
          {
          int offset;
          *code = OP_END;
          adjust_recurse(previous, 2 + LINK_SIZE, utf8, cd);
          memmove(previous + 2 + LINK_SIZE, previous, len);
          code += 2 + LINK_SIZE;
          *previous++ = OP_BRAZERO + repeat_type;
          *previous++ = OP_BRA;

          /* We chain together the bracket offset fields that have to be
          filled in later when the ends of the brackets are reached. */

          offset = (bralink == NULL)? 0 : previous - bralink;
          bralink = previous;
          PUTINC(previous, 0, offset);
          }

        repeat_max--;
        }

      /* If the minimum is greater than zero, replicate the group as many
      times as necessary, and adjust the maximum to the number of subsequent
      copies that we need. If we set a first char from the group, and didn't
      set a required char, copy the latter from the former. */

      else
        {
        if (repeat_min > 1)
          {
          if (groupsetfirstbyte && reqbyte < 0) reqbyte = firstbyte;
          for (i = 1; i < repeat_min; i++)
            {
            memcpy(code, previous, len);
            code += len;
            }
          }
        if (repeat_max > 0) repeat_max -= repeat_min;
        }

      /* This code is common to both the zero and non-zero minimum cases. If
      the maximum is limited, it replicates the group in a nested fashion,
      remembering the bracket starts on a stack. In the case of a zero minimum,
      the first one was set up above. In all cases the repeat_max now specifies
      the number of additional copies needed. */

      if (repeat_max >= 0)
        {
        for (i = repeat_max - 1; i >= 0; i--)
          {
          *code++ = OP_BRAZERO + repeat_type;

          /* All but the final copy start a new nesting, maintaining the
          chain of brackets outstanding. */

          if (i != 0)
            {
            int offset;
            *code++ = OP_BRA;
            offset = (bralink == NULL)? 0 : code - bralink;
            bralink = code;
            PUTINC(code, 0, offset);
            }

          memcpy(code, previous, len);
          code += len;
          }

        /* Now chain through the pending brackets, and fill in their length
        fields (which are holding the chain links pro tem). */

        while (bralink != NULL)
          {
          int oldlinkoffset;
          int offset = code - bralink + 1;
          uschar *bra = code - offset;
          oldlinkoffset = GET(bra, 1);
          bralink = (oldlinkoffset == 0)? NULL : bralink - oldlinkoffset;
          *code++ = OP_KET;
          PUTINC(code, 0, offset);
          PUT(bra, 1, offset);
          }
        }

      /* If the maximum is unlimited, set a repeater in the final copy. We
      can't just offset backwards from the current code point, because we
      don't know if there's been an options resetting after the ket. The
      correct offset was computed above. */

      else code[-ketoffset] = OP_KETRMAX + repeat_type;
      }

    /* Else there's some kind of shambles */

    else
      {
      *errorcodeptr = ERR11;
      goto FAILED;
      }

    /* If the character following a repeat is '+', we wrap the entire repeated
    item inside OP_ONCE brackets. This is just syntactic sugar, taken from
    Sun's Java package. The repeated item starts at tempcode, not at previous,
    which might be the first part of a string whose (former) last char we
    repeated. However, we don't support '+' after a greediness '?'. */

    if (possessive_quantifier)
      {
      int len = code - tempcode;
      memmove(tempcode + 1+LINK_SIZE, tempcode, len);
      code += 1 + LINK_SIZE;
      len += 1 + LINK_SIZE;
      tempcode[0] = OP_ONCE;
      *code++ = OP_KET;
      PUTINC(code, 0, len);
      PUT(tempcode, 1, len);
      }

    /* In all case we no longer have a previous item. We also set the
    "follows varying string" flag for subsequently encountered reqbytes if
    it isn't already set and we have just passed a varying length item. */

    END_REPEAT:
    previous = NULL;
    cd->req_varyopt |= reqvary;
    break;


    /* Start of nested bracket sub-expression, or comment or lookahead or
    lookbehind or option setting or condition. First deal with special things
    that can come after a bracket; all are introduced by ?, and the appearance
    of any of them means that this is not a referencing group. They were
    checked for validity in the first pass over the string, so we don't have to
    check for syntax errors here.  */

    case '(':
    newoptions = options;
    skipbytes = 0;

    if (*(++ptr) == '?')
      {
      int set, unset;
      int *optset;

      switch (*(++ptr))
        {
        case '#':                 /* Comment; skip to ket */
        ptr++;
        while (*ptr != ')') ptr++;
        continue;

        case ':':                 /* Non-extracting bracket */
        bravalue = OP_BRA;
        ptr++;
        break;

        case '(':
        bravalue = OP_COND;       /* Conditional group */

        /* Condition to test for recursion */

        if (ptr[1] == 'R')
          {
          code[1+LINK_SIZE] = OP_CREF;
          PUT2(code, 2+LINK_SIZE, CREF_RECURSE);
          skipbytes = 3;
          ptr += 3;
          }

        /* Condition to test for a numbered subpattern match. We know that
        if a digit follows ( then there will just be digits until ) because
        the syntax was checked in the first pass. */

        else if ((digitab[ptr[1]] && ctype_digit) != 0)
          {
          int condref;                 /* Don't amalgamate; some compilers */
          condref = *(++ptr) - '0';    /* grumble at autoincrement in declaration */
          while (*(++ptr) != ')') condref = condref*10 + *ptr - '0';
          if (condref == 0)
            {
            *errorcodeptr = ERR35;
            goto FAILED;
            }
          ptr++;
          code[1+LINK_SIZE] = OP_CREF;
          PUT2(code, 2+LINK_SIZE, condref);
          skipbytes = 3;
          }
        /* For conditions that are assertions, we just fall through, having
        set bravalue above. */
        break;

        case '=':                 /* Positive lookahead */
        bravalue = OP_ASSERT;
        ptr++;
        break;

        case '!':                 /* Negative lookahead */
        bravalue = OP_ASSERT_NOT;
        ptr++;
        break;

        case '<':                 /* Lookbehinds */
        switch (*(++ptr))
          {
          case '=':               /* Positive lookbehind */
          bravalue = OP_ASSERTBACK;
          ptr++;
          break;

          case '!':               /* Negative lookbehind */
          bravalue = OP_ASSERTBACK_NOT;
          ptr++;
          break;
          }
        break;

        case '>':                 /* One-time brackets */
        bravalue = OP_ONCE;
        ptr++;
        break;

        case 'C':                 /* Callout - may be followed by digits; */
        previous_callout = code;  /* Save for later completion */
        after_manual_callout = 1; /* Skip one item before completing */
        *code++ = OP_CALLOUT;     /* Already checked that the terminating */
          {                       /* closing parenthesis is present. */
          int n = 0;
          while ((digitab[*(++ptr)] & ctype_digit) != 0)
            n = n * 10 + *ptr - '0';
          if (n > 255)
            {
            *errorcodeptr = ERR38;
            goto FAILED;
            }
          *code++ = n;
          PUT(code, 0, ptr - cd->start_pattern + 1);  /* Pattern offset */
          PUT(code, LINK_SIZE, 0);                    /* Default length */
          code += 2 * LINK_SIZE;
          }
        previous = NULL;
        continue;

        case 'P':                 /* Named subpattern handling */
        if (*(++ptr) == '<')      /* Definition */
          {
          int i, namelen;
          uschar *slot = cd->name_table;
          const uschar *name;     /* Don't amalgamate; some compilers */
          name = ++ptr;           /* grumble at autoincrement in declaration */

          while (*ptr++ != '>');
          namelen = ptr - name - 1;

          for (i = 0; i < cd->names_found; i++)
            {
            int crc = memcmp(name, slot+2, namelen);
            if (crc == 0)
              {
              if (slot[2+namelen] == 0)
                {
                *errorcodeptr = ERR43;
                goto FAILED;
                }
              crc = -1;             /* Current name is substring */
              }
            if (crc < 0)
              {
              memmove(slot + cd->name_entry_size, slot,
                (cd->names_found - i) * cd->name_entry_size);
              break;
              }
            slot += cd->name_entry_size;
            }

          PUT2(slot, 0, *brackets + 1);
          memcpy(slot + 2, name, namelen);
          slot[2+namelen] = 0;
          cd->names_found++;
          goto NUMBERED_GROUP;
          }

        if (*ptr == '=' || *ptr == '>')  /* Reference or recursion */
          {
          int i, namelen;
          int type = *ptr++;
          const uschar *name = ptr;
          uschar *slot = cd->name_table;

          while (*ptr != ')') ptr++;
          namelen = ptr - name;

          for (i = 0; i < cd->names_found; i++)
            {
            if (strncmp((char *)name, (char *)slot+2, namelen) == 0) break;
            slot += cd->name_entry_size;
            }
          if (i >= cd->names_found)
            {
            *errorcodeptr = ERR15;
            goto FAILED;
            }

          recno = GET2(slot, 0);

          if (type == '>') goto HANDLE_RECURSION;  /* A few lines below */

          /* Back reference */

          previous = code;
          *code++ = OP_REF;
          PUT2INC(code, 0, recno);
          cd->backref_map |= (recno < 32)? (1 << recno) : 1;
          if (recno > cd->top_backref) cd->top_backref = recno;
          continue;
          }

        /* Should never happen */
        break;

        case 'R':                 /* Pattern recursion */
        ptr++;                    /* Same as (?0)      */
        /* Fall through */

        /* Recursion or "subroutine" call */

        case '0': case '1': case '2': case '3': case '4':
        case '5': case '6': case '7': case '8': case '9':
          {
          const uschar *called;
          recno = 0;
          while((digitab[*ptr] & ctype_digit) != 0)
            recno = recno * 10 + *ptr++ - '0';

          /* Come here from code above that handles a named recursion */

          HANDLE_RECURSION:

          previous = code;

          /* Find the bracket that is being referenced. Temporarily end the
          regex in case it doesn't exist. */

          *code = OP_END;
          called = (recno == 0)?
            cd->start_code : find_bracket(cd->start_code, utf8, recno);

          if (called == NULL)
            {
            *errorcodeptr = ERR15;
            goto FAILED;
            }

          /* If the subpattern is still open, this is a recursive call. We
          check to see if this is a left recursion that could loop for ever,
          and diagnose that case. */

          if (GET(called, 1) == 0 && could_be_empty(called, code, bcptr, utf8))
            {
            *errorcodeptr = ERR40;
            goto FAILED;
            }

          /* Insert the recursion/subroutine item */

          *code = OP_RECURSE;
          PUT(code, 1, called - cd->start_code);
          code += 1 + LINK_SIZE;
          }
        continue;

        /* Character after (? not specially recognized */

        default:                  /* Option setting */
        set = unset = 0;
        optset = &set;

        while (*ptr != ')' && *ptr != ':')
          {
          switch (*ptr++)
            {
            case '-': optset = &unset; break;

            case 'i': *optset |= PCRE_CASELESS; break;
            case 'm': *optset |= PCRE_MULTILINE; break;
            case 's': *optset |= PCRE_DOTALL; break;
            case 'x': *optset |= PCRE_EXTENDED; break;
            case 'U': *optset |= PCRE_UNGREEDY; break;
            case 'X': *optset |= PCRE_EXTRA; break;
            }
          }

        /* Set up the changed option bits, but don't change anything yet. */

        newoptions = (options | set) & (~unset);

        /* If the options ended with ')' this is not the start of a nested
        group with option changes, so the options change at this level. Compile
        code to change the ims options if this setting actually changes any of
        them. We also pass the new setting back so that it can be put at the
        start of any following branches, and when this group ends (if we are in
        a group), a resetting item can be compiled.

        Note that if this item is right at the start of the pattern, the
        options will have been abstracted and made global, so there will be no
        change to compile. */

        if (*ptr == ')')
          {
          if ((options & PCRE_IMS) != (newoptions & PCRE_IMS))
            {
            *code++ = OP_OPT;
            *code++ = newoptions & PCRE_IMS;
            }

          /* Change options at this level, and pass them back for use
          in subsequent branches. Reset the greedy defaults and the case
          value for firstbyte and reqbyte. */

          *optionsptr = options = newoptions;
          greedy_default = ((newoptions & PCRE_UNGREEDY) != 0);
          greedy_non_default = greedy_default ^ 1;
          req_caseopt = ((options & PCRE_CASELESS) != 0)? REQ_CASELESS : 0;

          previous = NULL;       /* This item can't be repeated */
          continue;              /* It is complete */
          }

        /* If the options ended with ':' we are heading into a nested group
        with possible change of options. Such groups are non-capturing and are
        not assertions of any kind. All we need to do is skip over the ':';
        the newoptions value is handled below. */

        bravalue = OP_BRA;
        ptr++;
        }
      }

    /* If PCRE_NO_AUTO_CAPTURE is set, all unadorned brackets become
    non-capturing and behave like (?:...) brackets */

    else if ((options & PCRE_NO_AUTO_CAPTURE) != 0)
      {
      bravalue = OP_BRA;
      }

    /* Else we have a referencing group; adjust the opcode. If the bracket
    number is greater than EXTRACT_BASIC_MAX, we set the opcode one higher, and
    arrange for the true number to follow later, in an OP_BRANUMBER item. */

    else
      {
      NUMBERED_GROUP:
      if (++(*brackets) > EXTRACT_BASIC_MAX)
        {
        bravalue = OP_BRA + EXTRACT_BASIC_MAX + 1;
        code[1+LINK_SIZE] = OP_BRANUMBER;
        PUT2(code, 2+LINK_SIZE, *brackets);
        skipbytes = 3;
        }
      else bravalue = OP_BRA + *brackets;
      }

    /* Process nested bracketed re. Assertions may not be repeated, but other
    kinds can be. We copy code into a non-register variable in order to be able
    to pass its address because some compilers complain otherwise. Pass in a
    new setting for the ims options if they have changed. */

    previous = (bravalue >= OP_ONCE)? code : NULL;
    *code = bravalue;
    tempcode = code;
    tempreqvary = cd->req_varyopt;     /* Save value before bracket */

    if (!compile_regex(
         newoptions,                   /* The complete new option state */
         options & PCRE_IMS,           /* The previous ims option state */
         brackets,                     /* Extracting bracket count */
         &tempcode,                    /* Where to put code (updated) */
         &ptr,                         /* Input pointer (updated) */
         errorcodeptr,                 /* Where to put an error message */
         (bravalue == OP_ASSERTBACK ||
          bravalue == OP_ASSERTBACK_NOT), /* TRUE if back assert */
         skipbytes,                    /* Skip over OP_COND/OP_BRANUMBER */
         &subfirstbyte,                /* For possible first char */
         &subreqbyte,                  /* For possible last char */
         bcptr,                        /* Current branch chain */
         cd))                          /* Tables block */
      goto FAILED;

    /* At the end of compiling, code is still pointing to the start of the
    group, while tempcode has been updated to point past the end of the group
    and any option resetting that may follow it. The pattern pointer (ptr)
    is on the bracket. */

    /* If this is a conditional bracket, check that there are no more than
    two branches in the group. */

    else if (bravalue == OP_COND)
      {
      uschar *tc = code;
      condcount = 0;

      do {
         condcount++;
         tc += GET(tc,1);
         }
      while (*tc != OP_KET);

      if (condcount > 2)
        {
        *errorcodeptr = ERR27;
        goto FAILED;
        }

      /* If there is just one branch, we must not make use of its firstbyte or
      reqbyte, because this is equivalent to an empty second branch. */

      if (condcount == 1) subfirstbyte = subreqbyte = REQ_NONE;
      }

    /* Handle updating of the required and first characters. Update for normal
    brackets of all kinds, and conditions with two branches (see code above).
    If the bracket is followed by a quantifier with zero repeat, we have to
    back off. Hence the definition of zeroreqbyte and zerofirstbyte outside the
    main loop so that they can be accessed for the back off. */

    zeroreqbyte = reqbyte;
    zerofirstbyte = firstbyte;
    groupsetfirstbyte = FALSE;

    if (bravalue >= OP_BRA || bravalue == OP_ONCE || bravalue == OP_COND)
      {
      /* If we have not yet set a firstbyte in this branch, take it from the
      subpattern, remembering that it was set here so that a repeat of more
      than one can replicate it as reqbyte if necessary. If the subpattern has
      no firstbyte, set "none" for the whole branch. In both cases, a zero
      repeat forces firstbyte to "none". */

      if (firstbyte == REQ_UNSET)
        {
        if (subfirstbyte >= 0)
          {
          firstbyte = subfirstbyte;
          groupsetfirstbyte = TRUE;
          }
        else firstbyte = REQ_NONE;
        zerofirstbyte = REQ_NONE;
        }

      /* If firstbyte was previously set, convert the subpattern's firstbyte
      into reqbyte if there wasn't one, using the vary flag that was in
      existence beforehand. */

      else if (subfirstbyte >= 0 && subreqbyte < 0)
        subreqbyte = subfirstbyte | tempreqvary;

      /* If the subpattern set a required byte (or set a first byte that isn't
      really the first byte - see above), set it. */

      if (subreqbyte >= 0) reqbyte = subreqbyte;
      }

    /* For a forward assertion, we take the reqbyte, if set. This can be
    helpful if the pattern that follows the assertion doesn't set a different
    char. For example, it's useful for /(?=abcde).+/. We can't set firstbyte
    for an assertion, however because it leads to incorrect effect for patterns
    such as /(?=a)a.+/ when the "real" "a" would then become a reqbyte instead
    of a firstbyte. This is overcome by a scan at the end if there's no
    firstbyte, looking for an asserted first char. */

    else if (bravalue == OP_ASSERT && subreqbyte >= 0) reqbyte = subreqbyte;

    /* Now update the main code pointer to the end of the group. */

    code = tempcode;

    /* Error if hit end of pattern */

    if (*ptr != ')')
      {
      *errorcodeptr = ERR14;
      goto FAILED;
      }
    break;

    /* Check \ for being a real metacharacter; if not, fall through and handle
    it as a data character at the start of a string. Escape items are checked
    for validity in the pre-compiling pass. */

    case '\\':
    tempptr = ptr;
    c = check_escape(&ptr, errorcodeptr, *brackets, options, FALSE);

    /* Handle metacharacters introduced by \. For ones like \d, the ESC_ values
    are arranged to be the negation of the corresponding OP_values. For the
    back references, the values are ESC_REF plus the reference number. Only
    back references and those types that consume a character may be repeated.
    We can test for values between ESC_b and ESC_Z for the latter; this may
    have to change if any new ones are ever created. */

    if (c < 0)
      {
      if (-c == ESC_Q)            /* Handle start of quoted string */
        {
        if (ptr[1] == '\\' && ptr[2] == 'E') ptr += 2; /* avoid empty string */
          else inescq = TRUE;
        continue;
        }

      /* For metasequences that actually match a character, we disable the
      setting of a first character if it hasn't already been set. */

      if (firstbyte == REQ_UNSET && -c > ESC_b && -c < ESC_Z)
        firstbyte = REQ_NONE;

      /* Set values to reset to if this is followed by a zero repeat. */

      zerofirstbyte = firstbyte;
      zeroreqbyte = reqbyte;

      /* Back references are handled specially */

      if (-c >= ESC_REF)
        {
        int number = -c - ESC_REF;
        previous = code;
        *code++ = OP_REF;
        PUT2INC(code, 0, number);
        }

      /* So are Unicode property matches, if supported. We know that get_ucp
      won't fail because it was tested in the pre-pass. */

#ifdef SUPPORT_UCP
      else if (-c == ESC_P || -c == ESC_p)
        {
        BOOL negated;
        int value = get_ucp(&ptr, &negated, errorcodeptr);
        previous = code;
        *code++ = ((-c == ESC_p) != negated)? OP_PROP : OP_NOTPROP;
        *code++ = value;
        }
#endif

      /* For the rest, we can obtain the OP value by negating the escape
      value */

      else
        {
        previous = (-c > ESC_b && -c < ESC_Z)? code : NULL;
        *code++ = -c;
        }
      continue;
      }

    /* We have a data character whose value is in c. In UTF-8 mode it may have
    a value > 127. We set its representation in the length/buffer, and then
    handle it as a data character. */

#ifdef SUPPORT_UTF8
    if (utf8 && c > 127)
      mclength = _pcre_ord2utf8(c, mcbuffer);
    else
#endif

     {
     mcbuffer[0] = c;
     mclength = 1;
     }

    goto ONE_CHAR;

    /* Handle a literal character. It is guaranteed not to be whitespace or #
    when the extended flag is set. If we are in UTF-8 mode, it may be a
    multi-byte literal character. */

    default:
    NORMAL_CHAR:
    mclength = 1;
    mcbuffer[0] = c;

#ifdef SUPPORT_UTF8
    if (utf8 && (c & 0xc0) == 0xc0)
      {
      while ((ptr[1] & 0xc0) == 0x80)
        mcbuffer[mclength++] = *(++ptr);
      }
#endif

    /* At this point we have the character's bytes in mcbuffer, and the length
    in mclength. When not in UTF-8 mode, the length is always 1. */

    ONE_CHAR:
    previous = code;
    *code++ = ((options & PCRE_CASELESS) != 0)? OP_CHARNC : OP_CHAR;
    for (c = 0; c < mclength; c++) *code++ = mcbuffer[c];

    /* Set the first and required bytes appropriately. If no previous first
    byte, set it from this character, but revert to none on a zero repeat.
    Otherwise, leave the firstbyte value alone, and don't change it on a zero
    repeat. */

    if (firstbyte == REQ_UNSET)
      {
      zerofirstbyte = REQ_NONE;
      zeroreqbyte = reqbyte;

      /* If the character is more than one byte long, we can set firstbyte
      only if it is not to be matched caselessly. */

      if (mclength == 1 || req_caseopt == 0)
        {
        firstbyte = mcbuffer[0] | req_caseopt;
        if (mclength != 1) reqbyte = code[-1] | cd->req_varyopt;
        }
      else firstbyte = reqbyte = REQ_NONE;
      }

    /* firstbyte was previously set; we can set reqbyte only the length is
    1 or the matching is caseful. */

    else
      {
      zerofirstbyte = firstbyte;
      zeroreqbyte = reqbyte;
      if (mclength == 1 || req_caseopt == 0)
        reqbyte = code[-1] | req_caseopt | cd->req_varyopt;
      }

    break;            /* End of literal character handling */
    }
  }                   /* end of big loop */

/* Control never reaches here by falling through, only by a goto for all the
error states. Pass back the position in the pattern so that it can be displayed
to the user for diagnosing the error. */

FAILED:
*ptrptr = ptr;
return FALSE;
}




/*************************************************
*     Compile sequence of alternatives           *
*************************************************/

/* On entry, ptr is pointing past the bracket character, but on return
it points to the closing bracket, or vertical bar, or end of string.
The code variable is pointing at the byte into which the BRA operator has been
stored. If the ims options are changed at the start (for a (?ims: group) or
during any branch, we need to insert an OP_OPT item at the start of every
following branch to ensure they get set correctly at run time, and also pass
the new options into every subsequent branch compile.

Argument:
  options        option bits, including any changes for this subpattern
  oldims         previous settings of ims option bits
  brackets       -> int containing the number of extracting brackets used
  codeptr        -> the address of the current code pointer
  ptrptr         -> the address of the current pattern pointer
  errorcodeptr   -> pointer to error code variable
  lookbehind     TRUE if this is a lookbehind assertion
  skipbytes      skip this many bytes at start (for OP_COND, OP_BRANUMBER)
  firstbyteptr   place to put the first required character, or a negative number
  reqbyteptr     place to put the last required character, or a negative number
  bcptr          pointer to the chain of currently open branches
  cd             points to the data block with tables pointers etc.

Returns:      TRUE on success
*/

static BOOL
compile_regex(int options, int oldims, int *brackets, uschar **codeptr,
  const uschar **ptrptr, int *errorcodeptr, BOOL lookbehind, int skipbytes,
  int *firstbyteptr, int *reqbyteptr, branch_chain *bcptr, compile_data *cd)
{
const uschar *ptr = *ptrptr;
uschar *code = *codeptr;
uschar *last_branch = code;
uschar *start_bracket = code;
uschar *reverse_count = NULL;
int firstbyte, reqbyte;
int branchfirstbyte, branchreqbyte;
branch_chain bc;

bc.outer = bcptr;
bc.current = code;

firstbyte = reqbyte = REQ_UNSET;

/* Offset is set zero to mark that this bracket is still open */

PUT(code, 1, 0);
code += 1 + LINK_SIZE + skipbytes;

/* Loop for each alternative branch */

for (;;)
  {
  /* Handle a change of ims options at the start of the branch */

  if ((options & PCRE_IMS) != oldims)
    {
    *code++ = OP_OPT;
    *code++ = options & PCRE_IMS;
    }

  /* Set up dummy OP_REVERSE if lookbehind assertion */

  if (lookbehind)
    {
    *code++ = OP_REVERSE;
    reverse_count = code;
    PUTINC(code, 0, 0);
    }

  /* Now compile the branch */

  if (!compile_branch(&options, brackets, &code, &ptr, errorcodeptr,
        &branchfirstbyte, &branchreqbyte, &bc, cd))
    {
    *ptrptr = ptr;
    return FALSE;
    }

  /* If this is the first branch, the firstbyte and reqbyte values for the
  branch become the values for the regex. */

  if (*last_branch != OP_ALT)
    {
    firstbyte = branchfirstbyte;
    reqbyte = branchreqbyte;
    }

  /* If this is not the first branch, the first char and reqbyte have to
  match the values from all the previous branches, except that if the previous
  value for reqbyte didn't have REQ_VARY set, it can still match, and we set
  REQ_VARY for the regex. */

  else
    {
    /* If we previously had a firstbyte, but it doesn't match the new branch,
    we have to abandon the firstbyte for the regex, but if there was previously
    no reqbyte, it takes on the value of the old firstbyte. */

    if (firstbyte >= 0 && firstbyte != branchfirstbyte)
      {
      if (reqbyte < 0) reqbyte = firstbyte;
      firstbyte = REQ_NONE;
      }

    /* If we (now or from before) have no firstbyte, a firstbyte from the
    branch becomes a reqbyte if there isn't a branch reqbyte. */

    if (firstbyte < 0 && branchfirstbyte >= 0 && branchreqbyte < 0)
        branchreqbyte = branchfirstbyte;

    /* Now ensure that the reqbytes match */

    if ((reqbyte & ~REQ_VARY) != (branchreqbyte & ~REQ_VARY))
      reqbyte = REQ_NONE;
    else reqbyte |= branchreqbyte;   /* To "or" REQ_VARY */
    }

  /* If lookbehind, check that this branch matches a fixed-length string,
  and put the length into the OP_REVERSE item. Temporarily mark the end of
  the branch with OP_END. */

  if (lookbehind)
    {
    int length;
    *code = OP_END;
    length = find_fixedlength(last_branch, options);
    DPRINTF(("fixed length = %d\n", length));
    if (length < 0)
      {
      *errorcodeptr = (length == -2)? ERR36 : ERR25;
      *ptrptr = ptr;
      return FALSE;
      }
    PUT(reverse_count, 0, length);
    }

  /* Reached end of expression, either ')' or end of pattern. Go back through
  the alternative branches and reverse the chain of offsets, with the field in
  the BRA item now becoming an offset to the first alternative. If there are
  no alternatives, it points to the end of the group. The length in the
  terminating ket is always the length of the whole bracketed item. If any of
  the ims options were changed inside the group, compile a resetting op-code
  following, except at the very end of the pattern. Return leaving the pointer
  at the terminating char. */

  if (*ptr != '|')
    {
    int length = code - last_branch;
    do
      {
      int prev_length = GET(last_branch, 1);
      PUT(last_branch, 1, length);
      length = prev_length;
      last_branch -= length;
      }
    while (length > 0);

    /* Fill in the ket */

    *code = OP_KET;
    PUT(code, 1, code - start_bracket);
    code += 1 + LINK_SIZE;

    /* Resetting option if needed */

    if ((options & PCRE_IMS) != oldims && *ptr == ')')
      {
      *code++ = OP_OPT;
      *code++ = oldims;
      }

    /* Set values to pass back */

    *codeptr = code;
    *ptrptr = ptr;
    *firstbyteptr = firstbyte;
    *reqbyteptr = reqbyte;
    return TRUE;
    }

  /* Another branch follows; insert an "or" node. Its length field points back
  to the previous branch while the bracket remains open. At the end the chain
  is reversed. It's done like this so that the start of the bracket has a
  zero offset until it is closed, making it possible to detect recursion. */

  *code = OP_ALT;
  PUT(code, 1, code - last_branch);
  bc.current = last_branch = code;
  code += 1 + LINK_SIZE;
  ptr++;
  }
/* Control never reaches here */
}




/*************************************************
*          Check for anchored expression         *
*************************************************/

/* Try to find out if this is an anchored regular expression. Consider each
alternative branch. If they all start with OP_SOD or OP_CIRC, or with a bracket
all of whose alternatives start with OP_SOD or OP_CIRC (recurse ad lib), then
it's anchored. However, if this is a multiline pattern, then only OP_SOD
counts, since OP_CIRC can match in the middle.

We can also consider a regex to be anchored if OP_SOM starts all its branches.
This is the code for \G, which means "match at start of match position, taking
into account the match offset".

A branch is also implicitly anchored if it starts with .* and DOTALL is set,
because that will try the rest of the pattern at all possible matching points,
so there is no point trying again.... er ....

.... except when the .* appears inside capturing parentheses, and there is a
subsequent back reference to those parentheses. We haven't enough information
to catch that case precisely.

At first, the best we could do was to detect when .* was in capturing brackets
and the highest back reference was greater than or equal to that level.
However, by keeping a bitmap of the first 31 back references, we can catch some
of the more common cases more precisely.

Arguments:
  code           points to start of expression (the bracket)
  options        points to the options setting
  bracket_map    a bitmap of which brackets we are inside while testing; this
                  handles up to substring 31; after that we just have to take
                  the less precise approach
  backref_map    the back reference bitmap

Returns:     TRUE or FALSE
*/

static BOOL
is_anchored(register const uschar *code, int *options, unsigned int bracket_map,
  unsigned int backref_map)
{
do {
   const uschar *scode =
     first_significant_code(code + 1+LINK_SIZE, options, PCRE_MULTILINE, FALSE);
   register int op = *scode;

   /* Capturing brackets */

   if (op > OP_BRA)
     {
     int new_map;
     op -= OP_BRA;
     if (op > EXTRACT_BASIC_MAX) op = GET2(scode, 2+LINK_SIZE);
     new_map = bracket_map | ((op < 32)? (1 << op) : 1);
     if (!is_anchored(scode, options, new_map, backref_map)) return FALSE;
     }

   /* Other brackets */

   else if (op == OP_BRA || op == OP_ASSERT || op == OP_ONCE || op == OP_COND)
     {
     if (!is_anchored(scode, options, bracket_map, backref_map)) return FALSE;
     }

   /* .* is not anchored unless DOTALL is set and it isn't in brackets that
   are or may be referenced. */

   else if ((op == OP_TYPESTAR || op == OP_TYPEMINSTAR) &&
            (*options & PCRE_DOTALL) != 0)
     {
     if (scode[1] != OP_ANY || (bracket_map & backref_map) != 0) return FALSE;
     }

   /* Check for explicit anchoring */

   else if (op != OP_SOD && op != OP_SOM &&
           ((*options & PCRE_MULTILINE) != 0 || op != OP_CIRC))
     return FALSE;
   code += GET(code, 1);
   }
while (*code == OP_ALT);   /* Loop for each alternative */
return TRUE;
}



/*************************************************
*         Check for starting with ^ or .*        *
*************************************************/

/* This is called to find out if every branch starts with ^ or .* so that
"first char" processing can be done to speed things up in multiline
matching and for non-DOTALL patterns that start with .* (which must start at
the beginning or after \n). As in the case of is_anchored() (see above), we
have to take account of back references to capturing brackets that contain .*
because in that case we can't make the assumption.

Arguments:
  code           points to start of expression (the bracket)
  bracket_map    a bitmap of which brackets we are inside while testing; this
                  handles up to substring 31; after that we just have to take
                  the less precise approach
  backref_map    the back reference bitmap

Returns:         TRUE or FALSE
*/

static BOOL
is_startline(const uschar *code, unsigned int bracket_map,
  unsigned int backref_map)
{
do {
   const uschar *scode = first_significant_code(code + 1+LINK_SIZE, NULL, 0,
     FALSE);
   register int op = *scode;

   /* Capturing brackets */

   if (op > OP_BRA)
     {
     int new_map;
     op -= OP_BRA;
     if (op > EXTRACT_BASIC_MAX) op = GET2(scode, 2+LINK_SIZE);
     new_map = bracket_map | ((op < 32)? (1 << op) : 1);
     if (!is_startline(scode, new_map, backref_map)) return FALSE;
     }

   /* Other brackets */

   else if (op == OP_BRA || op == OP_ASSERT || op == OP_ONCE || op == OP_COND)
     { if (!is_startline(scode, bracket_map, backref_map)) return FALSE; }

   /* .* means "start at start or after \n" if it isn't in brackets that
   may be referenced. */

   else if (op == OP_TYPESTAR || op == OP_TYPEMINSTAR)
     {
     if (scode[1] != OP_ANY || (bracket_map & backref_map) != 0) return FALSE;
     }

   /* Check for explicit circumflex */

   else if (op != OP_CIRC) return FALSE;

   /* Move on to the next alternative */

   code += GET(code, 1);
   }
while (*code == OP_ALT);  /* Loop for each alternative */
return TRUE;
}



/*************************************************
*       Check for asserted fixed first char      *
*************************************************/

/* During compilation, the "first char" settings from forward assertions are
discarded, because they can cause conflicts with actual literals that follow.
However, if we end up without a first char setting for an unanchored pattern,
it is worth scanning the regex to see if there is an initial asserted first
char. If all branches start with the same asserted char, or with a bracket all
of whose alternatives start with the same asserted char (recurse ad lib), then
we return that char, otherwise -1.

Arguments:
  code       points to start of expression (the bracket)
  options    pointer to the options (used to check casing changes)
  inassert   TRUE if in an assertion

Returns:     -1 or the fixed first char
*/

static int
find_firstassertedchar(const uschar *code, int *options, BOOL inassert)
{
register int c = -1;
do {
   int d;
   const uschar *scode =
     first_significant_code(code + 1+LINK_SIZE, options, PCRE_CASELESS, TRUE);
   register int op = *scode;

   if (op >= OP_BRA) op = OP_BRA;

   switch(op)
     {
     default:
     return -1;

     case OP_BRA:
     case OP_ASSERT:
     case OP_ONCE:
     case OP_COND:
     if ((d = find_firstassertedchar(scode, options, op == OP_ASSERT)) < 0)
       return -1;
     if (c < 0) c = d; else if (c != d) return -1;
     break;

     case OP_EXACT:       /* Fall through */
     scode += 2;

     case OP_CHAR:
     case OP_CHARNC:
     case OP_PLUS:
     case OP_MINPLUS:
     if (!inassert) return -1;
     if (c < 0)
       {
       c = scode[1];
       if ((*options & PCRE_CASELESS) != 0) c |= REQ_CASELESS;
       }
     else if (c != scode[1]) return -1;
     break;
     }

   code += GET(code, 1);
   }
while (*code == OP_ALT);
return c;
}



/*************************************************
*        Compile a Regular Expression            *
*************************************************/

/* This function takes a string and returns a pointer to a block of store
holding a compiled version of the expression. The original API for this
function had no error code return variable; it is retained for backwards
compatibility. The new function is given a new name.

Arguments:
  pattern       the regular expression
  options       various option bits
  errorcodeptr  pointer to error code variable (pcre_compile2() only)
                  can be NULL if you don't want a code value
  errorptr      pointer to pointer to error text
  erroroffset   ptr offset in pattern where error was detected
  tables        pointer to character tables or NULL

Returns:        pointer to compiled data block, or NULL on error,
                with errorptr and erroroffset set
*/

EXPORT pcre *
pcre_compile(const char *pattern, int options, const char **errorptr,
  int *erroroffset, const unsigned char *tables)
{
return pcre_compile2(pattern, options, NULL, errorptr, erroroffset, tables);
}


EXPORT pcre *
pcre_compile2(const char *pattern, int options, int *errorcodeptr,
  const char **errorptr, int *erroroffset, const unsigned char *tables)
{
real_pcre *re;
int length = 1 + LINK_SIZE;      /* For initial BRA plus length */
int c, firstbyte, reqbyte;
int bracount = 0;
int branch_extra = 0;
int branch_newextra;
int item_count = -1;
int name_count = 0;
int max_name_size = 0;
int lastitemlength = 0;
int errorcode = 0;
#ifdef SUPPORT_UTF8
BOOL utf8;
BOOL class_utf8;
#endif
BOOL inescq = FALSE;
BOOL capturing;
unsigned int brastackptr = 0;
size_t size;
uschar *code;
const uschar *codestart;
const uschar *ptr;
compile_data compile_block;
int brastack[BRASTACK_SIZE];
uschar bralenstack[BRASTACK_SIZE];

/* We can't pass back an error message if errorptr is NULL; I guess the best we
can do is just return NULL, but we can set a code value if there is a code
pointer. */

if (errorptr == NULL)
  {
  if (errorcodeptr != NULL) *errorcodeptr = 99;
  return NULL;
  }

*errorptr = NULL;
if (errorcodeptr != NULL) *errorcodeptr = ERR0;

/* However, we can give a message for this error */

if (erroroffset == NULL)
  {
  errorcode = ERR16;
  goto PCRE_EARLY_ERROR_RETURN;
  }

*erroroffset = 0;

/* Can't support UTF8 unless PCRE has been compiled to include the code. */

#ifdef SUPPORT_UTF8
utf8 = (options & PCRE_UTF8) != 0;
if (utf8 && (options & PCRE_NO_UTF8_CHECK) == 0 &&
     (*erroroffset = _pcre_valid_utf8((uschar *)pattern, -1)) >= 0)
  {
  errorcode = ERR44;
  goto PCRE_EARLY_ERROR_RETURN;
  }
#else
if ((options & PCRE_UTF8) != 0)
  {
  errorcode = ERR32;
  goto PCRE_EARLY_ERROR_RETURN;
  }
#endif

if ((options & ~PUBLIC_OPTIONS) != 0)
  {
  errorcode = ERR17;
  goto PCRE_EARLY_ERROR_RETURN;
  }

/* Set up pointers to the individual character tables */

if (tables == NULL) tables = _pcre_default_tables;
compile_block.lcc = tables + lcc_offset;
compile_block.fcc = tables + fcc_offset;
compile_block.cbits = tables + cbits_offset;
compile_block.ctypes = tables + ctypes_offset;

/* Maximum back reference and backref bitmap. This is updated for numeric
references during the first pass, but for named references during the actual
compile pass. The bitmap records up to 31 back references to help in deciding
whether (.*) can be treated as anchored or not. */

compile_block.top_backref = 0;
compile_block.backref_map = 0;

/* Reflect pattern for debugging output */

DPRINTF(("------------------------------------------------------------------\n"));
DPRINTF(("%s\n", pattern));

/* The first thing to do is to make a pass over the pattern to compute the
amount of store required to hold the compiled code. This does not have to be
perfect as long as errors are overestimates. At the same time we can detect any
flag settings right at the start, and extract them. Make an attempt to correct
for any counted white space if an "extended" flag setting appears late in the
pattern. We can't be so clever for #-comments. */

ptr = (const uschar *)(pattern - 1);
while ((c = *(++ptr)) != 0)
  {
  int min, max;
  int class_optcount;
  int bracket_length;
  int duplength;

  /* If we are inside a \Q...\E sequence, all chars are literal */

  if (inescq)
    {
    if ((options & PCRE_AUTO_CALLOUT) != 0) length += 2 + 2*LINK_SIZE;
    goto NORMAL_CHAR;
    }

  /* Otherwise, first check for ignored whitespace and comments */

  if ((options & PCRE_EXTENDED) != 0)
    {
    if ((compile_block.ctypes[c] & ctype_space) != 0) continue;
    if (c == '#')
      {
      /* The space before the ; is to avoid a warning on a silly compiler
      on the Macintosh. */
      while ((c = *(++ptr)) != 0 && c != NEWLINE) ;
      if (c == 0) break;
      continue;
      }
    }

  item_count++;    /* Is zero for the first non-comment item */

  /* Allow space for auto callout before every item except quantifiers. */

  if ((options & PCRE_AUTO_CALLOUT) != 0 &&
       c != '*' && c != '+' && c != '?' &&
       (c != '{' || !is_counted_repeat(ptr + 1)))
    length += 2 + 2*LINK_SIZE;

  switch(c)
    {
    /* A backslashed item may be an escaped data character or it may be a
    character type. */

    case '\\':
    c = check_escape(&ptr, &errorcode, bracount, options, FALSE);
    if (errorcode != 0) goto PCRE_ERROR_RETURN;

    lastitemlength = 1;     /* Default length of last item for repeats */

    if (c >= 0)             /* Data character */
      {
      length += 2;          /* For a one-byte character */

#ifdef SUPPORT_UTF8
      if (utf8 && c > 127)
        {
        int i;
        for (i = 0; i < _pcre_utf8_table1_size; i++)
          if (c <= _pcre_utf8_table1[i]) break;
        length += i;
        lastitemlength += i;
        }
#endif

      continue;
      }

    /* If \Q, enter "literal" mode */

    if (-c == ESC_Q)
      {
      inescq = TRUE;
      continue;
      }

    /* \X is supported only if Unicode property support is compiled */

#ifndef SUPPORT_UCP
    if (-c == ESC_X)
      {
      errorcode = ERR45;
      goto PCRE_ERROR_RETURN;
      }
#endif

    /* \P and \p are for Unicode properties, but only when the support has
    been compiled. Each item needs 2 bytes. */

    else if (-c == ESC_P || -c == ESC_p)
      {
#ifdef SUPPORT_UCP
      BOOL negated;
      length += 2;
      lastitemlength = 2;
      if (get_ucp(&ptr, &negated, &errorcode) < 0) goto PCRE_ERROR_RETURN;
      continue;
#else
      errorcode = ERR45;
      goto PCRE_ERROR_RETURN;
#endif
      }

    /* Other escapes need one byte */

    length++;

    /* A back reference needs an additional 2 bytes, plus either one or 5
    bytes for a repeat. We also need to keep the value of the highest
    back reference. */

    if (c <= -ESC_REF)
      {
      int refnum = -c - ESC_REF;
      compile_block.backref_map |= (refnum < 32)? (1 << refnum) : 1;
      if (refnum > compile_block.top_backref)
        compile_block.top_backref = refnum;
      length += 2;   /* For single back reference */
      if (ptr[1] == '{' && is_counted_repeat(ptr+2))
        {
        ptr = read_repeat_counts(ptr+2, &min, &max, &errorcode);
        if (errorcode != 0) goto PCRE_ERROR_RETURN;
        if ((min == 0 && (max == 1 || max == -1)) ||
          (min == 1 && max == -1))
            length++;
        else length += 5;
        if (ptr[1] == '?') ptr++;
        }
      }
    continue;

    case '^':     /* Single-byte metacharacters */
    case '.':
    case '$':
    length++;
    lastitemlength = 1;
    continue;

    case '*':            /* These repeats won't be after brackets; */
    case '+':            /* those are handled separately */
    case '?':
    length++;
    goto POSESSIVE;      /* A few lines below */

    /* This covers the cases of braced repeats after a single char, metachar,
    class, or back reference. */

    case '{':
    if (!is_counted_repeat(ptr+1)) goto NORMAL_CHAR;
    ptr = read_repeat_counts(ptr+1, &min, &max, &errorcode);
    if (errorcode != 0) goto PCRE_ERROR_RETURN;

    /* These special cases just insert one extra opcode */

    if ((min == 0 && (max == 1 || max == -1)) ||
      (min == 1 && max == -1))
        length++;

    /* These cases might insert additional copies of a preceding character. */

    else
      {
      if (min != 1)
        {
        length -= lastitemlength;   /* Uncount the original char or metachar */
        if (min > 0) length += 3 + lastitemlength;
        }
      length += lastitemlength + ((max > 0)? 3 : 1);
      }

    if (ptr[1] == '?') ptr++;      /* Needs no extra length */

    POSESSIVE:                     /* Test for possessive quantifier */
    if (ptr[1] == '+')
      {
      ptr++;
      length += 2 + 2*LINK_SIZE;   /* Allow for atomic brackets */
      }
    continue;

    /* An alternation contains an offset to the next branch or ket. If any ims
    options changed in the previous branch(es), and/or if we are in a
    lookbehind assertion, extra space will be needed at the start of the
    branch. This is handled by branch_extra. */

    case '|':
    length += 1 + LINK_SIZE + branch_extra;
    continue;

    /* A character class uses 33 characters provided that all the character
    values are less than 256. Otherwise, it uses a bit map for low valued
    characters, and individual items for others. Don't worry about character
    types that aren't allowed in classes - they'll get picked up during the
    compile. A character class that contains only one single-byte character
    uses 2 or 3 bytes, depending on whether it is negated or not. Notice this
    where we can. (In UTF-8 mode we can do this only for chars < 128.) */

    case '[':
    if (*(++ptr) == '^')
      {
      class_optcount = 10;  /* Greater than one */
      ptr++;
      }
    else class_optcount = 0;

#ifdef SUPPORT_UTF8
    class_utf8 = FALSE;
#endif

    /* Written as a "do" so that an initial ']' is taken as data */

    if (*ptr != 0) do
      {
      /* Inside \Q...\E everything is literal except \E */

      if (inescq)
        {
        if (*ptr != '\\' || ptr[1] != 'E') goto GET_ONE_CHARACTER;
        inescq = FALSE;
        ptr += 1;
        continue;
        }

      /* Outside \Q...\E, check for escapes */

      if (*ptr == '\\')
        {
        c = check_escape(&ptr, &errorcode, bracount, options, TRUE);
        if (errorcode != 0) goto PCRE_ERROR_RETURN;

        /* \b is backspace inside a class; \X is literal */

        if (-c == ESC_b) c = '\b';
        else if (-c == ESC_X) c = 'X';

        /* \Q enters quoting mode */

        else if (-c == ESC_Q)
          {
          inescq = TRUE;
          continue;
          }

        /* Handle escapes that turn into characters */

        if (c >= 0) goto NON_SPECIAL_CHARACTER;

        /* Escapes that are meta-things. The normal ones just affect the
        bit map, but Unicode properties require an XCLASS extended item. */

        else
          {
          class_optcount = 10;         /* \d, \s etc; make sure > 1 */
#ifdef SUPPORT_UTF8
          if (-c == ESC_p || -c == ESC_P)
            {
            if (!class_utf8)
              {
              class_utf8 = TRUE;
              length += LINK_SIZE + 2;
              }
            length += 2;
            }
#endif
          }
        }

      /* Check the syntax for POSIX stuff. The bits we actually handle are
      checked during the real compile phase. */

      else if (*ptr == '[' && check_posix_syntax(ptr, &ptr, &compile_block))
        {
        ptr++;
        class_optcount = 10;    /* Make sure > 1 */
        }

      /* Anything else increments the possible optimization count. We have to
      detect ranges here so that we can compute the number of extra ranges for
      caseless wide characters when UCP support is available. If there are wide
      characters, we are going to have to use an XCLASS, even for single
      characters. */

      else
        {
        int d;

        GET_ONE_CHARACTER:

#ifdef SUPPORT_UTF8
        if (utf8)
          {
          int extra = 0;
          GETCHARLEN(c, ptr, extra);
          ptr += extra;
          }
        else c = *ptr;
#else
        c = *ptr;
#endif

        /* Come here from handling \ above when it escapes to a char value */

        NON_SPECIAL_CHARACTER:
        class_optcount++;

        d = -1;
        if (ptr[1] == '-')
          {
          uschar const *hyptr = ptr++;
          if (ptr[1] == '\\')
            {
            ptr++;
            d = check_escape(&ptr, &errorcode, bracount, options, TRUE);
            if (errorcode != 0) goto PCRE_ERROR_RETURN;
            if (-d == ESC_b) d = '\b';        /* backspace */
            else if (-d == ESC_X) d = 'X';    /* literal X in a class */
            }
          else if (ptr[1] != 0 && ptr[1] != ']')
            {
            ptr++;
#ifdef SUPPORT_UTF8
            if (utf8)
              {
              int extra = 0;
              GETCHARLEN(d, ptr, extra);
              ptr += extra;
              }
            else
#endif
            d = *ptr;
            }
          if (d < 0) ptr = hyptr;      /* go back to hyphen as data */
          }

        /* If d >= 0 we have a range. In UTF-8 mode, if the end is > 255, or >
        127 for caseless matching, we will need to use an XCLASS. */

        if (d >= 0)
          {
          class_optcount = 10;     /* Ensure > 1 */
          if (d < c)
            {
            errorcode = ERR8;
            goto PCRE_ERROR_RETURN;
            }

#ifdef SUPPORT_UTF8
          if (utf8 && (d > 255 || ((options & PCRE_CASELESS) != 0 && d > 127)))
            {
            uschar buffer[6];
            if (!class_utf8)         /* Allow for XCLASS overhead */
              {
              class_utf8 = TRUE;
              length += LINK_SIZE + 2;
              }

#ifdef SUPPORT_UCP
            /* If we have UCP support, find out how many extra ranges are
            needed to map the other case of characters within this range. We
            have to mimic the range optimization here, because extending the
            range upwards might push d over a boundary that makes is use
            another byte in the UTF-8 representation. */

            if ((options & PCRE_CASELESS) != 0)
              {
              int occ, ocd;
              int cc = c;
              int origd = d;
              while (get_othercase_range(&cc, origd, &occ, &ocd))
                {
                if (occ >= c && ocd <= d) continue;   /* Skip embedded */

                if (occ < c  && ocd >= c - 1)  /* Extend the basic range */
                  {                            /* if there is overlap,   */
                  c = occ;                     /* noting that if occ < c */
                  continue;                    /* we can't have ocd > d  */
                  }                            /* because a subrange is  */
                if (ocd > d && occ <= d + 1)   /* always shorter than    */
                  {                            /* the basic range.       */
                  d = ocd;
                  continue;
                  }

                /* An extra item is needed */

                length += 1 + _pcre_ord2utf8(occ, buffer) +
                  ((occ == ocd)? 0 : _pcre_ord2utf8(ocd, buffer));
                }
              }
#endif  /* SUPPORT_UCP */

            /* The length of the (possibly extended) range */

            length += 1 + _pcre_ord2utf8(c, buffer) + _pcre_ord2utf8(d, buffer);
            }
#endif  /* SUPPORT_UTF8 */

          }

        /* We have a single character. There is nothing to be done unless we
        are in UTF-8 mode. If the char is > 255, or 127 when caseless, we must
        allow for an XCL_SINGLE item, doubled for caselessness if there is UCP
        support. */

        else
          {
#ifdef SUPPORT_UTF8
          if (utf8 && (c > 255 || ((options & PCRE_CASELESS) != 0 && c > 127)))
            {
            uschar buffer[6];
            class_optcount = 10;     /* Ensure > 1 */
            if (!class_utf8)         /* Allow for XCLASS overhead */
              {
              class_utf8 = TRUE;
              length += LINK_SIZE + 2;
              }
#ifdef SUPPORT_UCP
            length += (((options & PCRE_CASELESS) != 0)? 2 : 1) *
              (1 + _pcre_ord2utf8(c, buffer));
#else   /* SUPPORT_UCP */
            length += 1 + _pcre_ord2utf8(c, buffer);
#endif  /* SUPPORT_UCP */
            }
#endif  /* SUPPORT_UTF8 */
          }
        }
      }
    while (*(++ptr) != 0 && (inescq || *ptr != ']')); /* Concludes "do" above */

    if (*ptr == 0)                          /* Missing terminating ']' */
      {
      errorcode = ERR6;
      goto PCRE_ERROR_RETURN;
      }

    /* We can optimize when there was only one optimizable character. Repeats
    for positive and negated single one-byte chars are handled by the general
    code. Here, we handle repeats for the class opcodes. */

    if (class_optcount == 1) length += 3; else
      {
      length += 33;

      /* A repeat needs either 1 or 5 bytes. If it is a possessive quantifier,
      we also need extra for wrapping the whole thing in a sub-pattern. */

      if (*ptr != 0 && ptr[1] == '{' && is_counted_repeat(ptr+2))
        {
        ptr = read_repeat_counts(ptr+2, &min, &max, &errorcode);
        if (errorcode != 0) goto PCRE_ERROR_RETURN;
        if ((min == 0 && (max == 1 || max == -1)) ||
          (min == 1 && max == -1))
            length++;
        else length += 5;
        if (ptr[1] == '+')
          {
          ptr++;
          length += 2 + 2*LINK_SIZE;
          }
        else if (ptr[1] == '?') ptr++;
        }
      }
    continue;

    /* Brackets may be genuine groups or special things */

    case '(':
    branch_newextra = 0;
    bracket_length = 1 + LINK_SIZE;
    capturing = FALSE;

    /* Handle special forms of bracket, which all start (? */

    if (ptr[1] == '?')
      {
      int set, unset;
      int *optset;

      switch (c = ptr[2])
        {
        /* Skip over comments entirely */
        case '#':
        ptr += 3;
        while (*ptr != 0 && *ptr != ')') ptr++;
        if (*ptr == 0)
          {
          errorcode = ERR18;
          goto PCRE_ERROR_RETURN;
          }
        continue;

        /* Non-referencing groups and lookaheads just move the pointer on, and
        then behave like a non-special bracket, except that they don't increment
        the count of extracting brackets. Ditto for the "once only" bracket,
        which is in Perl from version 5.005. */

        case ':':
        case '=':
        case '!':
        case '>':
        ptr += 2;
        break;

        /* (?R) specifies a recursive call to the regex, which is an extension
        to provide the facility which can be obtained by (?p{perl-code}) in
        Perl 5.6. In Perl 5.8 this has become (??{perl-code}).

        From PCRE 4.00, items such as (?3) specify subroutine-like "calls" to
        the appropriate numbered brackets. This includes both recursive and
        non-recursive calls. (?R) is now synonymous with (?0). */

        case 'R':
        ptr++;

        case '0': case '1': case '2': case '3': case '4':
        case '5': case '6': case '7': case '8': case '9':
        ptr += 2;
        if (c != 'R')
          while ((digitab[*(++ptr)] & ctype_digit) != 0);
        if (*ptr != ')')
          {
          errorcode = ERR29;
          goto PCRE_ERROR_RETURN;
          }
        length += 1 + LINK_SIZE;

        /* If this item is quantified, it will get wrapped inside brackets so
        as to use the code for quantified brackets. We jump down and use the
        code that handles this for real brackets. */

        if (ptr[1] == '+' || ptr[1] == '*' || ptr[1] == '?' || ptr[1] == '{')
          {
          length += 2 + 2 * LINK_SIZE;       /* to make bracketed */
          duplength = 5 + 3 * LINK_SIZE;
          goto HANDLE_QUANTIFIED_BRACKETS;
          }
        continue;

        /* (?C) is an extension which provides "callout" - to provide a bit of
        the functionality of the Perl (?{...}) feature. An optional number may
        follow (default is zero). */

        case 'C':
        ptr += 2;
        while ((digitab[*(++ptr)] & ctype_digit) != 0);
        if (*ptr != ')')
          {
          errorcode = ERR39;
          goto PCRE_ERROR_RETURN;
          }
        length += 2 + 2*LINK_SIZE;
        continue;

        /* Named subpatterns are an extension copied from Python */

        case 'P':
        ptr += 3;

        /* Handle the definition of a named subpattern */

        if (*ptr == '<')
          {
          const uschar *p;    /* Don't amalgamate; some compilers */
          p = ++ptr;          /* grumble at autoincrement in declaration */
          while ((compile_block.ctypes[*ptr] & ctype_word) != 0) ptr++;
          if (*ptr != '>')
            {
            errorcode = ERR42;
            goto PCRE_ERROR_RETURN;
            }
          name_count++;
          if (ptr - p > max_name_size) max_name_size = (ptr - p);
          capturing = TRUE;   /* Named parentheses are always capturing */
          break;
          }

        /* Handle back references and recursive calls to named subpatterns */

        if (*ptr == '=' || *ptr == '>')
          {
          while ((compile_block.ctypes[*(++ptr)] & ctype_word) != 0);
          if (*ptr != ')')
            {
            errorcode = ERR42;
            goto PCRE_ERROR_RETURN;
            }
          break;
          }

        /* Unknown character after (?P */

        errorcode = ERR41;
        goto PCRE_ERROR_RETURN;

        /* Lookbehinds are in Perl from version 5.005 */

        case '<':
        ptr += 3;
        if (*ptr == '=' || *ptr == '!')
          {
          branch_newextra = 1 + LINK_SIZE;
          length += 1 + LINK_SIZE;         /* For the first branch */
          break;
          }
        errorcode = ERR24;
        goto PCRE_ERROR_RETURN;

        /* Conditionals are in Perl from version 5.005. The bracket must either
        be followed by a number (for bracket reference) or by an assertion
        group, or (a PCRE extension) by 'R' for a recursion test. */

        case '(':
        if (ptr[3] == 'R' && ptr[4] == ')')
          {
          ptr += 4;
          length += 3;
          }
        else if ((digitab[ptr[3]] & ctype_digit) != 0)
          {
          ptr += 4;
          length += 3;
          while ((digitab[*ptr] & ctype_digit) != 0) ptr++;
          if (*ptr != ')')
            {
            errorcode = ERR26;
            goto PCRE_ERROR_RETURN;
            }
          }
        else   /* An assertion must follow */
          {
          ptr++;   /* Can treat like ':' as far as spacing is concerned */
          if (ptr[2] != '?' ||
             (ptr[3] != '=' && ptr[3] != '!' && ptr[3] != '<') )
            {
            ptr += 2;    /* To get right offset in message */
            errorcode = ERR28;
            goto PCRE_ERROR_RETURN;
            }
          }
        break;

        /* Else loop checking valid options until ) is met. Anything else is an
        error. If we are without any brackets, i.e. at top level, the settings
        act as if specified in the options, so massage the options immediately.
        This is for backward compatibility with Perl 5.004. */

        default:
        set = unset = 0;
        optset = &set;
        ptr += 2;

        for (;; ptr++)
          {
          c = *ptr;
          switch (c)
            {
            case 'i':
            *optset |= PCRE_CASELESS;
            continue;

            case 'm':
            *optset |= PCRE_MULTILINE;
            continue;

            case 's':
            *optset |= PCRE_DOTALL;
            continue;

            case 'x':
            *optset |= PCRE_EXTENDED;
            continue;

            case 'X':
            *optset |= PCRE_EXTRA;
            continue;

            case 'U':
            *optset |= PCRE_UNGREEDY;
            continue;

            case '-':
            optset = &unset;
            continue;

            /* A termination by ')' indicates an options-setting-only item; if
            this is at the very start of the pattern (indicated by item_count
            being zero), we use it to set the global options. This is helpful
            when analyzing the pattern for first characters, etc. Otherwise
            nothing is done here and it is handled during the compiling
            process.

            We allow for more than one options setting at the start. If such
            settings do not change the existing options, nothing is compiled.
            However, we must leave space just in case something is compiled.
            This can happen for pathological sequences such as (?i)(?-i)
            because the global options will end up with -i set. The space is
            small and not significant. (Before I did this there was a reported
            bug with (?i)(?-i) in a machine-generated pattern.)

            [Historical note: Up to Perl 5.8, options settings at top level
            were always global settings, wherever they appeared in the pattern.
            That is, they were equivalent to an external setting. From 5.8
            onwards, they apply only to what follows (which is what you might
            expect).] */

            case ')':
            if (item_count == 0)
              {
              options = (options | set) & (~unset);
              set = unset = 0;     /* To save length */
              item_count--;        /* To allow for several */
              length += 2;
              }

            /* Fall through */

            /* A termination by ':' indicates the start of a nested group with
            the given options set. This is again handled at compile time, but
            we must allow for compiled space if any of the ims options are
            set. We also have to allow for resetting space at the end of
            the group, which is why 4 is added to the length and not just 2.
            If there are several changes of options within the same group, this
            will lead to an over-estimate on the length, but this shouldn't
            matter very much. We also have to allow for resetting options at
            the start of any alternations, which we do by setting
            branch_newextra to 2. Finally, we record whether the case-dependent
            flag ever changes within the regex. This is used by the "required
            character" code. */

            case ':':
            if (((set|unset) & PCRE_IMS) != 0)
              {
              length += 4;
              branch_newextra = 2;
              if (((set|unset) & PCRE_CASELESS) != 0) options |= PCRE_ICHANGED;
              }
            goto END_OPTIONS;

            /* Unrecognized option character */

            default:
            errorcode = ERR12;
            goto PCRE_ERROR_RETURN;
            }
          }

        /* If we hit a closing bracket, that's it - this is a freestanding
        option-setting. We need to ensure that branch_extra is updated if
        necessary. The only values branch_newextra can have here are 0 or 2.
        If the value is 2, then branch_extra must either be 2 or 5, depending
        on whether this is a lookbehind group or not. */

        END_OPTIONS:
        if (c == ')')
          {
          if (branch_newextra == 2 &&
              (branch_extra == 0 || branch_extra == 1+LINK_SIZE))
            branch_extra += branch_newextra;
          continue;
          }

        /* If options were terminated by ':' control comes here. This is a
        non-capturing group with an options change. There is nothing more that
        needs to be done because "capturing" is already set FALSE by default;
        we can just fall through. */

        }
      }

    /* Ordinary parentheses, not followed by '?', are capturing unless
    PCRE_NO_AUTO_CAPTURE is set. */

    else capturing = (options & PCRE_NO_AUTO_CAPTURE) == 0;

    /* Capturing brackets must be counted so we can process escapes in a
    Perlish way. If the number exceeds EXTRACT_BASIC_MAX we are going to need
    an additional 3 bytes of memory per capturing bracket. */

    if (capturing)
      {
      bracount++;
      if (bracount > EXTRACT_BASIC_MAX) bracket_length += 3;
      }

    /* Save length for computing whole length at end if there's a repeat that
    requires duplication of the group. Also save the current value of
    branch_extra, and start the new group with the new value. If non-zero, this
    will either be 2 for a (?imsx: group, or 3 for a lookbehind assertion. */

    if (brastackptr >= sizeof(brastack)/sizeof(int))
      {
      errorcode = ERR19;
      goto PCRE_ERROR_RETURN;
      }

    bralenstack[brastackptr] = branch_extra;
    branch_extra = branch_newextra;

    brastack[brastackptr++] = length;
    length += bracket_length;
    continue;

    /* Handle ket. Look for subsequent max/min; for certain sets of values we
    have to replicate this bracket up to that many times. If brastackptr is
    0 this is an unmatched bracket which will generate an error, but take care
    not to try to access brastack[-1] when computing the length and restoring
    the branch_extra value. */

    case ')':
    length += 1 + LINK_SIZE;
    if (brastackptr > 0)
      {
      duplength = length - brastack[--brastackptr];
      branch_extra = bralenstack[brastackptr];
      }
    else duplength = 0;

    /* The following code is also used when a recursion such as (?3) is
    followed by a quantifier, because in that case, it has to be wrapped inside
    brackets so that the quantifier works. The value of duplength must be
    set before arrival. */

    HANDLE_QUANTIFIED_BRACKETS:

    /* Leave ptr at the final char; for read_repeat_counts this happens
    automatically; for the others we need an increment. */

    if ((c = ptr[1]) == '{' && is_counted_repeat(ptr+2))
      {
      ptr = read_repeat_counts(ptr+2, &min, &max, &errorcode);
      if (errorcode != 0) goto PCRE_ERROR_RETURN;
      }
    else if (c == '*') { min = 0; max = -1; ptr++; }
    else if (c == '+') { min = 1; max = -1; ptr++; }
    else if (c == '?') { min = 0; max = 1;  ptr++; }
    else { min = 1; max = 1; }

    /* If the minimum is zero, we have to allow for an OP_BRAZERO before the
    group, and if the maximum is greater than zero, we have to replicate
    maxval-1 times; each replication acquires an OP_BRAZERO plus a nesting
    bracket set. */

    if (min == 0)
      {
      length++;
      if (max > 0) length += (max - 1) * (duplength + 3 + 2*LINK_SIZE);
      }

    /* When the minimum is greater than zero, we have to replicate up to
    minval-1 times, with no additions required in the copies. Then, if there
    is a limited maximum we have to replicate up to maxval-1 times allowing
    for a BRAZERO item before each optional copy and nesting brackets for all
    but one of the optional copies. */

    else
      {
      length += (min - 1) * duplength;
      if (max > min)   /* Need this test as max=-1 means no limit */
        length += (max - min) * (duplength + 3 + 2*LINK_SIZE)
          - (2 + 2*LINK_SIZE);
      }

    /* Allow space for once brackets for "possessive quantifier" */

    if (ptr[1] == '+')
      {
      ptr++;
      length += 2 + 2*LINK_SIZE;
      }
    continue;

    /* Non-special character. It won't be space or # in extended mode, so it is
    always a genuine character. If we are in a \Q...\E sequence, check for the
    end; if not, we have a literal. */

    default:
    NORMAL_CHAR:

    if (inescq && c == '\\' && ptr[1] == 'E')
      {
      inescq = FALSE;
      ptr++;
      continue;
      }

    length += 2;          /* For a one-byte character */
    lastitemlength = 1;   /* Default length of last item for repeats */

    /* In UTF-8 mode, check for additional bytes. */

#ifdef SUPPORT_UTF8
    if (utf8 && (c & 0xc0) == 0xc0)
      {
      while ((ptr[1] & 0xc0) == 0x80)         /* Can't flow over the end */
        {                                     /* because the end is marked */
        lastitemlength++;                     /* by a zero byte. */
        length++;
        ptr++;
        }
      }
#endif

    continue;
    }
  }

length += 2 + LINK_SIZE;    /* For final KET and END */

if ((options & PCRE_AUTO_CALLOUT) != 0)
  length += 2 + 2*LINK_SIZE;  /* For final callout */

if (length > MAX_PATTERN_SIZE)
  {
  errorcode = ERR20;
  goto PCRE_EARLY_ERROR_RETURN;
  }

/* Compute the size of data block needed and get it, either from malloc or
externally provided function. */

size = length + sizeof(real_pcre) + name_count * (max_name_size + 3);
re = (real_pcre *)(pcre_malloc)(size);

if (re == NULL)
  {
  errorcode = ERR21;
  goto PCRE_EARLY_ERROR_RETURN;
  }

/* Put in the magic number, and save the sizes, options, and character table
pointer. NULL is used for the default character tables. The nullpad field is at
the end; it's there to help in the case when a regex compiled on a system with
4-byte pointers is run on another with 8-byte pointers. */

re->magic_number = MAGIC_NUMBER;
re->size = size;
re->options = options;
re->dummy1 = 0;
re->name_table_offset = sizeof(real_pcre);
re->name_entry_size = max_name_size + 3;
re->name_count = name_count;
re->ref_count = 0;
re->tables = (tables == _pcre_default_tables)? NULL : tables;
re->nullpad = NULL;

/* The starting points of the name/number translation table and of the code are
passed around in the compile data block. */

compile_block.names_found = 0;
compile_block.name_entry_size = max_name_size + 3;
compile_block.name_table = (uschar *)re + re->name_table_offset;
codestart = compile_block.name_table + re->name_entry_size * re->name_count;
compile_block.start_code = codestart;
compile_block.start_pattern = (const uschar *)pattern;
compile_block.req_varyopt = 0;
compile_block.nopartial = FALSE;

/* Set up a starting, non-extracting bracket, then compile the expression. On
error, errorcode will be set non-zero, so we don't need to look at the result
of the function here. */

ptr = (const uschar *)pattern;
code = (uschar *)codestart;
*code = OP_BRA;
bracount = 0;
(void)compile_regex(options, options & PCRE_IMS, &bracount, &code, &ptr,
  &errorcode, FALSE, 0, &firstbyte, &reqbyte, NULL, &compile_block);
re->top_bracket = bracount;
re->top_backref = compile_block.top_backref;

if (compile_block.nopartial) re->options |= PCRE_NOPARTIAL;

/* If not reached end of pattern on success, there's an excess bracket. */

if (errorcode == 0 && *ptr != 0) errorcode = ERR22;

/* Fill in the terminating state and check for disastrous overflow, but
if debugging, leave the test till after things are printed out. */

*code++ = OP_END;

#ifndef DEBUG
if (code - codestart > length) errorcode = ERR23;
#endif

/* Give an error if there's back reference to a non-existent capturing
subpattern. */

if (re->top_backref > re->top_bracket) errorcode = ERR15;

/* Failed to compile, or error while post-processing */

if (errorcode != 0)
  {
  (pcre_free)(re);
  PCRE_ERROR_RETURN:
  *erroroffset = ptr - (const uschar *)pattern;
  PCRE_EARLY_ERROR_RETURN:
  *errorptr = error_texts[errorcode];
  if (errorcodeptr != NULL) *errorcodeptr = errorcode;
  return NULL;
  }

/* If the anchored option was not passed, set the flag if we can determine that
the pattern is anchored by virtue of ^ characters or \A or anything else (such
as starting with .* when DOTALL is set).

Otherwise, if we know what the first character has to be, save it, because that
speeds up unanchored matches no end. If not, see if we can set the
PCRE_STARTLINE flag. This is helpful for multiline matches when all branches
start with ^. and also when all branches start with .* for non-DOTALL matches.
*/

if ((options & PCRE_ANCHORED) == 0)
  {
  int temp_options = options;
  if (is_anchored(codestart, &temp_options, 0, compile_block.backref_map))
    re->options |= PCRE_ANCHORED;
  else
    {
    if (firstbyte < 0)
      firstbyte = find_firstassertedchar(codestart, &temp_options, FALSE);
    if (firstbyte >= 0)   /* Remove caseless flag for non-caseable chars */
      {
      int ch = firstbyte & 255;
      re->first_byte = ((firstbyte & REQ_CASELESS) != 0 &&
         compile_block.fcc[ch] == ch)? ch : firstbyte;
      re->options |= PCRE_FIRSTSET;
      }
    else if (is_startline(codestart, 0, compile_block.backref_map))
      re->options |= PCRE_STARTLINE;
    }
  }

/* For an anchored pattern, we use the "required byte" only if it follows a
variable length item in the regex. Remove the caseless flag for non-caseable
bytes. */

if (reqbyte >= 0 &&
     ((re->options & PCRE_ANCHORED) == 0 || (reqbyte & REQ_VARY) != 0))
  {
  int ch = reqbyte & 255;
  re->req_byte = ((reqbyte & REQ_CASELESS) != 0 &&
    compile_block.fcc[ch] == ch)? (reqbyte & ~REQ_CASELESS) : reqbyte;
  re->options |= PCRE_REQCHSET;
  }

/* Print out the compiled data for debugging */

#ifdef DEBUG

printf("Length = %d top_bracket = %d top_backref = %d\n",
  length, re->top_bracket, re->top_backref);

if (re->options != 0)
  {
  printf("%s%s%s%s%s%s%s%s%s%s\n",
    ((re->options & PCRE_NOPARTIAL) != 0)? "nopartial " : "",
    ((re->options & PCRE_ANCHORED) != 0)? "anchored " : "",
    ((re->options & PCRE_CASELESS) != 0)? "caseless " : "",
    ((re->options & PCRE_ICHANGED) != 0)? "case state changed " : "",
    ((re->options & PCRE_EXTENDED) != 0)? "extended " : "",
    ((re->options & PCRE_MULTILINE) != 0)? "multiline " : "",
    ((re->options & PCRE_DOTALL) != 0)? "dotall " : "",
    ((re->options & PCRE_DOLLAR_ENDONLY) != 0)? "endonly " : "",
    ((re->options & PCRE_EXTRA) != 0)? "extra " : "",
    ((re->options & PCRE_UNGREEDY) != 0)? "ungreedy " : "");
  }

if ((re->options & PCRE_FIRSTSET) != 0)
  {
  int ch = re->first_byte & 255;
  const char *caseless = ((re->first_byte & REQ_CASELESS) == 0)? "" : " (caseless)";
  if (isprint(ch)) printf("First char = %c%s\n", ch, caseless);
    else printf("First char = \\x%02x%s\n", ch, caseless);
  }

if ((re->options & PCRE_REQCHSET) != 0)
  {
  int ch = re->req_byte & 255;
  const char *caseless = ((re->req_byte & REQ_CASELESS) == 0)? "" : " (caseless)";
  if (isprint(ch)) printf("Req char = %c%s\n", ch, caseless);
    else printf("Req char = \\x%02x%s\n", ch, caseless);
  }

_pcre_printint(re, stdout);

/* This check is done here in the debugging case so that the code that
was compiled can be seen. */

if (code - codestart > length)
  {
  (pcre_free)(re);
  *errorptr = error_texts[ERR23];
  *erroroffset = ptr - (uschar *)pattern;
  if (errorcodeptr != NULL) *errorcodeptr = ERR23;
  return NULL;
  }
#endif

return (pcre *)re;
}

/* End of pcre_compile.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains the external function pcre_config(). */




/*************************************************
* Return info about what features are configured *
*************************************************/

/* This function has an extensible interface so that additional items can be
added compatibly.

Arguments:
  what             what information is required
  where            where to put the information

Returns:           0 if data returned, negative on error
*/

EXPORT int
pcre_config(int what, void *where)
{
switch (what)
  {
  case PCRE_CONFIG_UTF8:
#ifdef SUPPORT_UTF8
  *((int *)where) = 1;
#else
  *((int *)where) = 0;
#endif
  break;

  case PCRE_CONFIG_UNICODE_PROPERTIES:
#ifdef SUPPORT_UCP
  *((int *)where) = 1;
#else
  *((int *)where) = 0;
#endif
  break;

  case PCRE_CONFIG_NEWLINE:
  *((int *)where) = NEWLINE;
  break;

  case PCRE_CONFIG_LINK_SIZE:
  *((int *)where) = LINK_SIZE;
  break;

  case PCRE_CONFIG_POSIX_MALLOC_THRESHOLD:
  *((int *)where) = POSIX_MALLOC_THRESHOLD;
  break;

  case PCRE_CONFIG_MATCH_LIMIT:
  *((unsigned int *)where) = MATCH_LIMIT;
  break;

  case PCRE_CONFIG_STACKRECURSE:
#ifdef NO_RECURSE
  *((int *)where) = 0;
#else
  *((int *)where) = 1;
#endif
  break;

  default: return PCRE_ERROR_BADOPTION;
  }

return 0;
}

/* End of pcre_config.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains the external function pcre_dfa_exec(), which is an
alternative matching function that uses a DFA algorithm. This is NOT Perl-
compatible, but it has advantages in certain applications. */




/* For use to indent debugging output */

#define SP "                   "



/*************************************************
*      Code parameters and static tables         *
*************************************************/

/* These are offsets that are used to turn the OP_TYPESTAR and friends opcodes
into others, under special conditions. A gap of 10 between the blocks should be
enough. */

#define OP_PROP_EXTRA    (EXTRACT_BASIC_MAX+1)
#define OP_EXTUNI_EXTRA  (EXTRACT_BASIC_MAX+11)


/* This table identifies those opcodes that are followed immediately by a
character that is to be tested in some way. This makes is possible to
centralize the loading of these characters. In the case of Type * etc, the
"character" is the opcode for \D, \d, \S, \s, \W, or \w, which will always be a
small value. */

static uschar coptable[] = {
  0,                             /* End                                    */
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  /* \A, \G, \B, \b, \D, \d, \S, \s, \W, \w */
  0, 0,                          /* Any, Anybyte                           */
  0, 0, 0,                       /* NOTPROP, PROP, EXTUNI                  */
  0, 0, 0, 0, 0,                 /* \Z, \z, Opt, ^, $                      */
  1,                             /* Char                                   */
  1,                             /* Charnc                                 */
  1,                             /* not                                    */
  /* Positive single-char repeats                                          */
  1, 1, 1, 1, 1, 1,              /* *, *?, +, +?, ?, ??                    */
  3, 3, 3,                       /* upto, minupto, exact                   */
  /* Negative single-char repeats - only for chars < 256                   */
  1, 1, 1, 1, 1, 1,              /* NOT *, *?, +, +?, ?, ??                */
  3, 3, 3,                       /* NOT upto, minupto, exact               */
  /* Positive type repeats                                                 */
  1, 1, 1, 1, 1, 1,              /* Type *, *?, +, +?, ?, ??               */
  3, 3, 3,                       /* Type upto, minupto, exact              */
  /* Character class & ref repeats                                         */
  0, 0, 0, 0, 0, 0,              /* *, *?, +, +?, ?, ??                    */
  0, 0,                          /* CRRANGE, CRMINRANGE                    */
  0,                             /* CLASS                                  */
  0,                             /* NCLASS                                 */
  0,                             /* XCLASS - variable length               */
  0,                             /* REF                                    */
  0,                             /* RECURSE                                */
  0,                             /* CALLOUT                                */
  0,                             /* Alt                                    */
  0,                             /* Ket                                    */
  0,                             /* KetRmax                                */
  0,                             /* KetRmin                                */
  0,                             /* Assert                                 */
  0,                             /* Assert not                             */
  0,                             /* Assert behind                          */
  0,                             /* Assert behind not                      */
  0,                             /* Reverse                                */
  0,                             /* Once                                   */
  0,                             /* COND                                   */
  0,                             /* CREF                                   */
  0, 0,                          /* BRAZERO, BRAMINZERO                    */
  0,                             /* BRANUMBER                              */
  0                              /* BRA                                    */
};

/* These 2 tables allow for compact code for testing for \D, \d, \S, \s, \W,
and \w */

static uschar toptable1[] = {
  0, 0, 0, 0, 0,
  ctype_digit, ctype_digit,
  ctype_space, ctype_space,
  ctype_word,  ctype_word,
  0                               /* OP_ANY */
};

static uschar toptable2[] = {
  0, 0, 0, 0, 0,
  ctype_digit, 0,
  ctype_space, 0,
  ctype_word,  0,
  1                               /* OP_ANY */
};


/* Structure for holding data about a particular state, which is in effect the
current data for an active path through the match tree. It must consist
entirely of ints because the working vector we are passed, and which we put
these structures in, is a vector of ints. */

typedef struct stateblock {
  int offset;                     /* Offset to opcode */
  int count;                      /* Count for repeats */
  int ims;                        /* ims flag bits */
  int data;                       /* Some use extra data */
} stateblock;

#define INTS_PER_STATEBLOCK  (sizeof(stateblock)/sizeof(int))


#ifdef DEBUG
/*************************************************
*             Print character string             *
*************************************************/

/* Character string printing function for debugging.

Arguments:
  p            points to string
  length       number of bytes
  f            where to print

Returns:       nothing
*/

static void
pchars(unsigned char *p, int length, FILE *f)
{
int c;
while (length-- > 0)
  {
  if (isprint(c = *(p++)))
    fprintf(f, "%c", c);
  else
    fprintf(f, "\\x%02x", c);
  }
}
#endif



/*************************************************
*    Execute a Regular Expression - DFA engine   *
*************************************************/

/* This internal function applies a compiled pattern to a subject string,
starting at a given point, using a DFA engine. This function is called from the
external one, possibly multiple times if the pattern is not anchored. The
function calls itself recursively for some kinds of subpattern.

Arguments:
  md                the match_data block with fixed information
  this_start_code   the opening bracket of this subexpression's code
  current_subject   where we currently are in the subject string
  start_offset      start offset in the subject string
  offsets           vector to contain the matching string offsets
  offsetcount       size of same
  workspace         vector of workspace
  wscount           size of same
  ims               the current ims flags
  rlevel            function call recursion level
  recursing         regex recursive call level

Returns:            > 0 =>
                    = 0 =>
                     -1 => failed to match
                   < -1 => some kind of unexpected problem

The following macros are used for adding states to the two state vectors (one
for the current character, one for the following character). */

#define ADD_ACTIVE(x,y) \
  if (active_count++ < wscount) \
    { \
    next_active_state->offset = (x); \
    next_active_state->count  = (y); \
    next_active_state->ims    = ims; \
    next_active_state++; \
    DPRINTF(("%.*sADD_ACTIVE(%d,%d)\n", rlevel*2-2, SP, (x), (y))); \
    } \
  else return PCRE_ERROR_DFA_WSSIZE

#define ADD_ACTIVE_DATA(x,y,z) \
  if (active_count++ < wscount) \
    { \
    next_active_state->offset = (x); \
    next_active_state->count  = (y); \
    next_active_state->ims    = ims; \
    next_active_state->data   = (z); \
    next_active_state++; \
    DPRINTF(("%.*sADD_ACTIVE_DATA(%d,%d,%d)\n", rlevel*2-2, SP, (x), (y), (z))); \
    } \
  else return PCRE_ERROR_DFA_WSSIZE

#define ADD_NEW(x,y) \
  if (new_count++ < wscount) \
    { \
    next_new_state->offset = (x); \
    next_new_state->count  = (y); \
    next_new_state->ims    = ims; \
    next_new_state++; \
    DPRINTF(("%.*sADD_NEW(%d,%d)\n", rlevel*2-2, SP, (x), (y))); \
    } \
  else return PCRE_ERROR_DFA_WSSIZE

#define ADD_NEW_DATA(x,y,z) \
  if (new_count++ < wscount) \
    { \
    next_new_state->offset = (x); \
    next_new_state->count  = (y); \
    next_new_state->ims    = ims; \
    next_new_state->data   = (z); \
    next_new_state++; \
    DPRINTF(("%.*sADD_NEW_DATA(%d,%d,%d)\n", rlevel*2-2, SP, (x), (y), (z))); \
    } \
  else return PCRE_ERROR_DFA_WSSIZE

/* And now, here is the code */

static int
internal_dfa_exec(
  dfa_match_data *md,
  const uschar *this_start_code,
  const uschar *current_subject,
  int start_offset,
  int *offsets,
  int offsetcount,
  int *workspace,
  int wscount,
  int ims,
  int  rlevel,
  int  recursing)
{
stateblock *active_states, *new_states, *temp_states;
stateblock *next_active_state, *next_new_state;

const uschar *ctypes, *lcc, *fcc;
const uschar *ptr;
const uschar *end_code;

int active_count, new_count, match_count;

/* Some fields in the md block are frequently referenced, so we load them into
independent variables in the hope that this will perform better. */

const uschar *start_subject = md->start_subject;
const uschar *end_subject = md->end_subject;
const uschar *start_code = md->start_code;

BOOL utf8 = (md->poptions & PCRE_UTF8) != 0;

rlevel++;
offsetcount &= (-2);

wscount -= 2;
wscount = (wscount - (wscount % (INTS_PER_STATEBLOCK * 2))) /
          (2 * INTS_PER_STATEBLOCK);

DPRINTF(("\n%.*s---------------------\n"
  "%.*sCall to internal_dfa_exec f=%d r=%d\n",
  rlevel*2-2, SP, rlevel*2-2, SP, rlevel, recursing));

ctypes = md->tables + ctypes_offset;
lcc = md->tables + lcc_offset;
fcc = md->tables + fcc_offset;

match_count = PCRE_ERROR_NOMATCH;   /* A negative number */

active_states = (stateblock *)(workspace + 2);
next_new_state = new_states = active_states + wscount;
new_count = 0;

/* The first thing in any (sub) pattern is a bracket of some sort. Push all
the alternative states onto the list, and find out where the end is. This
makes is possible to use this function recursively, when we want to stop at a
matching internal ket rather than at the end.

If the first opcode in the first alternative is OP_REVERSE, we are dealing with
a backward assertion. In that case, we have to find out the maximum amount to
move back, and set up each alternative appropriately. */

if (this_start_code[1+LINK_SIZE] == OP_REVERSE)
  {
  int max_back = 0;
  int gone_back;

  end_code = this_start_code;
  do
    {
    int back = GET(end_code, 2+LINK_SIZE);
    if (back > max_back) max_back = back;
    end_code += GET(end_code, 1);
    }
  while (*end_code == OP_ALT);

  /* If we can't go back the amount required for the longest lookbehind
  pattern, go back as far as we can; some alternatives may still be viable. */

#ifdef SUPPORT_UTF8
  /* In character mode we have to step back character by character */

  if (utf8)
    {
    for (gone_back = 0; gone_back < max_back; gone_back++)
      {
      if (current_subject <= start_subject) break;
      current_subject--;
      while (current_subject > start_subject &&
             (*current_subject & 0xc0) == 0x80)
        current_subject--;
      }
    }
  else
#endif

  /* In byte-mode we can do this quickly. */

    {
    gone_back = (current_subject - max_back < start_subject)?
      current_subject - start_subject : max_back;
    current_subject -= gone_back;
    }

  /* Now we can process the individual branches. */

  end_code = this_start_code;
  do
    {
    int back = GET(end_code, 2+LINK_SIZE);
    if (back <= gone_back)
      {
      int bstate = end_code - start_code + 2 + 2*LINK_SIZE;
      ADD_NEW_DATA(-bstate, 0, gone_back - back);
      }
    end_code += GET(end_code, 1);
    }
  while (*end_code == OP_ALT);
 }

/* This is the code for a "normal" subpattern (not a backward assertion). The
start of a whole pattern is always one of these. If we are at the top level,
we may be asked to restart matching from the same point that we reached for a
previous partial match. We still have to scan through the top-level branches to
find the end state. */

else
  {
  end_code = this_start_code;

  /* Restarting */

  if (rlevel == 1 && (md->moptions & PCRE_DFA_RESTART) != 0)
    {
    do { end_code += GET(end_code, 1); } while (*end_code == OP_ALT);
    new_count = workspace[1];
    if (!workspace[0])
      memcpy(new_states, active_states, new_count * sizeof(stateblock));
    }

  /* Not restarting */

  else
    {
    do
      {
      ADD_NEW(end_code - start_code + 1 + LINK_SIZE, 0);
      end_code += GET(end_code, 1);
      }
    while (*end_code == OP_ALT);
    }
  }

workspace[0] = 0;    /* Bit indicating which vector is current */

DPRINTF(("%.*sEnd state = %d\n", rlevel*2-2, SP, end_code - start_code));

/* Loop for scanning the subject */

ptr = current_subject;
for (;;)
  {
  int i, j;
  int c, d, clen, dlen;

  /* Make the new state list into the active state list and empty the
  new state list. */

  temp_states = active_states;
  active_states = new_states;
  new_states = temp_states;
  active_count = new_count;
  new_count = 0;

  workspace[0] ^= 1;              /* Remember for the restarting feature */
  workspace[1] = active_count;

#ifdef DEBUG
  printf("%.*sNext character: rest of subject = \"", rlevel*2-2, SP);
  pchars((uschar *)ptr, strlen((char *)ptr), stdout);
  printf("\"\n");

  printf("%.*sActive states: ", rlevel*2-2, SP);
  for (i = 0; i < active_count; i++)
    printf("%d/%d ", active_states[i].offset, active_states[i].count);
  printf("\n");
#endif

  /* Set the pointers for adding new states */

  next_active_state = active_states + active_count;
  next_new_state = new_states;

  /* Load the current character from the subject outside the loop, as many
  different states may want to look at it, and we assume that at least one
  will. */

  if (ptr < end_subject)
    {
    clen = 1;
#ifdef SUPPORT_UTF8
    if (utf8) { GETCHARLEN(c, ptr, clen); } else
#endif  /* SUPPORT_UTF8 */
    c = *ptr;
    }
  else
    {
    clen = 0;    /* At end subject */
    c = -1;
    }

  /* Scan up the active states and act on each one. The result of an action
  may be to add more states to the currently active list (e.g. on hitting a
  parenthesis) or it may be to put states on the new list, for considering
  when we move the character pointer on. */

  for (i = 0; i < active_count; i++)
    {
    stateblock *current_state = active_states + i;
    const uschar *code;
    int state_offset = current_state->offset;
    int count, codevalue;
    int chartype, othercase;

#ifdef DEBUG
    printf ("%.*sProcessing state %d c=", rlevel*2-2, SP, state_offset);
    if (c < 0) printf("-1\n");
      else if (c > 32 && c < 127) printf("'%c'\n", c);
        else printf("0x%02x\n", c);
#endif

    /* This variable is referred to implicity in the ADD_xxx macros. */

    ims = current_state->ims;

    /* A negative offset is a special case meaning "hold off going to this
    (negated) state until the number of characters in the data field have
    been skipped". */

    if (state_offset < 0)
      {
      if (current_state->data > 0)
        {
        DPRINTF(("%.*sSkipping this character\n", rlevel*2-2, SP));
        ADD_NEW_DATA(state_offset, current_state->count,
          current_state->data - 1);
        continue;
        }
      else
        {
        current_state->offset = state_offset = -state_offset;
        }
      }

    /* Check for a duplicate state with the same count, and skip if found. */

    for (j = 0; j < i; j++)
      {
      if (active_states[j].offset == state_offset &&
          active_states[j].count == current_state->count)
        {
        DPRINTF(("%.*sDuplicate state: skipped\n", rlevel*2-2, SP));
        goto NEXT_ACTIVE_STATE;
        }
      }

    /* The state offset is the offset to the opcode */

    code = start_code + state_offset;
    codevalue = *code;
    if (codevalue >= OP_BRA) codevalue = OP_BRA; /* All brackets are equal */

    /* If this opcode is followed by an inline character, load it. It is
    tempting to test for the presence of a subject character here, but that
    is wrong, because sometimes zero repetitions of the subject are
    permitted.

    We also use this mechanism for opcodes such as OP_TYPEPLUS that take an
    argument that is not a data character - but is always one byte long.
    Unfortunately, we have to take special action to deal with  \P, \p, and
    \X in this case. To keep the other cases fast, convert these ones to new
    opcodes. */

    if (coptable[codevalue] > 0)
      {
      dlen = 1;
#ifdef SUPPORT_UTF8
      if (utf8) { GETCHARLEN(d, (code + coptable[codevalue]), dlen); } else
#endif  /* SUPPORT_UTF8 */
      d = code[coptable[codevalue]];
      if (codevalue >= OP_TYPESTAR)
        {
        if (d == OP_ANYBYTE) return PCRE_ERROR_DFA_UITEM;
        if (d >= OP_NOTPROP)
          codevalue += (d == OP_EXTUNI)? OP_EXTUNI_EXTRA : OP_PROP_EXTRA;
        }
      }
    else
      {
      dlen = 0;         /* Not strictly necessary, but compilers moan */
      d = -1;           /* if these variables are not set. */
      }


    /* Now process the individual opcodes */

    switch (codevalue)
      {

/* ========================================================================== */
      /* Reached a closing bracket. If not at the end of the pattern, carry
      on with the next opcode. Otherwise, unless we have an empty string and
      PCRE_NOTEMPTY is set, save the match data, shifting up all previous
      matches so we always have the longest first. */

      case OP_KET:
      case OP_KETRMIN:
      case OP_KETRMAX:
      if (code != end_code)
        {
        ADD_ACTIVE(state_offset + 1 + LINK_SIZE, 0);
        if (codevalue != OP_KET)
          {
          ADD_ACTIVE(state_offset - GET(code, 1), 0);
          }
        }
      else if (ptr > current_subject || (md->moptions & PCRE_NOTEMPTY) == 0)
        {
        if (match_count < 0) match_count = (offsetcount >= 2)? 1 : 0;
          else if (match_count > 0 && ++match_count * 2 >= offsetcount)
            match_count = 0;
        count = ((match_count == 0)? offsetcount : match_count * 2) - 2;
        if (count > 0) memmove(offsets + 2, offsets, count * sizeof(int));
        if (offsetcount >= 2)
          {
          offsets[0] = current_subject - start_subject;
          offsets[1] = ptr - start_subject;
          DPRINTF(("%.*sSet matched string = \"%.*s\"\n", rlevel*2-2, SP,
            offsets[1] - offsets[0], current_subject));
          }
        if ((md->moptions & PCRE_DFA_SHORTEST) != 0)
          {
          DPRINTF(("%.*sEnd of internal_dfa_exec %d: returning %d\n"
            "%.*s---------------------\n\n", rlevel*2-2, SP, rlevel,
            match_count, rlevel*2-2, SP));
          return match_count;
          }
        }
      break;

/* ========================================================================== */
      /* These opcodes add to the current list of states without looking
      at the current character. */

      /*-----------------------------------------------------------------*/
      case OP_ALT:
      do { code += GET(code, 1); } while (*code == OP_ALT);
      ADD_ACTIVE(code - start_code, 0);
      break;

      /*-----------------------------------------------------------------*/
      case OP_BRA:
      do
        {
        ADD_ACTIVE(code - start_code + 1 + LINK_SIZE, 0);
        code += GET(code, 1);
        }
      while (*code == OP_ALT);
      break;

      /*-----------------------------------------------------------------*/
      case OP_BRAZERO:
      case OP_BRAMINZERO:
      ADD_ACTIVE(state_offset + 1, 0);
      code += 1 + GET(code, 2);
      while (*code == OP_ALT) code += GET(code, 1);
      ADD_ACTIVE(code - start_code + 1 + LINK_SIZE, 0);
      break;

      /*-----------------------------------------------------------------*/
      case OP_BRANUMBER:
      ADD_ACTIVE(state_offset + 1 + LINK_SIZE, 0);
      break;

      /*-----------------------------------------------------------------*/
      case OP_CIRC:
      if ((ptr == start_subject && (md->moptions & PCRE_NOTBOL) == 0) ||
          ((ims & PCRE_MULTILINE) != 0 && ptr[-1] == NEWLINE))
        { ADD_ACTIVE(state_offset + 1, 0); }
      break;

      /*-----------------------------------------------------------------*/
      case OP_EOD:
      if (ptr >= end_subject) { ADD_ACTIVE(state_offset + 1, 0); }
      break;

      /*-----------------------------------------------------------------*/
      case OP_OPT:
      ims = code[1];
      ADD_ACTIVE(state_offset + 2, 0);
      break;

      /*-----------------------------------------------------------------*/
      case OP_SOD:
      if (ptr == start_subject) { ADD_ACTIVE(state_offset + 1, 0); }
      break;

      /*-----------------------------------------------------------------*/
      case OP_SOM:
      if (ptr == start_subject + start_offset) { ADD_ACTIVE(state_offset + 1, 0); }
      break;


/* ========================================================================== */
      /* These opcodes inspect the next subject character, and sometimes
      the previous one as well, but do not have an argument. The variable
      clen contains the length of the current character and is zero if we are
      at the end of the subject. */

      /*-----------------------------------------------------------------*/
      case OP_ANY:
      if (clen > 0 && (c != NEWLINE || (ims & PCRE_DOTALL) != 0))
        { ADD_NEW(state_offset + 1, 0); }
      break;

      /*-----------------------------------------------------------------*/
      case OP_EODN:
      if (clen == 0 || (c == NEWLINE && ptr + 1 == end_subject))
        { ADD_ACTIVE(state_offset + 1, 0); }
      break;

      /*-----------------------------------------------------------------*/
      case OP_DOLL:
      if ((md->moptions & PCRE_NOTEOL) == 0)
        {
        if (clen == 0 || (c == NEWLINE && (ptr + 1 == end_subject ||
                                (ims & PCRE_MULTILINE) != 0)))
          { ADD_ACTIVE(state_offset + 1, 0); }
        }
      else if (c == NEWLINE && (ims & PCRE_MULTILINE) != 0)
        { ADD_ACTIVE(state_offset + 1, 0); }
      break;

      /*-----------------------------------------------------------------*/

      case OP_DIGIT:
      case OP_WHITESPACE:
      case OP_WORDCHAR:
      if (clen > 0 && c < 256 &&
            ((ctypes[c] & toptable1[codevalue]) ^ toptable2[codevalue]) != 0)
        { ADD_NEW(state_offset + 1, 0); }
      break;

      /*-----------------------------------------------------------------*/
      case OP_NOT_DIGIT:
      case OP_NOT_WHITESPACE:
      case OP_NOT_WORDCHAR:
      if (clen > 0 && (c >= 256 ||
            ((ctypes[c] & toptable1[codevalue]) ^ toptable2[codevalue]) != 0))
        { ADD_NEW(state_offset + 1, 0); }
      break;

      /*-----------------------------------------------------------------*/
      case OP_WORD_BOUNDARY:
      case OP_NOT_WORD_BOUNDARY:
        {
        int left_word, right_word;

        if (ptr > start_subject)
          {
          const uschar *temp = ptr - 1;
#ifdef SUPPORT_UTF8
          if (utf8) BACKCHAR(temp);
#endif
          GETCHARTEST(d, temp);
          left_word = d < 256 && (ctypes[d] & ctype_word) != 0;
          }
        else left_word = 0;

        if (clen > 0) right_word = c < 256 && (ctypes[c] & ctype_word) != 0;
          else right_word = 0;

        if ((left_word == right_word) == (codevalue == OP_NOT_WORD_BOUNDARY))
          { ADD_ACTIVE(state_offset + 1, 0); }
        }
      break;


#ifdef SUPPORT_UCP

      /*-----------------------------------------------------------------*/
      /* Check the next character by Unicode property. We will get here only
      if the support is in the binary; otherwise a compile-time error occurs.
      */

      case OP_PROP:
      case OP_NOTPROP:
      if (clen > 0)
        {
        int rqdtype, category;
        category = ucp_findchar(c, &chartype, &othercase);
        rqdtype = code[1];
        if (rqdtype >= 128)
          {
          if ((rqdtype - 128 == category) == (codevalue == OP_PROP))
            { ADD_NEW(state_offset + 2, 0); }
          }
        else
          {
          if ((rqdtype == chartype) == (codevalue == OP_PROP))
            { ADD_NEW(state_offset + 2, 0); }
          }
        }
      break;
#endif



/* ========================================================================== */
      /* These opcodes likewise inspect the subject character, but have an
      argument that is not a data character. It is one of these opcodes:
      OP_ANY, OP_DIGIT, OP_NOT_DIGIT, OP_WHITESPACE, OP_NOT_SPACE, OP_WORDCHAR,
      OP_NOT_WORDCHAR. The value is loaded into d. */

      case OP_TYPEPLUS:
      case OP_TYPEMINPLUS:
      count = current_state->count;  /* Already matched */
      if (count > 0) { ADD_ACTIVE(state_offset + 2, 0); }
      if (clen > 0)
        {
        if ((c >= 256 && d != OP_DIGIT && d != OP_WHITESPACE && d != OP_WORDCHAR) ||
            (c < 256 &&
              (d != OP_ANY || c != '\n' || (ims & PCRE_DOTALL) != 0) &&
              ((ctypes[c] & toptable1[d]) ^ toptable2[d]) != 0))
          {
          count++;
          ADD_NEW(state_offset, count);
          }
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_TYPEQUERY:
      case OP_TYPEMINQUERY:
      ADD_ACTIVE(state_offset + 2, 0);
      if (clen > 0)
        {
        if ((c >= 256 && d != OP_DIGIT && d != OP_WHITESPACE && d != OP_WORDCHAR) ||
            (c < 256 &&
              (d != OP_ANY || c != '\n' || (ims & PCRE_DOTALL) != 0) &&
              ((ctypes[c] & toptable1[d]) ^ toptable2[d]) != 0))
          {
          ADD_NEW(state_offset + 2, 0);
          }
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_TYPESTAR:
      case OP_TYPEMINSTAR:
      ADD_ACTIVE(state_offset + 2, 0);
      if (clen > 0)
        {
        if ((c >= 256 && d != OP_DIGIT && d != OP_WHITESPACE && d != OP_WORDCHAR) ||
            (c < 256 &&
              (d != OP_ANY || c != '\n' || (ims & PCRE_DOTALL) != 0) &&
              ((ctypes[c] & toptable1[d]) ^ toptable2[d]) != 0))
          {
          ADD_NEW(state_offset, 0);
          }
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_TYPEEXACT:
      case OP_TYPEUPTO:
      case OP_TYPEMINUPTO:
      if (codevalue != OP_TYPEEXACT)
        { ADD_ACTIVE(state_offset + 4, 0); }
      count = current_state->count;  /* Number already matched */
      if (clen > 0)
        {
        if ((c >= 256 && d != OP_DIGIT && d != OP_WHITESPACE && d != OP_WORDCHAR) ||
            (c < 256 &&
              (d != OP_ANY || c != '\n' || (ims & PCRE_DOTALL) != 0) &&
              ((ctypes[c] & toptable1[d]) ^ toptable2[d]) != 0))
          {
          if (++count >= GET2(code, 1))
            { ADD_NEW(state_offset + 4, 0); }
          else
            { ADD_NEW(state_offset, count); }
          }
        }
      break;

/* ========================================================================== */
      /* These are virtual opcodes that are used when something like
      OP_TYPEPLUS has OP_PROP, OP_NOTPROP, or OP_EXTUNI as its argument. It
      keeps the code above fast for the other cases. The argument is in the
      d variable. */

      case OP_PROP_EXTRA + OP_TYPEPLUS:
      case OP_PROP_EXTRA + OP_TYPEMINPLUS:
      count = current_state->count;           /* Already matched */
      if (count > 0) { ADD_ACTIVE(state_offset + 3, 0); }
      if (clen > 0)
        {
        int category = ucp_findchar(c, &chartype, &othercase);
        int rqdtype = code[2];
        if ((d == OP_PROP) ==
            (rqdtype == ((rqdtype >= 128)? (category + 128) : chartype)))
          { count++; ADD_NEW(state_offset, count); }
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_EXTUNI_EXTRA + OP_TYPEPLUS:
      case OP_EXTUNI_EXTRA + OP_TYPEMINPLUS:
      count = current_state->count;  /* Already matched */
      if (count > 0) { ADD_ACTIVE(state_offset + 2, 0); }
      if (clen > 0 && ucp_findchar(c, &chartype, &othercase) != ucp_M)
        {
        const uschar *nptr = ptr + clen;
        int ncount = 0;
        while (nptr < end_subject)
          {
          int nd;
          int ndlen = 1;
          GETCHARLEN(nd, nptr, ndlen);
          if (ucp_findchar(nd, &chartype, &othercase) != ucp_M) break;
          ncount++;
          nptr += ndlen;
          }
        count++;
        ADD_NEW_DATA(-state_offset, count, ncount);
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_PROP_EXTRA + OP_TYPEQUERY:
      case OP_PROP_EXTRA + OP_TYPEMINQUERY:
      count = 3;
      goto QS1;

      case OP_PROP_EXTRA + OP_TYPESTAR:
      case OP_PROP_EXTRA + OP_TYPEMINSTAR:
      count = 0;

      QS1:

      ADD_ACTIVE(state_offset + 3, 0);
      if (clen > 0)
        {
        int category = ucp_findchar(c, &chartype, &othercase);
        int rqdtype = code[2];
        if ((d == OP_PROP) ==
            (rqdtype == ((rqdtype >= 128)? (category + 128) : chartype)))
          { ADD_NEW(state_offset + count, 0); }
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_EXTUNI_EXTRA + OP_TYPEQUERY:
      case OP_EXTUNI_EXTRA + OP_TYPEMINQUERY:
      count = 2;
      goto QS2;

      case OP_EXTUNI_EXTRA + OP_TYPESTAR:
      case OP_EXTUNI_EXTRA + OP_TYPEMINSTAR:
      count = 0;

      QS2:

      ADD_ACTIVE(state_offset + 2, 0);
      if (clen > 0 && ucp_findchar(c, &chartype, &othercase) != ucp_M)
        {
        const uschar *nptr = ptr + clen;
        int ncount = 0;
        while (nptr < end_subject)
          {
          int nd;
          int ndlen = 1;
          GETCHARLEN(nd, nptr, ndlen);
          if (ucp_findchar(nd, &chartype, &othercase) != ucp_M) break;
          ncount++;
          nptr += ndlen;
          }
        ADD_NEW_DATA(-(state_offset + count), 0, ncount);
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_PROP_EXTRA + OP_TYPEEXACT:
      case OP_PROP_EXTRA + OP_TYPEUPTO:
      case OP_PROP_EXTRA + OP_TYPEMINUPTO:
      if (codevalue != OP_PROP_EXTRA + OP_TYPEEXACT)
        { ADD_ACTIVE(state_offset + 5, 0); }
      count = current_state->count;  /* Number already matched */
      if (clen > 0)
        {
        int category = ucp_findchar(c, &chartype, &othercase);
        int rqdtype = code[4];
        if ((d == OP_PROP) ==
            (rqdtype == ((rqdtype >= 128)? (category + 128) : chartype)))
          {
          if (++count >= GET2(code, 1))
            { ADD_NEW(state_offset + 5, 0); }
          else
            { ADD_NEW(state_offset, count); }
          }
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_EXTUNI_EXTRA + OP_TYPEEXACT:
      case OP_EXTUNI_EXTRA + OP_TYPEUPTO:
      case OP_EXTUNI_EXTRA + OP_TYPEMINUPTO:
      if (codevalue != OP_EXTUNI_EXTRA + OP_TYPEEXACT)
        { ADD_ACTIVE(state_offset + 4, 0); }
      count = current_state->count;  /* Number already matched */
      if (clen > 0 && ucp_findchar(c, &chartype, &othercase) != ucp_M)
        {
        const uschar *nptr = ptr + clen;
        int ncount = 0;
        while (nptr < end_subject)
          {
          int nd;
          int ndlen = 1;
          GETCHARLEN(nd, nptr, ndlen);
          if (ucp_findchar(nd, &chartype, &othercase) != ucp_M) break;
          ncount++;
          nptr += ndlen;
          }
        if (++count >= GET2(code, 1))
          { ADD_NEW_DATA(-(state_offset + 4), 0, ncount); }
        else
          { ADD_NEW_DATA(-state_offset, count, ncount); }
        }
      break;

/* ========================================================================== */
      /* These opcodes are followed by a character that is usually compared
      to the current subject character; it is loaded into d. We still get
      here even if there is no subject character, because in some cases zero
      repetitions are permitted. */

      /*-----------------------------------------------------------------*/
      case OP_CHAR:
      if (clen > 0 && c == d) { ADD_NEW(state_offset + dlen + 1, 0); }
      break;

      /*-----------------------------------------------------------------*/
      case OP_CHARNC:
      if (clen == 0) break;

#ifdef SUPPORT_UTF8
      if (utf8)
        {
        if (c == d) { ADD_NEW(state_offset + dlen + 1, 0); } else
          {
          if (c < 128) othercase = fcc[c]; else

          /* If we have Unicode property support, we can use it to test the
          other case of the character, if there is one. The result of
          ucp_findchar() is < 0 if the char isn't found, and othercase is
          returned as zero if there isn't another case. */

#ifdef SUPPORT_UCP
          if (ucp_findchar(c, &chartype, &othercase) < 0)
#endif
            othercase = -1;

          if (d == othercase) { ADD_NEW(state_offset + dlen + 1, 0); }
          }
        }
      else
#endif  /* SUPPORT_UTF8 */

      /* Non-UTF-8 mode */
        {
        if (lcc[c] == lcc[d]) { ADD_NEW(state_offset + 2, 0); }
        }
      break;


#ifdef SUPPORT_UCP
      /*-----------------------------------------------------------------*/
      /* This is a tricky one because it can match more than one character.
      Find out how many characters to skip, and then set up a negative state
      to wait for them to pass before continuing. */

      case OP_EXTUNI:
      if (clen > 0 && ucp_findchar(c, &chartype, &othercase) != ucp_M)
        {
        const uschar *nptr = ptr + clen;
        int ncount = 0;
        while (nptr < end_subject)
          {
          int nclen = 1;
          GETCHARLEN(c, nptr, nclen);
          if (ucp_findchar(c, &chartype, &othercase) != ucp_M) break;
          ncount++;
          nptr += nclen;
          }
        ADD_NEW_DATA(-(state_offset + 1), 0, ncount);
        }
      break;
#endif

      /*-----------------------------------------------------------------*/
      /* Match a negated single character. This is only used for one-byte
      characters, that is, we know that d < 256. The character we are
      checking (c) can be multibyte. */

      case OP_NOT:
      if (clen > 0)
        {
        int otherd = ((ims & PCRE_CASELESS) != 0)? fcc[d] : d;
        if (c != d && c != otherd) { ADD_NEW(state_offset + dlen + 1, 0); }
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_PLUS:
      case OP_MINPLUS:
      case OP_NOTPLUS:
      case OP_NOTMINPLUS:
      count = current_state->count;  /* Already matched */
      if (count > 0) { ADD_ACTIVE(state_offset + dlen + 1, 0); }
      if (clen > 0)
        {
        int otherd = -1;
        if ((ims & PCRE_CASELESS) != 0)
          {
#ifdef SUPPORT_UTF8
          if (utf8 && c >= 128)
            {
#ifdef SUPPORT_UCP
            if (ucp_findchar(d, &chartype, &otherd) < 0) otherd = -1;
#endif  /* SUPPORT_UCP */
            }
          else
#endif  /* SUPPORT_UTF8 */
          otherd = fcc[d];
          }
        if ((c == d || c == otherd) == (codevalue < OP_NOTSTAR))
          { count++; ADD_NEW(state_offset, count); }
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_QUERY:
      case OP_MINQUERY:
      case OP_NOTQUERY:
      case OP_NOTMINQUERY:
      ADD_ACTIVE(state_offset + dlen + 1, 0);
      if (clen > 0)
        {
        int otherd = -1;
        if ((ims && PCRE_CASELESS) != 0)
          {
#ifdef SUPPORT_UTF8
          if (utf8 && c >= 128)
            {
#ifdef SUPPORT_UCP
            if (ucp_findchar(c, &chartype, &otherd) < 0) otherd = -1;
#endif  /* SUPPORT_UCP */
            }
          else
#endif  /* SUPPORT_UTF8 */
          otherd = fcc[d];
          }
        if ((c == d || c == otherd) == (codevalue < OP_NOTSTAR))
          { ADD_NEW(state_offset + dlen + 1, 0); }
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_STAR:
      case OP_MINSTAR:
      case OP_NOTSTAR:
      case OP_NOTMINSTAR:
      ADD_ACTIVE(state_offset + dlen + 1, 0);
      if (clen > 0)
        {
        int otherd = -1;
        if ((ims && PCRE_CASELESS) != 0)
          {
#ifdef SUPPORT_UTF8
          if (utf8 && c >= 128)
            {
#ifdef SUPPORT_UCP
            if (ucp_findchar(c, &chartype, &otherd) < 0) otherd = -1;
#endif  /* SUPPORT_UCP */
            }
          else
#endif  /* SUPPORT_UTF8 */
          otherd = fcc[d];
          }
        if ((c == d || c == otherd) == (codevalue < OP_NOTSTAR))
          { ADD_NEW(state_offset, 0); }
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_EXACT:
      case OP_UPTO:
      case OP_MINUPTO:
      case OP_NOTEXACT:
      case OP_NOTUPTO:
      case OP_NOTMINUPTO:
      if (codevalue != OP_EXACT && codevalue != OP_NOTEXACT)
        { ADD_ACTIVE(state_offset + dlen + 3, 0); }
      count = current_state->count;  /* Number already matched */
      if (clen > 0)
        {
        int otherd = -1;
        if ((ims & PCRE_CASELESS) != 0)
          {
#ifdef SUPPORT_UTF8
          if (utf8 && c >= 128)
            {
#ifdef SUPPORT_UCP
            if (ucp_findchar(d, &chartype, &otherd) < 0) otherd = -1;
#endif  /* SUPPORT_UCP */
            }
          else
#endif  /* SUPPORT_UTF8 */
          otherd = fcc[d];
          }
        if ((c == d || c == otherd) == (codevalue < OP_NOTSTAR))
          {
          if (++count >= GET2(code, 1))
            { ADD_NEW(state_offset + dlen + 3, 0); }
          else
            { ADD_NEW(state_offset, count); }
          }
        }
      break;


/* ========================================================================== */
      /* These are the class-handling opcodes */

      case OP_CLASS:
      case OP_NCLASS:
      case OP_XCLASS:
        {
        BOOL isinclass = FALSE;
        int next_state_offset;
        const uschar *ecode;

        /* For a simple class, there is always just a 32-byte table, and we
        can set isinclass from it. */

        if (codevalue != OP_XCLASS)
          {
          ecode = code + 33;
          if (clen > 0)
            {
            isinclass = (c > 255)? (codevalue == OP_NCLASS) :
              ((code[1 + c/8] & (1 << (c&7))) != 0);
            }
          }

        /* An extended class may have a table or a list of single characters,
        ranges, or both, and it may be positive or negative. There's a
        function that sorts all this out. */

        else
         {
         ecode = code + GET(code, 1);
         if (clen > 0) isinclass = _pcre_xclass(c, code + 1 + LINK_SIZE);
         }

        /* At this point, isinclass is set for all kinds of class, and ecode
        points to the byte after the end of the class. If there is a
        quantifier, this is where it will be. */

        next_state_offset = ecode - start_code;

        switch (*ecode)
          {
          case OP_CRSTAR:
          case OP_CRMINSTAR:
          ADD_ACTIVE(next_state_offset + 1, 0);
          if (isinclass) { ADD_NEW(state_offset, 0); }
          break;

          case OP_CRPLUS:
          case OP_CRMINPLUS:
          count = current_state->count;  /* Already matched */
          if (count > 0) { ADD_ACTIVE(next_state_offset + 1, 0); }
          if (isinclass) { count++; ADD_NEW(state_offset, count); }
          break;

          case OP_CRQUERY:
          case OP_CRMINQUERY:
          ADD_ACTIVE(next_state_offset + 1, 0);
          if (isinclass) { ADD_NEW(next_state_offset + 1, 0); }
          break;

          case OP_CRRANGE:
          case OP_CRMINRANGE:
          count = current_state->count;  /* Already matched */
          if (count >= GET2(ecode, 1))
            { ADD_ACTIVE(next_state_offset + 5, 0); }
          if (isinclass)
            {
            if (++count >= GET2(ecode, 3))
              { ADD_NEW(next_state_offset + 5, 0); }
            else
              { ADD_NEW(state_offset, count); }
            }
          break;

          default:
          if (isinclass) { ADD_NEW(next_state_offset, 0); }
          break;
          }
        }
      break;

/* ========================================================================== */
      /* These are the opcodes for fancy brackets of various kinds. We have
      to use recursion in order to handle them. */

      case OP_ASSERT:
      case OP_ASSERT_NOT:
      case OP_ASSERTBACK:
      case OP_ASSERTBACK_NOT:
        {
        int rc;
        int local_offsets[2];
        int local_workspace[1000];
        const uschar *endasscode = code + GET(code, 1);

        while (*endasscode == OP_ALT) endasscode += GET(endasscode, 1);

        rc = internal_dfa_exec(
          md,                                   /* static match data */
          code,                                 /* this subexpression's code */
          ptr,                                  /* where we currently are */
          ptr - start_subject,                  /* start offset */
          local_offsets,                        /* offset vector */
          sizeof(local_offsets)/sizeof(int),    /* size of same */
          local_workspace,                      /* workspace vector */
          sizeof(local_workspace)/sizeof(int),  /* size of same */
          ims,                                  /* the current ims flags */
          rlevel,                               /* function recursion level */
          recursing);                           /* pass on regex recursion */

        if ((rc >= 0) == (codevalue == OP_ASSERT || codevalue == OP_ASSERTBACK))
            { ADD_ACTIVE(endasscode + LINK_SIZE + 1 - start_code, 0); }
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_COND:
        {
        int local_offsets[1000];
        int local_workspace[1000];
        int condcode = code[LINK_SIZE+1];

        /* The only supported version of OP_CREF is for the value 0xffff, which
        means "test if in a recursion". */

        if (condcode == OP_CREF)
          {
          int value = GET2(code, LINK_SIZE+2);
          if (value != 0xffff) return PCRE_ERROR_DFA_UCOND;
          if (recursing > 0) { ADD_ACTIVE(state_offset + LINK_SIZE + 4, 0); }
            else { ADD_ACTIVE(state_offset + GET(code, 1) + LINK_SIZE + 1, 0); }
          }

        /* Otherwise, the condition is an assertion */

        else
          {
          int rc;
          const uschar *asscode = code + LINK_SIZE + 1;
          const uschar *endasscode = asscode + GET(asscode, 1);

          while (*endasscode == OP_ALT) endasscode += GET(endasscode, 1);

          rc = internal_dfa_exec(
            md,                                   /* fixed match data */
            asscode,                              /* this subexpression's code */
            ptr,                                  /* where we currently are */
            ptr - start_subject,                  /* start offset */
            local_offsets,                        /* offset vector */
            sizeof(local_offsets)/sizeof(int),    /* size of same */
            local_workspace,                      /* workspace vector */
            sizeof(local_workspace)/sizeof(int),  /* size of same */
            ims,                                  /* the current ims flags */
            rlevel,                               /* function recursion level */
            recursing);                           /* pass on regex recursion */

          if ((rc >= 0) ==
                (condcode == OP_ASSERT || condcode == OP_ASSERTBACK))
            { ADD_ACTIVE(endasscode + LINK_SIZE + 1 - start_code, 0); }
          else
            { ADD_ACTIVE(state_offset + GET(code, 1) + LINK_SIZE + 1, 0); }
          }
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_RECURSE:
        {
        int local_offsets[1000];
        int local_workspace[1000];
        int rc;

        DPRINTF(("%.*sStarting regex recursion %d\n", rlevel*2-2, SP,
          recursing + 1));

        rc = internal_dfa_exec(
          md,                                   /* fixed match data */
          start_code + GET(code, 1),            /* this subexpression's code */
          ptr,                                  /* where we currently are */
          ptr - start_subject,                  /* start offset */
          local_offsets,                        /* offset vector */
          sizeof(local_offsets)/sizeof(int),    /* size of same */
          local_workspace,                      /* workspace vector */
          sizeof(local_workspace)/sizeof(int),  /* size of same */
          ims,                                  /* the current ims flags */
          rlevel,                               /* function recursion level */
          recursing + 1);                       /* regex recurse level */

        DPRINTF(("%.*sReturn from regex recursion %d: rc=%d\n", rlevel*2-2, SP,
          recursing + 1, rc));

        /* Ran out of internal offsets */

        if (rc == 0) return PCRE_ERROR_DFA_RECURSE;

        /* For each successful matched substring, set up the next state with a
        count of characters to skip before trying it. Note that the count is in
        characters, not bytes. */

        if (rc > 0)
          {
          for (rc = rc*2 - 2; rc >= 0; rc -= 2)
            {
            const uschar *p = start_subject + local_offsets[rc];
            const uschar *pp = start_subject + local_offsets[rc+1];
            int charcount = local_offsets[rc+1] - local_offsets[rc];
            while (p < pp) if ((*p++ & 0xc0) == 0x80) charcount--;
            if (charcount > 0)
              {
              ADD_NEW_DATA(-(state_offset + LINK_SIZE + 1), 0, (charcount - 1));
              }
            else
              {
              ADD_ACTIVE(state_offset + LINK_SIZE + 1, 0);
              }
            }
          }
        else if (rc != PCRE_ERROR_NOMATCH) return rc;
        }
      break;

      /*-----------------------------------------------------------------*/
      case OP_ONCE:
        {
        const uschar *endcode;
        int local_offsets[2];
        int local_workspace[1000];

        int rc = internal_dfa_exec(
          md,                                   /* fixed match data */
          code,                                 /* this subexpression's code */
          ptr,                                  /* where we currently are */
          ptr - start_subject,                  /* start offset */
          local_offsets,                        /* offset vector */
          sizeof(local_offsets)/sizeof(int),    /* size of same */
          local_workspace,                      /* workspace vector */
          sizeof(local_workspace)/sizeof(int),  /* size of same */
          ims,                                  /* the current ims flags */
          rlevel,                               /* function recursion level */
          recursing);                           /* pass on regex recursion */

        if (rc >= 0)
          {
          const uschar *end_subpattern = code;
          int charcount = local_offsets[1] - local_offsets[0];
          int next_state_offset, repeat_state_offset;
          BOOL is_repeated;

          do { end_subpattern += GET(end_subpattern, 1); }
            while (*end_subpattern == OP_ALT);
          next_state_offset = end_subpattern - start_code + LINK_SIZE + 1;

          /* If the end of this subpattern is KETRMAX or KETRMIN, we must
          arrange for the repeat state also to be added to the relevant list.
          Calculate the offset, or set -1 for no repeat. */

          repeat_state_offset = (*end_subpattern == OP_KETRMAX ||
                                 *end_subpattern == OP_KETRMIN)?
            end_subpattern - start_code - GET(end_subpattern, 1) : -1;

          /* If we have matched an empty string, add the next state at the
          current character pointer. This is important so that the duplicate
          checking kicks in, which is what breaks infinite loops that match an
          empty string. */

          if (charcount == 0)
            {
            ADD_ACTIVE(next_state_offset, 0);
            }

          /* Optimization: if there are no more active states, and there
          are no new states yet set up, then skip over the subject string
          right here, to save looping. Otherwise, set up the new state to swing
          into action when the end of the substring is reached. */

          else if (i + 1 >= active_count && new_count == 0)
            {
            ptr += charcount;
            clen = 0;
            ADD_NEW(next_state_offset, 0);

            /* If we are adding a repeat state at the new character position,
            we must fudge things so that it is the only current state.
            Otherwise, it might be a duplicate of one we processed before, and
            that would cause it to be skipped. */

            if (repeat_state_offset >= 0)
              {
              next_active_state = active_states;
              active_count = 0;
              i = -1;
              ADD_ACTIVE(repeat_state_offset, 0);
              }
            }
          else
            {
            const uschar *p = start_subject + local_offsets[0];
            const uschar *pp = start_subject + local_offsets[1];
            while (p < pp) if ((*p++ & 0xc0) == 0x80) charcount--;
            ADD_NEW_DATA(-next_state_offset, 0, (charcount - 1));
            if (repeat_state_offset >= 0)
              { ADD_NEW_DATA(-repeat_state_offset, 0, (charcount - 1)); }
            }

          }
        else if (rc != PCRE_ERROR_NOMATCH) return rc;
        }
      break;


/* ========================================================================== */
      /* Handle callouts */

      case OP_CALLOUT:
      if (pcre_callout != NULL)
        {
        int rrc;
        pcre_callout_block cb;
        cb.version          = 1;   /* Version 1 of the callout block */
        cb.callout_number   = code[1];
        cb.offset_vector    = offsets;
        cb.subject          = (char *)start_subject;
        cb.subject_length   = end_subject - start_subject;
        cb.start_match      = current_subject - start_subject;
        cb.current_position = ptr - start_subject;
        cb.pattern_position = GET(code, 2);
        cb.next_item_length = GET(code, 2 + LINK_SIZE);
        cb.capture_top      = 1;
        cb.capture_last     = -1;
        cb.callout_data     = md->callout_data;
        if ((rrc = (*pcre_callout)(&cb)) < 0) return rrc;   /* Abandon */
        if (rrc == 0) { ADD_ACTIVE(state_offset + 2 + 2*LINK_SIZE, 0); }
        }
      break;


/* ========================================================================== */
      default:        /* Unsupported opcode */
      return PCRE_ERROR_DFA_UITEM;
      }

    NEXT_ACTIVE_STATE: continue;

    }      /* End of loop scanning active states */

  /* We have finished the processing at the current subject character. If no
  new states have been set for the next character, we have found all the
  matches that we are going to find. If we are at the top level and partial
  matching has been requested, check for appropriate conditions. */

  if (new_count <= 0)
    {
    if (match_count < 0 &&                     /* No matches found */
        rlevel == 1 &&                         /* Top level match function */
        (md->moptions & PCRE_PARTIAL) != 0 &&  /* Want partial matching */
        ptr >= end_subject &&                  /* Reached end of subject */
        ptr > current_subject)                 /* Matched non-empty string */
      {
      if (offsetcount >= 2)
        {
        offsets[0] = current_subject - start_subject;
        offsets[1] = end_subject - start_subject;
        }
      match_count = PCRE_ERROR_PARTIAL;
      }

    DPRINTF(("%.*sEnd of internal_dfa_exec %d: returning %d\n"
      "%.*s---------------------\n\n", rlevel*2-2, SP, rlevel, match_count,
      rlevel*2-2, SP));
    return match_count;
    }

  /* One or more states are active for the next character. */

  ptr += clen;    /* Advance to next subject character */
  }               /* Loop to move along the subject string */

/* Control never gets here, but we must keep the compiler happy. */

DPRINTF(("%.*s+++ Unexpected end of internal_dfa_exec %d +++\n"
  "%.*s---------------------\n\n", rlevel*2-2, SP, rlevel, rlevel*2-2, SP));
return PCRE_ERROR_NOMATCH;
}




/*************************************************
*    Execute a Regular Expression - DFA engine   *
*************************************************/

/* This external function applies a compiled re to a subject string using a DFA
engine. This function calls the internal function multiple times if the pattern
is not anchored.

Arguments:
  argument_re     points to the compiled expression
  extra_data      points to extra data or is NULL (not currently used)
  subject         points to the subject string
  length          length of subject string (may contain binary zeros)
  start_offset    where to start in the subject string
  options         option bits
  offsets         vector of match offsets
  offsetcount     size of same
  workspace       workspace vector
  wscount         size of same

Returns:          > 0 => number of match offset pairs placed in offsets
                  = 0 => offsets overflowed; longest matches are present
                   -1 => failed to match
                 < -1 => some kind of unexpected problem
*/

EXPORT int
pcre_dfa_exec(const pcre *argument_re, const pcre_extra *extra_data,
  const char *subject, int length, int start_offset, int options, int *offsets,
  int offsetcount, int *workspace, int wscount)
{
real_pcre *re = (real_pcre *)argument_re;
dfa_match_data match_block;
BOOL utf8, anchored, startline, firstline;
const uschar *current_subject, *end_subject, *lcc;

pcre_study_data internal_study;
const pcre_study_data *study = NULL;
real_pcre internal_re;

const uschar *req_byte_ptr;
const uschar *start_bits = NULL;
BOOL first_byte_caseless = FALSE;
BOOL req_byte_caseless = FALSE;
int first_byte = -1;
int req_byte = -1;
int req_byte2 = -1;

/* Plausibility checks */

if ((options & ~PUBLIC_DFA_EXEC_OPTIONS) != 0) return PCRE_ERROR_BADOPTION;
if (re == NULL || subject == NULL || workspace == NULL ||
   (offsets == NULL && offsetcount > 0)) return PCRE_ERROR_NULL;
if (offsetcount < 0) return PCRE_ERROR_BADCOUNT;
if (wscount < 20) return PCRE_ERROR_DFA_WSSIZE;

/* We need to find the pointer to any study data before we test for byte
flipping, so we scan the extra_data block first. This may set two fields in the
match block, so we must initialize them beforehand. However, the other fields
in the match block must not be set until after the byte flipping. */

match_block.tables = re->tables;
match_block.callout_data = NULL;

if (extra_data != NULL)
  {
  unsigned int flags = extra_data->flags;
  if ((flags & PCRE_EXTRA_STUDY_DATA) != 0)
    study = (const pcre_study_data *)extra_data->study_data;
  if ((flags & PCRE_EXTRA_MATCH_LIMIT) != 0) return PCRE_ERROR_DFA_UMLIMIT;
  if ((flags & PCRE_EXTRA_CALLOUT_DATA) != 0)
    match_block.callout_data = extra_data->callout_data;
  if ((flags & PCRE_EXTRA_TABLES) != 0)
    match_block.tables = extra_data->tables;
  }

/* Check that the first field in the block is the magic number. If it is not,
test for a regex that was compiled on a host of opposite endianness. If this is
the case, flipped values are put in internal_re and internal_study if there was
study data too. */

if (re->magic_number != MAGIC_NUMBER)
  {
  re = _pcre_try_flipped(re, &internal_re, study, &internal_study);
  if (re == NULL) return PCRE_ERROR_BADMAGIC;
  if (study != NULL) study = &internal_study;
  }

/* Set some local values */

current_subject = (const unsigned char *)subject + start_offset;
end_subject = (const unsigned char *)subject + length;
req_byte_ptr = current_subject - 1;

utf8 = (re->options & PCRE_UTF8) != 0;
anchored = (options & PCRE_ANCHORED) != 0 || (re->options & PCRE_ANCHORED) != 0;

/* The remaining fixed data for passing around. */

match_block.start_code = (const uschar *)argument_re +
    re->name_table_offset + re->name_count * re->name_entry_size;
match_block.start_subject = (const unsigned char *)subject;
match_block.end_subject = end_subject;
match_block.moptions = options;
match_block.poptions = re->options;

/* Check a UTF-8 string if required. Unfortunately there's no way of passing
back the character offset. */

#ifdef SUPPORT_UTF8
if (utf8 && (options & PCRE_NO_UTF8_CHECK) == 0)
  {
  if (_pcre_valid_utf8((uschar *)subject, length) >= 0)
    return PCRE_ERROR_BADUTF8;
  if (start_offset > 0 && start_offset < length)
    {
    int tb = ((uschar *)subject)[start_offset];
    if (tb > 127)
      {
      tb &= 0xc0;
      if (tb != 0 && tb != 0xc0) return PCRE_ERROR_BADUTF8_OFFSET;
      }
    }
  }
#endif

/* If the exec call supplied NULL for tables, use the inbuilt ones. This
is a feature that makes it possible to save compiled regex and re-use them
in other programs later. */

if (match_block.tables == NULL) match_block.tables = _pcre_default_tables;

/* The lower casing table and the "must be at the start of a line" flag are
used in a loop when finding where to start. */

lcc = match_block.tables + lcc_offset;
startline = (re->options & PCRE_STARTLINE) != 0;
firstline = (re->options & PCRE_FIRSTLINE) != 0;

/* Set up the first character to match, if available. The first_byte value is
never set for an anchored regular expression, but the anchoring may be forced
at run time, so we have to test for anchoring. The first char may be unset for
an unanchored pattern, of course. If there's no first char and the pattern was
studied, there may be a bitmap of possible first characters. */

if (!anchored)
  {
  if ((re->options & PCRE_FIRSTSET) != 0)
    {
    first_byte = re->first_byte & 255;
    if ((first_byte_caseless = ((re->first_byte & REQ_CASELESS) != 0)) == TRUE)
      first_byte = lcc[first_byte];
    }
  else
    {
    if (startline && study != NULL &&
         (study->options & PCRE_STUDY_MAPPED) != 0)
      start_bits = study->start_bits;
    }
  }

/* For anchored or unanchored matches, there may be a "last known required
character" set. */

if ((re->options & PCRE_REQCHSET) != 0)
  {
  req_byte = re->req_byte & 255;
  req_byte_caseless = (re->req_byte & REQ_CASELESS) != 0;
  req_byte2 = (match_block.tables + fcc_offset)[req_byte];  /* case flipped */
  }

/* Call the main matching function, looping for a non-anchored regex after a
failed match. Unless restarting, optimize by moving to the first match
character if possible, when not anchored. Then unless wanting a partial match,
check for a required later character. */

for (;;)
  {
  int rc;

  if ((options & PCRE_DFA_RESTART) == 0)
    {
    const uschar *save_end_subject = end_subject;

    /* Advance to a unique first char if possible. If firstline is TRUE, the
    start of the match is constrained to the first line of a multiline string.
    Implement this by temporarily adjusting end_subject so that we stop scanning
    at a newline. If the match fails at the newline, later code breaks this loop.
    */

    if (firstline)
      {
      const uschar *t = current_subject;
      while (t < save_end_subject && *t != '\n') t++;
      end_subject = t;
      }

    if (first_byte >= 0)
      {
      if (first_byte_caseless)
        while (current_subject < end_subject &&
               lcc[*current_subject] != first_byte)
          current_subject++;
      else
        while (current_subject < end_subject && *current_subject != first_byte)
          current_subject++;
      }

    /* Or to just after \n for a multiline match if possible */

    else if (startline)
      {
      if (current_subject > match_block.start_subject + start_offset)
        {
        while (current_subject < end_subject && current_subject[-1] != NEWLINE)
          current_subject++;
        }
      }

    /* Or to a non-unique first char after study */

    else if (start_bits != NULL)
      {
      while (current_subject < end_subject)
        {
        register unsigned int c = *current_subject;
        if ((start_bits[c/8] & (1 << (c&7))) == 0) current_subject++;
          else break;
        }
      }

    /* Restore fudged end_subject */

    end_subject = save_end_subject;
    }

  /* If req_byte is set, we know that that character must appear in the subject
  for the match to succeed. If the first character is set, req_byte must be
  later in the subject; otherwise the test starts at the match point. This
  optimization can save a huge amount of work in patterns with nested unlimited
  repeats that aren't going to match. Writing separate code for cased/caseless
  versions makes it go faster, as does using an autoincrement and backing off
  on a match.

  HOWEVER: when the subject string is very, very long, searching to its end can
  take a long time, and give bad performance on quite ordinary patterns. This
  showed up when somebody was matching /^C/ on a 32-megabyte string... so we
  don't do this when the string is sufficiently long.

  ALSO: this processing is disabled when partial matching is requested.
  */

  if (req_byte >= 0 &&
      end_subject - current_subject < REQ_BYTE_MAX &&
      (options & PCRE_PARTIAL) == 0)
    {
    register const uschar *p = current_subject + ((first_byte >= 0)? 1 : 0);

    /* We don't need to repeat the search if we haven't yet reached the
    place we found it at last time. */

    if (p > req_byte_ptr)
      {
      if (req_byte_caseless)
        {
        while (p < end_subject)
          {
          register int pp = *p++;
          if (pp == req_byte || pp == req_byte2) { p--; break; }
          }
        }
      else
        {
        while (p < end_subject)
          {
          if (*p++ == req_byte) { p--; break; }
          }
        }

      /* If we can't find the required character, break the matching loop,
      which will cause a return or PCRE_ERROR_NOMATCH. */

      if (p >= end_subject) break;

      /* If we have found the required character, save the point where we
      found it, so that we don't search again next time round the loop if
      the start hasn't passed this character yet. */

      req_byte_ptr = p;
      }
    }

  /* OK, now we can do the business */

  rc = internal_dfa_exec(
    &match_block,                              /* fixed match data */
    match_block.start_code,                    /* this subexpression's code */
    current_subject,                           /* where we currently are */
    start_offset,                              /* start offset in subject */
    offsets,                                   /* offset vector */
    offsetcount,                               /* size of same */
    workspace,                                 /* workspace vector */
    wscount,                                   /* size of same */
    re->options & (PCRE_CASELESS|PCRE_MULTILINE|PCRE_DOTALL), /* ims flags */
    0,                                         /* function recurse level */
    0);                                        /* regex recurse level */

  /* Anything other than "no match" means we are done, always; otherwise, carry
  on only if not anchored. */

  if (rc != PCRE_ERROR_NOMATCH || anchored) return rc;

  /* Advance to the next subject character unless we are at the end of a line
  and firstline is set. */

  if (firstline && *current_subject == NEWLINE) break;
  current_subject++;

#ifdef SUPPORT_UTF8
  if (utf8)
    {
    while (current_subject < end_subject && (*current_subject & 0xc0) == 0x80)
      current_subject++;
    }
#endif

  if (current_subject > end_subject) break;
  }

return PCRE_ERROR_NOMATCH;
}

/* End of pcre_dfa_exec.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains pcre_exec(), the externally visible function that does
pattern matching using an NFA algorithm, trying to mimic Perl as closely as
possible. There are also some static supporting functions. */




/* Structure for building a chain of data that actually lives on the
stack, for holding the values of the subject pointer at the start of each
subpattern, so as to detect when an empty string has been matched by a
subpattern - to break infinite loops. When NO_RECURSE is set, these blocks
are on the heap, not on the stack. */

typedef struct eptrblock {
  struct eptrblock *epb_prev;
  const uschar *epb_saved_eptr;
} eptrblock;

/* Flag bits for the match() function */

#define match_condassert   0x01    /* Called to check a condition assertion */
#define match_isgroup      0x02    /* Set if start of bracketed group */

/* Non-error returns from the match() function. Error returns are externally
defined PCRE_ERROR_xxx codes, which are all negative. */

#define MATCH_MATCH        1
#define MATCH_NOMATCH      0

/* Maximum number of ints of offset to save on the stack for recursive calls.
If the offset vector is bigger, malloc is used. This should be a multiple of 3,
because the offset vector is always a multiple of 3 long. */

#define REC_STACK_SAVE_MAX 30

/* Min and max values for the common repeats; for the maxima, 0 => infinity */

static const char rep_min[] = { 0, 0, 1, 1, 0, 0 };
static const char rep_max[] = { 0, 0, 0, 0, 1, 1 };



#ifdef DEBUG
/*************************************************
*        Debugging function to print chars       *
*************************************************/

/* Print a sequence of chars in printable format, stopping at the end of the
subject if the requested.

Arguments:
  p           points to characters
  length      number to print
  is_subject  TRUE if printing from within md->start_subject
  md          pointer to matching data block, if is_subject is TRUE

Returns:     nothing
*/

static void
pchars(const uschar *p, int length, BOOL is_subject, match_data *md)
{
int c;
if (is_subject && length > md->end_subject - p) length = md->end_subject - p;
while (length-- > 0)
  if (isprint(c = *(p++))) printf("%c", c); else printf("\\x%02x", c);
}
#endif



/*************************************************
*          Match a back-reference                *
*************************************************/

/* If a back reference hasn't been set, the length that is passed is greater
than the number of characters left in the string, so the match fails.

Arguments:
  offset      index into the offset vector
  eptr        points into the subject
  length      length to be matched
  md          points to match data block
  ims         the ims flags

Returns:      TRUE if matched
*/

static BOOL
match_ref(int offset, register const uschar *eptr, int length, match_data *md,
  unsigned long int ims)
{
const uschar *p = md->start_subject + md->offset_vector[offset];

#ifdef DEBUG
if (eptr >= md->end_subject)
  printf("matching subject <null>");
else
  {
  printf("matching subject ");
  pchars(eptr, length, TRUE, md);
  }
printf(" against backref ");
pchars(p, length, FALSE, md);
printf("\n");
#endif

/* Always fail if not enough characters left */

if (length > md->end_subject - eptr) return FALSE;

/* Separate the caselesss case for speed */

if ((ims & PCRE_CASELESS) != 0)
  {
  while (length-- > 0)
    if (md->lcc[*p++] != md->lcc[*eptr++]) return FALSE;
  }
else
  { while (length-- > 0) if (*p++ != *eptr++) return FALSE; }

return TRUE;
}



/***************************************************************************
****************************************************************************
                   RECURSION IN THE match() FUNCTION

The match() function is highly recursive. Some regular expressions can cause
it to recurse thousands of times. I was writing for Unix, so I just let it
call itself recursively. This uses the stack for saving everything that has
to be saved for a recursive call. On Unix, the stack can be large, and this
works fine.

It turns out that on non-Unix systems there are problems with programs that
use a lot of stack. (This despite the fact that every last chip has oodles
of memory these days, and techniques for extending the stack have been known
for decades.) So....

There is a fudge, triggered by defining NO_RECURSE, which avoids recursive
calls by keeping local variables that need to be preserved in blocks of memory
obtained from malloc instead instead of on the stack. Macros are used to
achieve this so that the actual code doesn't look very different to what it
always used to.
****************************************************************************
***************************************************************************/


/* These versions of the macros use the stack, as normal */

#ifndef NO_RECURSE
#define REGISTER register
#define RMATCH(rx,ra,rb,rc,rd,re,rf,rg) rx = match(ra,rb,rc,rd,re,rf,rg)
#define RRETURN(ra) return ra
#else


/* These versions of the macros manage a private stack on the heap. Note
that the rd argument of RMATCH isn't actually used. It's the md argument of
match(), which never changes. */

#define REGISTER

#define RMATCH(rx,ra,rb,rc,rd,re,rf,rg)\
  {\
  heapframe *newframe = (pcre_stack_malloc)(sizeof(heapframe));\
  if (setjmp(frame->Xwhere) == 0)\
    {\
    newframe->Xeptr = ra;\
    newframe->Xecode = rb;\
    newframe->Xoffset_top = rc;\
    newframe->Xims = re;\
    newframe->Xeptrb = rf;\
    newframe->Xflags = rg;\
    newframe->Xprevframe = frame;\
    frame = newframe;\
    DPRINTF(("restarting from line %d\n", __LINE__));\
    goto HEAP_RECURSE;\
    }\
  else\
    {\
    DPRINTF(("longjumped back to line %d\n", __LINE__));\
    frame = md->thisframe;\
    rx = frame->Xresult;\
    }\
  }

#define RRETURN(ra)\
  {\
  heapframe *newframe = frame;\
  frame = newframe->Xprevframe;\
  (pcre_stack_free)(newframe);\
  if (frame != NULL)\
    {\
    frame->Xresult = ra;\
    md->thisframe = frame;\
    longjmp(frame->Xwhere, 1);\
    }\
  return ra;\
  }


/* Structure for remembering the local variables in a private frame */

typedef struct heapframe {
  struct heapframe *Xprevframe;

  /* Function arguments that may change */

  const uschar *Xeptr;
  const uschar *Xecode;
  int Xoffset_top;
  long int Xims;
  eptrblock *Xeptrb;
  int Xflags;

  /* Function local variables */

  const uschar *Xcallpat;
  const uschar *Xcharptr;
  const uschar *Xdata;
  const uschar *Xnext;
  const uschar *Xpp;
  const uschar *Xprev;
  const uschar *Xsaved_eptr;

  recursion_info Xnew_recursive;

  BOOL Xcur_is_word;
  BOOL Xcondition;
  BOOL Xminimize;
  BOOL Xprev_is_word;

  unsigned long int Xoriginal_ims;

#ifdef SUPPORT_UCP
  int Xprop_type;
  int Xprop_fail_result;
  int Xprop_category;
  int Xprop_chartype;
  int Xprop_othercase;
  int Xprop_test_against;
  int *Xprop_test_variable;
#endif

  int Xctype;
  int Xfc;
  int Xfi;
  int Xlength;
  int Xmax;
  int Xmin;
  int Xnumber;
  int Xoffset;
  int Xop;
  int Xsave_capture_last;
  int Xsave_offset1, Xsave_offset2, Xsave_offset3;
  int Xstacksave[REC_STACK_SAVE_MAX];

  eptrblock Xnewptrb;

  /* Place to pass back result, and where to jump back to */

  int  Xresult;
  jmp_buf Xwhere;

} heapframe;

#endif


/***************************************************************************
***************************************************************************/



/*************************************************
*         Match from current position            *
*************************************************/

/* On entry ecode points to the first opcode, and eptr to the first character
in the subject string, while eptrb holds the value of eptr at the start of the
last bracketed group - used for breaking infinite loops matching zero-length
strings. This function is called recursively in many circumstances. Whenever it
returns a negative (error) response, the outer incarnation must also return the
same response.

Performance note: It might be tempting to extract commonly used fields from the
md structure (e.g. utf8, end_subject) into individual variables to improve
performance. Tests using gcc on a SPARC disproved this; in the first case, it
made performance worse.

Arguments:
   eptr        pointer in subject
   ecode       position in code
   offset_top  current top pointer
   md          pointer to "static" info for the match
   ims         current /i, /m, and /s options
   eptrb       pointer to chain of blocks containing eptr at start of
                 brackets - for testing for empty matches
   flags       can contain
                 match_condassert - this is an assertion condition
                 match_isgroup - this is the start of a bracketed group

Returns:       MATCH_MATCH if matched            )  these values are >= 0
               MATCH_NOMATCH if failed to match  )
               a negative PCRE_ERROR_xxx value if aborted by an error condition
                 (e.g. stopped by recursion limit)
*/

static int
match(REGISTER const uschar *eptr, REGISTER const uschar *ecode,
  int offset_top, match_data *md, unsigned long int ims, eptrblock *eptrb,
  int flags)
{
/* These variables do not need to be preserved over recursion in this function,
so they can be ordinary variables in all cases. Mark them with "register"
because they are used a lot in loops. */

register int  rrc;    /* Returns from recursive calls */
register int  i;      /* Used for loops not involving calls to RMATCH() */
register int  c;      /* Character values not kept over RMATCH() calls */
register BOOL utf8;   /* Local copy of UTF-8 flag for speed */

/* When recursion is not being used, all "local" variables that have to be
preserved over calls to RMATCH() are part of a "frame" which is obtained from
heap storage. Set up the top-level frame here; others are obtained from the
heap whenever RMATCH() does a "recursion". See the macro definitions above. */

#ifdef NO_RECURSE
heapframe *frame = (pcre_stack_malloc)(sizeof(heapframe));
frame->Xprevframe = NULL;            /* Marks the top level */

/* Copy in the original argument variables */

frame->Xeptr = eptr;
frame->Xecode = ecode;
frame->Xoffset_top = offset_top;
frame->Xims = ims;
frame->Xeptrb = eptrb;
frame->Xflags = flags;

/* This is where control jumps back to to effect "recursion" */

HEAP_RECURSE:

/* Macros make the argument variables come from the current frame */

#define eptr               frame->Xeptr
#define ecode              frame->Xecode
#define offset_top         frame->Xoffset_top
#define ims                frame->Xims
#define eptrb              frame->Xeptrb
#define flags              frame->Xflags

/* Ditto for the local variables */

#ifdef SUPPORT_UTF8
#define charptr            frame->Xcharptr
#endif
#define callpat            frame->Xcallpat
#define data               frame->Xdata
#define next               frame->Xnext
#define pp                 frame->Xpp
#define prev               frame->Xprev
#define saved_eptr         frame->Xsaved_eptr

#define new_recursive      frame->Xnew_recursive

#define cur_is_word        frame->Xcur_is_word
#define condition          frame->Xcondition
#define minimize           frame->Xminimize
#define prev_is_word       frame->Xprev_is_word

#define original_ims       frame->Xoriginal_ims

#ifdef SUPPORT_UCP
#define prop_type          frame->Xprop_type
#define prop_fail_result   frame->Xprop_fail_result
#define prop_category      frame->Xprop_category
#define prop_chartype      frame->Xprop_chartype
#define prop_othercase     frame->Xprop_othercase
#define prop_test_against  frame->Xprop_test_against
#define prop_test_variable frame->Xprop_test_variable
#endif

#define ctype              frame->Xctype
#define fc                 frame->Xfc
#define fi                 frame->Xfi
#define length             frame->Xlength
#define max                frame->Xmax
#define min                frame->Xmin
#define number             frame->Xnumber
#define offset             frame->Xoffset
#define op                 frame->Xop
#define save_capture_last  frame->Xsave_capture_last
#define save_offset1       frame->Xsave_offset1
#define save_offset2       frame->Xsave_offset2
#define save_offset3       frame->Xsave_offset3
#define stacksave          frame->Xstacksave

#define newptrb            frame->Xnewptrb

/* When recursion is being used, local variables are allocated on the stack and
get preserved during recursion in the normal way. In this environment, fi and
i, and fc and c, can be the same variables. */

#else
#define fi i
#define fc c


#ifdef SUPPORT_UTF8                /* Many of these variables are used ony */
const uschar *charptr;             /* small blocks of the code. My normal  */
#endif                             /* style of coding would have declared  */
const uschar *callpat;             /* them within each of those blocks.    */
const uschar *data;                /* However, in order to accommodate the */
const uschar *next;                /* version of this code that uses an    */
const uschar *pp;                  /* external "stack" implemented on the  */
const uschar *prev;                /* heap, it is easier to declare them   */
const uschar *saved_eptr;          /* all here, so the declarations can    */
                                   /* be cut out in a block. The only      */
recursion_info new_recursive;      /* declarations within blocks below are */
                                   /* for variables that do not have to    */
BOOL cur_is_word;                  /* be preserved over a recursive call   */
BOOL condition;                    /* to RMATCH().                         */
BOOL minimize;
BOOL prev_is_word;

unsigned long int original_ims;

#ifdef SUPPORT_UCP
int prop_type;
int prop_fail_result;
int prop_category;
int prop_chartype;
int prop_othercase;
int prop_test_against;
int *prop_test_variable;
#endif

int ctype;
int length;
int max;
int min;
int number;
int offset;
int op;
int save_capture_last;
int save_offset1, save_offset2, save_offset3;
int stacksave[REC_STACK_SAVE_MAX];

eptrblock newptrb;
#endif

/* These statements are here to stop the compiler complaining about unitialized
variables. */

#ifdef SUPPORT_UCP
prop_fail_result = 0;
prop_test_against = 0;
prop_test_variable = NULL;
#endif

/* OK, now we can get on with the real code of the function. Recursion is
specified by the macros RMATCH and RRETURN. When NO_RECURSE is *not* defined,
these just turn into a recursive call to match() and a "return", respectively.
However, RMATCH isn't like a function call because it's quite a complicated
macro. It has to be used in one particular way. This shouldn't, however, impact
performance when true recursion is being used. */

if (md->match_call_count++ >= md->match_limit) RRETURN(PCRE_ERROR_MATCHLIMIT);

original_ims = ims;    /* Save for resetting on ')' */
utf8 = md->utf8;       /* Local copy of the flag */

/* At the start of a bracketed group, add the current subject pointer to the
stack of such pointers, to be re-instated at the end of the group when we hit
the closing ket. When match() is called in other circumstances, we don't add to
this stack. */

if ((flags & match_isgroup) != 0)
  {
  newptrb.epb_prev = eptrb;
  newptrb.epb_saved_eptr = eptr;
  eptrb = &newptrb;
  }

/* Now start processing the operations. */

for (;;)
  {
  op = *ecode;
  minimize = FALSE;

  /* For partial matching, remember if we ever hit the end of the subject after
  matching at least one subject character. */

  if (md->partial &&
      eptr >= md->end_subject &&
      eptr > md->start_match)
    md->hitend = TRUE;

  /* Opening capturing bracket. If there is space in the offset vector, save
  the current subject position in the working slot at the top of the vector. We
  mustn't change the current values of the data slot, because they may be set
  from a previous iteration of this group, and be referred to by a reference
  inside the group.

  If the bracket fails to match, we need to restore this value and also the
  values of the final offsets, in case they were set by a previous iteration of
  the same bracket.

  If there isn't enough space in the offset vector, treat this as if it were a
  non-capturing bracket. Don't worry about setting the flag for the error case
  here; that is handled in the code for KET. */

  if (op > OP_BRA)
    {
    number = op - OP_BRA;

    /* For extended extraction brackets (large number), we have to fish out the
    number from a dummy opcode at the start. */

    if (number > EXTRACT_BASIC_MAX)
      number = GET2(ecode, 2+LINK_SIZE);
    offset = number << 1;

#ifdef DEBUG
    printf("start bracket %d subject=", number);
    pchars(eptr, 16, TRUE, md);
    printf("\n");
#endif

    if (offset < md->offset_max)
      {
      save_offset1 = md->offset_vector[offset];
      save_offset2 = md->offset_vector[offset+1];
      save_offset3 = md->offset_vector[md->offset_end - number];
      save_capture_last = md->capture_last;

      DPRINTF(("saving %d %d %d\n", save_offset1, save_offset2, save_offset3));
      md->offset_vector[md->offset_end - number] = eptr - md->start_subject;

      do
        {
        RMATCH(rrc, eptr, ecode + 1 + LINK_SIZE, offset_top, md, ims, eptrb,
          match_isgroup);
        if (rrc != MATCH_NOMATCH) RRETURN(rrc);
        md->capture_last = save_capture_last;
        ecode += GET(ecode, 1);
        }
      while (*ecode == OP_ALT);

      DPRINTF(("bracket %d failed\n", number));

      md->offset_vector[offset] = save_offset1;
      md->offset_vector[offset+1] = save_offset2;
      md->offset_vector[md->offset_end - number] = save_offset3;

      RRETURN(MATCH_NOMATCH);
      }

    /* Insufficient room for saving captured contents */

    else op = OP_BRA;
    }

  /* Other types of node can be handled by a switch */

  switch(op)
    {
    case OP_BRA:     /* Non-capturing bracket: optimized */
    DPRINTF(("start bracket 0\n"));
    do
      {
      RMATCH(rrc, eptr, ecode + 1 + LINK_SIZE, offset_top, md, ims, eptrb,
        match_isgroup);
      if (rrc != MATCH_NOMATCH) RRETURN(rrc);
      ecode += GET(ecode, 1);
      }
    while (*ecode == OP_ALT);
    DPRINTF(("bracket 0 failed\n"));
    RRETURN(MATCH_NOMATCH);

    /* Conditional group: compilation checked that there are no more than
    two branches. If the condition is false, skipping the first branch takes us
    past the end if there is only one branch, but that's OK because that is
    exactly what going to the ket would do. */

    case OP_COND:
    if (ecode[LINK_SIZE+1] == OP_CREF) /* Condition extract or recurse test */
      {
      offset = GET2(ecode, LINK_SIZE+2) << 1;  /* Doubled ref number */
      condition = (offset == CREF_RECURSE * 2)?
        (md->recursive != NULL) :
        (offset < offset_top && md->offset_vector[offset] >= 0);
      RMATCH(rrc, eptr, ecode + (condition?
        (LINK_SIZE + 4) : (LINK_SIZE + 1 + GET(ecode, 1))),
        offset_top, md, ims, eptrb, match_isgroup);
      RRETURN(rrc);
      }

    /* The condition is an assertion. Call match() to evaluate it - setting
    the final argument TRUE causes it to stop at the end of an assertion. */

    else
      {
      RMATCH(rrc, eptr, ecode + 1 + LINK_SIZE, offset_top, md, ims, NULL,
          match_condassert | match_isgroup);
      if (rrc == MATCH_MATCH)
        {
        ecode += 1 + LINK_SIZE + GET(ecode, LINK_SIZE+2);
        while (*ecode == OP_ALT) ecode += GET(ecode, 1);
        }
      else if (rrc != MATCH_NOMATCH)
        {
        RRETURN(rrc);         /* Need braces because of following else */
        }
      else ecode += GET(ecode, 1);
      RMATCH(rrc, eptr, ecode + 1 + LINK_SIZE, offset_top, md, ims, eptrb,
        match_isgroup);
      RRETURN(rrc);
      }
    /* Control never reaches here */

    /* Skip over conditional reference or large extraction number data if
    encountered. */

    case OP_CREF:
    case OP_BRANUMBER:
    ecode += 3;
    break;

    /* End of the pattern. If we are in a recursion, we should restore the
    offsets appropriately and continue from after the call. */

    case OP_END:
    if (md->recursive != NULL && md->recursive->group_num == 0)
      {
      recursion_info *rec = md->recursive;
      DPRINTF(("Hit the end in a (?0) recursion\n"));
      md->recursive = rec->prevrec;
      memmove(md->offset_vector, rec->offset_save,
        rec->saved_max * sizeof(int));
      md->start_match = rec->save_start;
      ims = original_ims;
      ecode = rec->after_call;
      break;
      }

    /* Otherwise, if PCRE_NOTEMPTY is set, fail if we have matched an empty
    string - backtracking will then try other alternatives, if any. */

    if (md->notempty && eptr == md->start_match) RRETURN(MATCH_NOMATCH);
    md->end_match_ptr = eptr;          /* Record where we ended */
    md->end_offset_top = offset_top;   /* and how many extracts were taken */
    RRETURN(MATCH_MATCH);

    /* Change option settings */

    case OP_OPT:
    ims = ecode[1];
    ecode += 2;
    DPRINTF(("ims set to %02lx\n", ims));
    break;

    /* Assertion brackets. Check the alternative branches in turn - the
    matching won't pass the KET for an assertion. If any one branch matches,
    the assertion is true. Lookbehind assertions have an OP_REVERSE item at the
    start of each branch to move the current point backwards, so the code at
    this level is identical to the lookahead case. */

    case OP_ASSERT:
    case OP_ASSERTBACK:
    do
      {
      RMATCH(rrc, eptr, ecode + 1 + LINK_SIZE, offset_top, md, ims, NULL,
        match_isgroup);
      if (rrc == MATCH_MATCH) break;
      if (rrc != MATCH_NOMATCH) RRETURN(rrc);
      ecode += GET(ecode, 1);
      }
    while (*ecode == OP_ALT);
    if (*ecode == OP_KET) RRETURN(MATCH_NOMATCH);

    /* If checking an assertion for a condition, return MATCH_MATCH. */

    if ((flags & match_condassert) != 0) RRETURN(MATCH_MATCH);

    /* Continue from after the assertion, updating the offsets high water
    mark, since extracts may have been taken during the assertion. */

    do ecode += GET(ecode,1); while (*ecode == OP_ALT);
    ecode += 1 + LINK_SIZE;
    offset_top = md->end_offset_top;
    continue;

    /* Negative assertion: all branches must fail to match */

    case OP_ASSERT_NOT:
    case OP_ASSERTBACK_NOT:
    do
      {
      RMATCH(rrc, eptr, ecode + 1 + LINK_SIZE, offset_top, md, ims, NULL,
        match_isgroup);
      if (rrc == MATCH_MATCH) RRETURN(MATCH_NOMATCH);
      if (rrc != MATCH_NOMATCH) RRETURN(rrc);
      ecode += GET(ecode,1);
      }
    while (*ecode == OP_ALT);

    if ((flags & match_condassert) != 0) RRETURN(MATCH_MATCH);

    ecode += 1 + LINK_SIZE;
    continue;

    /* Move the subject pointer back. This occurs only at the start of
    each branch of a lookbehind assertion. If we are too close to the start to
    move back, this match function fails. When working with UTF-8 we move
    back a number of characters, not bytes. */

    case OP_REVERSE:
#ifdef SUPPORT_UTF8
    if (utf8)
      {
      c = GET(ecode,1);
      for (i = 0; i < c; i++)
        {
        eptr--;
        if (eptr < md->start_subject) RRETURN(MATCH_NOMATCH);
        BACKCHAR(eptr)
        }
      }
    else
#endif

    /* No UTF-8 support, or not in UTF-8 mode: count is byte count */

      {
      eptr -= GET(ecode,1);
      if (eptr < md->start_subject) RRETURN(MATCH_NOMATCH);
      }

    /* Skip to next op code */

    ecode += 1 + LINK_SIZE;
    break;

    /* The callout item calls an external function, if one is provided, passing
    details of the match so far. This is mainly for debugging, though the
    function is able to force a failure. */

    case OP_CALLOUT:
    if (pcre_callout != NULL)
      {
      pcre_callout_block cb;
      cb.version          = 1;   /* Version 1 of the callout block */
      cb.callout_number   = ecode[1];
      cb.offset_vector    = md->offset_vector;
      cb.subject          = (const char *)md->start_subject;
      cb.subject_length   = md->end_subject - md->start_subject;
      cb.start_match      = md->start_match - md->start_subject;
      cb.current_position = eptr - md->start_subject;
      cb.pattern_position = GET(ecode, 2);
      cb.next_item_length = GET(ecode, 2 + LINK_SIZE);
      cb.capture_top      = offset_top/2;
      cb.capture_last     = md->capture_last;
      cb.callout_data     = md->callout_data;
      if ((rrc = (*pcre_callout)(&cb)) > 0) RRETURN(MATCH_NOMATCH);
      if (rrc < 0) RRETURN(rrc);
      }
    ecode += 2 + 2*LINK_SIZE;
    break;

    /* Recursion either matches the current regex, or some subexpression. The
    offset data is the offset to the starting bracket from the start of the
    whole pattern. (This is so that it works from duplicated subpatterns.)

    If there are any capturing brackets started but not finished, we have to
    save their starting points and reinstate them after the recursion. However,
    we don't know how many such there are (offset_top records the completed
    total) so we just have to save all the potential data. There may be up to
    65535 such values, which is too large to put on the stack, but using malloc
    for small numbers seems expensive. As a compromise, the stack is used when
    there are no more than REC_STACK_SAVE_MAX values to store; otherwise malloc
    is used. A problem is what to do if the malloc fails ... there is no way of
    returning to the top level with an error. Save the top REC_STACK_SAVE_MAX
    values on the stack, and accept that the rest may be wrong.

    There are also other values that have to be saved. We use a chained
    sequence of blocks that actually live on the stack. Thanks to Robin Houston
    for the original version of this logic. */

    case OP_RECURSE:
      {
      callpat = md->start_code + GET(ecode, 1);
      new_recursive.group_num = *callpat - OP_BRA;

      /* For extended extraction brackets (large number), we have to fish out
      the number from a dummy opcode at the start. */

      if (new_recursive.group_num > EXTRACT_BASIC_MAX)
        new_recursive.group_num = GET2(callpat, 2+LINK_SIZE);

      /* Add to "recursing stack" */

      new_recursive.prevrec = md->recursive;
      md->recursive = &new_recursive;

      /* Find where to continue from afterwards */

      ecode += 1 + LINK_SIZE;
      new_recursive.after_call = ecode;

      /* Now save the offset data. */

      new_recursive.saved_max = md->offset_end;
      if (new_recursive.saved_max <= REC_STACK_SAVE_MAX)
        new_recursive.offset_save = stacksave;
      else
        {
        new_recursive.offset_save =
          (int *)(pcre_malloc)(new_recursive.saved_max * sizeof(int));
        if (new_recursive.offset_save == NULL) RRETURN(PCRE_ERROR_NOMEMORY);
        }

      memcpy(new_recursive.offset_save, md->offset_vector,
            new_recursive.saved_max * sizeof(int));
      new_recursive.save_start = md->start_match;
      md->start_match = eptr;

      /* OK, now we can do the recursion. For each top-level alternative we
      restore the offset and recursion data. */

      DPRINTF(("Recursing into group %d\n", new_recursive.group_num));
      do
        {
        RMATCH(rrc, eptr, callpat + 1 + LINK_SIZE, offset_top, md, ims,
            eptrb, match_isgroup);
        if (rrc == MATCH_MATCH)
          {
          md->recursive = new_recursive.prevrec;
          if (new_recursive.offset_save != stacksave)
            (pcre_free)(new_recursive.offset_save);
          RRETURN(MATCH_MATCH);
          }
        else if (rrc != MATCH_NOMATCH) RRETURN(rrc);

        md->recursive = &new_recursive;
        memcpy(md->offset_vector, new_recursive.offset_save,
            new_recursive.saved_max * sizeof(int));
        callpat += GET(callpat, 1);
        }
      while (*callpat == OP_ALT);

      DPRINTF(("Recursion didn't match\n"));
      md->recursive = new_recursive.prevrec;
      if (new_recursive.offset_save != stacksave)
        (pcre_free)(new_recursive.offset_save);
      RRETURN(MATCH_NOMATCH);
      }
    /* Control never reaches here */

    /* "Once" brackets are like assertion brackets except that after a match,
    the point in the subject string is not moved back. Thus there can never be
    a move back into the brackets. Friedl calls these "atomic" subpatterns.
    Check the alternative branches in turn - the matching won't pass the KET
    for this kind of subpattern. If any one branch matches, we carry on as at
    the end of a normal bracket, leaving the subject pointer. */

    case OP_ONCE:
      {
      prev = ecode;
      saved_eptr = eptr;

      do
        {
        RMATCH(rrc, eptr, ecode + 1 + LINK_SIZE, offset_top, md, ims,
          eptrb, match_isgroup);
        if (rrc == MATCH_MATCH) break;
        if (rrc != MATCH_NOMATCH) RRETURN(rrc);
        ecode += GET(ecode,1);
        }
      while (*ecode == OP_ALT);

      /* If hit the end of the group (which could be repeated), fail */

      if (*ecode != OP_ONCE && *ecode != OP_ALT) RRETURN(MATCH_NOMATCH);

      /* Continue as from after the assertion, updating the offsets high water
      mark, since extracts may have been taken. */

      do ecode += GET(ecode,1); while (*ecode == OP_ALT);

      offset_top = md->end_offset_top;
      eptr = md->end_match_ptr;

      /* For a non-repeating ket, just continue at this level. This also
      happens for a repeating ket if no characters were matched in the group.
      This is the forcible breaking of infinite loops as implemented in Perl
      5.005. If there is an options reset, it will get obeyed in the normal
      course of events. */

      if (*ecode == OP_KET || eptr == saved_eptr)
        {
        ecode += 1+LINK_SIZE;
        break;
        }

      /* The repeating kets try the rest of the pattern or restart from the
      preceding bracket, in the appropriate order. We need to reset any options
      that changed within the bracket before re-running it, so check the next
      opcode. */

      if (ecode[1+LINK_SIZE] == OP_OPT)
        {
        ims = (ims & ~PCRE_IMS) | ecode[4];
        DPRINTF(("ims set to %02lx at group repeat\n", ims));
        }

      if (*ecode == OP_KETRMIN)
        {
        RMATCH(rrc, eptr, ecode + 1 + LINK_SIZE, offset_top, md, ims, eptrb, 0);
        if (rrc != MATCH_NOMATCH) RRETURN(rrc);
        RMATCH(rrc, eptr, prev, offset_top, md, ims, eptrb, match_isgroup);
        if (rrc != MATCH_NOMATCH) RRETURN(rrc);
        }
      else  /* OP_KETRMAX */
        {
        RMATCH(rrc, eptr, prev, offset_top, md, ims, eptrb, match_isgroup);
        if (rrc != MATCH_NOMATCH) RRETURN(rrc);
        RMATCH(rrc, eptr, ecode + 1+LINK_SIZE, offset_top, md, ims, eptrb, 0);
        if (rrc != MATCH_NOMATCH) RRETURN(rrc);
        }
      }
    RRETURN(MATCH_NOMATCH);

    /* An alternation is the end of a branch; scan along to find the end of the
    bracketed group and go to there. */

    case OP_ALT:
    do ecode += GET(ecode,1); while (*ecode == OP_ALT);
    break;

    /* BRAZERO and BRAMINZERO occur just before a bracket group, indicating
    that it may occur zero times. It may repeat infinitely, or not at all -
    i.e. it could be ()* or ()? in the pattern. Brackets with fixed upper
    repeat limits are compiled as a number of copies, with the optional ones
    preceded by BRAZERO or BRAMINZERO. */

    case OP_BRAZERO:
      {
      next = ecode+1;
      RMATCH(rrc, eptr, next, offset_top, md, ims, eptrb, match_isgroup);
      if (rrc != MATCH_NOMATCH) RRETURN(rrc);
      do next += GET(next,1); while (*next == OP_ALT);
      ecode = next + 1+LINK_SIZE;
      }
    break;

    case OP_BRAMINZERO:
      {
      next = ecode+1;
      do next += GET(next,1); while (*next == OP_ALT);
      RMATCH(rrc, eptr, next + 1+LINK_SIZE, offset_top, md, ims, eptrb,
        match_isgroup);
      if (rrc != MATCH_NOMATCH) RRETURN(rrc);
      ecode++;
      }
    break;

    /* End of a group, repeated or non-repeating. If we are at the end of
    an assertion "group", stop matching and return MATCH_MATCH, but record the
    current high water mark for use by positive assertions. Do this also
    for the "once" (not-backup up) groups. */

    case OP_KET:
    case OP_KETRMIN:
    case OP_KETRMAX:
      {
      prev = ecode - GET(ecode, 1);
      saved_eptr = eptrb->epb_saved_eptr;

      /* Back up the stack of bracket start pointers. */

      eptrb = eptrb->epb_prev;

      if (*prev == OP_ASSERT || *prev == OP_ASSERT_NOT ||
          *prev == OP_ASSERTBACK || *prev == OP_ASSERTBACK_NOT ||
          *prev == OP_ONCE)
        {
        md->end_match_ptr = eptr;      /* For ONCE */
        md->end_offset_top = offset_top;
        RRETURN(MATCH_MATCH);
        }

      /* In all other cases except a conditional group we have to check the
      group number back at the start and if necessary complete handling an
      extraction by setting the offsets and bumping the high water mark. */

      if (*prev != OP_COND)
        {
        number = *prev - OP_BRA;

        /* For extended extraction brackets (large number), we have to fish out
        the number from a dummy opcode at the start. */

        if (number > EXTRACT_BASIC_MAX) number = GET2(prev, 2+LINK_SIZE);
        offset = number << 1;

#ifdef DEBUG
        printf("end bracket %d", number);
        printf("\n");
#endif

        /* Test for a numbered group. This includes groups called as a result
        of recursion. Note that whole-pattern recursion is coded as a recurse
        into group 0, so it won't be picked up here. Instead, we catch it when
        the OP_END is reached. */

        if (number > 0)
          {
          md->capture_last = number;
          if (offset >= md->offset_max) md->offset_overflow = TRUE; else
            {
            md->offset_vector[offset] =
              md->offset_vector[md->offset_end - number];
            md->offset_vector[offset+1] = eptr - md->start_subject;
            if (offset_top <= offset) offset_top = offset + 2;
            }

          /* Handle a recursively called group. Restore the offsets
          appropriately and continue from after the call. */

          if (md->recursive != NULL && md->recursive->group_num == number)
            {
            recursion_info *rec = md->recursive;
            DPRINTF(("Recursion (%d) succeeded - continuing\n", number));
            md->recursive = rec->prevrec;
            md->start_match = rec->save_start;
            memcpy(md->offset_vector, rec->offset_save,
              rec->saved_max * sizeof(int));
            ecode = rec->after_call;
            ims = original_ims;
            break;
            }
          }
        }

      /* Reset the value of the ims flags, in case they got changed during
      the group. */

      ims = original_ims;
      DPRINTF(("ims reset to %02lx\n", ims));

      /* For a non-repeating ket, just continue at this level. This also
      happens for a repeating ket if no characters were matched in the group.
      This is the forcible breaking of infinite loops as implemented in Perl
      5.005. If there is an options reset, it will get obeyed in the normal
      course of events. */

      if (*ecode == OP_KET || eptr == saved_eptr)
        {
        ecode += 1 + LINK_SIZE;
        break;
        }

      /* The repeating kets try the rest of the pattern or restart from the
      preceding bracket, in the appropriate order. */

      if (*ecode == OP_KETRMIN)
        {
        RMATCH(rrc, eptr, ecode + 1+LINK_SIZE, offset_top, md, ims, eptrb, 0);
        if (rrc != MATCH_NOMATCH) RRETURN(rrc);
        RMATCH(rrc, eptr, prev, offset_top, md, ims, eptrb, match_isgroup);
        if (rrc != MATCH_NOMATCH) RRETURN(rrc);
        }
      else  /* OP_KETRMAX */
        {
        RMATCH(rrc, eptr, prev, offset_top, md, ims, eptrb, match_isgroup);
        if (rrc != MATCH_NOMATCH) RRETURN(rrc);
        RMATCH(rrc, eptr, ecode + 1+LINK_SIZE, offset_top, md, ims, eptrb, 0);
        if (rrc != MATCH_NOMATCH) RRETURN(rrc);
        }
      }

    RRETURN(MATCH_NOMATCH);

    /* Start of subject unless notbol, or after internal newline if multiline */

    case OP_CIRC:
    if (md->notbol && eptr == md->start_subject) RRETURN(MATCH_NOMATCH);
    if ((ims & PCRE_MULTILINE) != 0)
      {
      if (eptr != md->start_subject && eptr[-1] != NEWLINE)
        RRETURN(MATCH_NOMATCH);
      ecode++;
      break;
      }
    /* ... else fall through */

    /* Start of subject assertion */

    case OP_SOD:
    if (eptr != md->start_subject) RRETURN(MATCH_NOMATCH);
    ecode++;
    break;

    /* Start of match assertion */

    case OP_SOM:
    if (eptr != md->start_subject + md->start_offset) RRETURN(MATCH_NOMATCH);
    ecode++;
    break;

    /* Assert before internal newline if multiline, or before a terminating
    newline unless endonly is set, else end of subject unless noteol is set. */

    case OP_DOLL:
    if ((ims & PCRE_MULTILINE) != 0)
      {
      if (eptr < md->end_subject)
        { if (*eptr != NEWLINE) RRETURN(MATCH_NOMATCH); }
      else
        { if (md->noteol) RRETURN(MATCH_NOMATCH); }
      ecode++;
      break;
      }
    else
      {
      if (md->noteol) RRETURN(MATCH_NOMATCH);
      if (!md->endonly)
        {
        if (eptr < md->end_subject - 1 ||
           (eptr == md->end_subject - 1 && *eptr != NEWLINE))
          RRETURN(MATCH_NOMATCH);
        ecode++;
        break;
        }
      }
    /* ... else fall through */

    /* End of subject assertion (\z) */

    case OP_EOD:
    if (eptr < md->end_subject) RRETURN(MATCH_NOMATCH);
    ecode++;
    break;

    /* End of subject or ending \n assertion (\Z) */

    case OP_EODN:
    if (eptr < md->end_subject - 1 ||
       (eptr == md->end_subject - 1 && *eptr != NEWLINE)) RRETURN(MATCH_NOMATCH);
    ecode++;
    break;

    /* Word boundary assertions */

    case OP_NOT_WORD_BOUNDARY:
    case OP_WORD_BOUNDARY:
      {

      /* Find out if the previous and current characters are "word" characters.
      It takes a bit more work in UTF-8 mode. Characters > 255 are assumed to
      be "non-word" characters. */

#ifdef SUPPORT_UTF8
      if (utf8)
        {
        if (eptr == md->start_subject) prev_is_word = FALSE; else
          {
          const uschar *lastptr = eptr - 1;
          while((*lastptr & 0xc0) == 0x80) lastptr--;
          GETCHAR(c, lastptr);
          prev_is_word = c < 256 && (md->ctypes[c] & ctype_word) != 0;
          }
        if (eptr >= md->end_subject) cur_is_word = FALSE; else
          {
          GETCHAR(c, eptr);
          cur_is_word = c < 256 && (md->ctypes[c] & ctype_word) != 0;
          }
        }
      else
#endif

      /* More streamlined when not in UTF-8 mode */

        {
        prev_is_word = (eptr != md->start_subject) &&
          ((md->ctypes[eptr[-1]] & ctype_word) != 0);
        cur_is_word = (eptr < md->end_subject) &&
          ((md->ctypes[*eptr] & ctype_word) != 0);
        }

      /* Now see if the situation is what we want */

      if ((*ecode++ == OP_WORD_BOUNDARY)?
           cur_is_word == prev_is_word : cur_is_word != prev_is_word)
        RRETURN(MATCH_NOMATCH);
      }
    break;

    /* Match a single character type; inline for speed */

    case OP_ANY:
    if ((ims & PCRE_DOTALL) == 0 && eptr < md->end_subject && *eptr == NEWLINE)
      RRETURN(MATCH_NOMATCH);
    if (eptr++ >= md->end_subject) RRETURN(MATCH_NOMATCH);
#ifdef SUPPORT_UTF8
    if (utf8)
      while (eptr < md->end_subject && (*eptr & 0xc0) == 0x80) eptr++;
#endif
    ecode++;
    break;

    /* Match a single byte, even in UTF-8 mode. This opcode really does match
    any byte, even newline, independent of the setting of PCRE_DOTALL. */

    case OP_ANYBYTE:
    if (eptr++ >= md->end_subject) RRETURN(MATCH_NOMATCH);
    ecode++;
    break;

    case OP_NOT_DIGIT:
    if (eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
    GETCHARINCTEST(c, eptr);
    if (
#ifdef SUPPORT_UTF8
       c < 256 &&
#endif
       (md->ctypes[c] & ctype_digit) != 0
       )
      RRETURN(MATCH_NOMATCH);
    ecode++;
    break;

    case OP_DIGIT:
    if (eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
    GETCHARINCTEST(c, eptr);
    if (
#ifdef SUPPORT_UTF8
       c >= 256 ||
#endif
       (md->ctypes[c] & ctype_digit) == 0
       )
      RRETURN(MATCH_NOMATCH);
    ecode++;
    break;

    case OP_NOT_WHITESPACE:
    if (eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
    GETCHARINCTEST(c, eptr);
    if (
#ifdef SUPPORT_UTF8
       c < 256 &&
#endif
       (md->ctypes[c] & ctype_space) != 0
       )
      RRETURN(MATCH_NOMATCH);
    ecode++;
    break;

    case OP_WHITESPACE:
    if (eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
    GETCHARINCTEST(c, eptr);
    if (
#ifdef SUPPORT_UTF8
       c >= 256 ||
#endif
       (md->ctypes[c] & ctype_space) == 0
       )
      RRETURN(MATCH_NOMATCH);
    ecode++;
    break;

    case OP_NOT_WORDCHAR:
    if (eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
    GETCHARINCTEST(c, eptr);
    if (
#ifdef SUPPORT_UTF8
       c < 256 &&
#endif
       (md->ctypes[c] & ctype_word) != 0
       )
      RRETURN(MATCH_NOMATCH);
    ecode++;
    break;

    case OP_WORDCHAR:
    if (eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
    GETCHARINCTEST(c, eptr);
    if (
#ifdef SUPPORT_UTF8
       c >= 256 ||
#endif
       (md->ctypes[c] & ctype_word) == 0
       )
      RRETURN(MATCH_NOMATCH);
    ecode++;
    break;

#ifdef SUPPORT_UCP
    /* Check the next character by Unicode property. We will get here only
    if the support is in the binary; otherwise a compile-time error occurs. */

    case OP_PROP:
    case OP_NOTPROP:
    if (eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
    GETCHARINCTEST(c, eptr);
      {
      int chartype, rqdtype;
      int othercase;
      int category = ucp_findchar(c, &chartype, &othercase);

      rqdtype = *(++ecode);
      ecode++;

      if (rqdtype >= 128)
        {
        if ((rqdtype - 128 != category) == (op == OP_PROP))
          RRETURN(MATCH_NOMATCH);
        }
      else
        {
        if ((rqdtype != chartype) == (op == OP_PROP))
          RRETURN(MATCH_NOMATCH);
        }
      }
    break;

    /* Match an extended Unicode sequence. We will get here only if the support
    is in the binary; otherwise a compile-time error occurs. */

    case OP_EXTUNI:
    if (eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
    GETCHARINCTEST(c, eptr);
      {
      int chartype;
      int othercase;
      int category = ucp_findchar(c, &chartype, &othercase);
      if (category == ucp_M) RRETURN(MATCH_NOMATCH);
      while (eptr < md->end_subject)
        {
        int len = 1;
        if (!utf8) c = *eptr; else
          {
          GETCHARLEN(c, eptr, len);
          }
        category = ucp_findchar(c, &chartype, &othercase);
        if (category != ucp_M) break;
        eptr += len;
        }
      }
    ecode++;
    break;
#endif


    /* Match a back reference, possibly repeatedly. Look past the end of the
    item to see if there is repeat information following. The code is similar
    to that for character classes, but repeated for efficiency. Then obey
    similar code to character type repeats - written out again for speed.
    However, if the referenced string is the empty string, always treat
    it as matched, any number of times (otherwise there could be infinite
    loops). */

    case OP_REF:
      {
      offset = GET2(ecode, 1) << 1;               /* Doubled ref number */
      ecode += 3;                                 /* Advance past item */

      /* If the reference is unset, set the length to be longer than the amount
      of subject left; this ensures that every attempt at a match fails. We
      can't just fail here, because of the possibility of quantifiers with zero
      minima. */

      length = (offset >= offset_top || md->offset_vector[offset] < 0)?
        md->end_subject - eptr + 1 :
        md->offset_vector[offset+1] - md->offset_vector[offset];

      /* Set up for repetition, or handle the non-repeated case */

      switch (*ecode)
        {
        case OP_CRSTAR:
        case OP_CRMINSTAR:
        case OP_CRPLUS:
        case OP_CRMINPLUS:
        case OP_CRQUERY:
        case OP_CRMINQUERY:
        c = *ecode++ - OP_CRSTAR;
        minimize = (c & 1) != 0;
        min = rep_min[c];                 /* Pick up values from tables; */
        max = rep_max[c];                 /* zero for max => infinity */
        if (max == 0) max = INT_MAX;
        break;

        case OP_CRRANGE:
        case OP_CRMINRANGE:
        minimize = (*ecode == OP_CRMINRANGE);
        min = GET2(ecode, 1);
        max = GET2(ecode, 3);
        if (max == 0) max = INT_MAX;
        ecode += 5;
        break;

        default:               /* No repeat follows */
        if (!match_ref(offset, eptr, length, md, ims)) RRETURN(MATCH_NOMATCH);
        eptr += length;
        continue;              /* With the main loop */
        }

      /* If the length of the reference is zero, just continue with the
      main loop. */

      if (length == 0) continue;

      /* First, ensure the minimum number of matches are present. We get back
      the length of the reference string explicitly rather than passing the
      address of eptr, so that eptr can be a register variable. */

      for (i = 1; i <= min; i++)
        {
        if (!match_ref(offset, eptr, length, md, ims)) RRETURN(MATCH_NOMATCH);
        eptr += length;
        }

      /* If min = max, continue at the same level without recursion.
      They are not both allowed to be zero. */

      if (min == max) continue;

      /* If minimizing, keep trying and advancing the pointer */

      if (minimize)
        {
        for (fi = min;; fi++)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          if (fi >= max || !match_ref(offset, eptr, length, md, ims))
            RRETURN(MATCH_NOMATCH);
          eptr += length;
          }
        /* Control never gets here */
        }

      /* If maximizing, find the longest string and work backwards */

      else
        {
        pp = eptr;
        for (i = min; i < max; i++)
          {
          if (!match_ref(offset, eptr, length, md, ims)) break;
          eptr += length;
          }
        while (eptr >= pp)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          eptr -= length;
          }
        RRETURN(MATCH_NOMATCH);
        }
      }
    /* Control never gets here */



    /* Match a bit-mapped character class, possibly repeatedly. This op code is
    used when all the characters in the class have values in the range 0-255,
    and either the matching is caseful, or the characters are in the range
    0-127 when UTF-8 processing is enabled. The only difference between
    OP_CLASS and OP_NCLASS occurs when a data character outside the range is
    encountered.

    First, look past the end of the item to see if there is repeat information
    following. Then obey similar code to character type repeats - written out
    again for speed. */

    case OP_NCLASS:
    case OP_CLASS:
      {
      data = ecode + 1;                /* Save for matching */
      ecode += 33;                     /* Advance past the item */

      switch (*ecode)
        {
        case OP_CRSTAR:
        case OP_CRMINSTAR:
        case OP_CRPLUS:
        case OP_CRMINPLUS:
        case OP_CRQUERY:
        case OP_CRMINQUERY:
        c = *ecode++ - OP_CRSTAR;
        minimize = (c & 1) != 0;
        min = rep_min[c];                 /* Pick up values from tables; */
        max = rep_max[c];                 /* zero for max => infinity */
        if (max == 0) max = INT_MAX;
        break;

        case OP_CRRANGE:
        case OP_CRMINRANGE:
        minimize = (*ecode == OP_CRMINRANGE);
        min = GET2(ecode, 1);
        max = GET2(ecode, 3);
        if (max == 0) max = INT_MAX;
        ecode += 5;
        break;

        default:               /* No repeat follows */
        min = max = 1;
        break;
        }

      /* First, ensure the minimum number of matches are present. */

#ifdef SUPPORT_UTF8
      /* UTF-8 mode */
      if (utf8)
        {
        for (i = 1; i <= min; i++)
          {
          if (eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
          GETCHARINC(c, eptr);
          if (c > 255)
            {
            if (op == OP_CLASS) RRETURN(MATCH_NOMATCH);
            }
          else
            {
            if ((data[c/8] & (1 << (c&7))) == 0) RRETURN(MATCH_NOMATCH);
            }
          }
        }
      else
#endif
      /* Not UTF-8 mode */
        {
        for (i = 1; i <= min; i++)
          {
          if (eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
          c = *eptr++;
          if ((data[c/8] & (1 << (c&7))) == 0) RRETURN(MATCH_NOMATCH);
          }
        }

      /* If max == min we can continue with the main loop without the
      need to recurse. */

      if (min == max) continue;

      /* If minimizing, keep testing the rest of the expression and advancing
      the pointer while it matches the class. */

      if (minimize)
        {
#ifdef SUPPORT_UTF8
        /* UTF-8 mode */
        if (utf8)
          {
          for (fi = min;; fi++)
            {
            RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
            if (rrc != MATCH_NOMATCH) RRETURN(rrc);
            if (fi >= max || eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
            GETCHARINC(c, eptr);
            if (c > 255)
              {
              if (op == OP_CLASS) RRETURN(MATCH_NOMATCH);
              }
            else
              {
              if ((data[c/8] & (1 << (c&7))) == 0) RRETURN(MATCH_NOMATCH);
              }
            }
          }
        else
#endif
        /* Not UTF-8 mode */
          {
          for (fi = min;; fi++)
            {
            RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
            if (rrc != MATCH_NOMATCH) RRETURN(rrc);
            if (fi >= max || eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
            c = *eptr++;
            if ((data[c/8] & (1 << (c&7))) == 0) RRETURN(MATCH_NOMATCH);
            }
          }
        /* Control never gets here */
        }

      /* If maximizing, find the longest possible run, then work backwards. */

      else
        {
        pp = eptr;

#ifdef SUPPORT_UTF8
        /* UTF-8 mode */
        if (utf8)
          {
          for (i = min; i < max; i++)
            {
            int len = 1;
            if (eptr >= md->end_subject) break;
            GETCHARLEN(c, eptr, len);
            if (c > 255)
              {
              if (op == OP_CLASS) break;
              }
            else
              {
              if ((data[c/8] & (1 << (c&7))) == 0) break;
              }
            eptr += len;
            }
          for (;;)
            {
            RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
            if (rrc != MATCH_NOMATCH) RRETURN(rrc);
            if (eptr-- == pp) break;        /* Stop if tried at original pos */
            BACKCHAR(eptr);
            }
          }
        else
#endif
          /* Not UTF-8 mode */
          {
          for (i = min; i < max; i++)
            {
            if (eptr >= md->end_subject) break;
            c = *eptr;
            if ((data[c/8] & (1 << (c&7))) == 0) break;
            eptr++;
            }
          while (eptr >= pp)
            {
            RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
            eptr--;
            if (rrc != MATCH_NOMATCH) RRETURN(rrc);
            }
          }

        RRETURN(MATCH_NOMATCH);
        }
      }
    /* Control never gets here */


    /* Match an extended character class. This opcode is encountered only
    in UTF-8 mode, because that's the only time it is compiled. */

#ifdef SUPPORT_UTF8
    case OP_XCLASS:
      {
      data = ecode + 1 + LINK_SIZE;                /* Save for matching */
      ecode += GET(ecode, 1);                      /* Advance past the item */

      switch (*ecode)
        {
        case OP_CRSTAR:
        case OP_CRMINSTAR:
        case OP_CRPLUS:
        case OP_CRMINPLUS:
        case OP_CRQUERY:
        case OP_CRMINQUERY:
        c = *ecode++ - OP_CRSTAR;
        minimize = (c & 1) != 0;
        min = rep_min[c];                 /* Pick up values from tables; */
        max = rep_max[c];                 /* zero for max => infinity */
        if (max == 0) max = INT_MAX;
        break;

        case OP_CRRANGE:
        case OP_CRMINRANGE:
        minimize = (*ecode == OP_CRMINRANGE);
        min = GET2(ecode, 1);
        max = GET2(ecode, 3);
        if (max == 0) max = INT_MAX;
        ecode += 5;
        break;

        default:               /* No repeat follows */
        min = max = 1;
        break;
        }

      /* First, ensure the minimum number of matches are present. */

      for (i = 1; i <= min; i++)
        {
        if (eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
        GETCHARINC(c, eptr);
        if (!_pcre_xclass(c, data)) RRETURN(MATCH_NOMATCH);
        }

      /* If max == min we can continue with the main loop without the
      need to recurse. */

      if (min == max) continue;

      /* If minimizing, keep testing the rest of the expression and advancing
      the pointer while it matches the class. */

      if (minimize)
        {
        for (fi = min;; fi++)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          if (fi >= max || eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
          GETCHARINC(c, eptr);
          if (!_pcre_xclass(c, data)) RRETURN(MATCH_NOMATCH);
          }
        /* Control never gets here */
        }

      /* If maximizing, find the longest possible run, then work backwards. */

      else
        {
        pp = eptr;
        for (i = min; i < max; i++)
          {
          int len = 1;
          if (eptr >= md->end_subject) break;
          GETCHARLEN(c, eptr, len);
          if (!_pcre_xclass(c, data)) break;
          eptr += len;
          }
        for(;;)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          if (eptr-- == pp) break;        /* Stop if tried at original pos */
          BACKCHAR(eptr)
          }
        RRETURN(MATCH_NOMATCH);
        }

      /* Control never gets here */
      }
#endif    /* End of XCLASS */

    /* Match a single character, casefully */

    case OP_CHAR:
#ifdef SUPPORT_UTF8
    if (utf8)
      {
      length = 1;
      ecode++;
      GETCHARLEN(fc, ecode, length);
      if (length > md->end_subject - eptr) RRETURN(MATCH_NOMATCH);
      while (length-- > 0) if (*ecode++ != *eptr++) RRETURN(MATCH_NOMATCH);
      }
    else
#endif

    /* Non-UTF-8 mode */
      {
      if (md->end_subject - eptr < 1) RRETURN(MATCH_NOMATCH);
      if (ecode[1] != *eptr++) RRETURN(MATCH_NOMATCH);
      ecode += 2;
      }
    break;

    /* Match a single character, caselessly */

    case OP_CHARNC:
#ifdef SUPPORT_UTF8
    if (utf8)
      {
      length = 1;
      ecode++;
      GETCHARLEN(fc, ecode, length);

      if (length > md->end_subject - eptr) RRETURN(MATCH_NOMATCH);

      /* If the pattern character's value is < 128, we have only one byte, and
      can use the fast lookup table. */

      if (fc < 128)
        {
        if (md->lcc[*ecode++] != md->lcc[*eptr++]) RRETURN(MATCH_NOMATCH);
        }

      /* Otherwise we must pick up the subject character */

      else
        {
        int dc;
        GETCHARINC(dc, eptr);
        ecode += length;

        /* If we have Unicode property support, we can use it to test the other
        case of the character, if there is one. The result of ucp_findchar() is
        < 0 if the char isn't found, and othercase is returned as zero if there
        isn't one. */

        if (fc != dc)
          {
#ifdef SUPPORT_UCP
          int chartype;
          int othercase;
          if (ucp_findchar(fc, &chartype, &othercase) < 0 || dc != othercase)
#endif
            RRETURN(MATCH_NOMATCH);
          }
        }
      }
    else
#endif   /* SUPPORT_UTF8 */

    /* Non-UTF-8 mode */
      {
      if (md->end_subject - eptr < 1) RRETURN(MATCH_NOMATCH);
      if (md->lcc[ecode[1]] != md->lcc[*eptr++]) RRETURN(MATCH_NOMATCH);
      ecode += 2;
      }
    break;

    /* Match a single character repeatedly; different opcodes share code. */

    case OP_EXACT:
    min = max = GET2(ecode, 1);
    ecode += 3;
    goto REPEATCHAR;

    case OP_UPTO:
    case OP_MINUPTO:
    min = 0;
    max = GET2(ecode, 1);
    minimize = *ecode == OP_MINUPTO;
    ecode += 3;
    goto REPEATCHAR;

    case OP_STAR:
    case OP_MINSTAR:
    case OP_PLUS:
    case OP_MINPLUS:
    case OP_QUERY:
    case OP_MINQUERY:
    c = *ecode++ - OP_STAR;
    minimize = (c & 1) != 0;
    min = rep_min[c];                 /* Pick up values from tables; */
    max = rep_max[c];                 /* zero for max => infinity */
    if (max == 0) max = INT_MAX;

    /* Common code for all repeated single-character matches. We can give
    up quickly if there are fewer than the minimum number of characters left in
    the subject. */

    REPEATCHAR:
#ifdef SUPPORT_UTF8
    if (utf8)
      {
      length = 1;
      charptr = ecode;
      GETCHARLEN(fc, ecode, length);
      if (min * length > md->end_subject - eptr) RRETURN(MATCH_NOMATCH);
      ecode += length;

      /* Handle multibyte character matching specially here. There is
      support for caseless matching if UCP support is present. */

      if (length > 1)
        {
        int oclength = 0;
        uschar occhars[8];

#ifdef SUPPORT_UCP
        int othercase;
        int chartype;
        if ((ims & PCRE_CASELESS) != 0 &&
             ucp_findchar(fc, &chartype, &othercase) >= 0 &&
             othercase > 0)
          oclength = _pcre_ord2utf8(othercase, occhars);
#endif  /* SUPPORT_UCP */

        for (i = 1; i <= min; i++)
          {
          if (memcmp(eptr, charptr, length) == 0) eptr += length;
          /* Need braces because of following else */
          else if (oclength == 0) { RRETURN(MATCH_NOMATCH); }
          else
            {
            if (memcmp(eptr, occhars, oclength) != 0) RRETURN(MATCH_NOMATCH);
            eptr += oclength;
            }
          }

        if (min == max) continue;

        if (minimize)
          {
          for (fi = min;; fi++)
            {
            RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
            if (rrc != MATCH_NOMATCH) RRETURN(rrc);
            if (fi >= max || eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
            if (memcmp(eptr, charptr, length) == 0) eptr += length;
            /* Need braces because of following else */
            else if (oclength == 0) { RRETURN(MATCH_NOMATCH); }
            else
              {
              if (memcmp(eptr, occhars, oclength) != 0) RRETURN(MATCH_NOMATCH);
              eptr += oclength;
              }
            }
          /* Control never gets here */
          }
        else
          {
          pp = eptr;
          for (i = min; i < max; i++)
            {
            if (eptr > md->end_subject - length) break;
            if (memcmp(eptr, charptr, length) == 0) eptr += length;
            else if (oclength == 0) break;
            else
              {
              if (memcmp(eptr, occhars, oclength) != 0) break;
              eptr += oclength;
              }
            }
          while (eptr >= pp)
           {
           RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
           if (rrc != MATCH_NOMATCH) RRETURN(rrc);
           eptr -= length;
           }
          RRETURN(MATCH_NOMATCH);
          }
        /* Control never gets here */
        }

      /* If the length of a UTF-8 character is 1, we fall through here, and
      obey the code as for non-UTF-8 characters below, though in this case the
      value of fc will always be < 128. */
      }
    else
#endif  /* SUPPORT_UTF8 */

    /* When not in UTF-8 mode, load a single-byte character. */
      {
      if (min > md->end_subject - eptr) RRETURN(MATCH_NOMATCH);
      fc = *ecode++;
      }

    /* The value of fc at this point is always less than 256, though we may or
    may not be in UTF-8 mode. The code is duplicated for the caseless and
    caseful cases, for speed, since matching characters is likely to be quite
    common. First, ensure the minimum number of matches are present. If min =
    max, continue at the same level without recursing. Otherwise, if
    minimizing, keep trying the rest of the expression and advancing one
    matching character if failing, up to the maximum. Alternatively, if
    maximizing, find the maximum number of characters and work backwards. */

    DPRINTF(("matching %c{%d,%d} against subject %.*s\n", fc, min, max,
      max, eptr));

    if ((ims & PCRE_CASELESS) != 0)
      {
      fc = md->lcc[fc];
      for (i = 1; i <= min; i++)
        if (fc != md->lcc[*eptr++]) RRETURN(MATCH_NOMATCH);
      if (min == max) continue;
      if (minimize)
        {
        for (fi = min;; fi++)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          if (fi >= max || eptr >= md->end_subject ||
              fc != md->lcc[*eptr++])
            RRETURN(MATCH_NOMATCH);
          }
        /* Control never gets here */
        }
      else
        {
        pp = eptr;
        for (i = min; i < max; i++)
          {
          if (eptr >= md->end_subject || fc != md->lcc[*eptr]) break;
          eptr++;
          }
        while (eptr >= pp)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          eptr--;
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          }
        RRETURN(MATCH_NOMATCH);
        }
      /* Control never gets here */
      }

    /* Caseful comparisons (includes all multi-byte characters) */

    else
      {
      for (i = 1; i <= min; i++) if (fc != *eptr++) RRETURN(MATCH_NOMATCH);
      if (min == max) continue;
      if (minimize)
        {
        for (fi = min;; fi++)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          if (fi >= max || eptr >= md->end_subject || fc != *eptr++)
            RRETURN(MATCH_NOMATCH);
          }
        /* Control never gets here */
        }
      else
        {
        pp = eptr;
        for (i = min; i < max; i++)
          {
          if (eptr >= md->end_subject || fc != *eptr) break;
          eptr++;
          }
        while (eptr >= pp)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          eptr--;
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          }
        RRETURN(MATCH_NOMATCH);
        }
      }
    /* Control never gets here */

    /* Match a negated single one-byte character. The character we are
    checking can be multibyte. */

    case OP_NOT:
    if (eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
    ecode++;
    GETCHARINCTEST(c, eptr);
    if ((ims & PCRE_CASELESS) != 0)
      {
#ifdef SUPPORT_UTF8
      if (c < 256)
#endif
      c = md->lcc[c];
      if (md->lcc[*ecode++] == c) RRETURN(MATCH_NOMATCH);
      }
    else
      {
      if (*ecode++ == c) RRETURN(MATCH_NOMATCH);
      }
    break;

    /* Match a negated single one-byte character repeatedly. This is almost a
    repeat of the code for a repeated single character, but I haven't found a
    nice way of commoning these up that doesn't require a test of the
    positive/negative option for each character match. Maybe that wouldn't add
    very much to the time taken, but character matching *is* what this is all
    about... */

    case OP_NOTEXACT:
    min = max = GET2(ecode, 1);
    ecode += 3;
    goto REPEATNOTCHAR;

    case OP_NOTUPTO:
    case OP_NOTMINUPTO:
    min = 0;
    max = GET2(ecode, 1);
    minimize = *ecode == OP_NOTMINUPTO;
    ecode += 3;
    goto REPEATNOTCHAR;

    case OP_NOTSTAR:
    case OP_NOTMINSTAR:
    case OP_NOTPLUS:
    case OP_NOTMINPLUS:
    case OP_NOTQUERY:
    case OP_NOTMINQUERY:
    c = *ecode++ - OP_NOTSTAR;
    minimize = (c & 1) != 0;
    min = rep_min[c];                 /* Pick up values from tables; */
    max = rep_max[c];                 /* zero for max => infinity */
    if (max == 0) max = INT_MAX;

    /* Common code for all repeated single-byte matches. We can give up quickly
    if there are fewer than the minimum number of bytes left in the
    subject. */

    REPEATNOTCHAR:
    if (min > md->end_subject - eptr) RRETURN(MATCH_NOMATCH);
    fc = *ecode++;

    /* The code is duplicated for the caseless and caseful cases, for speed,
    since matching characters is likely to be quite common. First, ensure the
    minimum number of matches are present. If min = max, continue at the same
    level without recursing. Otherwise, if minimizing, keep trying the rest of
    the expression and advancing one matching character if failing, up to the
    maximum. Alternatively, if maximizing, find the maximum number of
    characters and work backwards. */

    DPRINTF(("negative matching %c{%d,%d} against subject %.*s\n", fc, min, max,
      max, eptr));

    if ((ims & PCRE_CASELESS) != 0)
      {
      fc = md->lcc[fc];

#ifdef SUPPORT_UTF8
      /* UTF-8 mode */
      if (utf8)
        {
        register int d;
        for (i = 1; i <= min; i++)
          {
          GETCHARINC(d, eptr);
          if (d < 256) d = md->lcc[d];
          if (fc == d) RRETURN(MATCH_NOMATCH);
          }
        }
      else
#endif

      /* Not UTF-8 mode */
        {
        for (i = 1; i <= min; i++)
          if (fc == md->lcc[*eptr++]) RRETURN(MATCH_NOMATCH);
        }

      if (min == max) continue;

      if (minimize)
        {
#ifdef SUPPORT_UTF8
        /* UTF-8 mode */
        if (utf8)
          {
          register int d;
          for (fi = min;; fi++)
            {
            RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
            if (rrc != MATCH_NOMATCH) RRETURN(rrc);
            GETCHARINC(d, eptr);
            if (d < 256) d = md->lcc[d];
            if (fi >= max || eptr >= md->end_subject || fc == d)
              RRETURN(MATCH_NOMATCH);
            }
          }
        else
#endif
        /* Not UTF-8 mode */
          {
          for (fi = min;; fi++)
            {
            RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
            if (rrc != MATCH_NOMATCH) RRETURN(rrc);
            if (fi >= max || eptr >= md->end_subject || fc == md->lcc[*eptr++])
              RRETURN(MATCH_NOMATCH);
            }
          }
        /* Control never gets here */
        }

      /* Maximize case */

      else
        {
        pp = eptr;

#ifdef SUPPORT_UTF8
        /* UTF-8 mode */
        if (utf8)
          {
          register int d;
          for (i = min; i < max; i++)
            {
            int len = 1;
            if (eptr >= md->end_subject) break;
            GETCHARLEN(d, eptr, len);
            if (d < 256) d = md->lcc[d];
            if (fc == d) break;
            eptr += len;
            }
          for(;;)
            {
            RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
            if (rrc != MATCH_NOMATCH) RRETURN(rrc);
            if (eptr-- == pp) break;        /* Stop if tried at original pos */
            BACKCHAR(eptr);
            }
          }
        else
#endif
        /* Not UTF-8 mode */
          {
          for (i = min; i < max; i++)
            {
            if (eptr >= md->end_subject || fc == md->lcc[*eptr]) break;
            eptr++;
            }
          while (eptr >= pp)
            {
            RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
            if (rrc != MATCH_NOMATCH) RRETURN(rrc);
            eptr--;
            }
          }

        RRETURN(MATCH_NOMATCH);
        }
      /* Control never gets here */
      }

    /* Caseful comparisons */

    else
      {
#ifdef SUPPORT_UTF8
      /* UTF-8 mode */
      if (utf8)
        {
        register int d;
        for (i = 1; i <= min; i++)
          {
          GETCHARINC(d, eptr);
          if (fc == d) RRETURN(MATCH_NOMATCH);
          }
        }
      else
#endif
      /* Not UTF-8 mode */
        {
        for (i = 1; i <= min; i++)
          if (fc == *eptr++) RRETURN(MATCH_NOMATCH);
        }

      if (min == max) continue;

      if (minimize)
        {
#ifdef SUPPORT_UTF8
        /* UTF-8 mode */
        if (utf8)
          {
          register int d;
          for (fi = min;; fi++)
            {
            RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
            if (rrc != MATCH_NOMATCH) RRETURN(rrc);
            GETCHARINC(d, eptr);
            if (fi >= max || eptr >= md->end_subject || fc == d)
              RRETURN(MATCH_NOMATCH);
            }
          }
        else
#endif
        /* Not UTF-8 mode */
          {
          for (fi = min;; fi++)
            {
            RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
            if (rrc != MATCH_NOMATCH) RRETURN(rrc);
            if (fi >= max || eptr >= md->end_subject || fc == *eptr++)
              RRETURN(MATCH_NOMATCH);
            }
          }
        /* Control never gets here */
        }

      /* Maximize case */

      else
        {
        pp = eptr;

#ifdef SUPPORT_UTF8
        /* UTF-8 mode */
        if (utf8)
          {
          register int d;
          for (i = min; i < max; i++)
            {
            int len = 1;
            if (eptr >= md->end_subject) break;
            GETCHARLEN(d, eptr, len);
            if (fc == d) break;
            eptr += len;
            }
          for(;;)
            {
            RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
            if (rrc != MATCH_NOMATCH) RRETURN(rrc);
            if (eptr-- == pp) break;        /* Stop if tried at original pos */
            BACKCHAR(eptr);
            }
          }
        else
#endif
        /* Not UTF-8 mode */
          {
          for (i = min; i < max; i++)
            {
            if (eptr >= md->end_subject || fc == *eptr) break;
            eptr++;
            }
          while (eptr >= pp)
            {
            RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
            if (rrc != MATCH_NOMATCH) RRETURN(rrc);
            eptr--;
            }
          }

        RRETURN(MATCH_NOMATCH);
        }
      }
    /* Control never gets here */

    /* Match a single character type repeatedly; several different opcodes
    share code. This is very similar to the code for single characters, but we
    repeat it in the interests of efficiency. */

    case OP_TYPEEXACT:
    min = max = GET2(ecode, 1);
    minimize = TRUE;
    ecode += 3;
    goto REPEATTYPE;

    case OP_TYPEUPTO:
    case OP_TYPEMINUPTO:
    min = 0;
    max = GET2(ecode, 1);
    minimize = *ecode == OP_TYPEMINUPTO;
    ecode += 3;
    goto REPEATTYPE;

    case OP_TYPESTAR:
    case OP_TYPEMINSTAR:
    case OP_TYPEPLUS:
    case OP_TYPEMINPLUS:
    case OP_TYPEQUERY:
    case OP_TYPEMINQUERY:
    c = *ecode++ - OP_TYPESTAR;
    minimize = (c & 1) != 0;
    min = rep_min[c];                 /* Pick up values from tables; */
    max = rep_max[c];                 /* zero for max => infinity */
    if (max == 0) max = INT_MAX;

    /* Common code for all repeated single character type matches. Note that
    in UTF-8 mode, '.' matches a character of any length, but for the other
    character types, the valid characters are all one-byte long. */

    REPEATTYPE:
    ctype = *ecode++;      /* Code for the character type */

#ifdef SUPPORT_UCP
    if (ctype == OP_PROP || ctype == OP_NOTPROP)
      {
      prop_fail_result = ctype == OP_NOTPROP;
      prop_type = *ecode++;
      if (prop_type >= 128)
        {
        prop_test_against = prop_type - 128;
        prop_test_variable = &prop_category;
        }
      else
        {
        prop_test_against = prop_type;
        prop_test_variable = &prop_chartype;
        }
      }
    else prop_type = -1;
#endif

    /* First, ensure the minimum number of matches are present. Use inline
    code for maximizing the speed, and do the type test once at the start
    (i.e. keep it out of the loop). Also we can test that there are at least
    the minimum number of bytes before we start. This isn't as effective in
    UTF-8 mode, but it does no harm. Separate the UTF-8 code completely as that
    is tidier. Also separate the UCP code, which can be the same for both UTF-8
    and single-bytes. */

    if (min > md->end_subject - eptr) RRETURN(MATCH_NOMATCH);
    if (min > 0)
      {
#ifdef SUPPORT_UCP
      if (prop_type > 0)
        {
        for (i = 1; i <= min; i++)
          {
          GETCHARINC(c, eptr);
          prop_category = ucp_findchar(c, &prop_chartype, &prop_othercase);
          if ((*prop_test_variable == prop_test_against) == prop_fail_result)
            RRETURN(MATCH_NOMATCH);
          }
        }

      /* Match extended Unicode sequences. We will get here only if the
      support is in the binary; otherwise a compile-time error occurs. */

      else if (ctype == OP_EXTUNI)
        {
        for (i = 1; i <= min; i++)
          {
          GETCHARINCTEST(c, eptr);
          prop_category = ucp_findchar(c, &prop_chartype, &prop_othercase);
          if (prop_category == ucp_M) RRETURN(MATCH_NOMATCH);
          while (eptr < md->end_subject)
            {
            int len = 1;
            if (!utf8) c = *eptr; else
              {
              GETCHARLEN(c, eptr, len);
              }
            prop_category = ucp_findchar(c, &prop_chartype, &prop_othercase);
            if (prop_category != ucp_M) break;
            eptr += len;
            }
          }
        }

      else
#endif     /* SUPPORT_UCP */

/* Handle all other cases when the coding is UTF-8 */

#ifdef SUPPORT_UTF8
      if (utf8) switch(ctype)
        {
        case OP_ANY:
        for (i = 1; i <= min; i++)
          {
          if (eptr >= md->end_subject ||
             (*eptr++ == NEWLINE && (ims & PCRE_DOTALL) == 0))
            RRETURN(MATCH_NOMATCH);
          while (eptr < md->end_subject && (*eptr & 0xc0) == 0x80) eptr++;
          }
        break;

        case OP_ANYBYTE:
        eptr += min;
        break;

        case OP_NOT_DIGIT:
        for (i = 1; i <= min; i++)
          {
          if (eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
          GETCHARINC(c, eptr);
          if (c < 128 && (md->ctypes[c] & ctype_digit) != 0)
            RRETURN(MATCH_NOMATCH);
          }
        break;

        case OP_DIGIT:
        for (i = 1; i <= min; i++)
          {
          if (eptr >= md->end_subject ||
             *eptr >= 128 || (md->ctypes[*eptr++] & ctype_digit) == 0)
            RRETURN(MATCH_NOMATCH);
          /* No need to skip more bytes - we know it's a 1-byte character */
          }
        break;

        case OP_NOT_WHITESPACE:
        for (i = 1; i <= min; i++)
          {
          if (eptr >= md->end_subject ||
             (*eptr < 128 && (md->ctypes[*eptr++] & ctype_space) != 0))
            RRETURN(MATCH_NOMATCH);
          while (eptr < md->end_subject && (*eptr & 0xc0) == 0x80) eptr++;
          }
        break;

        case OP_WHITESPACE:
        for (i = 1; i <= min; i++)
          {
          if (eptr >= md->end_subject ||
             *eptr >= 128 || (md->ctypes[*eptr++] & ctype_space) == 0)
            RRETURN(MATCH_NOMATCH);
          /* No need to skip more bytes - we know it's a 1-byte character */
          }
        break;

        case OP_NOT_WORDCHAR:
        for (i = 1; i <= min; i++)
          {
          if (eptr >= md->end_subject ||
             (*eptr < 128 && (md->ctypes[*eptr++] & ctype_word) != 0))
            RRETURN(MATCH_NOMATCH);
          while (eptr < md->end_subject && (*eptr & 0xc0) == 0x80) eptr++;
          }
        break;

        case OP_WORDCHAR:
        for (i = 1; i <= min; i++)
          {
          if (eptr >= md->end_subject ||
             *eptr >= 128 || (md->ctypes[*eptr++] & ctype_word) == 0)
            RRETURN(MATCH_NOMATCH);
          /* No need to skip more bytes - we know it's a 1-byte character */
          }
        break;

        default:
        RRETURN(PCRE_ERROR_INTERNAL);
        }  /* End switch(ctype) */

      else
#endif     /* SUPPORT_UTF8 */

      /* Code for the non-UTF-8 case for minimum matching of operators other
      than OP_PROP and OP_NOTPROP. */

      switch(ctype)
        {
        case OP_ANY:
        if ((ims & PCRE_DOTALL) == 0)
          {
          for (i = 1; i <= min; i++)
            if (*eptr++ == NEWLINE) RRETURN(MATCH_NOMATCH);
          }
        else eptr += min;
        break;

        case OP_ANYBYTE:
        eptr += min;
        break;

        case OP_NOT_DIGIT:
        for (i = 1; i <= min; i++)
          if ((md->ctypes[*eptr++] & ctype_digit) != 0) RRETURN(MATCH_NOMATCH);
        break;

        case OP_DIGIT:
        for (i = 1; i <= min; i++)
          if ((md->ctypes[*eptr++] & ctype_digit) == 0) RRETURN(MATCH_NOMATCH);
        break;

        case OP_NOT_WHITESPACE:
        for (i = 1; i <= min; i++)
          if ((md->ctypes[*eptr++] & ctype_space) != 0) RRETURN(MATCH_NOMATCH);
        break;

        case OP_WHITESPACE:
        for (i = 1; i <= min; i++)
          if ((md->ctypes[*eptr++] & ctype_space) == 0) RRETURN(MATCH_NOMATCH);
        break;

        case OP_NOT_WORDCHAR:
        for (i = 1; i <= min; i++)
          if ((md->ctypes[*eptr++] & ctype_word) != 0)
            RRETURN(MATCH_NOMATCH);
        break;

        case OP_WORDCHAR:
        for (i = 1; i <= min; i++)
          if ((md->ctypes[*eptr++] & ctype_word) == 0)
            RRETURN(MATCH_NOMATCH);
        break;

        default:
        RRETURN(PCRE_ERROR_INTERNAL);
        }
      }

    /* If min = max, continue at the same level without recursing */

    if (min == max) continue;

    /* If minimizing, we have to test the rest of the pattern before each
    subsequent match. Again, separate the UTF-8 case for speed, and also
    separate the UCP cases. */

    if (minimize)
      {
#ifdef SUPPORT_UCP
      if (prop_type > 0)
        {
        for (fi = min;; fi++)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          if (fi >= max || eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
          GETCHARINC(c, eptr);
          prop_category = ucp_findchar(c, &prop_chartype, &prop_othercase);
          if ((*prop_test_variable == prop_test_against) == prop_fail_result)
            RRETURN(MATCH_NOMATCH);
          }
        }

      /* Match extended Unicode sequences. We will get here only if the
      support is in the binary; otherwise a compile-time error occurs. */

      else if (ctype == OP_EXTUNI)
        {
        for (fi = min;; fi++)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          if (fi >= max || eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
          GETCHARINCTEST(c, eptr);
          prop_category = ucp_findchar(c, &prop_chartype, &prop_othercase);
          if (prop_category == ucp_M) RRETURN(MATCH_NOMATCH);
          while (eptr < md->end_subject)
            {
            int len = 1;
            if (!utf8) c = *eptr; else
              {
              GETCHARLEN(c, eptr, len);
              }
            prop_category = ucp_findchar(c, &prop_chartype, &prop_othercase);
            if (prop_category != ucp_M) break;
            eptr += len;
            }
          }
        }

      else
#endif     /* SUPPORT_UCP */

#ifdef SUPPORT_UTF8
      /* UTF-8 mode */
      if (utf8)
        {
        for (fi = min;; fi++)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          if (fi >= max || eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);

          GETCHARINC(c, eptr);
          switch(ctype)
            {
            case OP_ANY:
            if ((ims & PCRE_DOTALL) == 0 && c == NEWLINE) RRETURN(MATCH_NOMATCH);
            break;

            case OP_ANYBYTE:
            break;

            case OP_NOT_DIGIT:
            if (c < 256 && (md->ctypes[c] & ctype_digit) != 0)
              RRETURN(MATCH_NOMATCH);
            break;

            case OP_DIGIT:
            if (c >= 256 || (md->ctypes[c] & ctype_digit) == 0)
              RRETURN(MATCH_NOMATCH);
            break;

            case OP_NOT_WHITESPACE:
            if (c < 256 && (md->ctypes[c] & ctype_space) != 0)
              RRETURN(MATCH_NOMATCH);
            break;

            case OP_WHITESPACE:
            if  (c >= 256 || (md->ctypes[c] & ctype_space) == 0)
              RRETURN(MATCH_NOMATCH);
            break;

            case OP_NOT_WORDCHAR:
            if (c < 256 && (md->ctypes[c] & ctype_word) != 0)
              RRETURN(MATCH_NOMATCH);
            break;

            case OP_WORDCHAR:
            if (c >= 256 || (md->ctypes[c] & ctype_word) == 0)
              RRETURN(MATCH_NOMATCH);
            break;

            default:
            RRETURN(PCRE_ERROR_INTERNAL);
            }
          }
        }
      else
#endif
      /* Not UTF-8 mode */
        {
        for (fi = min;; fi++)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          if (fi >= max || eptr >= md->end_subject) RRETURN(MATCH_NOMATCH);
          c = *eptr++;
          switch(ctype)
            {
            case OP_ANY:
            if ((ims & PCRE_DOTALL) == 0 && c == NEWLINE) RRETURN(MATCH_NOMATCH);
            break;

            case OP_ANYBYTE:
            break;

            case OP_NOT_DIGIT:
            if ((md->ctypes[c] & ctype_digit) != 0) RRETURN(MATCH_NOMATCH);
            break;

            case OP_DIGIT:
            if ((md->ctypes[c] & ctype_digit) == 0) RRETURN(MATCH_NOMATCH);
            break;

            case OP_NOT_WHITESPACE:
            if ((md->ctypes[c] & ctype_space) != 0) RRETURN(MATCH_NOMATCH);
            break;

            case OP_WHITESPACE:
            if  ((md->ctypes[c] & ctype_space) == 0) RRETURN(MATCH_NOMATCH);
            break;

            case OP_NOT_WORDCHAR:
            if ((md->ctypes[c] & ctype_word) != 0) RRETURN(MATCH_NOMATCH);
            break;

            case OP_WORDCHAR:
            if ((md->ctypes[c] & ctype_word) == 0) RRETURN(MATCH_NOMATCH);
            break;

            default:
            RRETURN(PCRE_ERROR_INTERNAL);
            }
          }
        }
      /* Control never gets here */
      }

    /* If maximizing it is worth using inline code for speed, doing the type
    test once at the start (i.e. keep it out of the loop). Again, keep the
    UTF-8 and UCP stuff separate. */

    else
      {
      pp = eptr;  /* Remember where we started */

#ifdef SUPPORT_UCP
      if (prop_type > 0)
        {
        for (i = min; i < max; i++)
          {
          int len = 1;
          if (eptr >= md->end_subject) break;
          GETCHARLEN(c, eptr, len);
          prop_category = ucp_findchar(c, &prop_chartype, &prop_othercase);
          if ((*prop_test_variable == prop_test_against) == prop_fail_result)
            break;
          eptr+= len;
          }

        /* eptr is now past the end of the maximum run */

        for(;;)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          if (eptr-- == pp) break;        /* Stop if tried at original pos */
          BACKCHAR(eptr);
          }
        }

      /* Match extended Unicode sequences. We will get here only if the
      support is in the binary; otherwise a compile-time error occurs. */

      else if (ctype == OP_EXTUNI)
        {
        for (i = min; i < max; i++)
          {
          if (eptr >= md->end_subject) break;
          GETCHARINCTEST(c, eptr);
          prop_category = ucp_findchar(c, &prop_chartype, &prop_othercase);
          if (prop_category == ucp_M) break;
          while (eptr < md->end_subject)
            {
            int len = 1;
            if (!utf8) c = *eptr; else
              {
              GETCHARLEN(c, eptr, len);
              }
            prop_category = ucp_findchar(c, &prop_chartype, &prop_othercase);
            if (prop_category != ucp_M) break;
            eptr += len;
            }
          }

        /* eptr is now past the end of the maximum run */

        for(;;)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          if (eptr-- == pp) break;        /* Stop if tried at original pos */
          for (;;)                        /* Move back over one extended */
            {
            int len = 1;
            BACKCHAR(eptr);
            if (!utf8) c = *eptr; else
              {
              GETCHARLEN(c, eptr, len);
              }
            prop_category = ucp_findchar(c, &prop_chartype, &prop_othercase);
            if (prop_category != ucp_M) break;
            eptr--;
            }
          }
        }

      else
#endif   /* SUPPORT_UCP */

#ifdef SUPPORT_UTF8
      /* UTF-8 mode */

      if (utf8)
        {
        switch(ctype)
          {
          case OP_ANY:

          /* Special code is required for UTF8, but when the maximum is unlimited
          we don't need it, so we repeat the non-UTF8 code. This is probably
          worth it, because .* is quite a common idiom. */

          if (max < INT_MAX)
            {
            if ((ims & PCRE_DOTALL) == 0)
              {
              for (i = min; i < max; i++)
                {
                if (eptr >= md->end_subject || *eptr == NEWLINE) break;
                eptr++;
                while (eptr < md->end_subject && (*eptr & 0xc0) == 0x80) eptr++;
                }
              }
            else
              {
              for (i = min; i < max; i++)
                {
                eptr++;
                while (eptr < md->end_subject && (*eptr & 0xc0) == 0x80) eptr++;
                }
              }
            }

          /* Handle unlimited UTF-8 repeat */

          else
            {
            if ((ims & PCRE_DOTALL) == 0)
              {
              for (i = min; i < max; i++)
                {
                if (eptr >= md->end_subject || *eptr == NEWLINE) break;
                eptr++;
                }
              break;
              }
            else
              {
              c = max - min;
              if (c > md->end_subject - eptr) c = md->end_subject - eptr;
              eptr += c;
              }
            }
          break;

          /* The byte case is the same as non-UTF8 */

          case OP_ANYBYTE:
          c = max - min;
          if (c > md->end_subject - eptr) c = md->end_subject - eptr;
          eptr += c;
          break;

          case OP_NOT_DIGIT:
          for (i = min; i < max; i++)
            {
            int len = 1;
            if (eptr >= md->end_subject) break;
            GETCHARLEN(c, eptr, len);
            if (c < 256 && (md->ctypes[c] & ctype_digit) != 0) break;
            eptr+= len;
            }
          break;

          case OP_DIGIT:
          for (i = min; i < max; i++)
            {
            int len = 1;
            if (eptr >= md->end_subject) break;
            GETCHARLEN(c, eptr, len);
            if (c >= 256 ||(md->ctypes[c] & ctype_digit) == 0) break;
            eptr+= len;
            }
          break;

          case OP_NOT_WHITESPACE:
          for (i = min; i < max; i++)
            {
            int len = 1;
            if (eptr >= md->end_subject) break;
            GETCHARLEN(c, eptr, len);
            if (c < 256 && (md->ctypes[c] & ctype_space) != 0) break;
            eptr+= len;
            }
          break;

          case OP_WHITESPACE:
          for (i = min; i < max; i++)
            {
            int len = 1;
            if (eptr >= md->end_subject) break;
            GETCHARLEN(c, eptr, len);
            if (c >= 256 ||(md->ctypes[c] & ctype_space) == 0) break;
            eptr+= len;
            }
          break;

          case OP_NOT_WORDCHAR:
          for (i = min; i < max; i++)
            {
            int len = 1;
            if (eptr >= md->end_subject) break;
            GETCHARLEN(c, eptr, len);
            if (c < 256 && (md->ctypes[c] & ctype_word) != 0) break;
            eptr+= len;
            }
          break;

          case OP_WORDCHAR:
          for (i = min; i < max; i++)
            {
            int len = 1;
            if (eptr >= md->end_subject) break;
            GETCHARLEN(c, eptr, len);
            if (c >= 256 || (md->ctypes[c] & ctype_word) == 0) break;
            eptr+= len;
            }
          break;

          default:
          RRETURN(PCRE_ERROR_INTERNAL);
          }

        /* eptr is now past the end of the maximum run */

        for(;;)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          if (eptr-- == pp) break;        /* Stop if tried at original pos */
          BACKCHAR(eptr);
          }
        }
      else
#endif

      /* Not UTF-8 mode */
        {
        switch(ctype)
          {
          case OP_ANY:
          if ((ims & PCRE_DOTALL) == 0)
            {
            for (i = min; i < max; i++)
              {
              if (eptr >= md->end_subject || *eptr == NEWLINE) break;
              eptr++;
              }
            break;
            }
          /* For DOTALL case, fall through and treat as \C */

          case OP_ANYBYTE:
          c = max - min;
          if (c > md->end_subject - eptr) c = md->end_subject - eptr;
          eptr += c;
          break;

          case OP_NOT_DIGIT:
          for (i = min; i < max; i++)
            {
            if (eptr >= md->end_subject || (md->ctypes[*eptr] & ctype_digit) != 0)
              break;
            eptr++;
            }
          break;

          case OP_DIGIT:
          for (i = min; i < max; i++)
            {
            if (eptr >= md->end_subject || (md->ctypes[*eptr] & ctype_digit) == 0)
              break;
            eptr++;
            }
          break;

          case OP_NOT_WHITESPACE:
          for (i = min; i < max; i++)
            {
            if (eptr >= md->end_subject || (md->ctypes[*eptr] & ctype_space) != 0)
              break;
            eptr++;
            }
          break;

          case OP_WHITESPACE:
          for (i = min; i < max; i++)
            {
            if (eptr >= md->end_subject || (md->ctypes[*eptr] & ctype_space) == 0)
              break;
            eptr++;
            }
          break;

          case OP_NOT_WORDCHAR:
          for (i = min; i < max; i++)
            {
            if (eptr >= md->end_subject || (md->ctypes[*eptr] & ctype_word) != 0)
              break;
            eptr++;
            }
          break;

          case OP_WORDCHAR:
          for (i = min; i < max; i++)
            {
            if (eptr >= md->end_subject || (md->ctypes[*eptr] & ctype_word) == 0)
              break;
            eptr++;
            }
          break;

          default:
          RRETURN(PCRE_ERROR_INTERNAL);
          }

        /* eptr is now past the end of the maximum run */

        while (eptr >= pp)
          {
          RMATCH(rrc, eptr, ecode, offset_top, md, ims, eptrb, 0);
          eptr--;
          if (rrc != MATCH_NOMATCH) RRETURN(rrc);
          }
        }

      /* Get here if we can't make it match with any permitted repetitions */

      RRETURN(MATCH_NOMATCH);
      }
    /* Control never gets here */

    /* There's been some horrible disaster. Since all codes > OP_BRA are
    for capturing brackets, and there shouldn't be any gaps between 0 and
    OP_BRA, arrival here can only mean there is something seriously wrong
    in the code above or the OP_xxx definitions. */

    default:
    DPRINTF(("Unknown opcode %d\n", *ecode));
    RRETURN(PCRE_ERROR_UNKNOWN_NODE);
    }

  /* Do not stick any code in here without much thought; it is assumed
  that "continue" in the code above comes out to here to repeat the main
  loop. */

  }             /* End of main loop */
/* Control never reaches here */
}


/***************************************************************************
****************************************************************************
                   RECURSION IN THE match() FUNCTION

Undefine all the macros that were defined above to handle this. */

#ifdef NO_RECURSE
#undef eptr
#undef ecode
#undef offset_top
#undef ims
#undef eptrb
#undef flags

#undef callpat
#undef charptr
#undef data
#undef next
#undef pp
#undef prev
#undef saved_eptr

#undef new_recursive

#undef cur_is_word
#undef condition
#undef minimize
#undef prev_is_word

#undef original_ims

#undef ctype
#undef length
#undef max
#undef min
#undef number
#undef offset
#undef op
#undef save_capture_last
#undef save_offset1
#undef save_offset2
#undef save_offset3
#undef stacksave

#undef newptrb

#endif

/* These two are defined as macros in both cases */

#undef fc
#undef fi

/***************************************************************************
***************************************************************************/



/*************************************************
*         Execute a Regular Expression           *
*************************************************/

/* This function applies a compiled re to a subject string and picks out
portions of the string if it matches. Two elements in the vector are set for
each substring: the offsets to the start and end of the substring.

Arguments:
  argument_re     points to the compiled expression
  extra_data      points to extra data or is NULL
  subject         points to the subject string
  length          length of subject string (may contain binary zeros)
  start_offset    where to start in the subject string
  options         option bits
  offsets         points to a vector of ints to be filled in with offsets
  offsetcount     the number of elements in the vector

Returns:          > 0 => success; value is the number of elements filled in
                  = 0 => success, but offsets is not big enough
                   -1 => failed to match
                 < -1 => some kind of unexpected problem
*/

EXPORT int
pcre_exec(const pcre *argument_re, const pcre_extra *extra_data,
  const char *subject, int length, int start_offset, int options, int *offsets,
  int offsetcount)
{
int rc, resetcount, ocount;
int first_byte = -1;
int req_byte = -1;
int req_byte2 = -1;
unsigned long int ims = 0;
BOOL using_temporary_offsets = FALSE;
BOOL anchored;
BOOL startline;
BOOL firstline;
BOOL first_byte_caseless = FALSE;
BOOL req_byte_caseless = FALSE;
match_data match_block;
const uschar *tables;
const uschar *start_bits = NULL;
const uschar *start_match = (const uschar *)subject + start_offset;
const uschar *end_subject;
const uschar *req_byte_ptr = start_match - 1;

pcre_study_data internal_study;
const pcre_study_data *study;

real_pcre internal_re;
const real_pcre *external_re = (const real_pcre *)argument_re;
const real_pcre *re = external_re;

/* Plausibility checks */

if ((options & ~PUBLIC_EXEC_OPTIONS) != 0) return PCRE_ERROR_BADOPTION;
if (re == NULL || subject == NULL ||
   (offsets == NULL && offsetcount > 0)) return PCRE_ERROR_NULL;
if (offsetcount < 0) return PCRE_ERROR_BADCOUNT;

/* Fish out the optional data from the extra_data structure, first setting
the default values. */

study = NULL;
match_block.match_limit = MATCH_LIMIT;
match_block.callout_data = NULL;

/* The table pointer is always in native byte order. */

tables = external_re->tables;

if (extra_data != NULL)
  {
  register unsigned int flags = extra_data->flags;
  if ((flags & PCRE_EXTRA_STUDY_DATA) != 0)
    study = (const pcre_study_data *)extra_data->study_data;
  if ((flags & PCRE_EXTRA_MATCH_LIMIT) != 0)
    match_block.match_limit = extra_data->match_limit;
  if ((flags & PCRE_EXTRA_CALLOUT_DATA) != 0)
    match_block.callout_data = extra_data->callout_data;
  if ((flags & PCRE_EXTRA_TABLES) != 0) tables = extra_data->tables;
  }

/* If the exec call supplied NULL for tables, use the inbuilt ones. This
is a feature that makes it possible to save compiled regex and re-use them
in other programs later. */

if (tables == NULL) tables = _pcre_default_tables;

/* Check that the first field in the block is the magic number. If it is not,
test for a regex that was compiled on a host of opposite endianness. If this is
the case, flipped values are put in internal_re and internal_study if there was
study data too. */

if (re->magic_number != MAGIC_NUMBER)
  {
  re = _pcre_try_flipped(re, &internal_re, study, &internal_study);
  if (re == NULL) return PCRE_ERROR_BADMAGIC;
  if (study != NULL) study = &internal_study;
  }

/* Set up other data */

anchored = ((re->options | options) & PCRE_ANCHORED) != 0;
startline = (re->options & PCRE_STARTLINE) != 0;
firstline = (re->options & PCRE_FIRSTLINE) != 0;

/* The code starts after the real_pcre block and the capture name table. */

match_block.start_code = (const uschar *)external_re + re->name_table_offset +
  re->name_count * re->name_entry_size;

match_block.start_subject = (const uschar *)subject;
match_block.start_offset = start_offset;
match_block.end_subject = match_block.start_subject + length;
end_subject = match_block.end_subject;

match_block.endonly = (re->options & PCRE_DOLLAR_ENDONLY) != 0;
match_block.utf8 = (re->options & PCRE_UTF8) != 0;

match_block.notbol = (options & PCRE_NOTBOL) != 0;
match_block.noteol = (options & PCRE_NOTEOL) != 0;
match_block.notempty = (options & PCRE_NOTEMPTY) != 0;
match_block.partial = (options & PCRE_PARTIAL) != 0;
match_block.hitend = FALSE;

match_block.recursive = NULL;                   /* No recursion at top level */

match_block.lcc = tables + lcc_offset;
match_block.ctypes = tables + ctypes_offset;

/* Partial matching is supported only for a restricted set of regexes at the
moment. */

if (match_block.partial && (re->options & PCRE_NOPARTIAL) != 0)
  return PCRE_ERROR_BADPARTIAL;

/* Check a UTF-8 string if required. Unfortunately there's no way of passing
back the character offset. */

#ifdef SUPPORT_UTF8
if (match_block.utf8 && (options & PCRE_NO_UTF8_CHECK) == 0)
  {
  if (_pcre_valid_utf8((uschar *)subject, length) >= 0)
    return PCRE_ERROR_BADUTF8;
  if (start_offset > 0 && start_offset < length)
    {
    int tb = ((uschar *)subject)[start_offset];
    if (tb > 127)
      {
      tb &= 0xc0;
      if (tb != 0 && tb != 0xc0) return PCRE_ERROR_BADUTF8_OFFSET;
      }
    }
  }
#endif

/* The ims options can vary during the matching as a result of the presence
of (?ims) items in the pattern. They are kept in a local variable so that
restoring at the exit of a group is easy. */

ims = re->options & (PCRE_CASELESS|PCRE_MULTILINE|PCRE_DOTALL);

/* If the expression has got more back references than the offsets supplied can
hold, we get a temporary chunk of working store to use during the matching.
Otherwise, we can use the vector supplied, rounding down its size to a multiple
of 3. */

ocount = offsetcount - (offsetcount % 3);

if (re->top_backref > 0 && re->top_backref >= ocount/3)
  {
  ocount = re->top_backref * 3 + 3;
  match_block.offset_vector = (int *)(pcre_malloc)(ocount * sizeof(int));
  if (match_block.offset_vector == NULL) return PCRE_ERROR_NOMEMORY;
  using_temporary_offsets = TRUE;
  DPRINTF(("Got memory to hold back references\n"));
  }
else match_block.offset_vector = offsets;

match_block.offset_end = ocount;
match_block.offset_max = (2*ocount)/3;
match_block.offset_overflow = FALSE;
match_block.capture_last = -1;

/* Compute the minimum number of offsets that we need to reset each time. Doing
this makes a huge difference to execution time when there aren't many brackets
in the pattern. */

resetcount = 2 + re->top_bracket * 2;
if (resetcount > offsetcount) resetcount = ocount;

/* Reset the working variable associated with each extraction. These should
never be used unless previously set, but they get saved and restored, and so we
initialize them to avoid reading uninitialized locations. */

if (match_block.offset_vector != NULL)
  {
  register int *iptr = match_block.offset_vector + ocount;
  register int *iend = iptr - resetcount/2 + 1;
  while (--iptr >= iend) *iptr = -1;
  }

/* Set up the first character to match, if available. The first_byte value is
never set for an anchored regular expression, but the anchoring may be forced
at run time, so we have to test for anchoring. The first char may be unset for
an unanchored pattern, of course. If there's no first char and the pattern was
studied, there may be a bitmap of possible first characters. */

if (!anchored)
  {
  if ((re->options & PCRE_FIRSTSET) != 0)
    {
    first_byte = re->first_byte & 255;
    if ((first_byte_caseless = ((re->first_byte & REQ_CASELESS) != 0)) == TRUE)
      first_byte = match_block.lcc[first_byte];
    }
  else
    if (!startline && study != NULL &&
      (study->options & PCRE_STUDY_MAPPED) != 0)
        start_bits = study->start_bits;
  }

/* For anchored or unanchored matches, there may be a "last known required
character" set. */

if ((re->options & PCRE_REQCHSET) != 0)
  {
  req_byte = re->req_byte & 255;
  req_byte_caseless = (re->req_byte & REQ_CASELESS) != 0;
  req_byte2 = (tables + fcc_offset)[req_byte];  /* case flipped */
  }

/* Loop for handling unanchored repeated matching attempts; for anchored regexs
the loop runs just once. */

do
  {
  const uschar *save_end_subject = end_subject;

  /* Reset the maximum number of extractions we might see. */

  if (match_block.offset_vector != NULL)
    {
    register int *iptr = match_block.offset_vector;
    register int *iend = iptr + resetcount;
    while (iptr < iend) *iptr++ = -1;
    }

  /* Advance to a unique first char if possible. If firstline is TRUE, the
  start of the match is constrained to the first line of a multiline string.
  Implement this by temporarily adjusting end_subject so that we stop scanning
  at a newline. If the match fails at the newline, later code breaks this loop.
  */

  if (firstline)
    {
    const uschar *t = start_match;
    while (t < save_end_subject && *t != '\n') t++;
    end_subject = t;
    }

  /* Now test for a unique first byte */

  if (first_byte >= 0)
    {
    if (first_byte_caseless)
      while (start_match < end_subject &&
             match_block.lcc[*start_match] != first_byte)
        start_match++;
    else
      while (start_match < end_subject && *start_match != first_byte)
        start_match++;
    }

  /* Or to just after \n for a multiline match if possible */

  else if (startline)
    {
    if (start_match > match_block.start_subject + start_offset)
      {
      while (start_match < end_subject && start_match[-1] != NEWLINE)
        start_match++;
      }
    }

  /* Or to a non-unique first char after study */

  else if (start_bits != NULL)
    {
    while (start_match < end_subject)
      {
      register unsigned int c = *start_match;
      if ((start_bits[c/8] & (1 << (c&7))) == 0) start_match++; else break;
      }
    }

  /* Restore fudged end_subject */

  end_subject = save_end_subject;

#ifdef DEBUG  /* Sigh. Some compilers never learn. */
  printf(">>>> Match against: ");
  pchars(start_match, end_subject - start_match, TRUE, &match_block);
  printf("\n");
#endif

  /* If req_byte is set, we know that that character must appear in the subject
  for the match to succeed. If the first character is set, req_byte must be
  later in the subject; otherwise the test starts at the match point. This
  optimization can save a huge amount of backtracking in patterns with nested
  unlimited repeats that aren't going to match. Writing separate code for
  cased/caseless versions makes it go faster, as does using an autoincrement
  and backing off on a match.

  HOWEVER: when the subject string is very, very long, searching to its end can
  take a long time, and give bad performance on quite ordinary patterns. This
  showed up when somebody was matching /^C/ on a 32-megabyte string... so we
  don't do this when the string is sufficiently long.

  ALSO: this processing is disabled when partial matching is requested.
  */

  if (req_byte >= 0 &&
      end_subject - start_match < REQ_BYTE_MAX &&
      !match_block.partial)
    {
    register const uschar *p = start_match + ((first_byte >= 0)? 1 : 0);

    /* We don't need to repeat the search if we haven't yet reached the
    place we found it at last time. */

    if (p > req_byte_ptr)
      {
      if (req_byte_caseless)
        {
        while (p < end_subject)
          {
          register int pp = *p++;
          if (pp == req_byte || pp == req_byte2) { p--; break; }
          }
        }
      else
        {
        while (p < end_subject)
          {
          if (*p++ == req_byte) { p--; break; }
          }
        }

      /* If we can't find the required character, break the matching loop */

      if (p >= end_subject) break;

      /* If we have found the required character, save the point where we
      found it, so that we don't search again next time round the loop if
      the start hasn't passed this character yet. */

      req_byte_ptr = p;
      }
    }

  /* When a match occurs, substrings will be set for all internal extractions;
  we just need to set up the whole thing as substring 0 before returning. If
  there were too many extractions, set the return code to zero. In the case
  where we had to get some local store to hold offsets for backreferences, copy
  those back references that we can. In this case there need not be overflow
  if certain parts of the pattern were not used. */

  match_block.start_match = start_match;
  match_block.match_call_count = 0;

  rc = match(start_match, match_block.start_code, 2, &match_block, ims, NULL,
    match_isgroup);

  /* When the result is no match, if the subject's first character was a
  newline and the PCRE_FIRSTLINE option is set, break (which will return
  PCRE_ERROR_NOMATCH). The option requests that a match occur before the first
  newline in the subject. Otherwise, advance the pointer to the next character
  and continue - but the continuation will actually happen only when the
  pattern is not anchored. */

  if (rc == MATCH_NOMATCH)
    {
    if (firstline && *start_match == NEWLINE) break;
    start_match++;
#ifdef SUPPORT_UTF8
    if (match_block.utf8)
      while(start_match < end_subject && (*start_match & 0xc0) == 0x80)
        start_match++;
#endif
    continue;
    }

  if (rc != MATCH_MATCH)
    {
    DPRINTF((">>>> error: returning %d\n", rc));
    return rc;
    }

  /* We have a match! Copy the offset information from temporary store if
  necessary */

  if (using_temporary_offsets)
    {
    if (offsetcount >= 4)
      {
      memcpy(offsets + 2, match_block.offset_vector + 2,
        (offsetcount - 2) * sizeof(int));
      DPRINTF(("Copied offsets from temporary memory\n"));
      }
    if (match_block.end_offset_top > offsetcount)
      match_block.offset_overflow = TRUE;

    DPRINTF(("Freeing temporary memory\n"));
    (pcre_free)(match_block.offset_vector);
    }

  rc = match_block.offset_overflow? 0 : match_block.end_offset_top/2;

  if (offsetcount < 2) rc = 0; else
    {
    offsets[0] = start_match - match_block.start_subject;
    offsets[1] = match_block.end_match_ptr - match_block.start_subject;
    }

  DPRINTF((">>>> returning %d\n", rc));
  return rc;
  }

/* This "while" is the end of the "do" above */

while (!anchored && start_match <= end_subject);

if (using_temporary_offsets)
  {
  DPRINTF(("Freeing temporary memory\n"));
  (pcre_free)(match_block.offset_vector);
  }

if (match_block.partial && match_block.hitend)
  {
  DPRINTF((">>>> returning PCRE_ERROR_PARTIAL\n"));
  return PCRE_ERROR_PARTIAL;
  }
else
  {
  DPRINTF((">>>> returning PCRE_ERROR_NOMATCH\n"));
  return PCRE_ERROR_NOMATCH;
  }
}

/* End of pcre_exec.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/*PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains the external function pcre_fullinfo(), which returns
information about a compiled pattern. */




/*************************************************
*        Return info about compiled pattern      *
*************************************************/

/* This is a newer "info" function which has an extensible interface so
that additional items can be added compatibly.

Arguments:
  argument_re      points to compiled code
  extra_data       points extra data, or NULL
  what             what information is required
  where            where to put the information

Returns:           0 if data returned, negative on error
*/

EXPORT int
pcre_fullinfo(const pcre *argument_re, const pcre_extra *extra_data, int what,
  void *where)
{
real_pcre internal_re;
pcre_study_data internal_study;
const real_pcre *re = (const real_pcre *)argument_re;
const pcre_study_data *study = NULL;

if (re == NULL || where == NULL) return PCRE_ERROR_NULL;

if (extra_data != NULL && (extra_data->flags & PCRE_EXTRA_STUDY_DATA) != 0)
  study = (const pcre_study_data *)extra_data->study_data;

if (re->magic_number != MAGIC_NUMBER)
  {
  re = _pcre_try_flipped(re, &internal_re, study, &internal_study);
  if (re == NULL) return PCRE_ERROR_BADMAGIC;
  if (study != NULL) study = &internal_study;
  }

switch (what)
  {
  case PCRE_INFO_OPTIONS:
  *((unsigned long int *)where) = re->options & PUBLIC_OPTIONS;
  break;

  case PCRE_INFO_SIZE:
  *((size_t *)where) = re->size;
  break;

  case PCRE_INFO_STUDYSIZE:
  *((size_t *)where) = (study == NULL)? 0 : study->size;
  break;

  case PCRE_INFO_CAPTURECOUNT:
  *((int *)where) = re->top_bracket;
  break;

  case PCRE_INFO_BACKREFMAX:
  *((int *)where) = re->top_backref;
  break;

  case PCRE_INFO_FIRSTBYTE:
  *((int *)where) =
    ((re->options & PCRE_FIRSTSET) != 0)? re->first_byte :
    ((re->options & PCRE_STARTLINE) != 0)? -1 : -2;
  break;

  /* Make sure we pass back the pointer to the bit vector in the external
  block, not the internal copy (with flipped integer fields). */

  case PCRE_INFO_FIRSTTABLE:
  *((const uschar **)where) =
    (study != NULL && (study->options & PCRE_STUDY_MAPPED) != 0)?
      ((const pcre_study_data *)extra_data->study_data)->start_bits : NULL;
  break;

  case PCRE_INFO_LASTLITERAL:
  *((int *)where) =
    ((re->options & PCRE_REQCHSET) != 0)? re->req_byte : -1;
  break;

  case PCRE_INFO_NAMEENTRYSIZE:
  *((int *)where) = re->name_entry_size;
  break;

  case PCRE_INFO_NAMECOUNT:
  *((int *)where) = re->name_count;
  break;

  case PCRE_INFO_NAMETABLE:
  *((const uschar **)where) = (const uschar *)re + re->name_table_offset;
  break;

  case PCRE_INFO_DEFAULT_TABLES:
  *((const uschar **)where) = (const uschar *)(_pcre_default_tables);
  break;

  default: return PCRE_ERROR_BADOPTION;
  }

return 0;
}

/* End of pcre_fullinfo.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains some convenience functions for extracting substrings
from the subject string after a regex match has succeeded. The original idea
for these functions came from Scott Wimer. */




/*************************************************
*           Find number for named string         *
*************************************************/

/* This function is used by the two extraction functions below, as well
as being generally available.

Arguments:
  code        the compiled regex
  stringname  the name whose number is required

Returns:      the number of the named parentheses, or a negative number
                (PCRE_ERROR_NOSUBSTRING) if not found
*/

int
pcre_get_stringnumber(const pcre *code, const char *stringname)
{
int rc;
int entrysize;
int top, bot;
uschar *nametable;

if ((rc = pcre_fullinfo(code, NULL, PCRE_INFO_NAMECOUNT, &top)) != 0)
  return rc;
if (top <= 0) return PCRE_ERROR_NOSUBSTRING;

if ((rc = pcre_fullinfo(code, NULL, PCRE_INFO_NAMEENTRYSIZE, &entrysize)) != 0)
  return rc;
if ((rc = pcre_fullinfo(code, NULL, PCRE_INFO_NAMETABLE, &nametable)) != 0)
  return rc;

bot = 0;
while (top > bot)
  {
  int mid = (top + bot) / 2;
  uschar *entry = nametable + entrysize*mid;
  int c = strcmp(stringname, (char *)(entry + 2));
  if (c == 0) return (entry[0] << 8) + entry[1];
  if (c > 0) bot = mid + 1; else top = mid;
  }

return PCRE_ERROR_NOSUBSTRING;
}



/*************************************************
*      Copy captured string to given buffer      *
*************************************************/

/* This function copies a single captured substring into a given buffer.
Note that we use memcpy() rather than strncpy() in case there are binary zeros
in the string.

Arguments:
  subject        the subject string that was matched
  ovector        pointer to the offsets table
  stringcount    the number of substrings that were captured
                   (i.e. the yield of the pcre_exec call, unless
                   that was zero, in which case it should be 1/3
                   of the offset table size)
  stringnumber   the number of the required substring
  buffer         where to put the substring
  size           the size of the buffer

Returns:         if successful:
                   the length of the copied string, not including the zero
                   that is put on the end; can be zero
                 if not successful:
                   PCRE_ERROR_NOMEMORY (-6) buffer too small
                   PCRE_ERROR_NOSUBSTRING (-7) no such captured substring
*/

int
pcre_copy_substring(const char *subject, int *ovector, int stringcount,
  int stringnumber, char *buffer, int size)
{
int yield;
if (stringnumber < 0 || stringnumber >= stringcount)
  return PCRE_ERROR_NOSUBSTRING;
stringnumber *= 2;
yield = ovector[stringnumber+1] - ovector[stringnumber];
if (size < yield + 1) return PCRE_ERROR_NOMEMORY;
memcpy(buffer, subject + ovector[stringnumber], yield);
buffer[yield] = 0;
return yield;
}



/*************************************************
*   Copy named captured string to given buffer   *
*************************************************/

/* This function copies a single captured substring into a given buffer,
identifying it by name.

Arguments:
  code           the compiled regex
  subject        the subject string that was matched
  ovector        pointer to the offsets table
  stringcount    the number of substrings that were captured
                   (i.e. the yield of the pcre_exec call, unless
                   that was zero, in which case it should be 1/3
                   of the offset table size)
  stringname     the name of the required substring
  buffer         where to put the substring
  size           the size of the buffer

Returns:         if successful:
                   the length of the copied string, not including the zero
                   that is put on the end; can be zero
                 if not successful:
                   PCRE_ERROR_NOMEMORY (-6) buffer too small
                   PCRE_ERROR_NOSUBSTRING (-7) no such captured substring
*/

int
pcre_copy_named_substring(const pcre *code, const char *subject, int *ovector,
  int stringcount, const char *stringname, char *buffer, int size)
{
int n = pcre_get_stringnumber(code, stringname);
if (n <= 0) return n;
return pcre_copy_substring(subject, ovector, stringcount, n, buffer, size);
}



/*************************************************
*      Copy all captured strings to new store    *
*************************************************/

/* This function gets one chunk of store and builds a list of pointers and all
of the captured substrings in it. A NULL pointer is put on the end of the list.

Arguments:
  subject        the subject string that was matched
  ovector        pointer to the offsets table
  stringcount    the number of substrings that were captured
                   (i.e. the yield of the pcre_exec call, unless
                   that was zero, in which case it should be 1/3
                   of the offset table size)
  listptr        set to point to the list of pointers

Returns:         if successful: 0
                 if not successful:
                   PCRE_ERROR_NOMEMORY (-6) failed to get store
*/

int
pcre_get_substring_list(const char *subject, int *ovector, int stringcount,
  const char ***listptr)
{
int i;
int size = sizeof(char *);
int double_count = stringcount * 2;
char **stringlist;
char *p;

for (i = 0; i < double_count; i += 2)
  size += sizeof(char *) + ovector[i+1] - ovector[i] + 1;

stringlist = (char **)(pcre_malloc)(size);
if (stringlist == NULL) return PCRE_ERROR_NOMEMORY;

*listptr = (const char **)stringlist;
p = (char *)(stringlist + stringcount + 1);

for (i = 0; i < double_count; i += 2)
  {
  int len = ovector[i+1] - ovector[i];
  memcpy(p, subject + ovector[i], len);
  *stringlist++ = p;
  p += len;
  *p++ = 0;
  }

*stringlist = NULL;
return 0;
}



/*************************************************
*   Free store obtained by get_substring_list    *
*************************************************/

/* This function exists for the benefit of people calling PCRE from non-C
programs that can call its functions, but not free() or (pcre_free)() directly.

Argument:   the result of a previous pcre_get_substring_list()
Returns:    nothing
*/

void
pcre_free_substring_list(const char **pointer)
{
(pcre_free)((void *)pointer);
}



/*************************************************
*      Copy captured string to new store         *
*************************************************/

/* This function copies a single captured substring into a piece of new
store

Arguments:
  subject        the subject string that was matched
  ovector        pointer to the offsets table
  stringcount    the number of substrings that were captured
                   (i.e. the yield of the pcre_exec call, unless
                   that was zero, in which case it should be 1/3
                   of the offset table size)
  stringnumber   the number of the required substring
  stringptr      where to put a pointer to the substring

Returns:         if successful:
                   the length of the string, not including the zero that
                   is put on the end; can be zero
                 if not successful:
                   PCRE_ERROR_NOMEMORY (-6) failed to get store
                   PCRE_ERROR_NOSUBSTRING (-7) substring not present
*/

int
pcre_get_substring(const char *subject, int *ovector, int stringcount,
  int stringnumber, const char **stringptr)
{
int yield;
char *substring;
if (stringnumber < 0 || stringnumber >= stringcount)
  return PCRE_ERROR_NOSUBSTRING;
stringnumber *= 2;
yield = ovector[stringnumber+1] - ovector[stringnumber];
substring = (char *)(pcre_malloc)(yield + 1);
if (substring == NULL) return PCRE_ERROR_NOMEMORY;
memcpy(substring, subject + ovector[stringnumber], yield);
substring[yield] = 0;
*stringptr = substring;
return yield;
}



/*************************************************
*   Copy named captured string to new store      *
*************************************************/

/* This function copies a single captured substring, identified by name, into
new store.

Arguments:
  code           the compiled regex
  subject        the subject string that was matched
  ovector        pointer to the offsets table
  stringcount    the number of substrings that were captured
                   (i.e. the yield of the pcre_exec call, unless
                   that was zero, in which case it should be 1/3
                   of the offset table size)
  stringname     the name of the required substring
  stringptr      where to put the pointer

Returns:         if successful:
                   the length of the copied string, not including the zero
                   that is put on the end; can be zero
                 if not successful:
                   PCRE_ERROR_NOMEMORY (-6) couldn't get memory
                   PCRE_ERROR_NOSUBSTRING (-7) no such captured substring
*/

int
pcre_get_named_substring(const pcre *code, const char *subject, int *ovector,
  int stringcount, const char *stringname, const char **stringptr)
{
int n = pcre_get_stringnumber(code, stringname);
if (n <= 0) return n;
return pcre_get_substring(subject, ovector, stringcount, n, stringptr);
}




/*************************************************
*       Free store obtained by get_substring     *
*************************************************/

/* This function exists for the benefit of people calling PCRE from non-C
programs that can call its functions, but not free() or (pcre_free)() directly.

Argument:   the result of a previous pcre_get_substring()
Returns:    nothing
*/

void
pcre_free_substring(const char *pointer)
{
(pcre_free)((void *)pointer);
}

/* End of pcre_get.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains global variables that are exported by the PCRE library.
PCRE is thread-clean and doesn't use any global variables in the normal sense.
However, it calls memory allocation and freeing functions via the four
indirections below, and it can optionally do callouts, using the fifth
indirection. These values can be changed by the caller, but are shared between
all threads. However, when compiling for Virtual Pascal, things are done
differently, and global variables are not used (see pcre.in). */




#ifndef VPCOMPAT
#ifdef __cplusplus
extern "C" void *(*pcre_malloc)(size_t) = malloc;
extern "C" void  (*pcre_free)(void *) = free;
extern "C" void *(*pcre_stack_malloc)(size_t) = malloc;
extern "C" void  (*pcre_stack_free)(void *) = free;
extern "C" int   (*pcre_callout)(pcre_callout_block *) = NULL;
#else
void *(*pcre_malloc)(size_t) = malloc;
void  (*pcre_free)(void *) = free;
void *(*pcre_stack_malloc)(size_t) = malloc;
void  (*pcre_stack_free)(void *) = free;
int   (*pcre_callout)(pcre_callout_block *) = NULL;
#endif
#endif

/* End of pcre_globals.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains the external function pcre_info(), which gives some
information about a compiled pattern. However, use of this function is now
deprecated, as it has been superseded by pcre_fullinfo(). */




/*************************************************
* (Obsolete) Return info about compiled pattern  *
*************************************************/

/* This is the original "info" function. It picks potentially useful data out
of the private structure, but its interface was too rigid. It remains for
backwards compatibility. The public options are passed back in an int - though
the re->options field has been expanded to a long int, all the public options
at the low end of it, and so even on 16-bit systems this will still be OK.
Therefore, I haven't changed the API for pcre_info().

Arguments:
  argument_re   points to compiled code
  optptr        where to pass back the options
  first_byte    where to pass back the first character,
                or -1 if multiline and all branches start ^,
                or -2 otherwise

Returns:        number of capturing subpatterns
                or negative values on error
*/

EXPORT int
pcre_info(const pcre *argument_re, int *optptr, int *first_byte)
{
real_pcre internal_re;
const real_pcre *re = (const real_pcre *)argument_re;
if (re == NULL) return PCRE_ERROR_NULL;
if (re->magic_number != MAGIC_NUMBER)
  {
  re = _pcre_try_flipped(re, &internal_re, NULL, NULL);
  if (re == NULL) return PCRE_ERROR_BADMAGIC;
  }
if (optptr != NULL) *optptr = (int)(re->options & PUBLIC_OPTIONS);
if (first_byte != NULL)
  *first_byte = ((re->options & PCRE_FIRSTSET) != 0)? re->first_byte :
     ((re->options & PCRE_STARTLINE) != 0)? -1 : -2;
return re->top_bracket;
}

/* End of pcre_info.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains the external function pcre_maketables(), which builds
character tables for PCRE in the current locale. The file is compiled on its
own as part of the PCRE library. However, it is also included in the
compilation of dftables.c, in which case the macro DFTABLES is defined. */


#ifndef DFTABLES
#endif


/*************************************************
*           Create PCRE character tables         *
*************************************************/

/* This function builds a set of character tables for use by PCRE and returns
a pointer to them. They are build using the ctype functions, and consequently
their contents will depend upon the current locale setting. When compiled as
part of the library, the store is obtained via pcre_malloc(), but when compiled
inside dftables, use malloc().

Arguments:   none
Returns:     pointer to the contiguous block of data
*/

const unsigned char *
pcre_maketables(void)
{
unsigned char *yield, *p;
int i;

#ifndef DFTABLES
yield = (unsigned char*)(pcre_malloc)(tables_length);
#else
yield = (unsigned char*)malloc(tables_length);
#endif

if (yield == NULL) return NULL;
p = yield;

/* First comes the lower casing table */

for (i = 0; i < 256; i++) *p++ = tolower(i);

/* Next the case-flipping table */

for (i = 0; i < 256; i++) *p++ = islower(i)? toupper(i) : tolower(i);

/* Then the character class tables. Don't try to be clever and save effort
on exclusive ones - in some locales things may be different. Note that the
table for "space" includes everything "isspace" gives, including VT in the
default locale. This makes it work for the POSIX class [:space:]. */

memset(p, 0, cbit_length);
for (i = 0; i < 256; i++)
  {
  if (isdigit(i))
    {
    p[cbit_digit  + i/8] |= 1 << (i&7);
    p[cbit_word   + i/8] |= 1 << (i&7);
    }
  if (isupper(i))
    {
    p[cbit_upper  + i/8] |= 1 << (i&7);
    p[cbit_word   + i/8] |= 1 << (i&7);
    }
  if (islower(i))
    {
    p[cbit_lower  + i/8] |= 1 << (i&7);
    p[cbit_word   + i/8] |= 1 << (i&7);
    }
  if (i == '_')   p[cbit_word   + i/8] |= 1 << (i&7);
  if (isspace(i)) p[cbit_space  + i/8] |= 1 << (i&7);
  if (isxdigit(i))p[cbit_xdigit + i/8] |= 1 << (i&7);
  if (isgraph(i)) p[cbit_graph  + i/8] |= 1 << (i&7);
  if (isprint(i)) p[cbit_print  + i/8] |= 1 << (i&7);
  if (ispunct(i)) p[cbit_punct  + i/8] |= 1 << (i&7);
  if (iscntrl(i)) p[cbit_cntrl  + i/8] |= 1 << (i&7);
  }
p += cbit_length;

/* Finally, the character type table. In this, we exclude VT from the white
space chars, because Perl doesn't recognize it as such for \s and for comments
within regexes. */

for (i = 0; i < 256; i++)
  {
  int x = 0;
  if (i != 0x0b && isspace(i)) x += ctype_space;
  if (isalpha(i)) x += ctype_letter;
  if (isdigit(i)) x += ctype_digit;
  if (isxdigit(i)) x += ctype_xdigit;
  if (isalnum(i) || i == '_') x += ctype_word;

  /* Note: strchr includes the terminating zero in the characters it considers.
  In this instance, that is ok because we want binary zero to be flagged as a
  meta-character, which in this sense is any character that terminates a run
  of data characters. */

  if (strchr("*+?{^.$|()[", i) != 0) x += ctype_meta; *p++ = x; }

return yield;
}

/* End of pcre_maketables.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This file contains a private PCRE function that converts an ordinal
character value into a UTF8 string. */




/*************************************************
*       Convert character value to UTF-8         *
*************************************************/

/* This function takes an integer value in the range 0 - 0x7fffffff
and encodes it as a UTF-8 character in 0 to 6 bytes.

Arguments:
  cvalue     the character value
  buffer     pointer to buffer for result - at least 6 bytes long

Returns:     number of characters placed in the buffer
*/

EXPORT int
_pcre_ord2utf8(int cvalue, uschar *buffer)
{
register int i, j;
for (i = 0; i < _pcre_utf8_table1_size; i++)
  if (cvalue <= _pcre_utf8_table1[i]) break;
buffer += i;
for (j = i; j > 0; j--)
 {
 *buffer-- = 0x80 | (cvalue & 0x3f);
 cvalue >>= 6;
 }
*buffer = _pcre_utf8_table2[i] | cvalue;
return i + 1;
}

/* End of pcre_ord2utf8.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains an PCRE private debugging function for printing out the
internal form of a compiled regular expression, along with some supporting
local functions. */




static const char *OP_names[] = { OP_NAME_LIST };


/*************************************************
*       Print single- or multi-byte character    *
*************************************************/

static int
print_char(FILE *f, uschar *ptr, BOOL utf8)
{
int c = *ptr;

if (!utf8 || (c & 0xc0) != 0xc0)
  {
  if (isprint(c)) fprintf(f, "%c", c); else fprintf(f, "\\x%02x", c);
  return 0;
  }
else
  {
  int i;
  int a = _pcre_utf8_table4[c & 0x3f];  /* Number of additional bytes */
  int s = 6*a;
  c = (c & _pcre_utf8_table3[a]) << s;
  for (i = 1; i <= a; i++)
    {
    /* This is a check for malformed UTF-8; it should only occur if the sanity
    check has been turned off. Rather than swallow random bytes, just stop if
    we hit a bad one. Print it with \X instead of \x as an indication. */

    if ((ptr[i] & 0xc0) != 0x80)
      {
      fprintf(f, "\\X{%x}", c);
      return i - 1;
      }

    /* The byte is OK */

    s -= 6;
    c |= (ptr[i] & 0x3f) << s;
    }
  if (c < 128) fprintf(f, "\\x%02x", c); else fprintf(f, "\\x{%x}", c);
  return a;
  }
}



/*************************************************
*          Find Unicode property name            *
*************************************************/

static const char *
get_ucpname(int property)
{
#ifdef SUPPORT_UCP
int i;
for (i = _pcre_utt_size; i >= 0; i--)
  {
  if (property == _pcre_utt[i].value) break;
  }
return (i >= 0)? _pcre_utt[i].name : "??";
#else
return "??";
#endif
}



/*************************************************
*         Print compiled regex                   *
*************************************************/

/* Make this function work for a regex with integers either byte order.
However, we assume that what we are passed is a compiled regex. */

EXPORT void
_pcre_printint(pcre *external_re, FILE *f)
{
real_pcre *re = (real_pcre *)external_re;
uschar *codestart, *code;
BOOL utf8;

unsigned int options = re->options;
int offset = re->name_table_offset;
int count = re->name_count;
int size = re->name_entry_size;

if (re->magic_number != MAGIC_NUMBER)
  {
  offset = ((offset << 8) & 0xff00) | ((offset >> 8) & 0xff);
  count = ((count << 8) & 0xff00) | ((count >> 8) & 0xff);
  size = ((size << 8) & 0xff00) | ((size >> 8) & 0xff);
  options = ((options << 24) & 0xff000000) |
            ((options <<  8) & 0x00ff0000) |
            ((options >>  8) & 0x0000ff00) |
            ((options >> 24) & 0x000000ff);
  }

code = codestart = (uschar *)re + offset + count * size;
utf8 = (options & PCRE_UTF8) != 0;

for(;;)
  {
  uschar *ccode;
  int c;
  int extra = 0;

  fprintf(f, "%3d ", (int)(code - codestart));

  if (*code >= OP_BRA)
    {
    if (*code - OP_BRA > EXTRACT_BASIC_MAX)
      fprintf(f, "%3d Bra extra\n", GET(code, 1));
    else
      fprintf(f, "%3d Bra %d\n", GET(code, 1), *code - OP_BRA);
    code += _pcre_OP_lengths[OP_BRA];
    continue;
    }

  switch(*code)
    {
    case OP_END:
    fprintf(f, "    %s\n", OP_names[*code]);
    fprintf(f, "------------------------------------------------------------------\n");
    return;

    case OP_OPT:
    fprintf(f, " %.2x %s", code[1], OP_names[*code]);
    break;

    case OP_CHAR:
      {
      fprintf(f, "    ");
      do
        {
        code++;
        code += 1 + print_char(f, code, utf8);
        }
      while (*code == OP_CHAR);
      fprintf(f, "\n");
      continue;
      }
    break;

    case OP_CHARNC:
      {
      fprintf(f, " NC ");
      do
        {
        code++;
        code += 1 + print_char(f, code, utf8);
        }
      while (*code == OP_CHARNC);
      fprintf(f, "\n");
      continue;
      }
    break;

    case OP_KETRMAX:
    case OP_KETRMIN:
    case OP_ALT:
    case OP_KET:
    case OP_ASSERT:
    case OP_ASSERT_NOT:
    case OP_ASSERTBACK:
    case OP_ASSERTBACK_NOT:
    case OP_ONCE:
    case OP_COND:
    case OP_REVERSE:
    fprintf(f, "%3d %s", GET(code, 1), OP_names[*code]);
    break;

    case OP_BRANUMBER:
    printf("%3d %s", GET2(code, 1), OP_names[*code]);
    break;

    case OP_CREF:
    if (GET2(code, 1) == CREF_RECURSE)
      fprintf(f, "    Cond recurse");
    else
      fprintf(f, "%3d %s", GET2(code,1), OP_names[*code]);
    break;

    case OP_STAR:
    case OP_MINSTAR:
    case OP_PLUS:
    case OP_MINPLUS:
    case OP_QUERY:
    case OP_MINQUERY:
    case OP_TYPESTAR:
    case OP_TYPEMINSTAR:
    case OP_TYPEPLUS:
    case OP_TYPEMINPLUS:
    case OP_TYPEQUERY:
    case OP_TYPEMINQUERY:
    fprintf(f, "    ");
    if (*code >= OP_TYPESTAR)
      {
      fprintf(f, "%s", OP_names[code[1]]);
      if (code[1] == OP_PROP || code[1] == OP_NOTPROP)
        {
        fprintf(f, " %s ", get_ucpname(code[2]));
        extra = 1;
        }
      }
    else extra = print_char(f, code+1, utf8);
    fprintf(f, "%s", OP_names[*code]);
    break;

    case OP_EXACT:
    case OP_UPTO:
    case OP_MINUPTO:
    fprintf(f, "    ");
    extra = print_char(f, code+3, utf8);
    fprintf(f, "{");
    if (*code != OP_EXACT) fprintf(f, ",");
    fprintf(f, "%d}", GET2(code,1));
    if (*code == OP_MINUPTO) fprintf(f, "?");
    break;

    case OP_TYPEEXACT:
    case OP_TYPEUPTO:
    case OP_TYPEMINUPTO:
    fprintf(f, "    %s", OP_names[code[3]]);
    if (code[3] == OP_PROP || code[3] == OP_NOTPROP)
      {
      fprintf(f, " %s ", get_ucpname(code[4]));
      extra = 1;
      }
    fprintf(f, "{");
    if (*code != OP_TYPEEXACT) fprintf(f, "0,");
    fprintf(f, "%d}", GET2(code,1));
    if (*code == OP_TYPEMINUPTO) fprintf(f, "?");
    break;

    case OP_NOT:
    if (isprint(c = code[1])) fprintf(f, "    [^%c]", c);
      else fprintf(f, "    [^\\x%02x]", c);
    break;

    case OP_NOTSTAR:
    case OP_NOTMINSTAR:
    case OP_NOTPLUS:
    case OP_NOTMINPLUS:
    case OP_NOTQUERY:
    case OP_NOTMINQUERY:
    if (isprint(c = code[1])) fprintf(f, "    [^%c]", c);
      else fprintf(f, "    [^\\x%02x]", c);
    fprintf(f, "%s", OP_names[*code]);
    break;

    case OP_NOTEXACT:
    case OP_NOTUPTO:
    case OP_NOTMINUPTO:
    if (isprint(c = code[3])) fprintf(f, "    [^%c]{", c);
      else fprintf(f, "    [^\\x%02x]{", c);
    if (*code != OP_NOTEXACT) fprintf(f, "0,");
    fprintf(f, "%d}", GET2(code,1));
    if (*code == OP_NOTMINUPTO) fprintf(f, "?");
    break;

    case OP_RECURSE:
    fprintf(f, "%3d %s", GET(code, 1), OP_names[*code]);
    break;

    case OP_REF:
    fprintf(f, "    \\%d", GET2(code,1));
    ccode = code + _pcre_OP_lengths[*code];
    goto CLASS_REF_REPEAT;

    case OP_CALLOUT:
    fprintf(f, "    %s %d %d %d", OP_names[*code], code[1], GET(code,2),
      GET(code, 2 + LINK_SIZE));
    break;

    case OP_PROP:
    case OP_NOTPROP:
    fprintf(f, "    %s %s", OP_names[*code], get_ucpname(code[1]));
    break;

    /* OP_XCLASS can only occur in UTF-8 mode. However, there's no harm in
    having this code always here, and it makes it less messy without all those
    #ifdefs. */

    case OP_CLASS:
    case OP_NCLASS:
    case OP_XCLASS:
      {
      int i, min, max;
      BOOL printmap;

      fprintf(f, "    [");

      if (*code == OP_XCLASS)
        {
        extra = GET(code, 1);
        ccode = code + LINK_SIZE + 1;
        printmap = (*ccode & XCL_MAP) != 0;
        if ((*ccode++ & XCL_NOT) != 0) fprintf(f, "^");
        }
      else
        {
        printmap = TRUE;
        ccode = code + 1;
        }

      /* Print a bit map */

      if (printmap)
        {
        for (i = 0; i < 256; i++)
          {
          if ((ccode[i/8] & (1 << (i&7))) != 0)
            {
            int j;
            for (j = i+1; j < 256; j++)
              if ((ccode[j/8] & (1 << (j&7))) == 0) break;
            if (i == '-' || i == ']') fprintf(f, "\\");
            if (isprint(i)) fprintf(f, "%c", i); else fprintf(f, "\\x%02x", i);
            if (--j > i)
              {
              if (j != i + 1) fprintf(f, "-");
              if (j == '-' || j == ']') fprintf(f, "\\");
              if (isprint(j)) fprintf(f, "%c", j); else fprintf(f, "\\x%02x", j);
              }
            i = j;
            }
          }
        ccode += 32;
        }

      /* For an XCLASS there is always some additional data */

      if (*code == OP_XCLASS)
        {
        int ch;
        while ((ch = *ccode++) != XCL_END)
          {
          if (ch == XCL_PROP)
            {
            fprintf(f, "\\p{%s}", get_ucpname(*ccode++));
            }
          else if (ch == XCL_NOTPROP)
            {
            fprintf(f, "\\P{%s}", get_ucpname(*ccode++));
            }
          else
            {
            ccode += 1 + print_char(f, ccode, TRUE);
            if (ch == XCL_RANGE)
              {
              fprintf(f, "-");
              ccode += 1 + print_char(f, ccode, TRUE);
              }
            }
          }
        }

      /* Indicate a non-UTF8 class which was created by negation */

      fprintf(f, "]%s", (*code == OP_NCLASS)? " (neg)" : "");

      /* Handle repeats after a class or a back reference */

      CLASS_REF_REPEAT:
      switch(*ccode)
        {
        case OP_CRSTAR:
        case OP_CRMINSTAR:
        case OP_CRPLUS:
        case OP_CRMINPLUS:
        case OP_CRQUERY:
        case OP_CRMINQUERY:
        fprintf(f, "%s", OP_names[*ccode]);
        extra += _pcre_OP_lengths[*ccode];
        break;

        case OP_CRRANGE:
        case OP_CRMINRANGE:
        min = GET2(ccode,1);
        max = GET2(ccode,3);
        if (max == 0) fprintf(f, "{%d,}", min);
        else fprintf(f, "{%d,%d}", min, max);
        if (*ccode == OP_CRMINRANGE) fprintf(f, "?");
        extra += _pcre_OP_lengths[*ccode];
        break;
        }
      }
    break;

    /* Anything else is just an item with no data*/

    default:
    fprintf(f, "    %s", OP_names[*code]);
    break;
    }

  code += _pcre_OP_lengths[*code] + extra;
  fprintf(f, "\n");
  }
}

/* End of pcre_printint.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains the external function pcre_refcount(), which is an
auxiliary function that can be used to maintain a reference count in a compiled
pattern data block. This might be helpful in applications where the block is
shared by different users. */



/*************************************************
*           Maintain reference count             *
*************************************************/

/* The reference count is a 16-bit field, initialized to zero. It is not
possible to transfer a non-zero count from one host to a different host that
has a different byte order - though I can't see why anyone in their right mind
would ever want to do that!

Arguments:
  argument_re   points to compiled code
  adjust        value to add to the count

Returns:        the (possibly updated) count value (a non-negative number), or
                a negative error number
*/

EXPORT int
pcre_refcount(pcre *argument_re, int adjust)
{
real_pcre *re = (real_pcre *)argument_re;
if (re == NULL) return PCRE_ERROR_NULL;
re->ref_count = (-adjust > re->ref_count)? 0 :
                (adjust + re->ref_count > 65535)? 65535 :
                re->ref_count + adjust;
return re->ref_count;
}

/* End of pcre_refcount.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains the external function pcre_study(), along with local
supporting functions. */




/*************************************************
*      Set a bit and maybe its alternate case    *
*************************************************/

/* Given a character, set its bit in the table, and also the bit for the other
version of a letter if we are caseless.

Arguments:
  start_bits    points to the bit map
  c             is the character
  caseless      the caseless flag
  cd            the block with char table pointers

Returns:        nothing
*/

static void
set_bit(uschar *start_bits, unsigned int c, BOOL caseless, compile_data *cd)
{
start_bits[c/8] |= (1 << (c&7));
if (caseless && (cd->ctypes[c] & ctype_letter) != 0)
  start_bits[cd->fcc[c]/8] |= (1 << (cd->fcc[c]&7));
}



/*************************************************
*          Create bitmap of starting chars       *
*************************************************/

/* This function scans a compiled unanchored expression and attempts to build a
bitmap of the set of initial characters. If it can't, it returns FALSE. As time
goes by, we may be able to get more clever at doing this.

Arguments:
  code         points to an expression
  start_bits   points to a 32-byte table, initialized to 0
  caseless     the current state of the caseless flag
  utf8         TRUE if in UTF-8 mode
  cd           the block with char table pointers

Returns:       TRUE if table built, FALSE otherwise
*/

static BOOL
set_start_bits(const uschar *code, uschar *start_bits, BOOL caseless,
  BOOL utf8, compile_data *cd)
{
register int c;

/* This next statement and the later reference to dummy are here in order to
trick the optimizer of the IBM C compiler for OS/2 into generating correct
code. Apparently IBM isn't going to fix the problem, and we would rather not
disable optimization (in this module it actually makes a big difference, and
the pcre module can use all the optimization it can get). */

volatile int dummy;

do
  {
  const uschar *tcode = code + 1 + LINK_SIZE;
  BOOL try_next = TRUE;

  while (try_next)
    {
    /* If a branch starts with a bracket or a positive lookahead assertion,
    recurse to set bits from within them. That's all for this branch. */

    if ((int)*tcode >= OP_BRA || *tcode == OP_ASSERT)
      {
      if (!set_start_bits(tcode, start_bits, caseless, utf8, cd))
        return FALSE;
      try_next = FALSE;
      }

    else switch(*tcode)
      {
      default:
      return FALSE;

      /* Skip over callout */

      case OP_CALLOUT:
      tcode += 2 + 2*LINK_SIZE;
      break;

      /* Skip over extended extraction bracket number */

      case OP_BRANUMBER:
      tcode += 3;
      break;

      /* Skip over lookbehind and negative lookahead assertions */

      case OP_ASSERT_NOT:
      case OP_ASSERTBACK:
      case OP_ASSERTBACK_NOT:
      do tcode += GET(tcode, 1); while (*tcode == OP_ALT);
      tcode += 1+LINK_SIZE;
      break;

      /* Skip over an option setting, changing the caseless flag */

      case OP_OPT:
      caseless = (tcode[1] & PCRE_CASELESS) != 0;
      tcode += 2;
      break;

      /* BRAZERO does the bracket, but carries on. */

      case OP_BRAZERO:
      case OP_BRAMINZERO:
      if (!set_start_bits(++tcode, start_bits, caseless, utf8, cd))
        return FALSE;
      dummy = 1;
      do tcode += GET(tcode,1); while (*tcode == OP_ALT);
      tcode += 1+LINK_SIZE;
      break;

      /* Single-char * or ? sets the bit and tries the next item */

      case OP_STAR:
      case OP_MINSTAR:
      case OP_QUERY:
      case OP_MINQUERY:
      set_bit(start_bits, tcode[1], caseless, cd);
      tcode += 2;
#ifdef SUPPORT_UTF8
      if (utf8) while ((*tcode & 0xc0) == 0x80) tcode++;
#endif
      break;

      /* Single-char upto sets the bit and tries the next */

      case OP_UPTO:
      case OP_MINUPTO:
      set_bit(start_bits, tcode[3], caseless, cd);
      tcode += 4;
#ifdef SUPPORT_UTF8
      if (utf8) while ((*tcode & 0xc0) == 0x80) tcode++;
#endif
      break;

      /* At least one single char sets the bit and stops */

      case OP_EXACT:       /* Fall through */
      tcode += 2;

      case OP_CHAR:
      case OP_CHARNC:
      case OP_PLUS:
      case OP_MINPLUS:
      set_bit(start_bits, tcode[1], caseless, cd);
      try_next = FALSE;
      break;

      /* Single character type sets the bits and stops */

      case OP_NOT_DIGIT:
      for (c = 0; c < 32; c++)
        start_bits[c] |= ~cd->cbits[c+cbit_digit];
      try_next = FALSE;
      break;

      case OP_DIGIT:
      for (c = 0; c < 32; c++)
        start_bits[c] |= cd->cbits[c+cbit_digit];
      try_next = FALSE;
      break;

      case OP_NOT_WHITESPACE:
      for (c = 0; c < 32; c++)
        start_bits[c] |= ~cd->cbits[c+cbit_space];
      try_next = FALSE;
      break;

      case OP_WHITESPACE:
      for (c = 0; c < 32; c++)
        start_bits[c] |= cd->cbits[c+cbit_space];
      try_next = FALSE;
      break;

      case OP_NOT_WORDCHAR:
      for (c = 0; c < 32; c++)
        start_bits[c] |= ~cd->cbits[c+cbit_word];
      try_next = FALSE;
      break;

      case OP_WORDCHAR:
      for (c = 0; c < 32; c++)
        start_bits[c] |= cd->cbits[c+cbit_word];
      try_next = FALSE;
      break;

      /* One or more character type fudges the pointer and restarts, knowing
      it will hit a single character type and stop there. */

      case OP_TYPEPLUS:
      case OP_TYPEMINPLUS:
      tcode++;
      break;

      case OP_TYPEEXACT:
      tcode += 3;
      break;

      /* Zero or more repeats of character types set the bits and then
      try again. */

      case OP_TYPEUPTO:
      case OP_TYPEMINUPTO:
      tcode += 2;               /* Fall through */

      case OP_TYPESTAR:
      case OP_TYPEMINSTAR:
      case OP_TYPEQUERY:
      case OP_TYPEMINQUERY:
      switch(tcode[1])
        {
        case OP_ANY:
        return FALSE;

        case OP_NOT_DIGIT:
        for (c = 0; c < 32; c++)
          start_bits[c] |= ~cd->cbits[c+cbit_digit];
        break;

        case OP_DIGIT:
        for (c = 0; c < 32; c++)
          start_bits[c] |= cd->cbits[c+cbit_digit];
        break;

        case OP_NOT_WHITESPACE:
        for (c = 0; c < 32; c++)
          start_bits[c] |= ~cd->cbits[c+cbit_space];
        break;

        case OP_WHITESPACE:
        for (c = 0; c < 32; c++)
          start_bits[c] |= cd->cbits[c+cbit_space];
        break;

        case OP_NOT_WORDCHAR:
        for (c = 0; c < 32; c++)
          start_bits[c] |= ~cd->cbits[c+cbit_word];
        break;

        case OP_WORDCHAR:
        for (c = 0; c < 32; c++)
          start_bits[c] |= cd->cbits[c+cbit_word];
        break;
        }

      tcode += 2;
      break;

      /* Character class where all the information is in a bit map: set the
      bits and either carry on or not, according to the repeat count. If it was
      a negative class, and we are operating with UTF-8 characters, any byte
      with a value >= 0xc4 is a potentially valid starter because it starts a
      character with a value > 255. */

      case OP_NCLASS:
      if (utf8)
        {
        start_bits[24] |= 0xf0;              /* Bits for 0xc4 - 0xc8 */
        memset(start_bits+25, 0xff, 7);      /* Bits for 0xc9 - 0xff */
        }
      /* Fall through */

      case OP_CLASS:
        {
        tcode++;

        /* In UTF-8 mode, the bits in a bit map correspond to character
        values, not to byte values. However, the bit map we are constructing is
        for byte values. So we have to do a conversion for characters whose
        value is > 127. In fact, there are only two possible starting bytes for
        characters in the range 128 - 255. */

        if (utf8)
          {
          for (c = 0; c < 16; c++) start_bits[c] |= tcode[c];
          for (c = 128; c < 256; c++)
            {
            if ((tcode[c/8] && (1 << (c&7))) != 0)
              {
              int d = (c >> 6) | 0xc0;            /* Set bit for this starter */
              start_bits[d/8] |= (1 << (d&7));    /* and then skip on to the */
              c = (c & 0xc0) + 0x40 - 1;          /* next relevant character. */
              }
            }
          }

        /* In non-UTF-8 mode, the two bit maps are completely compatible. */

        else
          {
          for (c = 0; c < 32; c++) start_bits[c] |= tcode[c];
          }

        /* Advance past the bit map, and act on what follows */

        tcode += 32;
        switch (*tcode)
          {
          case OP_CRSTAR:
          case OP_CRMINSTAR:
          case OP_CRQUERY:
          case OP_CRMINQUERY:
          tcode++;
          break;

          case OP_CRRANGE:
          case OP_CRMINRANGE:
          if (((tcode[1] << 8) + tcode[2]) == 0) tcode += 5;
            else try_next = FALSE;
          break;

          default:
          try_next = FALSE;
          break;
          }
        }
      break; /* End of bitmap class handling */

      }      /* End of switch */
    }        /* End of try_next loop */

  code += GET(code, 1);   /* Advance to next branch */
  }
while (*code == OP_ALT);
return TRUE;
}



/*************************************************
*          Study a compiled expression           *
*************************************************/

/* This function is handed a compiled expression that it must study to produce
information that will speed up the matching. It returns a pcre_extra block
which then gets handed back to pcre_exec().

Arguments:
  re        points to the compiled expression
  options   contains option bits
  errorptr  points to where to place error messages;
            set NULL unless error

Returns:    pointer to a pcre_extra block, with study_data filled in and the
              appropriate flag set;
            NULL on error or if no optimization possible
*/

EXPORT pcre_extra *
pcre_study(const pcre *external_re, int options, const char **errorptr)
{
uschar start_bits[32];
pcre_extra *extra;
pcre_study_data *study;
const uschar *tables;
const real_pcre *re = (const real_pcre *)external_re;
uschar *code = (uschar *)re + re->name_table_offset +
  (re->name_count * re->name_entry_size);
compile_data compile_block;

*errorptr = NULL;

if (re == NULL || re->magic_number != MAGIC_NUMBER)
  {
  *errorptr = "argument is not a compiled regular expression";
  return NULL;
  }

if ((options & ~PUBLIC_STUDY_OPTIONS) != 0)
  {
  *errorptr = "unknown or incorrect option bit(s) set";
  return NULL;
  }

/* For an anchored pattern, or an unanchored pattern that has a first char, or
a multiline pattern that matches only at "line starts", no further processing
at present. */

if ((re->options & (PCRE_ANCHORED|PCRE_FIRSTSET|PCRE_STARTLINE)) != 0)
  return NULL;

/* Set the character tables in the block that is passed around */

tables = re->tables;
if (tables == NULL)
  (void)pcre_fullinfo(external_re, NULL, PCRE_INFO_DEFAULT_TABLES,
  (void *)(&tables));

compile_block.lcc = tables + lcc_offset;
compile_block.fcc = tables + fcc_offset;
compile_block.cbits = tables + cbits_offset;
compile_block.ctypes = tables + ctypes_offset;

/* See if we can find a fixed set of initial characters for the pattern. */

memset(start_bits, 0, 32 * sizeof(uschar));
if (!set_start_bits(code, start_bits, (re->options & PCRE_CASELESS) != 0,
  (re->options & PCRE_UTF8) != 0, &compile_block)) return NULL;

/* Get a pcre_extra block and a pcre_study_data block. The study data is put in
the latter, which is pointed to by the former, which may also get additional
data set later by the calling program. At the moment, the size of
pcre_study_data is fixed. We nevertheless save it in a field for returning via
the pcre_fullinfo() function so that if it becomes variable in the future, we
don't have to change that code. */

extra = (pcre_extra *)(pcre_malloc)
  (sizeof(pcre_extra) + sizeof(pcre_study_data));

if (extra == NULL)
  {
  *errorptr = "failed to get memory";
  return NULL;
  }

study = (pcre_study_data *)((char *)extra + sizeof(pcre_extra));
extra->flags = PCRE_EXTRA_STUDY_DATA;
extra->study_data = study;

study->size = sizeof(pcre_study_data);
study->options = PCRE_STUDY_MAPPED;
memcpy(study->start_bits, start_bits, sizeof(start_bits));

return extra;
}

/* End of pcre_study.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains some fixed tables that are used by more than one of the
PCRE code modules. */




/* Table of sizes for the fixed-length opcodes. It's defined in a macro so that
the definition is next to the definition of the opcodes in internal.h. */

const uschar _pcre_OP_lengths[] = { OP_LENGTHS };



/*************************************************
*           Tables for UTF-8 support             *
*************************************************/

/* These are the breakpoints for different numbers of bytes in a UTF-8
character. */

const int _pcre_utf8_table1[] =
  { 0x7f, 0x7ff, 0xffff, 0x1fffff, 0x3ffffff, 0x7fffffff};

const int _pcre_utf8_table1_size = sizeof(_pcre_utf8_table1)/sizeof(int);

/* These are the indicator bits and the mask for the data bits to set in the
first byte of a character, indexed by the number of additional bytes. */

const int _pcre_utf8_table2[] = { 0,    0xc0, 0xe0, 0xf0, 0xf8, 0xfc};
const int _pcre_utf8_table3[] = { 0xff, 0x1f, 0x0f, 0x07, 0x03, 0x01};

/* Table of the number of extra characters, indexed by the first character
masked with 0x3f. The highest number for a valid UTF-8 character is in fact
0x3d. */

const uschar _pcre_utf8_table4[] = {
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
  3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5 };

/* This table translates Unicode property names into code values for the
ucp_findchar() function. It is used by pcretest as well as by the library
functions. */

const ucp_type_table _pcre_utt[] = {
  { "C",  128 + ucp_C },
  { "Cc", ucp_Cc },
  { "Cf", ucp_Cf },
  { "Cn", ucp_Cn },
  { "Co", ucp_Co },
  { "Cs", ucp_Cs },
  { "L",  128 + ucp_L },
  { "Ll", ucp_Ll },
  { "Lm", ucp_Lm },
  { "Lo", ucp_Lo },
  { "Lt", ucp_Lt },
  { "Lu", ucp_Lu },
  { "M",  128 + ucp_M },
  { "Mc", ucp_Mc },
  { "Me", ucp_Me },
  { "Mn", ucp_Mn },
  { "N",  128 + ucp_N },
  { "Nd", ucp_Nd },
  { "Nl", ucp_Nl },
  { "No", ucp_No },
  { "P",  128 + ucp_P },
  { "Pc", ucp_Pc },
  { "Pd", ucp_Pd },
  { "Pe", ucp_Pe },
  { "Pf", ucp_Pf },
  { "Pi", ucp_Pi },
  { "Po", ucp_Po },
  { "Ps", ucp_Ps },
  { "S",  128 + ucp_S },
  { "Sc", ucp_Sc },
  { "Sk", ucp_Sk },
  { "Sm", ucp_Sm },
  { "So", ucp_So },
  { "Z",  128 + ucp_Z },
  { "Zl", ucp_Zl },
  { "Zp", ucp_Zp },
  { "Zs", ucp_Zs }
};

const int _pcre_utt_size = sizeof(_pcre_utt)/sizeof(ucp_type_table);

/* End of pcre_tables.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains an internal function that tests a compiled pattern to
see if it was compiled with the opposite endianness. If so, it uses an
auxiliary local function to flip the appropriate bytes. */




/*************************************************
*         Flip bytes in an integer               *
*************************************************/

/* This function is called when the magic number in a regex doesn't match, in
order to flip its bytes to see if we are dealing with a pattern that was
compiled on a host of different endianness. If so, this function is used to
flip other byte values.

Arguments:
  value        the number to flip
  n            the number of bytes to flip (assumed to be 2 or 4)

Returns:       the flipped value
*/

static long int
byteflip(long int value, int n)
{
if (n == 2) return ((value & 0x00ff) << 8) | ((value & 0xff00) >> 8);
return ((value & 0x000000ff) << 24) |
       ((value & 0x0000ff00) <<  8) |
       ((value & 0x00ff0000) >>  8) |
       ((value & 0xff000000) >> 24);
}



/*************************************************
*       Test for a byte-flipped compiled regex   *
*************************************************/

/* This function is called from pcre_exec(), pcre_dfa_exec(), and also from
pcre_fullinfo(). Its job is to test whether the regex is byte-flipped - that
is, it was compiled on a system of opposite endianness. The function is called
only when the native MAGIC_NUMBER test fails. If the regex is indeed flipped,
we flip all the relevant values into a different data block, and return it.

Arguments:
  re               points to the regex
  study            points to study data, or NULL
  internal_re      points to a new regex block
  internal_study   points to a new study block

Returns:           the new block if is is indeed a byte-flipped regex
                   NULL if it is not
*/

EXPORT real_pcre *
_pcre_try_flipped(const real_pcre *re, real_pcre *internal_re,
  const pcre_study_data *study, pcre_study_data *internal_study)
{
if (byteflip(re->magic_number, sizeof(re->magic_number)) != MAGIC_NUMBER)
  return NULL;

*internal_re = *re;           /* To copy other fields */
internal_re->size = byteflip(re->size, sizeof(re->size));
internal_re->options = byteflip(re->options, sizeof(re->options));
internal_re->top_bracket =
  (pcre_uint16)byteflip(re->top_bracket, sizeof(re->top_bracket));
internal_re->top_backref =
  (pcre_uint16)byteflip(re->top_backref, sizeof(re->top_backref));
internal_re->first_byte =
  (pcre_uint16)byteflip(re->first_byte, sizeof(re->first_byte));
internal_re->req_byte =
  (pcre_uint16)byteflip(re->req_byte, sizeof(re->req_byte));
internal_re->name_table_offset =
  (pcre_uint16)byteflip(re->name_table_offset, sizeof(re->name_table_offset));
internal_re->name_entry_size =
  (pcre_uint16)byteflip(re->name_entry_size, sizeof(re->name_entry_size));
internal_re->name_count =
  (pcre_uint16)byteflip(re->name_count, sizeof(re->name_count));

if (study != NULL)
  {
  *internal_study = *study;   /* To copy other fields */
  internal_study->size = byteflip(study->size, sizeof(study->size));
  internal_study->options = byteflip(study->options, sizeof(study->options));
  }

return internal_re;
}

/* End of pcre_tryflipped.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module compiles code for supporting the use of Unicode character
properties. We use the (embryonic at the time of writing) UCP library, by
including some of its files, copies of which have been put in the PCRE
distribution. There is a macro in pcre_internal.h that changes the name
ucp_findchar into _pcre_ucp_findchar. */



/*************************************************
*     libucp - Unicode Property Table handler    *
*************************************************/

/* Copyright (c) University of Cambridge 2004 */

/* This little library provides a fast way of obtaining the basic Unicode
properties of a character, using a compact binary tree that occupies less than
100K bytes.

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/*************************************************
*     libucp - Unicode Property Table handler    *
*************************************************/

/* Internal header file defining the layout of compact nodes in the tree. */

typedef struct cnode {
  unsigned short int f0;
  unsigned short int f1;
  unsigned short int f2;
} cnode;

/* Things for the f0 field */

#define f0_leftexists   0x8000    /* Left child exists */
#define f0_typemask     0x3f00    /* Type bits */
#define f0_typeshift         8    /* Type shift */
#define f0_chhmask      0x00ff    /* Character high bits */

/* Things for the f2 field */

#define f2_rightmask    0xf000    /* Mask for right offset bits */
#define f2_rightshift       12    /* Shift for right offset */
#define f2_casemask     0x0fff    /* Mask for case offset */

/* The tree consists of a vector of structures of type cnode, with the root
node as the first element. The three short ints (16-bits) are used as follows:

(f0) (1) The 0x8000 bit of f0 is set if a left child exists. The child's node
         is the next node in the vector.
     (2) The 0x4000 bits of f0 is spare.
     (3) The 0x3f00 bits of f0 contain the character type; this is a number
         defined by the enumeration in ucp.h (e.g. ucp_Lu).
     (4) The bottom 8 bits of f0 contain the most significant byte of the
         character's 24-bit codepoint.

(f1) (1) The f1 field contains the two least significant bytes of the
         codepoint.

(f2) (1) The 0xf000 bits of f2 contain zero if there is no right child of this
         node. Otherwise, they contain one plus the exponent of the power of
         two of the offset to the right node (e.g. a value of 3 means 8). The
         units of the offset are node items.

     (2) The 0x0fff bits of f2 contain the signed offset from this character to
         its alternate cased value. They are zero if there is no such
         character.


-----------------------------------------------------------------------------
||.|.| type (6) | ms char (8) ||  ls char (16)  ||....|  case offset (12)  ||
-----------------------------------------------------------------------------
  | |                                              |
  | |-> spare                                      |
  |                                        exponent of right
  |-> left child exists                       child offset


The upper/lower casing information is set only for characters that come in
pairs. There are (at present) four non-one-to-one mappings in the Unicode data.
These are ignored. They are:

  1FBE Greek Prosgegrammeni (lower, with upper -> capital iota)
  2126 Ohm
  212A Kelvin
  212B Angstrom

Certainly for the last three, having an alternate case would seem to be a
mistake. I don't know any Greek, so cannot comment on the first one.


When searching the tree, proceed as follows:

(1) Start at the first node.

(2) Extract the character value from f1 and the bottom 8 bits of f0;

(3) Compare with the character being sought. If equal, we are done.

(4) If the test character is smaller, inspect the f0_leftexists flag. If it is
    not set, the character is not in the tree. If it is set, move to the next
    node, and go to (2).

(5) If the test character is bigger, extract the f2_rightmask bits from f2, and
    shift them right by f2_rightshift. If the result is zero, the character is
    not in the tree. Otherwise, calculate the number of nodes to skip by
    shifting the value 1 left by this number minus one. Go to (2).
*/


/* End of internal.h */
/* This source module is automatically generated from the Unicode
property table. See internal.h for a description of the layout. */

static cnode ucp_table[] = {
  { 0x9a00, 0x2f1f, 0xe000 },
  { 0x8700, 0x1558, 0xd000 },
  { 0x8700, 0x0a99, 0xc000 },
  { 0x8500, 0x0435, 0xbfe0 },
  { 0x8500, 0x01ff, 0xafff },
  { 0x8500, 0x00ff, 0x9079 },
  { 0x8000, 0x007f, 0x8000 },
  { 0x9500, 0x003f, 0x7000 },
  { 0x8000, 0x001f, 0x6000 },
  { 0x8000, 0x000f, 0x5000 },
  { 0x8000, 0x0007, 0x4000 },
  { 0x8000, 0x0003, 0x3000 },
  { 0x8000, 0x0001, 0x2000 },
  { 0x0000, 0x0000, 0x0000 },
  { 0x0000, 0x0002, 0x0000 },
  { 0x8000, 0x0005, 0x2000 },
  { 0x0000, 0x0004, 0x0000 },
  { 0x0000, 0x0006, 0x0000 },
  { 0x8000, 0x000b, 0x3000 },
  { 0x8000, 0x0009, 0x2000 },
  { 0x0000, 0x0008, 0x0000 },
  { 0x0000, 0x000a, 0x0000 },
  { 0x8000, 0x000d, 0x2000 },
  { 0x0000, 0x000c, 0x0000 },
  { 0x0000, 0x000e, 0x0000 },
  { 0x8000, 0x0017, 0x4000 },
  { 0x8000, 0x0013, 0x3000 },
  { 0x8000, 0x0011, 0x2000 },
  { 0x0000, 0x0010, 0x0000 },
  { 0x0000, 0x0012, 0x0000 },
  { 0x8000, 0x0015, 0x2000 },
  { 0x0000, 0x0014, 0x0000 },
  { 0x0000, 0x0016, 0x0000 },
  { 0x8000, 0x001b, 0x3000 },
  { 0x8000, 0x0019, 0x2000 },
  { 0x0000, 0x0018, 0x0000 },
  { 0x0000, 0x001a, 0x0000 },
  { 0x8000, 0x001d, 0x2000 },
  { 0x0000, 0x001c, 0x0000 },
  { 0x0000, 0x001e, 0x0000 },
  { 0x9500, 0x002f, 0x5000 },
  { 0x9500, 0x0027, 0x4000 },
  { 0x9500, 0x0023, 0x3000 },
  { 0x9500, 0x0021, 0x2000 },
  { 0x1d00, 0x0020, 0x0000 },
  { 0x1500, 0x0022, 0x0000 },
  { 0x9500, 0x0025, 0x2000 },
  { 0x1700, 0x0024, 0x0000 },
  { 0x1500, 0x0026, 0x0000 },
  { 0x9900, 0x002b, 0x3000 },
  { 0x9200, 0x0029, 0x2000 },
  { 0x1600, 0x0028, 0x0000 },
  { 0x1500, 0x002a, 0x0000 },
  { 0x9100, 0x002d, 0x2000 },
  { 0x1500, 0x002c, 0x0000 },
  { 0x1500, 0x002e, 0x0000 },
  { 0x8d00, 0x0037, 0x4000 },
  { 0x8d00, 0x0033, 0x3000 },
  { 0x8d00, 0x0031, 0x2000 },
  { 0x0d00, 0x0030, 0x0000 },
  { 0x0d00, 0x0032, 0x0000 },
  { 0x8d00, 0x0035, 0x2000 },
  { 0x0d00, 0x0034, 0x0000 },
  { 0x0d00, 0x0036, 0x0000 },
  { 0x9500, 0x003b, 0x3000 },
  { 0x8d00, 0x0039, 0x2000 },
  { 0x0d00, 0x0038, 0x0000 },
  { 0x1500, 0x003a, 0x0000 },
  { 0x9900, 0x003d, 0x2000 },
  { 0x1900, 0x003c, 0x0000 },
  { 0x1900, 0x003e, 0x0000 },
  { 0x9000, 0x005f, 0x6000 },
  { 0x8900, 0x004f, 0x5020 },
  { 0x8900, 0x0047, 0x4020 },
  { 0x8900, 0x0043, 0x3020 },
  { 0x8900, 0x0041, 0x2020 },
  { 0x1500, 0x0040, 0x0000 },
  { 0x0900, 0x0042, 0x0020 },
  { 0x8900, 0x0045, 0x2020 },
  { 0x0900, 0x0044, 0x0020 },
  { 0x0900, 0x0046, 0x0020 },
  { 0x8900, 0x004b, 0x3020 },
  { 0x8900, 0x0049, 0x2020 },
  { 0x0900, 0x0048, 0x0020 },
  { 0x0900, 0x004a, 0x0020 },
  { 0x8900, 0x004d, 0x2020 },
  { 0x0900, 0x004c, 0x0020 },
  { 0x0900, 0x004e, 0x0020 },
  { 0x8900, 0x0057, 0x4020 },
  { 0x8900, 0x0053, 0x3020 },
  { 0x8900, 0x0051, 0x2020 },
  { 0x0900, 0x0050, 0x0020 },
  { 0x0900, 0x0052, 0x0020 },
  { 0x8900, 0x0055, 0x2020 },
  { 0x0900, 0x0054, 0x0020 },
  { 0x0900, 0x0056, 0x0020 },
  { 0x9600, 0x005b, 0x3000 },
  { 0x8900, 0x0059, 0x2020 },
  { 0x0900, 0x0058, 0x0020 },
  { 0x0900, 0x005a, 0x0020 },
  { 0x9200, 0x005d, 0x2000 },
  { 0x1500, 0x005c, 0x0000 },
  { 0x1800, 0x005e, 0x0000 },
  { 0x8500, 0x006f, 0x5fe0 },
  { 0x8500, 0x0067, 0x4fe0 },
  { 0x8500, 0x0063, 0x3fe0 },
  { 0x8500, 0x0061, 0x2fe0 },
  { 0x1800, 0x0060, 0x0000 },
  { 0x0500, 0x0062, 0x0fe0 },
  { 0x8500, 0x0065, 0x2fe0 },
  { 0x0500, 0x0064, 0x0fe0 },
  { 0x0500, 0x0066, 0x0fe0 },
  { 0x8500, 0x006b, 0x3fe0 },
  { 0x8500, 0x0069, 0x2fe0 },
  { 0x0500, 0x0068, 0x0fe0 },
  { 0x0500, 0x006a, 0x0fe0 },
  { 0x8500, 0x006d, 0x2fe0 },
  { 0x0500, 0x006c, 0x0fe0 },
  { 0x0500, 0x006e, 0x0fe0 },
  { 0x8500, 0x0077, 0x4fe0 },
  { 0x8500, 0x0073, 0x3fe0 },
  { 0x8500, 0x0071, 0x2fe0 },
  { 0x0500, 0x0070, 0x0fe0 },
  { 0x0500, 0x0072, 0x0fe0 },
  { 0x8500, 0x0075, 0x2fe0 },
  { 0x0500, 0x0074, 0x0fe0 },
  { 0x0500, 0x0076, 0x0fe0 },
  { 0x9600, 0x007b, 0x3000 },
  { 0x8500, 0x0079, 0x2fe0 },
  { 0x0500, 0x0078, 0x0fe0 },
  { 0x0500, 0x007a, 0x0fe0 },
  { 0x9200, 0x007d, 0x2000 },
  { 0x1900, 0x007c, 0x0000 },
  { 0x1900, 0x007e, 0x0000 },
  { 0x9500, 0x00bf, 0x7000 },
  { 0x8000, 0x009f, 0x6000 },
  { 0x8000, 0x008f, 0x5000 },
  { 0x8000, 0x0087, 0x4000 },
  { 0x8000, 0x0083, 0x3000 },
  { 0x8000, 0x0081, 0x2000 },
  { 0x0000, 0x0080, 0x0000 },
  { 0x0000, 0x0082, 0x0000 },
  { 0x8000, 0x0085, 0x2000 },
  { 0x0000, 0x0084, 0x0000 },
  { 0x0000, 0x0086, 0x0000 },
  { 0x8000, 0x008b, 0x3000 },
  { 0x8000, 0x0089, 0x2000 },
  { 0x0000, 0x0088, 0x0000 },
  { 0x0000, 0x008a, 0x0000 },
  { 0x8000, 0x008d, 0x2000 },
  { 0x0000, 0x008c, 0x0000 },
  { 0x0000, 0x008e, 0x0000 },
  { 0x8000, 0x0097, 0x4000 },
  { 0x8000, 0x0093, 0x3000 },
  { 0x8000, 0x0091, 0x2000 },
  { 0x0000, 0x0090, 0x0000 },
  { 0x0000, 0x0092, 0x0000 },
  { 0x8000, 0x0095, 0x2000 },
  { 0x0000, 0x0094, 0x0000 },
  { 0x0000, 0x0096, 0x0000 },
  { 0x8000, 0x009b, 0x3000 },
  { 0x8000, 0x0099, 0x2000 },
  { 0x0000, 0x0098, 0x0000 },
  { 0x0000, 0x009a, 0x0000 },
  { 0x8000, 0x009d, 0x2000 },
  { 0x0000, 0x009c, 0x0000 },
  { 0x0000, 0x009e, 0x0000 },
  { 0x9800, 0x00af, 0x5000 },
  { 0x9a00, 0x00a7, 0x4000 },
  { 0x9700, 0x00a3, 0x3000 },
  { 0x9500, 0x00a1, 0x2000 },
  { 0x1d00, 0x00a0, 0x0000 },
  { 0x1700, 0x00a2, 0x0000 },
  { 0x9700, 0x00a5, 0x2000 },
  { 0x1700, 0x00a4, 0x0000 },
  { 0x1a00, 0x00a6, 0x0000 },
  { 0x9400, 0x00ab, 0x3000 },
  { 0x9a00, 0x00a9, 0x2000 },
  { 0x1800, 0x00a8, 0x0000 },
  { 0x0500, 0x00aa, 0x0000 },
  { 0x8100, 0x00ad, 0x2000 },
  { 0x1900, 0x00ac, 0x0000 },
  { 0x1a00, 0x00ae, 0x0000 },
  { 0x9500, 0x00b7, 0x4000 },
  { 0x8f00, 0x00b3, 0x3000 },
  { 0x9900, 0x00b1, 0x2000 },
  { 0x1a00, 0x00b0, 0x0000 },
  { 0x0f00, 0x00b2, 0x0000 },
  { 0x8500, 0x00b5, 0x22e7 },
  { 0x1800, 0x00b4, 0x0000 },
  { 0x1a00, 0x00b6, 0x0000 },
  { 0x9300, 0x00bb, 0x3000 },
  { 0x8f00, 0x00b9, 0x2000 },
  { 0x1800, 0x00b8, 0x0000 },
  { 0x0500, 0x00ba, 0x0000 },
  { 0x8f00, 0x00bd, 0x2000 },
  { 0x0f00, 0x00bc, 0x0000 },
  { 0x0f00, 0x00be, 0x0000 },
  { 0x8500, 0x00df, 0x6000 },
  { 0x8900, 0x00cf, 0x5020 },
  { 0x8900, 0x00c7, 0x4020 },
  { 0x8900, 0x00c3, 0x3020 },
  { 0x8900, 0x00c1, 0x2020 },
  { 0x0900, 0x00c0, 0x0020 },
  { 0x0900, 0x00c2, 0x0020 },
  { 0x8900, 0x00c5, 0x2020 },
  { 0x0900, 0x00c4, 0x0020 },
  { 0x0900, 0x00c6, 0x0020 },
  { 0x8900, 0x00cb, 0x3020 },
  { 0x8900, 0x00c9, 0x2020 },
  { 0x0900, 0x00c8, 0x0020 },
  { 0x0900, 0x00ca, 0x0020 },
  { 0x8900, 0x00cd, 0x2020 },
  { 0x0900, 0x00cc, 0x0020 },
  { 0x0900, 0x00ce, 0x0020 },
  { 0x9900, 0x00d7, 0x4000 },
  { 0x8900, 0x00d3, 0x3020 },
  { 0x8900, 0x00d1, 0x2020 },
  { 0x0900, 0x00d0, 0x0020 },
  { 0x0900, 0x00d2, 0x0020 },
  { 0x8900, 0x00d5, 0x2020 },
  { 0x0900, 0x00d4, 0x0020 },
  { 0x0900, 0x00d6, 0x0020 },
  { 0x8900, 0x00db, 0x3020 },
  { 0x8900, 0x00d9, 0x2020 },
  { 0x0900, 0x00d8, 0x0020 },
  { 0x0900, 0x00da, 0x0020 },
  { 0x8900, 0x00dd, 0x2020 },
  { 0x0900, 0x00dc, 0x0020 },
  { 0x0900, 0x00de, 0x0020 },
  { 0x8500, 0x00ef, 0x5fe0 },
  { 0x8500, 0x00e7, 0x4fe0 },
  { 0x8500, 0x00e3, 0x3fe0 },
  { 0x8500, 0x00e1, 0x2fe0 },
  { 0x0500, 0x00e0, 0x0fe0 },
  { 0x0500, 0x00e2, 0x0fe0 },
  { 0x8500, 0x00e5, 0x2fe0 },
  { 0x0500, 0x00e4, 0x0fe0 },
  { 0x0500, 0x00e6, 0x0fe0 },
  { 0x8500, 0x00eb, 0x3fe0 },
  { 0x8500, 0x00e9, 0x2fe0 },
  { 0x0500, 0x00e8, 0x0fe0 },
  { 0x0500, 0x00ea, 0x0fe0 },
  { 0x8500, 0x00ed, 0x2fe0 },
  { 0x0500, 0x00ec, 0x0fe0 },
  { 0x0500, 0x00ee, 0x0fe0 },
  { 0x9900, 0x00f7, 0x4000 },
  { 0x8500, 0x00f3, 0x3fe0 },
  { 0x8500, 0x00f1, 0x2fe0 },
  { 0x0500, 0x00f0, 0x0fe0 },
  { 0x0500, 0x00f2, 0x0fe0 },
  { 0x8500, 0x00f5, 0x2fe0 },
  { 0x0500, 0x00f4, 0x0fe0 },
  { 0x0500, 0x00f6, 0x0fe0 },
  { 0x8500, 0x00fb, 0x3fe0 },
  { 0x8500, 0x00f9, 0x2fe0 },
  { 0x0500, 0x00f8, 0x0fe0 },
  { 0x0500, 0x00fa, 0x0fe0 },
  { 0x8500, 0x00fd, 0x2fe0 },
  { 0x0500, 0x00fc, 0x0fe0 },
  { 0x0500, 0x00fe, 0x0fe0 },
  { 0x8500, 0x017f, 0x8ed4 },
  { 0x8900, 0x013f, 0x7001 },
  { 0x8500, 0x011f, 0x6fff },
  { 0x8500, 0x010f, 0x5fff },
  { 0x8500, 0x0107, 0x4fff },
  { 0x8500, 0x0103, 0x3fff },
  { 0x8500, 0x0101, 0x2fff },
  { 0x0900, 0x0100, 0x0001 },
  { 0x0900, 0x0102, 0x0001 },
  { 0x8500, 0x0105, 0x2fff },
  { 0x0900, 0x0104, 0x0001 },
  { 0x0900, 0x0106, 0x0001 },
  { 0x8500, 0x010b, 0x3fff },
  { 0x8500, 0x0109, 0x2fff },
  { 0x0900, 0x0108, 0x0001 },
  { 0x0900, 0x010a, 0x0001 },
  { 0x8500, 0x010d, 0x2fff },
  { 0x0900, 0x010c, 0x0001 },
  { 0x0900, 0x010e, 0x0001 },
  { 0x8500, 0x0117, 0x4fff },
  { 0x8500, 0x0113, 0x3fff },
  { 0x8500, 0x0111, 0x2fff },
  { 0x0900, 0x0110, 0x0001 },
  { 0x0900, 0x0112, 0x0001 },
  { 0x8500, 0x0115, 0x2fff },
  { 0x0900, 0x0114, 0x0001 },
  { 0x0900, 0x0116, 0x0001 },
  { 0x8500, 0x011b, 0x3fff },
  { 0x8500, 0x0119, 0x2fff },
  { 0x0900, 0x0118, 0x0001 },
  { 0x0900, 0x011a, 0x0001 },
  { 0x8500, 0x011d, 0x2fff },
  { 0x0900, 0x011c, 0x0001 },
  { 0x0900, 0x011e, 0x0001 },
  { 0x8500, 0x012f, 0x5fff },
  { 0x8500, 0x0127, 0x4fff },
  { 0x8500, 0x0123, 0x3fff },
  { 0x8500, 0x0121, 0x2fff },
  { 0x0900, 0x0120, 0x0001 },
  { 0x0900, 0x0122, 0x0001 },
  { 0x8500, 0x0125, 0x2fff },
  { 0x0900, 0x0124, 0x0001 },
  { 0x0900, 0x0126, 0x0001 },
  { 0x8500, 0x012b, 0x3fff },
  { 0x8500, 0x0129, 0x2fff },
  { 0x0900, 0x0128, 0x0001 },
  { 0x0900, 0x012a, 0x0001 },
  { 0x8500, 0x012d, 0x2fff },
  { 0x0900, 0x012c, 0x0001 },
  { 0x0900, 0x012e, 0x0001 },
  { 0x8500, 0x0137, 0x4fff },
  { 0x8500, 0x0133, 0x3fff },
  { 0x8500, 0x0131, 0x2f18 },
  { 0x0900, 0x0130, 0x0f39 },
  { 0x0900, 0x0132, 0x0001 },
  { 0x8500, 0x0135, 0x2fff },
  { 0x0900, 0x0134, 0x0001 },
  { 0x0900, 0x0136, 0x0001 },
  { 0x8900, 0x013b, 0x3001 },
  { 0x8900, 0x0139, 0x2001 },
  { 0x0500, 0x0138, 0x0000 },
  { 0x0500, 0x013a, 0x0fff },
  { 0x8900, 0x013d, 0x2001 },
  { 0x0500, 0x013c, 0x0fff },
  { 0x0500, 0x013e, 0x0fff },
  { 0x8500, 0x015f, 0x6fff },
  { 0x8500, 0x014f, 0x5fff },
  { 0x8900, 0x0147, 0x4001 },
  { 0x8900, 0x0143, 0x3001 },
  { 0x8900, 0x0141, 0x2001 },
  { 0x0500, 0x0140, 0x0fff },
  { 0x0500, 0x0142, 0x0fff },
  { 0x8900, 0x0145, 0x2001 },
  { 0x0500, 0x0144, 0x0fff },
  { 0x0500, 0x0146, 0x0fff },
  { 0x8500, 0x014b, 0x3fff },
  { 0x8500, 0x0149, 0x2000 },
  { 0x0500, 0x0148, 0x0fff },
  { 0x0900, 0x014a, 0x0001 },
  { 0x8500, 0x014d, 0x2fff },
  { 0x0900, 0x014c, 0x0001 },
  { 0x0900, 0x014e, 0x0001 },
  { 0x8500, 0x0157, 0x4fff },
  { 0x8500, 0x0153, 0x3fff },
  { 0x8500, 0x0151, 0x2fff },
  { 0x0900, 0x0150, 0x0001 },
  { 0x0900, 0x0152, 0x0001 },
  { 0x8500, 0x0155, 0x2fff },
  { 0x0900, 0x0154, 0x0001 },
  { 0x0900, 0x0156, 0x0001 },
  { 0x8500, 0x015b, 0x3fff },
  { 0x8500, 0x0159, 0x2fff },
  { 0x0900, 0x0158, 0x0001 },
  { 0x0900, 0x015a, 0x0001 },
  { 0x8500, 0x015d, 0x2fff },
  { 0x0900, 0x015c, 0x0001 },
  { 0x0900, 0x015e, 0x0001 },
  { 0x8500, 0x016f, 0x5fff },
  { 0x8500, 0x0167, 0x4fff },
  { 0x8500, 0x0163, 0x3fff },
  { 0x8500, 0x0161, 0x2fff },
  { 0x0900, 0x0160, 0x0001 },
  { 0x0900, 0x0162, 0x0001 },
  { 0x8500, 0x0165, 0x2fff },
  { 0x0900, 0x0164, 0x0001 },
  { 0x0900, 0x0166, 0x0001 },
  { 0x8500, 0x016b, 0x3fff },
  { 0x8500, 0x0169, 0x2fff },
  { 0x0900, 0x0168, 0x0001 },
  { 0x0900, 0x016a, 0x0001 },
  { 0x8500, 0x016d, 0x2fff },
  { 0x0900, 0x016c, 0x0001 },
  { 0x0900, 0x016e, 0x0001 },
  { 0x8500, 0x0177, 0x4fff },
  { 0x8500, 0x0173, 0x3fff },
  { 0x8500, 0x0171, 0x2fff },
  { 0x0900, 0x0170, 0x0001 },
  { 0x0900, 0x0172, 0x0001 },
  { 0x8500, 0x0175, 0x2fff },
  { 0x0900, 0x0174, 0x0001 },
  { 0x0900, 0x0176, 0x0001 },
  { 0x8900, 0x017b, 0x3001 },
  { 0x8900, 0x0179, 0x2001 },
  { 0x0900, 0x0178, 0x0f87 },
  { 0x0500, 0x017a, 0x0fff },
  { 0x8900, 0x017d, 0x2001 },
  { 0x0500, 0x017c, 0x0fff },
  { 0x0500, 0x017e, 0x0fff },
  { 0x8500, 0x01bf, 0x7038 },
  { 0x8900, 0x019f, 0x60d6 },
  { 0x8900, 0x018f, 0x50ca },
  { 0x8900, 0x0187, 0x4001 },
  { 0x8500, 0x0183, 0x3fff },
  { 0x8900, 0x0181, 0x20d2 },
  { 0x0500, 0x0180, 0x0000 },
  { 0x0900, 0x0182, 0x0001 },
  { 0x8500, 0x0185, 0x2fff },
  { 0x0900, 0x0184, 0x0001 },
  { 0x0900, 0x0186, 0x00ce },
  { 0x8900, 0x018b, 0x3001 },
  { 0x8900, 0x0189, 0x20cd },
  { 0x0500, 0x0188, 0x0fff },
  { 0x0900, 0x018a, 0x00cd },
  { 0x8500, 0x018d, 0x2000 },
  { 0x0500, 0x018c, 0x0fff },
  { 0x0900, 0x018e, 0x004f },
  { 0x8900, 0x0197, 0x40d1 },
  { 0x8900, 0x0193, 0x30cd },
  { 0x8900, 0x0191, 0x2001 },
  { 0x0900, 0x0190, 0x00cb },
  { 0x0500, 0x0192, 0x0fff },
  { 0x8500, 0x0195, 0x2061 },
  { 0x0900, 0x0194, 0x00cf },
  { 0x0900, 0x0196, 0x00d3 },
  { 0x8500, 0x019b, 0x3000 },
  { 0x8500, 0x0199, 0x2fff },
  { 0x0900, 0x0198, 0x0001 },
  { 0x0500, 0x019a, 0x0000 },
  { 0x8900, 0x019d, 0x20d5 },
  { 0x0900, 0x019c, 0x00d3 },
  { 0x0500, 0x019e, 0x0082 },
  { 0x8900, 0x01af, 0x5001 },
  { 0x8900, 0x01a7, 0x4001 },
  { 0x8500, 0x01a3, 0x3fff },
  { 0x8500, 0x01a1, 0x2fff },
  { 0x0900, 0x01a0, 0x0001 },
  { 0x0900, 0x01a2, 0x0001 },
  { 0x8500, 0x01a5, 0x2fff },
  { 0x0900, 0x01a4, 0x0001 },
  { 0x0900, 0x01a6, 0x00da },
  { 0x8500, 0x01ab, 0x3000 },
  { 0x8900, 0x01a9, 0x20da },
  { 0x0500, 0x01a8, 0x0fff },
  { 0x0500, 0x01aa, 0x0000 },
  { 0x8500, 0x01ad, 0x2fff },
  { 0x0900, 0x01ac, 0x0001 },
  { 0x0900, 0x01ae, 0x00da },
  { 0x8900, 0x01b7, 0x40db },
  { 0x8900, 0x01b3, 0x3001 },
  { 0x8900, 0x01b1, 0x20d9 },
  { 0x0500, 0x01b0, 0x0fff },
  { 0x0900, 0x01b2, 0x00d9 },
  { 0x8900, 0x01b5, 0x2001 },
  { 0x0500, 0x01b4, 0x0fff },
  { 0x0500, 0x01b6, 0x0fff },
  { 0x8700, 0x01bb, 0x3000 },
  { 0x8500, 0x01b9, 0x2fff },
  { 0x0900, 0x01b8, 0x0001 },
  { 0x0500, 0x01ba, 0x0000 },
  { 0x8500, 0x01bd, 0x2fff },
  { 0x0900, 0x01bc, 0x0001 },
  { 0x0500, 0x01be, 0x0000 },
  { 0x8500, 0x01df, 0x6fff },
  { 0x8900, 0x01cf, 0x5001 },
  { 0x8900, 0x01c7, 0x4002 },
  { 0x8700, 0x01c3, 0x3000 },
  { 0x8700, 0x01c1, 0x2000 },
  { 0x0700, 0x01c0, 0x0000 },
  { 0x0700, 0x01c2, 0x0000 },
  { 0x8800, 0x01c5, 0x2000 },
  { 0x0900, 0x01c4, 0x0002 },
  { 0x0500, 0x01c6, 0x0ffe },
  { 0x8800, 0x01cb, 0x3000 },
  { 0x8500, 0x01c9, 0x2ffe },
  { 0x0800, 0x01c8, 0x0000 },
  { 0x0900, 0x01ca, 0x0002 },
  { 0x8900, 0x01cd, 0x2001 },
  { 0x0500, 0x01cc, 0x0ffe },
  { 0x0500, 0x01ce, 0x0fff },
  { 0x8900, 0x01d7, 0x4001 },
  { 0x8900, 0x01d3, 0x3001 },
  { 0x8900, 0x01d1, 0x2001 },
  { 0x0500, 0x01d0, 0x0fff },
  { 0x0500, 0x01d2, 0x0fff },
  { 0x8900, 0x01d5, 0x2001 },
  { 0x0500, 0x01d4, 0x0fff },
  { 0x0500, 0x01d6, 0x0fff },
  { 0x8900, 0x01db, 0x3001 },
  { 0x8900, 0x01d9, 0x2001 },
  { 0x0500, 0x01d8, 0x0fff },
  { 0x0500, 0x01da, 0x0fff },
  { 0x8500, 0x01dd, 0x2fb1 },
  { 0x0500, 0x01dc, 0x0fff },
  { 0x0900, 0x01de, 0x0001 },
  { 0x8500, 0x01ef, 0x5fff },
  { 0x8500, 0x01e7, 0x4fff },
  { 0x8500, 0x01e3, 0x3fff },
  { 0x8500, 0x01e1, 0x2fff },
  { 0x0900, 0x01e0, 0x0001 },
  { 0x0900, 0x01e2, 0x0001 },
  { 0x8500, 0x01e5, 0x2fff },
  { 0x0900, 0x01e4, 0x0001 },
  { 0x0900, 0x01e6, 0x0001 },
  { 0x8500, 0x01eb, 0x3fff },
  { 0x8500, 0x01e9, 0x2fff },
  { 0x0900, 0x01e8, 0x0001 },
  { 0x0900, 0x01ea, 0x0001 },
  { 0x8500, 0x01ed, 0x2fff },
  { 0x0900, 0x01ec, 0x0001 },
  { 0x0900, 0x01ee, 0x0001 },
  { 0x8900, 0x01f7, 0x4fc8 },
  { 0x8500, 0x01f3, 0x3ffe },
  { 0x8900, 0x01f1, 0x2002 },
  { 0x0500, 0x01f0, 0x0000 },
  { 0x0800, 0x01f2, 0x0000 },
  { 0x8500, 0x01f5, 0x2fff },
  { 0x0900, 0x01f4, 0x0001 },
  { 0x0900, 0x01f6, 0x0f9f },
  { 0x8500, 0x01fb, 0x3fff },
  { 0x8500, 0x01f9, 0x2fff },
  { 0x0900, 0x01f8, 0x0001 },
  { 0x0900, 0x01fa, 0x0001 },
  { 0x8500, 0x01fd, 0x2fff },
  { 0x0900, 0x01fc, 0x0001 },
  { 0x0900, 0x01fe, 0x0001 },
  { 0x8c00, 0x0318, 0x9000 },
  { 0x8500, 0x0298, 0x8000 },
  { 0x8500, 0x0258, 0x7000 },
  { 0x8500, 0x021f, 0x6fff },
  { 0x8500, 0x020f, 0x5fff },
  { 0x8500, 0x0207, 0x4fff },
  { 0x8500, 0x0203, 0x3fff },
  { 0x8500, 0x0201, 0x2fff },
  { 0x0900, 0x0200, 0x0001 },
  { 0x0900, 0x0202, 0x0001 },
  { 0x8500, 0x0205, 0x2fff },
  { 0x0900, 0x0204, 0x0001 },
  { 0x0900, 0x0206, 0x0001 },
  { 0x8500, 0x020b, 0x3fff },
  { 0x8500, 0x0209, 0x2fff },
  { 0x0900, 0x0208, 0x0001 },
  { 0x0900, 0x020a, 0x0001 },
  { 0x8500, 0x020d, 0x2fff },
  { 0x0900, 0x020c, 0x0001 },
  { 0x0900, 0x020e, 0x0001 },
  { 0x8500, 0x0217, 0x4fff },
  { 0x8500, 0x0213, 0x3fff },
  { 0x8500, 0x0211, 0x2fff },
  { 0x0900, 0x0210, 0x0001 },
  { 0x0900, 0x0212, 0x0001 },
  { 0x8500, 0x0215, 0x2fff },
  { 0x0900, 0x0214, 0x0001 },
  { 0x0900, 0x0216, 0x0001 },
  { 0x8500, 0x021b, 0x3fff },
  { 0x8500, 0x0219, 0x2fff },
  { 0x0900, 0x0218, 0x0001 },
  { 0x0900, 0x021a, 0x0001 },
  { 0x8500, 0x021d, 0x2fff },
  { 0x0900, 0x021c, 0x0001 },
  { 0x0900, 0x021e, 0x0001 },
  { 0x8500, 0x022f, 0x5fff },
  { 0x8500, 0x0227, 0x4fff },
  { 0x8500, 0x0223, 0x3fff },
  { 0x8500, 0x0221, 0x2000 },
  { 0x0900, 0x0220, 0x0f7e },
  { 0x0900, 0x0222, 0x0001 },
  { 0x8500, 0x0225, 0x2fff },
  { 0x0900, 0x0224, 0x0001 },
  { 0x0900, 0x0226, 0x0001 },
  { 0x8500, 0x022b, 0x3fff },
  { 0x8500, 0x0229, 0x2fff },
  { 0x0900, 0x0228, 0x0001 },
  { 0x0900, 0x022a, 0x0001 },
  { 0x8500, 0x022d, 0x2fff },
  { 0x0900, 0x022c, 0x0001 },
  { 0x0900, 0x022e, 0x0001 },
  { 0x8500, 0x0250, 0x4000 },
  { 0x8500, 0x0233, 0x3fff },
  { 0x8500, 0x0231, 0x2fff },
  { 0x0900, 0x0230, 0x0001 },
  { 0x0900, 0x0232, 0x0001 },
  { 0x8500, 0x0235, 0x2000 },
  { 0x0500, 0x0234, 0x0000 },
  { 0x0500, 0x0236, 0x0000 },
  { 0x8500, 0x0254, 0x3f32 },
  { 0x8500, 0x0252, 0x2000 },
  { 0x0500, 0x0251, 0x0000 },
  { 0x0500, 0x0253, 0x0f2e },
  { 0x8500, 0x0256, 0x2f33 },
  { 0x0500, 0x0255, 0x0000 },
  { 0x0500, 0x0257, 0x0f33 },
  { 0x8500, 0x0278, 0x6000 },
  { 0x8500, 0x0268, 0x5f2f },
  { 0x8500, 0x0260, 0x4f33 },
  { 0x8500, 0x025c, 0x3000 },
  { 0x8500, 0x025a, 0x2000 },
  { 0x0500, 0x0259, 0x0f36 },
  { 0x0500, 0x025b, 0x0f35 },
  { 0x8500, 0x025e, 0x2000 },
  { 0x0500, 0x025d, 0x0000 },
  { 0x0500, 0x025f, 0x0000 },
  { 0x8500, 0x0264, 0x3000 },
  { 0x8500, 0x0262, 0x2000 },
  { 0x0500, 0x0261, 0x0000 },
  { 0x0500, 0x0263, 0x0f31 },
  { 0x8500, 0x0266, 0x2000 },
  { 0x0500, 0x0265, 0x0000 },
  { 0x0500, 0x0267, 0x0000 },
  { 0x8500, 0x0270, 0x4000 },
  { 0x8500, 0x026c, 0x3000 },
  { 0x8500, 0x026a, 0x2000 },
  { 0x0500, 0x0269, 0x0f2d },
  { 0x0500, 0x026b, 0x0000 },
  { 0x8500, 0x026e, 0x2000 },
  { 0x0500, 0x026d, 0x0000 },
  { 0x0500, 0x026f, 0x0f2d },
  { 0x8500, 0x0274, 0x3000 },
  { 0x8500, 0x0272, 0x2f2b },
  { 0x0500, 0x0271, 0x0000 },
  { 0x0500, 0x0273, 0x0000 },
  { 0x8500, 0x0276, 0x2000 },
  { 0x0500, 0x0275, 0x0f2a },
  { 0x0500, 0x0277, 0x0000 },
  { 0x8500, 0x0288, 0x5f26 },
  { 0x8500, 0x0280, 0x4f26 },
  { 0x8500, 0x027c, 0x3000 },
  { 0x8500, 0x027a, 0x2000 },
  { 0x0500, 0x0279, 0x0000 },
  { 0x0500, 0x027b, 0x0000 },
  { 0x8500, 0x027e, 0x2000 },
  { 0x0500, 0x027d, 0x0000 },
  { 0x0500, 0x027f, 0x0000 },
  { 0x8500, 0x0284, 0x3000 },
  { 0x8500, 0x0282, 0x2000 },
  { 0x0500, 0x0281, 0x0000 },
  { 0x0500, 0x0283, 0x0f26 },
  { 0x8500, 0x0286, 0x2000 },
  { 0x0500, 0x0285, 0x0000 },
  { 0x0500, 0x0287, 0x0000 },
  { 0x8500, 0x0290, 0x4000 },
  { 0x8500, 0x028c, 0x3000 },
  { 0x8500, 0x028a, 0x2f27 },
  { 0x0500, 0x0289, 0x0000 },
  { 0x0500, 0x028b, 0x0f27 },
  { 0x8500, 0x028e, 0x2000 },
  { 0x0500, 0x028d, 0x0000 },
  { 0x0500, 0x028f, 0x0000 },
  { 0x8500, 0x0294, 0x3000 },
  { 0x8500, 0x0292, 0x2f25 },
  { 0x0500, 0x0291, 0x0000 },
  { 0x0500, 0x0293, 0x0000 },
  { 0x8500, 0x0296, 0x2000 },
  { 0x0500, 0x0295, 0x0000 },
  { 0x0500, 0x0297, 0x0000 },
  { 0x9800, 0x02d8, 0x7000 },
  { 0x8600, 0x02b8, 0x6000 },
  { 0x8500, 0x02a8, 0x5000 },
  { 0x8500, 0x02a0, 0x4000 },
  { 0x8500, 0x029c, 0x3000 },
  { 0x8500, 0x029a, 0x2000 },
  { 0x0500, 0x0299, 0x0000 },
  { 0x0500, 0x029b, 0x0000 },
  { 0x8500, 0x029e, 0x2000 },
  { 0x0500, 0x029d, 0x0000 },
  { 0x0500, 0x029f, 0x0000 },
  { 0x8500, 0x02a4, 0x3000 },
  { 0x8500, 0x02a2, 0x2000 },
  { 0x0500, 0x02a1, 0x0000 },
  { 0x0500, 0x02a3, 0x0000 },
  { 0x8500, 0x02a6, 0x2000 },
  { 0x0500, 0x02a5, 0x0000 },
  { 0x0500, 0x02a7, 0x0000 },
  { 0x8600, 0x02b0, 0x4000 },
  { 0x8500, 0x02ac, 0x3000 },
  { 0x8500, 0x02aa, 0x2000 },
  { 0x0500, 0x02a9, 0x0000 },
  { 0x0500, 0x02ab, 0x0000 },
  { 0x8500, 0x02ae, 0x2000 },
  { 0x0500, 0x02ad, 0x0000 },
  { 0x0500, 0x02af, 0x0000 },
  { 0x8600, 0x02b4, 0x3000 },
  { 0x8600, 0x02b2, 0x2000 },
  { 0x0600, 0x02b1, 0x0000 },
  { 0x0600, 0x02b3, 0x0000 },
  { 0x8600, 0x02b6, 0x2000 },
  { 0x0600, 0x02b5, 0x0000 },
  { 0x0600, 0x02b7, 0x0000 },
  { 0x8600, 0x02c8, 0x5000 },
  { 0x8600, 0x02c0, 0x4000 },
  { 0x8600, 0x02bc, 0x3000 },
  { 0x8600, 0x02ba, 0x2000 },
  { 0x0600, 0x02b9, 0x0000 },
  { 0x0600, 0x02bb, 0x0000 },
  { 0x8600, 0x02be, 0x2000 },
  { 0x0600, 0x02bd, 0x0000 },
  { 0x0600, 0x02bf, 0x0000 },
  { 0x9800, 0x02c4, 0x3000 },
  { 0x9800, 0x02c2, 0x2000 },
  { 0x0600, 0x02c1, 0x0000 },
  { 0x1800, 0x02c3, 0x0000 },
  { 0x8600, 0x02c6, 0x2000 },
  { 0x1800, 0x02c5, 0x0000 },
  { 0x0600, 0x02c7, 0x0000 },
  { 0x8600, 0x02d0, 0x4000 },
  { 0x8600, 0x02cc, 0x3000 },
  { 0x8600, 0x02ca, 0x2000 },
  { 0x0600, 0x02c9, 0x0000 },
  { 0x0600, 0x02cb, 0x0000 },
  { 0x8600, 0x02ce, 0x2000 },
  { 0x0600, 0x02cd, 0x0000 },
  { 0x0600, 0x02cf, 0x0000 },
  { 0x9800, 0x02d4, 0x3000 },
  { 0x9800, 0x02d2, 0x2000 },
  { 0x0600, 0x02d1, 0x0000 },
  { 0x1800, 0x02d3, 0x0000 },
  { 0x9800, 0x02d6, 0x2000 },
  { 0x1800, 0x02d5, 0x0000 },
  { 0x1800, 0x02d7, 0x0000 },
  { 0x9800, 0x02f8, 0x6000 },
  { 0x9800, 0x02e8, 0x5000 },
  { 0x8600, 0x02e0, 0x4000 },
  { 0x9800, 0x02dc, 0x3000 },
  { 0x9800, 0x02da, 0x2000 },
  { 0x1800, 0x02d9, 0x0000 },
  { 0x1800, 0x02db, 0x0000 },
  { 0x9800, 0x02de, 0x2000 },
  { 0x1800, 0x02dd, 0x0000 },
  { 0x1800, 0x02df, 0x0000 },
  { 0x8600, 0x02e4, 0x3000 },
  { 0x8600, 0x02e2, 0x2000 },
  { 0x0600, 0x02e1, 0x0000 },
  { 0x0600, 0x02e3, 0x0000 },
  { 0x9800, 0x02e6, 0x2000 },
  { 0x1800, 0x02e5, 0x0000 },
  { 0x1800, 0x02e7, 0x0000 },
  { 0x9800, 0x02f0, 0x4000 },
  { 0x9800, 0x02ec, 0x3000 },
  { 0x9800, 0x02ea, 0x2000 },
  { 0x1800, 0x02e9, 0x0000 },
  { 0x1800, 0x02eb, 0x0000 },
  { 0x8600, 0x02ee, 0x2000 },
  { 0x1800, 0x02ed, 0x0000 },
  { 0x1800, 0x02ef, 0x0000 },
  { 0x9800, 0x02f4, 0x3000 },
  { 0x9800, 0x02f2, 0x2000 },
  { 0x1800, 0x02f1, 0x0000 },
  { 0x1800, 0x02f3, 0x0000 },
  { 0x9800, 0x02f6, 0x2000 },
  { 0x1800, 0x02f5, 0x0000 },
  { 0x1800, 0x02f7, 0x0000 },
  { 0x8c00, 0x0308, 0x5000 },
  { 0x8c00, 0x0300, 0x4000 },
  { 0x9800, 0x02fc, 0x3000 },
  { 0x9800, 0x02fa, 0x2000 },
  { 0x1800, 0x02f9, 0x0000 },
  { 0x1800, 0x02fb, 0x0000 },
  { 0x9800, 0x02fe, 0x2000 },
  { 0x1800, 0x02fd, 0x0000 },
  { 0x1800, 0x02ff, 0x0000 },
  { 0x8c00, 0x0304, 0x3000 },
  { 0x8c00, 0x0302, 0x2000 },
  { 0x0c00, 0x0301, 0x0000 },
  { 0x0c00, 0x0303, 0x0000 },
  { 0x8c00, 0x0306, 0x2000 },
  { 0x0c00, 0x0305, 0x0000 },
  { 0x0c00, 0x0307, 0x0000 },
  { 0x8c00, 0x0310, 0x4000 },
  { 0x8c00, 0x030c, 0x3000 },
  { 0x8c00, 0x030a, 0x2000 },
  { 0x0c00, 0x0309, 0x0000 },
  { 0x0c00, 0x030b, 0x0000 },
  { 0x8c00, 0x030e, 0x2000 },
  { 0x0c00, 0x030d, 0x0000 },
  { 0x0c00, 0x030f, 0x0000 },
  { 0x8c00, 0x0314, 0x3000 },
  { 0x8c00, 0x0312, 0x2000 },
  { 0x0c00, 0x0311, 0x0000 },
  { 0x0c00, 0x0313, 0x0000 },
  { 0x8c00, 0x0316, 0x2000 },
  { 0x0c00, 0x0315, 0x0000 },
  { 0x0c00, 0x0317, 0x0000 },
  { 0x8500, 0x03b0, 0x8000 },
  { 0x8c00, 0x035d, 0x7000 },
  { 0x8c00, 0x0338, 0x6000 },
  { 0x8c00, 0x0328, 0x5000 },
  { 0x8c00, 0x0320, 0x4000 },
  { 0x8c00, 0x031c, 0x3000 },
  { 0x8c00, 0x031a, 0x2000 },
  { 0x0c00, 0x0319, 0x0000 },
  { 0x0c00, 0x031b, 0x0000 },
  { 0x8c00, 0x031e, 0x2000 },
  { 0x0c00, 0x031d, 0x0000 },
  { 0x0c00, 0x031f, 0x0000 },
  { 0x8c00, 0x0324, 0x3000 },
  { 0x8c00, 0x0322, 0x2000 },
  { 0x0c00, 0x0321, 0x0000 },
  { 0x0c00, 0x0323, 0x0000 },
  { 0x8c00, 0x0326, 0x2000 },
  { 0x0c00, 0x0325, 0x0000 },
  { 0x0c00, 0x0327, 0x0000 },
  { 0x8c00, 0x0330, 0x4000 },
  { 0x8c00, 0x032c, 0x3000 },
  { 0x8c00, 0x032a, 0x2000 },
  { 0x0c00, 0x0329, 0x0000 },
  { 0x0c00, 0x032b, 0x0000 },
  { 0x8c00, 0x032e, 0x2000 },
  { 0x0c00, 0x032d, 0x0000 },
  { 0x0c00, 0x032f, 0x0000 },
  { 0x8c00, 0x0334, 0x3000 },
  { 0x8c00, 0x0332, 0x2000 },
  { 0x0c00, 0x0331, 0x0000 },
  { 0x0c00, 0x0333, 0x0000 },
  { 0x8c00, 0x0336, 0x2000 },
  { 0x0c00, 0x0335, 0x0000 },
  { 0x0c00, 0x0337, 0x0000 },
  { 0x8c00, 0x0348, 0x5000 },
  { 0x8c00, 0x0340, 0x4000 },
  { 0x8c00, 0x033c, 0x3000 },
  { 0x8c00, 0x033a, 0x2000 },
  { 0x0c00, 0x0339, 0x0000 },
  { 0x0c00, 0x033b, 0x0000 },
  { 0x8c00, 0x033e, 0x2000 },
  { 0x0c00, 0x033d, 0x0000 },
  { 0x0c00, 0x033f, 0x0000 },
  { 0x8c00, 0x0344, 0x3000 },
  { 0x8c00, 0x0342, 0x2000 },
  { 0x0c00, 0x0341, 0x0000 },
  { 0x0c00, 0x0343, 0x0000 },
  { 0x8c00, 0x0346, 0x2000 },
  { 0x0c00, 0x0345, 0x0000 },
  { 0x0c00, 0x0347, 0x0000 },
  { 0x8c00, 0x0350, 0x4000 },
  { 0x8c00, 0x034c, 0x3000 },
  { 0x8c00, 0x034a, 0x2000 },
  { 0x0c00, 0x0349, 0x0000 },
  { 0x0c00, 0x034b, 0x0000 },
  { 0x8c00, 0x034e, 0x2000 },
  { 0x0c00, 0x034d, 0x0000 },
  { 0x0c00, 0x034f, 0x0000 },
  { 0x8c00, 0x0354, 0x3000 },
  { 0x8c00, 0x0352, 0x2000 },
  { 0x0c00, 0x0351, 0x0000 },
  { 0x0c00, 0x0353, 0x0000 },
  { 0x8c00, 0x0356, 0x2000 },
  { 0x0c00, 0x0355, 0x0000 },
  { 0x0c00, 0x0357, 0x0000 },
  { 0x8900, 0x038f, 0x603f },
  { 0x8c00, 0x036d, 0x5000 },
  { 0x8c00, 0x0365, 0x4000 },
  { 0x8c00, 0x0361, 0x3000 },
  { 0x8c00, 0x035f, 0x2000 },
  { 0x0c00, 0x035e, 0x0000 },
  { 0x0c00, 0x0360, 0x0000 },
  { 0x8c00, 0x0363, 0x2000 },
  { 0x0c00, 0x0362, 0x0000 },
  { 0x0c00, 0x0364, 0x0000 },
  { 0x8c00, 0x0369, 0x3000 },
  { 0x8c00, 0x0367, 0x2000 },
  { 0x0c00, 0x0366, 0x0000 },
  { 0x0c00, 0x0368, 0x0000 },
  { 0x8c00, 0x036b, 0x2000 },
  { 0x0c00, 0x036a, 0x0000 },
  { 0x0c00, 0x036c, 0x0000 },
  { 0x9800, 0x0385, 0x4000 },
  { 0x9800, 0x0375, 0x3000 },
  { 0x8c00, 0x036f, 0x2000 },
  { 0x0c00, 0x036e, 0x0000 },
  { 0x1800, 0x0374, 0x0000 },
  { 0x9500, 0x037e, 0x2000 },
  { 0x0600, 0x037a, 0x0000 },
  { 0x1800, 0x0384, 0x0000 },
  { 0x8900, 0x0389, 0x3025 },
  { 0x9500, 0x0387, 0x2000 },
  { 0x0900, 0x0386, 0x0026 },
  { 0x0900, 0x0388, 0x0025 },
  { 0x8900, 0x038c, 0x2040 },
  { 0x0900, 0x038a, 0x0025 },
  { 0x0900, 0x038e, 0x003f },
  { 0x8900, 0x039f, 0x5020 },
  { 0x8900, 0x0397, 0x4020 },
  { 0x8900, 0x0393, 0x3020 },
  { 0x8900, 0x0391, 0x2020 },
  { 0x0500, 0x0390, 0x0000 },
  { 0x0900, 0x0392, 0x0020 },
  { 0x8900, 0x0395, 0x2020 },
  { 0x0900, 0x0394, 0x0020 },
  { 0x0900, 0x0396, 0x0020 },
  { 0x8900, 0x039b, 0x3020 },
  { 0x8900, 0x0399, 0x2020 },
  { 0x0900, 0x0398, 0x0020 },
  { 0x0900, 0x039a, 0x0020 },
  { 0x8900, 0x039d, 0x2020 },
  { 0x0900, 0x039c, 0x0020 },
  { 0x0900, 0x039e, 0x0020 },
  { 0x8900, 0x03a8, 0x4020 },
  { 0x8900, 0x03a4, 0x3020 },
  { 0x8900, 0x03a1, 0x2020 },
  { 0x0900, 0x03a0, 0x0020 },
  { 0x0900, 0x03a3, 0x0020 },
  { 0x8900, 0x03a6, 0x2020 },
  { 0x0900, 0x03a5, 0x0020 },
  { 0x0900, 0x03a7, 0x0020 },
  { 0x8500, 0x03ac, 0x3fda },
  { 0x8900, 0x03aa, 0x2020 },
  { 0x0900, 0x03a9, 0x0020 },
  { 0x0900, 0x03ab, 0x0020 },
  { 0x8500, 0x03ae, 0x2fdb },
  { 0x0500, 0x03ad, 0x0fdb },
  { 0x0500, 0x03af, 0x0fdb },
  { 0x8500, 0x03f1, 0x7fb0 },
  { 0x8500, 0x03d1, 0x6fc7 },
  { 0x8500, 0x03c0, 0x5fe0 },
  { 0x8500, 0x03b8, 0x4fe0 },
  { 0x8500, 0x03b4, 0x3fe0 },
  { 0x8500, 0x03b2, 0x2fe0 },
  { 0x0500, 0x03b1, 0x0fe0 },
  { 0x0500, 0x03b3, 0x0fe0 },
  { 0x8500, 0x03b6, 0x2fe0 },
  { 0x0500, 0x03b5, 0x0fe0 },
  { 0x0500, 0x03b7, 0x0fe0 },
  { 0x8500, 0x03bc, 0x3fe0 },
  { 0x8500, 0x03ba, 0x2fe0 },
  { 0x0500, 0x03b9, 0x0fe0 },
  { 0x0500, 0x03bb, 0x0fe0 },
  { 0x8500, 0x03be, 0x2fe0 },
  { 0x0500, 0x03bd, 0x0fe0 },
  { 0x0500, 0x03bf, 0x0fe0 },
  { 0x8500, 0x03c8, 0x4fe0 },
  { 0x8500, 0x03c4, 0x3fe0 },
  { 0x8500, 0x03c2, 0x2fe1 },
  { 0x0500, 0x03c1, 0x0fe0 },
  { 0x0500, 0x03c3, 0x0fe0 },
  { 0x8500, 0x03c6, 0x2fe0 },
  { 0x0500, 0x03c5, 0x0fe0 },
  { 0x0500, 0x03c7, 0x0fe0 },
  { 0x8500, 0x03cc, 0x3fc0 },
  { 0x8500, 0x03ca, 0x2fe0 },
  { 0x0500, 0x03c9, 0x0fe0 },
  { 0x0500, 0x03cb, 0x0fe0 },
  { 0x8500, 0x03ce, 0x2fc1 },
  { 0x0500, 0x03cd, 0x0fc1 },
  { 0x0500, 0x03d0, 0x0fc2 },
  { 0x8500, 0x03e1, 0x5fff },
  { 0x8500, 0x03d9, 0x4fff },
  { 0x8500, 0x03d5, 0x3fd1 },
  { 0x8900, 0x03d3, 0x2000 },
  { 0x0900, 0x03d2, 0x0000 },
  { 0x0900, 0x03d4, 0x0000 },
  { 0x8500, 0x03d7, 0x2000 },
  { 0x0500, 0x03d6, 0x0fca },
  { 0x0900, 0x03d8, 0x0001 },
  { 0x8500, 0x03dd, 0x3fff },
  { 0x8500, 0x03db, 0x2fff },
  { 0x0900, 0x03da, 0x0001 },
  { 0x0900, 0x03dc, 0x0001 },
  { 0x8500, 0x03df, 0x2fff },
  { 0x0900, 0x03de, 0x0001 },
  { 0x0900, 0x03e0, 0x0001 },
  { 0x8500, 0x03e9, 0x4fff },
  { 0x8500, 0x03e5, 0x3fff },
  { 0x8500, 0x03e3, 0x2fff },
  { 0x0900, 0x03e2, 0x0001 },
  { 0x0900, 0x03e4, 0x0001 },
  { 0x8500, 0x03e7, 0x2fff },
  { 0x0900, 0x03e6, 0x0001 },
  { 0x0900, 0x03e8, 0x0001 },
  { 0x8500, 0x03ed, 0x3fff },
  { 0x8500, 0x03eb, 0x2fff },
  { 0x0900, 0x03ea, 0x0001 },
  { 0x0900, 0x03ec, 0x0001 },
  { 0x8500, 0x03ef, 0x2fff },
  { 0x0900, 0x03ee, 0x0001 },
  { 0x0500, 0x03f0, 0x0faa },
  { 0x8900, 0x0415, 0x6020 },
  { 0x8900, 0x0405, 0x5050 },
  { 0x8900, 0x03f9, 0x4ff9 },
  { 0x8500, 0x03f5, 0x3fa0 },
  { 0x8500, 0x03f3, 0x2000 },
  { 0x0500, 0x03f2, 0x0007 },
  { 0x0900, 0x03f4, 0x0fc4 },
  { 0x8900, 0x03f7, 0x2001 },
  { 0x1900, 0x03f6, 0x0000 },
  { 0x0500, 0x03f8, 0x0fff },
  { 0x8900, 0x0401, 0x3050 },
  { 0x8500, 0x03fb, 0x2fff },
  { 0x0900, 0x03fa, 0x0001 },
  { 0x0900, 0x0400, 0x0050 },
  { 0x8900, 0x0403, 0x2050 },
  { 0x0900, 0x0402, 0x0050 },
  { 0x0900, 0x0404, 0x0050 },
  { 0x8900, 0x040d, 0x4050 },
  { 0x8900, 0x0409, 0x3050 },
  { 0x8900, 0x0407, 0x2050 },
  { 0x0900, 0x0406, 0x0050 },
  { 0x0900, 0x0408, 0x0050 },
  { 0x8900, 0x040b, 0x2050 },
  { 0x0900, 0x040a, 0x0050 },
  { 0x0900, 0x040c, 0x0050 },
  { 0x8900, 0x0411, 0x3020 },
  { 0x8900, 0x040f, 0x2050 },
  { 0x0900, 0x040e, 0x0050 },
  { 0x0900, 0x0410, 0x0020 },
  { 0x8900, 0x0413, 0x2020 },
  { 0x0900, 0x0412, 0x0020 },
  { 0x0900, 0x0414, 0x0020 },
  { 0x8900, 0x0425, 0x5020 },
  { 0x8900, 0x041d, 0x4020 },
  { 0x8900, 0x0419, 0x3020 },
  { 0x8900, 0x0417, 0x2020 },
  { 0x0900, 0x0416, 0x0020 },
  { 0x0900, 0x0418, 0x0020 },
  { 0x8900, 0x041b, 0x2020 },
  { 0x0900, 0x041a, 0x0020 },
  { 0x0900, 0x041c, 0x0020 },
  { 0x8900, 0x0421, 0x3020 },
  { 0x8900, 0x041f, 0x2020 },
  { 0x0900, 0x041e, 0x0020 },
  { 0x0900, 0x0420, 0x0020 },
  { 0x8900, 0x0423, 0x2020 },
  { 0x0900, 0x0422, 0x0020 },
  { 0x0900, 0x0424, 0x0020 },
  { 0x8900, 0x042d, 0x4020 },
  { 0x8900, 0x0429, 0x3020 },
  { 0x8900, 0x0427, 0x2020 },
  { 0x0900, 0x0426, 0x0020 },
  { 0x0900, 0x0428, 0x0020 },
  { 0x8900, 0x042b, 0x2020 },
  { 0x0900, 0x042a, 0x0020 },
  { 0x0900, 0x042c, 0x0020 },
  { 0x8500, 0x0431, 0x3fe0 },
  { 0x8900, 0x042f, 0x2020 },
  { 0x0900, 0x042e, 0x0020 },
  { 0x0500, 0x0430, 0x0fe0 },
  { 0x8500, 0x0433, 0x2fe0 },
  { 0x0500, 0x0432, 0x0fe0 },
  { 0x0500, 0x0434, 0x0fe0 },
  { 0x8700, 0x06a4, 0xa000 },
  { 0x8500, 0x0563, 0x9fd0 },
  { 0x8900, 0x04b6, 0x8001 },
  { 0x8500, 0x0475, 0x7fff },
  { 0x8500, 0x0455, 0x6fb0 },
  { 0x8500, 0x0445, 0x5fe0 },
  { 0x8500, 0x043d, 0x4fe0 },
  { 0x8500, 0x0439, 0x3fe0 },
  { 0x8500, 0x0437, 0x2fe0 },
  { 0x0500, 0x0436, 0x0fe0 },
  { 0x0500, 0x0438, 0x0fe0 },
  { 0x8500, 0x043b, 0x2fe0 },
  { 0x0500, 0x043a, 0x0fe0 },
  { 0x0500, 0x043c, 0x0fe0 },
  { 0x8500, 0x0441, 0x3fe0 },
  { 0x8500, 0x043f, 0x2fe0 },
  { 0x0500, 0x043e, 0x0fe0 },
  { 0x0500, 0x0440, 0x0fe0 },
  { 0x8500, 0x0443, 0x2fe0 },
  { 0x0500, 0x0442, 0x0fe0 },
  { 0x0500, 0x0444, 0x0fe0 },
  { 0x8500, 0x044d, 0x4fe0 },
  { 0x8500, 0x0449, 0x3fe0 },
  { 0x8500, 0x0447, 0x2fe0 },
  { 0x0500, 0x0446, 0x0fe0 },
  { 0x0500, 0x0448, 0x0fe0 },
  { 0x8500, 0x044b, 0x2fe0 },
  { 0x0500, 0x044a, 0x0fe0 },
  { 0x0500, 0x044c, 0x0fe0 },
  { 0x8500, 0x0451, 0x3fb0 },
  { 0x8500, 0x044f, 0x2fe0 },
  { 0x0500, 0x044e, 0x0fe0 },
  { 0x0500, 0x0450, 0x0fb0 },
  { 0x8500, 0x0453, 0x2fb0 },
  { 0x0500, 0x0452, 0x0fb0 },
  { 0x0500, 0x0454, 0x0fb0 },
  { 0x8500, 0x0465, 0x5fff },
  { 0x8500, 0x045d, 0x4fb0 },
  { 0x8500, 0x0459, 0x3fb0 },
  { 0x8500, 0x0457, 0x2fb0 },
  { 0x0500, 0x0456, 0x0fb0 },
  { 0x0500, 0x0458, 0x0fb0 },
  { 0x8500, 0x045b, 0x2fb0 },
  { 0x0500, 0x045a, 0x0fb0 },
  { 0x0500, 0x045c, 0x0fb0 },
  { 0x8500, 0x0461, 0x3fff },
  { 0x8500, 0x045f, 0x2fb0 },
  { 0x0500, 0x045e, 0x0fb0 },
  { 0x0900, 0x0460, 0x0001 },
  { 0x8500, 0x0463, 0x2fff },
  { 0x0900, 0x0462, 0x0001 },
  { 0x0900, 0x0464, 0x0001 },
  { 0x8500, 0x046d, 0x4fff },
  { 0x8500, 0x0469, 0x3fff },
  { 0x8500, 0x0467, 0x2fff },
  { 0x0900, 0x0466, 0x0001 },
  { 0x0900, 0x0468, 0x0001 },
  { 0x8500, 0x046b, 0x2fff },
  { 0x0900, 0x046a, 0x0001 },
  { 0x0900, 0x046c, 0x0001 },
  { 0x8500, 0x0471, 0x3fff },
  { 0x8500, 0x046f, 0x2fff },
  { 0x0900, 0x046e, 0x0001 },
  { 0x0900, 0x0470, 0x0001 },
  { 0x8500, 0x0473, 0x2fff },
  { 0x0900, 0x0472, 0x0001 },
  { 0x0900, 0x0474, 0x0001 },
  { 0x8900, 0x0496, 0x6001 },
  { 0x8c00, 0x0485, 0x5000 },
  { 0x8500, 0x047d, 0x4fff },
  { 0x8500, 0x0479, 0x3fff },
  { 0x8500, 0x0477, 0x2fff },
  { 0x0900, 0x0476, 0x0001 },
  { 0x0900, 0x0478, 0x0001 },
  { 0x8500, 0x047b, 0x2fff },
  { 0x0900, 0x047a, 0x0001 },
  { 0x0900, 0x047c, 0x0001 },
  { 0x8500, 0x0481, 0x3fff },
  { 0x8500, 0x047f, 0x2fff },
  { 0x0900, 0x047e, 0x0001 },
  { 0x0900, 0x0480, 0x0001 },
  { 0x8c00, 0x0483, 0x2000 },
  { 0x1a00, 0x0482, 0x0000 },
  { 0x0c00, 0x0484, 0x0000 },
  { 0x8900, 0x048e, 0x4001 },
  { 0x8900, 0x048a, 0x3001 },
  { 0x8b00, 0x0488, 0x2000 },
  { 0x0c00, 0x0486, 0x0000 },
  { 0x0b00, 0x0489, 0x0000 },
  { 0x8900, 0x048c, 0x2001 },
  { 0x0500, 0x048b, 0x0fff },
  { 0x0500, 0x048d, 0x0fff },
  { 0x8900, 0x0492, 0x3001 },
  { 0x8900, 0x0490, 0x2001 },
  { 0x0500, 0x048f, 0x0fff },
  { 0x0500, 0x0491, 0x0fff },
  { 0x8900, 0x0494, 0x2001 },
  { 0x0500, 0x0493, 0x0fff },
  { 0x0500, 0x0495, 0x0fff },
  { 0x8900, 0x04a6, 0x5001 },
  { 0x8900, 0x049e, 0x4001 },
  { 0x8900, 0x049a, 0x3001 },
  { 0x8900, 0x0498, 0x2001 },
  { 0x0500, 0x0497, 0x0fff },
  { 0x0500, 0x0499, 0x0fff },
  { 0x8900, 0x049c, 0x2001 },
  { 0x0500, 0x049b, 0x0fff },
  { 0x0500, 0x049d, 0x0fff },
  { 0x8900, 0x04a2, 0x3001 },
  { 0x8900, 0x04a0, 0x2001 },
  { 0x0500, 0x049f, 0x0fff },
  { 0x0500, 0x04a1, 0x0fff },
  { 0x8900, 0x04a4, 0x2001 },
  { 0x0500, 0x04a3, 0x0fff },
  { 0x0500, 0x04a5, 0x0fff },
  { 0x8900, 0x04ae, 0x4001 },
  { 0x8900, 0x04aa, 0x3001 },
  { 0x8900, 0x04a8, 0x2001 },
  { 0x0500, 0x04a7, 0x0fff },
  { 0x0500, 0x04a9, 0x0fff },
  { 0x8900, 0x04ac, 0x2001 },
  { 0x0500, 0x04ab, 0x0fff },
  { 0x0500, 0x04ad, 0x0fff },
  { 0x8900, 0x04b2, 0x3001 },
  { 0x8900, 0x04b0, 0x2001 },
  { 0x0500, 0x04af, 0x0fff },
  { 0x0500, 0x04b1, 0x0fff },
  { 0x8900, 0x04b4, 0x2001 },
  { 0x0500, 0x04b3, 0x0fff },
  { 0x0500, 0x04b5, 0x0fff },
  { 0x8500, 0x04f9, 0x7fff },
  { 0x8500, 0x04d7, 0x6fff },
  { 0x8500, 0x04c6, 0x5fff },
  { 0x8900, 0x04be, 0x4001 },
  { 0x8900, 0x04ba, 0x3001 },
  { 0x8900, 0x04b8, 0x2001 },
  { 0x0500, 0x04b7, 0x0fff },
  { 0x0500, 0x04b9, 0x0fff },
  { 0x8900, 0x04bc, 0x2001 },
  { 0x0500, 0x04bb, 0x0fff },
  { 0x0500, 0x04bd, 0x0fff },
  { 0x8500, 0x04c2, 0x3fff },
  { 0x8900, 0x04c0, 0x2000 },
  { 0x0500, 0x04bf, 0x0fff },
  { 0x0900, 0x04c1, 0x0001 },
  { 0x8500, 0x04c4, 0x2fff },
  { 0x0900, 0x04c3, 0x0001 },
  { 0x0900, 0x04c5, 0x0001 },
  { 0x8500, 0x04ce, 0x4fff },
  { 0x8500, 0x04ca, 0x3fff },
  { 0x8500, 0x04c8, 0x2fff },
  { 0x0900, 0x04c7, 0x0001 },
  { 0x0900, 0x04c9, 0x0001 },
  { 0x8500, 0x04cc, 0x2fff },
  { 0x0900, 0x04cb, 0x0001 },
  { 0x0900, 0x04cd, 0x0001 },
  { 0x8500, 0x04d3, 0x3fff },
  { 0x8500, 0x04d1, 0x2fff },
  { 0x0900, 0x04d0, 0x0001 },
  { 0x0900, 0x04d2, 0x0001 },
  { 0x8500, 0x04d5, 0x2fff },
  { 0x0900, 0x04d4, 0x0001 },
  { 0x0900, 0x04d6, 0x0001 },
  { 0x8500, 0x04e7, 0x5fff },
  { 0x8500, 0x04df, 0x4fff },
  { 0x8500, 0x04db, 0x3fff },
  { 0x8500, 0x04d9, 0x2fff },
  { 0x0900, 0x04d8, 0x0001 },
  { 0x0900, 0x04da, 0x0001 },
  { 0x8500, 0x04dd, 0x2fff },
  { 0x0900, 0x04dc, 0x0001 },
  { 0x0900, 0x04de, 0x0001 },
  { 0x8500, 0x04e3, 0x3fff },
  { 0x8500, 0x04e1, 0x2fff },
  { 0x0900, 0x04e0, 0x0001 },
  { 0x0900, 0x04e2, 0x0001 },
  { 0x8500, 0x04e5, 0x2fff },
  { 0x0900, 0x04e4, 0x0001 },
  { 0x0900, 0x04e6, 0x0001 },
  { 0x8500, 0x04ef, 0x4fff },
  { 0x8500, 0x04eb, 0x3fff },
  { 0x8500, 0x04e9, 0x2fff },
  { 0x0900, 0x04e8, 0x0001 },
  { 0x0900, 0x04ea, 0x0001 },
  { 0x8500, 0x04ed, 0x2fff },
  { 0x0900, 0x04ec, 0x0001 },
  { 0x0900, 0x04ee, 0x0001 },
  { 0x8500, 0x04f3, 0x3fff },
  { 0x8500, 0x04f1, 0x2fff },
  { 0x0900, 0x04f0, 0x0001 },
  { 0x0900, 0x04f2, 0x0001 },
  { 0x8500, 0x04f5, 0x2fff },
  { 0x0900, 0x04f4, 0x0001 },
  { 0x0900, 0x04f8, 0x0001 },
  { 0x8900, 0x0540, 0x6030 },
  { 0x8500, 0x050f, 0x5fff },
  { 0x8500, 0x0507, 0x4fff },
  { 0x8500, 0x0503, 0x3fff },
  { 0x8500, 0x0501, 0x2fff },
  { 0x0900, 0x0500, 0x0001 },
  { 0x0900, 0x0502, 0x0001 },
  { 0x8500, 0x0505, 0x2fff },
  { 0x0900, 0x0504, 0x0001 },
  { 0x0900, 0x0506, 0x0001 },
  { 0x8500, 0x050b, 0x3fff },
  { 0x8500, 0x0509, 0x2fff },
  { 0x0900, 0x0508, 0x0001 },
  { 0x0900, 0x050a, 0x0001 },
  { 0x8500, 0x050d, 0x2fff },
  { 0x0900, 0x050c, 0x0001 },
  { 0x0900, 0x050e, 0x0001 },
  { 0x8900, 0x0538, 0x4030 },
  { 0x8900, 0x0534, 0x3030 },
  { 0x8900, 0x0532, 0x2030 },
  { 0x0900, 0x0531, 0x0030 },
  { 0x0900, 0x0533, 0x0030 },
  { 0x8900, 0x0536, 0x2030 },
  { 0x0900, 0x0535, 0x0030 },
  { 0x0900, 0x0537, 0x0030 },
  { 0x8900, 0x053c, 0x3030 },
  { 0x8900, 0x053a, 0x2030 },
  { 0x0900, 0x0539, 0x0030 },
  { 0x0900, 0x053b, 0x0030 },
  { 0x8900, 0x053e, 0x2030 },
  { 0x0900, 0x053d, 0x0030 },
  { 0x0900, 0x053f, 0x0030 },
  { 0x8900, 0x0550, 0x5030 },
  { 0x8900, 0x0548, 0x4030 },
  { 0x8900, 0x0544, 0x3030 },
  { 0x8900, 0x0542, 0x2030 },
  { 0x0900, 0x0541, 0x0030 },
  { 0x0900, 0x0543, 0x0030 },
  { 0x8900, 0x0546, 0x2030 },
  { 0x0900, 0x0545, 0x0030 },
  { 0x0900, 0x0547, 0x0030 },
  { 0x8900, 0x054c, 0x3030 },
  { 0x8900, 0x054a, 0x2030 },
  { 0x0900, 0x0549, 0x0030 },
  { 0x0900, 0x054b, 0x0030 },
  { 0x8900, 0x054e, 0x2030 },
  { 0x0900, 0x054d, 0x0030 },
  { 0x0900, 0x054f, 0x0030 },
  { 0x9500, 0x055a, 0x4000 },
  { 0x8900, 0x0554, 0x3030 },
  { 0x8900, 0x0552, 0x2030 },
  { 0x0900, 0x0551, 0x0030 },
  { 0x0900, 0x0553, 0x0030 },
  { 0x8900, 0x0556, 0x2030 },
  { 0x0900, 0x0555, 0x0030 },
  { 0x0600, 0x0559, 0x0000 },
  { 0x9500, 0x055e, 0x3000 },
  { 0x9500, 0x055c, 0x2000 },
  { 0x1500, 0x055b, 0x0000 },
  { 0x1500, 0x055d, 0x0000 },
  { 0x8500, 0x0561, 0x2fd0 },
  { 0x1500, 0x055f, 0x0000 },
  { 0x0500, 0x0562, 0x0fd0 },
  { 0x9a00, 0x060f, 0x8000 },
  { 0x8c00, 0x05ab, 0x7000 },
  { 0x8500, 0x0583, 0x6fd0 },
  { 0x8500, 0x0573, 0x5fd0 },
  { 0x8500, 0x056b, 0x4fd0 },
  { 0x8500, 0x0567, 0x3fd0 },
  { 0x8500, 0x0565, 0x2fd0 },
  { 0x0500, 0x0564, 0x0fd0 },
  { 0x0500, 0x0566, 0x0fd0 },
  { 0x8500, 0x0569, 0x2fd0 },
  { 0x0500, 0x0568, 0x0fd0 },
  { 0x0500, 0x056a, 0x0fd0 },
  { 0x8500, 0x056f, 0x3fd0 },
  { 0x8500, 0x056d, 0x2fd0 },
  { 0x0500, 0x056c, 0x0fd0 },
  { 0x0500, 0x056e, 0x0fd0 },
  { 0x8500, 0x0571, 0x2fd0 },
  { 0x0500, 0x0570, 0x0fd0 },
  { 0x0500, 0x0572, 0x0fd0 },
  { 0x8500, 0x057b, 0x4fd0 },
  { 0x8500, 0x0577, 0x3fd0 },
  { 0x8500, 0x0575, 0x2fd0 },
  { 0x0500, 0x0574, 0x0fd0 },
  { 0x0500, 0x0576, 0x0fd0 },
  { 0x8500, 0x0579, 0x2fd0 },
  { 0x0500, 0x0578, 0x0fd0 },
  { 0x0500, 0x057a, 0x0fd0 },
  { 0x8500, 0x057f, 0x3fd0 },
  { 0x8500, 0x057d, 0x2fd0 },
  { 0x0500, 0x057c, 0x0fd0 },
  { 0x0500, 0x057e, 0x0fd0 },
  { 0x8500, 0x0581, 0x2fd0 },
  { 0x0500, 0x0580, 0x0fd0 },
  { 0x0500, 0x0582, 0x0fd0 },
  { 0x8c00, 0x059a, 0x5000 },
  { 0x8c00, 0x0592, 0x4000 },
  { 0x8500, 0x0587, 0x3000 },
  { 0x8500, 0x0585, 0x2fd0 },
  { 0x0500, 0x0584, 0x0fd0 },
  { 0x0500, 0x0586, 0x0fd0 },
  { 0x9100, 0x058a, 0x2000 },
  { 0x1500, 0x0589, 0x0000 },
  { 0x0c00, 0x0591, 0x0000 },
  { 0x8c00, 0x0596, 0x3000 },
  { 0x8c00, 0x0594, 0x2000 },
  { 0x0c00, 0x0593, 0x0000 },
  { 0x0c00, 0x0595, 0x0000 },
  { 0x8c00, 0x0598, 0x2000 },
  { 0x0c00, 0x0597, 0x0000 },
  { 0x0c00, 0x0599, 0x0000 },
  { 0x8c00, 0x05a3, 0x4000 },
  { 0x8c00, 0x059e, 0x3000 },
  { 0x8c00, 0x059c, 0x2000 },
  { 0x0c00, 0x059b, 0x0000 },
  { 0x0c00, 0x059d, 0x0000 },
  { 0x8c00, 0x05a0, 0x2000 },
  { 0x0c00, 0x059f, 0x0000 },
  { 0x0c00, 0x05a1, 0x0000 },
  { 0x8c00, 0x05a7, 0x3000 },
  { 0x8c00, 0x05a5, 0x2000 },
  { 0x0c00, 0x05a4, 0x0000 },
  { 0x0c00, 0x05a6, 0x0000 },
  { 0x8c00, 0x05a9, 0x2000 },
  { 0x0c00, 0x05a8, 0x0000 },
  { 0x0c00, 0x05aa, 0x0000 },
  { 0x8700, 0x05d7, 0x6000 },
  { 0x8c00, 0x05bc, 0x5000 },
  { 0x8c00, 0x05b3, 0x4000 },
  { 0x8c00, 0x05af, 0x3000 },
  { 0x8c00, 0x05ad, 0x2000 },
  { 0x0c00, 0x05ac, 0x0000 },
  { 0x0c00, 0x05ae, 0x0000 },
  { 0x8c00, 0x05b1, 0x2000 },
  { 0x0c00, 0x05b0, 0x0000 },
  { 0x0c00, 0x05b2, 0x0000 },
  { 0x8c00, 0x05b7, 0x3000 },
  { 0x8c00, 0x05b5, 0x2000 },
  { 0x0c00, 0x05b4, 0x0000 },
  { 0x0c00, 0x05b6, 0x0000 },
  { 0x8c00, 0x05b9, 0x2000 },
  { 0x0c00, 0x05b8, 0x0000 },
  { 0x0c00, 0x05bb, 0x0000 },
  { 0x8c00, 0x05c4, 0x4000 },
  { 0x9500, 0x05c0, 0x3000 },
  { 0x9500, 0x05be, 0x2000 },
  { 0x0c00, 0x05bd, 0x0000 },
  { 0x0c00, 0x05bf, 0x0000 },
  { 0x8c00, 0x05c2, 0x2000 },
  { 0x0c00, 0x05c1, 0x0000 },
  { 0x1500, 0x05c3, 0x0000 },
  { 0x8700, 0x05d3, 0x3000 },
  { 0x8700, 0x05d1, 0x2000 },
  { 0x0700, 0x05d0, 0x0000 },
  { 0x0700, 0x05d2, 0x0000 },
  { 0x8700, 0x05d5, 0x2000 },
  { 0x0700, 0x05d4, 0x0000 },
  { 0x0700, 0x05d6, 0x0000 },
  { 0x8700, 0x05e7, 0x5000 },
  { 0x8700, 0x05df, 0x4000 },
  { 0x8700, 0x05db, 0x3000 },
  { 0x8700, 0x05d9, 0x2000 },
  { 0x0700, 0x05d8, 0x0000 },
  { 0x0700, 0x05da, 0x0000 },
  { 0x8700, 0x05dd, 0x2000 },
  { 0x0700, 0x05dc, 0x0000 },
  { 0x0700, 0x05de, 0x0000 },
  { 0x8700, 0x05e3, 0x3000 },
  { 0x8700, 0x05e1, 0x2000 },
  { 0x0700, 0x05e0, 0x0000 },
  { 0x0700, 0x05e2, 0x0000 },
  { 0x8700, 0x05e5, 0x2000 },
  { 0x0700, 0x05e4, 0x0000 },
  { 0x0700, 0x05e6, 0x0000 },
  { 0x9500, 0x05f4, 0x4000 },
  { 0x8700, 0x05f0, 0x3000 },
  { 0x8700, 0x05e9, 0x2000 },
  { 0x0700, 0x05e8, 0x0000 },
  { 0x0700, 0x05ea, 0x0000 },
  { 0x8700, 0x05f2, 0x2000 },
  { 0x0700, 0x05f1, 0x0000 },
  { 0x1500, 0x05f3, 0x0000 },
  { 0x8100, 0x0603, 0x3000 },
  { 0x8100, 0x0601, 0x2000 },
  { 0x0100, 0x0600, 0x0000 },
  { 0x0100, 0x0602, 0x0000 },
  { 0x9500, 0x060d, 0x2000 },
  { 0x1500, 0x060c, 0x0000 },
  { 0x1a00, 0x060e, 0x0000 },
  { 0x8d00, 0x0664, 0x7000 },
  { 0x8700, 0x0638, 0x6000 },
  { 0x8700, 0x0628, 0x5000 },
  { 0x9500, 0x061f, 0x4000 },
  { 0x8c00, 0x0613, 0x3000 },
  { 0x8c00, 0x0611, 0x2000 },
  { 0x0c00, 0x0610, 0x0000 },
  { 0x0c00, 0x0612, 0x0000 },
  { 0x8c00, 0x0615, 0x2000 },
  { 0x0c00, 0x0614, 0x0000 },
  { 0x1500, 0x061b, 0x0000 },
  { 0x8700, 0x0624, 0x3000 },
  { 0x8700, 0x0622, 0x2000 },
  { 0x0700, 0x0621, 0x0000 },
  { 0x0700, 0x0623, 0x0000 },
  { 0x8700, 0x0626, 0x2000 },
  { 0x0700, 0x0625, 0x0000 },
  { 0x0700, 0x0627, 0x0000 },
  { 0x8700, 0x0630, 0x4000 },
  { 0x8700, 0x062c, 0x3000 },
  { 0x8700, 0x062a, 0x2000 },
  { 0x0700, 0x0629, 0x0000 },
  { 0x0700, 0x062b, 0x0000 },
  { 0x8700, 0x062e, 0x2000 },
  { 0x0700, 0x062d, 0x0000 },
  { 0x0700, 0x062f, 0x0000 },
  { 0x8700, 0x0634, 0x3000 },
  { 0x8700, 0x0632, 0x2000 },
  { 0x0700, 0x0631, 0x0000 },
  { 0x0700, 0x0633, 0x0000 },
  { 0x8700, 0x0636, 0x2000 },
  { 0x0700, 0x0635, 0x0000 },
  { 0x0700, 0x0637, 0x0000 },
  { 0x8c00, 0x064d, 0x5000 },
  { 0x8700, 0x0645, 0x4000 },
  { 0x8700, 0x0641, 0x3000 },
  { 0x8700, 0x063a, 0x2000 },
  { 0x0700, 0x0639, 0x0000 },
  { 0x0600, 0x0640, 0x0000 },
  { 0x8700, 0x0643, 0x2000 },
  { 0x0700, 0x0642, 0x0000 },
  { 0x0700, 0x0644, 0x0000 },
  { 0x8700, 0x0649, 0x3000 },
  { 0x8700, 0x0647, 0x2000 },
  { 0x0700, 0x0646, 0x0000 },
  { 0x0700, 0x0648, 0x0000 },
  { 0x8c00, 0x064b, 0x2000 },
  { 0x0700, 0x064a, 0x0000 },
  { 0x0c00, 0x064c, 0x0000 },
  { 0x8c00, 0x0655, 0x4000 },
  { 0x8c00, 0x0651, 0x3000 },
  { 0x8c00, 0x064f, 0x2000 },
  { 0x0c00, 0x064e, 0x0000 },
  { 0x0c00, 0x0650, 0x0000 },
  { 0x8c00, 0x0653, 0x2000 },
  { 0x0c00, 0x0652, 0x0000 },
  { 0x0c00, 0x0654, 0x0000 },
  { 0x8d00, 0x0660, 0x3000 },
  { 0x8c00, 0x0657, 0x2000 },
  { 0x0c00, 0x0656, 0x0000 },
  { 0x0c00, 0x0658, 0x0000 },
  { 0x8d00, 0x0662, 0x2000 },
  { 0x0d00, 0x0661, 0x0000 },
  { 0x0d00, 0x0663, 0x0000 },
  { 0x8700, 0x0684, 0x6000 },
  { 0x8700, 0x0674, 0x5000 },
  { 0x9500, 0x066c, 0x4000 },
  { 0x8d00, 0x0668, 0x3000 },
  { 0x8d00, 0x0666, 0x2000 },
  { 0x0d00, 0x0665, 0x0000 },
  { 0x0d00, 0x0667, 0x0000 },
  { 0x9500, 0x066a, 0x2000 },
  { 0x0d00, 0x0669, 0x0000 },
  { 0x1500, 0x066b, 0x0000 },
  { 0x8c00, 0x0670, 0x3000 },
  { 0x8700, 0x066e, 0x2000 },
  { 0x1500, 0x066d, 0x0000 },
  { 0x0700, 0x066f, 0x0000 },
  { 0x8700, 0x0672, 0x2000 },
  { 0x0700, 0x0671, 0x0000 },
  { 0x0700, 0x0673, 0x0000 },
  { 0x8700, 0x067c, 0x4000 },
  { 0x8700, 0x0678, 0x3000 },
  { 0x8700, 0x0676, 0x2000 },
  { 0x0700, 0x0675, 0x0000 },
  { 0x0700, 0x0677, 0x0000 },
  { 0x8700, 0x067a, 0x2000 },
  { 0x0700, 0x0679, 0x0000 },
  { 0x0700, 0x067b, 0x0000 },
  { 0x8700, 0x0680, 0x3000 },
  { 0x8700, 0x067e, 0x2000 },
  { 0x0700, 0x067d, 0x0000 },
  { 0x0700, 0x067f, 0x0000 },
  { 0x8700, 0x0682, 0x2000 },
  { 0x0700, 0x0681, 0x0000 },
  { 0x0700, 0x0683, 0x0000 },
  { 0x8700, 0x0694, 0x5000 },
  { 0x8700, 0x068c, 0x4000 },
  { 0x8700, 0x0688, 0x3000 },
  { 0x8700, 0x0686, 0x2000 },
  { 0x0700, 0x0685, 0x0000 },
  { 0x0700, 0x0687, 0x0000 },
  { 0x8700, 0x068a, 0x2000 },
  { 0x0700, 0x0689, 0x0000 },
  { 0x0700, 0x068b, 0x0000 },
  { 0x8700, 0x0690, 0x3000 },
  { 0x8700, 0x068e, 0x2000 },
  { 0x0700, 0x068d, 0x0000 },
  { 0x0700, 0x068f, 0x0000 },
  { 0x8700, 0x0692, 0x2000 },
  { 0x0700, 0x0691, 0x0000 },
  { 0x0700, 0x0693, 0x0000 },
  { 0x8700, 0x069c, 0x4000 },
  { 0x8700, 0x0698, 0x3000 },
  { 0x8700, 0x0696, 0x2000 },
  { 0x0700, 0x0695, 0x0000 },
  { 0x0700, 0x0697, 0x0000 },
  { 0x8700, 0x069a, 0x2000 },
  { 0x0700, 0x0699, 0x0000 },
  { 0x0700, 0x069b, 0x0000 },
  { 0x8700, 0x06a0, 0x3000 },
  { 0x8700, 0x069e, 0x2000 },
  { 0x0700, 0x069d, 0x0000 },
  { 0x0700, 0x069f, 0x0000 },
  { 0x8700, 0x06a2, 0x2000 },
  { 0x0700, 0x06a1, 0x0000 },
  { 0x0700, 0x06a3, 0x0000 },
  { 0x8700, 0x0926, 0x9000 },
  { 0x8700, 0x0725, 0x8000 },
  { 0x8c00, 0x06e4, 0x7000 },
  { 0x8700, 0x06c4, 0x6000 },
  { 0x8700, 0x06b4, 0x5000 },
  { 0x8700, 0x06ac, 0x4000 },
  { 0x8700, 0x06a8, 0x3000 },
  { 0x8700, 0x06a6, 0x2000 },
  { 0x0700, 0x06a5, 0x0000 },
  { 0x0700, 0x06a7, 0x0000 },
  { 0x8700, 0x06aa, 0x2000 },
  { 0x0700, 0x06a9, 0x0000 },
  { 0x0700, 0x06ab, 0x0000 },
  { 0x8700, 0x06b0, 0x3000 },
  { 0x8700, 0x06ae, 0x2000 },
  { 0x0700, 0x06ad, 0x0000 },
  { 0x0700, 0x06af, 0x0000 },
  { 0x8700, 0x06b2, 0x2000 },
  { 0x0700, 0x06b1, 0x0000 },
  { 0x0700, 0x06b3, 0x0000 },
  { 0x8700, 0x06bc, 0x4000 },
  { 0x8700, 0x06b8, 0x3000 },
  { 0x8700, 0x06b6, 0x2000 },
  { 0x0700, 0x06b5, 0x0000 },
  { 0x0700, 0x06b7, 0x0000 },
  { 0x8700, 0x06ba, 0x2000 },
  { 0x0700, 0x06b9, 0x0000 },
  { 0x0700, 0x06bb, 0x0000 },
  { 0x8700, 0x06c0, 0x3000 },
  { 0x8700, 0x06be, 0x2000 },
  { 0x0700, 0x06bd, 0x0000 },
  { 0x0700, 0x06bf, 0x0000 },
  { 0x8700, 0x06c2, 0x2000 },
  { 0x0700, 0x06c1, 0x0000 },
  { 0x0700, 0x06c3, 0x0000 },
  { 0x9500, 0x06d4, 0x5000 },
  { 0x8700, 0x06cc, 0x4000 },
  { 0x8700, 0x06c8, 0x3000 },
  { 0x8700, 0x06c6, 0x2000 },
  { 0x0700, 0x06c5, 0x0000 },
  { 0x0700, 0x06c7, 0x0000 },
  { 0x8700, 0x06ca, 0x2000 },
  { 0x0700, 0x06c9, 0x0000 },
  { 0x0700, 0x06cb, 0x0000 },
  { 0x8700, 0x06d0, 0x3000 },
  { 0x8700, 0x06ce, 0x2000 },
  { 0x0700, 0x06cd, 0x0000 },
  { 0x0700, 0x06cf, 0x0000 },
  { 0x8700, 0x06d2, 0x2000 },
  { 0x0700, 0x06d1, 0x0000 },
  { 0x0700, 0x06d3, 0x0000 },
  { 0x8c00, 0x06dc, 0x4000 },
  { 0x8c00, 0x06d8, 0x3000 },
  { 0x8c00, 0x06d6, 0x2000 },
  { 0x0700, 0x06d5, 0x0000 },
  { 0x0c00, 0x06d7, 0x0000 },
  { 0x8c00, 0x06da, 0x2000 },
  { 0x0c00, 0x06d9, 0x0000 },
  { 0x0c00, 0x06db, 0x0000 },
  { 0x8c00, 0x06e0, 0x3000 },
  { 0x8b00, 0x06de, 0x2000 },
  { 0x0100, 0x06dd, 0x0000 },
  { 0x0c00, 0x06df, 0x0000 },
  { 0x8c00, 0x06e2, 0x2000 },
  { 0x0c00, 0x06e1, 0x0000 },
  { 0x0c00, 0x06e3, 0x0000 },
  { 0x9500, 0x0704, 0x6000 },
  { 0x8d00, 0x06f4, 0x5000 },
  { 0x8c00, 0x06ec, 0x4000 },
  { 0x8c00, 0x06e8, 0x3000 },
  { 0x8600, 0x06e6, 0x2000 },
  { 0x0600, 0x06e5, 0x0000 },
  { 0x0c00, 0x06e7, 0x0000 },
  { 0x8c00, 0x06ea, 0x2000 },
  { 0x1a00, 0x06e9, 0x0000 },
  { 0x0c00, 0x06eb, 0x0000 },
  { 0x8d00, 0x06f0, 0x3000 },
  { 0x8700, 0x06ee, 0x2000 },
  { 0x0c00, 0x06ed, 0x0000 },
  { 0x0700, 0x06ef, 0x0000 },
  { 0x8d00, 0x06f2, 0x2000 },
  { 0x0d00, 0x06f1, 0x0000 },
  { 0x0d00, 0x06f3, 0x0000 },
  { 0x8700, 0x06fc, 0x4000 },
  { 0x8d00, 0x06f8, 0x3000 },
  { 0x8d00, 0x06f6, 0x2000 },
  { 0x0d00, 0x06f5, 0x0000 },
  { 0x0d00, 0x06f7, 0x0000 },
  { 0x8700, 0x06fa, 0x2000 },
  { 0x0d00, 0x06f9, 0x0000 },
  { 0x0700, 0x06fb, 0x0000 },
  { 0x9500, 0x0700, 0x3000 },
  { 0x9a00, 0x06fe, 0x2000 },
  { 0x1a00, 0x06fd, 0x0000 },
  { 0x0700, 0x06ff, 0x0000 },
  { 0x9500, 0x0702, 0x2000 },
  { 0x1500, 0x0701, 0x0000 },
  { 0x1500, 0x0703, 0x0000 },
  { 0x8700, 0x0715, 0x5000 },
  { 0x9500, 0x070c, 0x4000 },
  { 0x9500, 0x0708, 0x3000 },
  { 0x9500, 0x0706, 0x2000 },
  { 0x1500, 0x0705, 0x0000 },
  { 0x1500, 0x0707, 0x0000 },
  { 0x9500, 0x070a, 0x2000 },
  { 0x1500, 0x0709, 0x0000 },
  { 0x1500, 0x070b, 0x0000 },
  { 0x8c00, 0x0711, 0x3000 },
  { 0x8100, 0x070f, 0x2000 },
  { 0x1500, 0x070d, 0x0000 },
  { 0x0700, 0x0710, 0x0000 },
  { 0x8700, 0x0713, 0x2000 },
  { 0x0700, 0x0712, 0x0000 },
  { 0x0700, 0x0714, 0x0000 },
  { 0x8700, 0x071d, 0x4000 },
  { 0x8700, 0x0719, 0x3000 },
  { 0x8700, 0x0717, 0x2000 },
  { 0x0700, 0x0716, 0x0000 },
  { 0x0700, 0x0718, 0x0000 },
  { 0x8700, 0x071b, 0x2000 },
  { 0x0700, 0x071a, 0x0000 },
  { 0x0700, 0x071c, 0x0000 },
  { 0x8700, 0x0721, 0x3000 },
  { 0x8700, 0x071f, 0x2000 },
  { 0x0700, 0x071e, 0x0000 },
  { 0x0700, 0x0720, 0x0000 },
  { 0x8700, 0x0723, 0x2000 },
  { 0x0700, 0x0722, 0x0000 },
  { 0x0700, 0x0724, 0x0000 },
  { 0x8700, 0x0797, 0x7000 },
  { 0x8c00, 0x0745, 0x6000 },
  { 0x8c00, 0x0735, 0x5000 },
  { 0x8700, 0x072d, 0x4000 },
  { 0x8700, 0x0729, 0x3000 },
  { 0x8700, 0x0727, 0x2000 },
  { 0x0700, 0x0726, 0x0000 },
  { 0x0700, 0x0728, 0x0000 },
  { 0x8700, 0x072b, 0x2000 },
  { 0x0700, 0x072a, 0x0000 },
  { 0x0700, 0x072c, 0x0000 },
  { 0x8c00, 0x0731, 0x3000 },
  { 0x8700, 0x072f, 0x2000 },
  { 0x0700, 0x072e, 0x0000 },
  { 0x0c00, 0x0730, 0x0000 },
  { 0x8c00, 0x0733, 0x2000 },
  { 0x0c00, 0x0732, 0x0000 },
  { 0x0c00, 0x0734, 0x0000 },
  { 0x8c00, 0x073d, 0x4000 },
  { 0x8c00, 0x0739, 0x3000 },
  { 0x8c00, 0x0737, 0x2000 },
  { 0x0c00, 0x0736, 0x0000 },
  { 0x0c00, 0x0738, 0x0000 },
  { 0x8c00, 0x073b, 0x2000 },
  { 0x0c00, 0x073a, 0x0000 },
  { 0x0c00, 0x073c, 0x0000 },
  { 0x8c00, 0x0741, 0x3000 },
  { 0x8c00, 0x073f, 0x2000 },
  { 0x0c00, 0x073e, 0x0000 },
  { 0x0c00, 0x0740, 0x0000 },
  { 0x8c00, 0x0743, 0x2000 },
  { 0x0c00, 0x0742, 0x0000 },
  { 0x0c00, 0x0744, 0x0000 },
  { 0x8700, 0x0787, 0x5000 },
  { 0x8700, 0x074f, 0x4000 },
  { 0x8c00, 0x0749, 0x3000 },
  { 0x8c00, 0x0747, 0x2000 },
  { 0x0c00, 0x0746, 0x0000 },
  { 0x0c00, 0x0748, 0x0000 },
  { 0x8700, 0x074d, 0x2000 },
  { 0x0c00, 0x074a, 0x0000 },
  { 0x0700, 0x074e, 0x0000 },
  { 0x8700, 0x0783, 0x3000 },
  { 0x8700, 0x0781, 0x2000 },
  { 0x0700, 0x0780, 0x0000 },
  { 0x0700, 0x0782, 0x0000 },
  { 0x8700, 0x0785, 0x2000 },
  { 0x0700, 0x0784, 0x0000 },
  { 0x0700, 0x0786, 0x0000 },
  { 0x8700, 0x078f, 0x4000 },
  { 0x8700, 0x078b, 0x3000 },
  { 0x8700, 0x0789, 0x2000 },
  { 0x0700, 0x0788, 0x0000 },
  { 0x0700, 0x078a, 0x0000 },
  { 0x8700, 0x078d, 0x2000 },
  { 0x0700, 0x078c, 0x0000 },
  { 0x0700, 0x078e, 0x0000 },
  { 0x8700, 0x0793, 0x3000 },
  { 0x8700, 0x0791, 0x2000 },
  { 0x0700, 0x0790, 0x0000 },
  { 0x0700, 0x0792, 0x0000 },
  { 0x8700, 0x0795, 0x2000 },
  { 0x0700, 0x0794, 0x0000 },
  { 0x0700, 0x0796, 0x0000 },
  { 0x8700, 0x0906, 0x6000 },
  { 0x8c00, 0x07a7, 0x5000 },
  { 0x8700, 0x079f, 0x4000 },
  { 0x8700, 0x079b, 0x3000 },
  { 0x8700, 0x0799, 0x2000 },
  { 0x0700, 0x0798, 0x0000 },
  { 0x0700, 0x079a, 0x0000 },
  { 0x8700, 0x079d, 0x2000 },
  { 0x0700, 0x079c, 0x0000 },
  { 0x0700, 0x079e, 0x0000 },
  { 0x8700, 0x07a3, 0x3000 },
  { 0x8700, 0x07a1, 0x2000 },
  { 0x0700, 0x07a0, 0x0000 },
  { 0x0700, 0x07a2, 0x0000 },
  { 0x8700, 0x07a5, 0x2000 },
  { 0x0700, 0x07a4, 0x0000 },
  { 0x0c00, 0x07a6, 0x0000 },
  { 0x8c00, 0x07af, 0x4000 },
  { 0x8c00, 0x07ab, 0x3000 },
  { 0x8c00, 0x07a9, 0x2000 },
  { 0x0c00, 0x07a8, 0x0000 },
  { 0x0c00, 0x07aa, 0x0000 },
  { 0x8c00, 0x07ad, 0x2000 },
  { 0x0c00, 0x07ac, 0x0000 },
  { 0x0c00, 0x07ae, 0x0000 },
  { 0x8c00, 0x0902, 0x3000 },
  { 0x8700, 0x07b1, 0x2000 },
  { 0x0c00, 0x07b0, 0x0000 },
  { 0x0c00, 0x0901, 0x0000 },
  { 0x8700, 0x0904, 0x2000 },
  { 0x0a00, 0x0903, 0x0000 },
  { 0x0700, 0x0905, 0x0000 },
  { 0x8700, 0x0916, 0x5000 },
  { 0x8700, 0x090e, 0x4000 },
  { 0x8700, 0x090a, 0x3000 },
  { 0x8700, 0x0908, 0x2000 },
  { 0x0700, 0x0907, 0x0000 },
  { 0x0700, 0x0909, 0x0000 },
  { 0x8700, 0x090c, 0x2000 },
  { 0x0700, 0x090b, 0x0000 },
  { 0x0700, 0x090d, 0x0000 },
  { 0x8700, 0x0912, 0x3000 },
  { 0x8700, 0x0910, 0x2000 },
  { 0x0700, 0x090f, 0x0000 },
  { 0x0700, 0x0911, 0x0000 },
  { 0x8700, 0x0914, 0x2000 },
  { 0x0700, 0x0913, 0x0000 },
  { 0x0700, 0x0915, 0x0000 },
  { 0x8700, 0x091e, 0x4000 },
  { 0x8700, 0x091a, 0x3000 },
  { 0x8700, 0x0918, 0x2000 },
  { 0x0700, 0x0917, 0x0000 },
  { 0x0700, 0x0919, 0x0000 },
  { 0x8700, 0x091c, 0x2000 },
  { 0x0700, 0x091b, 0x0000 },
  { 0x0700, 0x091d, 0x0000 },
  { 0x8700, 0x0922, 0x3000 },
  { 0x8700, 0x0920, 0x2000 },
  { 0x0700, 0x091f, 0x0000 },
  { 0x0700, 0x0921, 0x0000 },
  { 0x8700, 0x0924, 0x2000 },
  { 0x0700, 0x0923, 0x0000 },
  { 0x0700, 0x0925, 0x0000 },
  { 0x8c00, 0x09cd, 0x8000 },
  { 0x8d00, 0x096d, 0x7000 },
  { 0x8c00, 0x0948, 0x6000 },
  { 0x8700, 0x0936, 0x5000 },
  { 0x8700, 0x092e, 0x4000 },
  { 0x8700, 0x092a, 0x3000 },
  { 0x8700, 0x0928, 0x2000 },
  { 0x0700, 0x0927, 0x0000 },
  { 0x0700, 0x0929, 0x0000 },
  { 0x8700, 0x092c, 0x2000 },
  { 0x0700, 0x092b, 0x0000 },
  { 0x0700, 0x092d, 0x0000 },
  { 0x8700, 0x0932, 0x3000 },
  { 0x8700, 0x0930, 0x2000 },
  { 0x0700, 0x092f, 0x0000 },
  { 0x0700, 0x0931, 0x0000 },
  { 0x8700, 0x0934, 0x2000 },
  { 0x0700, 0x0933, 0x0000 },
  { 0x0700, 0x0935, 0x0000 },
  { 0x8a00, 0x0940, 0x4000 },
  { 0x8c00, 0x093c, 0x3000 },
  { 0x8700, 0x0938, 0x2000 },
  { 0x0700, 0x0937, 0x0000 },
  { 0x0700, 0x0939, 0x0000 },
  { 0x8a00, 0x093e, 0x2000 },
  { 0x0700, 0x093d, 0x0000 },
  { 0x0a00, 0x093f, 0x0000 },
  { 0x8c00, 0x0944, 0x3000 },
  { 0x8c00, 0x0942, 0x2000 },
  { 0x0c00, 0x0941, 0x0000 },
  { 0x0c00, 0x0943, 0x0000 },
  { 0x8c00, 0x0946, 0x2000 },
  { 0x0c00, 0x0945, 0x0000 },
  { 0x0c00, 0x0947, 0x0000 },
  { 0x8700, 0x095d, 0x5000 },
  { 0x8c00, 0x0952, 0x4000 },
  { 0x8a00, 0x094c, 0x3000 },
  { 0x8a00, 0x094a, 0x2000 },
  { 0x0a00, 0x0949, 0x0000 },
  { 0x0a00, 0x094b, 0x0000 },
  { 0x8700, 0x0950, 0x2000 },
  { 0x0c00, 0x094d, 0x0000 },
  { 0x0c00, 0x0951, 0x0000 },
  { 0x8700, 0x0959, 0x3000 },
  { 0x8c00, 0x0954, 0x2000 },
  { 0x0c00, 0x0953, 0x0000 },
  { 0x0700, 0x0958, 0x0000 },
  { 0x8700, 0x095b, 0x2000 },
  { 0x0700, 0x095a, 0x0000 },
  { 0x0700, 0x095c, 0x0000 },
  { 0x9500, 0x0965, 0x4000 },
  { 0x8700, 0x0961, 0x3000 },
  { 0x8700, 0x095f, 0x2000 },
  { 0x0700, 0x095e, 0x0000 },
  { 0x0700, 0x0960, 0x0000 },
  { 0x8c00, 0x0963, 0x2000 },
  { 0x0c00, 0x0962, 0x0000 },
  { 0x1500, 0x0964, 0x0000 },
  { 0x8d00, 0x0969, 0x3000 },
  { 0x8d00, 0x0967, 0x2000 },
  { 0x0d00, 0x0966, 0x0000 },
  { 0x0d00, 0x0968, 0x0000 },
  { 0x8d00, 0x096b, 0x2000 },
  { 0x0d00, 0x096a, 0x0000 },
  { 0x0d00, 0x096c, 0x0000 },
  { 0x8700, 0x09a2, 0x6000 },
  { 0x8700, 0x0990, 0x5000 },
  { 0x8700, 0x0986, 0x4000 },
  { 0x8c00, 0x0981, 0x3000 },
  { 0x8d00, 0x096f, 0x2000 },
  { 0x0d00, 0x096e, 0x0000 },
  { 0x1500, 0x0970, 0x0000 },
  { 0x8a00, 0x0983, 0x2000 },
  { 0x0a00, 0x0982, 0x0000 },
  { 0x0700, 0x0985, 0x0000 },
  { 0x8700, 0x098a, 0x3000 },
  { 0x8700, 0x0988, 0x2000 },
  { 0x0700, 0x0987, 0x0000 },
  { 0x0700, 0x0989, 0x0000 },
  { 0x8700, 0x098c, 0x2000 },
  { 0x0700, 0x098b, 0x0000 },
  { 0x0700, 0x098f, 0x0000 },
  { 0x8700, 0x099a, 0x4000 },
  { 0x8700, 0x0996, 0x3000 },
  { 0x8700, 0x0994, 0x2000 },
  { 0x0700, 0x0993, 0x0000 },
  { 0x0700, 0x0995, 0x0000 },
  { 0x8700, 0x0998, 0x2000 },
  { 0x0700, 0x0997, 0x0000 },
  { 0x0700, 0x0999, 0x0000 },
  { 0x8700, 0x099e, 0x3000 },
  { 0x8700, 0x099c, 0x2000 },
  { 0x0700, 0x099b, 0x0000 },
  { 0x0700, 0x099d, 0x0000 },
  { 0x8700, 0x09a0, 0x2000 },
  { 0x0700, 0x099f, 0x0000 },
  { 0x0700, 0x09a1, 0x0000 },
  { 0x8700, 0x09b7, 0x5000 },
  { 0x8700, 0x09ab, 0x4000 },
  { 0x8700, 0x09a6, 0x3000 },
  { 0x8700, 0x09a4, 0x2000 },
  { 0x0700, 0x09a3, 0x0000 },
  { 0x0700, 0x09a5, 0x0000 },
  { 0x8700, 0x09a8, 0x2000 },
  { 0x0700, 0x09a7, 0x0000 },
  { 0x0700, 0x09aa, 0x0000 },
  { 0x8700, 0x09af, 0x3000 },
  { 0x8700, 0x09ad, 0x2000 },
  { 0x0700, 0x09ac, 0x0000 },
  { 0x0700, 0x09ae, 0x0000 },
  { 0x8700, 0x09b2, 0x2000 },
  { 0x0700, 0x09b0, 0x0000 },
  { 0x0700, 0x09b6, 0x0000 },
  { 0x8c00, 0x09c1, 0x4000 },
  { 0x8700, 0x09bd, 0x3000 },
  { 0x8700, 0x09b9, 0x2000 },
  { 0x0700, 0x09b8, 0x0000 },
  { 0x0c00, 0x09bc, 0x0000 },
  { 0x8a00, 0x09bf, 0x2000 },
  { 0x0a00, 0x09be, 0x0000 },
  { 0x0a00, 0x09c0, 0x0000 },
  { 0x8a00, 0x09c7, 0x3000 },
  { 0x8c00, 0x09c3, 0x2000 },
  { 0x0c00, 0x09c2, 0x0000 },
  { 0x0c00, 0x09c4, 0x0000 },
  { 0x8a00, 0x09cb, 0x2000 },
  { 0x0a00, 0x09c8, 0x0000 },
  { 0x0a00, 0x09cc, 0x0000 },
  { 0x8700, 0x0a2b, 0x7000 },
  { 0x8a00, 0x0a03, 0x6000 },
  { 0x8d00, 0x09ed, 0x5000 },
  { 0x8c00, 0x09e3, 0x4000 },
  { 0x8700, 0x09df, 0x3000 },
  { 0x8700, 0x09dc, 0x2000 },
  { 0x0a00, 0x09d7, 0x0000 },
  { 0x0700, 0x09dd, 0x0000 },
  { 0x8700, 0x09e1, 0x2000 },
  { 0x0700, 0x09e0, 0x0000 },
  { 0x0c00, 0x09e2, 0x0000 },
  { 0x8d00, 0x09e9, 0x3000 },
  { 0x8d00, 0x09e7, 0x2000 },
  { 0x0d00, 0x09e6, 0x0000 },
  { 0x0d00, 0x09e8, 0x0000 },
  { 0x8d00, 0x09eb, 0x2000 },
  { 0x0d00, 0x09ea, 0x0000 },
  { 0x0d00, 0x09ec, 0x0000 },
  { 0x8f00, 0x09f5, 0x4000 },
  { 0x8700, 0x09f1, 0x3000 },
  { 0x8d00, 0x09ef, 0x2000 },
  { 0x0d00, 0x09ee, 0x0000 },
  { 0x0700, 0x09f0, 0x0000 },
  { 0x9700, 0x09f3, 0x2000 },
  { 0x1700, 0x09f2, 0x0000 },
  { 0x0f00, 0x09f4, 0x0000 },
  { 0x8f00, 0x09f9, 0x3000 },
  { 0x8f00, 0x09f7, 0x2000 },
  { 0x0f00, 0x09f6, 0x0000 },
  { 0x0f00, 0x09f8, 0x0000 },
  { 0x8c00, 0x0a01, 0x2000 },
  { 0x1a00, 0x09fa, 0x0000 },
  { 0x0c00, 0x0a02, 0x0000 },
  { 0x8700, 0x0a1a, 0x5000 },
  { 0x8700, 0x0a10, 0x4000 },
  { 0x8700, 0x0a08, 0x3000 },
  { 0x8700, 0x0a06, 0x2000 },
  { 0x0700, 0x0a05, 0x0000 },
  { 0x0700, 0x0a07, 0x0000 },
  { 0x8700, 0x0a0a, 0x2000 },
  { 0x0700, 0x0a09, 0x0000 },
  { 0x0700, 0x0a0f, 0x0000 },
  { 0x8700, 0x0a16, 0x3000 },
  { 0x8700, 0x0a14, 0x2000 },
  { 0x0700, 0x0a13, 0x0000 },
  { 0x0700, 0x0a15, 0x0000 },
  { 0x8700, 0x0a18, 0x2000 },
  { 0x0700, 0x0a17, 0x0000 },
  { 0x0700, 0x0a19, 0x0000 },
  { 0x8700, 0x0a22, 0x4000 },
  { 0x8700, 0x0a1e, 0x3000 },
  { 0x8700, 0x0a1c, 0x2000 },
  { 0x0700, 0x0a1b, 0x0000 },
  { 0x0700, 0x0a1d, 0x0000 },
  { 0x8700, 0x0a20, 0x2000 },
  { 0x0700, 0x0a1f, 0x0000 },
  { 0x0700, 0x0a21, 0x0000 },
  { 0x8700, 0x0a26, 0x3000 },
  { 0x8700, 0x0a24, 0x2000 },
  { 0x0700, 0x0a23, 0x0000 },
  { 0x0700, 0x0a25, 0x0000 },
  { 0x8700, 0x0a28, 0x2000 },
  { 0x0700, 0x0a27, 0x0000 },
  { 0x0700, 0x0a2a, 0x0000 },
  { 0x8d00, 0x0a6a, 0x6000 },
  { 0x8c00, 0x0a41, 0x5000 },
  { 0x8700, 0x0a35, 0x4000 },
  { 0x8700, 0x0a2f, 0x3000 },
  { 0x8700, 0x0a2d, 0x2000 },
  { 0x0700, 0x0a2c, 0x0000 },
  { 0x0700, 0x0a2e, 0x0000 },
  { 0x8700, 0x0a32, 0x2000 },
  { 0x0700, 0x0a30, 0x0000 },
  { 0x0700, 0x0a33, 0x0000 },
  { 0x8c00, 0x0a3c, 0x3000 },
  { 0x8700, 0x0a38, 0x2000 },
  { 0x0700, 0x0a36, 0x0000 },
  { 0x0700, 0x0a39, 0x0000 },
  { 0x8a00, 0x0a3f, 0x2000 },
  { 0x0a00, 0x0a3e, 0x0000 },
  { 0x0a00, 0x0a40, 0x0000 },
  { 0x8700, 0x0a5a, 0x4000 },
  { 0x8c00, 0x0a4b, 0x3000 },
  { 0x8c00, 0x0a47, 0x2000 },
  { 0x0c00, 0x0a42, 0x0000 },
  { 0x0c00, 0x0a48, 0x0000 },
  { 0x8c00, 0x0a4d, 0x2000 },
  { 0x0c00, 0x0a4c, 0x0000 },
  { 0x0700, 0x0a59, 0x0000 },
  { 0x8d00, 0x0a66, 0x3000 },
  { 0x8700, 0x0a5c, 0x2000 },
  { 0x0700, 0x0a5b, 0x0000 },
  { 0x0700, 0x0a5e, 0x0000 },
  { 0x8d00, 0x0a68, 0x2000 },
  { 0x0d00, 0x0a67, 0x0000 },
  { 0x0d00, 0x0a69, 0x0000 },
  { 0x8700, 0x0a87, 0x5000 },
  { 0x8700, 0x0a72, 0x4000 },
  { 0x8d00, 0x0a6e, 0x3000 },
  { 0x8d00, 0x0a6c, 0x2000 },
  { 0x0d00, 0x0a6b, 0x0000 },
  { 0x0d00, 0x0a6d, 0x0000 },
  { 0x8c00, 0x0a70, 0x2000 },
  { 0x0d00, 0x0a6f, 0x0000 },
  { 0x0c00, 0x0a71, 0x0000 },
  { 0x8c00, 0x0a82, 0x3000 },
  { 0x8700, 0x0a74, 0x2000 },
  { 0x0700, 0x0a73, 0x0000 },
  { 0x0c00, 0x0a81, 0x0000 },
  { 0x8700, 0x0a85, 0x2000 },
  { 0x0a00, 0x0a83, 0x0000 },
  { 0x0700, 0x0a86, 0x0000 },
  { 0x8700, 0x0a90, 0x4000 },
  { 0x8700, 0x0a8b, 0x3000 },
  { 0x8700, 0x0a89, 0x2000 },
  { 0x0700, 0x0a88, 0x0000 },
  { 0x0700, 0x0a8a, 0x0000 },
  { 0x8700, 0x0a8d, 0x2000 },
  { 0x0700, 0x0a8c, 0x0000 },
  { 0x0700, 0x0a8f, 0x0000 },
  { 0x8700, 0x0a95, 0x3000 },
  { 0x8700, 0x0a93, 0x2000 },
  { 0x0700, 0x0a91, 0x0000 },
  { 0x0700, 0x0a94, 0x0000 },
  { 0x8700, 0x0a97, 0x2000 },
  { 0x0700, 0x0a96, 0x0000 },
  { 0x0700, 0x0a98, 0x0000 },
  { 0x8700, 0x10ef, 0xb000 },
  { 0x8700, 0x0dc6, 0xa000 },
  { 0x8700, 0x0c31, 0x9000 },
  { 0x8700, 0x0b5f, 0x8000 },
  { 0x8a00, 0x0b03, 0x7000 },
  { 0x8a00, 0x0abe, 0x6000 },
  { 0x8700, 0x0aaa, 0x5000 },
  { 0x8700, 0x0aa1, 0x4000 },
  { 0x8700, 0x0a9d, 0x3000 },
  { 0x8700, 0x0a9b, 0x2000 },
  { 0x0700, 0x0a9a, 0x0000 },
  { 0x0700, 0x0a9c, 0x0000 },
  { 0x8700, 0x0a9f, 0x2000 },
  { 0x0700, 0x0a9e, 0x0000 },
  { 0x0700, 0x0aa0, 0x0000 },
  { 0x8700, 0x0aa5, 0x3000 },
  { 0x8700, 0x0aa3, 0x2000 },
  { 0x0700, 0x0aa2, 0x0000 },
  { 0x0700, 0x0aa4, 0x0000 },
  { 0x8700, 0x0aa7, 0x2000 },
  { 0x0700, 0x0aa6, 0x0000 },
  { 0x0700, 0x0aa8, 0x0000 },
  { 0x8700, 0x0ab3, 0x4000 },
  { 0x8700, 0x0aae, 0x3000 },
  { 0x8700, 0x0aac, 0x2000 },
  { 0x0700, 0x0aab, 0x0000 },
  { 0x0700, 0x0aad, 0x0000 },
  { 0x8700, 0x0ab0, 0x2000 },
  { 0x0700, 0x0aaf, 0x0000 },
  { 0x0700, 0x0ab2, 0x0000 },
  { 0x8700, 0x0ab8, 0x3000 },
  { 0x8700, 0x0ab6, 0x2000 },
  { 0x0700, 0x0ab5, 0x0000 },
  { 0x0700, 0x0ab7, 0x0000 },
  { 0x8c00, 0x0abc, 0x2000 },
  { 0x0700, 0x0ab9, 0x0000 },
  { 0x0700, 0x0abd, 0x0000 },
  { 0x8700, 0x0ae1, 0x5000 },
  { 0x8c00, 0x0ac7, 0x4000 },
  { 0x8c00, 0x0ac2, 0x3000 },
  { 0x8a00, 0x0ac0, 0x2000 },
  { 0x0a00, 0x0abf, 0x0000 },
  { 0x0c00, 0x0ac1, 0x0000 },
  { 0x8c00, 0x0ac4, 0x2000 },
  { 0x0c00, 0x0ac3, 0x0000 },
  { 0x0c00, 0x0ac5, 0x0000 },
  { 0x8a00, 0x0acc, 0x3000 },
  { 0x8a00, 0x0ac9, 0x2000 },
  { 0x0c00, 0x0ac8, 0x0000 },
  { 0x0a00, 0x0acb, 0x0000 },
  { 0x8700, 0x0ad0, 0x2000 },
  { 0x0c00, 0x0acd, 0x0000 },
  { 0x0700, 0x0ae0, 0x0000 },
  { 0x8d00, 0x0aeb, 0x4000 },
  { 0x8d00, 0x0ae7, 0x3000 },
  { 0x8c00, 0x0ae3, 0x2000 },
  { 0x0c00, 0x0ae2, 0x0000 },
  { 0x0d00, 0x0ae6, 0x0000 },
  { 0x8d00, 0x0ae9, 0x2000 },
  { 0x0d00, 0x0ae8, 0x0000 },
  { 0x0d00, 0x0aea, 0x0000 },
  { 0x8d00, 0x0aef, 0x3000 },
  { 0x8d00, 0x0aed, 0x2000 },
  { 0x0d00, 0x0aec, 0x0000 },
  { 0x0d00, 0x0aee, 0x0000 },
  { 0x8c00, 0x0b01, 0x2000 },
  { 0x1700, 0x0af1, 0x0000 },
  { 0x0a00, 0x0b02, 0x0000 },
  { 0x8700, 0x0b28, 0x6000 },
  { 0x8700, 0x0b18, 0x5000 },
  { 0x8700, 0x0b0c, 0x4000 },
  { 0x8700, 0x0b08, 0x3000 },
  { 0x8700, 0x0b06, 0x2000 },
  { 0x0700, 0x0b05, 0x0000 },
  { 0x0700, 0x0b07, 0x0000 },
  { 0x8700, 0x0b0a, 0x2000 },
  { 0x0700, 0x0b09, 0x0000 },
  { 0x0700, 0x0b0b, 0x0000 },
  { 0x8700, 0x0b14, 0x3000 },
  { 0x8700, 0x0b10, 0x2000 },
  { 0x0700, 0x0b0f, 0x0000 },
  { 0x0700, 0x0b13, 0x0000 },
  { 0x8700, 0x0b16, 0x2000 },
  { 0x0700, 0x0b15, 0x0000 },
  { 0x0700, 0x0b17, 0x0000 },
  { 0x8700, 0x0b20, 0x4000 },
  { 0x8700, 0x0b1c, 0x3000 },
  { 0x8700, 0x0b1a, 0x2000 },
  { 0x0700, 0x0b19, 0x0000 },
  { 0x0700, 0x0b1b, 0x0000 },
  { 0x8700, 0x0b1e, 0x2000 },
  { 0x0700, 0x0b1d, 0x0000 },
  { 0x0700, 0x0b1f, 0x0000 },
  { 0x8700, 0x0b24, 0x3000 },
  { 0x8700, 0x0b22, 0x2000 },
  { 0x0700, 0x0b21, 0x0000 },
  { 0x0700, 0x0b23, 0x0000 },
  { 0x8700, 0x0b26, 0x2000 },
  { 0x0700, 0x0b25, 0x0000 },
  { 0x0700, 0x0b27, 0x0000 },
  { 0x8700, 0x0b3d, 0x5000 },
  { 0x8700, 0x0b32, 0x4000 },
  { 0x8700, 0x0b2d, 0x3000 },
  { 0x8700, 0x0b2b, 0x2000 },
  { 0x0700, 0x0b2a, 0x0000 },
  { 0x0700, 0x0b2c, 0x0000 },
  { 0x8700, 0x0b2f, 0x2000 },
  { 0x0700, 0x0b2e, 0x0000 },
  { 0x0700, 0x0b30, 0x0000 },
  { 0x8700, 0x0b37, 0x3000 },
  { 0x8700, 0x0b35, 0x2000 },
  { 0x0700, 0x0b33, 0x0000 },
  { 0x0700, 0x0b36, 0x0000 },
  { 0x8700, 0x0b39, 0x2000 },
  { 0x0700, 0x0b38, 0x0000 },
  { 0x0c00, 0x0b3c, 0x0000 },
  { 0x8a00, 0x0b48, 0x4000 },
  { 0x8c00, 0x0b41, 0x3000 },
  { 0x8c00, 0x0b3f, 0x2000 },
  { 0x0a00, 0x0b3e, 0x0000 },
  { 0x0a00, 0x0b40, 0x0000 },
  { 0x8c00, 0x0b43, 0x2000 },
  { 0x0c00, 0x0b42, 0x0000 },
  { 0x0a00, 0x0b47, 0x0000 },
  { 0x8c00, 0x0b56, 0x3000 },
  { 0x8a00, 0x0b4c, 0x2000 },
  { 0x0a00, 0x0b4b, 0x0000 },
  { 0x0c00, 0x0b4d, 0x0000 },
  { 0x8700, 0x0b5c, 0x2000 },
  { 0x0a00, 0x0b57, 0x0000 },
  { 0x0700, 0x0b5d, 0x0000 },
  { 0x8d00, 0x0be7, 0x7000 },
  { 0x8700, 0x0b9c, 0x6000 },
  { 0x8700, 0x0b83, 0x5000 },
  { 0x8d00, 0x0b6b, 0x4000 },
  { 0x8d00, 0x0b67, 0x3000 },
  { 0x8700, 0x0b61, 0x2000 },
  { 0x0700, 0x0b60, 0x0000 },
  { 0x0d00, 0x0b66, 0x0000 },
  { 0x8d00, 0x0b69, 0x2000 },
  { 0x0d00, 0x0b68, 0x0000 },
  { 0x0d00, 0x0b6a, 0x0000 },
  { 0x8d00, 0x0b6f, 0x3000 },
  { 0x8d00, 0x0b6d, 0x2000 },
  { 0x0d00, 0x0b6c, 0x0000 },
  { 0x0d00, 0x0b6e, 0x0000 },
  { 0x8700, 0x0b71, 0x2000 },
  { 0x1a00, 0x0b70, 0x0000 },
  { 0x0c00, 0x0b82, 0x0000 },
  { 0x8700, 0x0b8f, 0x4000 },
  { 0x8700, 0x0b88, 0x3000 },
  { 0x8700, 0x0b86, 0x2000 },
  { 0x0700, 0x0b85, 0x0000 },
  { 0x0700, 0x0b87, 0x0000 },
  { 0x8700, 0x0b8a, 0x2000 },
  { 0x0700, 0x0b89, 0x0000 },
  { 0x0700, 0x0b8e, 0x0000 },
  { 0x8700, 0x0b94, 0x3000 },
  { 0x8700, 0x0b92, 0x2000 },
  { 0x0700, 0x0b90, 0x0000 },
  { 0x0700, 0x0b93, 0x0000 },
  { 0x8700, 0x0b99, 0x2000 },
  { 0x0700, 0x0b95, 0x0000 },
  { 0x0700, 0x0b9a, 0x0000 },
  { 0x8700, 0x0bb7, 0x5000 },
  { 0x8700, 0x0bae, 0x4000 },
  { 0x8700, 0x0ba4, 0x3000 },
  { 0x8700, 0x0b9f, 0x2000 },
  { 0x0700, 0x0b9e, 0x0000 },
  { 0x0700, 0x0ba3, 0x0000 },
  { 0x8700, 0x0ba9, 0x2000 },
  { 0x0700, 0x0ba8, 0x0000 },
  { 0x0700, 0x0baa, 0x0000 },
  { 0x8700, 0x0bb2, 0x3000 },
  { 0x8700, 0x0bb0, 0x2000 },
  { 0x0700, 0x0baf, 0x0000 },
  { 0x0700, 0x0bb1, 0x0000 },
  { 0x8700, 0x0bb4, 0x2000 },
  { 0x0700, 0x0bb3, 0x0000 },
  { 0x0700, 0x0bb5, 0x0000 },
  { 0x8a00, 0x0bc6, 0x4000 },
  { 0x8a00, 0x0bbf, 0x3000 },
  { 0x8700, 0x0bb9, 0x2000 },
  { 0x0700, 0x0bb8, 0x0000 },
  { 0x0a00, 0x0bbe, 0x0000 },
  { 0x8a00, 0x0bc1, 0x2000 },
  { 0x0c00, 0x0bc0, 0x0000 },
  { 0x0a00, 0x0bc2, 0x0000 },
  { 0x8a00, 0x0bcb, 0x3000 },
  { 0x8a00, 0x0bc8, 0x2000 },
  { 0x0a00, 0x0bc7, 0x0000 },
  { 0x0a00, 0x0bca, 0x0000 },
  { 0x8c00, 0x0bcd, 0x2000 },
  { 0x0a00, 0x0bcc, 0x0000 },
  { 0x0a00, 0x0bd7, 0x0000 },
  { 0x8700, 0x0c0f, 0x6000 },
  { 0x9a00, 0x0bf7, 0x5000 },
  { 0x8d00, 0x0bef, 0x4000 },
  { 0x8d00, 0x0beb, 0x3000 },
  { 0x8d00, 0x0be9, 0x2000 },
  { 0x0d00, 0x0be8, 0x0000 },
  { 0x0d00, 0x0bea, 0x0000 },
  { 0x8d00, 0x0bed, 0x2000 },
  { 0x0d00, 0x0bec, 0x0000 },
  { 0x0d00, 0x0bee, 0x0000 },
  { 0x9a00, 0x0bf3, 0x3000 },
  { 0x8f00, 0x0bf1, 0x2000 },
  { 0x0f00, 0x0bf0, 0x0000 },
  { 0x0f00, 0x0bf2, 0x0000 },
  { 0x9a00, 0x0bf5, 0x2000 },
  { 0x1a00, 0x0bf4, 0x0000 },
  { 0x1a00, 0x0bf6, 0x0000 },
  { 0x8700, 0x0c06, 0x4000 },
  { 0x8a00, 0x0c01, 0x3000 },
  { 0x9700, 0x0bf9, 0x2000 },
  { 0x1a00, 0x0bf8, 0x0000 },
  { 0x1a00, 0x0bfa, 0x0000 },
  { 0x8a00, 0x0c03, 0x2000 },
  { 0x0a00, 0x0c02, 0x0000 },
  { 0x0700, 0x0c05, 0x0000 },
  { 0x8700, 0x0c0a, 0x3000 },
  { 0x8700, 0x0c08, 0x2000 },
  { 0x0700, 0x0c07, 0x0000 },
  { 0x0700, 0x0c09, 0x0000 },
  { 0x8700, 0x0c0c, 0x2000 },
  { 0x0700, 0x0c0b, 0x0000 },
  { 0x0700, 0x0c0e, 0x0000 },
  { 0x8700, 0x0c20, 0x5000 },
  { 0x8700, 0x0c18, 0x4000 },
  { 0x8700, 0x0c14, 0x3000 },
  { 0x8700, 0x0c12, 0x2000 },
  { 0x0700, 0x0c10, 0x0000 },
  { 0x0700, 0x0c13, 0x0000 },
  { 0x8700, 0x0c16, 0x2000 },
  { 0x0700, 0x0c15, 0x0000 },
  { 0x0700, 0x0c17, 0x0000 },
  { 0x8700, 0x0c1c, 0x3000 },
  { 0x8700, 0x0c1a, 0x2000 },
  { 0x0700, 0x0c19, 0x0000 },
  { 0x0700, 0x0c1b, 0x0000 },
  { 0x8700, 0x0c1e, 0x2000 },
  { 0x0700, 0x0c1d, 0x0000 },
  { 0x0700, 0x0c1f, 0x0000 },
  { 0x8700, 0x0c28, 0x4000 },
  { 0x8700, 0x0c24, 0x3000 },
  { 0x8700, 0x0c22, 0x2000 },
  { 0x0700, 0x0c21, 0x0000 },
  { 0x0700, 0x0c23, 0x0000 },
  { 0x8700, 0x0c26, 0x2000 },
  { 0x0700, 0x0c25, 0x0000 },
  { 0x0700, 0x0c27, 0x0000 },
  { 0x8700, 0x0c2d, 0x3000 },
  { 0x8700, 0x0c2b, 0x2000 },
  { 0x0700, 0x0c2a, 0x0000 },
  { 0x0700, 0x0c2c, 0x0000 },
  { 0x8700, 0x0c2f, 0x2000 },
  { 0x0700, 0x0c2e, 0x0000 },
  { 0x0700, 0x0c30, 0x0000 },
  { 0x8700, 0x0d0e, 0x8000 },
  { 0x8700, 0x0ca1, 0x7000 },
  { 0x8d00, 0x0c6c, 0x6000 },
  { 0x8c00, 0x0c47, 0x5000 },
  { 0x8c00, 0x0c3e, 0x4000 },
  { 0x8700, 0x0c36, 0x3000 },
  { 0x8700, 0x0c33, 0x2000 },
  { 0x0700, 0x0c32, 0x0000 },
  { 0x0700, 0x0c35, 0x0000 },
  { 0x8700, 0x0c38, 0x2000 },
  { 0x0700, 0x0c37, 0x0000 },
  { 0x0700, 0x0c39, 0x0000 },
  { 0x8a00, 0x0c42, 0x3000 },
  { 0x8c00, 0x0c40, 0x2000 },
  { 0x0c00, 0x0c3f, 0x0000 },
  { 0x0a00, 0x0c41, 0x0000 },
  { 0x8a00, 0x0c44, 0x2000 },
  { 0x0a00, 0x0c43, 0x0000 },
  { 0x0c00, 0x0c46, 0x0000 },
  { 0x8700, 0x0c60, 0x4000 },
  { 0x8c00, 0x0c4c, 0x3000 },
  { 0x8c00, 0x0c4a, 0x2000 },
  { 0x0c00, 0x0c48, 0x0000 },
  { 0x0c00, 0x0c4b, 0x0000 },
  { 0x8c00, 0x0c55, 0x2000 },
  { 0x0c00, 0x0c4d, 0x0000 },
  { 0x0c00, 0x0c56, 0x0000 },
  { 0x8d00, 0x0c68, 0x3000 },
  { 0x8d00, 0x0c66, 0x2000 },
  { 0x0700, 0x0c61, 0x0000 },
  { 0x0d00, 0x0c67, 0x0000 },
  { 0x8d00, 0x0c6a, 0x2000 },
  { 0x0d00, 0x0c69, 0x0000 },
  { 0x0d00, 0x0c6b, 0x0000 },
  { 0x8700, 0x0c90, 0x5000 },
  { 0x8700, 0x0c87, 0x4000 },
  { 0x8a00, 0x0c82, 0x3000 },
  { 0x8d00, 0x0c6e, 0x2000 },
  { 0x0d00, 0x0c6d, 0x0000 },
  { 0x0d00, 0x0c6f, 0x0000 },
  { 0x8700, 0x0c85, 0x2000 },
  { 0x0a00, 0x0c83, 0x0000 },
  { 0x0700, 0x0c86, 0x0000 },
  { 0x8700, 0x0c8b, 0x3000 },
  { 0x8700, 0x0c89, 0x2000 },
  { 0x0700, 0x0c88, 0x0000 },
  { 0x0700, 0x0c8a, 0x0000 },
  { 0x8700, 0x0c8e, 0x2000 },
  { 0x0700, 0x0c8c, 0x0000 },
  { 0x0700, 0x0c8f, 0x0000 },
  { 0x8700, 0x0c99, 0x4000 },
  { 0x8700, 0x0c95, 0x3000 },
  { 0x8700, 0x0c93, 0x2000 },
  { 0x0700, 0x0c92, 0x0000 },
  { 0x0700, 0x0c94, 0x0000 },
  { 0x8700, 0x0c97, 0x2000 },
  { 0x0700, 0x0c96, 0x0000 },
  { 0x0700, 0x0c98, 0x0000 },
  { 0x8700, 0x0c9d, 0x3000 },
  { 0x8700, 0x0c9b, 0x2000 },
  { 0x0700, 0x0c9a, 0x0000 },
  { 0x0700, 0x0c9c, 0x0000 },
  { 0x8700, 0x0c9f, 0x2000 },
  { 0x0700, 0x0c9e, 0x0000 },
  { 0x0700, 0x0ca0, 0x0000 },
  { 0x8c00, 0x0cc6, 0x6000 },
  { 0x8700, 0x0cb2, 0x5000 },
  { 0x8700, 0x0caa, 0x4000 },
  { 0x8700, 0x0ca5, 0x3000 },
  { 0x8700, 0x0ca3, 0x2000 },
  { 0x0700, 0x0ca2, 0x0000 },
  { 0x0700, 0x0ca4, 0x0000 },
  { 0x8700, 0x0ca7, 0x2000 },
  { 0x0700, 0x0ca6, 0x0000 },
  { 0x0700, 0x0ca8, 0x0000 },
  { 0x8700, 0x0cae, 0x3000 },
  { 0x8700, 0x0cac, 0x2000 },
  { 0x0700, 0x0cab, 0x0000 },
  { 0x0700, 0x0cad, 0x0000 },
  { 0x8700, 0x0cb0, 0x2000 },
  { 0x0700, 0x0caf, 0x0000 },
  { 0x0700, 0x0cb1, 0x0000 },
  { 0x8700, 0x0cbd, 0x4000 },
  { 0x8700, 0x0cb7, 0x3000 },
  { 0x8700, 0x0cb5, 0x2000 },
  { 0x0700, 0x0cb3, 0x0000 },
  { 0x0700, 0x0cb6, 0x0000 },
  { 0x8700, 0x0cb9, 0x2000 },
  { 0x0700, 0x0cb8, 0x0000 },
  { 0x0c00, 0x0cbc, 0x0000 },
  { 0x8a00, 0x0cc1, 0x3000 },
  { 0x8c00, 0x0cbf, 0x2000 },
  { 0x0a00, 0x0cbe, 0x0000 },
  { 0x0a00, 0x0cc0, 0x0000 },
  { 0x8a00, 0x0cc3, 0x2000 },
  { 0x0a00, 0x0cc2, 0x0000 },
  { 0x0a00, 0x0cc4, 0x0000 },
  { 0x8d00, 0x0cea, 0x5000 },
  { 0x8a00, 0x0cd6, 0x4000 },
  { 0x8a00, 0x0ccb, 0x3000 },
  { 0x8a00, 0x0cc8, 0x2000 },
  { 0x0a00, 0x0cc7, 0x0000 },
  { 0x0a00, 0x0cca, 0x0000 },
  { 0x8c00, 0x0ccd, 0x2000 },
  { 0x0c00, 0x0ccc, 0x0000 },
  { 0x0a00, 0x0cd5, 0x0000 },
  { 0x8d00, 0x0ce6, 0x3000 },
  { 0x8700, 0x0ce0, 0x2000 },
  { 0x0700, 0x0cde, 0x0000 },
  { 0x0700, 0x0ce1, 0x0000 },
  { 0x8d00, 0x0ce8, 0x2000 },
  { 0x0d00, 0x0ce7, 0x0000 },
  { 0x0d00, 0x0ce9, 0x0000 },
  { 0x8700, 0x0d05, 0x4000 },
  { 0x8d00, 0x0cee, 0x3000 },
  { 0x8d00, 0x0cec, 0x2000 },
  { 0x0d00, 0x0ceb, 0x0000 },
  { 0x0d00, 0x0ced, 0x0000 },
  { 0x8a00, 0x0d02, 0x2000 },
  { 0x0d00, 0x0cef, 0x0000 },
  { 0x0a00, 0x0d03, 0x0000 },
  { 0x8700, 0x0d09, 0x3000 },
  { 0x8700, 0x0d07, 0x2000 },
  { 0x0700, 0x0d06, 0x0000 },
  { 0x0700, 0x0d08, 0x0000 },
  { 0x8700, 0x0d0b, 0x2000 },
  { 0x0700, 0x0d0a, 0x0000 },
  { 0x0700, 0x0d0c, 0x0000 },
  { 0x8d00, 0x0d6c, 0x7000 },
  { 0x8700, 0x0d30, 0x6000 },
  { 0x8700, 0x0d1f, 0x5000 },
  { 0x8700, 0x0d17, 0x4000 },
  { 0x8700, 0x0d13, 0x3000 },
  { 0x8700, 0x0d10, 0x2000 },
  { 0x0700, 0x0d0f, 0x0000 },
  { 0x0700, 0x0d12, 0x0000 },
  { 0x8700, 0x0d15, 0x2000 },
  { 0x0700, 0x0d14, 0x0000 },
  { 0x0700, 0x0d16, 0x0000 },
  { 0x8700, 0x0d1b, 0x3000 },
  { 0x8700, 0x0d19, 0x2000 },
  { 0x0700, 0x0d18, 0x0000 },
  { 0x0700, 0x0d1a, 0x0000 },
  { 0x8700, 0x0d1d, 0x2000 },
  { 0x0700, 0x0d1c, 0x0000 },
  { 0x0700, 0x0d1e, 0x0000 },
  { 0x8700, 0x0d27, 0x4000 },
  { 0x8700, 0x0d23, 0x3000 },
  { 0x8700, 0x0d21, 0x2000 },
  { 0x0700, 0x0d20, 0x0000 },
  { 0x0700, 0x0d22, 0x0000 },
  { 0x8700, 0x0d25, 0x2000 },
  { 0x0700, 0x0d24, 0x0000 },
  { 0x0700, 0x0d26, 0x0000 },
  { 0x8700, 0x0d2c, 0x3000 },
  { 0x8700, 0x0d2a, 0x2000 },
  { 0x0700, 0x0d28, 0x0000 },
  { 0x0700, 0x0d2b, 0x0000 },
  { 0x8700, 0x0d2e, 0x2000 },
  { 0x0700, 0x0d2d, 0x0000 },
  { 0x0700, 0x0d2f, 0x0000 },
  { 0x8a00, 0x0d46, 0x5000 },
  { 0x8700, 0x0d38, 0x4000 },
  { 0x8700, 0x0d34, 0x3000 },
  { 0x8700, 0x0d32, 0x2000 },
  { 0x0700, 0x0d31, 0x0000 },
  { 0x0700, 0x0d33, 0x0000 },
  { 0x8700, 0x0d36, 0x2000 },
  { 0x0700, 0x0d35, 0x0000 },
  { 0x0700, 0x0d37, 0x0000 },
  { 0x8a00, 0x0d40, 0x3000 },
  { 0x8a00, 0x0d3e, 0x2000 },
  { 0x0700, 0x0d39, 0x0000 },
  { 0x0a00, 0x0d3f, 0x0000 },
  { 0x8c00, 0x0d42, 0x2000 },
  { 0x0c00, 0x0d41, 0x0000 },
  { 0x0c00, 0x0d43, 0x0000 },
  { 0x8700, 0x0d60, 0x4000 },
  { 0x8a00, 0x0d4b, 0x3000 },
  { 0x8a00, 0x0d48, 0x2000 },
  { 0x0a00, 0x0d47, 0x0000 },
  { 0x0a00, 0x0d4a, 0x0000 },
  { 0x8c00, 0x0d4d, 0x2000 },
  { 0x0a00, 0x0d4c, 0x0000 },
  { 0x0a00, 0x0d57, 0x0000 },
  { 0x8d00, 0x0d68, 0x3000 },
  { 0x8d00, 0x0d66, 0x2000 },
  { 0x0700, 0x0d61, 0x0000 },
  { 0x0d00, 0x0d67, 0x0000 },
  { 0x8d00, 0x0d6a, 0x2000 },
  { 0x0d00, 0x0d69, 0x0000 },
  { 0x0d00, 0x0d6b, 0x0000 },
  { 0x8700, 0x0da2, 0x6000 },
  { 0x8700, 0x0d8f, 0x5000 },
  { 0x8700, 0x0d87, 0x4000 },
  { 0x8a00, 0x0d82, 0x3000 },
  { 0x8d00, 0x0d6e, 0x2000 },
  { 0x0d00, 0x0d6d, 0x0000 },
  { 0x0d00, 0x0d6f, 0x0000 },
  { 0x8700, 0x0d85, 0x2000 },
  { 0x0a00, 0x0d83, 0x0000 },
  { 0x0700, 0x0d86, 0x0000 },
  { 0x8700, 0x0d8b, 0x3000 },
  { 0x8700, 0x0d89, 0x2000 },
  { 0x0700, 0x0d88, 0x0000 },
  { 0x0700, 0x0d8a, 0x0000 },
  { 0x8700, 0x0d8d, 0x2000 },
  { 0x0700, 0x0d8c, 0x0000 },
  { 0x0700, 0x0d8e, 0x0000 },
  { 0x8700, 0x0d9a, 0x4000 },
  { 0x8700, 0x0d93, 0x3000 },
  { 0x8700, 0x0d91, 0x2000 },
  { 0x0700, 0x0d90, 0x0000 },
  { 0x0700, 0x0d92, 0x0000 },
  { 0x8700, 0x0d95, 0x2000 },
  { 0x0700, 0x0d94, 0x0000 },
  { 0x0700, 0x0d96, 0x0000 },
  { 0x8700, 0x0d9e, 0x3000 },
  { 0x8700, 0x0d9c, 0x2000 },
  { 0x0700, 0x0d9b, 0x0000 },
  { 0x0700, 0x0d9d, 0x0000 },
  { 0x8700, 0x0da0, 0x2000 },
  { 0x0700, 0x0d9f, 0x0000 },
  { 0x0700, 0x0da1, 0x0000 },
  { 0x8700, 0x0db3, 0x5000 },
  { 0x8700, 0x0daa, 0x4000 },
  { 0x8700, 0x0da6, 0x3000 },
  { 0x8700, 0x0da4, 0x2000 },
  { 0x0700, 0x0da3, 0x0000 },
  { 0x0700, 0x0da5, 0x0000 },
  { 0x8700, 0x0da8, 0x2000 },
  { 0x0700, 0x0da7, 0x0000 },
  { 0x0700, 0x0da9, 0x0000 },
  { 0x8700, 0x0dae, 0x3000 },
  { 0x8700, 0x0dac, 0x2000 },
  { 0x0700, 0x0dab, 0x0000 },
  { 0x0700, 0x0dad, 0x0000 },
  { 0x8700, 0x0db0, 0x2000 },
  { 0x0700, 0x0daf, 0x0000 },
  { 0x0700, 0x0db1, 0x0000 },
  { 0x8700, 0x0dbb, 0x4000 },
  { 0x8700, 0x0db7, 0x3000 },
  { 0x8700, 0x0db5, 0x2000 },
  { 0x0700, 0x0db4, 0x0000 },
  { 0x0700, 0x0db6, 0x0000 },
  { 0x8700, 0x0db9, 0x2000 },
  { 0x0700, 0x0db8, 0x0000 },
  { 0x0700, 0x0dba, 0x0000 },
  { 0x8700, 0x0dc2, 0x3000 },
  { 0x8700, 0x0dc0, 0x2000 },
  { 0x0700, 0x0dbd, 0x0000 },
  { 0x0700, 0x0dc1, 0x0000 },
  { 0x8700, 0x0dc4, 0x2000 },
  { 0x0700, 0x0dc3, 0x0000 },
  { 0x0700, 0x0dc5, 0x0000 },
  { 0x8700, 0x0f55, 0x9000 },
  { 0x8700, 0x0ea5, 0x8000 },
  { 0x8700, 0x0e2d, 0x7000 },
  { 0x8700, 0x0e0d, 0x6000 },
  { 0x8a00, 0x0ddf, 0x5000 },
  { 0x8c00, 0x0dd6, 0x4000 },
  { 0x8a00, 0x0dd1, 0x3000 },
  { 0x8a00, 0x0dcf, 0x2000 },
  { 0x0c00, 0x0dca, 0x0000 },
  { 0x0a00, 0x0dd0, 0x0000 },
  { 0x8c00, 0x0dd3, 0x2000 },
  { 0x0c00, 0x0dd2, 0x0000 },
  { 0x0c00, 0x0dd4, 0x0000 },
  { 0x8a00, 0x0ddb, 0x3000 },
  { 0x8a00, 0x0dd9, 0x2000 },
  { 0x0a00, 0x0dd8, 0x0000 },
  { 0x0a00, 0x0dda, 0x0000 },
  { 0x8a00, 0x0ddd, 0x2000 },
  { 0x0a00, 0x0ddc, 0x0000 },
  { 0x0a00, 0x0dde, 0x0000 },
  { 0x8700, 0x0e05, 0x4000 },
  { 0x8700, 0x0e01, 0x3000 },
  { 0x8a00, 0x0df3, 0x2000 },
  { 0x0a00, 0x0df2, 0x0000 },
  { 0x1500, 0x0df4, 0x0000 },
  { 0x8700, 0x0e03, 0x2000 },
  { 0x0700, 0x0e02, 0x0000 },
  { 0x0700, 0x0e04, 0x0000 },
  { 0x8700, 0x0e09, 0x3000 },
  { 0x8700, 0x0e07, 0x2000 },
  { 0x0700, 0x0e06, 0x0000 },
  { 0x0700, 0x0e08, 0x0000 },
  { 0x8700, 0x0e0b, 0x2000 },
  { 0x0700, 0x0e0a, 0x0000 },
  { 0x0700, 0x0e0c, 0x0000 },
  { 0x8700, 0x0e1d, 0x5000 },
  { 0x8700, 0x0e15, 0x4000 },
  { 0x8700, 0x0e11, 0x3000 },
  { 0x8700, 0x0e0f, 0x2000 },
  { 0x0700, 0x0e0e, 0x0000 },
  { 0x0700, 0x0e10, 0x0000 },
  { 0x8700, 0x0e13, 0x2000 },
  { 0x0700, 0x0e12, 0x0000 },
  { 0x0700, 0x0e14, 0x0000 },
  { 0x8700, 0x0e19, 0x3000 },
  { 0x8700, 0x0e17, 0x2000 },
  { 0x0700, 0x0e16, 0x0000 },
  { 0x0700, 0x0e18, 0x0000 },
  { 0x8700, 0x0e1b, 0x2000 },
  { 0x0700, 0x0e1a, 0x0000 },
  { 0x0700, 0x0e1c, 0x0000 },
  { 0x8700, 0x0e25, 0x4000 },
  { 0x8700, 0x0e21, 0x3000 },
  { 0x8700, 0x0e1f, 0x2000 },
  { 0x0700, 0x0e1e, 0x0000 },
  { 0x0700, 0x0e20, 0x0000 },
  { 0x8700, 0x0e23, 0x2000 },
  { 0x0700, 0x0e22, 0x0000 },
  { 0x0700, 0x0e24, 0x0000 },
  { 0x8700, 0x0e29, 0x3000 },
  { 0x8700, 0x0e27, 0x2000 },
  { 0x0700, 0x0e26, 0x0000 },
  { 0x0700, 0x0e28, 0x0000 },
  { 0x8700, 0x0e2b, 0x2000 },
  { 0x0700, 0x0e2a, 0x0000 },
  { 0x0700, 0x0e2c, 0x0000 },
  { 0x8d00, 0x0e51, 0x6000 },
  { 0x8700, 0x0e41, 0x5000 },
  { 0x8c00, 0x0e35, 0x4000 },
  { 0x8c00, 0x0e31, 0x3000 },
  { 0x8700, 0x0e2f, 0x2000 },
  { 0x0700, 0x0e2e, 0x0000 },
  { 0x0700, 0x0e30, 0x0000 },
  { 0x8700, 0x0e33, 0x2000 },
  { 0x0700, 0x0e32, 0x0000 },
  { 0x0c00, 0x0e34, 0x0000 },
  { 0x8c00, 0x0e39, 0x3000 },
  { 0x8c00, 0x0e37, 0x2000 },
  { 0x0c00, 0x0e36, 0x0000 },
  { 0x0c00, 0x0e38, 0x0000 },
  { 0x9700, 0x0e3f, 0x2000 },
  { 0x0c00, 0x0e3a, 0x0000 },
  { 0x0700, 0x0e40, 0x0000 },
  { 0x8c00, 0x0e49, 0x4000 },
  { 0x8700, 0x0e45, 0x3000 },
  { 0x8700, 0x0e43, 0x2000 },
  { 0x0700, 0x0e42, 0x0000 },
  { 0x0700, 0x0e44, 0x0000 },
  { 0x8c00, 0x0e47, 0x2000 },
  { 0x0600, 0x0e46, 0x0000 },
  { 0x0c00, 0x0e48, 0x0000 },
  { 0x8c00, 0x0e4d, 0x3000 },
  { 0x8c00, 0x0e4b, 0x2000 },
  { 0x0c00, 0x0e4a, 0x0000 },
  { 0x0c00, 0x0e4c, 0x0000 },
  { 0x9500, 0x0e4f, 0x2000 },
  { 0x0c00, 0x0e4e, 0x0000 },
  { 0x0d00, 0x0e50, 0x0000 },
  { 0x8700, 0x0e8a, 0x5000 },
  { 0x8d00, 0x0e59, 0x4000 },
  { 0x8d00, 0x0e55, 0x3000 },
  { 0x8d00, 0x0e53, 0x2000 },
  { 0x0d00, 0x0e52, 0x0000 },
  { 0x0d00, 0x0e54, 0x0000 },
  { 0x8d00, 0x0e57, 0x2000 },
  { 0x0d00, 0x0e56, 0x0000 },
  { 0x0d00, 0x0e58, 0x0000 },
  { 0x8700, 0x0e82, 0x3000 },
  { 0x9500, 0x0e5b, 0x2000 },
  { 0x1500, 0x0e5a, 0x0000 },
  { 0x0700, 0x0e81, 0x0000 },
  { 0x8700, 0x0e87, 0x2000 },
  { 0x0700, 0x0e84, 0x0000 },
  { 0x0700, 0x0e88, 0x0000 },
  { 0x8700, 0x0e9b, 0x4000 },
  { 0x8700, 0x0e96, 0x3000 },
  { 0x8700, 0x0e94, 0x2000 },
  { 0x0700, 0x0e8d, 0x0000 },
  { 0x0700, 0x0e95, 0x0000 },
  { 0x8700, 0x0e99, 0x2000 },
  { 0x0700, 0x0e97, 0x0000 },
  { 0x0700, 0x0e9a, 0x0000 },
  { 0x8700, 0x0e9f, 0x3000 },
  { 0x8700, 0x0e9d, 0x2000 },
  { 0x0700, 0x0e9c, 0x0000 },
  { 0x0700, 0x0e9e, 0x0000 },
  { 0x8700, 0x0ea2, 0x2000 },
  { 0x0700, 0x0ea1, 0x0000 },
  { 0x0700, 0x0ea3, 0x0000 },
  { 0x9a00, 0x0f14, 0x7000 },
  { 0x8d00, 0x0ed0, 0x6000 },
  { 0x8c00, 0x0eb9, 0x5000 },
  { 0x8c00, 0x0eb1, 0x4000 },
  { 0x8700, 0x0ead, 0x3000 },
  { 0x8700, 0x0eaa, 0x2000 },
  { 0x0700, 0x0ea7, 0x0000 },
  { 0x0700, 0x0eab, 0x0000 },
  { 0x8700, 0x0eaf, 0x2000 },
  { 0x0700, 0x0eae, 0x0000 },
  { 0x0700, 0x0eb0, 0x0000 },
  { 0x8c00, 0x0eb5, 0x3000 },
  { 0x8700, 0x0eb3, 0x2000 },
  { 0x0700, 0x0eb2, 0x0000 },
  { 0x0c00, 0x0eb4, 0x0000 },
  { 0x8c00, 0x0eb7, 0x2000 },
  { 0x0c00, 0x0eb6, 0x0000 },
  { 0x0c00, 0x0eb8, 0x0000 },
  { 0x8700, 0x0ec4, 0x4000 },
  { 0x8700, 0x0ec0, 0x3000 },
  { 0x8c00, 0x0ebc, 0x2000 },
  { 0x0c00, 0x0ebb, 0x0000 },
  { 0x0700, 0x0ebd, 0x0000 },
  { 0x8700, 0x0ec2, 0x2000 },
  { 0x0700, 0x0ec1, 0x0000 },
  { 0x0700, 0x0ec3, 0x0000 },
  { 0x8c00, 0x0eca, 0x3000 },
  { 0x8c00, 0x0ec8, 0x2000 },
  { 0x0600, 0x0ec6, 0x0000 },
  { 0x0c00, 0x0ec9, 0x0000 },
  { 0x8c00, 0x0ecc, 0x2000 },
  { 0x0c00, 0x0ecb, 0x0000 },
  { 0x0c00, 0x0ecd, 0x0000 },
  { 0x9500, 0x0f04, 0x5000 },
  { 0x8d00, 0x0ed8, 0x4000 },
  { 0x8d00, 0x0ed4, 0x3000 },
  { 0x8d00, 0x0ed2, 0x2000 },
  { 0x0d00, 0x0ed1, 0x0000 },
  { 0x0d00, 0x0ed3, 0x0000 },
  { 0x8d00, 0x0ed6, 0x2000 },
  { 0x0d00, 0x0ed5, 0x0000 },
  { 0x0d00, 0x0ed7, 0x0000 },
  { 0x8700, 0x0f00, 0x3000 },
  { 0x8700, 0x0edc, 0x2000 },
  { 0x0d00, 0x0ed9, 0x0000 },
  { 0x0700, 0x0edd, 0x0000 },
  { 0x9a00, 0x0f02, 0x2000 },
  { 0x1a00, 0x0f01, 0x0000 },
  { 0x1a00, 0x0f03, 0x0000 },
  { 0x9500, 0x0f0c, 0x4000 },
  { 0x9500, 0x0f08, 0x3000 },
  { 0x9500, 0x0f06, 0x2000 },
  { 0x1500, 0x0f05, 0x0000 },
  { 0x1500, 0x0f07, 0x0000 },
  { 0x9500, 0x0f0a, 0x2000 },
  { 0x1500, 0x0f09, 0x0000 },
  { 0x1500, 0x0f0b, 0x0000 },
  { 0x9500, 0x0f10, 0x3000 },
  { 0x9500, 0x0f0e, 0x2000 },
  { 0x1500, 0x0f0d, 0x0000 },
  { 0x1500, 0x0f0f, 0x0000 },
  { 0x9500, 0x0f12, 0x2000 },
  { 0x1500, 0x0f11, 0x0000 },
  { 0x1a00, 0x0f13, 0x0000 },
  { 0x9a00, 0x0f34, 0x6000 },
  { 0x8d00, 0x0f24, 0x5000 },
  { 0x9a00, 0x0f1c, 0x4000 },
  { 0x8c00, 0x0f18, 0x3000 },
  { 0x9a00, 0x0f16, 0x2000 },
  { 0x1a00, 0x0f15, 0x0000 },
  { 0x1a00, 0x0f17, 0x0000 },
  { 0x9a00, 0x0f1a, 0x2000 },
  { 0x0c00, 0x0f19, 0x0000 },
  { 0x1a00, 0x0f1b, 0x0000 },
  { 0x8d00, 0x0f20, 0x3000 },
  { 0x9a00, 0x0f1e, 0x2000 },
  { 0x1a00, 0x0f1d, 0x0000 },
  { 0x1a00, 0x0f1f, 0x0000 },
  { 0x8d00, 0x0f22, 0x2000 },
  { 0x0d00, 0x0f21, 0x0000 },
  { 0x0d00, 0x0f23, 0x0000 },
  { 0x8f00, 0x0f2c, 0x4000 },
  { 0x8d00, 0x0f28, 0x3000 },
  { 0x8d00, 0x0f26, 0x2000 },
  { 0x0d00, 0x0f25, 0x0000 },
  { 0x0d00, 0x0f27, 0x0000 },
  { 0x8f00, 0x0f2a, 0x2000 },
  { 0x0d00, 0x0f29, 0x0000 },
  { 0x0f00, 0x0f2b, 0x0000 },
  { 0x8f00, 0x0f30, 0x3000 },
  { 0x8f00, 0x0f2e, 0x2000 },
  { 0x0f00, 0x0f2d, 0x0000 },
  { 0x0f00, 0x0f2f, 0x0000 },
  { 0x8f00, 0x0f32, 0x2000 },
  { 0x0f00, 0x0f31, 0x0000 },
  { 0x0f00, 0x0f33, 0x0000 },
  { 0x8700, 0x0f44, 0x5000 },
  { 0x9600, 0x0f3c, 0x4000 },
  { 0x9a00, 0x0f38, 0x3000 },
  { 0x9a00, 0x0f36, 0x2000 },
  { 0x0c00, 0x0f35, 0x0000 },
  { 0x0c00, 0x0f37, 0x0000 },
  { 0x9600, 0x0f3a, 0x2000 },
  { 0x0c00, 0x0f39, 0x0000 },
  { 0x1200, 0x0f3b, 0x0000 },
  { 0x8700, 0x0f40, 0x3000 },
  { 0x8a00, 0x0f3e, 0x2000 },
  { 0x1200, 0x0f3d, 0x0000 },
  { 0x0a00, 0x0f3f, 0x0000 },
  { 0x8700, 0x0f42, 0x2000 },
  { 0x0700, 0x0f41, 0x0000 },
  { 0x0700, 0x0f43, 0x0000 },
  { 0x8700, 0x0f4d, 0x4000 },
  { 0x8700, 0x0f49, 0x3000 },
  { 0x8700, 0x0f46, 0x2000 },
  { 0x0700, 0x0f45, 0x0000 },
  { 0x0700, 0x0f47, 0x0000 },
  { 0x8700, 0x0f4b, 0x2000 },
  { 0x0700, 0x0f4a, 0x0000 },
  { 0x0700, 0x0f4c, 0x0000 },
  { 0x8700, 0x0f51, 0x3000 },
  { 0x8700, 0x0f4f, 0x2000 },
  { 0x0700, 0x0f4e, 0x0000 },
  { 0x0700, 0x0f50, 0x0000 },
  { 0x8700, 0x0f53, 0x2000 },
  { 0x0700, 0x0f52, 0x0000 },
  { 0x0700, 0x0f54, 0x0000 },
  { 0x8700, 0x1013, 0x8000 },
  { 0x8c00, 0x0fa0, 0x7000 },
  { 0x8c00, 0x0f7b, 0x6000 },
  { 0x8700, 0x0f65, 0x5000 },
  { 0x8700, 0x0f5d, 0x4000 },
  { 0x8700, 0x0f59, 0x3000 },
  { 0x8700, 0x0f57, 0x2000 },
  { 0x0700, 0x0f56, 0x0000 },
  { 0x0700, 0x0f58, 0x0000 },
  { 0x8700, 0x0f5b, 0x2000 },
  { 0x0700, 0x0f5a, 0x0000 },
  { 0x0700, 0x0f5c, 0x0000 },
  { 0x8700, 0x0f61, 0x3000 },
  { 0x8700, 0x0f5f, 0x2000 },
  { 0x0700, 0x0f5e, 0x0000 },
  { 0x0700, 0x0f60, 0x0000 },
  { 0x8700, 0x0f63, 0x2000 },
  { 0x0700, 0x0f62, 0x0000 },
  { 0x0700, 0x0f64, 0x0000 },
  { 0x8c00, 0x0f73, 0x4000 },
  { 0x8700, 0x0f69, 0x3000 },
  { 0x8700, 0x0f67, 0x2000 },
  { 0x0700, 0x0f66, 0x0000 },
  { 0x0700, 0x0f68, 0x0000 },
  { 0x8c00, 0x0f71, 0x2000 },
  { 0x0700, 0x0f6a, 0x0000 },
  { 0x0c00, 0x0f72, 0x0000 },
  { 0x8c00, 0x0f77, 0x3000 },
  { 0x8c00, 0x0f75, 0x2000 },
  { 0x0c00, 0x0f74, 0x0000 },
  { 0x0c00, 0x0f76, 0x0000 },
  { 0x8c00, 0x0f79, 0x2000 },
  { 0x0c00, 0x0f78, 0x0000 },
  { 0x0c00, 0x0f7a, 0x0000 },
  { 0x8700, 0x0f8b, 0x5000 },
  { 0x8c00, 0x0f83, 0x4000 },
  { 0x8a00, 0x0f7f, 0x3000 },
  { 0x8c00, 0x0f7d, 0x2000 },
  { 0x0c00, 0x0f7c, 0x0000 },
  { 0x0c00, 0x0f7e, 0x0000 },
  { 0x8c00, 0x0f81, 0x2000 },
  { 0x0c00, 0x0f80, 0x0000 },
  { 0x0c00, 0x0f82, 0x0000 },
  { 0x8c00, 0x0f87, 0x3000 },
  { 0x9500, 0x0f85, 0x2000 },
  { 0x0c00, 0x0f84, 0x0000 },
  { 0x0c00, 0x0f86, 0x0000 },
  { 0x8700, 0x0f89, 0x2000 },
  { 0x0700, 0x0f88, 0x0000 },
  { 0x0700, 0x0f8a, 0x0000 },
  { 0x8c00, 0x0f97, 0x4000 },
  { 0x8c00, 0x0f93, 0x3000 },
  { 0x8c00, 0x0f91, 0x2000 },
  { 0x0c00, 0x0f90, 0x0000 },
  { 0x0c00, 0x0f92, 0x0000 },
  { 0x8c00, 0x0f95, 0x2000 },
  { 0x0c00, 0x0f94, 0x0000 },
  { 0x0c00, 0x0f96, 0x0000 },
  { 0x8c00, 0x0f9c, 0x3000 },
  { 0x8c00, 0x0f9a, 0x2000 },
  { 0x0c00, 0x0f99, 0x0000 },
  { 0x0c00, 0x0f9b, 0x0000 },
  { 0x8c00, 0x0f9e, 0x2000 },
  { 0x0c00, 0x0f9d, 0x0000 },
  { 0x0c00, 0x0f9f, 0x0000 },
  { 0x9a00, 0x0fc1, 0x6000 },
  { 0x8c00, 0x0fb0, 0x5000 },
  { 0x8c00, 0x0fa8, 0x4000 },
  { 0x8c00, 0x0fa4, 0x3000 },
  { 0x8c00, 0x0fa2, 0x2000 },
  { 0x0c00, 0x0fa1, 0x0000 },
  { 0x0c00, 0x0fa3, 0x0000 },
  { 0x8c00, 0x0fa6, 0x2000 },
  { 0x0c00, 0x0fa5, 0x0000 },
  { 0x0c00, 0x0fa7, 0x0000 },
  { 0x8c00, 0x0fac, 0x3000 },
  { 0x8c00, 0x0faa, 0x2000 },
  { 0x0c00, 0x0fa9, 0x0000 },
  { 0x0c00, 0x0fab, 0x0000 },
  { 0x8c00, 0x0fae, 0x2000 },
  { 0x0c00, 0x0fad, 0x0000 },
  { 0x0c00, 0x0faf, 0x0000 },
  { 0x8c00, 0x0fb8, 0x4000 },
  { 0x8c00, 0x0fb4, 0x3000 },
  { 0x8c00, 0x0fb2, 0x2000 },
  { 0x0c00, 0x0fb1, 0x0000 },
  { 0x0c00, 0x0fb3, 0x0000 },
  { 0x8c00, 0x0fb6, 0x2000 },
  { 0x0c00, 0x0fb5, 0x0000 },
  { 0x0c00, 0x0fb7, 0x0000 },
  { 0x8c00, 0x0fbc, 0x3000 },
  { 0x8c00, 0x0fba, 0x2000 },
  { 0x0c00, 0x0fb9, 0x0000 },
  { 0x0c00, 0x0fbb, 0x0000 },
  { 0x9a00, 0x0fbf, 0x2000 },
  { 0x1a00, 0x0fbe, 0x0000 },
  { 0x1a00, 0x0fc0, 0x0000 },
  { 0x8700, 0x1003, 0x5000 },
  { 0x9a00, 0x0fc9, 0x4000 },
  { 0x9a00, 0x0fc5, 0x3000 },
  { 0x9a00, 0x0fc3, 0x2000 },
  { 0x1a00, 0x0fc2, 0x0000 },
  { 0x1a00, 0x0fc4, 0x0000 },
  { 0x9a00, 0x0fc7, 0x2000 },
  { 0x0c00, 0x0fc6, 0x0000 },
  { 0x1a00, 0x0fc8, 0x0000 },
  { 0x9a00, 0x0fcf, 0x3000 },
  { 0x9a00, 0x0fcb, 0x2000 },
  { 0x1a00, 0x0fca, 0x0000 },
  { 0x1a00, 0x0fcc, 0x0000 },
  { 0x8700, 0x1001, 0x2000 },
  { 0x0700, 0x1000, 0x0000 },
  { 0x0700, 0x1002, 0x0000 },
  { 0x8700, 0x100b, 0x4000 },
  { 0x8700, 0x1007, 0x3000 },
  { 0x8700, 0x1005, 0x2000 },
  { 0x0700, 0x1004, 0x0000 },
  { 0x0700, 0x1006, 0x0000 },
  { 0x8700, 0x1009, 0x2000 },
  { 0x0700, 0x1008, 0x0000 },
  { 0x0700, 0x100a, 0x0000 },
  { 0x8700, 0x100f, 0x3000 },
  { 0x8700, 0x100d, 0x2000 },
  { 0x0700, 0x100c, 0x0000 },
  { 0x0700, 0x100e, 0x0000 },
  { 0x8700, 0x1011, 0x2000 },
  { 0x0700, 0x1010, 0x0000 },
  { 0x0700, 0x1012, 0x0000 },
  { 0x8900, 0x10a5, 0x7000 },
  { 0x8c00, 0x1039, 0x6000 },
  { 0x8700, 0x1024, 0x5000 },
  { 0x8700, 0x101b, 0x4000 },
  { 0x8700, 0x1017, 0x3000 },
  { 0x8700, 0x1015, 0x2000 },
  { 0x0700, 0x1014, 0x0000 },
  { 0x0700, 0x1016, 0x0000 },
  { 0x8700, 0x1019, 0x2000 },
  { 0x0700, 0x1018, 0x0000 },
  { 0x0700, 0x101a, 0x0000 },
  { 0x8700, 0x101f, 0x3000 },
  { 0x8700, 0x101d, 0x2000 },
  { 0x0700, 0x101c, 0x0000 },
  { 0x0700, 0x101e, 0x0000 },
  { 0x8700, 0x1021, 0x2000 },
  { 0x0700, 0x1020, 0x0000 },
  { 0x0700, 0x1023, 0x0000 },
  { 0x8c00, 0x102e, 0x4000 },
  { 0x8700, 0x1029, 0x3000 },
  { 0x8700, 0x1026, 0x2000 },
  { 0x0700, 0x1025, 0x0000 },
  { 0x0700, 0x1027, 0x0000 },
  { 0x8a00, 0x102c, 0x2000 },
  { 0x0700, 0x102a, 0x0000 },
  { 0x0c00, 0x102d, 0x0000 },
  { 0x8c00, 0x1032, 0x3000 },
  { 0x8c00, 0x1030, 0x2000 },
  { 0x0c00, 0x102f, 0x0000 },
  { 0x0a00, 0x1031, 0x0000 },
  { 0x8c00, 0x1037, 0x2000 },
  { 0x0c00, 0x1036, 0x0000 },
  { 0x0a00, 0x1038, 0x0000 },
  { 0x9500, 0x104f, 0x5000 },
  { 0x8d00, 0x1047, 0x4000 },
  { 0x8d00, 0x1043, 0x3000 },
  { 0x8d00, 0x1041, 0x2000 },
  { 0x0d00, 0x1040, 0x0000 },
  { 0x0d00, 0x1042, 0x0000 },
  { 0x8d00, 0x1045, 0x2000 },
  { 0x0d00, 0x1044, 0x0000 },
  { 0x0d00, 0x1046, 0x0000 },
  { 0x9500, 0x104b, 0x3000 },
  { 0x8d00, 0x1049, 0x2000 },
  { 0x0d00, 0x1048, 0x0000 },
  { 0x1500, 0x104a, 0x0000 },
  { 0x9500, 0x104d, 0x2000 },
  { 0x1500, 0x104c, 0x0000 },
  { 0x1500, 0x104e, 0x0000 },
  { 0x8a00, 0x1057, 0x4000 },
  { 0x8700, 0x1053, 0x3000 },
  { 0x8700, 0x1051, 0x2000 },
  { 0x0700, 0x1050, 0x0000 },
  { 0x0700, 0x1052, 0x0000 },
  { 0x8700, 0x1055, 0x2000 },
  { 0x0700, 0x1054, 0x0000 },
  { 0x0a00, 0x1056, 0x0000 },
  { 0x8900, 0x10a1, 0x3000 },
  { 0x8c00, 0x1059, 0x2000 },
  { 0x0c00, 0x1058, 0x0000 },
  { 0x0900, 0x10a0, 0x0000 },
  { 0x8900, 0x10a3, 0x2000 },
  { 0x0900, 0x10a2, 0x0000 },
  { 0x0900, 0x10a4, 0x0000 },
  { 0x8900, 0x10c5, 0x6000 },
  { 0x8900, 0x10b5, 0x5000 },
  { 0x8900, 0x10ad, 0x4000 },
  { 0x8900, 0x10a9, 0x3000 },
  { 0x8900, 0x10a7, 0x2000 },
  { 0x0900, 0x10a6, 0x0000 },
  { 0x0900, 0x10a8, 0x0000 },
  { 0x8900, 0x10ab, 0x2000 },
  { 0x0900, 0x10aa, 0x0000 },
  { 0x0900, 0x10ac, 0x0000 },
  { 0x8900, 0x10b1, 0x3000 },
  { 0x8900, 0x10af, 0x2000 },
  { 0x0900, 0x10ae, 0x0000 },
  { 0x0900, 0x10b0, 0x0000 },
  { 0x8900, 0x10b3, 0x2000 },
  { 0x0900, 0x10b2, 0x0000 },
  { 0x0900, 0x10b4, 0x0000 },
  { 0x8900, 0x10bd, 0x4000 },
  { 0x8900, 0x10b9, 0x3000 },
  { 0x8900, 0x10b7, 0x2000 },
  { 0x0900, 0x10b6, 0x0000 },
  { 0x0900, 0x10b8, 0x0000 },
  { 0x8900, 0x10bb, 0x2000 },
  { 0x0900, 0x10ba, 0x0000 },
  { 0x0900, 0x10bc, 0x0000 },
  { 0x8900, 0x10c1, 0x3000 },
  { 0x8900, 0x10bf, 0x2000 },
  { 0x0900, 0x10be, 0x0000 },
  { 0x0900, 0x10c0, 0x0000 },
  { 0x8900, 0x10c3, 0x2000 },
  { 0x0900, 0x10c2, 0x0000 },
  { 0x0900, 0x10c4, 0x0000 },
  { 0x8700, 0x10df, 0x5000 },
  { 0x8700, 0x10d7, 0x4000 },
  { 0x8700, 0x10d3, 0x3000 },
  { 0x8700, 0x10d1, 0x2000 },
  { 0x0700, 0x10d0, 0x0000 },
  { 0x0700, 0x10d2, 0x0000 },
  { 0x8700, 0x10d5, 0x2000 },
  { 0x0700, 0x10d4, 0x0000 },
  { 0x0700, 0x10d6, 0x0000 },
  { 0x8700, 0x10db, 0x3000 },
  { 0x8700, 0x10d9, 0x2000 },
  { 0x0700, 0x10d8, 0x0000 },
  { 0x0700, 0x10da, 0x0000 },
  { 0x8700, 0x10dd, 0x2000 },
  { 0x0700, 0x10dc, 0x0000 },
  { 0x0700, 0x10de, 0x0000 },
  { 0x8700, 0x10e7, 0x4000 },
  { 0x8700, 0x10e3, 0x3000 },
  { 0x8700, 0x10e1, 0x2000 },
  { 0x0700, 0x10e0, 0x0000 },
  { 0x0700, 0x10e2, 0x0000 },
  { 0x8700, 0x10e5, 0x2000 },
  { 0x0700, 0x10e4, 0x0000 },
  { 0x0700, 0x10e6, 0x0000 },
  { 0x8700, 0x10eb, 0x3000 },
  { 0x8700, 0x10e9, 0x2000 },
  { 0x0700, 0x10e8, 0x0000 },
  { 0x0700, 0x10ea, 0x0000 },
  { 0x8700, 0x10ed, 0x2000 },
  { 0x0700, 0x10ec, 0x0000 },
  { 0x0700, 0x10ee, 0x0000 },
  { 0x8700, 0x1322, 0xa000 },
  { 0x8700, 0x1205, 0x9000 },
  { 0x8700, 0x117a, 0x8000 },
  { 0x8700, 0x1135, 0x7000 },
  { 0x8700, 0x1115, 0x6000 },
  { 0x8700, 0x1105, 0x5000 },
  { 0x8700, 0x10f7, 0x4000 },
  { 0x8700, 0x10f3, 0x3000 },
  { 0x8700, 0x10f1, 0x2000 },
  { 0x0700, 0x10f0, 0x0000 },
  { 0x0700, 0x10f2, 0x0000 },
  { 0x8700, 0x10f5, 0x2000 },
  { 0x0700, 0x10f4, 0x0000 },
  { 0x0700, 0x10f6, 0x0000 },
  { 0x8700, 0x1101, 0x3000 },
  { 0x9500, 0x10fb, 0x2000 },
  { 0x0700, 0x10f8, 0x0000 },
  { 0x0700, 0x1100, 0x0000 },
  { 0x8700, 0x1103, 0x2000 },
  { 0x0700, 0x1102, 0x0000 },
  { 0x0700, 0x1104, 0x0000 },
  { 0x8700, 0x110d, 0x4000 },
  { 0x8700, 0x1109, 0x3000 },
  { 0x8700, 0x1107, 0x2000 },
  { 0x0700, 0x1106, 0x0000 },
  { 0x0700, 0x1108, 0x0000 },
  { 0x8700, 0x110b, 0x2000 },
  { 0x0700, 0x110a, 0x0000 },
  { 0x0700, 0x110c, 0x0000 },
  { 0x8700, 0x1111, 0x3000 },
  { 0x8700, 0x110f, 0x2000 },
  { 0x0700, 0x110e, 0x0000 },
  { 0x0700, 0x1110, 0x0000 },
  { 0x8700, 0x1113, 0x2000 },
  { 0x0700, 0x1112, 0x0000 },
  { 0x0700, 0x1114, 0x0000 },
  { 0x8700, 0x1125, 0x5000 },
  { 0x8700, 0x111d, 0x4000 },
  { 0x8700, 0x1119, 0x3000 },
  { 0x8700, 0x1117, 0x2000 },
  { 0x0700, 0x1116, 0x0000 },
  { 0x0700, 0x1118, 0x0000 },
  { 0x8700, 0x111b, 0x2000 },
  { 0x0700, 0x111a, 0x0000 },
  { 0x0700, 0x111c, 0x0000 },
  { 0x8700, 0x1121, 0x3000 },
  { 0x8700, 0x111f, 0x2000 },
  { 0x0700, 0x111e, 0x0000 },
  { 0x0700, 0x1120, 0x0000 },
  { 0x8700, 0x1123, 0x2000 },
  { 0x0700, 0x1122, 0x0000 },
  { 0x0700, 0x1124, 0x0000 },
  { 0x8700, 0x112d, 0x4000 },
  { 0x8700, 0x1129, 0x3000 },
  { 0x8700, 0x1127, 0x2000 },
  { 0x0700, 0x1126, 0x0000 },
  { 0x0700, 0x1128, 0x0000 },
  { 0x8700, 0x112b, 0x2000 },
  { 0x0700, 0x112a, 0x0000 },
  { 0x0700, 0x112c, 0x0000 },
  { 0x8700, 0x1131, 0x3000 },
  { 0x8700, 0x112f, 0x2000 },
  { 0x0700, 0x112e, 0x0000 },
  { 0x0700, 0x1130, 0x0000 },
  { 0x8700, 0x1133, 0x2000 },
  { 0x0700, 0x1132, 0x0000 },
  { 0x0700, 0x1134, 0x0000 },
  { 0x8700, 0x1155, 0x6000 },
  { 0x8700, 0x1145, 0x5000 },
  { 0x8700, 0x113d, 0x4000 },
  { 0x8700, 0x1139, 0x3000 },
  { 0x8700, 0x1137, 0x2000 },
  { 0x0700, 0x1136, 0x0000 },
  { 0x0700, 0x1138, 0x0000 },
  { 0x8700, 0x113b, 0x2000 },
  { 0x0700, 0x113a, 0x0000 },
  { 0x0700, 0x113c, 0x0000 },
  { 0x8700, 0x1141, 0x3000 },
  { 0x8700, 0x113f, 0x2000 },
  { 0x0700, 0x113e, 0x0000 },
  { 0x0700, 0x1140, 0x0000 },
  { 0x8700, 0x1143, 0x2000 },
  { 0x0700, 0x1142, 0x0000 },
  { 0x0700, 0x1144, 0x0000 },
  { 0x8700, 0x114d, 0x4000 },
  { 0x8700, 0x1149, 0x3000 },
  { 0x8700, 0x1147, 0x2000 },
  { 0x0700, 0x1146, 0x0000 },
  { 0x0700, 0x1148, 0x0000 },
  { 0x8700, 0x114b, 0x2000 },
  { 0x0700, 0x114a, 0x0000 },
  { 0x0700, 0x114c, 0x0000 },
  { 0x8700, 0x1151, 0x3000 },
  { 0x8700, 0x114f, 0x2000 },
  { 0x0700, 0x114e, 0x0000 },
  { 0x0700, 0x1150, 0x0000 },
  { 0x8700, 0x1153, 0x2000 },
  { 0x0700, 0x1152, 0x0000 },
  { 0x0700, 0x1154, 0x0000 },
  { 0x8700, 0x116a, 0x5000 },
  { 0x8700, 0x1162, 0x4000 },
  { 0x8700, 0x1159, 0x3000 },
  { 0x8700, 0x1157, 0x2000 },
  { 0x0700, 0x1156, 0x0000 },
  { 0x0700, 0x1158, 0x0000 },
  { 0x8700, 0x1160, 0x2000 },
  { 0x0700, 0x115f, 0x0000 },
  { 0x0700, 0x1161, 0x0000 },
  { 0x8700, 0x1166, 0x3000 },
  { 0x8700, 0x1164, 0x2000 },
  { 0x0700, 0x1163, 0x0000 },
  { 0x0700, 0x1165, 0x0000 },
  { 0x8700, 0x1168, 0x2000 },
  { 0x0700, 0x1167, 0x0000 },
  { 0x0700, 0x1169, 0x0000 },
  { 0x8700, 0x1172, 0x4000 },
  { 0x8700, 0x116e, 0x3000 },
  { 0x8700, 0x116c, 0x2000 },
  { 0x0700, 0x116b, 0x0000 },
  { 0x0700, 0x116d, 0x0000 },
  { 0x8700, 0x1170, 0x2000 },
  { 0x0700, 0x116f, 0x0000 },
  { 0x0700, 0x1171, 0x0000 },
  { 0x8700, 0x1176, 0x3000 },
  { 0x8700, 0x1174, 0x2000 },
  { 0x0700, 0x1173, 0x0000 },
  { 0x0700, 0x1175, 0x0000 },
  { 0x8700, 0x1178, 0x2000 },
  { 0x0700, 0x1177, 0x0000 },
  { 0x0700, 0x1179, 0x0000 },
  { 0x8700, 0x11bf, 0x7000 },
  { 0x8700, 0x119a, 0x6000 },
  { 0x8700, 0x118a, 0x5000 },
  { 0x8700, 0x1182, 0x4000 },
  { 0x8700, 0x117e, 0x3000 },
  { 0x8700, 0x117c, 0x2000 },
  { 0x0700, 0x117b, 0x0000 },
  { 0x0700, 0x117d, 0x0000 },
  { 0x8700, 0x1180, 0x2000 },
  { 0x0700, 0x117f, 0x0000 },
  { 0x0700, 0x1181, 0x0000 },
  { 0x8700, 0x1186, 0x3000 },
  { 0x8700, 0x1184, 0x2000 },
  { 0x0700, 0x1183, 0x0000 },
  { 0x0700, 0x1185, 0x0000 },
  { 0x8700, 0x1188, 0x2000 },
  { 0x0700, 0x1187, 0x0000 },
  { 0x0700, 0x1189, 0x0000 },
  { 0x8700, 0x1192, 0x4000 },
  { 0x8700, 0x118e, 0x3000 },
  { 0x8700, 0x118c, 0x2000 },
  { 0x0700, 0x118b, 0x0000 },
  { 0x0700, 0x118d, 0x0000 },
  { 0x8700, 0x1190, 0x2000 },
  { 0x0700, 0x118f, 0x0000 },
  { 0x0700, 0x1191, 0x0000 },
  { 0x8700, 0x1196, 0x3000 },
  { 0x8700, 0x1194, 0x2000 },
  { 0x0700, 0x1193, 0x0000 },
  { 0x0700, 0x1195, 0x0000 },
  { 0x8700, 0x1198, 0x2000 },
  { 0x0700, 0x1197, 0x0000 },
  { 0x0700, 0x1199, 0x0000 },
  { 0x8700, 0x11af, 0x5000 },
  { 0x8700, 0x11a2, 0x4000 },
  { 0x8700, 0x119e, 0x3000 },
  { 0x8700, 0x119c, 0x2000 },
  { 0x0700, 0x119b, 0x0000 },
  { 0x0700, 0x119d, 0x0000 },
  { 0x8700, 0x11a0, 0x2000 },
  { 0x0700, 0x119f, 0x0000 },
  { 0x0700, 0x11a1, 0x0000 },
  { 0x8700, 0x11ab, 0x3000 },
  { 0x8700, 0x11a9, 0x2000 },
  { 0x0700, 0x11a8, 0x0000 },
  { 0x0700, 0x11aa, 0x0000 },
  { 0x8700, 0x11ad, 0x2000 },
  { 0x0700, 0x11ac, 0x0000 },
  { 0x0700, 0x11ae, 0x0000 },
  { 0x8700, 0x11b7, 0x4000 },
  { 0x8700, 0x11b3, 0x3000 },
  { 0x8700, 0x11b1, 0x2000 },
  { 0x0700, 0x11b0, 0x0000 },
  { 0x0700, 0x11b2, 0x0000 },
  { 0x8700, 0x11b5, 0x2000 },
  { 0x0700, 0x11b4, 0x0000 },
  { 0x0700, 0x11b6, 0x0000 },
  { 0x8700, 0x11bb, 0x3000 },
  { 0x8700, 0x11b9, 0x2000 },
  { 0x0700, 0x11b8, 0x0000 },
  { 0x0700, 0x11ba, 0x0000 },
  { 0x8700, 0x11bd, 0x2000 },
  { 0x0700, 0x11bc, 0x0000 },
  { 0x0700, 0x11be, 0x0000 },
  { 0x8700, 0x11df, 0x6000 },
  { 0x8700, 0x11cf, 0x5000 },
  { 0x8700, 0x11c7, 0x4000 },
  { 0x8700, 0x11c3, 0x3000 },
  { 0x8700, 0x11c1, 0x2000 },
  { 0x0700, 0x11c0, 0x0000 },
  { 0x0700, 0x11c2, 0x0000 },
  { 0x8700, 0x11c5, 0x2000 },
  { 0x0700, 0x11c4, 0x0000 },
  { 0x0700, 0x11c6, 0x0000 },
  { 0x8700, 0x11cb, 0x3000 },
  { 0x8700, 0x11c9, 0x2000 },
  { 0x0700, 0x11c8, 0x0000 },
  { 0x0700, 0x11ca, 0x0000 },
  { 0x8700, 0x11cd, 0x2000 },
  { 0x0700, 0x11cc, 0x0000 },
  { 0x0700, 0x11ce, 0x0000 },
  { 0x8700, 0x11d7, 0x4000 },
  { 0x8700, 0x11d3, 0x3000 },
  { 0x8700, 0x11d1, 0x2000 },
  { 0x0700, 0x11d0, 0x0000 },
  { 0x0700, 0x11d2, 0x0000 },
  { 0x8700, 0x11d5, 0x2000 },
  { 0x0700, 0x11d4, 0x0000 },
  { 0x0700, 0x11d6, 0x0000 },
  { 0x8700, 0x11db, 0x3000 },
  { 0x8700, 0x11d9, 0x2000 },
  { 0x0700, 0x11d8, 0x0000 },
  { 0x0700, 0x11da, 0x0000 },
  { 0x8700, 0x11dd, 0x2000 },
  { 0x0700, 0x11dc, 0x0000 },
  { 0x0700, 0x11de, 0x0000 },
  { 0x8700, 0x11ef, 0x5000 },
  { 0x8700, 0x11e7, 0x4000 },
  { 0x8700, 0x11e3, 0x3000 },
  { 0x8700, 0x11e1, 0x2000 },
  { 0x0700, 0x11e0, 0x0000 },
  { 0x0700, 0x11e2, 0x0000 },
  { 0x8700, 0x11e5, 0x2000 },
  { 0x0700, 0x11e4, 0x0000 },
  { 0x0700, 0x11e6, 0x0000 },
  { 0x8700, 0x11eb, 0x3000 },
  { 0x8700, 0x11e9, 0x2000 },
  { 0x0700, 0x11e8, 0x0000 },
  { 0x0700, 0x11ea, 0x0000 },
  { 0x8700, 0x11ed, 0x2000 },
  { 0x0700, 0x11ec, 0x0000 },
  { 0x0700, 0x11ee, 0x0000 },
  { 0x8700, 0x11f7, 0x4000 },
  { 0x8700, 0x11f3, 0x3000 },
  { 0x8700, 0x11f1, 0x2000 },
  { 0x0700, 0x11f0, 0x0000 },
  { 0x0700, 0x11f2, 0x0000 },
  { 0x8700, 0x11f5, 0x2000 },
  { 0x0700, 0x11f4, 0x0000 },
  { 0x0700, 0x11f6, 0x0000 },
  { 0x8700, 0x1201, 0x3000 },
  { 0x8700, 0x11f9, 0x2000 },
  { 0x0700, 0x11f8, 0x0000 },
  { 0x0700, 0x1200, 0x0000 },
  { 0x8700, 0x1203, 0x2000 },
  { 0x0700, 0x1202, 0x0000 },
  { 0x0700, 0x1204, 0x0000 },
  { 0x8700, 0x1292, 0x8000 },
  { 0x8700, 0x1246, 0x7000 },
  { 0x8700, 0x1226, 0x6000 },
  { 0x8700, 0x1216, 0x5000 },
  { 0x8700, 0x120e, 0x4000 },
  { 0x8700, 0x120a, 0x3000 },
  { 0x8700, 0x1208, 0x2000 },
  { 0x0700, 0x1206, 0x0000 },
  { 0x0700, 0x1209, 0x0000 },
  { 0x8700, 0x120c, 0x2000 },
  { 0x0700, 0x120b, 0x0000 },
  { 0x0700, 0x120d, 0x0000 },
  { 0x8700, 0x1212, 0x3000 },
  { 0x8700, 0x1210, 0x2000 },
  { 0x0700, 0x120f, 0x0000 },
  { 0x0700, 0x1211, 0x0000 },
  { 0x8700, 0x1214, 0x2000 },
  { 0x0700, 0x1213, 0x0000 },
  { 0x0700, 0x1215, 0x0000 },
  { 0x8700, 0x121e, 0x4000 },
  { 0x8700, 0x121a, 0x3000 },
  { 0x8700, 0x1218, 0x2000 },
  { 0x0700, 0x1217, 0x0000 },
  { 0x0700, 0x1219, 0x0000 },
  { 0x8700, 0x121c, 0x2000 },
  { 0x0700, 0x121b, 0x0000 },
  { 0x0700, 0x121d, 0x0000 },
  { 0x8700, 0x1222, 0x3000 },
  { 0x8700, 0x1220, 0x2000 },
  { 0x0700, 0x121f, 0x0000 },
  { 0x0700, 0x1221, 0x0000 },
  { 0x8700, 0x1224, 0x2000 },
  { 0x0700, 0x1223, 0x0000 },
  { 0x0700, 0x1225, 0x0000 },
  { 0x8700, 0x1236, 0x5000 },
  { 0x8700, 0x122e, 0x4000 },
  { 0x8700, 0x122a, 0x3000 },
  { 0x8700, 0x1228, 0x2000 },
  { 0x0700, 0x1227, 0x0000 },
  { 0x0700, 0x1229, 0x0000 },
  { 0x8700, 0x122c, 0x2000 },
  { 0x0700, 0x122b, 0x0000 },
  { 0x0700, 0x122d, 0x0000 },
  { 0x8700, 0x1232, 0x3000 },
  { 0x8700, 0x1230, 0x2000 },
  { 0x0700, 0x122f, 0x0000 },
  { 0x0700, 0x1231, 0x0000 },
  { 0x8700, 0x1234, 0x2000 },
  { 0x0700, 0x1233, 0x0000 },
  { 0x0700, 0x1235, 0x0000 },
  { 0x8700, 0x123e, 0x4000 },
  { 0x8700, 0x123a, 0x3000 },
  { 0x8700, 0x1238, 0x2000 },
  { 0x0700, 0x1237, 0x0000 },
  { 0x0700, 0x1239, 0x0000 },
  { 0x8700, 0x123c, 0x2000 },
  { 0x0700, 0x123b, 0x0000 },
  { 0x0700, 0x123d, 0x0000 },
  { 0x8700, 0x1242, 0x3000 },
  { 0x8700, 0x1240, 0x2000 },
  { 0x0700, 0x123f, 0x0000 },
  { 0x0700, 0x1241, 0x0000 },
  { 0x8700, 0x1244, 0x2000 },
  { 0x0700, 0x1243, 0x0000 },
  { 0x0700, 0x1245, 0x0000 },
  { 0x8700, 0x126e, 0x6000 },
  { 0x8700, 0x125c, 0x5000 },
  { 0x8700, 0x1252, 0x4000 },
  { 0x8700, 0x124c, 0x3000 },
  { 0x8700, 0x124a, 0x2000 },
  { 0x0700, 0x1248, 0x0000 },
  { 0x0700, 0x124b, 0x0000 },
  { 0x8700, 0x1250, 0x2000 },
  { 0x0700, 0x124d, 0x0000 },
  { 0x0700, 0x1251, 0x0000 },
  { 0x8700, 0x1256, 0x3000 },
  { 0x8700, 0x1254, 0x2000 },
  { 0x0700, 0x1253, 0x0000 },
  { 0x0700, 0x1255, 0x0000 },
  { 0x8700, 0x125a, 0x2000 },
  { 0x0700, 0x1258, 0x0000 },
  { 0x0700, 0x125b, 0x0000 },
  { 0x8700, 0x1266, 0x4000 },
  { 0x8700, 0x1262, 0x3000 },
  { 0x8700, 0x1260, 0x2000 },
  { 0x0700, 0x125d, 0x0000 },
  { 0x0700, 0x1261, 0x0000 },
  { 0x8700, 0x1264, 0x2000 },
  { 0x0700, 0x1263, 0x0000 },
  { 0x0700, 0x1265, 0x0000 },
  { 0x8700, 0x126a, 0x3000 },
  { 0x8700, 0x1268, 0x2000 },
  { 0x0700, 0x1267, 0x0000 },
  { 0x0700, 0x1269, 0x0000 },
  { 0x8700, 0x126c, 0x2000 },
  { 0x0700, 0x126b, 0x0000 },
  { 0x0700, 0x126d, 0x0000 },
  { 0x8700, 0x127e, 0x5000 },
  { 0x8700, 0x1276, 0x4000 },
  { 0x8700, 0x1272, 0x3000 },
  { 0x8700, 0x1270, 0x2000 },
  { 0x0700, 0x126f, 0x0000 },
  { 0x0700, 0x1271, 0x0000 },
  { 0x8700, 0x1274, 0x2000 },
  { 0x0700, 0x1273, 0x0000 },
  { 0x0700, 0x1275, 0x0000 },
  { 0x8700, 0x127a, 0x3000 },
  { 0x8700, 0x1278, 0x2000 },
  { 0x0700, 0x1277, 0x0000 },
  { 0x0700, 0x1279, 0x0000 },
  { 0x8700, 0x127c, 0x2000 },
  { 0x0700, 0x127b, 0x0000 },
  { 0x0700, 0x127d, 0x0000 },
  { 0x8700, 0x1286, 0x4000 },
  { 0x8700, 0x1282, 0x3000 },
  { 0x8700, 0x1280, 0x2000 },
  { 0x0700, 0x127f, 0x0000 },
  { 0x0700, 0x1281, 0x0000 },
  { 0x8700, 0x1284, 0x2000 },
  { 0x0700, 0x1283, 0x0000 },
  { 0x0700, 0x1285, 0x0000 },
  { 0x8700, 0x128c, 0x3000 },
  { 0x8700, 0x128a, 0x2000 },
  { 0x0700, 0x1288, 0x0000 },
  { 0x0700, 0x128b, 0x0000 },
  { 0x8700, 0x1290, 0x2000 },
  { 0x0700, 0x128d, 0x0000 },
  { 0x0700, 0x1291, 0x0000 },
  { 0x8700, 0x12dc, 0x7000 },
  { 0x8700, 0x12b4, 0x6000 },
  { 0x8700, 0x12a2, 0x5000 },
  { 0x8700, 0x129a, 0x4000 },
  { 0x8700, 0x1296, 0x3000 },
  { 0x8700, 0x1294, 0x2000 },
  { 0x0700, 0x1293, 0x0000 },
  { 0x0700, 0x1295, 0x0000 },
  { 0x8700, 0x1298, 0x2000 },
  { 0x0700, 0x1297, 0x0000 },
  { 0x0700, 0x1299, 0x0000 },
  { 0x8700, 0x129e, 0x3000 },
  { 0x8700, 0x129c, 0x2000 },
  { 0x0700, 0x129b, 0x0000 },
  { 0x0700, 0x129d, 0x0000 },
  { 0x8700, 0x12a0, 0x2000 },
  { 0x0700, 0x129f, 0x0000 },
  { 0x0700, 0x12a1, 0x0000 },
  { 0x8700, 0x12aa, 0x4000 },
  { 0x8700, 0x12a6, 0x3000 },
  { 0x8700, 0x12a4, 0x2000 },
  { 0x0700, 0x12a3, 0x0000 },
  { 0x0700, 0x12a5, 0x0000 },
  { 0x8700, 0x12a8, 0x2000 },
  { 0x0700, 0x12a7, 0x0000 },
  { 0x0700, 0x12a9, 0x0000 },
  { 0x8700, 0x12ae, 0x3000 },
  { 0x8700, 0x12ac, 0x2000 },
  { 0x0700, 0x12ab, 0x0000 },
  { 0x0700, 0x12ad, 0x0000 },
  { 0x8700, 0x12b2, 0x2000 },
  { 0x0700, 0x12b0, 0x0000 },
  { 0x0700, 0x12b3, 0x0000 },
  { 0x8700, 0x12ca, 0x5000 },
  { 0x8700, 0x12be, 0x4000 },
  { 0x8700, 0x12ba, 0x3000 },
  { 0x8700, 0x12b8, 0x2000 },
  { 0x0700, 0x12b5, 0x0000 },
  { 0x0700, 0x12b9, 0x0000 },
  { 0x8700, 0x12bc, 0x2000 },
  { 0x0700, 0x12bb, 0x0000 },
  { 0x0700, 0x12bd, 0x0000 },
  { 0x8700, 0x12c4, 0x3000 },
  { 0x8700, 0x12c2, 0x2000 },
  { 0x0700, 0x12c0, 0x0000 },
  { 0x0700, 0x12c3, 0x0000 },
  { 0x8700, 0x12c8, 0x2000 },
  { 0x0700, 0x12c5, 0x0000 },
  { 0x0700, 0x12c9, 0x0000 },
  { 0x8700, 0x12d3, 0x4000 },
  { 0x8700, 0x12ce, 0x3000 },
  { 0x8700, 0x12cc, 0x2000 },
  { 0x0700, 0x12cb, 0x0000 },
  { 0x0700, 0x12cd, 0x0000 },
  { 0x8700, 0x12d1, 0x2000 },
  { 0x0700, 0x12d0, 0x0000 },
  { 0x0700, 0x12d2, 0x0000 },
  { 0x8700, 0x12d8, 0x3000 },
  { 0x8700, 0x12d5, 0x2000 },
  { 0x0700, 0x12d4, 0x0000 },
  { 0x0700, 0x12d6, 0x0000 },
  { 0x8700, 0x12da, 0x2000 },
  { 0x0700, 0x12d9, 0x0000 },
  { 0x0700, 0x12db, 0x0000 },
  { 0x8700, 0x12fd, 0x6000 },
  { 0x8700, 0x12ec, 0x5000 },
  { 0x8700, 0x12e4, 0x4000 },
  { 0x8700, 0x12e0, 0x3000 },
  { 0x8700, 0x12de, 0x2000 },
  { 0x0700, 0x12dd, 0x0000 },
  { 0x0700, 0x12df, 0x0000 },
  { 0x8700, 0x12e2, 0x2000 },
  { 0x0700, 0x12e1, 0x0000 },
  { 0x0700, 0x12e3, 0x0000 },
  { 0x8700, 0x12e8, 0x3000 },
  { 0x8700, 0x12e6, 0x2000 },
  { 0x0700, 0x12e5, 0x0000 },
  { 0x0700, 0x12e7, 0x0000 },
  { 0x8700, 0x12ea, 0x2000 },
  { 0x0700, 0x12e9, 0x0000 },
  { 0x0700, 0x12eb, 0x0000 },
  { 0x8700, 0x12f5, 0x4000 },
  { 0x8700, 0x12f1, 0x3000 },
  { 0x8700, 0x12ee, 0x2000 },
  { 0x0700, 0x12ed, 0x0000 },
  { 0x0700, 0x12f0, 0x0000 },
  { 0x8700, 0x12f3, 0x2000 },
  { 0x0700, 0x12f2, 0x0000 },
  { 0x0700, 0x12f4, 0x0000 },
  { 0x8700, 0x12f9, 0x3000 },
  { 0x8700, 0x12f7, 0x2000 },
  { 0x0700, 0x12f6, 0x0000 },
  { 0x0700, 0x12f8, 0x0000 },
  { 0x8700, 0x12fb, 0x2000 },
  { 0x0700, 0x12fa, 0x0000 },
  { 0x0700, 0x12fc, 0x0000 },
  { 0x8700, 0x130d, 0x5000 },
  { 0x8700, 0x1305, 0x4000 },
  { 0x8700, 0x1301, 0x3000 },
  { 0x8700, 0x12ff, 0x2000 },
  { 0x0700, 0x12fe, 0x0000 },
  { 0x0700, 0x1300, 0x0000 },
  { 0x8700, 0x1303, 0x2000 },
  { 0x0700, 0x1302, 0x0000 },
  { 0x0700, 0x1304, 0x0000 },
  { 0x8700, 0x1309, 0x3000 },
  { 0x8700, 0x1307, 0x2000 },
  { 0x0700, 0x1306, 0x0000 },
  { 0x0700, 0x1308, 0x0000 },
  { 0x8700, 0x130b, 0x2000 },
  { 0x0700, 0x130a, 0x0000 },
  { 0x0700, 0x130c, 0x0000 },
  { 0x8700, 0x1319, 0x4000 },
  { 0x8700, 0x1313, 0x3000 },
  { 0x8700, 0x1310, 0x2000 },
  { 0x0700, 0x130e, 0x0000 },
  { 0x0700, 0x1312, 0x0000 },
  { 0x8700, 0x1315, 0x2000 },
  { 0x0700, 0x1314, 0x0000 },
  { 0x0700, 0x1318, 0x0000 },
  { 0x8700, 0x131d, 0x3000 },
  { 0x8700, 0x131b, 0x2000 },
  { 0x0700, 0x131a, 0x0000 },
  { 0x0700, 0x131c, 0x0000 },
  { 0x8700, 0x1320, 0x2000 },
  { 0x0700, 0x131e, 0x0000 },
  { 0x0700, 0x1321, 0x0000 },
  { 0x8700, 0x1458, 0x9000 },
  { 0x8700, 0x13cc, 0x8000 },
  { 0x8d00, 0x1369, 0x7000 },
  { 0x8700, 0x1342, 0x6000 },
  { 0x8700, 0x1332, 0x5000 },
  { 0x8700, 0x132a, 0x4000 },
  { 0x8700, 0x1326, 0x3000 },
  { 0x8700, 0x1324, 0x2000 },
  { 0x0700, 0x1323, 0x0000 },
  { 0x0700, 0x1325, 0x0000 },
  { 0x8700, 0x1328, 0x2000 },
  { 0x0700, 0x1327, 0x0000 },
  { 0x0700, 0x1329, 0x0000 },
  { 0x8700, 0x132e, 0x3000 },
  { 0x8700, 0x132c, 0x2000 },
  { 0x0700, 0x132b, 0x0000 },
  { 0x0700, 0x132d, 0x0000 },
  { 0x8700, 0x1330, 0x2000 },
  { 0x0700, 0x132f, 0x0000 },
  { 0x0700, 0x1331, 0x0000 },
  { 0x8700, 0x133a, 0x4000 },
  { 0x8700, 0x1336, 0x3000 },
  { 0x8700, 0x1334, 0x2000 },
  { 0x0700, 0x1333, 0x0000 },
  { 0x0700, 0x1335, 0x0000 },
  { 0x8700, 0x1338, 0x2000 },
  { 0x0700, 0x1337, 0x0000 },
  { 0x0700, 0x1339, 0x0000 },
  { 0x8700, 0x133e, 0x3000 },
  { 0x8700, 0x133c, 0x2000 },
  { 0x0700, 0x133b, 0x0000 },
  { 0x0700, 0x133d, 0x0000 },
  { 0x8700, 0x1340, 0x2000 },
  { 0x0700, 0x133f, 0x0000 },
  { 0x0700, 0x1341, 0x0000 },
  { 0x8700, 0x1353, 0x5000 },
  { 0x8700, 0x134b, 0x4000 },
  { 0x8700, 0x1346, 0x3000 },
  { 0x8700, 0x1344, 0x2000 },
  { 0x0700, 0x1343, 0x0000 },
  { 0x0700, 0x1345, 0x0000 },
  { 0x8700, 0x1349, 0x2000 },
  { 0x0700, 0x1348, 0x0000 },
  { 0x0700, 0x134a, 0x0000 },
  { 0x8700, 0x134f, 0x3000 },
  { 0x8700, 0x134d, 0x2000 },
  { 0x0700, 0x134c, 0x0000 },
  { 0x0700, 0x134e, 0x0000 },
  { 0x8700, 0x1351, 0x2000 },
  { 0x0700, 0x1350, 0x0000 },
  { 0x0700, 0x1352, 0x0000 },
  { 0x9500, 0x1361, 0x4000 },
  { 0x8700, 0x1357, 0x3000 },
  { 0x8700, 0x1355, 0x2000 },
  { 0x0700, 0x1354, 0x0000 },
  { 0x0700, 0x1356, 0x0000 },
  { 0x8700, 0x1359, 0x2000 },
  { 0x0700, 0x1358, 0x0000 },
  { 0x0700, 0x135a, 0x0000 },
  { 0x9500, 0x1365, 0x3000 },
  { 0x9500, 0x1363, 0x2000 },
  { 0x1500, 0x1362, 0x0000 },
  { 0x1500, 0x1364, 0x0000 },
  { 0x9500, 0x1367, 0x2000 },
  { 0x1500, 0x1366, 0x0000 },
  { 0x1500, 0x1368, 0x0000 },
  { 0x8700, 0x13ac, 0x6000 },
  { 0x8f00, 0x1379, 0x5000 },
  { 0x8d00, 0x1371, 0x4000 },
  { 0x8d00, 0x136d, 0x3000 },
  { 0x8d00, 0x136b, 0x2000 },
  { 0x0d00, 0x136a, 0x0000 },
  { 0x0d00, 0x136c, 0x0000 },
  { 0x8d00, 0x136f, 0x2000 },
  { 0x0d00, 0x136e, 0x0000 },
  { 0x0d00, 0x1370, 0x0000 },
  { 0x8f00, 0x1375, 0x3000 },
  { 0x8f00, 0x1373, 0x2000 },
  { 0x0f00, 0x1372, 0x0000 },
  { 0x0f00, 0x1374, 0x0000 },
  { 0x8f00, 0x1377, 0x2000 },
  { 0x0f00, 0x1376, 0x0000 },
  { 0x0f00, 0x1378, 0x0000 },
  { 0x8700, 0x13a4, 0x4000 },
  { 0x8700, 0x13a0, 0x3000 },
  { 0x8f00, 0x137b, 0x2000 },
  { 0x0f00, 0x137a, 0x0000 },
  { 0x0f00, 0x137c, 0x0000 },
  { 0x8700, 0x13a2, 0x2000 },
  { 0x0700, 0x13a1, 0x0000 },
  { 0x0700, 0x13a3, 0x0000 },
  { 0x8700, 0x13a8, 0x3000 },
  { 0x8700, 0x13a6, 0x2000 },
  { 0x0700, 0x13a5, 0x0000 },
  { 0x0700, 0x13a7, 0x0000 },
  { 0x8700, 0x13aa, 0x2000 },
  { 0x0700, 0x13a9, 0x0000 },
  { 0x0700, 0x13ab, 0x0000 },
  { 0x8700, 0x13bc, 0x5000 },
  { 0x8700, 0x13b4, 0x4000 },
  { 0x8700, 0x13b0, 0x3000 },
  { 0x8700, 0x13ae, 0x2000 },
  { 0x0700, 0x13ad, 0x0000 },
  { 0x0700, 0x13af, 0x0000 },
  { 0x8700, 0x13b2, 0x2000 },
  { 0x0700, 0x13b1, 0x0000 },
  { 0x0700, 0x13b3, 0x0000 },
  { 0x8700, 0x13b8, 0x3000 },
  { 0x8700, 0x13b6, 0x2000 },
  { 0x0700, 0x13b5, 0x0000 },
  { 0x0700, 0x13b7, 0x0000 },
  { 0x8700, 0x13ba, 0x2000 },
  { 0x0700, 0x13b9, 0x0000 },
  { 0x0700, 0x13bb, 0x0000 },
  { 0x8700, 0x13c4, 0x4000 },
  { 0x8700, 0x13c0, 0x3000 },
  { 0x8700, 0x13be, 0x2000 },
  { 0x0700, 0x13bd, 0x0000 },
  { 0x0700, 0x13bf, 0x0000 },
  { 0x8700, 0x13c2, 0x2000 },
  { 0x0700, 0x13c1, 0x0000 },
  { 0x0700, 0x13c3, 0x0000 },
  { 0x8700, 0x13c8, 0x3000 },
  { 0x8700, 0x13c6, 0x2000 },
  { 0x0700, 0x13c5, 0x0000 },
  { 0x0700, 0x13c7, 0x0000 },
  { 0x8700, 0x13ca, 0x2000 },
  { 0x0700, 0x13c9, 0x0000 },
  { 0x0700, 0x13cb, 0x0000 },
  { 0x8700, 0x1418, 0x7000 },
  { 0x8700, 0x13ec, 0x6000 },
  { 0x8700, 0x13dc, 0x5000 },
  { 0x8700, 0x13d4, 0x4000 },
  { 0x8700, 0x13d0, 0x3000 },
  { 0x8700, 0x13ce, 0x2000 },
  { 0x0700, 0x13cd, 0x0000 },
  { 0x0700, 0x13cf, 0x0000 },
  { 0x8700, 0x13d2, 0x2000 },
  { 0x0700, 0x13d1, 0x0000 },
  { 0x0700, 0x13d3, 0x0000 },
  { 0x8700, 0x13d8, 0x3000 },
  { 0x8700, 0x13d6, 0x2000 },
  { 0x0700, 0x13d5, 0x0000 },
  { 0x0700, 0x13d7, 0x0000 },
  { 0x8700, 0x13da, 0x2000 },
  { 0x0700, 0x13d9, 0x0000 },
  { 0x0700, 0x13db, 0x0000 },
  { 0x8700, 0x13e4, 0x4000 },
  { 0x8700, 0x13e0, 0x3000 },
  { 0x8700, 0x13de, 0x2000 },
  { 0x0700, 0x13dd, 0x0000 },
  { 0x0700, 0x13df, 0x0000 },
  { 0x8700, 0x13e2, 0x2000 },
  { 0x0700, 0x13e1, 0x0000 },
  { 0x0700, 0x13e3, 0x0000 },
  { 0x8700, 0x13e8, 0x3000 },
  { 0x8700, 0x13e6, 0x2000 },
  { 0x0700, 0x13e5, 0x0000 },
  { 0x0700, 0x13e7, 0x0000 },
  { 0x8700, 0x13ea, 0x2000 },
  { 0x0700, 0x13e9, 0x0000 },
  { 0x0700, 0x13eb, 0x0000 },
  { 0x8700, 0x1408, 0x5000 },
  { 0x8700, 0x13f4, 0x4000 },
  { 0x8700, 0x13f0, 0x3000 },
  { 0x8700, 0x13ee, 0x2000 },
  { 0x0700, 0x13ed, 0x0000 },
  { 0x0700, 0x13ef, 0x0000 },
  { 0x8700, 0x13f2, 0x2000 },
  { 0x0700, 0x13f1, 0x0000 },
  { 0x0700, 0x13f3, 0x0000 },
  { 0x8700, 0x1404, 0x3000 },
  { 0x8700, 0x1402, 0x2000 },
  { 0x0700, 0x1401, 0x0000 },
  { 0x0700, 0x1403, 0x0000 },
  { 0x8700, 0x1406, 0x2000 },
  { 0x0700, 0x1405, 0x0000 },
  { 0x0700, 0x1407, 0x0000 },
  { 0x8700, 0x1410, 0x4000 },
  { 0x8700, 0x140c, 0x3000 },
  { 0x8700, 0x140a, 0x2000 },
  { 0x0700, 0x1409, 0x0000 },
  { 0x0700, 0x140b, 0x0000 },
  { 0x8700, 0x140e, 0x2000 },
  { 0x0700, 0x140d, 0x0000 },
  { 0x0700, 0x140f, 0x0000 },
  { 0x8700, 0x1414, 0x3000 },
  { 0x8700, 0x1412, 0x2000 },
  { 0x0700, 0x1411, 0x0000 },
  { 0x0700, 0x1413, 0x0000 },
  { 0x8700, 0x1416, 0x2000 },
  { 0x0700, 0x1415, 0x0000 },
  { 0x0700, 0x1417, 0x0000 },
  { 0x8700, 0x1438, 0x6000 },
  { 0x8700, 0x1428, 0x5000 },
  { 0x8700, 0x1420, 0x4000 },
  { 0x8700, 0x141c, 0x3000 },
  { 0x8700, 0x141a, 0x2000 },
  { 0x0700, 0x1419, 0x0000 },
  { 0x0700, 0x141b, 0x0000 },
  { 0x8700, 0x141e, 0x2000 },
  { 0x0700, 0x141d, 0x0000 },
  { 0x0700, 0x141f, 0x0000 },
  { 0x8700, 0x1424, 0x3000 },
  { 0x8700, 0x1422, 0x2000 },
  { 0x0700, 0x1421, 0x0000 },
  { 0x0700, 0x1423, 0x0000 },
  { 0x8700, 0x1426, 0x2000 },
  { 0x0700, 0x1425, 0x0000 },
  { 0x0700, 0x1427, 0x0000 },
  { 0x8700, 0x1430, 0x4000 },
  { 0x8700, 0x142c, 0x3000 },
  { 0x8700, 0x142a, 0x2000 },
  { 0x0700, 0x1429, 0x0000 },
  { 0x0700, 0x142b, 0x0000 },
  { 0x8700, 0x142e, 0x2000 },
  { 0x0700, 0x142d, 0x0000 },
  { 0x0700, 0x142f, 0x0000 },
  { 0x8700, 0x1434, 0x3000 },
  { 0x8700, 0x1432, 0x2000 },
  { 0x0700, 0x1431, 0x0000 },
  { 0x0700, 0x1433, 0x0000 },
  { 0x8700, 0x1436, 0x2000 },
  { 0x0700, 0x1435, 0x0000 },
  { 0x0700, 0x1437, 0x0000 },
  { 0x8700, 0x1448, 0x5000 },
  { 0x8700, 0x1440, 0x4000 },
  { 0x8700, 0x143c, 0x3000 },
  { 0x8700, 0x143a, 0x2000 },
  { 0x0700, 0x1439, 0x0000 },
  { 0x0700, 0x143b, 0x0000 },
  { 0x8700, 0x143e, 0x2000 },
  { 0x0700, 0x143d, 0x0000 },
  { 0x0700, 0x143f, 0x0000 },
  { 0x8700, 0x1444, 0x3000 },
  { 0x8700, 0x1442, 0x2000 },
  { 0x0700, 0x1441, 0x0000 },
  { 0x0700, 0x1443, 0x0000 },
  { 0x8700, 0x1446, 0x2000 },
  { 0x0700, 0x1445, 0x0000 },
  { 0x0700, 0x1447, 0x0000 },
  { 0x8700, 0x1450, 0x4000 },
  { 0x8700, 0x144c, 0x3000 },
  { 0x8700, 0x144a, 0x2000 },
  { 0x0700, 0x1449, 0x0000 },
  { 0x0700, 0x144b, 0x0000 },
  { 0x8700, 0x144e, 0x2000 },
  { 0x0700, 0x144d, 0x0000 },
  { 0x0700, 0x144f, 0x0000 },
  { 0x8700, 0x1454, 0x3000 },
  { 0x8700, 0x1452, 0x2000 },
  { 0x0700, 0x1451, 0x0000 },
  { 0x0700, 0x1453, 0x0000 },
  { 0x8700, 0x1456, 0x2000 },
  { 0x0700, 0x1455, 0x0000 },
  { 0x0700, 0x1457, 0x0000 },
  { 0x8700, 0x14d8, 0x8000 },
  { 0x8700, 0x1498, 0x7000 },
  { 0x8700, 0x1478, 0x6000 },
  { 0x8700, 0x1468, 0x5000 },
  { 0x8700, 0x1460, 0x4000 },
  { 0x8700, 0x145c, 0x3000 },
  { 0x8700, 0x145a, 0x2000 },
  { 0x0700, 0x1459, 0x0000 },
  { 0x0700, 0x145b, 0x0000 },
  { 0x8700, 0x145e, 0x2000 },
  { 0x0700, 0x145d, 0x0000 },
  { 0x0700, 0x145f, 0x0000 },
  { 0x8700, 0x1464, 0x3000 },
  { 0x8700, 0x1462, 0x2000 },
  { 0x0700, 0x1461, 0x0000 },
  { 0x0700, 0x1463, 0x0000 },
  { 0x8700, 0x1466, 0x2000 },
  { 0x0700, 0x1465, 0x0000 },
  { 0x0700, 0x1467, 0x0000 },
  { 0x8700, 0x1470, 0x4000 },
  { 0x8700, 0x146c, 0x3000 },
  { 0x8700, 0x146a, 0x2000 },
  { 0x0700, 0x1469, 0x0000 },
  { 0x0700, 0x146b, 0x0000 },
  { 0x8700, 0x146e, 0x2000 },
  { 0x0700, 0x146d, 0x0000 },
  { 0x0700, 0x146f, 0x0000 },
  { 0x8700, 0x1474, 0x3000 },
  { 0x8700, 0x1472, 0x2000 },
  { 0x0700, 0x1471, 0x0000 },
  { 0x0700, 0x1473, 0x0000 },
  { 0x8700, 0x1476, 0x2000 },
  { 0x0700, 0x1475, 0x0000 },
  { 0x0700, 0x1477, 0x0000 },
  { 0x8700, 0x1488, 0x5000 },
  { 0x8700, 0x1480, 0x4000 },
  { 0x8700, 0x147c, 0x3000 },
  { 0x8700, 0x147a, 0x2000 },
  { 0x0700, 0x1479, 0x0000 },
  { 0x0700, 0x147b, 0x0000 },
  { 0x8700, 0x147e, 0x2000 },
  { 0x0700, 0x147d, 0x0000 },
  { 0x0700, 0x147f, 0x0000 },
  { 0x8700, 0x1484, 0x3000 },
  { 0x8700, 0x1482, 0x2000 },
  { 0x0700, 0x1481, 0x0000 },
  { 0x0700, 0x1483, 0x0000 },
  { 0x8700, 0x1486, 0x2000 },
  { 0x0700, 0x1485, 0x0000 },
  { 0x0700, 0x1487, 0x0000 },
  { 0x8700, 0x1490, 0x4000 },
  { 0x8700, 0x148c, 0x3000 },
  { 0x8700, 0x148a, 0x2000 },
  { 0x0700, 0x1489, 0x0000 },
  { 0x0700, 0x148b, 0x0000 },
  { 0x8700, 0x148e, 0x2000 },
  { 0x0700, 0x148d, 0x0000 },
  { 0x0700, 0x148f, 0x0000 },
  { 0x8700, 0x1494, 0x3000 },
  { 0x8700, 0x1492, 0x2000 },
  { 0x0700, 0x1491, 0x0000 },
  { 0x0700, 0x1493, 0x0000 },
  { 0x8700, 0x1496, 0x2000 },
  { 0x0700, 0x1495, 0x0000 },
  { 0x0700, 0x1497, 0x0000 },
  { 0x8700, 0x14b8, 0x6000 },
  { 0x8700, 0x14a8, 0x5000 },
  { 0x8700, 0x14a0, 0x4000 },
  { 0x8700, 0x149c, 0x3000 },
  { 0x8700, 0x149a, 0x2000 },
  { 0x0700, 0x1499, 0x0000 },
  { 0x0700, 0x149b, 0x0000 },
  { 0x8700, 0x149e, 0x2000 },
  { 0x0700, 0x149d, 0x0000 },
  { 0x0700, 0x149f, 0x0000 },
  { 0x8700, 0x14a4, 0x3000 },
  { 0x8700, 0x14a2, 0x2000 },
  { 0x0700, 0x14a1, 0x0000 },
  { 0x0700, 0x14a3, 0x0000 },
  { 0x8700, 0x14a6, 0x2000 },
  { 0x0700, 0x14a5, 0x0000 },
  { 0x0700, 0x14a7, 0x0000 },
  { 0x8700, 0x14b0, 0x4000 },
  { 0x8700, 0x14ac, 0x3000 },
  { 0x8700, 0x14aa, 0x2000 },
  { 0x0700, 0x14a9, 0x0000 },
  { 0x0700, 0x14ab, 0x0000 },
  { 0x8700, 0x14ae, 0x2000 },
  { 0x0700, 0x14ad, 0x0000 },
  { 0x0700, 0x14af, 0x0000 },
  { 0x8700, 0x14b4, 0x3000 },
  { 0x8700, 0x14b2, 0x2000 },
  { 0x0700, 0x14b1, 0x0000 },
  { 0x0700, 0x14b3, 0x0000 },
  { 0x8700, 0x14b6, 0x2000 },
  { 0x0700, 0x14b5, 0x0000 },
  { 0x0700, 0x14b7, 0x0000 },
  { 0x8700, 0x14c8, 0x5000 },
  { 0x8700, 0x14c0, 0x4000 },
  { 0x8700, 0x14bc, 0x3000 },
  { 0x8700, 0x14ba, 0x2000 },
  { 0x0700, 0x14b9, 0x0000 },
  { 0x0700, 0x14bb, 0x0000 },
  { 0x8700, 0x14be, 0x2000 },
  { 0x0700, 0x14bd, 0x0000 },
  { 0x0700, 0x14bf, 0x0000 },
  { 0x8700, 0x14c4, 0x3000 },
  { 0x8700, 0x14c2, 0x2000 },
  { 0x0700, 0x14c1, 0x0000 },
  { 0x0700, 0x14c3, 0x0000 },
  { 0x8700, 0x14c6, 0x2000 },
  { 0x0700, 0x14c5, 0x0000 },
  { 0x0700, 0x14c7, 0x0000 },
  { 0x8700, 0x14d0, 0x4000 },
  { 0x8700, 0x14cc, 0x3000 },
  { 0x8700, 0x14ca, 0x2000 },
  { 0x0700, 0x14c9, 0x0000 },
  { 0x0700, 0x14cb, 0x0000 },
  { 0x8700, 0x14ce, 0x2000 },
  { 0x0700, 0x14cd, 0x0000 },
  { 0x0700, 0x14cf, 0x0000 },
  { 0x8700, 0x14d4, 0x3000 },
  { 0x8700, 0x14d2, 0x2000 },
  { 0x0700, 0x14d1, 0x0000 },
  { 0x0700, 0x14d3, 0x0000 },
  { 0x8700, 0x14d6, 0x2000 },
  { 0x0700, 0x14d5, 0x0000 },
  { 0x0700, 0x14d7, 0x0000 },
  { 0x8700, 0x1518, 0x7000 },
  { 0x8700, 0x14f8, 0x6000 },
  { 0x8700, 0x14e8, 0x5000 },
  { 0x8700, 0x14e0, 0x4000 },
  { 0x8700, 0x14dc, 0x3000 },
  { 0x8700, 0x14da, 0x2000 },
  { 0x0700, 0x14d9, 0x0000 },
  { 0x0700, 0x14db, 0x0000 },
  { 0x8700, 0x14de, 0x2000 },
  { 0x0700, 0x14dd, 0x0000 },
  { 0x0700, 0x14df, 0x0000 },
  { 0x8700, 0x14e4, 0x3000 },
  { 0x8700, 0x14e2, 0x2000 },
  { 0x0700, 0x14e1, 0x0000 },
  { 0x0700, 0x14e3, 0x0000 },
  { 0x8700, 0x14e6, 0x2000 },
  { 0x0700, 0x14e5, 0x0000 },
  { 0x0700, 0x14e7, 0x0000 },
  { 0x8700, 0x14f0, 0x4000 },
  { 0x8700, 0x14ec, 0x3000 },
  { 0x8700, 0x14ea, 0x2000 },
  { 0x0700, 0x14e9, 0x0000 },
  { 0x0700, 0x14eb, 0x0000 },
  { 0x8700, 0x14ee, 0x2000 },
  { 0x0700, 0x14ed, 0x0000 },
  { 0x0700, 0x14ef, 0x0000 },
  { 0x8700, 0x14f4, 0x3000 },
  { 0x8700, 0x14f2, 0x2000 },
  { 0x0700, 0x14f1, 0x0000 },
  { 0x0700, 0x14f3, 0x0000 },
  { 0x8700, 0x14f6, 0x2000 },
  { 0x0700, 0x14f5, 0x0000 },
  { 0x0700, 0x14f7, 0x0000 },
  { 0x8700, 0x1508, 0x5000 },
  { 0x8700, 0x1500, 0x4000 },
  { 0x8700, 0x14fc, 0x3000 },
  { 0x8700, 0x14fa, 0x2000 },
  { 0x0700, 0x14f9, 0x0000 },
  { 0x0700, 0x14fb, 0x0000 },
  { 0x8700, 0x14fe, 0x2000 },
  { 0x0700, 0x14fd, 0x0000 },
  { 0x0700, 0x14ff, 0x0000 },
  { 0x8700, 0x1504, 0x3000 },
  { 0x8700, 0x1502, 0x2000 },
  { 0x0700, 0x1501, 0x0000 },
  { 0x0700, 0x1503, 0x0000 },
  { 0x8700, 0x1506, 0x2000 },
  { 0x0700, 0x1505, 0x0000 },
  { 0x0700, 0x1507, 0x0000 },
  { 0x8700, 0x1510, 0x4000 },
  { 0x8700, 0x150c, 0x3000 },
  { 0x8700, 0x150a, 0x2000 },
  { 0x0700, 0x1509, 0x0000 },
  { 0x0700, 0x150b, 0x0000 },
  { 0x8700, 0x150e, 0x2000 },
  { 0x0700, 0x150d, 0x0000 },
  { 0x0700, 0x150f, 0x0000 },
  { 0x8700, 0x1514, 0x3000 },
  { 0x8700, 0x1512, 0x2000 },
  { 0x0700, 0x1511, 0x0000 },
  { 0x0700, 0x1513, 0x0000 },
  { 0x8700, 0x1516, 0x2000 },
  { 0x0700, 0x1515, 0x0000 },
  { 0x0700, 0x1517, 0x0000 },
  { 0x8700, 0x1538, 0x6000 },
  { 0x8700, 0x1528, 0x5000 },
  { 0x8700, 0x1520, 0x4000 },
  { 0x8700, 0x151c, 0x3000 },
  { 0x8700, 0x151a, 0x2000 },
  { 0x0700, 0x1519, 0x0000 },
  { 0x0700, 0x151b, 0x0000 },
  { 0x8700, 0x151e, 0x2000 },
  { 0x0700, 0x151d, 0x0000 },
  { 0x0700, 0x151f, 0x0000 },
  { 0x8700, 0x1524, 0x3000 },
  { 0x8700, 0x1522, 0x2000 },
  { 0x0700, 0x1521, 0x0000 },
  { 0x0700, 0x1523, 0x0000 },
  { 0x8700, 0x1526, 0x2000 },
  { 0x0700, 0x1525, 0x0000 },
  { 0x0700, 0x1527, 0x0000 },
  { 0x8700, 0x1530, 0x4000 },
  { 0x8700, 0x152c, 0x3000 },
  { 0x8700, 0x152a, 0x2000 },
  { 0x0700, 0x1529, 0x0000 },
  { 0x0700, 0x152b, 0x0000 },
  { 0x8700, 0x152e, 0x2000 },
  { 0x0700, 0x152d, 0x0000 },
  { 0x0700, 0x152f, 0x0000 },
  { 0x8700, 0x1534, 0x3000 },
  { 0x8700, 0x1532, 0x2000 },
  { 0x0700, 0x1531, 0x0000 },
  { 0x0700, 0x1533, 0x0000 },
  { 0x8700, 0x1536, 0x2000 },
  { 0x0700, 0x1535, 0x0000 },
  { 0x0700, 0x1537, 0x0000 },
  { 0x8700, 0x1548, 0x5000 },
  { 0x8700, 0x1540, 0x4000 },
  { 0x8700, 0x153c, 0x3000 },
  { 0x8700, 0x153a, 0x2000 },
  { 0x0700, 0x1539, 0x0000 },
  { 0x0700, 0x153b, 0x0000 },
  { 0x8700, 0x153e, 0x2000 },
  { 0x0700, 0x153d, 0x0000 },
  { 0x0700, 0x153f, 0x0000 },
  { 0x8700, 0x1544, 0x3000 },
  { 0x8700, 0x1542, 0x2000 },
  { 0x0700, 0x1541, 0x0000 },
  { 0x0700, 0x1543, 0x0000 },
  { 0x8700, 0x1546, 0x2000 },
  { 0x0700, 0x1545, 0x0000 },
  { 0x0700, 0x1547, 0x0000 },
  { 0x8700, 0x1550, 0x4000 },
  { 0x8700, 0x154c, 0x3000 },
  { 0x8700, 0x154a, 0x2000 },
  { 0x0700, 0x1549, 0x0000 },
  { 0x0700, 0x154b, 0x0000 },
  { 0x8700, 0x154e, 0x2000 },
  { 0x0700, 0x154d, 0x0000 },
  { 0x0700, 0x154f, 0x0000 },
  { 0x8700, 0x1554, 0x3000 },
  { 0x8700, 0x1552, 0x2000 },
  { 0x0700, 0x1551, 0x0000 },
  { 0x0700, 0x1553, 0x0000 },
  { 0x8700, 0x1556, 0x2000 },
  { 0x0700, 0x1555, 0x0000 },
  { 0x0700, 0x1557, 0x0000 },
  { 0x9900, 0x22ae, 0xc000 },
  { 0x8900, 0x1e24, 0xb001 },
  { 0x8700, 0x17a2, 0xa000 },
  { 0x8700, 0x1658, 0x9000 },
  { 0x8700, 0x15d8, 0x8000 },
  { 0x8700, 0x1598, 0x7000 },
  { 0x8700, 0x1578, 0x6000 },
  { 0x8700, 0x1568, 0x5000 },
  { 0x8700, 0x1560, 0x4000 },
  { 0x8700, 0x155c, 0x3000 },
  { 0x8700, 0x155a, 0x2000 },
  { 0x0700, 0x1559, 0x0000 },
  { 0x0700, 0x155b, 0x0000 },
  { 0x8700, 0x155e, 0x2000 },
  { 0x0700, 0x155d, 0x0000 },
  { 0x0700, 0x155f, 0x0000 },
  { 0x8700, 0x1564, 0x3000 },
  { 0x8700, 0x1562, 0x2000 },
  { 0x0700, 0x1561, 0x0000 },
  { 0x0700, 0x1563, 0x0000 },
  { 0x8700, 0x1566, 0x2000 },
  { 0x0700, 0x1565, 0x0000 },
  { 0x0700, 0x1567, 0x0000 },
  { 0x8700, 0x1570, 0x4000 },
  { 0x8700, 0x156c, 0x3000 },
  { 0x8700, 0x156a, 0x2000 },
  { 0x0700, 0x1569, 0x0000 },
  { 0x0700, 0x156b, 0x0000 },
  { 0x8700, 0x156e, 0x2000 },
  { 0x0700, 0x156d, 0x0000 },
  { 0x0700, 0x156f, 0x0000 },
  { 0x8700, 0x1574, 0x3000 },
  { 0x8700, 0x1572, 0x2000 },
  { 0x0700, 0x1571, 0x0000 },
  { 0x0700, 0x1573, 0x0000 },
  { 0x8700, 0x1576, 0x2000 },
  { 0x0700, 0x1575, 0x0000 },
  { 0x0700, 0x1577, 0x0000 },
  { 0x8700, 0x1588, 0x5000 },
  { 0x8700, 0x1580, 0x4000 },
  { 0x8700, 0x157c, 0x3000 },
  { 0x8700, 0x157a, 0x2000 },
  { 0x0700, 0x1579, 0x0000 },
  { 0x0700, 0x157b, 0x0000 },
  { 0x8700, 0x157e, 0x2000 },
  { 0x0700, 0x157d, 0x0000 },
  { 0x0700, 0x157f, 0x0000 },
  { 0x8700, 0x1584, 0x3000 },
  { 0x8700, 0x1582, 0x2000 },
  { 0x0700, 0x1581, 0x0000 },
  { 0x0700, 0x1583, 0x0000 },
  { 0x8700, 0x1586, 0x2000 },
  { 0x0700, 0x1585, 0x0000 },
  { 0x0700, 0x1587, 0x0000 },
  { 0x8700, 0x1590, 0x4000 },
  { 0x8700, 0x158c, 0x3000 },
  { 0x8700, 0x158a, 0x2000 },
  { 0x0700, 0x1589, 0x0000 },
  { 0x0700, 0x158b, 0x0000 },
  { 0x8700, 0x158e, 0x2000 },
  { 0x0700, 0x158d, 0x0000 },
  { 0x0700, 0x158f, 0x0000 },
  { 0x8700, 0x1594, 0x3000 },
  { 0x8700, 0x1592, 0x2000 },
  { 0x0700, 0x1591, 0x0000 },
  { 0x0700, 0x1593, 0x0000 },
  { 0x8700, 0x1596, 0x2000 },
  { 0x0700, 0x1595, 0x0000 },
  { 0x0700, 0x1597, 0x0000 },
  { 0x8700, 0x15b8, 0x6000 },
  { 0x8700, 0x15a8, 0x5000 },
  { 0x8700, 0x15a0, 0x4000 },
  { 0x8700, 0x159c, 0x3000 },
  { 0x8700, 0x159a, 0x2000 },
  { 0x0700, 0x1599, 0x0000 },
  { 0x0700, 0x159b, 0x0000 },
  { 0x8700, 0x159e, 0x2000 },
  { 0x0700, 0x159d, 0x0000 },
  { 0x0700, 0x159f, 0x0000 },
  { 0x8700, 0x15a4, 0x3000 },
  { 0x8700, 0x15a2, 0x2000 },
  { 0x0700, 0x15a1, 0x0000 },
  { 0x0700, 0x15a3, 0x0000 },
  { 0x8700, 0x15a6, 0x2000 },
  { 0x0700, 0x15a5, 0x0000 },
  { 0x0700, 0x15a7, 0x0000 },
  { 0x8700, 0x15b0, 0x4000 },
  { 0x8700, 0x15ac, 0x3000 },
  { 0x8700, 0x15aa, 0x2000 },
  { 0x0700, 0x15a9, 0x0000 },
  { 0x0700, 0x15ab, 0x0000 },
  { 0x8700, 0x15ae, 0x2000 },
  { 0x0700, 0x15ad, 0x0000 },
  { 0x0700, 0x15af, 0x0000 },
  { 0x8700, 0x15b4, 0x3000 },
  { 0x8700, 0x15b2, 0x2000 },
  { 0x0700, 0x15b1, 0x0000 },
  { 0x0700, 0x15b3, 0x0000 },
  { 0x8700, 0x15b6, 0x2000 },
  { 0x0700, 0x15b5, 0x0000 },
  { 0x0700, 0x15b7, 0x0000 },
  { 0x8700, 0x15c8, 0x5000 },
  { 0x8700, 0x15c0, 0x4000 },
  { 0x8700, 0x15bc, 0x3000 },
  { 0x8700, 0x15ba, 0x2000 },
  { 0x0700, 0x15b9, 0x0000 },
  { 0x0700, 0x15bb, 0x0000 },
  { 0x8700, 0x15be, 0x2000 },
  { 0x0700, 0x15bd, 0x0000 },
  { 0x0700, 0x15bf, 0x0000 },
  { 0x8700, 0x15c4, 0x3000 },
  { 0x8700, 0x15c2, 0x2000 },
  { 0x0700, 0x15c1, 0x0000 },
  { 0x0700, 0x15c3, 0x0000 },
  { 0x8700, 0x15c6, 0x2000 },
  { 0x0700, 0x15c5, 0x0000 },
  { 0x0700, 0x15c7, 0x0000 },
  { 0x8700, 0x15d0, 0x4000 },
  { 0x8700, 0x15cc, 0x3000 },
  { 0x8700, 0x15ca, 0x2000 },
  { 0x0700, 0x15c9, 0x0000 },
  { 0x0700, 0x15cb, 0x0000 },
  { 0x8700, 0x15ce, 0x2000 },
  { 0x0700, 0x15cd, 0x0000 },
  { 0x0700, 0x15cf, 0x0000 },
  { 0x8700, 0x15d4, 0x3000 },
  { 0x8700, 0x15d2, 0x2000 },
  { 0x0700, 0x15d1, 0x0000 },
  { 0x0700, 0x15d3, 0x0000 },
  { 0x8700, 0x15d6, 0x2000 },
  { 0x0700, 0x15d5, 0x0000 },
  { 0x0700, 0x15d7, 0x0000 },
  { 0x8700, 0x1618, 0x7000 },
  { 0x8700, 0x15f8, 0x6000 },
  { 0x8700, 0x15e8, 0x5000 },
  { 0x8700, 0x15e0, 0x4000 },
  { 0x8700, 0x15dc, 0x3000 },
  { 0x8700, 0x15da, 0x2000 },
  { 0x0700, 0x15d9, 0x0000 },
  { 0x0700, 0x15db, 0x0000 },
  { 0x8700, 0x15de, 0x2000 },
  { 0x0700, 0x15dd, 0x0000 },
  { 0x0700, 0x15df, 0x0000 },
  { 0x8700, 0x15e4, 0x3000 },
  { 0x8700, 0x15e2, 0x2000 },
  { 0x0700, 0x15e1, 0x0000 },
  { 0x0700, 0x15e3, 0x0000 },
  { 0x8700, 0x15e6, 0x2000 },
  { 0x0700, 0x15e5, 0x0000 },
  { 0x0700, 0x15e7, 0x0000 },
  { 0x8700, 0x15f0, 0x4000 },
  { 0x8700, 0x15ec, 0x3000 },
  { 0x8700, 0x15ea, 0x2000 },
  { 0x0700, 0x15e9, 0x0000 },
  { 0x0700, 0x15eb, 0x0000 },
  { 0x8700, 0x15ee, 0x2000 },
  { 0x0700, 0x15ed, 0x0000 },
  { 0x0700, 0x15ef, 0x0000 },
  { 0x8700, 0x15f4, 0x3000 },
  { 0x8700, 0x15f2, 0x2000 },
  { 0x0700, 0x15f1, 0x0000 },
  { 0x0700, 0x15f3, 0x0000 },
  { 0x8700, 0x15f6, 0x2000 },
  { 0x0700, 0x15f5, 0x0000 },
  { 0x0700, 0x15f7, 0x0000 },
  { 0x8700, 0x1608, 0x5000 },
  { 0x8700, 0x1600, 0x4000 },
  { 0x8700, 0x15fc, 0x3000 },
  { 0x8700, 0x15fa, 0x2000 },
  { 0x0700, 0x15f9, 0x0000 },
  { 0x0700, 0x15fb, 0x0000 },
  { 0x8700, 0x15fe, 0x2000 },
  { 0x0700, 0x15fd, 0x0000 },
  { 0x0700, 0x15ff, 0x0000 },
  { 0x8700, 0x1604, 0x3000 },
  { 0x8700, 0x1602, 0x2000 },
  { 0x0700, 0x1601, 0x0000 },
  { 0x0700, 0x1603, 0x0000 },
  { 0x8700, 0x1606, 0x2000 },
  { 0x0700, 0x1605, 0x0000 },
  { 0x0700, 0x1607, 0x0000 },
  { 0x8700, 0x1610, 0x4000 },
  { 0x8700, 0x160c, 0x3000 },
  { 0x8700, 0x160a, 0x2000 },
  { 0x0700, 0x1609, 0x0000 },
  { 0x0700, 0x160b, 0x0000 },
  { 0x8700, 0x160e, 0x2000 },
  { 0x0700, 0x160d, 0x0000 },
  { 0x0700, 0x160f, 0x0000 },
  { 0x8700, 0x1614, 0x3000 },
  { 0x8700, 0x1612, 0x2000 },
  { 0x0700, 0x1611, 0x0000 },
  { 0x0700, 0x1613, 0x0000 },
  { 0x8700, 0x1616, 0x2000 },
  { 0x0700, 0x1615, 0x0000 },
  { 0x0700, 0x1617, 0x0000 },
  { 0x8700, 0x1638, 0x6000 },
  { 0x8700, 0x1628, 0x5000 },
  { 0x8700, 0x1620, 0x4000 },
  { 0x8700, 0x161c, 0x3000 },
  { 0x8700, 0x161a, 0x2000 },
  { 0x0700, 0x1619, 0x0000 },
  { 0x0700, 0x161b, 0x0000 },
  { 0x8700, 0x161e, 0x2000 },
  { 0x0700, 0x161d, 0x0000 },
  { 0x0700, 0x161f, 0x0000 },
  { 0x8700, 0x1624, 0x3000 },
  { 0x8700, 0x1622, 0x2000 },
  { 0x0700, 0x1621, 0x0000 },
  { 0x0700, 0x1623, 0x0000 },
  { 0x8700, 0x1626, 0x2000 },
  { 0x0700, 0x1625, 0x0000 },
  { 0x0700, 0x1627, 0x0000 },
  { 0x8700, 0x1630, 0x4000 },
  { 0x8700, 0x162c, 0x3000 },
  { 0x8700, 0x162a, 0x2000 },
  { 0x0700, 0x1629, 0x0000 },
  { 0x0700, 0x162b, 0x0000 },
  { 0x8700, 0x162e, 0x2000 },
  { 0x0700, 0x162d, 0x0000 },
  { 0x0700, 0x162f, 0x0000 },
  { 0x8700, 0x1634, 0x3000 },
  { 0x8700, 0x1632, 0x2000 },
  { 0x0700, 0x1631, 0x0000 },
  { 0x0700, 0x1633, 0x0000 },
  { 0x8700, 0x1636, 0x2000 },
  { 0x0700, 0x1635, 0x0000 },
  { 0x0700, 0x1637, 0x0000 },
  { 0x8700, 0x1648, 0x5000 },
  { 0x8700, 0x1640, 0x4000 },
  { 0x8700, 0x163c, 0x3000 },
  { 0x8700, 0x163a, 0x2000 },
  { 0x0700, 0x1639, 0x0000 },
  { 0x0700, 0x163b, 0x0000 },
  { 0x8700, 0x163e, 0x2000 },
  { 0x0700, 0x163d, 0x0000 },
  { 0x0700, 0x163f, 0x0000 },
  { 0x8700, 0x1644, 0x3000 },
  { 0x8700, 0x1642, 0x2000 },
  { 0x0700, 0x1641, 0x0000 },
  { 0x0700, 0x1643, 0x0000 },
  { 0x8700, 0x1646, 0x2000 },
  { 0x0700, 0x1645, 0x0000 },
  { 0x0700, 0x1647, 0x0000 },
  { 0x8700, 0x1650, 0x4000 },
  { 0x8700, 0x164c, 0x3000 },
  { 0x8700, 0x164a, 0x2000 },
  { 0x0700, 0x1649, 0x0000 },
  { 0x0700, 0x164b, 0x0000 },
  { 0x8700, 0x164e, 0x2000 },
  { 0x0700, 0x164d, 0x0000 },
  { 0x0700, 0x164f, 0x0000 },
  { 0x8700, 0x1654, 0x3000 },
  { 0x8700, 0x1652, 0x2000 },
  { 0x0700, 0x1651, 0x0000 },
  { 0x0700, 0x1653, 0x0000 },
  { 0x8700, 0x1656, 0x2000 },
  { 0x0700, 0x1655, 0x0000 },
  { 0x0700, 0x1657, 0x0000 },
  { 0x8700, 0x16e4, 0x8000 },
  { 0x8700, 0x16a4, 0x7000 },
  { 0x8700, 0x1681, 0x6000 },
  { 0x8700, 0x1668, 0x5000 },
  { 0x8700, 0x1660, 0x4000 },
  { 0x8700, 0x165c, 0x3000 },
  { 0x8700, 0x165a, 0x2000 },
  { 0x0700, 0x1659, 0x0000 },
  { 0x0700, 0x165b, 0x0000 },
  { 0x8700, 0x165e, 0x2000 },
  { 0x0700, 0x165d, 0x0000 },
  { 0x0700, 0x165f, 0x0000 },
  { 0x8700, 0x1664, 0x3000 },
  { 0x8700, 0x1662, 0x2000 },
  { 0x0700, 0x1661, 0x0000 },
  { 0x0700, 0x1663, 0x0000 },
  { 0x8700, 0x1666, 0x2000 },
  { 0x0700, 0x1665, 0x0000 },
  { 0x0700, 0x1667, 0x0000 },
  { 0x8700, 0x1670, 0x4000 },
  { 0x8700, 0x166c, 0x3000 },
  { 0x8700, 0x166a, 0x2000 },
  { 0x0700, 0x1669, 0x0000 },
  { 0x0700, 0x166b, 0x0000 },
  { 0x9500, 0x166e, 0x2000 },
  { 0x1500, 0x166d, 0x0000 },
  { 0x0700, 0x166f, 0x0000 },
  { 0x8700, 0x1674, 0x3000 },
  { 0x8700, 0x1672, 0x2000 },
  { 0x0700, 0x1671, 0x0000 },
  { 0x0700, 0x1673, 0x0000 },
  { 0x8700, 0x1676, 0x2000 },
  { 0x0700, 0x1675, 0x0000 },
  { 0x1d00, 0x1680, 0x0000 },
  { 0x8700, 0x1691, 0x5000 },
  { 0x8700, 0x1689, 0x4000 },
  { 0x8700, 0x1685, 0x3000 },
  { 0x8700, 0x1683, 0x2000 },
  { 0x0700, 0x1682, 0x0000 },
  { 0x0700, 0x1684, 0x0000 },
  { 0x8700, 0x1687, 0x2000 },
  { 0x0700, 0x1686, 0x0000 },
  { 0x0700, 0x1688, 0x0000 },
  { 0x8700, 0x168d, 0x3000 },
  { 0x8700, 0x168b, 0x2000 },
  { 0x0700, 0x168a, 0x0000 },
  { 0x0700, 0x168c, 0x0000 },
  { 0x8700, 0x168f, 0x2000 },
  { 0x0700, 0x168e, 0x0000 },
  { 0x0700, 0x1690, 0x0000 },
  { 0x8700, 0x1699, 0x4000 },
  { 0x8700, 0x1695, 0x3000 },
  { 0x8700, 0x1693, 0x2000 },
  { 0x0700, 0x1692, 0x0000 },
  { 0x0700, 0x1694, 0x0000 },
  { 0x8700, 0x1697, 0x2000 },
  { 0x0700, 0x1696, 0x0000 },
  { 0x0700, 0x1698, 0x0000 },
  { 0x8700, 0x16a0, 0x3000 },
  { 0x9600, 0x169b, 0x2000 },
  { 0x0700, 0x169a, 0x0000 },
  { 0x1200, 0x169c, 0x0000 },
  { 0x8700, 0x16a2, 0x2000 },
  { 0x0700, 0x16a1, 0x0000 },
  { 0x0700, 0x16a3, 0x0000 },
  { 0x8700, 0x16c4, 0x6000 },
  { 0x8700, 0x16b4, 0x5000 },
  { 0x8700, 0x16ac, 0x4000 },
  { 0x8700, 0x16a8, 0x3000 },
  { 0x8700, 0x16a6, 0x2000 },
  { 0x0700, 0x16a5, 0x0000 },
  { 0x0700, 0x16a7, 0x0000 },
  { 0x8700, 0x16aa, 0x2000 },
  { 0x0700, 0x16a9, 0x0000 },
  { 0x0700, 0x16ab, 0x0000 },
  { 0x8700, 0x16b0, 0x3000 },
  { 0x8700, 0x16ae, 0x2000 },
  { 0x0700, 0x16ad, 0x0000 },
  { 0x0700, 0x16af, 0x0000 },
  { 0x8700, 0x16b2, 0x2000 },
  { 0x0700, 0x16b1, 0x0000 },
  { 0x0700, 0x16b3, 0x0000 },
  { 0x8700, 0x16bc, 0x4000 },
  { 0x8700, 0x16b8, 0x3000 },
  { 0x8700, 0x16b6, 0x2000 },
  { 0x0700, 0x16b5, 0x0000 },
  { 0x0700, 0x16b7, 0x0000 },
  { 0x8700, 0x16ba, 0x2000 },
  { 0x0700, 0x16b9, 0x0000 },
  { 0x0700, 0x16bb, 0x0000 },
  { 0x8700, 0x16c0, 0x3000 },
  { 0x8700, 0x16be, 0x2000 },
  { 0x0700, 0x16bd, 0x0000 },
  { 0x0700, 0x16bf, 0x0000 },
  { 0x8700, 0x16c2, 0x2000 },
  { 0x0700, 0x16c1, 0x0000 },
  { 0x0700, 0x16c3, 0x0000 },
  { 0x8700, 0x16d4, 0x5000 },
  { 0x8700, 0x16cc, 0x4000 },
  { 0x8700, 0x16c8, 0x3000 },
  { 0x8700, 0x16c6, 0x2000 },
  { 0x0700, 0x16c5, 0x0000 },
  { 0x0700, 0x16c7, 0x0000 },
  { 0x8700, 0x16ca, 0x2000 },
  { 0x0700, 0x16c9, 0x0000 },
  { 0x0700, 0x16cb, 0x0000 },
  { 0x8700, 0x16d0, 0x3000 },
  { 0x8700, 0x16ce, 0x2000 },
  { 0x0700, 0x16cd, 0x0000 },
  { 0x0700, 0x16cf, 0x0000 },
  { 0x8700, 0x16d2, 0x2000 },
  { 0x0700, 0x16d1, 0x0000 },
  { 0x0700, 0x16d3, 0x0000 },
  { 0x8700, 0x16dc, 0x4000 },
  { 0x8700, 0x16d8, 0x3000 },
  { 0x8700, 0x16d6, 0x2000 },
  { 0x0700, 0x16d5, 0x0000 },
  { 0x0700, 0x16d7, 0x0000 },
  { 0x8700, 0x16da, 0x2000 },
  { 0x0700, 0x16d9, 0x0000 },
  { 0x0700, 0x16db, 0x0000 },
  { 0x8700, 0x16e0, 0x3000 },
  { 0x8700, 0x16de, 0x2000 },
  { 0x0700, 0x16dd, 0x0000 },
  { 0x0700, 0x16df, 0x0000 },
  { 0x8700, 0x16e2, 0x2000 },
  { 0x0700, 0x16e1, 0x0000 },
  { 0x0700, 0x16e3, 0x0000 },
  { 0x8700, 0x1748, 0x7000 },
  { 0x8c00, 0x1714, 0x6000 },
  { 0x8700, 0x1703, 0x5000 },
  { 0x9500, 0x16ec, 0x4000 },
  { 0x8700, 0x16e8, 0x3000 },
  { 0x8700, 0x16e6, 0x2000 },
  { 0x0700, 0x16e5, 0x0000 },
  { 0x0700, 0x16e7, 0x0000 },
  { 0x8700, 0x16ea, 0x2000 },
  { 0x0700, 0x16e9, 0x0000 },
  { 0x1500, 0x16eb, 0x0000 },
  { 0x8e00, 0x16f0, 0x3000 },
  { 0x8e00, 0x16ee, 0x2000 },
  { 0x1500, 0x16ed, 0x0000 },
  { 0x0e00, 0x16ef, 0x0000 },
  { 0x8700, 0x1701, 0x2000 },
  { 0x0700, 0x1700, 0x0000 },
  { 0x0700, 0x1702, 0x0000 },
  { 0x8700, 0x170b, 0x4000 },
  { 0x8700, 0x1707, 0x3000 },
  { 0x8700, 0x1705, 0x2000 },
  { 0x0700, 0x1704, 0x0000 },
  { 0x0700, 0x1706, 0x0000 },
  { 0x8700, 0x1709, 0x2000 },
  { 0x0700, 0x1708, 0x0000 },
  { 0x0700, 0x170a, 0x0000 },
  { 0x8700, 0x1710, 0x3000 },
  { 0x8700, 0x170e, 0x2000 },
  { 0x0700, 0x170c, 0x0000 },
  { 0x0700, 0x170f, 0x0000 },
  { 0x8c00, 0x1712, 0x2000 },
  { 0x0700, 0x1711, 0x0000 },
  { 0x0c00, 0x1713, 0x0000 },
  { 0x8700, 0x172f, 0x5000 },
  { 0x8700, 0x1727, 0x4000 },
  { 0x8700, 0x1723, 0x3000 },
  { 0x8700, 0x1721, 0x2000 },
  { 0x0700, 0x1720, 0x0000 },
  { 0x0700, 0x1722, 0x0000 },
  { 0x8700, 0x1725, 0x2000 },
  { 0x0700, 0x1724, 0x0000 },
  { 0x0700, 0x1726, 0x0000 },
  { 0x8700, 0x172b, 0x3000 },
  { 0x8700, 0x1729, 0x2000 },
  { 0x0700, 0x1728, 0x0000 },
  { 0x0700, 0x172a, 0x0000 },
  { 0x8700, 0x172d, 0x2000 },
  { 0x0700, 0x172c, 0x0000 },
  { 0x0700, 0x172e, 0x0000 },
  { 0x8700, 0x1740, 0x4000 },
  { 0x8c00, 0x1733, 0x3000 },
  { 0x8700, 0x1731, 0x2000 },
  { 0x0700, 0x1730, 0x0000 },
  { 0x0c00, 0x1732, 0x0000 },
  { 0x9500, 0x1735, 0x2000 },
  { 0x0c00, 0x1734, 0x0000 },
  { 0x1500, 0x1736, 0x0000 },
  { 0x8700, 0x1744, 0x3000 },
  { 0x8700, 0x1742, 0x2000 },
  { 0x0700, 0x1741, 0x0000 },
  { 0x0700, 0x1743, 0x0000 },
  { 0x8700, 0x1746, 0x2000 },
  { 0x0700, 0x1745, 0x0000 },
  { 0x0700, 0x1747, 0x0000 },
  { 0x8700, 0x1782, 0x6000 },
  { 0x8700, 0x1764, 0x5000 },
  { 0x8700, 0x1750, 0x4000 },
  { 0x8700, 0x174c, 0x3000 },
  { 0x8700, 0x174a, 0x2000 },
  { 0x0700, 0x1749, 0x0000 },
  { 0x0700, 0x174b, 0x0000 },
  { 0x8700, 0x174e, 0x2000 },
  { 0x0700, 0x174d, 0x0000 },
  { 0x0700, 0x174f, 0x0000 },
  { 0x8700, 0x1760, 0x3000 },
  { 0x8c00, 0x1752, 0x2000 },
  { 0x0700, 0x1751, 0x0000 },
  { 0x0c00, 0x1753, 0x0000 },
  { 0x8700, 0x1762, 0x2000 },
  { 0x0700, 0x1761, 0x0000 },
  { 0x0700, 0x1763, 0x0000 },
  { 0x8700, 0x176c, 0x4000 },
  { 0x8700, 0x1768, 0x3000 },
  { 0x8700, 0x1766, 0x2000 },
  { 0x0700, 0x1765, 0x0000 },
  { 0x0700, 0x1767, 0x0000 },
  { 0x8700, 0x176a, 0x2000 },
  { 0x0700, 0x1769, 0x0000 },
  { 0x0700, 0x176b, 0x0000 },
  { 0x8c00, 0x1772, 0x3000 },
  { 0x8700, 0x176f, 0x2000 },
  { 0x0700, 0x176e, 0x0000 },
  { 0x0700, 0x1770, 0x0000 },
  { 0x8700, 0x1780, 0x2000 },
  { 0x0c00, 0x1773, 0x0000 },
  { 0x0700, 0x1781, 0x0000 },
  { 0x8700, 0x1792, 0x5000 },
  { 0x8700, 0x178a, 0x4000 },
  { 0x8700, 0x1786, 0x3000 },
  { 0x8700, 0x1784, 0x2000 },
  { 0x0700, 0x1783, 0x0000 },
  { 0x0700, 0x1785, 0x0000 },
  { 0x8700, 0x1788, 0x2000 },
  { 0x0700, 0x1787, 0x0000 },
  { 0x0700, 0x1789, 0x0000 },
  { 0x8700, 0x178e, 0x3000 },
  { 0x8700, 0x178c, 0x2000 },
  { 0x0700, 0x178b, 0x0000 },
  { 0x0700, 0x178d, 0x0000 },
  { 0x8700, 0x1790, 0x2000 },
  { 0x0700, 0x178f, 0x0000 },
  { 0x0700, 0x1791, 0x0000 },
  { 0x8700, 0x179a, 0x4000 },
  { 0x8700, 0x1796, 0x3000 },
  { 0x8700, 0x1794, 0x2000 },
  { 0x0700, 0x1793, 0x0000 },
  { 0x0700, 0x1795, 0x0000 },
  { 0x8700, 0x1798, 0x2000 },
  { 0x0700, 0x1797, 0x0000 },
  { 0x0700, 0x1799, 0x0000 },
  { 0x8700, 0x179e, 0x3000 },
  { 0x8700, 0x179c, 0x2000 },
  { 0x0700, 0x179b, 0x0000 },
  { 0x0700, 0x179d, 0x0000 },
  { 0x8700, 0x17a0, 0x2000 },
  { 0x0700, 0x179f, 0x0000 },
  { 0x0700, 0x17a1, 0x0000 },
  { 0x8700, 0x1915, 0x9000 },
  { 0x8700, 0x1837, 0x8000 },
  { 0x8d00, 0x17e4, 0x7000 },
  { 0x8a00, 0x17c2, 0x6000 },
  { 0x8700, 0x17b2, 0x5000 },
  { 0x8700, 0x17aa, 0x4000 },
  { 0x8700, 0x17a6, 0x3000 },
  { 0x8700, 0x17a4, 0x2000 },
  { 0x0700, 0x17a3, 0x0000 },
  { 0x0700, 0x17a5, 0x0000 },
  { 0x8700, 0x17a8, 0x2000 },
  { 0x0700, 0x17a7, 0x0000 },
  { 0x0700, 0x17a9, 0x0000 },
  { 0x8700, 0x17ae, 0x3000 },
  { 0x8700, 0x17ac, 0x2000 },
  { 0x0700, 0x17ab, 0x0000 },
  { 0x0700, 0x17ad, 0x0000 },
  { 0x8700, 0x17b0, 0x2000 },
  { 0x0700, 0x17af, 0x0000 },
  { 0x0700, 0x17b1, 0x0000 },
  { 0x8c00, 0x17ba, 0x4000 },
  { 0x8a00, 0x17b6, 0x3000 },
  { 0x8100, 0x17b4, 0x2000 },
  { 0x0700, 0x17b3, 0x0000 },
  { 0x0100, 0x17b5, 0x0000 },
  { 0x8c00, 0x17b8, 0x2000 },
  { 0x0c00, 0x17b7, 0x0000 },
  { 0x0c00, 0x17b9, 0x0000 },
  { 0x8a00, 0x17be, 0x3000 },
  { 0x8c00, 0x17bc, 0x2000 },
  { 0x0c00, 0x17bb, 0x0000 },
  { 0x0c00, 0x17bd, 0x0000 },
  { 0x8a00, 0x17c0, 0x2000 },
  { 0x0a00, 0x17bf, 0x0000 },
  { 0x0a00, 0x17c1, 0x0000 },
  { 0x8c00, 0x17d2, 0x5000 },
  { 0x8c00, 0x17ca, 0x4000 },
  { 0x8c00, 0x17c6, 0x3000 },
  { 0x8a00, 0x17c4, 0x2000 },
  { 0x0a00, 0x17c3, 0x0000 },
  { 0x0a00, 0x17c5, 0x0000 },
  { 0x8a00, 0x17c8, 0x2000 },
  { 0x0a00, 0x17c7, 0x0000 },
  { 0x0c00, 0x17c9, 0x0000 },
  { 0x8c00, 0x17ce, 0x3000 },
  { 0x8c00, 0x17cc, 0x2000 },
  { 0x0c00, 0x17cb, 0x0000 },
  { 0x0c00, 0x17cd, 0x0000 },
  { 0x8c00, 0x17d0, 0x2000 },
  { 0x0c00, 0x17cf, 0x0000 },
  { 0x0c00, 0x17d1, 0x0000 },
  { 0x9500, 0x17da, 0x4000 },
  { 0x9500, 0x17d6, 0x3000 },
  { 0x9500, 0x17d4, 0x2000 },
  { 0x0c00, 0x17d3, 0x0000 },
  { 0x1500, 0x17d5, 0x0000 },
  { 0x9500, 0x17d8, 0x2000 },
  { 0x0600, 0x17d7, 0x0000 },
  { 0x1500, 0x17d9, 0x0000 },
  { 0x8d00, 0x17e0, 0x3000 },
  { 0x8700, 0x17dc, 0x2000 },
  { 0x1700, 0x17db, 0x0000 },
  { 0x0c00, 0x17dd, 0x0000 },
  { 0x8d00, 0x17e2, 0x2000 },
  { 0x0d00, 0x17e1, 0x0000 },
  { 0x0d00, 0x17e3, 0x0000 },
  { 0x8d00, 0x1811, 0x6000 },
  { 0x9500, 0x1800, 0x5000 },
  { 0x8f00, 0x17f2, 0x4000 },
  { 0x8d00, 0x17e8, 0x3000 },
  { 0x8d00, 0x17e6, 0x2000 },
  { 0x0d00, 0x17e5, 0x0000 },
  { 0x0d00, 0x17e7, 0x0000 },
  { 0x8f00, 0x17f0, 0x2000 },
  { 0x0d00, 0x17e9, 0x0000 },
  { 0x0f00, 0x17f1, 0x0000 },
  { 0x8f00, 0x17f6, 0x3000 },
  { 0x8f00, 0x17f4, 0x2000 },
  { 0x0f00, 0x17f3, 0x0000 },
  { 0x0f00, 0x17f5, 0x0000 },
  { 0x8f00, 0x17f8, 0x2000 },
  { 0x0f00, 0x17f7, 0x0000 },
  { 0x0f00, 0x17f9, 0x0000 },
  { 0x9500, 0x1808, 0x4000 },
  { 0x9500, 0x1804, 0x3000 },
  { 0x9500, 0x1802, 0x2000 },
  { 0x1500, 0x1801, 0x0000 },
  { 0x1500, 0x1803, 0x0000 },
  { 0x9100, 0x1806, 0x2000 },
  { 0x1500, 0x1805, 0x0000 },
  { 0x1500, 0x1807, 0x0000 },
  { 0x8c00, 0x180c, 0x3000 },
  { 0x9500, 0x180a, 0x2000 },
  { 0x1500, 0x1809, 0x0000 },
  { 0x0c00, 0x180b, 0x0000 },
  { 0x9d00, 0x180e, 0x2000 },
  { 0x0c00, 0x180d, 0x0000 },
  { 0x0d00, 0x1810, 0x0000 },
  { 0x8700, 0x1827, 0x5000 },
  { 0x8d00, 0x1819, 0x4000 },
  { 0x8d00, 0x1815, 0x3000 },
  { 0x8d00, 0x1813, 0x2000 },
  { 0x0d00, 0x1812, 0x0000 },
  { 0x0d00, 0x1814, 0x0000 },
  { 0x8d00, 0x1817, 0x2000 },
  { 0x0d00, 0x1816, 0x0000 },
  { 0x0d00, 0x1818, 0x0000 },
  { 0x8700, 0x1823, 0x3000 },
  { 0x8700, 0x1821, 0x2000 },
  { 0x0700, 0x1820, 0x0000 },
  { 0x0700, 0x1822, 0x0000 },
  { 0x8700, 0x1825, 0x2000 },
  { 0x0700, 0x1824, 0x0000 },
  { 0x0700, 0x1826, 0x0000 },
  { 0x8700, 0x182f, 0x4000 },
  { 0x8700, 0x182b, 0x3000 },
  { 0x8700, 0x1829, 0x2000 },
  { 0x0700, 0x1828, 0x0000 },
  { 0x0700, 0x182a, 0x0000 },
  { 0x8700, 0x182d, 0x2000 },
  { 0x0700, 0x182c, 0x0000 },
  { 0x0700, 0x182e, 0x0000 },
  { 0x8700, 0x1833, 0x3000 },
  { 0x8700, 0x1831, 0x2000 },
  { 0x0700, 0x1830, 0x0000 },
  { 0x0700, 0x1832, 0x0000 },
  { 0x8700, 0x1835, 0x2000 },
  { 0x0700, 0x1834, 0x0000 },
  { 0x0700, 0x1836, 0x0000 },
  { 0x8700, 0x1877, 0x7000 },
  { 0x8700, 0x1857, 0x6000 },
  { 0x8700, 0x1847, 0x5000 },
  { 0x8700, 0x183f, 0x4000 },
  { 0x8700, 0x183b, 0x3000 },
  { 0x8700, 0x1839, 0x2000 },
  { 0x0700, 0x1838, 0x0000 },
  { 0x0700, 0x183a, 0x0000 },
  { 0x8700, 0x183d, 0x2000 },
  { 0x0700, 0x183c, 0x0000 },
  { 0x0700, 0x183e, 0x0000 },
  { 0x8600, 0x1843, 0x3000 },
  { 0x8700, 0x1841, 0x2000 },
  { 0x0700, 0x1840, 0x0000 },
  { 0x0700, 0x1842, 0x0000 },
  { 0x8700, 0x1845, 0x2000 },
  { 0x0700, 0x1844, 0x0000 },
  { 0x0700, 0x1846, 0x0000 },
  { 0x8700, 0x184f, 0x4000 },
  { 0x8700, 0x184b, 0x3000 },
  { 0x8700, 0x1849, 0x2000 },
  { 0x0700, 0x1848, 0x0000 },
  { 0x0700, 0x184a, 0x0000 },
  { 0x8700, 0x184d, 0x2000 },
  { 0x0700, 0x184c, 0x0000 },
  { 0x0700, 0x184e, 0x0000 },
  { 0x8700, 0x1853, 0x3000 },
  { 0x8700, 0x1851, 0x2000 },
  { 0x0700, 0x1850, 0x0000 },
  { 0x0700, 0x1852, 0x0000 },
  { 0x8700, 0x1855, 0x2000 },
  { 0x0700, 0x1854, 0x0000 },
  { 0x0700, 0x1856, 0x0000 },
  { 0x8700, 0x1867, 0x5000 },
  { 0x8700, 0x185f, 0x4000 },
  { 0x8700, 0x185b, 0x3000 },
  { 0x8700, 0x1859, 0x2000 },
  { 0x0700, 0x1858, 0x0000 },
  { 0x0700, 0x185a, 0x0000 },
  { 0x8700, 0x185d, 0x2000 },
  { 0x0700, 0x185c, 0x0000 },
  { 0x0700, 0x185e, 0x0000 },
  { 0x8700, 0x1863, 0x3000 },
  { 0x8700, 0x1861, 0x2000 },
  { 0x0700, 0x1860, 0x0000 },
  { 0x0700, 0x1862, 0x0000 },
  { 0x8700, 0x1865, 0x2000 },
  { 0x0700, 0x1864, 0x0000 },
  { 0x0700, 0x1866, 0x0000 },
  { 0x8700, 0x186f, 0x4000 },
  { 0x8700, 0x186b, 0x3000 },
  { 0x8700, 0x1869, 0x2000 },
  { 0x0700, 0x1868, 0x0000 },
  { 0x0700, 0x186a, 0x0000 },
  { 0x8700, 0x186d, 0x2000 },
  { 0x0700, 0x186c, 0x0000 },
  { 0x0700, 0x186e, 0x0000 },
  { 0x8700, 0x1873, 0x3000 },
  { 0x8700, 0x1871, 0x2000 },
  { 0x0700, 0x1870, 0x0000 },
  { 0x0700, 0x1872, 0x0000 },
  { 0x8700, 0x1875, 0x2000 },
  { 0x0700, 0x1874, 0x0000 },
  { 0x0700, 0x1876, 0x0000 },
  { 0x8700, 0x189f, 0x6000 },
  { 0x8700, 0x188f, 0x5000 },
  { 0x8700, 0x1887, 0x4000 },
  { 0x8700, 0x1883, 0x3000 },
  { 0x8700, 0x1881, 0x2000 },
  { 0x0700, 0x1880, 0x0000 },
  { 0x0700, 0x1882, 0x0000 },
  { 0x8700, 0x1885, 0x2000 },
  { 0x0700, 0x1884, 0x0000 },
  { 0x0700, 0x1886, 0x0000 },
  { 0x8700, 0x188b, 0x3000 },
  { 0x8700, 0x1889, 0x2000 },
  { 0x0700, 0x1888, 0x0000 },
  { 0x0700, 0x188a, 0x0000 },
  { 0x8700, 0x188d, 0x2000 },
  { 0x0700, 0x188c, 0x0000 },
  { 0x0700, 0x188e, 0x0000 },
  { 0x8700, 0x1897, 0x4000 },
  { 0x8700, 0x1893, 0x3000 },
  { 0x8700, 0x1891, 0x2000 },
  { 0x0700, 0x1890, 0x0000 },
  { 0x0700, 0x1892, 0x0000 },
  { 0x8700, 0x1895, 0x2000 },
  { 0x0700, 0x1894, 0x0000 },
  { 0x0700, 0x1896, 0x0000 },
  { 0x8700, 0x189b, 0x3000 },
  { 0x8700, 0x1899, 0x2000 },
  { 0x0700, 0x1898, 0x0000 },
  { 0x0700, 0x189a, 0x0000 },
  { 0x8700, 0x189d, 0x2000 },
  { 0x0700, 0x189c, 0x0000 },
  { 0x0700, 0x189e, 0x0000 },
  { 0x8700, 0x1905, 0x5000 },
  { 0x8700, 0x18a7, 0x4000 },
  { 0x8700, 0x18a3, 0x3000 },
  { 0x8700, 0x18a1, 0x2000 },
  { 0x0700, 0x18a0, 0x0000 },
  { 0x0700, 0x18a2, 0x0000 },
  { 0x8700, 0x18a5, 0x2000 },
  { 0x0700, 0x18a4, 0x0000 },
  { 0x0700, 0x18a6, 0x0000 },
  { 0x8700, 0x1901, 0x3000 },
  { 0x8c00, 0x18a9, 0x2000 },
  { 0x0700, 0x18a8, 0x0000 },
  { 0x0700, 0x1900, 0x0000 },
  { 0x8700, 0x1903, 0x2000 },
  { 0x0700, 0x1902, 0x0000 },
  { 0x0700, 0x1904, 0x0000 },
  { 0x8700, 0x190d, 0x4000 },
  { 0x8700, 0x1909, 0x3000 },
  { 0x8700, 0x1907, 0x2000 },
  { 0x0700, 0x1906, 0x0000 },
  { 0x0700, 0x1908, 0x0000 },
  { 0x8700, 0x190b, 0x2000 },
  { 0x0700, 0x190a, 0x0000 },
  { 0x0700, 0x190c, 0x0000 },
  { 0x8700, 0x1911, 0x3000 },
  { 0x8700, 0x190f, 0x2000 },
  { 0x0700, 0x190e, 0x0000 },
  { 0x0700, 0x1910, 0x0000 },
  { 0x8700, 0x1913, 0x2000 },
  { 0x0700, 0x1912, 0x0000 },
  { 0x0700, 0x1914, 0x0000 },
  { 0x8500, 0x1d10, 0x8000 },
  { 0x8700, 0x1963, 0x7000 },
  { 0x9a00, 0x1940, 0x6000 },
  { 0x8c00, 0x1928, 0x5000 },
  { 0x8c00, 0x1920, 0x4000 },
  { 0x8700, 0x1919, 0x3000 },
  { 0x8700, 0x1917, 0x2000 },
  { 0x0700, 0x1916, 0x0000 },
  { 0x0700, 0x1918, 0x0000 },
  { 0x8700, 0x191b, 0x2000 },
  { 0x0700, 0x191a, 0x0000 },
  { 0x0700, 0x191c, 0x0000 },
  { 0x8a00, 0x1924, 0x3000 },
  { 0x8c00, 0x1922, 0x2000 },
  { 0x0c00, 0x1921, 0x0000 },
  { 0x0a00, 0x1923, 0x0000 },
  { 0x8a00, 0x1926, 0x2000 },
  { 0x0a00, 0x1925, 0x0000 },
  { 0x0c00, 0x1927, 0x0000 },
  { 0x8a00, 0x1934, 0x4000 },
  { 0x8a00, 0x1930, 0x3000 },
  { 0x8a00, 0x192a, 0x2000 },
  { 0x0a00, 0x1929, 0x0000 },
  { 0x0a00, 0x192b, 0x0000 },
  { 0x8c00, 0x1932, 0x2000 },
  { 0x0a00, 0x1931, 0x0000 },
  { 0x0a00, 0x1933, 0x0000 },
  { 0x8a00, 0x1938, 0x3000 },
  { 0x8a00, 0x1936, 0x2000 },
  { 0x0a00, 0x1935, 0x0000 },
  { 0x0a00, 0x1937, 0x0000 },
  { 0x8c00, 0x193a, 0x2000 },
  { 0x0c00, 0x1939, 0x0000 },
  { 0x0c00, 0x193b, 0x0000 },
  { 0x8700, 0x1953, 0x5000 },
  { 0x8d00, 0x194b, 0x4000 },
  { 0x8d00, 0x1947, 0x3000 },
  { 0x9500, 0x1945, 0x2000 },
  { 0x1500, 0x1944, 0x0000 },
  { 0x0d00, 0x1946, 0x0000 },
  { 0x8d00, 0x1949, 0x2000 },
  { 0x0d00, 0x1948, 0x0000 },
  { 0x0d00, 0x194a, 0x0000 },
  { 0x8d00, 0x194f, 0x3000 },
  { 0x8d00, 0x194d, 0x2000 },
  { 0x0d00, 0x194c, 0x0000 },
  { 0x0d00, 0x194e, 0x0000 },
  { 0x8700, 0x1951, 0x2000 },
  { 0x0700, 0x1950, 0x0000 },
  { 0x0700, 0x1952, 0x0000 },
  { 0x8700, 0x195b, 0x4000 },
  { 0x8700, 0x1957, 0x3000 },
  { 0x8700, 0x1955, 0x2000 },
  { 0x0700, 0x1954, 0x0000 },
  { 0x0700, 0x1956, 0x0000 },
  { 0x8700, 0x1959, 0x2000 },
  { 0x0700, 0x1958, 0x0000 },
  { 0x0700, 0x195a, 0x0000 },
  { 0x8700, 0x195f, 0x3000 },
  { 0x8700, 0x195d, 0x2000 },
  { 0x0700, 0x195c, 0x0000 },
  { 0x0700, 0x195e, 0x0000 },
  { 0x8700, 0x1961, 0x2000 },
  { 0x0700, 0x1960, 0x0000 },
  { 0x0700, 0x1962, 0x0000 },
  { 0x9a00, 0x19f0, 0x6000 },
  { 0x9a00, 0x19e0, 0x5000 },
  { 0x8700, 0x196b, 0x4000 },
  { 0x8700, 0x1967, 0x3000 },
  { 0x8700, 0x1965, 0x2000 },
  { 0x0700, 0x1964, 0x0000 },
  { 0x0700, 0x1966, 0x0000 },
  { 0x8700, 0x1969, 0x2000 },
  { 0x0700, 0x1968, 0x0000 },
  { 0x0700, 0x196a, 0x0000 },
  { 0x8700, 0x1971, 0x3000 },
  { 0x8700, 0x196d, 0x2000 },
  { 0x0700, 0x196c, 0x0000 },
  { 0x0700, 0x1970, 0x0000 },
  { 0x8700, 0x1973, 0x2000 },
  { 0x0700, 0x1972, 0x0000 },
  { 0x0700, 0x1974, 0x0000 },
  { 0x9a00, 0x19e8, 0x4000 },
  { 0x9a00, 0x19e4, 0x3000 },
  { 0x9a00, 0x19e2, 0x2000 },
  { 0x1a00, 0x19e1, 0x0000 },
  { 0x1a00, 0x19e3, 0x0000 },
  { 0x9a00, 0x19e6, 0x2000 },
  { 0x1a00, 0x19e5, 0x0000 },
  { 0x1a00, 0x19e7, 0x0000 },
  { 0x9a00, 0x19ec, 0x3000 },
  { 0x9a00, 0x19ea, 0x2000 },
  { 0x1a00, 0x19e9, 0x0000 },
  { 0x1a00, 0x19eb, 0x0000 },
  { 0x9a00, 0x19ee, 0x2000 },
  { 0x1a00, 0x19ed, 0x0000 },
  { 0x1a00, 0x19ef, 0x0000 },
  { 0x8500, 0x1d00, 0x5000 },
  { 0x9a00, 0x19f8, 0x4000 },
  { 0x9a00, 0x19f4, 0x3000 },
  { 0x9a00, 0x19f2, 0x2000 },
  { 0x1a00, 0x19f1, 0x0000 },
  { 0x1a00, 0x19f3, 0x0000 },
  { 0x9a00, 0x19f6, 0x2000 },
  { 0x1a00, 0x19f5, 0x0000 },
  { 0x1a00, 0x19f7, 0x0000 },
  { 0x9a00, 0x19fc, 0x3000 },
  { 0x9a00, 0x19fa, 0x2000 },
  { 0x1a00, 0x19f9, 0x0000 },
  { 0x1a00, 0x19fb, 0x0000 },
  { 0x9a00, 0x19fe, 0x2000 },
  { 0x1a00, 0x19fd, 0x0000 },
  { 0x1a00, 0x19ff, 0x0000 },
  { 0x8500, 0x1d08, 0x4000 },
  { 0x8500, 0x1d04, 0x3000 },
  { 0x8500, 0x1d02, 0x2000 },
  { 0x0500, 0x1d01, 0x0000 },
  { 0x0500, 0x1d03, 0x0000 },
  { 0x8500, 0x1d06, 0x2000 },
  { 0x0500, 0x1d05, 0x0000 },
  { 0x0500, 0x1d07, 0x0000 },
  { 0x8500, 0x1d0c, 0x3000 },
  { 0x8500, 0x1d0a, 0x2000 },
  { 0x0500, 0x1d09, 0x0000 },
  { 0x0500, 0x1d0b, 0x0000 },
  { 0x8500, 0x1d0e, 0x2000 },
  { 0x0500, 0x1d0d, 0x0000 },
  { 0x0500, 0x1d0f, 0x0000 },
  { 0x8600, 0x1d50, 0x7000 },
  { 0x8600, 0x1d30, 0x6000 },
  { 0x8500, 0x1d20, 0x5000 },
  { 0x8500, 0x1d18, 0x4000 },
  { 0x8500, 0x1d14, 0x3000 },
  { 0x8500, 0x1d12, 0x2000 },
  { 0x0500, 0x1d11, 0x0000 },
  { 0x0500, 0x1d13, 0x0000 },
  { 0x8500, 0x1d16, 0x2000 },
  { 0x0500, 0x1d15, 0x0000 },
  { 0x0500, 0x1d17, 0x0000 },
  { 0x8500, 0x1d1c, 0x3000 },
  { 0x8500, 0x1d1a, 0x2000 },
  { 0x0500, 0x1d19, 0x0000 },
  { 0x0500, 0x1d1b, 0x0000 },
  { 0x8500, 0x1d1e, 0x2000 },
  { 0x0500, 0x1d1d, 0x0000 },
  { 0x0500, 0x1d1f, 0x0000 },
  { 0x8500, 0x1d28, 0x4000 },
  { 0x8500, 0x1d24, 0x3000 },
  { 0x8500, 0x1d22, 0x2000 },
  { 0x0500, 0x1d21, 0x0000 },
  { 0x0500, 0x1d23, 0x0000 },
  { 0x8500, 0x1d26, 0x2000 },
  { 0x0500, 0x1d25, 0x0000 },
  { 0x0500, 0x1d27, 0x0000 },
  { 0x8600, 0x1d2c, 0x3000 },
  { 0x8500, 0x1d2a, 0x2000 },
  { 0x0500, 0x1d29, 0x0000 },
  { 0x0500, 0x1d2b, 0x0000 },
  { 0x8600, 0x1d2e, 0x2000 },
  { 0x0600, 0x1d2d, 0x0000 },
  { 0x0600, 0x1d2f, 0x0000 },
  { 0x8600, 0x1d40, 0x5000 },
  { 0x8600, 0x1d38, 0x4000 },
  { 0x8600, 0x1d34, 0x3000 },
  { 0x8600, 0x1d32, 0x2000 },
  { 0x0600, 0x1d31, 0x0000 },
  { 0x0600, 0x1d33, 0x0000 },
  { 0x8600, 0x1d36, 0x2000 },
  { 0x0600, 0x1d35, 0x0000 },
  { 0x0600, 0x1d37, 0x0000 },
  { 0x8600, 0x1d3c, 0x3000 },
  { 0x8600, 0x1d3a, 0x2000 },
  { 0x0600, 0x1d39, 0x0000 },
  { 0x0600, 0x1d3b, 0x0000 },
  { 0x8600, 0x1d3e, 0x2000 },
  { 0x0600, 0x1d3d, 0x0000 },
  { 0x0600, 0x1d3f, 0x0000 },
  { 0x8600, 0x1d48, 0x4000 },
  { 0x8600, 0x1d44, 0x3000 },
  { 0x8600, 0x1d42, 0x2000 },
  { 0x0600, 0x1d41, 0x0000 },
  { 0x0600, 0x1d43, 0x0000 },
  { 0x8600, 0x1d46, 0x2000 },
  { 0x0600, 0x1d45, 0x0000 },
  { 0x0600, 0x1d47, 0x0000 },
  { 0x8600, 0x1d4c, 0x3000 },
  { 0x8600, 0x1d4a, 0x2000 },
  { 0x0600, 0x1d49, 0x0000 },
  { 0x0600, 0x1d4b, 0x0000 },
  { 0x8600, 0x1d4e, 0x2000 },
  { 0x0600, 0x1d4d, 0x0000 },
  { 0x0600, 0x1d4f, 0x0000 },
  { 0x8900, 0x1e04, 0x6001 },
  { 0x8600, 0x1d60, 0x5000 },
  { 0x8600, 0x1d58, 0x4000 },
  { 0x8600, 0x1d54, 0x3000 },
  { 0x8600, 0x1d52, 0x2000 },
  { 0x0600, 0x1d51, 0x0000 },
  { 0x0600, 0x1d53, 0x0000 },
  { 0x8600, 0x1d56, 0x2000 },
  { 0x0600, 0x1d55, 0x0000 },
  { 0x0600, 0x1d57, 0x0000 },
  { 0x8600, 0x1d5c, 0x3000 },
  { 0x8600, 0x1d5a, 0x2000 },
  { 0x0600, 0x1d59, 0x0000 },
  { 0x0600, 0x1d5b, 0x0000 },
  { 0x8600, 0x1d5e, 0x2000 },
  { 0x0600, 0x1d5d, 0x0000 },
  { 0x0600, 0x1d5f, 0x0000 },
  { 0x8500, 0x1d68, 0x4000 },
  { 0x8500, 0x1d64, 0x3000 },
  { 0x8500, 0x1d62, 0x2000 },
  { 0x0600, 0x1d61, 0x0000 },
  { 0x0500, 0x1d63, 0x0000 },
  { 0x8500, 0x1d66, 0x2000 },
  { 0x0500, 0x1d65, 0x0000 },
  { 0x0500, 0x1d67, 0x0000 },
  { 0x8900, 0x1e00, 0x3001 },
  { 0x8500, 0x1d6a, 0x2000 },
  { 0x0500, 0x1d69, 0x0000 },
  { 0x0500, 0x1d6b, 0x0000 },
  { 0x8900, 0x1e02, 0x2001 },
  { 0x0500, 0x1e01, 0x0fff },
  { 0x0500, 0x1e03, 0x0fff },
  { 0x8900, 0x1e14, 0x5001 },
  { 0x8900, 0x1e0c, 0x4001 },
  { 0x8900, 0x1e08, 0x3001 },
  { 0x8900, 0x1e06, 0x2001 },
  { 0x0500, 0x1e05, 0x0fff },
  { 0x0500, 0x1e07, 0x0fff },
  { 0x8900, 0x1e0a, 0x2001 },
  { 0x0500, 0x1e09, 0x0fff },
  { 0x0500, 0x1e0b, 0x0fff },
  { 0x8900, 0x1e10, 0x3001 },
  { 0x8900, 0x1e0e, 0x2001 },
  { 0x0500, 0x1e0d, 0x0fff },
  { 0x0500, 0x1e0f, 0x0fff },
  { 0x8900, 0x1e12, 0x2001 },
  { 0x0500, 0x1e11, 0x0fff },
  { 0x0500, 0x1e13, 0x0fff },
  { 0x8900, 0x1e1c, 0x4001 },
  { 0x8900, 0x1e18, 0x3001 },
  { 0x8900, 0x1e16, 0x2001 },
  { 0x0500, 0x1e15, 0x0fff },
  { 0x0500, 0x1e17, 0x0fff },
  { 0x8900, 0x1e1a, 0x2001 },
  { 0x0500, 0x1e19, 0x0fff },
  { 0x0500, 0x1e1b, 0x0fff },
  { 0x8900, 0x1e20, 0x3001 },
  { 0x8900, 0x1e1e, 0x2001 },
  { 0x0500, 0x1e1d, 0x0fff },
  { 0x0500, 0x1e1f, 0x0fff },
  { 0x8900, 0x1e22, 0x2001 },
  { 0x0500, 0x1e21, 0x0fff },
  { 0x0500, 0x1e23, 0x0fff },
  { 0x9600, 0x2045, 0xa000 },
  { 0x8500, 0x1f32, 0x9008 },
  { 0x8900, 0x1ea8, 0x8001 },
  { 0x8900, 0x1e64, 0x7001 },
  { 0x8900, 0x1e44, 0x6001 },
  { 0x8900, 0x1e34, 0x5001 },
  { 0x8900, 0x1e2c, 0x4001 },
  { 0x8900, 0x1e28, 0x3001 },
  { 0x8900, 0x1e26, 0x2001 },
  { 0x0500, 0x1e25, 0x0fff },
  { 0x0500, 0x1e27, 0x0fff },
  { 0x8900, 0x1e2a, 0x2001 },
  { 0x0500, 0x1e29, 0x0fff },
  { 0x0500, 0x1e2b, 0x0fff },
  { 0x8900, 0x1e30, 0x3001 },
  { 0x8900, 0x1e2e, 0x2001 },
  { 0x0500, 0x1e2d, 0x0fff },
  { 0x0500, 0x1e2f, 0x0fff },
  { 0x8900, 0x1e32, 0x2001 },
  { 0x0500, 0x1e31, 0x0fff },
  { 0x0500, 0x1e33, 0x0fff },
  { 0x8900, 0x1e3c, 0x4001 },
  { 0x8900, 0x1e38, 0x3001 },
  { 0x8900, 0x1e36, 0x2001 },
  { 0x0500, 0x1e35, 0x0fff },
  { 0x0500, 0x1e37, 0x0fff },
  { 0x8900, 0x1e3a, 0x2001 },
  { 0x0500, 0x1e39, 0x0fff },
  { 0x0500, 0x1e3b, 0x0fff },
  { 0x8900, 0x1e40, 0x3001 },
  { 0x8900, 0x1e3e, 0x2001 },
  { 0x0500, 0x1e3d, 0x0fff },
  { 0x0500, 0x1e3f, 0x0fff },
  { 0x8900, 0x1e42, 0x2001 },
  { 0x0500, 0x1e41, 0x0fff },
  { 0x0500, 0x1e43, 0x0fff },
  { 0x8900, 0x1e54, 0x5001 },
  { 0x8900, 0x1e4c, 0x4001 },
  { 0x8900, 0x1e48, 0x3001 },
  { 0x8900, 0x1e46, 0x2001 },
  { 0x0500, 0x1e45, 0x0fff },
  { 0x0500, 0x1e47, 0x0fff },
  { 0x8900, 0x1e4a, 0x2001 },
  { 0x0500, 0x1e49, 0x0fff },
  { 0x0500, 0x1e4b, 0x0fff },
  { 0x8900, 0x1e50, 0x3001 },
  { 0x8900, 0x1e4e, 0x2001 },
  { 0x0500, 0x1e4d, 0x0fff },
  { 0x0500, 0x1e4f, 0x0fff },
  { 0x8900, 0x1e52, 0x2001 },
  { 0x0500, 0x1e51, 0x0fff },
  { 0x0500, 0x1e53, 0x0fff },
  { 0x8900, 0x1e5c, 0x4001 },
  { 0x8900, 0x1e58, 0x3001 },
  { 0x8900, 0x1e56, 0x2001 },
  { 0x0500, 0x1e55, 0x0fff },
  { 0x0500, 0x1e57, 0x0fff },
  { 0x8900, 0x1e5a, 0x2001 },
  { 0x0500, 0x1e59, 0x0fff },
  { 0x0500, 0x1e5b, 0x0fff },
  { 0x8900, 0x1e60, 0x3001 },
  { 0x8900, 0x1e5e, 0x2001 },
  { 0x0500, 0x1e5d, 0x0fff },
  { 0x0500, 0x1e5f, 0x0fff },
  { 0x8900, 0x1e62, 0x2001 },
  { 0x0500, 0x1e61, 0x0fff },
  { 0x0500, 0x1e63, 0x0fff },
  { 0x8900, 0x1e84, 0x6001 },
  { 0x8900, 0x1e74, 0x5001 },
  { 0x8900, 0x1e6c, 0x4001 },
  { 0x8900, 0x1e68, 0x3001 },
  { 0x8900, 0x1e66, 0x2001 },
  { 0x0500, 0x1e65, 0x0fff },
  { 0x0500, 0x1e67, 0x0fff },
  { 0x8900, 0x1e6a, 0x2001 },
  { 0x0500, 0x1e69, 0x0fff },
  { 0x0500, 0x1e6b, 0x0fff },
  { 0x8900, 0x1e70, 0x3001 },
  { 0x8900, 0x1e6e, 0x2001 },
  { 0x0500, 0x1e6d, 0x0fff },
  { 0x0500, 0x1e6f, 0x0fff },
  { 0x8900, 0x1e72, 0x2001 },
  { 0x0500, 0x1e71, 0x0fff },
  { 0x0500, 0x1e73, 0x0fff },
  { 0x8900, 0x1e7c, 0x4001 },
  { 0x8900, 0x1e78, 0x3001 },
  { 0x8900, 0x1e76, 0x2001 },
  { 0x0500, 0x1e75, 0x0fff },
  { 0x0500, 0x1e77, 0x0fff },
  { 0x8900, 0x1e7a, 0x2001 },
  { 0x0500, 0x1e79, 0x0fff },
  { 0x0500, 0x1e7b, 0x0fff },
  { 0x8900, 0x1e80, 0x3001 },
  { 0x8900, 0x1e7e, 0x2001 },
  { 0x0500, 0x1e7d, 0x0fff },
  { 0x0500, 0x1e7f, 0x0fff },
  { 0x8900, 0x1e82, 0x2001 },
  { 0x0500, 0x1e81, 0x0fff },
  { 0x0500, 0x1e83, 0x0fff },
  { 0x8900, 0x1e94, 0x5001 },
  { 0x8900, 0x1e8c, 0x4001 },
  { 0x8900, 0x1e88, 0x3001 },
  { 0x8900, 0x1e86, 0x2001 },
  { 0x0500, 0x1e85, 0x0fff },
  { 0x0500, 0x1e87, 0x0fff },
  { 0x8900, 0x1e8a, 0x2001 },
  { 0x0500, 0x1e89, 0x0fff },
  { 0x0500, 0x1e8b, 0x0fff },
  { 0x8900, 0x1e90, 0x3001 },
  { 0x8900, 0x1e8e, 0x2001 },
  { 0x0500, 0x1e8d, 0x0fff },
  { 0x0500, 0x1e8f, 0x0fff },
  { 0x8900, 0x1e92, 0x2001 },
  { 0x0500, 0x1e91, 0x0fff },
  { 0x0500, 0x1e93, 0x0fff },
  { 0x8900, 0x1ea0, 0x4001 },
  { 0x8500, 0x1e98, 0x3000 },
  { 0x8500, 0x1e96, 0x2000 },
  { 0x0500, 0x1e95, 0x0fff },
  { 0x0500, 0x1e97, 0x0000 },
  { 0x8500, 0x1e9a, 0x2000 },
  { 0x0500, 0x1e99, 0x0000 },
  { 0x0500, 0x1e9b, 0x0fc5 },
  { 0x8900, 0x1ea4, 0x3001 },
  { 0x8900, 0x1ea2, 0x2001 },
  { 0x0500, 0x1ea1, 0x0fff },
  { 0x0500, 0x1ea3, 0x0fff },
  { 0x8900, 0x1ea6, 0x2001 },
  { 0x0500, 0x1ea5, 0x0fff },
  { 0x0500, 0x1ea7, 0x0fff },
  { 0x8900, 0x1ee8, 0x7001 },
  { 0x8900, 0x1ec8, 0x6001 },
  { 0x8900, 0x1eb8, 0x5001 },
  { 0x8900, 0x1eb0, 0x4001 },
  { 0x8900, 0x1eac, 0x3001 },
  { 0x8900, 0x1eaa, 0x2001 },
  { 0x0500, 0x1ea9, 0x0fff },
  { 0x0500, 0x1eab, 0x0fff },
  { 0x8900, 0x1eae, 0x2001 },
  { 0x0500, 0x1ead, 0x0fff },
  { 0x0500, 0x1eaf, 0x0fff },
  { 0x8900, 0x1eb4, 0x3001 },
  { 0x8900, 0x1eb2, 0x2001 },
  { 0x0500, 0x1eb1, 0x0fff },
  { 0x0500, 0x1eb3, 0x0fff },
  { 0x8900, 0x1eb6, 0x2001 },
  { 0x0500, 0x1eb5, 0x0fff },
  { 0x0500, 0x1eb7, 0x0fff },
  { 0x8900, 0x1ec0, 0x4001 },
  { 0x8900, 0x1ebc, 0x3001 },
  { 0x8900, 0x1eba, 0x2001 },
  { 0x0500, 0x1eb9, 0x0fff },
  { 0x0500, 0x1ebb, 0x0fff },
  { 0x8900, 0x1ebe, 0x2001 },
  { 0x0500, 0x1ebd, 0x0fff },
  { 0x0500, 0x1ebf, 0x0fff },
  { 0x8900, 0x1ec4, 0x3001 },
  { 0x8900, 0x1ec2, 0x2001 },
  { 0x0500, 0x1ec1, 0x0fff },
  { 0x0500, 0x1ec3, 0x0fff },
  { 0x8900, 0x1ec6, 0x2001 },
  { 0x0500, 0x1ec5, 0x0fff },
  { 0x0500, 0x1ec7, 0x0fff },
  { 0x8900, 0x1ed8, 0x5001 },
  { 0x8900, 0x1ed0, 0x4001 },
  { 0x8900, 0x1ecc, 0x3001 },
  { 0x8900, 0x1eca, 0x2001 },
  { 0x0500, 0x1ec9, 0x0fff },
  { 0x0500, 0x1ecb, 0x0fff },
  { 0x8900, 0x1ece, 0x2001 },
  { 0x0500, 0x1ecd, 0x0fff },
  { 0x0500, 0x1ecf, 0x0fff },
  { 0x8900, 0x1ed4, 0x3001 },
  { 0x8900, 0x1ed2, 0x2001 },
  { 0x0500, 0x1ed1, 0x0fff },
  { 0x0500, 0x1ed3, 0x0fff },
  { 0x8900, 0x1ed6, 0x2001 },
  { 0x0500, 0x1ed5, 0x0fff },
  { 0x0500, 0x1ed7, 0x0fff },
  { 0x8900, 0x1ee0, 0x4001 },
  { 0x8900, 0x1edc, 0x3001 },
  { 0x8900, 0x1eda, 0x2001 },
  { 0x0500, 0x1ed9, 0x0fff },
  { 0x0500, 0x1edb, 0x0fff },
  { 0x8900, 0x1ede, 0x2001 },
  { 0x0500, 0x1edd, 0x0fff },
  { 0x0500, 0x1edf, 0x0fff },
  { 0x8900, 0x1ee4, 0x3001 },
  { 0x8900, 0x1ee2, 0x2001 },
  { 0x0500, 0x1ee1, 0x0fff },
  { 0x0500, 0x1ee3, 0x0fff },
  { 0x8900, 0x1ee6, 0x2001 },
  { 0x0500, 0x1ee5, 0x0fff },
  { 0x0500, 0x1ee7, 0x0fff },
  { 0x8900, 0x1f0e, 0x6ff8 },
  { 0x8900, 0x1ef8, 0x5001 },
  { 0x8900, 0x1ef0, 0x4001 },
  { 0x8900, 0x1eec, 0x3001 },
  { 0x8900, 0x1eea, 0x2001 },
  { 0x0500, 0x1ee9, 0x0fff },
  { 0x0500, 0x1eeb, 0x0fff },
  { 0x8900, 0x1eee, 0x2001 },
  { 0x0500, 0x1eed, 0x0fff },
  { 0x0500, 0x1eef, 0x0fff },
  { 0x8900, 0x1ef4, 0x3001 },
  { 0x8900, 0x1ef2, 0x2001 },
  { 0x0500, 0x1ef1, 0x0fff },
  { 0x0500, 0x1ef3, 0x0fff },
  { 0x8900, 0x1ef6, 0x2001 },
  { 0x0500, 0x1ef5, 0x0fff },
  { 0x0500, 0x1ef7, 0x0fff },
  { 0x8500, 0x1f06, 0x4008 },
  { 0x8500, 0x1f02, 0x3008 },
  { 0x8500, 0x1f00, 0x2008 },
  { 0x0500, 0x1ef9, 0x0fff },
  { 0x0500, 0x1f01, 0x0008 },
  { 0x8500, 0x1f04, 0x2008 },
  { 0x0500, 0x1f03, 0x0008 },
  { 0x0500, 0x1f05, 0x0008 },
  { 0x8900, 0x1f0a, 0x3ff8 },
  { 0x8900, 0x1f08, 0x2ff8 },
  { 0x0500, 0x1f07, 0x0008 },
  { 0x0900, 0x1f09, 0x0ff8 },
  { 0x8900, 0x1f0c, 0x2ff8 },
  { 0x0900, 0x1f0b, 0x0ff8 },
  { 0x0900, 0x1f0d, 0x0ff8 },
  { 0x8500, 0x1f22, 0x5008 },
  { 0x8900, 0x1f18, 0x4ff8 },
  { 0x8500, 0x1f12, 0x3008 },
  { 0x8500, 0x1f10, 0x2008 },
  { 0x0900, 0x1f0f, 0x0ff8 },
  { 0x0500, 0x1f11, 0x0008 },
  { 0x8500, 0x1f14, 0x2008 },
  { 0x0500, 0x1f13, 0x0008 },
  { 0x0500, 0x1f15, 0x0008 },
  { 0x8900, 0x1f1c, 0x3ff8 },
  { 0x8900, 0x1f1a, 0x2ff8 },
  { 0x0900, 0x1f19, 0x0ff8 },
  { 0x0900, 0x1f1b, 0x0ff8 },
  { 0x8500, 0x1f20, 0x2008 },
  { 0x0900, 0x1f1d, 0x0ff8 },
  { 0x0500, 0x1f21, 0x0008 },
  { 0x8900, 0x1f2a, 0x4ff8 },
  { 0x8500, 0x1f26, 0x3008 },
  { 0x8500, 0x1f24, 0x2008 },
  { 0x0500, 0x1f23, 0x0008 },
  { 0x0500, 0x1f25, 0x0008 },
  { 0x8900, 0x1f28, 0x2ff8 },
  { 0x0500, 0x1f27, 0x0008 },
  { 0x0900, 0x1f29, 0x0ff8 },
  { 0x8900, 0x1f2e, 0x3ff8 },
  { 0x8900, 0x1f2c, 0x2ff8 },
  { 0x0900, 0x1f2b, 0x0ff8 },
  { 0x0900, 0x1f2d, 0x0ff8 },
  { 0x8500, 0x1f30, 0x2008 },
  { 0x0900, 0x1f2f, 0x0ff8 },
  { 0x0500, 0x1f31, 0x0008 },
  { 0x9800, 0x1fbd, 0x8000 },
  { 0x8500, 0x1f7a, 0x7070 },
  { 0x8500, 0x1f56, 0x6000 },
  { 0x8500, 0x1f42, 0x5008 },
  { 0x8900, 0x1f3a, 0x4ff8 },
  { 0x8500, 0x1f36, 0x3008 },
  { 0x8500, 0x1f34, 0x2008 },
  { 0x0500, 0x1f33, 0x0008 },
  { 0x0500, 0x1f35, 0x0008 },
  { 0x8900, 0x1f38, 0x2ff8 },
  { 0x0500, 0x1f37, 0x0008 },
  { 0x0900, 0x1f39, 0x0ff8 },
  { 0x8900, 0x1f3e, 0x3ff8 },
  { 0x8900, 0x1f3c, 0x2ff8 },
  { 0x0900, 0x1f3b, 0x0ff8 },
  { 0x0900, 0x1f3d, 0x0ff8 },
  { 0x8500, 0x1f40, 0x2008 },
  { 0x0900, 0x1f3f, 0x0ff8 },
  { 0x0500, 0x1f41, 0x0008 },
  { 0x8900, 0x1f4c, 0x4ff8 },
  { 0x8900, 0x1f48, 0x3ff8 },
  { 0x8500, 0x1f44, 0x2008 },
  { 0x0500, 0x1f43, 0x0008 },
  { 0x0500, 0x1f45, 0x0008 },
  { 0x8900, 0x1f4a, 0x2ff8 },
  { 0x0900, 0x1f49, 0x0ff8 },
  { 0x0900, 0x1f4b, 0x0ff8 },
  { 0x8500, 0x1f52, 0x3000 },
  { 0x8500, 0x1f50, 0x2000 },
  { 0x0900, 0x1f4d, 0x0ff8 },
  { 0x0500, 0x1f51, 0x0008 },
  { 0x8500, 0x1f54, 0x2000 },
  { 0x0500, 0x1f53, 0x0008 },
  { 0x0500, 0x1f55, 0x0008 },
  { 0x8900, 0x1f6a, 0x5ff8 },
  { 0x8500, 0x1f62, 0x4008 },
  { 0x8900, 0x1f5d, 0x3ff8 },
  { 0x8900, 0x1f59, 0x2ff8 },
  { 0x0500, 0x1f57, 0x0008 },
  { 0x0900, 0x1f5b, 0x0ff8 },
  { 0x8500, 0x1f60, 0x2008 },
  { 0x0900, 0x1f5f, 0x0ff8 },
  { 0x0500, 0x1f61, 0x0008 },
  { 0x8500, 0x1f66, 0x3008 },
  { 0x8500, 0x1f64, 0x2008 },
  { 0x0500, 0x1f63, 0x0008 },
  { 0x0500, 0x1f65, 0x0008 },
  { 0x8900, 0x1f68, 0x2ff8 },
  { 0x0500, 0x1f67, 0x0008 },
  { 0x0900, 0x1f69, 0x0ff8 },
  { 0x8500, 0x1f72, 0x4056 },
  { 0x8900, 0x1f6e, 0x3ff8 },
  { 0x8900, 0x1f6c, 0x2ff8 },
  { 0x0900, 0x1f6b, 0x0ff8 },
  { 0x0900, 0x1f6d, 0x0ff8 },
  { 0x8500, 0x1f70, 0x204a },
  { 0x0900, 0x1f6f, 0x0ff8 },
  { 0x0500, 0x1f71, 0x004a },
  { 0x8500, 0x1f76, 0x3064 },
  { 0x8500, 0x1f74, 0x2056 },
  { 0x0500, 0x1f73, 0x0056 },
  { 0x0500, 0x1f75, 0x0056 },
  { 0x8500, 0x1f78, 0x2080 },
  { 0x0500, 0x1f77, 0x0064 },
  { 0x0500, 0x1f79, 0x0080 },
  { 0x8800, 0x1f9c, 0x6000 },
  { 0x8800, 0x1f8c, 0x5000 },
  { 0x8500, 0x1f84, 0x4008 },
  { 0x8500, 0x1f80, 0x3008 },
  { 0x8500, 0x1f7c, 0x207e },
  { 0x0500, 0x1f7b, 0x0070 },
  { 0x0500, 0x1f7d, 0x007e },
  { 0x8500, 0x1f82, 0x2008 },
  { 0x0500, 0x1f81, 0x0008 },
  { 0x0500, 0x1f83, 0x0008 },
  { 0x8800, 0x1f88, 0x3000 },
  { 0x8500, 0x1f86, 0x2008 },
  { 0x0500, 0x1f85, 0x0008 },
  { 0x0500, 0x1f87, 0x0008 },
  { 0x8800, 0x1f8a, 0x2000 },
  { 0x0800, 0x1f89, 0x0000 },
  { 0x0800, 0x1f8b, 0x0000 },
  { 0x8500, 0x1f94, 0x4008 },
  { 0x8500, 0x1f90, 0x3008 },
  { 0x8800, 0x1f8e, 0x2000 },
  { 0x0800, 0x1f8d, 0x0000 },
  { 0x0800, 0x1f8f, 0x0000 },
  { 0x8500, 0x1f92, 0x2008 },
  { 0x0500, 0x1f91, 0x0008 },
  { 0x0500, 0x1f93, 0x0008 },
  { 0x8800, 0x1f98, 0x3000 },
  { 0x8500, 0x1f96, 0x2008 },
  { 0x0500, 0x1f95, 0x0008 },
  { 0x0500, 0x1f97, 0x0008 },
  { 0x8800, 0x1f9a, 0x2000 },
  { 0x0800, 0x1f99, 0x0000 },
  { 0x0800, 0x1f9b, 0x0000 },
  { 0x8800, 0x1fac, 0x5000 },
  { 0x8500, 0x1fa4, 0x4008 },
  { 0x8500, 0x1fa0, 0x3008 },
  { 0x8800, 0x1f9e, 0x2000 },
  { 0x0800, 0x1f9d, 0x0000 },
  { 0x0800, 0x1f9f, 0x0000 },
  { 0x8500, 0x1fa2, 0x2008 },
  { 0x0500, 0x1fa1, 0x0008 },
  { 0x0500, 0x1fa3, 0x0008 },
  { 0x8800, 0x1fa8, 0x3000 },
  { 0x8500, 0x1fa6, 0x2008 },
  { 0x0500, 0x1fa5, 0x0008 },
  { 0x0500, 0x1fa7, 0x0008 },
  { 0x8800, 0x1faa, 0x2000 },
  { 0x0800, 0x1fa9, 0x0000 },
  { 0x0800, 0x1fab, 0x0000 },
  { 0x8500, 0x1fb4, 0x4000 },
  { 0x8500, 0x1fb0, 0x3008 },
  { 0x8800, 0x1fae, 0x2000 },
  { 0x0800, 0x1fad, 0x0000 },
  { 0x0800, 0x1faf, 0x0000 },
  { 0x8500, 0x1fb2, 0x2000 },
  { 0x0500, 0x1fb1, 0x0008 },
  { 0x0500, 0x1fb3, 0x0009 },
  { 0x8900, 0x1fb9, 0x3ff8 },
  { 0x8500, 0x1fb7, 0x2000 },
  { 0x0500, 0x1fb6, 0x0000 },
  { 0x0900, 0x1fb8, 0x0ff8 },
  { 0x8900, 0x1fbb, 0x2fb6 },
  { 0x0900, 0x1fba, 0x0fb6 },
  { 0x0800, 0x1fbc, 0x0000 },
  { 0x9d00, 0x2005, 0x7000 },
  { 0x8500, 0x1fe1, 0x6008 },
  { 0x9800, 0x1fce, 0x5000 },
  { 0x8500, 0x1fc6, 0x4000 },
  { 0x9800, 0x1fc1, 0x3000 },
  { 0x9800, 0x1fbf, 0x2000 },
  { 0x0500, 0x1fbe, 0x0000 },
  { 0x1800, 0x1fc0, 0x0000 },
  { 0x8500, 0x1fc3, 0x2009 },
  { 0x0500, 0x1fc2, 0x0000 },
  { 0x0500, 0x1fc4, 0x0000 },
  { 0x8900, 0x1fca, 0x3faa },
  { 0x8900, 0x1fc8, 0x2faa },
  { 0x0500, 0x1fc7, 0x0000 },
  { 0x0900, 0x1fc9, 0x0faa },
  { 0x8800, 0x1fcc, 0x2000 },
  { 0x0900, 0x1fcb, 0x0faa },
  { 0x1800, 0x1fcd, 0x0000 },
  { 0x8900, 0x1fd8, 0x4ff8 },
  { 0x8500, 0x1fd2, 0x3000 },
  { 0x8500, 0x1fd0, 0x2008 },
  { 0x1800, 0x1fcf, 0x0000 },
  { 0x0500, 0x1fd1, 0x0008 },
  { 0x8500, 0x1fd6, 0x2000 },
  { 0x0500, 0x1fd3, 0x0000 },
  { 0x0500, 0x1fd7, 0x0000 },
  { 0x9800, 0x1fdd, 0x3000 },
  { 0x8900, 0x1fda, 0x2f9c },
  { 0x0900, 0x1fd9, 0x0ff8 },
  { 0x0900, 0x1fdb, 0x0f9c },
  { 0x9800, 0x1fdf, 0x2000 },
  { 0x1800, 0x1fde, 0x0000 },
  { 0x0500, 0x1fe0, 0x0008 },
  { 0x8500, 0x1ff3, 0x5009 },
  { 0x8900, 0x1fe9, 0x4ff8 },
  { 0x8500, 0x1fe5, 0x3007 },
  { 0x8500, 0x1fe3, 0x2000 },
  { 0x0500, 0x1fe2, 0x0000 },
  { 0x0500, 0x1fe4, 0x0000 },
  { 0x8500, 0x1fe7, 0x2000 },
  { 0x0500, 0x1fe6, 0x0000 },
  { 0x0900, 0x1fe8, 0x0ff8 },
  { 0x9800, 0x1fed, 0x3000 },
  { 0x8900, 0x1feb, 0x2f90 },
  { 0x0900, 0x1fea, 0x0f90 },
  { 0x0900, 0x1fec, 0x0ff9 },
  { 0x9800, 0x1fef, 0x2000 },
  { 0x1800, 0x1fee, 0x0000 },
  { 0x0500, 0x1ff2, 0x0000 },
  { 0x8800, 0x1ffc, 0x4000 },
  { 0x8900, 0x1ff8, 0x3f80 },
  { 0x8500, 0x1ff6, 0x2000 },
  { 0x0500, 0x1ff4, 0x0000 },
  { 0x0500, 0x1ff7, 0x0000 },
  { 0x8900, 0x1ffa, 0x2f82 },
  { 0x0900, 0x1ff9, 0x0f80 },
  { 0x0900, 0x1ffb, 0x0f82 },
  { 0x9d00, 0x2001, 0x3000 },
  { 0x9800, 0x1ffe, 0x2000 },
  { 0x1800, 0x1ffd, 0x0000 },
  { 0x1d00, 0x2000, 0x0000 },
  { 0x9d00, 0x2003, 0x2000 },
  { 0x1d00, 0x2002, 0x0000 },
  { 0x1d00, 0x2004, 0x0000 },
  { 0x9500, 0x2025, 0x6000 },
  { 0x9100, 0x2015, 0x5000 },
  { 0x8100, 0x200d, 0x4000 },
  { 0x9d00, 0x2009, 0x3000 },
  { 0x9d00, 0x2007, 0x2000 },
  { 0x1d00, 0x2006, 0x0000 },
  { 0x1d00, 0x2008, 0x0000 },
  { 0x9d00, 0x200b, 0x2000 },
  { 0x1d00, 0x200a, 0x0000 },
  { 0x0100, 0x200c, 0x0000 },
  { 0x9100, 0x2011, 0x3000 },
  { 0x8100, 0x200f, 0x2000 },
  { 0x0100, 0x200e, 0x0000 },
  { 0x1100, 0x2010, 0x0000 },
  { 0x9100, 0x2013, 0x2000 },
  { 0x1100, 0x2012, 0x0000 },
  { 0x1100, 0x2014, 0x0000 },
  { 0x9300, 0x201d, 0x4000 },
  { 0x9300, 0x2019, 0x3000 },
  { 0x9500, 0x2017, 0x2000 },
  { 0x1500, 0x2016, 0x0000 },
  { 0x1400, 0x2018, 0x0000 },
  { 0x9400, 0x201b, 0x2000 },
  { 0x1600, 0x201a, 0x0000 },
  { 0x1400, 0x201c, 0x0000 },
  { 0x9500, 0x2021, 0x3000 },
  { 0x9400, 0x201f, 0x2000 },
  { 0x1600, 0x201e, 0x0000 },
  { 0x1500, 0x2020, 0x0000 },
  { 0x9500, 0x2023, 0x2000 },
  { 0x1500, 0x2022, 0x0000 },
  { 0x1500, 0x2024, 0x0000 },
  { 0x9500, 0x2035, 0x5000 },
  { 0x8100, 0x202d, 0x4000 },
  { 0x9c00, 0x2029, 0x3000 },
  { 0x9500, 0x2027, 0x2000 },
  { 0x1500, 0x2026, 0x0000 },
  { 0x1b00, 0x2028, 0x0000 },
  { 0x8100, 0x202b, 0x2000 },
  { 0x0100, 0x202a, 0x0000 },
  { 0x0100, 0x202c, 0x0000 },
  { 0x9500, 0x2031, 0x3000 },
  { 0x9d00, 0x202f, 0x2000 },
  { 0x0100, 0x202e, 0x0000 },
  { 0x1500, 0x2030, 0x0000 },
  { 0x9500, 0x2033, 0x2000 },
  { 0x1500, 0x2032, 0x0000 },
  { 0x1500, 0x2034, 0x0000 },
  { 0x9500, 0x203d, 0x4000 },
  { 0x9400, 0x2039, 0x3000 },
  { 0x9500, 0x2037, 0x2000 },
  { 0x1500, 0x2036, 0x0000 },
  { 0x1500, 0x2038, 0x0000 },
  { 0x9500, 0x203b, 0x2000 },
  { 0x1300, 0x203a, 0x0000 },
  { 0x1500, 0x203c, 0x0000 },
  { 0x9500, 0x2041, 0x3000 },
  { 0x9000, 0x203f, 0x2000 },
  { 0x1500, 0x203e, 0x0000 },
  { 0x1000, 0x2040, 0x0000 },
  { 0x9500, 0x2043, 0x2000 },
  { 0x1500, 0x2042, 0x0000 },
  { 0x1900, 0x2044, 0x0000 },
  { 0x9900, 0x21ae, 0x9000 },
  { 0x8900, 0x211a, 0x8000 },
  { 0x9700, 0x20a7, 0x7000 },
  { 0x8f00, 0x2076, 0x6000 },
  { 0x9500, 0x2057, 0x5000 },
  { 0x9500, 0x204d, 0x4000 },
  { 0x9500, 0x2049, 0x3000 },
  { 0x9500, 0x2047, 0x2000 },
  { 0x1200, 0x2046, 0x0000 },
  { 0x1500, 0x2048, 0x0000 },
  { 0x9500, 0x204b, 0x2000 },
  { 0x1500, 0x204a, 0x0000 },
  { 0x1500, 0x204c, 0x0000 },
  { 0x9500, 0x2051, 0x3000 },
  { 0x9500, 0x204f, 0x2000 },
  { 0x1500, 0x204e, 0x0000 },
  { 0x1500, 0x2050, 0x0000 },
  { 0x9500, 0x2053, 0x2000 },
  { 0x1900, 0x2052, 0x0000 },
  { 0x1000, 0x2054, 0x0000 },
  { 0x8100, 0x206c, 0x4000 },
  { 0x8100, 0x2062, 0x3000 },
  { 0x8100, 0x2060, 0x2000 },
  { 0x1d00, 0x205f, 0x0000 },
  { 0x0100, 0x2061, 0x0000 },
  { 0x8100, 0x206a, 0x2000 },
  { 0x0100, 0x2063, 0x0000 },
  { 0x0100, 0x206b, 0x0000 },
  { 0x8f00, 0x2070, 0x3000 },
  { 0x8100, 0x206e, 0x2000 },
  { 0x0100, 0x206d, 0x0000 },
  { 0x0100, 0x206f, 0x0000 },
  { 0x8f00, 0x2074, 0x2000 },
  { 0x0500, 0x2071, 0x0000 },
  { 0x0f00, 0x2075, 0x0000 },
  { 0x8f00, 0x2086, 0x5000 },
  { 0x9200, 0x207e, 0x4000 },
  { 0x9900, 0x207a, 0x3000 },
  { 0x8f00, 0x2078, 0x2000 },
  { 0x0f00, 0x2077, 0x0000 },
  { 0x0f00, 0x2079, 0x0000 },
  { 0x9900, 0x207c, 0x2000 },
  { 0x1900, 0x207b, 0x0000 },
  { 0x1600, 0x207d, 0x0000 },
  { 0x8f00, 0x2082, 0x3000 },
  { 0x8f00, 0x2080, 0x2000 },
  { 0x0500, 0x207f, 0x0000 },
  { 0x0f00, 0x2081, 0x0000 },
  { 0x8f00, 0x2084, 0x2000 },
  { 0x0f00, 0x2083, 0x0000 },
  { 0x0f00, 0x2085, 0x0000 },
  { 0x9200, 0x208e, 0x4000 },
  { 0x9900, 0x208a, 0x3000 },
  { 0x8f00, 0x2088, 0x2000 },
  { 0x0f00, 0x2087, 0x0000 },
  { 0x0f00, 0x2089, 0x0000 },
  { 0x9900, 0x208c, 0x2000 },
  { 0x1900, 0x208b, 0x0000 },
  { 0x1600, 0x208d, 0x0000 },
  { 0x9700, 0x20a3, 0x3000 },
  { 0x9700, 0x20a1, 0x2000 },
  { 0x1700, 0x20a0, 0x0000 },
  { 0x1700, 0x20a2, 0x0000 },
  { 0x9700, 0x20a5, 0x2000 },
  { 0x1700, 0x20a4, 0x0000 },
  { 0x1700, 0x20a6, 0x0000 },
  { 0x8c00, 0x20e5, 0x6000 },
  { 0x8c00, 0x20d5, 0x5000 },
  { 0x9700, 0x20af, 0x4000 },
  { 0x9700, 0x20ab, 0x3000 },
  { 0x9700, 0x20a9, 0x2000 },
  { 0x1700, 0x20a8, 0x0000 },
  { 0x1700, 0x20aa, 0x0000 },
  { 0x9700, 0x20ad, 0x2000 },
  { 0x1700, 0x20ac, 0x0000 },
  { 0x1700, 0x20ae, 0x0000 },
  { 0x8c00, 0x20d1, 0x3000 },
  { 0x9700, 0x20b1, 0x2000 },
  { 0x1700, 0x20b0, 0x0000 },
  { 0x0c00, 0x20d0, 0x0000 },
  { 0x8c00, 0x20d3, 0x2000 },
  { 0x0c00, 0x20d2, 0x0000 },
  { 0x0c00, 0x20d4, 0x0000 },
  { 0x8b00, 0x20dd, 0x4000 },
  { 0x8c00, 0x20d9, 0x3000 },
  { 0x8c00, 0x20d7, 0x2000 },
  { 0x0c00, 0x20d6, 0x0000 },
  { 0x0c00, 0x20d8, 0x0000 },
  { 0x8c00, 0x20db, 0x2000 },
  { 0x0c00, 0x20da, 0x0000 },
  { 0x0c00, 0x20dc, 0x0000 },
  { 0x8c00, 0x20e1, 0x3000 },
  { 0x8b00, 0x20df, 0x2000 },
  { 0x0b00, 0x20de, 0x0000 },
  { 0x0b00, 0x20e0, 0x0000 },
  { 0x8b00, 0x20e3, 0x2000 },
  { 0x0b00, 0x20e2, 0x0000 },
  { 0x0b00, 0x20e4, 0x0000 },
  { 0x8500, 0x210a, 0x5000 },
  { 0x8900, 0x2102, 0x4000 },
  { 0x8c00, 0x20e9, 0x3000 },
  { 0x8c00, 0x20e7, 0x2000 },
  { 0x0c00, 0x20e6, 0x0000 },
  { 0x0c00, 0x20e8, 0x0000 },
  { 0x9a00, 0x2100, 0x2000 },
  { 0x0c00, 0x20ea, 0x0000 },
  { 0x1a00, 0x2101, 0x0000 },
  { 0x9a00, 0x2106, 0x3000 },
  { 0x9a00, 0x2104, 0x2000 },
  { 0x1a00, 0x2103, 0x0000 },
  { 0x1a00, 0x2105, 0x0000 },
  { 0x9a00, 0x2108, 0x2000 },
  { 0x0900, 0x2107, 0x0000 },
  { 0x1a00, 0x2109, 0x0000 },
  { 0x8900, 0x2112, 0x4000 },
  { 0x8500, 0x210e, 0x3000 },
  { 0x8900, 0x210c, 0x2000 },
  { 0x0900, 0x210b, 0x0000 },
  { 0x0900, 0x210d, 0x0000 },
  { 0x8900, 0x2110, 0x2000 },
  { 0x0500, 0x210f, 0x0000 },
  { 0x0900, 0x2111, 0x0000 },
  { 0x9a00, 0x2116, 0x3000 },
  { 0x9a00, 0x2114, 0x2000 },
  { 0x0500, 0x2113, 0x0000 },
  { 0x0900, 0x2115, 0x0000 },
  { 0x9a00, 0x2118, 0x2000 },
  { 0x1a00, 0x2117, 0x0000 },
  { 0x0900, 0x2119, 0x0000 },
  { 0x8e00, 0x2162, 0x7000 },
  { 0x9a00, 0x213a, 0x6000 },
  { 0x8900, 0x212a, 0x5000 },
  { 0x9a00, 0x2122, 0x4000 },
  { 0x9a00, 0x211e, 0x3000 },
  { 0x8900, 0x211c, 0x2000 },
  { 0x0900, 0x211b, 0x0000 },
  { 0x0900, 0x211d, 0x0000 },
  { 0x9a00, 0x2120, 0x2000 },
  { 0x1a00, 0x211f, 0x0000 },
  { 0x1a00, 0x2121, 0x0000 },
  { 0x8900, 0x2126, 0x3000 },
  { 0x8900, 0x2124, 0x2000 },
  { 0x1a00, 0x2123, 0x0000 },
  { 0x1a00, 0x2125, 0x0000 },
  { 0x8900, 0x2128, 0x2000 },
  { 0x1a00, 0x2127, 0x0000 },
  { 0x1a00, 0x2129, 0x0000 },
  { 0x9a00, 0x2132, 0x4000 },
  { 0x9a00, 0x212e, 0x3000 },
  { 0x8900, 0x212c, 0x2000 },
  { 0x0900, 0x212b, 0x0000 },
  { 0x0900, 0x212d, 0x0000 },
  { 0x8900, 0x2130, 0x2000 },
  { 0x0500, 0x212f, 0x0000 },
  { 0x0900, 0x2131, 0x0000 },
  { 0x8700, 0x2136, 0x3000 },
  { 0x8500, 0x2134, 0x2000 },
  { 0x0900, 0x2133, 0x0000 },
  { 0x0700, 0x2135, 0x0000 },
  { 0x8700, 0x2138, 0x2000 },
  { 0x0700, 0x2137, 0x0000 },
  { 0x0500, 0x2139, 0x0000 },
  { 0x9900, 0x214b, 0x5000 },
  { 0x9900, 0x2143, 0x4000 },
  { 0x8900, 0x213f, 0x3000 },
  { 0x8500, 0x213d, 0x2000 },
  { 0x1a00, 0x213b, 0x0000 },
  { 0x0900, 0x213e, 0x0000 },
  { 0x9900, 0x2141, 0x2000 },
  { 0x1900, 0x2140, 0x0000 },
  { 0x1900, 0x2142, 0x0000 },
  { 0x8500, 0x2147, 0x3000 },
  { 0x8900, 0x2145, 0x2000 },
  { 0x1900, 0x2144, 0x0000 },
  { 0x0500, 0x2146, 0x0000 },
  { 0x8500, 0x2149, 0x2000 },
  { 0x0500, 0x2148, 0x0000 },
  { 0x1a00, 0x214a, 0x0000 },
  { 0x8f00, 0x215a, 0x4000 },
  { 0x8f00, 0x2156, 0x3000 },
  { 0x8f00, 0x2154, 0x2000 },
  { 0x0f00, 0x2153, 0x0000 },
  { 0x0f00, 0x2155, 0x0000 },
  { 0x8f00, 0x2158, 0x2000 },
  { 0x0f00, 0x2157, 0x0000 },
  { 0x0f00, 0x2159, 0x0000 },
  { 0x8f00, 0x215e, 0x3000 },
  { 0x8f00, 0x215c, 0x2000 },
  { 0x0f00, 0x215b, 0x0000 },
  { 0x0f00, 0x215d, 0x0000 },
  { 0x8e00, 0x2160, 0x2000 },
  { 0x0f00, 0x215f, 0x0000 },
  { 0x0e00, 0x2161, 0x0000 },
  { 0x8e00, 0x2182, 0x6000 },
  { 0x8e00, 0x2172, 0x5000 },
  { 0x8e00, 0x216a, 0x4000 },
  { 0x8e00, 0x2166, 0x3000 },
  { 0x8e00, 0x2164, 0x2000 },
  { 0x0e00, 0x2163, 0x0000 },
  { 0x0e00, 0x2165, 0x0000 },
  { 0x8e00, 0x2168, 0x2000 },
  { 0x0e00, 0x2167, 0x0000 },
  { 0x0e00, 0x2169, 0x0000 },
  { 0x8e00, 0x216e, 0x3000 },
  { 0x8e00, 0x216c, 0x2000 },
  { 0x0e00, 0x216b, 0x0000 },
  { 0x0e00, 0x216d, 0x0000 },
  { 0x8e00, 0x2170, 0x2000 },
  { 0x0e00, 0x216f, 0x0000 },
  { 0x0e00, 0x2171, 0x0000 },
  { 0x8e00, 0x217a, 0x4000 },
  { 0x8e00, 0x2176, 0x3000 },
  { 0x8e00, 0x2174, 0x2000 },
  { 0x0e00, 0x2173, 0x0000 },
  { 0x0e00, 0x2175, 0x0000 },
  { 0x8e00, 0x2178, 0x2000 },
  { 0x0e00, 0x2177, 0x0000 },
  { 0x0e00, 0x2179, 0x0000 },
  { 0x8e00, 0x217e, 0x3000 },
  { 0x8e00, 0x217c, 0x2000 },
  { 0x0e00, 0x217b, 0x0000 },
  { 0x0e00, 0x217d, 0x0000 },
  { 0x8e00, 0x2180, 0x2000 },
  { 0x0e00, 0x217f, 0x0000 },
  { 0x0e00, 0x2181, 0x0000 },
  { 0x9a00, 0x219e, 0x5000 },
  { 0x9a00, 0x2196, 0x4000 },
  { 0x9900, 0x2192, 0x3000 },
  { 0x9900, 0x2190, 0x2000 },
  { 0x0e00, 0x2183, 0x0000 },
  { 0x1900, 0x2191, 0x0000 },
  { 0x9900, 0x2194, 0x2000 },
  { 0x1900, 0x2193, 0x0000 },
  { 0x1a00, 0x2195, 0x0000 },
  { 0x9900, 0x219a, 0x3000 },
  { 0x9a00, 0x2198, 0x2000 },
  { 0x1a00, 0x2197, 0x0000 },
  { 0x1a00, 0x2199, 0x0000 },
  { 0x9a00, 0x219c, 0x2000 },
  { 0x1900, 0x219b, 0x0000 },
  { 0x1a00, 0x219d, 0x0000 },
  { 0x9900, 0x21a6, 0x4000 },
  { 0x9a00, 0x21a2, 0x3000 },
  { 0x9900, 0x21a0, 0x2000 },
  { 0x1a00, 0x219f, 0x0000 },
  { 0x1a00, 0x21a1, 0x0000 },
  { 0x9a00, 0x21a4, 0x2000 },
  { 0x1900, 0x21a3, 0x0000 },
  { 0x1a00, 0x21a5, 0x0000 },
  { 0x9a00, 0x21aa, 0x3000 },
  { 0x9a00, 0x21a8, 0x2000 },
  { 0x1a00, 0x21a7, 0x0000 },
  { 0x1a00, 0x21a9, 0x0000 },
  { 0x9a00, 0x21ac, 0x2000 },
  { 0x1a00, 0x21ab, 0x0000 },
  { 0x1a00, 0x21ad, 0x0000 },
  { 0x9900, 0x222e, 0x8000 },
  { 0x9a00, 0x21ee, 0x7000 },
  { 0x9900, 0x21ce, 0x6000 },
  { 0x9a00, 0x21be, 0x5000 },
  { 0x9a00, 0x21b6, 0x4000 },
  { 0x9a00, 0x21b2, 0x3000 },
  { 0x9a00, 0x21b0, 0x2000 },
  { 0x1a00, 0x21af, 0x0000 },
  { 0x1a00, 0x21b1, 0x0000 },
  { 0x9a00, 0x21b4, 0x2000 },
  { 0x1a00, 0x21b3, 0x0000 },
  { 0x1a00, 0x21b5, 0x0000 },
  { 0x9a00, 0x21ba, 0x3000 },
  { 0x9a00, 0x21b8, 0x2000 },
  { 0x1a00, 0x21b7, 0x0000 },
  { 0x1a00, 0x21b9, 0x0000 },
  { 0x9a00, 0x21bc, 0x2000 },
  { 0x1a00, 0x21bb, 0x0000 },
  { 0x1a00, 0x21bd, 0x0000 },
  { 0x9a00, 0x21c6, 0x4000 },
  { 0x9a00, 0x21c2, 0x3000 },
  { 0x9a00, 0x21c0, 0x2000 },
  { 0x1a00, 0x21bf, 0x0000 },
  { 0x1a00, 0x21c1, 0x0000 },
  { 0x9a00, 0x21c4, 0x2000 },
  { 0x1a00, 0x21c3, 0x0000 },
  { 0x1a00, 0x21c5, 0x0000 },
  { 0x9a00, 0x21ca, 0x3000 },
  { 0x9a00, 0x21c8, 0x2000 },
  { 0x1a00, 0x21c7, 0x0000 },
  { 0x1a00, 0x21c9, 0x0000 },
  { 0x9a00, 0x21cc, 0x2000 },
  { 0x1a00, 0x21cb, 0x0000 },
  { 0x1a00, 0x21cd, 0x0000 },
  { 0x9a00, 0x21de, 0x5000 },
  { 0x9a00, 0x21d6, 0x4000 },
  { 0x9900, 0x21d2, 0x3000 },
  { 0x9a00, 0x21d0, 0x2000 },
  { 0x1900, 0x21cf, 0x0000 },
  { 0x1a00, 0x21d1, 0x0000 },
  { 0x9900, 0x21d4, 0x2000 },
  { 0x1a00, 0x21d3, 0x0000 },
  { 0x1a00, 0x21d5, 0x0000 },
  { 0x9a00, 0x21da, 0x3000 },
  { 0x9a00, 0x21d8, 0x2000 },
  { 0x1a00, 0x21d7, 0x0000 },
  { 0x1a00, 0x21d9, 0x0000 },
  { 0x9a00, 0x21dc, 0x2000 },
  { 0x1a00, 0x21db, 0x0000 },
  { 0x1a00, 0x21dd, 0x0000 },
  { 0x9a00, 0x21e6, 0x4000 },
  { 0x9a00, 0x21e2, 0x3000 },
  { 0x9a00, 0x21e0, 0x2000 },
  { 0x1a00, 0x21df, 0x0000 },
  { 0x1a00, 0x21e1, 0x0000 },
  { 0x9a00, 0x21e4, 0x2000 },
  { 0x1a00, 0x21e3, 0x0000 },
  { 0x1a00, 0x21e5, 0x0000 },
  { 0x9a00, 0x21ea, 0x3000 },
  { 0x9a00, 0x21e8, 0x2000 },
  { 0x1a00, 0x21e7, 0x0000 },
  { 0x1a00, 0x21e9, 0x0000 },
  { 0x9a00, 0x21ec, 0x2000 },
  { 0x1a00, 0x21eb, 0x0000 },
  { 0x1a00, 0x21ed, 0x0000 },
  { 0x9900, 0x220e, 0x6000 },
  { 0x9900, 0x21fe, 0x5000 },
  { 0x9900, 0x21f6, 0x4000 },
  { 0x9a00, 0x21f2, 0x3000 },
  { 0x9a00, 0x21f0, 0x2000 },
  { 0x1a00, 0x21ef, 0x0000 },
  { 0x1a00, 0x21f1, 0x0000 },
  { 0x9900, 0x21f4, 0x2000 },
  { 0x1a00, 0x21f3, 0x0000 },
  { 0x1900, 0x21f5, 0x0000 },
  { 0x9900, 0x21fa, 0x3000 },
  { 0x9900, 0x21f8, 0x2000 },
  { 0x1900, 0x21f7, 0x0000 },
  { 0x1900, 0x21f9, 0x0000 },
  { 0x9900, 0x21fc, 0x2000 },
  { 0x1900, 0x21fb, 0x0000 },
  { 0x1900, 0x21fd, 0x0000 },
  { 0x9900, 0x2206, 0x4000 },
  { 0x9900, 0x2202, 0x3000 },
  { 0x9900, 0x2200, 0x2000 },
  { 0x1900, 0x21ff, 0x0000 },
  { 0x1900, 0x2201, 0x0000 },
  { 0x9900, 0x2204, 0x2000 },
  { 0x1900, 0x2203, 0x0000 },
  { 0x1900, 0x2205, 0x0000 },
  { 0x9900, 0x220a, 0x3000 },
  { 0x9900, 0x2208, 0x2000 },
  { 0x1900, 0x2207, 0x0000 },
  { 0x1900, 0x2209, 0x0000 },
  { 0x9900, 0x220c, 0x2000 },
  { 0x1900, 0x220b, 0x0000 },
  { 0x1900, 0x220d, 0x0000 },
  { 0x9900, 0x221e, 0x5000 },
  { 0x9900, 0x2216, 0x4000 },
  { 0x9900, 0x2212, 0x3000 },
  { 0x9900, 0x2210, 0x2000 },
  { 0x1900, 0x220f, 0x0000 },
  { 0x1900, 0x2211, 0x0000 },
  { 0x9900, 0x2214, 0x2000 },
  { 0x1900, 0x2213, 0x0000 },
  { 0x1900, 0x2215, 0x0000 },
  { 0x9900, 0x221a, 0x3000 },
  { 0x9900, 0x2218, 0x2000 },
  { 0x1900, 0x2217, 0x0000 },
  { 0x1900, 0x2219, 0x0000 },
  { 0x9900, 0x221c, 0x2000 },
  { 0x1900, 0x221b, 0x0000 },
  { 0x1900, 0x221d, 0x0000 },
  { 0x9900, 0x2226, 0x4000 },
  { 0x9900, 0x2222, 0x3000 },
  { 0x9900, 0x2220, 0x2000 },
  { 0x1900, 0x221f, 0x0000 },
  { 0x1900, 0x2221, 0x0000 },
  { 0x9900, 0x2224, 0x2000 },
  { 0x1900, 0x2223, 0x0000 },
  { 0x1900, 0x2225, 0x0000 },
  { 0x9900, 0x222a, 0x3000 },
  { 0x9900, 0x2228, 0x2000 },
  { 0x1900, 0x2227, 0x0000 },
  { 0x1900, 0x2229, 0x0000 },
  { 0x9900, 0x222c, 0x2000 },
  { 0x1900, 0x222b, 0x0000 },
  { 0x1900, 0x222d, 0x0000 },
  { 0x9900, 0x226e, 0x7000 },
  { 0x9900, 0x224e, 0x6000 },
  { 0x9900, 0x223e, 0x5000 },
  { 0x9900, 0x2236, 0x4000 },
  { 0x9900, 0x2232, 0x3000 },
  { 0x9900, 0x2230, 0x2000 },
  { 0x1900, 0x222f, 0x0000 },
  { 0x1900, 0x2231, 0x0000 },
  { 0x9900, 0x2234, 0x2000 },
  { 0x1900, 0x2233, 0x0000 },
  { 0x1900, 0x2235, 0x0000 },
  { 0x9900, 0x223a, 0x3000 },
  { 0x9900, 0x2238, 0x2000 },
  { 0x1900, 0x2237, 0x0000 },
  { 0x1900, 0x2239, 0x0000 },
  { 0x9900, 0x223c, 0x2000 },
  { 0x1900, 0x223b, 0x0000 },
  { 0x1900, 0x223d, 0x0000 },
  { 0x9900, 0x2246, 0x4000 },
  { 0x9900, 0x2242, 0x3000 },
  { 0x9900, 0x2240, 0x2000 },
  { 0x1900, 0x223f, 0x0000 },
  { 0x1900, 0x2241, 0x0000 },
  { 0x9900, 0x2244, 0x2000 },
  { 0x1900, 0x2243, 0x0000 },
  { 0x1900, 0x2245, 0x0000 },
  { 0x9900, 0x224a, 0x3000 },
  { 0x9900, 0x2248, 0x2000 },
  { 0x1900, 0x2247, 0x0000 },
  { 0x1900, 0x2249, 0x0000 },
  { 0x9900, 0x224c, 0x2000 },
  { 0x1900, 0x224b, 0x0000 },
  { 0x1900, 0x224d, 0x0000 },
  { 0x9900, 0x225e, 0x5000 },
  { 0x9900, 0x2256, 0x4000 },
  { 0x9900, 0x2252, 0x3000 },
  { 0x9900, 0x2250, 0x2000 },
  { 0x1900, 0x224f, 0x0000 },
  { 0x1900, 0x2251, 0x0000 },
  { 0x9900, 0x2254, 0x2000 },
  { 0x1900, 0x2253, 0x0000 },
  { 0x1900, 0x2255, 0x0000 },
  { 0x9900, 0x225a, 0x3000 },
  { 0x9900, 0x2258, 0x2000 },
  { 0x1900, 0x2257, 0x0000 },
  { 0x1900, 0x2259, 0x0000 },
  { 0x9900, 0x225c, 0x2000 },
  { 0x1900, 0x225b, 0x0000 },
  { 0x1900, 0x225d, 0x0000 },
  { 0x9900, 0x2266, 0x4000 },
  { 0x9900, 0x2262, 0x3000 },
  { 0x9900, 0x2260, 0x2000 },
  { 0x1900, 0x225f, 0x0000 },
  { 0x1900, 0x2261, 0x0000 },
  { 0x9900, 0x2264, 0x2000 },
  { 0x1900, 0x2263, 0x0000 },
  { 0x1900, 0x2265, 0x0000 },
  { 0x9900, 0x226a, 0x3000 },
  { 0x9900, 0x2268, 0x2000 },
  { 0x1900, 0x2267, 0x0000 },
  { 0x1900, 0x2269, 0x0000 },
  { 0x9900, 0x226c, 0x2000 },
  { 0x1900, 0x226b, 0x0000 },
  { 0x1900, 0x226d, 0x0000 },
  { 0x9900, 0x228e, 0x6000 },
  { 0x9900, 0x227e, 0x5000 },
  { 0x9900, 0x2276, 0x4000 },
  { 0x9900, 0x2272, 0x3000 },
  { 0x9900, 0x2270, 0x2000 },
  { 0x1900, 0x226f, 0x0000 },
  { 0x1900, 0x2271, 0x0000 },
  { 0x9900, 0x2274, 0x2000 },
  { 0x1900, 0x2273, 0x0000 },
  { 0x1900, 0x2275, 0x0000 },
  { 0x9900, 0x227a, 0x3000 },
  { 0x9900, 0x2278, 0x2000 },
  { 0x1900, 0x2277, 0x0000 },
  { 0x1900, 0x2279, 0x0000 },
  { 0x9900, 0x227c, 0x2000 },
  { 0x1900, 0x227b, 0x0000 },
  { 0x1900, 0x227d, 0x0000 },
  { 0x9900, 0x2286, 0x4000 },
  { 0x9900, 0x2282, 0x3000 },
  { 0x9900, 0x2280, 0x2000 },
  { 0x1900, 0x227f, 0x0000 },
  { 0x1900, 0x2281, 0x0000 },
  { 0x9900, 0x2284, 0x2000 },
  { 0x1900, 0x2283, 0x0000 },
  { 0x1900, 0x2285, 0x0000 },
  { 0x9900, 0x228a, 0x3000 },
  { 0x9900, 0x2288, 0x2000 },
  { 0x1900, 0x2287, 0x0000 },
  { 0x1900, 0x2289, 0x0000 },
  { 0x9900, 0x228c, 0x2000 },
  { 0x1900, 0x228b, 0x0000 },
  { 0x1900, 0x228d, 0x0000 },
  { 0x9900, 0x229e, 0x5000 },
  { 0x9900, 0x2296, 0x4000 },
  { 0x9900, 0x2292, 0x3000 },
  { 0x9900, 0x2290, 0x2000 },
  { 0x1900, 0x228f, 0x0000 },
  { 0x1900, 0x2291, 0x0000 },
  { 0x9900, 0x2294, 0x2000 },
  { 0x1900, 0x2293, 0x0000 },
  { 0x1900, 0x2295, 0x0000 },
  { 0x9900, 0x229a, 0x3000 },
  { 0x9900, 0x2298, 0x2000 },
  { 0x1900, 0x2297, 0x0000 },
  { 0x1900, 0x2299, 0x0000 },
  { 0x9900, 0x229c, 0x2000 },
  { 0x1900, 0x229b, 0x0000 },
  { 0x1900, 0x229d, 0x0000 },
  { 0x9900, 0x22a6, 0x4000 },
  { 0x9900, 0x22a2, 0x3000 },
  { 0x9900, 0x22a0, 0x2000 },
  { 0x1900, 0x229f, 0x0000 },
  { 0x1900, 0x22a1, 0x0000 },
  { 0x9900, 0x22a4, 0x2000 },
  { 0x1900, 0x22a3, 0x0000 },
  { 0x1900, 0x22a5, 0x0000 },
  { 0x9900, 0x22aa, 0x3000 },
  { 0x9900, 0x22a8, 0x2000 },
  { 0x1900, 0x22a7, 0x0000 },
  { 0x1900, 0x22a9, 0x0000 },
  { 0x9900, 0x22ac, 0x2000 },
  { 0x1900, 0x22ab, 0x0000 },
  { 0x1900, 0x22ad, 0x0000 },
  { 0x8f00, 0x2787, 0xb000 },
  { 0x9a00, 0x250b, 0xa000 },
  { 0x9900, 0x23ae, 0x9000 },
  { 0x9a00, 0x232e, 0x8000 },
  { 0x9900, 0x22ee, 0x7000 },
  { 0x9900, 0x22ce, 0x6000 },
  { 0x9900, 0x22be, 0x5000 },
  { 0x9900, 0x22b6, 0x4000 },
  { 0x9900, 0x22b2, 0x3000 },
  { 0x9900, 0x22b0, 0x2000 },
  { 0x1900, 0x22af, 0x0000 },
  { 0x1900, 0x22b1, 0x0000 },
  { 0x9900, 0x22b4, 0x2000 },
  { 0x1900, 0x22b3, 0x0000 },
  { 0x1900, 0x22b5, 0x0000 },
  { 0x9900, 0x22ba, 0x3000 },
  { 0x9900, 0x22b8, 0x2000 },
  { 0x1900, 0x22b7, 0x0000 },
  { 0x1900, 0x22b9, 0x0000 },
  { 0x9900, 0x22bc, 0x2000 },
  { 0x1900, 0x22bb, 0x0000 },
  { 0x1900, 0x22bd, 0x0000 },
  { 0x9900, 0x22c6, 0x4000 },
  { 0x9900, 0x22c2, 0x3000 },
  { 0x9900, 0x22c0, 0x2000 },
  { 0x1900, 0x22bf, 0x0000 },
  { 0x1900, 0x22c1, 0x0000 },
  { 0x9900, 0x22c4, 0x2000 },
  { 0x1900, 0x22c3, 0x0000 },
  { 0x1900, 0x22c5, 0x0000 },
  { 0x9900, 0x22ca, 0x3000 },
  { 0x9900, 0x22c8, 0x2000 },
  { 0x1900, 0x22c7, 0x0000 },
  { 0x1900, 0x22c9, 0x0000 },
  { 0x9900, 0x22cc, 0x2000 },
  { 0x1900, 0x22cb, 0x0000 },
  { 0x1900, 0x22cd, 0x0000 },
  { 0x9900, 0x22de, 0x5000 },
  { 0x9900, 0x22d6, 0x4000 },
  { 0x9900, 0x22d2, 0x3000 },
  { 0x9900, 0x22d0, 0x2000 },
  { 0x1900, 0x22cf, 0x0000 },
  { 0x1900, 0x22d1, 0x0000 },
  { 0x9900, 0x22d4, 0x2000 },
  { 0x1900, 0x22d3, 0x0000 },
  { 0x1900, 0x22d5, 0x0000 },
  { 0x9900, 0x22da, 0x3000 },
  { 0x9900, 0x22d8, 0x2000 },
  { 0x1900, 0x22d7, 0x0000 },
  { 0x1900, 0x22d9, 0x0000 },
  { 0x9900, 0x22dc, 0x2000 },
  { 0x1900, 0x22db, 0x0000 },
  { 0x1900, 0x22dd, 0x0000 },
  { 0x9900, 0x22e6, 0x4000 },
  { 0x9900, 0x22e2, 0x3000 },
  { 0x9900, 0x22e0, 0x2000 },
  { 0x1900, 0x22df, 0x0000 },
  { 0x1900, 0x22e1, 0x0000 },
  { 0x9900, 0x22e4, 0x2000 },
  { 0x1900, 0x22e3, 0x0000 },
  { 0x1900, 0x22e5, 0x0000 },
  { 0x9900, 0x22ea, 0x3000 },
  { 0x9900, 0x22e8, 0x2000 },
  { 0x1900, 0x22e7, 0x0000 },
  { 0x1900, 0x22e9, 0x0000 },
  { 0x9900, 0x22ec, 0x2000 },
  { 0x1900, 0x22eb, 0x0000 },
  { 0x1900, 0x22ed, 0x0000 },
  { 0x9a00, 0x230e, 0x6000 },
  { 0x9900, 0x22fe, 0x5000 },
  { 0x9900, 0x22f6, 0x4000 },
  { 0x9900, 0x22f2, 0x3000 },
  { 0x9900, 0x22f0, 0x2000 },
  { 0x1900, 0x22ef, 0x0000 },
  { 0x1900, 0x22f1, 0x0000 },
  { 0x9900, 0x22f4, 0x2000 },
  { 0x1900, 0x22f3, 0x0000 },
  { 0x1900, 0x22f5, 0x0000 },
  { 0x9900, 0x22fa, 0x3000 },
  { 0x9900, 0x22f8, 0x2000 },
  { 0x1900, 0x22f7, 0x0000 },
  { 0x1900, 0x22f9, 0x0000 },
  { 0x9900, 0x22fc, 0x2000 },
  { 0x1900, 0x22fb, 0x0000 },
  { 0x1900, 0x22fd, 0x0000 },
  { 0x9a00, 0x2306, 0x4000 },
  { 0x9a00, 0x2302, 0x3000 },
  { 0x9a00, 0x2300, 0x2000 },
  { 0x1900, 0x22ff, 0x0000 },
  { 0x1a00, 0x2301, 0x0000 },
  { 0x9a00, 0x2304, 0x2000 },
  { 0x1a00, 0x2303, 0x0000 },
  { 0x1a00, 0x2305, 0x0000 },
  { 0x9900, 0x230a, 0x3000 },
  { 0x9900, 0x2308, 0x2000 },
  { 0x1a00, 0x2307, 0x0000 },
  { 0x1900, 0x2309, 0x0000 },
  { 0x9a00, 0x230c, 0x2000 },
  { 0x1900, 0x230b, 0x0000 },
  { 0x1a00, 0x230d, 0x0000 },
  { 0x9a00, 0x231e, 0x5000 },
  { 0x9a00, 0x2316, 0x4000 },
  { 0x9a00, 0x2312, 0x3000 },
  { 0x9a00, 0x2310, 0x2000 },
  { 0x1a00, 0x230f, 0x0000 },
  { 0x1a00, 0x2311, 0x0000 },
  { 0x9a00, 0x2314, 0x2000 },
  { 0x1a00, 0x2313, 0x0000 },
  { 0x1a00, 0x2315, 0x0000 },
  { 0x9a00, 0x231a, 0x3000 },
  { 0x9a00, 0x2318, 0x2000 },
  { 0x1a00, 0x2317, 0x0000 },
  { 0x1a00, 0x2319, 0x0000 },
  { 0x9a00, 0x231c, 0x2000 },
  { 0x1a00, 0x231b, 0x0000 },
  { 0x1a00, 0x231d, 0x0000 },
  { 0x9a00, 0x2326, 0x4000 },
  { 0x9a00, 0x2322, 0x3000 },
  { 0x9900, 0x2320, 0x2000 },
  { 0x1a00, 0x231f, 0x0000 },
  { 0x1900, 0x2321, 0x0000 },
  { 0x9a00, 0x2324, 0x2000 },
  { 0x1a00, 0x2323, 0x0000 },
  { 0x1a00, 0x2325, 0x0000 },
  { 0x9200, 0x232a, 0x3000 },
  { 0x9a00, 0x2328, 0x2000 },
  { 0x1a00, 0x2327, 0x0000 },
  { 0x1600, 0x2329, 0x0000 },
  { 0x9a00, 0x232c, 0x2000 },
  { 0x1a00, 0x232b, 0x0000 },
  { 0x1a00, 0x232d, 0x0000 },
  { 0x9a00, 0x236e, 0x7000 },
  { 0x9a00, 0x234e, 0x6000 },
  { 0x9a00, 0x233e, 0x5000 },
  { 0x9a00, 0x2336, 0x4000 },
  { 0x9a00, 0x2332, 0x3000 },
  { 0x9a00, 0x2330, 0x2000 },
  { 0x1a00, 0x232f, 0x0000 },
  { 0x1a00, 0x2331, 0x0000 },
  { 0x9a00, 0x2334, 0x2000 },
  { 0x1a00, 0x2333, 0x0000 },
  { 0x1a00, 0x2335, 0x0000 },
  { 0x9a00, 0x233a, 0x3000 },
  { 0x9a00, 0x2338, 0x2000 },
  { 0x1a00, 0x2337, 0x0000 },
  { 0x1a00, 0x2339, 0x0000 },
  { 0x9a00, 0x233c, 0x2000 },
  { 0x1a00, 0x233b, 0x0000 },
  { 0x1a00, 0x233d, 0x0000 },
  { 0x9a00, 0x2346, 0x4000 },
  { 0x9a00, 0x2342, 0x3000 },
  { 0x9a00, 0x2340, 0x2000 },
  { 0x1a00, 0x233f, 0x0000 },
  { 0x1a00, 0x2341, 0x0000 },
  { 0x9a00, 0x2344, 0x2000 },
  { 0x1a00, 0x2343, 0x0000 },
  { 0x1a00, 0x2345, 0x0000 },
  { 0x9a00, 0x234a, 0x3000 },
  { 0x9a00, 0x2348, 0x2000 },
  { 0x1a00, 0x2347, 0x0000 },
  { 0x1a00, 0x2349, 0x0000 },
  { 0x9a00, 0x234c, 0x2000 },
  { 0x1a00, 0x234b, 0x0000 },
  { 0x1a00, 0x234d, 0x0000 },
  { 0x9a00, 0x235e, 0x5000 },
  { 0x9a00, 0x2356, 0x4000 },
  { 0x9a00, 0x2352, 0x3000 },
  { 0x9a00, 0x2350, 0x2000 },
  { 0x1a00, 0x234f, 0x0000 },
  { 0x1a00, 0x2351, 0x0000 },
  { 0x9a00, 0x2354, 0x2000 },
  { 0x1a00, 0x2353, 0x0000 },
  { 0x1a00, 0x2355, 0x0000 },
  { 0x9a00, 0x235a, 0x3000 },
  { 0x9a00, 0x2358, 0x2000 },
  { 0x1a00, 0x2357, 0x0000 },
  { 0x1a00, 0x2359, 0x0000 },
  { 0x9a00, 0x235c, 0x2000 },
  { 0x1a00, 0x235b, 0x0000 },
  { 0x1a00, 0x235d, 0x0000 },
  { 0x9a00, 0x2366, 0x4000 },
  { 0x9a00, 0x2362, 0x3000 },
  { 0x9a00, 0x2360, 0x2000 },
  { 0x1a00, 0x235f, 0x0000 },
  { 0x1a00, 0x2361, 0x0000 },
  { 0x9a00, 0x2364, 0x2000 },
  { 0x1a00, 0x2363, 0x0000 },
  { 0x1a00, 0x2365, 0x0000 },
  { 0x9a00, 0x236a, 0x3000 },
  { 0x9a00, 0x2368, 0x2000 },
  { 0x1a00, 0x2367, 0x0000 },
  { 0x1a00, 0x2369, 0x0000 },
  { 0x9a00, 0x236c, 0x2000 },
  { 0x1a00, 0x236b, 0x0000 },
  { 0x1a00, 0x236d, 0x0000 },
  { 0x9a00, 0x238e, 0x6000 },
  { 0x9a00, 0x237e, 0x5000 },
  { 0x9a00, 0x2376, 0x4000 },
  { 0x9a00, 0x2372, 0x3000 },
  { 0x9a00, 0x2370, 0x2000 },
  { 0x1a00, 0x236f, 0x0000 },
  { 0x1a00, 0x2371, 0x0000 },
  { 0x9a00, 0x2374, 0x2000 },
  { 0x1a00, 0x2373, 0x0000 },
  { 0x1a00, 0x2375, 0x0000 },
  { 0x9a00, 0x237a, 0x3000 },
  { 0x9a00, 0x2378, 0x2000 },
  { 0x1a00, 0x2377, 0x0000 },
  { 0x1a00, 0x2379, 0x0000 },
  { 0x9900, 0x237c, 0x2000 },
  { 0x1a00, 0x237b, 0x0000 },
  { 0x1a00, 0x237d, 0x0000 },
  { 0x9a00, 0x2386, 0x4000 },
  { 0x9a00, 0x2382, 0x3000 },
  { 0x9a00, 0x2380, 0x2000 },
  { 0x1a00, 0x237f, 0x0000 },
  { 0x1a00, 0x2381, 0x0000 },
  { 0x9a00, 0x2384, 0x2000 },
  { 0x1a00, 0x2383, 0x0000 },
  { 0x1a00, 0x2385, 0x0000 },
  { 0x9a00, 0x238a, 0x3000 },
  { 0x9a00, 0x2388, 0x2000 },
  { 0x1a00, 0x2387, 0x0000 },
  { 0x1a00, 0x2389, 0x0000 },
  { 0x9a00, 0x238c, 0x2000 },
  { 0x1a00, 0x238b, 0x0000 },
  { 0x1a00, 0x238d, 0x0000 },
  { 0x9900, 0x239e, 0x5000 },
  { 0x9a00, 0x2396, 0x4000 },
  { 0x9a00, 0x2392, 0x3000 },
  { 0x9a00, 0x2390, 0x2000 },
  { 0x1a00, 0x238f, 0x0000 },
  { 0x1a00, 0x2391, 0x0000 },
  { 0x9a00, 0x2394, 0x2000 },
  { 0x1a00, 0x2393, 0x0000 },
  { 0x1a00, 0x2395, 0x0000 },
  { 0x9a00, 0x239a, 0x3000 },
  { 0x9a00, 0x2398, 0x2000 },
  { 0x1a00, 0x2397, 0x0000 },
  { 0x1a00, 0x2399, 0x0000 },
  { 0x9900, 0x239c, 0x2000 },
  { 0x1900, 0x239b, 0x0000 },
  { 0x1900, 0x239d, 0x0000 },
  { 0x9900, 0x23a6, 0x4000 },
  { 0x9900, 0x23a2, 0x3000 },
  { 0x9900, 0x23a0, 0x2000 },
  { 0x1900, 0x239f, 0x0000 },
  { 0x1900, 0x23a1, 0x0000 },
  { 0x9900, 0x23a4, 0x2000 },
  { 0x1900, 0x23a3, 0x0000 },
  { 0x1900, 0x23a5, 0x0000 },
  { 0x9900, 0x23aa, 0x3000 },
  { 0x9900, 0x23a8, 0x2000 },
  { 0x1900, 0x23a7, 0x0000 },
  { 0x1900, 0x23a9, 0x0000 },
  { 0x9900, 0x23ac, 0x2000 },
  { 0x1900, 0x23ab, 0x0000 },
  { 0x1900, 0x23ad, 0x0000 },
  { 0x8f00, 0x248b, 0x8000 },
  { 0x9a00, 0x241d, 0x7000 },
  { 0x9a00, 0x23ce, 0x6000 },
  { 0x9a00, 0x23be, 0x5000 },
  { 0x9500, 0x23b6, 0x4000 },
  { 0x9900, 0x23b2, 0x3000 },
  { 0x9900, 0x23b0, 0x2000 },
  { 0x1900, 0x23af, 0x0000 },
  { 0x1900, 0x23b1, 0x0000 },
  { 0x9600, 0x23b4, 0x2000 },
  { 0x1900, 0x23b3, 0x0000 },
  { 0x1200, 0x23b5, 0x0000 },
  { 0x9a00, 0x23ba, 0x3000 },
  { 0x9a00, 0x23b8, 0x2000 },
  { 0x1a00, 0x23b7, 0x0000 },
  { 0x1a00, 0x23b9, 0x0000 },
  { 0x9a00, 0x23bc, 0x2000 },
  { 0x1a00, 0x23bb, 0x0000 },
  { 0x1a00, 0x23bd, 0x0000 },
  { 0x9a00, 0x23c6, 0x4000 },
  { 0x9a00, 0x23c2, 0x3000 },
  { 0x9a00, 0x23c0, 0x2000 },
  { 0x1a00, 0x23bf, 0x0000 },
  { 0x1a00, 0x23c1, 0x0000 },
  { 0x9a00, 0x23c4, 0x2000 },
  { 0x1a00, 0x23c3, 0x0000 },
  { 0x1a00, 0x23c5, 0x0000 },
  { 0x9a00, 0x23ca, 0x3000 },
  { 0x9a00, 0x23c8, 0x2000 },
  { 0x1a00, 0x23c7, 0x0000 },
  { 0x1a00, 0x23c9, 0x0000 },
  { 0x9a00, 0x23cc, 0x2000 },
  { 0x1a00, 0x23cb, 0x0000 },
  { 0x1a00, 0x23cd, 0x0000 },
  { 0x9a00, 0x240d, 0x5000 },
  { 0x9a00, 0x2405, 0x4000 },
  { 0x9a00, 0x2401, 0x3000 },
  { 0x9a00, 0x23d0, 0x2000 },
  { 0x1a00, 0x23cf, 0x0000 },
  { 0x1a00, 0x2400, 0x0000 },
  { 0x9a00, 0x2403, 0x2000 },
  { 0x1a00, 0x2402, 0x0000 },
  { 0x1a00, 0x2404, 0x0000 },
  { 0x9a00, 0x2409, 0x3000 },
  { 0x9a00, 0x2407, 0x2000 },
  { 0x1a00, 0x2406, 0x0000 },
  { 0x1a00, 0x2408, 0x0000 },
  { 0x9a00, 0x240b, 0x2000 },
  { 0x1a00, 0x240a, 0x0000 },
  { 0x1a00, 0x240c, 0x0000 },
  { 0x9a00, 0x2415, 0x4000 },
  { 0x9a00, 0x2411, 0x3000 },
  { 0x9a00, 0x240f, 0x2000 },
  { 0x1a00, 0x240e, 0x0000 },
  { 0x1a00, 0x2410, 0x0000 },
  { 0x9a00, 0x2413, 0x2000 },
  { 0x1a00, 0x2412, 0x0000 },
  { 0x1a00, 0x2414, 0x0000 },
  { 0x9a00, 0x2419, 0x3000 },
  { 0x9a00, 0x2417, 0x2000 },
  { 0x1a00, 0x2416, 0x0000 },
  { 0x1a00, 0x2418, 0x0000 },
  { 0x9a00, 0x241b, 0x2000 },
  { 0x1a00, 0x241a, 0x0000 },
  { 0x1a00, 0x241c, 0x0000 },
  { 0x8f00, 0x246b, 0x6000 },
  { 0x9a00, 0x2446, 0x5000 },
  { 0x9a00, 0x2425, 0x4000 },
  { 0x9a00, 0x2421, 0x3000 },
  { 0x9a00, 0x241f, 0x2000 },
  { 0x1a00, 0x241e, 0x0000 },
  { 0x1a00, 0x2420, 0x0000 },
  { 0x9a00, 0x2423, 0x2000 },
  { 0x1a00, 0x2422, 0x0000 },
  { 0x1a00, 0x2424, 0x0000 },
  { 0x9a00, 0x2442, 0x3000 },
  { 0x9a00, 0x2440, 0x2000 },
  { 0x1a00, 0x2426, 0x0000 },
  { 0x1a00, 0x2441, 0x0000 },
  { 0x9a00, 0x2444, 0x2000 },
  { 0x1a00, 0x2443, 0x0000 },
  { 0x1a00, 0x2445, 0x0000 },
  { 0x8f00, 0x2463, 0x4000 },
  { 0x9a00, 0x244a, 0x3000 },
  { 0x9a00, 0x2448, 0x2000 },
  { 0x1a00, 0x2447, 0x0000 },
  { 0x1a00, 0x2449, 0x0000 },
  { 0x8f00, 0x2461, 0x2000 },
  { 0x0f00, 0x2460, 0x0000 },
  { 0x0f00, 0x2462, 0x0000 },
  { 0x8f00, 0x2467, 0x3000 },
  { 0x8f00, 0x2465, 0x2000 },
  { 0x0f00, 0x2464, 0x0000 },
  { 0x0f00, 0x2466, 0x0000 },
  { 0x8f00, 0x2469, 0x2000 },
  { 0x0f00, 0x2468, 0x0000 },
  { 0x0f00, 0x246a, 0x0000 },
  { 0x8f00, 0x247b, 0x5000 },
  { 0x8f00, 0x2473, 0x4000 },
  { 0x8f00, 0x246f, 0x3000 },
  { 0x8f00, 0x246d, 0x2000 },
  { 0x0f00, 0x246c, 0x0000 },
  { 0x0f00, 0x246e, 0x0000 },
  { 0x8f00, 0x2471, 0x2000 },
  { 0x0f00, 0x2470, 0x0000 },
  { 0x0f00, 0x2472, 0x0000 },
  { 0x8f00, 0x2477, 0x3000 },
  { 0x8f00, 0x2475, 0x2000 },
  { 0x0f00, 0x2474, 0x0000 },
  { 0x0f00, 0x2476, 0x0000 },
  { 0x8f00, 0x2479, 0x2000 },
  { 0x0f00, 0x2478, 0x0000 },
  { 0x0f00, 0x247a, 0x0000 },
  { 0x8f00, 0x2483, 0x4000 },
  { 0x8f00, 0x247f, 0x3000 },
  { 0x8f00, 0x247d, 0x2000 },
  { 0x0f00, 0x247c, 0x0000 },
  { 0x0f00, 0x247e, 0x0000 },
  { 0x8f00, 0x2481, 0x2000 },
  { 0x0f00, 0x2480, 0x0000 },
  { 0x0f00, 0x2482, 0x0000 },
  { 0x8f00, 0x2487, 0x3000 },
  { 0x8f00, 0x2485, 0x2000 },
  { 0x0f00, 0x2484, 0x0000 },
  { 0x0f00, 0x2486, 0x0000 },
  { 0x8f00, 0x2489, 0x2000 },
  { 0x0f00, 0x2488, 0x0000 },
  { 0x0f00, 0x248a, 0x0000 },
  { 0x9a00, 0x24cb, 0x7000 },
  { 0x9a00, 0x24ab, 0x6000 },
  { 0x8f00, 0x249b, 0x5000 },
  { 0x8f00, 0x2493, 0x4000 },
  { 0x8f00, 0x248f, 0x3000 },
  { 0x8f00, 0x248d, 0x2000 },
  { 0x0f00, 0x248c, 0x0000 },
  { 0x0f00, 0x248e, 0x0000 },
  { 0x8f00, 0x2491, 0x2000 },
  { 0x0f00, 0x2490, 0x0000 },
  { 0x0f00, 0x2492, 0x0000 },
  { 0x8f00, 0x2497, 0x3000 },
  { 0x8f00, 0x2495, 0x2000 },
  { 0x0f00, 0x2494, 0x0000 },
  { 0x0f00, 0x2496, 0x0000 },
  { 0x8f00, 0x2499, 0x2000 },
  { 0x0f00, 0x2498, 0x0000 },
  { 0x0f00, 0x249a, 0x0000 },
  { 0x9a00, 0x24a3, 0x4000 },
  { 0x9a00, 0x249f, 0x3000 },
  { 0x9a00, 0x249d, 0x2000 },
  { 0x1a00, 0x249c, 0x0000 },
  { 0x1a00, 0x249e, 0x0000 },
  { 0x9a00, 0x24a1, 0x2000 },
  { 0x1a00, 0x24a0, 0x0000 },
  { 0x1a00, 0x24a2, 0x0000 },
  { 0x9a00, 0x24a7, 0x3000 },
  { 0x9a00, 0x24a5, 0x2000 },
  { 0x1a00, 0x24a4, 0x0000 },
  { 0x1a00, 0x24a6, 0x0000 },
  { 0x9a00, 0x24a9, 0x2000 },
  { 0x1a00, 0x24a8, 0x0000 },
  { 0x1a00, 0x24aa, 0x0000 },
  { 0x9a00, 0x24bb, 0x5000 },
  { 0x9a00, 0x24b3, 0x4000 },
  { 0x9a00, 0x24af, 0x3000 },
  { 0x9a00, 0x24ad, 0x2000 },
  { 0x1a00, 0x24ac, 0x0000 },
  { 0x1a00, 0x24ae, 0x0000 },
  { 0x9a00, 0x24b1, 0x2000 },
  { 0x1a00, 0x24b0, 0x0000 },
  { 0x1a00, 0x24b2, 0x0000 },
  { 0x9a00, 0x24b7, 0x3000 },
  { 0x9a00, 0x24b5, 0x2000 },
  { 0x1a00, 0x24b4, 0x0000 },
  { 0x1a00, 0x24b6, 0x0000 },
  { 0x9a00, 0x24b9, 0x2000 },
  { 0x1a00, 0x24b8, 0x0000 },
  { 0x1a00, 0x24ba, 0x0000 },
  { 0x9a00, 0x24c3, 0x4000 },
  { 0x9a00, 0x24bf, 0x3000 },
  { 0x9a00, 0x24bd, 0x2000 },
  { 0x1a00, 0x24bc, 0x0000 },
  { 0x1a00, 0x24be, 0x0000 },
  { 0x9a00, 0x24c1, 0x2000 },
  { 0x1a00, 0x24c0, 0x0000 },
  { 0x1a00, 0x24c2, 0x0000 },
  { 0x9a00, 0x24c7, 0x3000 },
  { 0x9a00, 0x24c5, 0x2000 },
  { 0x1a00, 0x24c4, 0x0000 },
  { 0x1a00, 0x24c6, 0x0000 },
  { 0x9a00, 0x24c9, 0x2000 },
  { 0x1a00, 0x24c8, 0x0000 },
  { 0x1a00, 0x24ca, 0x0000 },
  { 0x8f00, 0x24eb, 0x6000 },
  { 0x9a00, 0x24db, 0x5000 },
  { 0x9a00, 0x24d3, 0x4000 },
  { 0x9a00, 0x24cf, 0x3000 },
  { 0x9a00, 0x24cd, 0x2000 },
  { 0x1a00, 0x24cc, 0x0000 },
  { 0x1a00, 0x24ce, 0x0000 },
  { 0x9a00, 0x24d1, 0x2000 },
  { 0x1a00, 0x24d0, 0x0000 },
  { 0x1a00, 0x24d2, 0x0000 },
  { 0x9a00, 0x24d7, 0x3000 },
  { 0x9a00, 0x24d5, 0x2000 },
  { 0x1a00, 0x24d4, 0x0000 },
  { 0x1a00, 0x24d6, 0x0000 },
  { 0x9a00, 0x24d9, 0x2000 },
  { 0x1a00, 0x24d8, 0x0000 },
  { 0x1a00, 0x24da, 0x0000 },
  { 0x9a00, 0x24e3, 0x4000 },
  { 0x9a00, 0x24df, 0x3000 },
  { 0x9a00, 0x24dd, 0x2000 },
  { 0x1a00, 0x24dc, 0x0000 },
  { 0x1a00, 0x24de, 0x0000 },
  { 0x9a00, 0x24e1, 0x2000 },
  { 0x1a00, 0x24e0, 0x0000 },
  { 0x1a00, 0x24e2, 0x0000 },
  { 0x9a00, 0x24e7, 0x3000 },
  { 0x9a00, 0x24e5, 0x2000 },
  { 0x1a00, 0x24e4, 0x0000 },
  { 0x1a00, 0x24e6, 0x0000 },
  { 0x9a00, 0x24e9, 0x2000 },
  { 0x1a00, 0x24e8, 0x0000 },
  { 0x0f00, 0x24ea, 0x0000 },
  { 0x8f00, 0x24fb, 0x5000 },
  { 0x8f00, 0x24f3, 0x4000 },
  { 0x8f00, 0x24ef, 0x3000 },
  { 0x8f00, 0x24ed, 0x2000 },
  { 0x0f00, 0x24ec, 0x0000 },
  { 0x0f00, 0x24ee, 0x0000 },
  { 0x8f00, 0x24f1, 0x2000 },
  { 0x0f00, 0x24f0, 0x0000 },
  { 0x0f00, 0x24f2, 0x0000 },
  { 0x8f00, 0x24f7, 0x3000 },
  { 0x8f00, 0x24f5, 0x2000 },
  { 0x0f00, 0x24f4, 0x0000 },
  { 0x0f00, 0x24f6, 0x0000 },
  { 0x8f00, 0x24f9, 0x2000 },
  { 0x0f00, 0x24f8, 0x0000 },
  { 0x0f00, 0x24fa, 0x0000 },
  { 0x9a00, 0x2503, 0x4000 },
  { 0x8f00, 0x24ff, 0x3000 },
  { 0x8f00, 0x24fd, 0x2000 },
  { 0x0f00, 0x24fc, 0x0000 },
  { 0x0f00, 0x24fe, 0x0000 },
  { 0x9a00, 0x2501, 0x2000 },
  { 0x1a00, 0x2500, 0x0000 },
  { 0x1a00, 0x2502, 0x0000 },
  { 0x9a00, 0x2507, 0x3000 },
  { 0x9a00, 0x2505, 0x2000 },
  { 0x1a00, 0x2504, 0x0000 },
  { 0x1a00, 0x2506, 0x0000 },
  { 0x9a00, 0x2509, 0x2000 },
  { 0x1a00, 0x2508, 0x0000 },
  { 0x1a00, 0x250a, 0x0000 },
  { 0x9a00, 0x260b, 0x9000 },
  { 0x9a00, 0x258b, 0x8000 },
  { 0x9a00, 0x254b, 0x7000 },
  { 0x9a00, 0x252b, 0x6000 },
  { 0x9a00, 0x251b, 0x5000 },
  { 0x9a00, 0x2513, 0x4000 },
  { 0x9a00, 0x250f, 0x3000 },
  { 0x9a00, 0x250d, 0x2000 },
  { 0x1a00, 0x250c, 0x0000 },
  { 0x1a00, 0x250e, 0x0000 },
  { 0x9a00, 0x2511, 0x2000 },
  { 0x1a00, 0x2510, 0x0000 },
  { 0x1a00, 0x2512, 0x0000 },
  { 0x9a00, 0x2517, 0x3000 },
  { 0x9a00, 0x2515, 0x2000 },
  { 0x1a00, 0x2514, 0x0000 },
  { 0x1a00, 0x2516, 0x0000 },
  { 0x9a00, 0x2519, 0x2000 },
  { 0x1a00, 0x2518, 0x0000 },
  { 0x1a00, 0x251a, 0x0000 },
  { 0x9a00, 0x2523, 0x4000 },
  { 0x9a00, 0x251f, 0x3000 },
  { 0x9a00, 0x251d, 0x2000 },
  { 0x1a00, 0x251c, 0x0000 },
  { 0x1a00, 0x251e, 0x0000 },
  { 0x9a00, 0x2521, 0x2000 },
  { 0x1a00, 0x2520, 0x0000 },
  { 0x1a00, 0x2522, 0x0000 },
  { 0x9a00, 0x2527, 0x3000 },
  { 0x9a00, 0x2525, 0x2000 },
  { 0x1a00, 0x2524, 0x0000 },
  { 0x1a00, 0x2526, 0x0000 },
  { 0x9a00, 0x2529, 0x2000 },
  { 0x1a00, 0x2528, 0x0000 },
  { 0x1a00, 0x252a, 0x0000 },
  { 0x9a00, 0x253b, 0x5000 },
  { 0x9a00, 0x2533, 0x4000 },
  { 0x9a00, 0x252f, 0x3000 },
  { 0x9a00, 0x252d, 0x2000 },
  { 0x1a00, 0x252c, 0x0000 },
  { 0x1a00, 0x252e, 0x0000 },
  { 0x9a00, 0x2531, 0x2000 },
  { 0x1a00, 0x2530, 0x0000 },
  { 0x1a00, 0x2532, 0x0000 },
  { 0x9a00, 0x2537, 0x3000 },
  { 0x9a00, 0x2535, 0x2000 },
  { 0x1a00, 0x2534, 0x0000 },
  { 0x1a00, 0x2536, 0x0000 },
  { 0x9a00, 0x2539, 0x2000 },
  { 0x1a00, 0x2538, 0x0000 },
  { 0x1a00, 0x253a, 0x0000 },
  { 0x9a00, 0x2543, 0x4000 },
  { 0x9a00, 0x253f, 0x3000 },
  { 0x9a00, 0x253d, 0x2000 },
  { 0x1a00, 0x253c, 0x0000 },
  { 0x1a00, 0x253e, 0x0000 },
  { 0x9a00, 0x2541, 0x2000 },
  { 0x1a00, 0x2540, 0x0000 },
  { 0x1a00, 0x2542, 0x0000 },
  { 0x9a00, 0x2547, 0x3000 },
  { 0x9a00, 0x2545, 0x2000 },
  { 0x1a00, 0x2544, 0x0000 },
  { 0x1a00, 0x2546, 0x0000 },
  { 0x9a00, 0x2549, 0x2000 },
  { 0x1a00, 0x2548, 0x0000 },
  { 0x1a00, 0x254a, 0x0000 },
  { 0x9a00, 0x256b, 0x6000 },
  { 0x9a00, 0x255b, 0x5000 },
  { 0x9a00, 0x2553, 0x4000 },
  { 0x9a00, 0x254f, 0x3000 },
  { 0x9a00, 0x254d, 0x2000 },
  { 0x1a00, 0x254c, 0x0000 },
  { 0x1a00, 0x254e, 0x0000 },
  { 0x9a00, 0x2551, 0x2000 },
  { 0x1a00, 0x2550, 0x0000 },
  { 0x1a00, 0x2552, 0x0000 },
  { 0x9a00, 0x2557, 0x3000 },
  { 0x9a00, 0x2555, 0x2000 },
  { 0x1a00, 0x2554, 0x0000 },
  { 0x1a00, 0x2556, 0x0000 },
  { 0x9a00, 0x2559, 0x2000 },
  { 0x1a00, 0x2558, 0x0000 },
  { 0x1a00, 0x255a, 0x0000 },
  { 0x9a00, 0x2563, 0x4000 },
  { 0x9a00, 0x255f, 0x3000 },
  { 0x9a00, 0x255d, 0x2000 },
  { 0x1a00, 0x255c, 0x0000 },
  { 0x1a00, 0x255e, 0x0000 },
  { 0x9a00, 0x2561, 0x2000 },
  { 0x1a00, 0x2560, 0x0000 },
  { 0x1a00, 0x2562, 0x0000 },
  { 0x9a00, 0x2567, 0x3000 },
  { 0x9a00, 0x2565, 0x2000 },
  { 0x1a00, 0x2564, 0x0000 },
  { 0x1a00, 0x2566, 0x0000 },
  { 0x9a00, 0x2569, 0x2000 },
  { 0x1a00, 0x2568, 0x0000 },
  { 0x1a00, 0x256a, 0x0000 },
  { 0x9a00, 0x257b, 0x5000 },
  { 0x9a00, 0x2573, 0x4000 },
  { 0x9a00, 0x256f, 0x3000 },
  { 0x9a00, 0x256d, 0x2000 },
  { 0x1a00, 0x256c, 0x0000 },
  { 0x1a00, 0x256e, 0x0000 },
  { 0x9a00, 0x2571, 0x2000 },
  { 0x1a00, 0x2570, 0x0000 },
  { 0x1a00, 0x2572, 0x0000 },
  { 0x9a00, 0x2577, 0x3000 },
  { 0x9a00, 0x2575, 0x2000 },
  { 0x1a00, 0x2574, 0x0000 },
  { 0x1a00, 0x2576, 0x0000 },
  { 0x9a00, 0x2579, 0x2000 },
  { 0x1a00, 0x2578, 0x0000 },
  { 0x1a00, 0x257a, 0x0000 },
  { 0x9a00, 0x2583, 0x4000 },
  { 0x9a00, 0x257f, 0x3000 },
  { 0x9a00, 0x257d, 0x2000 },
  { 0x1a00, 0x257c, 0x0000 },
  { 0x1a00, 0x257e, 0x0000 },
  { 0x9a00, 0x2581, 0x2000 },
  { 0x1a00, 0x2580, 0x0000 },
  { 0x1a00, 0x2582, 0x0000 },
  { 0x9a00, 0x2587, 0x3000 },
  { 0x9a00, 0x2585, 0x2000 },
  { 0x1a00, 0x2584, 0x0000 },
  { 0x1a00, 0x2586, 0x0000 },
  { 0x9a00, 0x2589, 0x2000 },
  { 0x1a00, 0x2588, 0x0000 },
  { 0x1a00, 0x258a, 0x0000 },
  { 0x9a00, 0x25cb, 0x7000 },
  { 0x9a00, 0x25ab, 0x6000 },
  { 0x9a00, 0x259b, 0x5000 },
  { 0x9a00, 0x2593, 0x4000 },
  { 0x9a00, 0x258f, 0x3000 },
  { 0x9a00, 0x258d, 0x2000 },
  { 0x1a00, 0x258c, 0x0000 },
  { 0x1a00, 0x258e, 0x0000 },
  { 0x9a00, 0x2591, 0x2000 },
  { 0x1a00, 0x2590, 0x0000 },
  { 0x1a00, 0x2592, 0x0000 },
  { 0x9a00, 0x2597, 0x3000 },
  { 0x9a00, 0x2595, 0x2000 },
  { 0x1a00, 0x2594, 0x0000 },
  { 0x1a00, 0x2596, 0x0000 },
  { 0x9a00, 0x2599, 0x2000 },
  { 0x1a00, 0x2598, 0x0000 },
  { 0x1a00, 0x259a, 0x0000 },
  { 0x9a00, 0x25a3, 0x4000 },
  { 0x9a00, 0x259f, 0x3000 },
  { 0x9a00, 0x259d, 0x2000 },
  { 0x1a00, 0x259c, 0x0000 },
  { 0x1a00, 0x259e, 0x0000 },
  { 0x9a00, 0x25a1, 0x2000 },
  { 0x1a00, 0x25a0, 0x0000 },
  { 0x1a00, 0x25a2, 0x0000 },
  { 0x9a00, 0x25a7, 0x3000 },
  { 0x9a00, 0x25a5, 0x2000 },
  { 0x1a00, 0x25a4, 0x0000 },
  { 0x1a00, 0x25a6, 0x0000 },
  { 0x9a00, 0x25a9, 0x2000 },
  { 0x1a00, 0x25a8, 0x0000 },
  { 0x1a00, 0x25aa, 0x0000 },
  { 0x9a00, 0x25bb, 0x5000 },
  { 0x9a00, 0x25b3, 0x4000 },
  { 0x9a00, 0x25af, 0x3000 },
  { 0x9a00, 0x25ad, 0x2000 },
  { 0x1a00, 0x25ac, 0x0000 },
  { 0x1a00, 0x25ae, 0x0000 },
  { 0x9a00, 0x25b1, 0x2000 },
  { 0x1a00, 0x25b0, 0x0000 },
  { 0x1a00, 0x25b2, 0x0000 },
  { 0x9900, 0x25b7, 0x3000 },
  { 0x9a00, 0x25b5, 0x2000 },
  { 0x1a00, 0x25b4, 0x0000 },
  { 0x1a00, 0x25b6, 0x0000 },
  { 0x9a00, 0x25b9, 0x2000 },
  { 0x1a00, 0x25b8, 0x0000 },
  { 0x1a00, 0x25ba, 0x0000 },
  { 0x9a00, 0x25c3, 0x4000 },
  { 0x9a00, 0x25bf, 0x3000 },
  { 0x9a00, 0x25bd, 0x2000 },
  { 0x1a00, 0x25bc, 0x0000 },
  { 0x1a00, 0x25be, 0x0000 },
  { 0x9900, 0x25c1, 0x2000 },
  { 0x1a00, 0x25c0, 0x0000 },
  { 0x1a00, 0x25c2, 0x0000 },
  { 0x9a00, 0x25c7, 0x3000 },
  { 0x9a00, 0x25c5, 0x2000 },
  { 0x1a00, 0x25c4, 0x0000 },
  { 0x1a00, 0x25c6, 0x0000 },
  { 0x9a00, 0x25c9, 0x2000 },
  { 0x1a00, 0x25c8, 0x0000 },
  { 0x1a00, 0x25ca, 0x0000 },
  { 0x9a00, 0x25eb, 0x6000 },
  { 0x9a00, 0x25db, 0x5000 },
  { 0x9a00, 0x25d3, 0x4000 },
  { 0x9a00, 0x25cf, 0x3000 },
  { 0x9a00, 0x25cd, 0x2000 },
  { 0x1a00, 0x25cc, 0x0000 },
  { 0x1a00, 0x25ce, 0x0000 },
  { 0x9a00, 0x25d1, 0x2000 },
  { 0x1a00, 0x25d0, 0x0000 },
  { 0x1a00, 0x25d2, 0x0000 },
  { 0x9a00, 0x25d7, 0x3000 },
  { 0x9a00, 0x25d5, 0x2000 },
  { 0x1a00, 0x25d4, 0x0000 },
  { 0x1a00, 0x25d6, 0x0000 },
  { 0x9a00, 0x25d9, 0x2000 },
  { 0x1a00, 0x25d8, 0x0000 },
  { 0x1a00, 0x25da, 0x0000 },
  { 0x9a00, 0x25e3, 0x4000 },
  { 0x9a00, 0x25df, 0x3000 },
  { 0x9a00, 0x25dd, 0x2000 },
  { 0x1a00, 0x25dc, 0x0000 },
  { 0x1a00, 0x25de, 0x0000 },
  { 0x9a00, 0x25e1, 0x2000 },
  { 0x1a00, 0x25e0, 0x0000 },
  { 0x1a00, 0x25e2, 0x0000 },
  { 0x9a00, 0x25e7, 0x3000 },
  { 0x9a00, 0x25e5, 0x2000 },
  { 0x1a00, 0x25e4, 0x0000 },
  { 0x1a00, 0x25e6, 0x0000 },
  { 0x9a00, 0x25e9, 0x2000 },
  { 0x1a00, 0x25e8, 0x0000 },
  { 0x1a00, 0x25ea, 0x0000 },
  { 0x9900, 0x25fb, 0x5000 },
  { 0x9a00, 0x25f3, 0x4000 },
  { 0x9a00, 0x25ef, 0x3000 },
  { 0x9a00, 0x25ed, 0x2000 },
  { 0x1a00, 0x25ec, 0x0000 },
  { 0x1a00, 0x25ee, 0x0000 },
  { 0x9a00, 0x25f1, 0x2000 },
  { 0x1a00, 0x25f0, 0x0000 },
  { 0x1a00, 0x25f2, 0x0000 },
  { 0x9a00, 0x25f7, 0x3000 },
  { 0x9a00, 0x25f5, 0x2000 },
  { 0x1a00, 0x25f4, 0x0000 },
  { 0x1a00, 0x25f6, 0x0000 },
  { 0x9900, 0x25f9, 0x2000 },
  { 0x1900, 0x25f8, 0x0000 },
  { 0x1900, 0x25fa, 0x0000 },
  { 0x9a00, 0x2603, 0x4000 },
  { 0x9900, 0x25ff, 0x3000 },
  { 0x9900, 0x25fd, 0x2000 },
  { 0x1900, 0x25fc, 0x0000 },
  { 0x1900, 0x25fe, 0x0000 },
  { 0x9a00, 0x2601, 0x2000 },
  { 0x1a00, 0x2600, 0x0000 },
  { 0x1a00, 0x2602, 0x0000 },
  { 0x9a00, 0x2607, 0x3000 },
  { 0x9a00, 0x2605, 0x2000 },
  { 0x1a00, 0x2604, 0x0000 },
  { 0x1a00, 0x2606, 0x0000 },
  { 0x9a00, 0x2609, 0x2000 },
  { 0x1a00, 0x2608, 0x0000 },
  { 0x1a00, 0x260a, 0x0000 },
  { 0x9a00, 0x268e, 0x8000 },
  { 0x9a00, 0x264c, 0x7000 },
  { 0x9a00, 0x262c, 0x6000 },
  { 0x9a00, 0x261c, 0x5000 },
  { 0x9a00, 0x2613, 0x4000 },
  { 0x9a00, 0x260f, 0x3000 },
  { 0x9a00, 0x260d, 0x2000 },
  { 0x1a00, 0x260c, 0x0000 },
  { 0x1a00, 0x260e, 0x0000 },
  { 0x9a00, 0x2611, 0x2000 },
  { 0x1a00, 0x2610, 0x0000 },
  { 0x1a00, 0x2612, 0x0000 },
  { 0x9a00, 0x2617, 0x3000 },
  { 0x9a00, 0x2615, 0x2000 },
  { 0x1a00, 0x2614, 0x0000 },
  { 0x1a00, 0x2616, 0x0000 },
  { 0x9a00, 0x261a, 0x2000 },
  { 0x1a00, 0x2619, 0x0000 },
  { 0x1a00, 0x261b, 0x0000 },
  { 0x9a00, 0x2624, 0x4000 },
  { 0x9a00, 0x2620, 0x3000 },
  { 0x9a00, 0x261e, 0x2000 },
  { 0x1a00, 0x261d, 0x0000 },
  { 0x1a00, 0x261f, 0x0000 },
  { 0x9a00, 0x2622, 0x2000 },
  { 0x1a00, 0x2621, 0x0000 },
  { 0x1a00, 0x2623, 0x0000 },
  { 0x9a00, 0x2628, 0x3000 },
  { 0x9a00, 0x2626, 0x2000 },
  { 0x1a00, 0x2625, 0x0000 },
  { 0x1a00, 0x2627, 0x0000 },
  { 0x9a00, 0x262a, 0x2000 },
  { 0x1a00, 0x2629, 0x0000 },
  { 0x1a00, 0x262b, 0x0000 },
  { 0x9a00, 0x263c, 0x5000 },
  { 0x9a00, 0x2634, 0x4000 },
  { 0x9a00, 0x2630, 0x3000 },
  { 0x9a00, 0x262e, 0x2000 },
  { 0x1a00, 0x262d, 0x0000 },
  { 0x1a00, 0x262f, 0x0000 },
  { 0x9a00, 0x2632, 0x2000 },
  { 0x1a00, 0x2631, 0x0000 },
  { 0x1a00, 0x2633, 0x0000 },
  { 0x9a00, 0x2638, 0x3000 },
  { 0x9a00, 0x2636, 0x2000 },
  { 0x1a00, 0x2635, 0x0000 },
  { 0x1a00, 0x2637, 0x0000 },
  { 0x9a00, 0x263a, 0x2000 },
  { 0x1a00, 0x2639, 0x0000 },
  { 0x1a00, 0x263b, 0x0000 },
  { 0x9a00, 0x2644, 0x4000 },
  { 0x9a00, 0x2640, 0x3000 },
  { 0x9a00, 0x263e, 0x2000 },
  { 0x1a00, 0x263d, 0x0000 },
  { 0x1a00, 0x263f, 0x0000 },
  { 0x9a00, 0x2642, 0x2000 },
  { 0x1a00, 0x2641, 0x0000 },
  { 0x1a00, 0x2643, 0x0000 },
  { 0x9a00, 0x2648, 0x3000 },
  { 0x9a00, 0x2646, 0x2000 },
  { 0x1a00, 0x2645, 0x0000 },
  { 0x1a00, 0x2647, 0x0000 },
  { 0x9a00, 0x264a, 0x2000 },
  { 0x1a00, 0x2649, 0x0000 },
  { 0x1a00, 0x264b, 0x0000 },
  { 0x9a00, 0x266c, 0x6000 },
  { 0x9a00, 0x265c, 0x5000 },
  { 0x9a00, 0x2654, 0x4000 },
  { 0x9a00, 0x2650, 0x3000 },
  { 0x9a00, 0x264e, 0x2000 },
  { 0x1a00, 0x264d, 0x0000 },
  { 0x1a00, 0x264f, 0x0000 },
  { 0x9a00, 0x2652, 0x2000 },
  { 0x1a00, 0x2651, 0x0000 },
  { 0x1a00, 0x2653, 0x0000 },
  { 0x9a00, 0x2658, 0x3000 },
  { 0x9a00, 0x2656, 0x2000 },
  { 0x1a00, 0x2655, 0x0000 },
  { 0x1a00, 0x2657, 0x0000 },
  { 0x9a00, 0x265a, 0x2000 },
  { 0x1a00, 0x2659, 0x0000 },
  { 0x1a00, 0x265b, 0x0000 },
  { 0x9a00, 0x2664, 0x4000 },
  { 0x9a00, 0x2660, 0x3000 },
  { 0x9a00, 0x265e, 0x2000 },
  { 0x1a00, 0x265d, 0x0000 },
  { 0x1a00, 0x265f, 0x0000 },
  { 0x9a00, 0x2662, 0x2000 },
  { 0x1a00, 0x2661, 0x0000 },
  { 0x1a00, 0x2663, 0x0000 },
  { 0x9a00, 0x2668, 0x3000 },
  { 0x9a00, 0x2666, 0x2000 },
  { 0x1a00, 0x2665, 0x0000 },
  { 0x1a00, 0x2667, 0x0000 },
  { 0x9a00, 0x266a, 0x2000 },
  { 0x1a00, 0x2669, 0x0000 },
  { 0x1a00, 0x266b, 0x0000 },
  { 0x9a00, 0x267c, 0x5000 },
  { 0x9a00, 0x2674, 0x4000 },
  { 0x9a00, 0x2670, 0x3000 },
  { 0x9a00, 0x266e, 0x2000 },
  { 0x1a00, 0x266d, 0x0000 },
  { 0x1900, 0x266f, 0x0000 },
  { 0x9a00, 0x2672, 0x2000 },
  { 0x1a00, 0x2671, 0x0000 },
  { 0x1a00, 0x2673, 0x0000 },
  { 0x9a00, 0x2678, 0x3000 },
  { 0x9a00, 0x2676, 0x2000 },
  { 0x1a00, 0x2675, 0x0000 },
  { 0x1a00, 0x2677, 0x0000 },
  { 0x9a00, 0x267a, 0x2000 },
  { 0x1a00, 0x2679, 0x0000 },
  { 0x1a00, 0x267b, 0x0000 },
  { 0x9a00, 0x2686, 0x4000 },
  { 0x9a00, 0x2682, 0x3000 },
  { 0x9a00, 0x2680, 0x2000 },
  { 0x1a00, 0x267d, 0x0000 },
  { 0x1a00, 0x2681, 0x0000 },
  { 0x9a00, 0x2684, 0x2000 },
  { 0x1a00, 0x2683, 0x0000 },
  { 0x1a00, 0x2685, 0x0000 },
  { 0x9a00, 0x268a, 0x3000 },
  { 0x9a00, 0x2688, 0x2000 },
  { 0x1a00, 0x2687, 0x0000 },
  { 0x1a00, 0x2689, 0x0000 },
  { 0x9a00, 0x268c, 0x2000 },
  { 0x1a00, 0x268b, 0x0000 },
  { 0x1a00, 0x268d, 0x0000 },
  { 0x9a00, 0x273f, 0x7000 },
  { 0x9a00, 0x271e, 0x6000 },
  { 0x9a00, 0x270e, 0x5000 },
  { 0x9a00, 0x2703, 0x4000 },
  { 0x9a00, 0x26a0, 0x3000 },
  { 0x9a00, 0x2690, 0x2000 },
  { 0x1a00, 0x268f, 0x0000 },
  { 0x1a00, 0x2691, 0x0000 },
  { 0x9a00, 0x2701, 0x2000 },
  { 0x1a00, 0x26a1, 0x0000 },
  { 0x1a00, 0x2702, 0x0000 },
  { 0x9a00, 0x2708, 0x3000 },
  { 0x9a00, 0x2706, 0x2000 },
  { 0x1a00, 0x2704, 0x0000 },
  { 0x1a00, 0x2707, 0x0000 },
  { 0x9a00, 0x270c, 0x2000 },
  { 0x1a00, 0x2709, 0x0000 },
  { 0x1a00, 0x270d, 0x0000 },
  { 0x9a00, 0x2716, 0x4000 },
  { 0x9a00, 0x2712, 0x3000 },
  { 0x9a00, 0x2710, 0x2000 },
  { 0x1a00, 0x270f, 0x0000 },
  { 0x1a00, 0x2711, 0x0000 },
  { 0x9a00, 0x2714, 0x2000 },
  { 0x1a00, 0x2713, 0x0000 },
  { 0x1a00, 0x2715, 0x0000 },
  { 0x9a00, 0x271a, 0x3000 },
  { 0x9a00, 0x2718, 0x2000 },
  { 0x1a00, 0x2717, 0x0000 },
  { 0x1a00, 0x2719, 0x0000 },
  { 0x9a00, 0x271c, 0x2000 },
  { 0x1a00, 0x271b, 0x0000 },
  { 0x1a00, 0x271d, 0x0000 },
  { 0x9a00, 0x272f, 0x5000 },
  { 0x9a00, 0x2726, 0x4000 },
  { 0x9a00, 0x2722, 0x3000 },
  { 0x9a00, 0x2720, 0x2000 },
  { 0x1a00, 0x271f, 0x0000 },
  { 0x1a00, 0x2721, 0x0000 },
  { 0x9a00, 0x2724, 0x2000 },
  { 0x1a00, 0x2723, 0x0000 },
  { 0x1a00, 0x2725, 0x0000 },
  { 0x9a00, 0x272b, 0x3000 },
  { 0x9a00, 0x2729, 0x2000 },
  { 0x1a00, 0x2727, 0x0000 },
  { 0x1a00, 0x272a, 0x0000 },
  { 0x9a00, 0x272d, 0x2000 },
  { 0x1a00, 0x272c, 0x0000 },
  { 0x1a00, 0x272e, 0x0000 },
  { 0x9a00, 0x2737, 0x4000 },
  { 0x9a00, 0x2733, 0x3000 },
  { 0x9a00, 0x2731, 0x2000 },
  { 0x1a00, 0x2730, 0x0000 },
  { 0x1a00, 0x2732, 0x0000 },
  { 0x9a00, 0x2735, 0x2000 },
  { 0x1a00, 0x2734, 0x0000 },
  { 0x1a00, 0x2736, 0x0000 },
  { 0x9a00, 0x273b, 0x3000 },
  { 0x9a00, 0x2739, 0x2000 },
  { 0x1a00, 0x2738, 0x0000 },
  { 0x1a00, 0x273a, 0x0000 },
  { 0x9a00, 0x273d, 0x2000 },
  { 0x1a00, 0x273c, 0x0000 },
  { 0x1a00, 0x273e, 0x0000 },
  { 0x9a00, 0x2767, 0x6000 },
  { 0x9a00, 0x2751, 0x5000 },
  { 0x9a00, 0x2747, 0x4000 },
  { 0x9a00, 0x2743, 0x3000 },
  { 0x9a00, 0x2741, 0x2000 },
  { 0x1a00, 0x2740, 0x0000 },
  { 0x1a00, 0x2742, 0x0000 },
  { 0x9a00, 0x2745, 0x2000 },
  { 0x1a00, 0x2744, 0x0000 },
  { 0x1a00, 0x2746, 0x0000 },
  { 0x9a00, 0x274b, 0x3000 },
  { 0x9a00, 0x2749, 0x2000 },
  { 0x1a00, 0x2748, 0x0000 },
  { 0x1a00, 0x274a, 0x0000 },
  { 0x9a00, 0x274f, 0x2000 },
  { 0x1a00, 0x274d, 0x0000 },
  { 0x1a00, 0x2750, 0x0000 },
  { 0x9a00, 0x275d, 0x4000 },
  { 0x9a00, 0x2759, 0x3000 },
  { 0x9a00, 0x2756, 0x2000 },
  { 0x1a00, 0x2752, 0x0000 },
  { 0x1a00, 0x2758, 0x0000 },
  { 0x9a00, 0x275b, 0x2000 },
  { 0x1a00, 0x275a, 0x0000 },
  { 0x1a00, 0x275c, 0x0000 },
  { 0x9a00, 0x2763, 0x3000 },
  { 0x9a00, 0x2761, 0x2000 },
  { 0x1a00, 0x275e, 0x0000 },
  { 0x1a00, 0x2762, 0x0000 },
  { 0x9a00, 0x2765, 0x2000 },
  { 0x1a00, 0x2764, 0x0000 },
  { 0x1a00, 0x2766, 0x0000 },
  { 0x8f00, 0x2777, 0x5000 },
  { 0x9200, 0x276f, 0x4000 },
  { 0x9200, 0x276b, 0x3000 },
  { 0x9200, 0x2769, 0x2000 },
  { 0x1600, 0x2768, 0x0000 },
  { 0x1600, 0x276a, 0x0000 },
  { 0x9200, 0x276d, 0x2000 },
  { 0x1600, 0x276c, 0x0000 },
  { 0x1600, 0x276e, 0x0000 },
  { 0x9200, 0x2773, 0x3000 },
  { 0x9200, 0x2771, 0x2000 },
  { 0x1600, 0x2770, 0x0000 },
  { 0x1600, 0x2772, 0x0000 },
  { 0x9200, 0x2775, 0x2000 },
  { 0x1600, 0x2774, 0x0000 },
  { 0x0f00, 0x2776, 0x0000 },
  { 0x8f00, 0x277f, 0x4000 },
  { 0x8f00, 0x277b, 0x3000 },
  { 0x8f00, 0x2779, 0x2000 },
  { 0x0f00, 0x2778, 0x0000 },
  { 0x0f00, 0x277a, 0x0000 },
  { 0x8f00, 0x277d, 0x2000 },
  { 0x0f00, 0x277c, 0x0000 },
  { 0x0f00, 0x277e, 0x0000 },
  { 0x8f00, 0x2783, 0x3000 },
  { 0x8f00, 0x2781, 0x2000 },
  { 0x0f00, 0x2780, 0x0000 },
  { 0x0f00, 0x2782, 0x0000 },
  { 0x8f00, 0x2785, 0x2000 },
  { 0x0f00, 0x2784, 0x0000 },
  { 0x0f00, 0x2786, 0x0000 },
  { 0x9900, 0x29a0, 0xa000 },
  { 0x9a00, 0x28a0, 0x9000 },
  { 0x9a00, 0x2820, 0x8000 },
  { 0x9900, 0x27dc, 0x7000 },
  { 0x9a00, 0x27aa, 0x6000 },
  { 0x9a00, 0x279a, 0x5000 },
  { 0x8f00, 0x278f, 0x4000 },
  { 0x8f00, 0x278b, 0x3000 },
  { 0x8f00, 0x2789, 0x2000 },
  { 0x0f00, 0x2788, 0x0000 },
  { 0x0f00, 0x278a, 0x0000 },
  { 0x8f00, 0x278d, 0x2000 },
  { 0x0f00, 0x278c, 0x0000 },
  { 0x0f00, 0x278e, 0x0000 },
  { 0x8f00, 0x2793, 0x3000 },
  { 0x8f00, 0x2791, 0x2000 },
  { 0x0f00, 0x2790, 0x0000 },
  { 0x0f00, 0x2792, 0x0000 },
  { 0x9a00, 0x2798, 0x2000 },
  { 0x1a00, 0x2794, 0x0000 },
  { 0x1a00, 0x2799, 0x0000 },
  { 0x9a00, 0x27a2, 0x4000 },
  { 0x9a00, 0x279e, 0x3000 },
  { 0x9a00, 0x279c, 0x2000 },
  { 0x1a00, 0x279b, 0x0000 },
  { 0x1a00, 0x279d, 0x0000 },
  { 0x9a00, 0x27a0, 0x2000 },
  { 0x1a00, 0x279f, 0x0000 },
  { 0x1a00, 0x27a1, 0x0000 },
  { 0x9a00, 0x27a6, 0x3000 },
  { 0x9a00, 0x27a4, 0x2000 },
  { 0x1a00, 0x27a3, 0x0000 },
  { 0x1a00, 0x27a5, 0x0000 },
  { 0x9a00, 0x27a8, 0x2000 },
  { 0x1a00, 0x27a7, 0x0000 },
  { 0x1a00, 0x27a9, 0x0000 },
  { 0x9a00, 0x27bb, 0x5000 },
  { 0x9a00, 0x27b3, 0x4000 },
  { 0x9a00, 0x27ae, 0x3000 },
  { 0x9a00, 0x27ac, 0x2000 },
  { 0x1a00, 0x27ab, 0x0000 },
  { 0x1a00, 0x27ad, 0x0000 },
  { 0x9a00, 0x27b1, 0x2000 },
  { 0x1a00, 0x27af, 0x0000 },
  { 0x1a00, 0x27b2, 0x0000 },
  { 0x9a00, 0x27b7, 0x3000 },
  { 0x9a00, 0x27b5, 0x2000 },
  { 0x1a00, 0x27b4, 0x0000 },
  { 0x1a00, 0x27b6, 0x0000 },
  { 0x9a00, 0x27b9, 0x2000 },
  { 0x1a00, 0x27b8, 0x0000 },
  { 0x1a00, 0x27ba, 0x0000 },
  { 0x9900, 0x27d4, 0x4000 },
  { 0x9900, 0x27d0, 0x3000 },
  { 0x9a00, 0x27bd, 0x2000 },
  { 0x1a00, 0x27bc, 0x0000 },
  { 0x1a00, 0x27be, 0x0000 },
  { 0x9900, 0x27d2, 0x2000 },
  { 0x1900, 0x27d1, 0x0000 },
  { 0x1900, 0x27d3, 0x0000 },
  { 0x9900, 0x27d8, 0x3000 },
  { 0x9900, 0x27d6, 0x2000 },
  { 0x1900, 0x27d5, 0x0000 },
  { 0x1900, 0x27d7, 0x0000 },
  { 0x9900, 0x27da, 0x2000 },
  { 0x1900, 0x27d9, 0x0000 },
  { 0x1900, 0x27db, 0x0000 },
  { 0x9a00, 0x2800, 0x6000 },
  { 0x9900, 0x27f0, 0x5000 },
  { 0x9900, 0x27e4, 0x4000 },
  { 0x9900, 0x27e0, 0x3000 },
  { 0x9900, 0x27de, 0x2000 },
  { 0x1900, 0x27dd, 0x0000 },
  { 0x1900, 0x27df, 0x0000 },
  { 0x9900, 0x27e2, 0x2000 },
  { 0x1900, 0x27e1, 0x0000 },
  { 0x1900, 0x27e3, 0x0000 },
  { 0x9600, 0x27e8, 0x3000 },
  { 0x9600, 0x27e6, 0x2000 },
  { 0x1900, 0x27e5, 0x0000 },
  { 0x1200, 0x27e7, 0x0000 },
  { 0x9600, 0x27ea, 0x2000 },
  { 0x1200, 0x27e9, 0x0000 },
  { 0x1200, 0x27eb, 0x0000 },
  { 0x9900, 0x27f8, 0x4000 },
  { 0x9900, 0x27f4, 0x3000 },
  { 0x9900, 0x27f2, 0x2000 },
  { 0x1900, 0x27f1, 0x0000 },
  { 0x1900, 0x27f3, 0x0000 },
  { 0x9900, 0x27f6, 0x2000 },
  { 0x1900, 0x27f5, 0x0000 },
  { 0x1900, 0x27f7, 0x0000 },
  { 0x9900, 0x27fc, 0x3000 },
  { 0x9900, 0x27fa, 0x2000 },
  { 0x1900, 0x27f9, 0x0000 },
  { 0x1900, 0x27fb, 0x0000 },
  { 0x9900, 0x27fe, 0x2000 },
  { 0x1900, 0x27fd, 0x0000 },
  { 0x1900, 0x27ff, 0x0000 },
  { 0x9a00, 0x2810, 0x5000 },
  { 0x9a00, 0x2808, 0x4000 },
  { 0x9a00, 0x2804, 0x3000 },
  { 0x9a00, 0x2802, 0x2000 },
  { 0x1a00, 0x2801, 0x0000 },
  { 0x1a00, 0x2803, 0x0000 },
  { 0x9a00, 0x2806, 0x2000 },
  { 0x1a00, 0x2805, 0x0000 },
  { 0x1a00, 0x2807, 0x0000 },
  { 0x9a00, 0x280c, 0x3000 },
  { 0x9a00, 0x280a, 0x2000 },
  { 0x1a00, 0x2809, 0x0000 },
  { 0x1a00, 0x280b, 0x0000 },
  { 0x9a00, 0x280e, 0x2000 },
  { 0x1a00, 0x280d, 0x0000 },
  { 0x1a00, 0x280f, 0x0000 },
  { 0x9a00, 0x2818, 0x4000 },
  { 0x9a00, 0x2814, 0x3000 },
  { 0x9a00, 0x2812, 0x2000 },
  { 0x1a00, 0x2811, 0x0000 },
  { 0x1a00, 0x2813, 0x0000 },
  { 0x9a00, 0x2816, 0x2000 },
  { 0x1a00, 0x2815, 0x0000 },
  { 0x1a00, 0x2817, 0x0000 },
  { 0x9a00, 0x281c, 0x3000 },
  { 0x9a00, 0x281a, 0x2000 },
  { 0x1a00, 0x2819, 0x0000 },
  { 0x1a00, 0x281b, 0x0000 },
  { 0x9a00, 0x281e, 0x2000 },
  { 0x1a00, 0x281d, 0x0000 },
  { 0x1a00, 0x281f, 0x0000 },
  { 0x9a00, 0x2860, 0x7000 },
  { 0x9a00, 0x2840, 0x6000 },
  { 0x9a00, 0x2830, 0x5000 },
  { 0x9a00, 0x2828, 0x4000 },
  { 0x9a00, 0x2824, 0x3000 },
  { 0x9a00, 0x2822, 0x2000 },
  { 0x1a00, 0x2821, 0x0000 },
  { 0x1a00, 0x2823, 0x0000 },
  { 0x9a00, 0x2826, 0x2000 },
  { 0x1a00, 0x2825, 0x0000 },
  { 0x1a00, 0x2827, 0x0000 },
  { 0x9a00, 0x282c, 0x3000 },
  { 0x9a00, 0x282a, 0x2000 },
  { 0x1a00, 0x2829, 0x0000 },
  { 0x1a00, 0x282b, 0x0000 },
  { 0x9a00, 0x282e, 0x2000 },
  { 0x1a00, 0x282d, 0x0000 },
  { 0x1a00, 0x282f, 0x0000 },
  { 0x9a00, 0x2838, 0x4000 },
  { 0x9a00, 0x2834, 0x3000 },
  { 0x9a00, 0x2832, 0x2000 },
  { 0x1a00, 0x2831, 0x0000 },
  { 0x1a00, 0x2833, 0x0000 },
  { 0x9a00, 0x2836, 0x2000 },
  { 0x1a00, 0x2835, 0x0000 },
  { 0x1a00, 0x2837, 0x0000 },
  { 0x9a00, 0x283c, 0x3000 },
  { 0x9a00, 0x283a, 0x2000 },
  { 0x1a00, 0x2839, 0x0000 },
  { 0x1a00, 0x283b, 0x0000 },
  { 0x9a00, 0x283e, 0x2000 },
  { 0x1a00, 0x283d, 0x0000 },
  { 0x1a00, 0x283f, 0x0000 },
  { 0x9a00, 0x2850, 0x5000 },
  { 0x9a00, 0x2848, 0x4000 },
  { 0x9a00, 0x2844, 0x3000 },
  { 0x9a00, 0x2842, 0x2000 },
  { 0x1a00, 0x2841, 0x0000 },
  { 0x1a00, 0x2843, 0x0000 },
  { 0x9a00, 0x2846, 0x2000 },
  { 0x1a00, 0x2845, 0x0000 },
  { 0x1a00, 0x2847, 0x0000 },
  { 0x9a00, 0x284c, 0x3000 },
  { 0x9a00, 0x284a, 0x2000 },
  { 0x1a00, 0x2849, 0x0000 },
  { 0x1a00, 0x284b, 0x0000 },
  { 0x9a00, 0x284e, 0x2000 },
  { 0x1a00, 0x284d, 0x0000 },
  { 0x1a00, 0x284f, 0x0000 },
  { 0x9a00, 0x2858, 0x4000 },
  { 0x9a00, 0x2854, 0x3000 },
  { 0x9a00, 0x2852, 0x2000 },
  { 0x1a00, 0x2851, 0x0000 },
  { 0x1a00, 0x2853, 0x0000 },
  { 0x9a00, 0x2856, 0x2000 },
  { 0x1a00, 0x2855, 0x0000 },
  { 0x1a00, 0x2857, 0x0000 },
  { 0x9a00, 0x285c, 0x3000 },
  { 0x9a00, 0x285a, 0x2000 },
  { 0x1a00, 0x2859, 0x0000 },
  { 0x1a00, 0x285b, 0x0000 },
  { 0x9a00, 0x285e, 0x2000 },
  { 0x1a00, 0x285d, 0x0000 },
  { 0x1a00, 0x285f, 0x0000 },
  { 0x9a00, 0x2880, 0x6000 },
  { 0x9a00, 0x2870, 0x5000 },
  { 0x9a00, 0x2868, 0x4000 },
  { 0x9a00, 0x2864, 0x3000 },
  { 0x9a00, 0x2862, 0x2000 },
  { 0x1a00, 0x2861, 0x0000 },
  { 0x1a00, 0x2863, 0x0000 },
  { 0x9a00, 0x2866, 0x2000 },
  { 0x1a00, 0x2865, 0x0000 },
  { 0x1a00, 0x2867, 0x0000 },
  { 0x9a00, 0x286c, 0x3000 },
  { 0x9a00, 0x286a, 0x2000 },
  { 0x1a00, 0x2869, 0x0000 },
  { 0x1a00, 0x286b, 0x0000 },
  { 0x9a00, 0x286e, 0x2000 },
  { 0x1a00, 0x286d, 0x0000 },
  { 0x1a00, 0x286f, 0x0000 },
  { 0x9a00, 0x2878, 0x4000 },
  { 0x9a00, 0x2874, 0x3000 },
  { 0x9a00, 0x2872, 0x2000 },
  { 0x1a00, 0x2871, 0x0000 },
  { 0x1a00, 0x2873, 0x0000 },
  { 0x9a00, 0x2876, 0x2000 },
  { 0x1a00, 0x2875, 0x0000 },
  { 0x1a00, 0x2877, 0x0000 },
  { 0x9a00, 0x287c, 0x3000 },
  { 0x9a00, 0x287a, 0x2000 },
  { 0x1a00, 0x2879, 0x0000 },
  { 0x1a00, 0x287b, 0x0000 },
  { 0x9a00, 0x287e, 0x2000 },
  { 0x1a00, 0x287d, 0x0000 },
  { 0x1a00, 0x287f, 0x0000 },
  { 0x9a00, 0x2890, 0x5000 },
  { 0x9a00, 0x2888, 0x4000 },
  { 0x9a00, 0x2884, 0x3000 },
  { 0x9a00, 0x2882, 0x2000 },
  { 0x1a00, 0x2881, 0x0000 },
  { 0x1a00, 0x2883, 0x0000 },
  { 0x9a00, 0x2886, 0x2000 },
  { 0x1a00, 0x2885, 0x0000 },
  { 0x1a00, 0x2887, 0x0000 },
  { 0x9a00, 0x288c, 0x3000 },
  { 0x9a00, 0x288a, 0x2000 },
  { 0x1a00, 0x2889, 0x0000 },
  { 0x1a00, 0x288b, 0x0000 },
  { 0x9a00, 0x288e, 0x2000 },
  { 0x1a00, 0x288d, 0x0000 },
  { 0x1a00, 0x288f, 0x0000 },
  { 0x9a00, 0x2898, 0x4000 },
  { 0x9a00, 0x2894, 0x3000 },
  { 0x9a00, 0x2892, 0x2000 },
  { 0x1a00, 0x2891, 0x0000 },
  { 0x1a00, 0x2893, 0x0000 },
  { 0x9a00, 0x2896, 0x2000 },
  { 0x1a00, 0x2895, 0x0000 },
  { 0x1a00, 0x2897, 0x0000 },
  { 0x9a00, 0x289c, 0x3000 },
  { 0x9a00, 0x289a, 0x2000 },
  { 0x1a00, 0x2899, 0x0000 },
  { 0x1a00, 0x289b, 0x0000 },
  { 0x9a00, 0x289e, 0x2000 },
  { 0x1a00, 0x289d, 0x0000 },
  { 0x1a00, 0x289f, 0x0000 },
  { 0x9900, 0x2920, 0x8000 },
  { 0x9a00, 0x28e0, 0x7000 },
  { 0x9a00, 0x28c0, 0x6000 },
  { 0x9a00, 0x28b0, 0x5000 },
  { 0x9a00, 0x28a8, 0x4000 },
  { 0x9a00, 0x28a4, 0x3000 },
  { 0x9a00, 0x28a2, 0x2000 },
  { 0x1a00, 0x28a1, 0x0000 },
  { 0x1a00, 0x28a3, 0x0000 },
  { 0x9a00, 0x28a6, 0x2000 },
  { 0x1a00, 0x28a5, 0x0000 },
  { 0x1a00, 0x28a7, 0x0000 },
  { 0x9a00, 0x28ac, 0x3000 },
  { 0x9a00, 0x28aa, 0x2000 },
  { 0x1a00, 0x28a9, 0x0000 },
  { 0x1a00, 0x28ab, 0x0000 },
  { 0x9a00, 0x28ae, 0x2000 },
  { 0x1a00, 0x28ad, 0x0000 },
  { 0x1a00, 0x28af, 0x0000 },
  { 0x9a00, 0x28b8, 0x4000 },
  { 0x9a00, 0x28b4, 0x3000 },
  { 0x9a00, 0x28b2, 0x2000 },
  { 0x1a00, 0x28b1, 0x0000 },
  { 0x1a00, 0x28b3, 0x0000 },
  { 0x9a00, 0x28b6, 0x2000 },
  { 0x1a00, 0x28b5, 0x0000 },
  { 0x1a00, 0x28b7, 0x0000 },
  { 0x9a00, 0x28bc, 0x3000 },
  { 0x9a00, 0x28ba, 0x2000 },
  { 0x1a00, 0x28b9, 0x0000 },
  { 0x1a00, 0x28bb, 0x0000 },
  { 0x9a00, 0x28be, 0x2000 },
  { 0x1a00, 0x28bd, 0x0000 },
  { 0x1a00, 0x28bf, 0x0000 },
  { 0x9a00, 0x28d0, 0x5000 },
  { 0x9a00, 0x28c8, 0x4000 },
  { 0x9a00, 0x28c4, 0x3000 },
  { 0x9a00, 0x28c2, 0x2000 },
  { 0x1a00, 0x28c1, 0x0000 },
  { 0x1a00, 0x28c3, 0x0000 },
  { 0x9a00, 0x28c6, 0x2000 },
  { 0x1a00, 0x28c5, 0x0000 },
  { 0x1a00, 0x28c7, 0x0000 },
  { 0x9a00, 0x28cc, 0x3000 },
  { 0x9a00, 0x28ca, 0x2000 },
  { 0x1a00, 0x28c9, 0x0000 },
  { 0x1a00, 0x28cb, 0x0000 },
  { 0x9a00, 0x28ce, 0x2000 },
  { 0x1a00, 0x28cd, 0x0000 },
  { 0x1a00, 0x28cf, 0x0000 },
  { 0x9a00, 0x28d8, 0x4000 },
  { 0x9a00, 0x28d4, 0x3000 },
  { 0x9a00, 0x28d2, 0x2000 },
  { 0x1a00, 0x28d1, 0x0000 },
  { 0x1a00, 0x28d3, 0x0000 },
  { 0x9a00, 0x28d6, 0x2000 },
  { 0x1a00, 0x28d5, 0x0000 },
  { 0x1a00, 0x28d7, 0x0000 },
  { 0x9a00, 0x28dc, 0x3000 },
  { 0x9a00, 0x28da, 0x2000 },
  { 0x1a00, 0x28d9, 0x0000 },
  { 0x1a00, 0x28db, 0x0000 },
  { 0x9a00, 0x28de, 0x2000 },
  { 0x1a00, 0x28dd, 0x0000 },
  { 0x1a00, 0x28df, 0x0000 },
  { 0x9900, 0x2900, 0x6000 },
  { 0x9a00, 0x28f0, 0x5000 },
  { 0x9a00, 0x28e8, 0x4000 },
  { 0x9a00, 0x28e4, 0x3000 },
  { 0x9a00, 0x28e2, 0x2000 },
  { 0x1a00, 0x28e1, 0x0000 },
  { 0x1a00, 0x28e3, 0x0000 },
  { 0x9a00, 0x28e6, 0x2000 },
  { 0x1a00, 0x28e5, 0x0000 },
  { 0x1a00, 0x28e7, 0x0000 },
  { 0x9a00, 0x28ec, 0x3000 },
  { 0x9a00, 0x28ea, 0x2000 },
  { 0x1a00, 0x28e9, 0x0000 },
  { 0x1a00, 0x28eb, 0x0000 },
  { 0x9a00, 0x28ee, 0x2000 },
  { 0x1a00, 0x28ed, 0x0000 },
  { 0x1a00, 0x28ef, 0x0000 },
  { 0x9a00, 0x28f8, 0x4000 },
  { 0x9a00, 0x28f4, 0x3000 },
  { 0x9a00, 0x28f2, 0x2000 },
  { 0x1a00, 0x28f1, 0x0000 },
  { 0x1a00, 0x28f3, 0x0000 },
  { 0x9a00, 0x28f6, 0x2000 },
  { 0x1a00, 0x28f5, 0x0000 },
  { 0x1a00, 0x28f7, 0x0000 },
  { 0x9a00, 0x28fc, 0x3000 },
  { 0x9a00, 0x28fa, 0x2000 },
  { 0x1a00, 0x28f9, 0x0000 },
  { 0x1a00, 0x28fb, 0x0000 },
  { 0x9a00, 0x28fe, 0x2000 },
  { 0x1a00, 0x28fd, 0x0000 },
  { 0x1a00, 0x28ff, 0x0000 },
  { 0x9900, 0x2910, 0x5000 },
  { 0x9900, 0x2908, 0x4000 },
  { 0x9900, 0x2904, 0x3000 },
  { 0x9900, 0x2902, 0x2000 },
  { 0x1900, 0x2901, 0x0000 },
  { 0x1900, 0x2903, 0x0000 },
  { 0x9900, 0x2906, 0x2000 },
  { 0x1900, 0x2905, 0x0000 },
  { 0x1900, 0x2907, 0x0000 },
  { 0x9900, 0x290c, 0x3000 },
  { 0x9900, 0x290a, 0x2000 },
  { 0x1900, 0x2909, 0x0000 },
  { 0x1900, 0x290b, 0x0000 },
  { 0x9900, 0x290e, 0x2000 },
  { 0x1900, 0x290d, 0x0000 },
  { 0x1900, 0x290f, 0x0000 },
  { 0x9900, 0x2918, 0x4000 },
  { 0x9900, 0x2914, 0x3000 },
  { 0x9900, 0x2912, 0x2000 },
  { 0x1900, 0x2911, 0x0000 },
  { 0x1900, 0x2913, 0x0000 },
  { 0x9900, 0x2916, 0x2000 },
  { 0x1900, 0x2915, 0x0000 },
  { 0x1900, 0x2917, 0x0000 },
  { 0x9900, 0x291c, 0x3000 },
  { 0x9900, 0x291a, 0x2000 },
  { 0x1900, 0x2919, 0x0000 },
  { 0x1900, 0x291b, 0x0000 },
  { 0x9900, 0x291e, 0x2000 },
  { 0x1900, 0x291d, 0x0000 },
  { 0x1900, 0x291f, 0x0000 },
  { 0x9900, 0x2960, 0x7000 },
  { 0x9900, 0x2940, 0x6000 },
  { 0x9900, 0x2930, 0x5000 },
  { 0x9900, 0x2928, 0x4000 },
  { 0x9900, 0x2924, 0x3000 },
  { 0x9900, 0x2922, 0x2000 },
  { 0x1900, 0x2921, 0x0000 },
  { 0x1900, 0x2923, 0x0000 },
  { 0x9900, 0x2926, 0x2000 },
  { 0x1900, 0x2925, 0x0000 },
  { 0x1900, 0x2927, 0x0000 },
  { 0x9900, 0x292c, 0x3000 },
  { 0x9900, 0x292a, 0x2000 },
  { 0x1900, 0x2929, 0x0000 },
  { 0x1900, 0x292b, 0x0000 },
  { 0x9900, 0x292e, 0x2000 },
  { 0x1900, 0x292d, 0x0000 },
  { 0x1900, 0x292f, 0x0000 },
  { 0x9900, 0x2938, 0x4000 },
  { 0x9900, 0x2934, 0x3000 },
  { 0x9900, 0x2932, 0x2000 },
  { 0x1900, 0x2931, 0x0000 },
  { 0x1900, 0x2933, 0x0000 },
  { 0x9900, 0x2936, 0x2000 },
  { 0x1900, 0x2935, 0x0000 },
  { 0x1900, 0x2937, 0x0000 },
  { 0x9900, 0x293c, 0x3000 },
  { 0x9900, 0x293a, 0x2000 },
  { 0x1900, 0x2939, 0x0000 },
  { 0x1900, 0x293b, 0x0000 },
  { 0x9900, 0x293e, 0x2000 },
  { 0x1900, 0x293d, 0x0000 },
  { 0x1900, 0x293f, 0x0000 },
  { 0x9900, 0x2950, 0x5000 },
  { 0x9900, 0x2948, 0x4000 },
  { 0x9900, 0x2944, 0x3000 },
  { 0x9900, 0x2942, 0x2000 },
  { 0x1900, 0x2941, 0x0000 },
  { 0x1900, 0x2943, 0x0000 },
  { 0x9900, 0x2946, 0x2000 },
  { 0x1900, 0x2945, 0x0000 },
  { 0x1900, 0x2947, 0x0000 },
  { 0x9900, 0x294c, 0x3000 },
  { 0x9900, 0x294a, 0x2000 },
  { 0x1900, 0x2949, 0x0000 },
  { 0x1900, 0x294b, 0x0000 },
  { 0x9900, 0x294e, 0x2000 },
  { 0x1900, 0x294d, 0x0000 },
  { 0x1900, 0x294f, 0x0000 },
  { 0x9900, 0x2958, 0x4000 },
  { 0x9900, 0x2954, 0x3000 },
  { 0x9900, 0x2952, 0x2000 },
  { 0x1900, 0x2951, 0x0000 },
  { 0x1900, 0x2953, 0x0000 },
  { 0x9900, 0x2956, 0x2000 },
  { 0x1900, 0x2955, 0x0000 },
  { 0x1900, 0x2957, 0x0000 },
  { 0x9900, 0x295c, 0x3000 },
  { 0x9900, 0x295a, 0x2000 },
  { 0x1900, 0x2959, 0x0000 },
  { 0x1900, 0x295b, 0x0000 },
  { 0x9900, 0x295e, 0x2000 },
  { 0x1900, 0x295d, 0x0000 },
  { 0x1900, 0x295f, 0x0000 },
  { 0x9900, 0x2980, 0x6000 },
  { 0x9900, 0x2970, 0x5000 },
  { 0x9900, 0x2968, 0x4000 },
  { 0x9900, 0x2964, 0x3000 },
  { 0x9900, 0x2962, 0x2000 },
  { 0x1900, 0x2961, 0x0000 },
  { 0x1900, 0x2963, 0x0000 },
  { 0x9900, 0x2966, 0x2000 },
  { 0x1900, 0x2965, 0x0000 },
  { 0x1900, 0x2967, 0x0000 },
  { 0x9900, 0x296c, 0x3000 },
  { 0x9900, 0x296a, 0x2000 },
  { 0x1900, 0x2969, 0x0000 },
  { 0x1900, 0x296b, 0x0000 },
  { 0x9900, 0x296e, 0x2000 },
  { 0x1900, 0x296d, 0x0000 },
  { 0x1900, 0x296f, 0x0000 },
  { 0x9900, 0x2978, 0x4000 },
  { 0x9900, 0x2974, 0x3000 },
  { 0x9900, 0x2972, 0x2000 },
  { 0x1900, 0x2971, 0x0000 },
  { 0x1900, 0x2973, 0x0000 },
  { 0x9900, 0x2976, 0x2000 },
  { 0x1900, 0x2975, 0x0000 },
  { 0x1900, 0x2977, 0x0000 },
  { 0x9900, 0x297c, 0x3000 },
  { 0x9900, 0x297a, 0x2000 },
  { 0x1900, 0x2979, 0x0000 },
  { 0x1900, 0x297b, 0x0000 },
  { 0x9900, 0x297e, 0x2000 },
  { 0x1900, 0x297d, 0x0000 },
  { 0x1900, 0x297f, 0x0000 },
  { 0x9200, 0x2990, 0x5000 },
  { 0x9200, 0x2988, 0x4000 },
  { 0x9200, 0x2984, 0x3000 },
  { 0x9900, 0x2982, 0x2000 },
  { 0x1900, 0x2981, 0x0000 },
  { 0x1600, 0x2983, 0x0000 },
  { 0x9200, 0x2986, 0x2000 },
  { 0x1600, 0x2985, 0x0000 },
  { 0x1600, 0x2987, 0x0000 },
  { 0x9200, 0x298c, 0x3000 },
  { 0x9200, 0x298a, 0x2000 },
  { 0x1600, 0x2989, 0x0000 },
  { 0x1600, 0x298b, 0x0000 },
  { 0x9200, 0x298e, 0x2000 },
  { 0x1600, 0x298d, 0x0000 },
  { 0x1600, 0x298f, 0x0000 },
  { 0x9200, 0x2998, 0x4000 },
  { 0x9200, 0x2994, 0x3000 },
  { 0x9200, 0x2992, 0x2000 },
  { 0x1600, 0x2991, 0x0000 },
  { 0x1600, 0x2993, 0x0000 },
  { 0x9200, 0x2996, 0x2000 },
  { 0x1600, 0x2995, 0x0000 },
  { 0x1600, 0x2997, 0x0000 },
  { 0x9900, 0x299c, 0x3000 },
  { 0x9900, 0x299a, 0x2000 },
  { 0x1900, 0x2999, 0x0000 },
  { 0x1900, 0x299b, 0x0000 },
  { 0x9900, 0x299e, 0x2000 },
  { 0x1900, 0x299d, 0x0000 },
  { 0x1900, 0x299f, 0x0000 },
  { 0x9900, 0x2aa0, 0x9000 },
  { 0x9900, 0x2a20, 0x8000 },
  { 0x9900, 0x29e0, 0x7000 },
  { 0x9900, 0x29c0, 0x6000 },
  { 0x9900, 0x29b0, 0x5000 },
  { 0x9900, 0x29a8, 0x4000 },
  { 0x9900, 0x29a4, 0x3000 },
  { 0x9900, 0x29a2, 0x2000 },
  { 0x1900, 0x29a1, 0x0000 },
  { 0x1900, 0x29a3, 0x0000 },
  { 0x9900, 0x29a6, 0x2000 },
  { 0x1900, 0x29a5, 0x0000 },
  { 0x1900, 0x29a7, 0x0000 },
  { 0x9900, 0x29ac, 0x3000 },
  { 0x9900, 0x29aa, 0x2000 },
  { 0x1900, 0x29a9, 0x0000 },
  { 0x1900, 0x29ab, 0x0000 },
  { 0x9900, 0x29ae, 0x2000 },
  { 0x1900, 0x29ad, 0x0000 },
  { 0x1900, 0x29af, 0x0000 },
  { 0x9900, 0x29b8, 0x4000 },
  { 0x9900, 0x29b4, 0x3000 },
  { 0x9900, 0x29b2, 0x2000 },
  { 0x1900, 0x29b1, 0x0000 },
  { 0x1900, 0x29b3, 0x0000 },
  { 0x9900, 0x29b6, 0x2000 },
  { 0x1900, 0x29b5, 0x0000 },
  { 0x1900, 0x29b7, 0x0000 },
  { 0x9900, 0x29bc, 0x3000 },
  { 0x9900, 0x29ba, 0x2000 },
  { 0x1900, 0x29b9, 0x0000 },
  { 0x1900, 0x29bb, 0x0000 },
  { 0x9900, 0x29be, 0x2000 },
  { 0x1900, 0x29bd, 0x0000 },
  { 0x1900, 0x29bf, 0x0000 },
  { 0x9900, 0x29d0, 0x5000 },
  { 0x9900, 0x29c8, 0x4000 },
  { 0x9900, 0x29c4, 0x3000 },
  { 0x9900, 0x29c2, 0x2000 },
  { 0x1900, 0x29c1, 0x0000 },
  { 0x1900, 0x29c3, 0x0000 },
  { 0x9900, 0x29c6, 0x2000 },
  { 0x1900, 0x29c5, 0x0000 },
  { 0x1900, 0x29c7, 0x0000 },
  { 0x9900, 0x29cc, 0x3000 },
  { 0x9900, 0x29ca, 0x2000 },
  { 0x1900, 0x29c9, 0x0000 },
  { 0x1900, 0x29cb, 0x0000 },
  { 0x9900, 0x29ce, 0x2000 },
  { 0x1900, 0x29cd, 0x0000 },
  { 0x1900, 0x29cf, 0x0000 },
  { 0x9600, 0x29d8, 0x4000 },
  { 0x9900, 0x29d4, 0x3000 },
  { 0x9900, 0x29d2, 0x2000 },
  { 0x1900, 0x29d1, 0x0000 },
  { 0x1900, 0x29d3, 0x0000 },
  { 0x9900, 0x29d6, 0x2000 },
  { 0x1900, 0x29d5, 0x0000 },
  { 0x1900, 0x29d7, 0x0000 },
  { 0x9900, 0x29dc, 0x3000 },
  { 0x9600, 0x29da, 0x2000 },
  { 0x1200, 0x29d9, 0x0000 },
  { 0x1200, 0x29db, 0x0000 },
  { 0x9900, 0x29de, 0x2000 },
  { 0x1900, 0x29dd, 0x0000 },
  { 0x1900, 0x29df, 0x0000 },
  { 0x9900, 0x2a00, 0x6000 },
  { 0x9900, 0x29f0, 0x5000 },
  { 0x9900, 0x29e8, 0x4000 },
  { 0x9900, 0x29e4, 0x3000 },
  { 0x9900, 0x29e2, 0x2000 },
  { 0x1900, 0x29e1, 0x0000 },
  { 0x1900, 0x29e3, 0x0000 },
  { 0x9900, 0x29e6, 0x2000 },
  { 0x1900, 0x29e5, 0x0000 },
  { 0x1900, 0x29e7, 0x0000 },
  { 0x9900, 0x29ec, 0x3000 },
  { 0x9900, 0x29ea, 0x2000 },
  { 0x1900, 0x29e9, 0x0000 },
  { 0x1900, 0x29eb, 0x0000 },
  { 0x9900, 0x29ee, 0x2000 },
  { 0x1900, 0x29ed, 0x0000 },
  { 0x1900, 0x29ef, 0x0000 },
  { 0x9900, 0x29f8, 0x4000 },
  { 0x9900, 0x29f4, 0x3000 },
  { 0x9900, 0x29f2, 0x2000 },
  { 0x1900, 0x29f1, 0x0000 },
  { 0x1900, 0x29f3, 0x0000 },
  { 0x9900, 0x29f6, 0x2000 },
  { 0x1900, 0x29f5, 0x0000 },
  { 0x1900, 0x29f7, 0x0000 },
  { 0x9600, 0x29fc, 0x3000 },
  { 0x9900, 0x29fa, 0x2000 },
  { 0x1900, 0x29f9, 0x0000 },
  { 0x1900, 0x29fb, 0x0000 },
  { 0x9900, 0x29fe, 0x2000 },
  { 0x1200, 0x29fd, 0x0000 },
  { 0x1900, 0x29ff, 0x0000 },
  { 0x9900, 0x2a10, 0x5000 },
  { 0x9900, 0x2a08, 0x4000 },
  { 0x9900, 0x2a04, 0x3000 },
  { 0x9900, 0x2a02, 0x2000 },
  { 0x1900, 0x2a01, 0x0000 },
  { 0x1900, 0x2a03, 0x0000 },
  { 0x9900, 0x2a06, 0x2000 },
  { 0x1900, 0x2a05, 0x0000 },
  { 0x1900, 0x2a07, 0x0000 },
  { 0x9900, 0x2a0c, 0x3000 },
  { 0x9900, 0x2a0a, 0x2000 },
  { 0x1900, 0x2a09, 0x0000 },
  { 0x1900, 0x2a0b, 0x0000 },
  { 0x9900, 0x2a0e, 0x2000 },
  { 0x1900, 0x2a0d, 0x0000 },
  { 0x1900, 0x2a0f, 0x0000 },
  { 0x9900, 0x2a18, 0x4000 },
  { 0x9900, 0x2a14, 0x3000 },
  { 0x9900, 0x2a12, 0x2000 },
  { 0x1900, 0x2a11, 0x0000 },
  { 0x1900, 0x2a13, 0x0000 },
  { 0x9900, 0x2a16, 0x2000 },
  { 0x1900, 0x2a15, 0x0000 },
  { 0x1900, 0x2a17, 0x0000 },
  { 0x9900, 0x2a1c, 0x3000 },
  { 0x9900, 0x2a1a, 0x2000 },
  { 0x1900, 0x2a19, 0x0000 },
  { 0x1900, 0x2a1b, 0x0000 },
  { 0x9900, 0x2a1e, 0x2000 },
  { 0x1900, 0x2a1d, 0x0000 },
  { 0x1900, 0x2a1f, 0x0000 },
  { 0x9900, 0x2a60, 0x7000 },
  { 0x9900, 0x2a40, 0x6000 },
  { 0x9900, 0x2a30, 0x5000 },
  { 0x9900, 0x2a28, 0x4000 },
  { 0x9900, 0x2a24, 0x3000 },
  { 0x9900, 0x2a22, 0x2000 },
  { 0x1900, 0x2a21, 0x0000 },
  { 0x1900, 0x2a23, 0x0000 },
  { 0x9900, 0x2a26, 0x2000 },
  { 0x1900, 0x2a25, 0x0000 },
  { 0x1900, 0x2a27, 0x0000 },
  { 0x9900, 0x2a2c, 0x3000 },
  { 0x9900, 0x2a2a, 0x2000 },
  { 0x1900, 0x2a29, 0x0000 },
  { 0x1900, 0x2a2b, 0x0000 },
  { 0x9900, 0x2a2e, 0x2000 },
  { 0x1900, 0x2a2d, 0x0000 },
  { 0x1900, 0x2a2f, 0x0000 },
  { 0x9900, 0x2a38, 0x4000 },
  { 0x9900, 0x2a34, 0x3000 },
  { 0x9900, 0x2a32, 0x2000 },
  { 0x1900, 0x2a31, 0x0000 },
  { 0x1900, 0x2a33, 0x0000 },
  { 0x9900, 0x2a36, 0x2000 },
  { 0x1900, 0x2a35, 0x0000 },
  { 0x1900, 0x2a37, 0x0000 },
  { 0x9900, 0x2a3c, 0x3000 },
  { 0x9900, 0x2a3a, 0x2000 },
  { 0x1900, 0x2a39, 0x0000 },
  { 0x1900, 0x2a3b, 0x0000 },
  { 0x9900, 0x2a3e, 0x2000 },
  { 0x1900, 0x2a3d, 0x0000 },
  { 0x1900, 0x2a3f, 0x0000 },
  { 0x9900, 0x2a50, 0x5000 },
  { 0x9900, 0x2a48, 0x4000 },
  { 0x9900, 0x2a44, 0x3000 },
  { 0x9900, 0x2a42, 0x2000 },
  { 0x1900, 0x2a41, 0x0000 },
  { 0x1900, 0x2a43, 0x0000 },
  { 0x9900, 0x2a46, 0x2000 },
  { 0x1900, 0x2a45, 0x0000 },
  { 0x1900, 0x2a47, 0x0000 },
  { 0x9900, 0x2a4c, 0x3000 },
  { 0x9900, 0x2a4a, 0x2000 },
  { 0x1900, 0x2a49, 0x0000 },
  { 0x1900, 0x2a4b, 0x0000 },
  { 0x9900, 0x2a4e, 0x2000 },
  { 0x1900, 0x2a4d, 0x0000 },
  { 0x1900, 0x2a4f, 0x0000 },
  { 0x9900, 0x2a58, 0x4000 },
  { 0x9900, 0x2a54, 0x3000 },
  { 0x9900, 0x2a52, 0x2000 },
  { 0x1900, 0x2a51, 0x0000 },
  { 0x1900, 0x2a53, 0x0000 },
  { 0x9900, 0x2a56, 0x2000 },
  { 0x1900, 0x2a55, 0x0000 },
  { 0x1900, 0x2a57, 0x0000 },
  { 0x9900, 0x2a5c, 0x3000 },
  { 0x9900, 0x2a5a, 0x2000 },
  { 0x1900, 0x2a59, 0x0000 },
  { 0x1900, 0x2a5b, 0x0000 },
  { 0x9900, 0x2a5e, 0x2000 },
  { 0x1900, 0x2a5d, 0x0000 },
  { 0x1900, 0x2a5f, 0x0000 },
  { 0x9900, 0x2a80, 0x6000 },
  { 0x9900, 0x2a70, 0x5000 },
  { 0x9900, 0x2a68, 0x4000 },
  { 0x9900, 0x2a64, 0x3000 },
  { 0x9900, 0x2a62, 0x2000 },
  { 0x1900, 0x2a61, 0x0000 },
  { 0x1900, 0x2a63, 0x0000 },
  { 0x9900, 0x2a66, 0x2000 },
  { 0x1900, 0x2a65, 0x0000 },
  { 0x1900, 0x2a67, 0x0000 },
  { 0x9900, 0x2a6c, 0x3000 },
  { 0x9900, 0x2a6a, 0x2000 },
  { 0x1900, 0x2a69, 0x0000 },
  { 0x1900, 0x2a6b, 0x0000 },
  { 0x9900, 0x2a6e, 0x2000 },
  { 0x1900, 0x2a6d, 0x0000 },
  { 0x1900, 0x2a6f, 0x0000 },
  { 0x9900, 0x2a78, 0x4000 },
  { 0x9900, 0x2a74, 0x3000 },
  { 0x9900, 0x2a72, 0x2000 },
  { 0x1900, 0x2a71, 0x0000 },
  { 0x1900, 0x2a73, 0x0000 },
  { 0x9900, 0x2a76, 0x2000 },
  { 0x1900, 0x2a75, 0x0000 },
  { 0x1900, 0x2a77, 0x0000 },
  { 0x9900, 0x2a7c, 0x3000 },
  { 0x9900, 0x2a7a, 0x2000 },
  { 0x1900, 0x2a79, 0x0000 },
  { 0x1900, 0x2a7b, 0x0000 },
  { 0x9900, 0x2a7e, 0x2000 },
  { 0x1900, 0x2a7d, 0x0000 },
  { 0x1900, 0x2a7f, 0x0000 },
  { 0x9900, 0x2a90, 0x5000 },
  { 0x9900, 0x2a88, 0x4000 },
  { 0x9900, 0x2a84, 0x3000 },
  { 0x9900, 0x2a82, 0x2000 },
  { 0x1900, 0x2a81, 0x0000 },
  { 0x1900, 0x2a83, 0x0000 },
  { 0x9900, 0x2a86, 0x2000 },
  { 0x1900, 0x2a85, 0x0000 },
  { 0x1900, 0x2a87, 0x0000 },
  { 0x9900, 0x2a8c, 0x3000 },
  { 0x9900, 0x2a8a, 0x2000 },
  { 0x1900, 0x2a89, 0x0000 },
  { 0x1900, 0x2a8b, 0x0000 },
  { 0x9900, 0x2a8e, 0x2000 },
  { 0x1900, 0x2a8d, 0x0000 },
  { 0x1900, 0x2a8f, 0x0000 },
  { 0x9900, 0x2a98, 0x4000 },
  { 0x9900, 0x2a94, 0x3000 },
  { 0x9900, 0x2a92, 0x2000 },
  { 0x1900, 0x2a91, 0x0000 },
  { 0x1900, 0x2a93, 0x0000 },
  { 0x9900, 0x2a96, 0x2000 },
  { 0x1900, 0x2a95, 0x0000 },
  { 0x1900, 0x2a97, 0x0000 },
  { 0x9900, 0x2a9c, 0x3000 },
  { 0x9900, 0x2a9a, 0x2000 },
  { 0x1900, 0x2a99, 0x0000 },
  { 0x1900, 0x2a9b, 0x0000 },
  { 0x9900, 0x2a9e, 0x2000 },
  { 0x1900, 0x2a9d, 0x0000 },
  { 0x1900, 0x2a9f, 0x0000 },
  { 0x9a00, 0x2e92, 0x8000 },
  { 0x9900, 0x2ae0, 0x7000 },
  { 0x9900, 0x2ac0, 0x6000 },
  { 0x9900, 0x2ab0, 0x5000 },
  { 0x9900, 0x2aa8, 0x4000 },
  { 0x9900, 0x2aa4, 0x3000 },
  { 0x9900, 0x2aa2, 0x2000 },
  { 0x1900, 0x2aa1, 0x0000 },
  { 0x1900, 0x2aa3, 0x0000 },
  { 0x9900, 0x2aa6, 0x2000 },
  { 0x1900, 0x2aa5, 0x0000 },
  { 0x1900, 0x2aa7, 0x0000 },
  { 0x9900, 0x2aac, 0x3000 },
  { 0x9900, 0x2aaa, 0x2000 },
  { 0x1900, 0x2aa9, 0x0000 },
  { 0x1900, 0x2aab, 0x0000 },
  { 0x9900, 0x2aae, 0x2000 },
  { 0x1900, 0x2aad, 0x0000 },
  { 0x1900, 0x2aaf, 0x0000 },
  { 0x9900, 0x2ab8, 0x4000 },
  { 0x9900, 0x2ab4, 0x3000 },
  { 0x9900, 0x2ab2, 0x2000 },
  { 0x1900, 0x2ab1, 0x0000 },
  { 0x1900, 0x2ab3, 0x0000 },
  { 0x9900, 0x2ab6, 0x2000 },
  { 0x1900, 0x2ab5, 0x0000 },
  { 0x1900, 0x2ab7, 0x0000 },
  { 0x9900, 0x2abc, 0x3000 },
  { 0x9900, 0x2aba, 0x2000 },
  { 0x1900, 0x2ab9, 0x0000 },
  { 0x1900, 0x2abb, 0x0000 },
  { 0x9900, 0x2abe, 0x2000 },
  { 0x1900, 0x2abd, 0x0000 },
  { 0x1900, 0x2abf, 0x0000 },
  { 0x9900, 0x2ad0, 0x5000 },
  { 0x9900, 0x2ac8, 0x4000 },
  { 0x9900, 0x2ac4, 0x3000 },
  { 0x9900, 0x2ac2, 0x2000 },
  { 0x1900, 0x2ac1, 0x0000 },
  { 0x1900, 0x2ac3, 0x0000 },
  { 0x9900, 0x2ac6, 0x2000 },
  { 0x1900, 0x2ac5, 0x0000 },
  { 0x1900, 0x2ac7, 0x0000 },
  { 0x9900, 0x2acc, 0x3000 },
  { 0x9900, 0x2aca, 0x2000 },
  { 0x1900, 0x2ac9, 0x0000 },
  { 0x1900, 0x2acb, 0x0000 },
  { 0x9900, 0x2ace, 0x2000 },
  { 0x1900, 0x2acd, 0x0000 },
  { 0x1900, 0x2acf, 0x0000 },
  { 0x9900, 0x2ad8, 0x4000 },
  { 0x9900, 0x2ad4, 0x3000 },
  { 0x9900, 0x2ad2, 0x2000 },
  { 0x1900, 0x2ad1, 0x0000 },
  { 0x1900, 0x2ad3, 0x0000 },
  { 0x9900, 0x2ad6, 0x2000 },
  { 0x1900, 0x2ad5, 0x0000 },
  { 0x1900, 0x2ad7, 0x0000 },
  { 0x9900, 0x2adc, 0x3000 },
  { 0x9900, 0x2ada, 0x2000 },
  { 0x1900, 0x2ad9, 0x0000 },
  { 0x1900, 0x2adb, 0x0000 },
  { 0x9900, 0x2ade, 0x2000 },
  { 0x1900, 0x2add, 0x0000 },
  { 0x1900, 0x2adf, 0x0000 },
  { 0x9a00, 0x2b00, 0x6000 },
  { 0x9900, 0x2af0, 0x5000 },
  { 0x9900, 0x2ae8, 0x4000 },
  { 0x9900, 0x2ae4, 0x3000 },
  { 0x9900, 0x2ae2, 0x2000 },
  { 0x1900, 0x2ae1, 0x0000 },
  { 0x1900, 0x2ae3, 0x0000 },
  { 0x9900, 0x2ae6, 0x2000 },
  { 0x1900, 0x2ae5, 0x0000 },
  { 0x1900, 0x2ae7, 0x0000 },
  { 0x9900, 0x2aec, 0x3000 },
  { 0x9900, 0x2aea, 0x2000 },
  { 0x1900, 0x2ae9, 0x0000 },
  { 0x1900, 0x2aeb, 0x0000 },
  { 0x9900, 0x2aee, 0x2000 },
  { 0x1900, 0x2aed, 0x0000 },
  { 0x1900, 0x2aef, 0x0000 },
  { 0x9900, 0x2af8, 0x4000 },
  { 0x9900, 0x2af4, 0x3000 },
  { 0x9900, 0x2af2, 0x2000 },
  { 0x1900, 0x2af1, 0x0000 },
  { 0x1900, 0x2af3, 0x0000 },
  { 0x9900, 0x2af6, 0x2000 },
  { 0x1900, 0x2af5, 0x0000 },
  { 0x1900, 0x2af7, 0x0000 },
  { 0x9900, 0x2afc, 0x3000 },
  { 0x9900, 0x2afa, 0x2000 },
  { 0x1900, 0x2af9, 0x0000 },
  { 0x1900, 0x2afb, 0x0000 },
  { 0x9900, 0x2afe, 0x2000 },
  { 0x1900, 0x2afd, 0x0000 },
  { 0x1900, 0x2aff, 0x0000 },
  { 0x9a00, 0x2e82, 0x5000 },
  { 0x9a00, 0x2b08, 0x4000 },
  { 0x9a00, 0x2b04, 0x3000 },
  { 0x9a00, 0x2b02, 0x2000 },
  { 0x1a00, 0x2b01, 0x0000 },
  { 0x1a00, 0x2b03, 0x0000 },
  { 0x9a00, 0x2b06, 0x2000 },
  { 0x1a00, 0x2b05, 0x0000 },
  { 0x1a00, 0x2b07, 0x0000 },
  { 0x9a00, 0x2b0c, 0x3000 },
  { 0x9a00, 0x2b0a, 0x2000 },
  { 0x1a00, 0x2b09, 0x0000 },
  { 0x1a00, 0x2b0b, 0x0000 },
  { 0x9a00, 0x2e80, 0x2000 },
  { 0x1a00, 0x2b0d, 0x0000 },
  { 0x1a00, 0x2e81, 0x0000 },
  { 0x9a00, 0x2e8a, 0x4000 },
  { 0x9a00, 0x2e86, 0x3000 },
  { 0x9a00, 0x2e84, 0x2000 },
  { 0x1a00, 0x2e83, 0x0000 },
  { 0x1a00, 0x2e85, 0x0000 },
  { 0x9a00, 0x2e88, 0x2000 },
  { 0x1a00, 0x2e87, 0x0000 },
  { 0x1a00, 0x2e89, 0x0000 },
  { 0x9a00, 0x2e8e, 0x3000 },
  { 0x9a00, 0x2e8c, 0x2000 },
  { 0x1a00, 0x2e8b, 0x0000 },
  { 0x1a00, 0x2e8d, 0x0000 },
  { 0x9a00, 0x2e90, 0x2000 },
  { 0x1a00, 0x2e8f, 0x0000 },
  { 0x1a00, 0x2e91, 0x0000 },
  { 0x9a00, 0x2ed3, 0x7000 },
  { 0x9a00, 0x2eb3, 0x6000 },
  { 0x9a00, 0x2ea3, 0x5000 },
  { 0x9a00, 0x2e9b, 0x4000 },
  { 0x9a00, 0x2e96, 0x3000 },
  { 0x9a00, 0x2e94, 0x2000 },
  { 0x1a00, 0x2e93, 0x0000 },
  { 0x1a00, 0x2e95, 0x0000 },
  { 0x9a00, 0x2e98, 0x2000 },
  { 0x1a00, 0x2e97, 0x0000 },
  { 0x1a00, 0x2e99, 0x0000 },
  { 0x9a00, 0x2e9f, 0x3000 },
  { 0x9a00, 0x2e9d, 0x2000 },
  { 0x1a00, 0x2e9c, 0x0000 },
  { 0x1a00, 0x2e9e, 0x0000 },
  { 0x9a00, 0x2ea1, 0x2000 },
  { 0x1a00, 0x2ea0, 0x0000 },
  { 0x1a00, 0x2ea2, 0x0000 },
  { 0x9a00, 0x2eab, 0x4000 },
  { 0x9a00, 0x2ea7, 0x3000 },
  { 0x9a00, 0x2ea5, 0x2000 },
  { 0x1a00, 0x2ea4, 0x0000 },
  { 0x1a00, 0x2ea6, 0x0000 },
  { 0x9a00, 0x2ea9, 0x2000 },
  { 0x1a00, 0x2ea8, 0x0000 },
  { 0x1a00, 0x2eaa, 0x0000 },
  { 0x9a00, 0x2eaf, 0x3000 },
  { 0x9a00, 0x2ead, 0x2000 },
  { 0x1a00, 0x2eac, 0x0000 },
  { 0x1a00, 0x2eae, 0x0000 },
  { 0x9a00, 0x2eb1, 0x2000 },
  { 0x1a00, 0x2eb0, 0x0000 },
  { 0x1a00, 0x2eb2, 0x0000 },
  { 0x9a00, 0x2ec3, 0x5000 },
  { 0x9a00, 0x2ebb, 0x4000 },
  { 0x9a00, 0x2eb7, 0x3000 },
  { 0x9a00, 0x2eb5, 0x2000 },
  { 0x1a00, 0x2eb4, 0x0000 },
  { 0x1a00, 0x2eb6, 0x0000 },
  { 0x9a00, 0x2eb9, 0x2000 },
  { 0x1a00, 0x2eb8, 0x0000 },
  { 0x1a00, 0x2eba, 0x0000 },
  { 0x9a00, 0x2ebf, 0x3000 },
  { 0x9a00, 0x2ebd, 0x2000 },
  { 0x1a00, 0x2ebc, 0x0000 },
  { 0x1a00, 0x2ebe, 0x0000 },
  { 0x9a00, 0x2ec1, 0x2000 },
  { 0x1a00, 0x2ec0, 0x0000 },
  { 0x1a00, 0x2ec2, 0x0000 },
  { 0x9a00, 0x2ecb, 0x4000 },
  { 0x9a00, 0x2ec7, 0x3000 },
  { 0x9a00, 0x2ec5, 0x2000 },
  { 0x1a00, 0x2ec4, 0x0000 },
  { 0x1a00, 0x2ec6, 0x0000 },
  { 0x9a00, 0x2ec9, 0x2000 },
  { 0x1a00, 0x2ec8, 0x0000 },
  { 0x1a00, 0x2eca, 0x0000 },
  { 0x9a00, 0x2ecf, 0x3000 },
  { 0x9a00, 0x2ecd, 0x2000 },
  { 0x1a00, 0x2ecc, 0x0000 },
  { 0x1a00, 0x2ece, 0x0000 },
  { 0x9a00, 0x2ed1, 0x2000 },
  { 0x1a00, 0x2ed0, 0x0000 },
  { 0x1a00, 0x2ed2, 0x0000 },
  { 0x9a00, 0x2ef3, 0x6000 },
  { 0x9a00, 0x2ee3, 0x5000 },
  { 0x9a00, 0x2edb, 0x4000 },
  { 0x9a00, 0x2ed7, 0x3000 },
  { 0x9a00, 0x2ed5, 0x2000 },
  { 0x1a00, 0x2ed4, 0x0000 },
  { 0x1a00, 0x2ed6, 0x0000 },
  { 0x9a00, 0x2ed9, 0x2000 },
  { 0x1a00, 0x2ed8, 0x0000 },
  { 0x1a00, 0x2eda, 0x0000 },
  { 0x9a00, 0x2edf, 0x3000 },
  { 0x9a00, 0x2edd, 0x2000 },
  { 0x1a00, 0x2edc, 0x0000 },
  { 0x1a00, 0x2ede, 0x0000 },
  { 0x9a00, 0x2ee1, 0x2000 },
  { 0x1a00, 0x2ee0, 0x0000 },
  { 0x1a00, 0x2ee2, 0x0000 },
  { 0x9a00, 0x2eeb, 0x4000 },
  { 0x9a00, 0x2ee7, 0x3000 },
  { 0x9a00, 0x2ee5, 0x2000 },
  { 0x1a00, 0x2ee4, 0x0000 },
  { 0x1a00, 0x2ee6, 0x0000 },
  { 0x9a00, 0x2ee9, 0x2000 },
  { 0x1a00, 0x2ee8, 0x0000 },
  { 0x1a00, 0x2eea, 0x0000 },
  { 0x9a00, 0x2eef, 0x3000 },
  { 0x9a00, 0x2eed, 0x2000 },
  { 0x1a00, 0x2eec, 0x0000 },
  { 0x1a00, 0x2eee, 0x0000 },
  { 0x9a00, 0x2ef1, 0x2000 },
  { 0x1a00, 0x2ef0, 0x0000 },
  { 0x1a00, 0x2ef2, 0x0000 },
  { 0x9a00, 0x2f0f, 0x5000 },
  { 0x9a00, 0x2f07, 0x4000 },
  { 0x9a00, 0x2f03, 0x3000 },
  { 0x9a00, 0x2f01, 0x2000 },
  { 0x1a00, 0x2f00, 0x0000 },
  { 0x1a00, 0x2f02, 0x0000 },
  { 0x9a00, 0x2f05, 0x2000 },
  { 0x1a00, 0x2f04, 0x0000 },
  { 0x1a00, 0x2f06, 0x0000 },
  { 0x9a00, 0x2f0b, 0x3000 },
  { 0x9a00, 0x2f09, 0x2000 },
  { 0x1a00, 0x2f08, 0x0000 },
  { 0x1a00, 0x2f0a, 0x0000 },
  { 0x9a00, 0x2f0d, 0x2000 },
  { 0x1a00, 0x2f0c, 0x0000 },
  { 0x1a00, 0x2f0e, 0x0000 },
  { 0x9a00, 0x2f17, 0x4000 },
  { 0x9a00, 0x2f13, 0x3000 },
  { 0x9a00, 0x2f11, 0x2000 },
  { 0x1a00, 0x2f10, 0x0000 },
  { 0x1a00, 0x2f12, 0x0000 },
  { 0x9a00, 0x2f15, 0x2000 },
  { 0x1a00, 0x2f14, 0x0000 },
  { 0x1a00, 0x2f16, 0x0000 },
  { 0x9a00, 0x2f1b, 0x3000 },
  { 0x9a00, 0x2f19, 0x2000 },
  { 0x1a00, 0x2f18, 0x0000 },
  { 0x1a00, 0x2f1a, 0x0000 },
  { 0x9a00, 0x2f1d, 0x2000 },
  { 0x1a00, 0x2f1c, 0x0000 },
  { 0x1a00, 0x2f1e, 0x0000 },
  { 0x8701, 0x00f0, 0xd000 },
  { 0x8700, 0xa34d, 0xc000 },
  { 0x9a00, 0x3391, 0xb000 },
  { 0x8700, 0x3149, 0xa000 },
  { 0x9500, 0x303d, 0x9000 },
  { 0x9a00, 0x2f9f, 0x8000 },
  { 0x9a00, 0x2f5f, 0x7000 },
  { 0x9a00, 0x2f3f, 0x6000 },
  { 0x9a00, 0x2f2f, 0x5000 },
  { 0x9a00, 0x2f27, 0x4000 },
  { 0x9a00, 0x2f23, 0x3000 },
  { 0x9a00, 0x2f21, 0x2000 },
  { 0x1a00, 0x2f20, 0x0000 },
  { 0x1a00, 0x2f22, 0x0000 },
  { 0x9a00, 0x2f25, 0x2000 },
  { 0x1a00, 0x2f24, 0x0000 },
  { 0x1a00, 0x2f26, 0x0000 },
  { 0x9a00, 0x2f2b, 0x3000 },
  { 0x9a00, 0x2f29, 0x2000 },
  { 0x1a00, 0x2f28, 0x0000 },
  { 0x1a00, 0x2f2a, 0x0000 },
  { 0x9a00, 0x2f2d, 0x2000 },
  { 0x1a00, 0x2f2c, 0x0000 },
  { 0x1a00, 0x2f2e, 0x0000 },
  { 0x9a00, 0x2f37, 0x4000 },
  { 0x9a00, 0x2f33, 0x3000 },
  { 0x9a00, 0x2f31, 0x2000 },
  { 0x1a00, 0x2f30, 0x0000 },
  { 0x1a00, 0x2f32, 0x0000 },
  { 0x9a00, 0x2f35, 0x2000 },
  { 0x1a00, 0x2f34, 0x0000 },
  { 0x1a00, 0x2f36, 0x0000 },
  { 0x9a00, 0x2f3b, 0x3000 },
  { 0x9a00, 0x2f39, 0x2000 },
  { 0x1a00, 0x2f38, 0x0000 },
  { 0x1a00, 0x2f3a, 0x0000 },
  { 0x9a00, 0x2f3d, 0x2000 },
  { 0x1a00, 0x2f3c, 0x0000 },
  { 0x1a00, 0x2f3e, 0x0000 },
  { 0x9a00, 0x2f4f, 0x5000 },
  { 0x9a00, 0x2f47, 0x4000 },
  { 0x9a00, 0x2f43, 0x3000 },
  { 0x9a00, 0x2f41, 0x2000 },
  { 0x1a00, 0x2f40, 0x0000 },
  { 0x1a00, 0x2f42, 0x0000 },
  { 0x9a00, 0x2f45, 0x2000 },
  { 0x1a00, 0x2f44, 0x0000 },
  { 0x1a00, 0x2f46, 0x0000 },
  { 0x9a00, 0x2f4b, 0x3000 },
  { 0x9a00, 0x2f49, 0x2000 },
  { 0x1a00, 0x2f48, 0x0000 },
  { 0x1a00, 0x2f4a, 0x0000 },
  { 0x9a00, 0x2f4d, 0x2000 },
  { 0x1a00, 0x2f4c, 0x0000 },
  { 0x1a00, 0x2f4e, 0x0000 },
  { 0x9a00, 0x2f57, 0x4000 },
  { 0x9a00, 0x2f53, 0x3000 },
  { 0x9a00, 0x2f51, 0x2000 },
  { 0x1a00, 0x2f50, 0x0000 },
  { 0x1a00, 0x2f52, 0x0000 },
  { 0x9a00, 0x2f55, 0x2000 },
  { 0x1a00, 0x2f54, 0x0000 },
  { 0x1a00, 0x2f56, 0x0000 },
  { 0x9a00, 0x2f5b, 0x3000 },
  { 0x9a00, 0x2f59, 0x2000 },
  { 0x1a00, 0x2f58, 0x0000 },
  { 0x1a00, 0x2f5a, 0x0000 },
  { 0x9a00, 0x2f5d, 0x2000 },
  { 0x1a00, 0x2f5c, 0x0000 },
  { 0x1a00, 0x2f5e, 0x0000 },
  { 0x9a00, 0x2f7f, 0x6000 },
  { 0x9a00, 0x2f6f, 0x5000 },
  { 0x9a00, 0x2f67, 0x4000 },
  { 0x9a00, 0x2f63, 0x3000 },
  { 0x9a00, 0x2f61, 0x2000 },
  { 0x1a00, 0x2f60, 0x0000 },
  { 0x1a00, 0x2f62, 0x0000 },
  { 0x9a00, 0x2f65, 0x2000 },
  { 0x1a00, 0x2f64, 0x0000 },
  { 0x1a00, 0x2f66, 0x0000 },
  { 0x9a00, 0x2f6b, 0x3000 },
  { 0x9a00, 0x2f69, 0x2000 },
  { 0x1a00, 0x2f68, 0x0000 },
  { 0x1a00, 0x2f6a, 0x0000 },
  { 0x9a00, 0x2f6d, 0x2000 },
  { 0x1a00, 0x2f6c, 0x0000 },
  { 0x1a00, 0x2f6e, 0x0000 },
  { 0x9a00, 0x2f77, 0x4000 },
  { 0x9a00, 0x2f73, 0x3000 },
  { 0x9a00, 0x2f71, 0x2000 },
  { 0x1a00, 0x2f70, 0x0000 },
  { 0x1a00, 0x2f72, 0x0000 },
  { 0x9a00, 0x2f75, 0x2000 },
  { 0x1a00, 0x2f74, 0x0000 },
  { 0x1a00, 0x2f76, 0x0000 },
  { 0x9a00, 0x2f7b, 0x3000 },
  { 0x9a00, 0x2f79, 0x2000 },
  { 0x1a00, 0x2f78, 0x0000 },
  { 0x1a00, 0x2f7a, 0x0000 },
  { 0x9a00, 0x2f7d, 0x2000 },
  { 0x1a00, 0x2f7c, 0x0000 },
  { 0x1a00, 0x2f7e, 0x0000 },
  { 0x9a00, 0x2f8f, 0x5000 },
  { 0x9a00, 0x2f87, 0x4000 },
  { 0x9a00, 0x2f83, 0x3000 },
  { 0x9a00, 0x2f81, 0x2000 },
  { 0x1a00, 0x2f80, 0x0000 },
  { 0x1a00, 0x2f82, 0x0000 },
  { 0x9a00, 0x2f85, 0x2000 },
  { 0x1a00, 0x2f84, 0x0000 },
  { 0x1a00, 0x2f86, 0x0000 },
  { 0x9a00, 0x2f8b, 0x3000 },
  { 0x9a00, 0x2f89, 0x2000 },
  { 0x1a00, 0x2f88, 0x0000 },
  { 0x1a00, 0x2f8a, 0x0000 },
  { 0x9a00, 0x2f8d, 0x2000 },
  { 0x1a00, 0x2f8c, 0x0000 },
  { 0x1a00, 0x2f8e, 0x0000 },
  { 0x9a00, 0x2f97, 0x4000 },
  { 0x9a00, 0x2f93, 0x3000 },
  { 0x9a00, 0x2f91, 0x2000 },
  { 0x1a00, 0x2f90, 0x0000 },
  { 0x1a00, 0x2f92, 0x0000 },
  { 0x9a00, 0x2f95, 0x2000 },
  { 0x1a00, 0x2f94, 0x0000 },
  { 0x1a00, 0x2f96, 0x0000 },
  { 0x9a00, 0x2f9b, 0x3000 },
  { 0x9a00, 0x2f99, 0x2000 },
  { 0x1a00, 0x2f98, 0x0000 },
  { 0x1a00, 0x2f9a, 0x0000 },
  { 0x9a00, 0x2f9d, 0x2000 },
  { 0x1a00, 0x2f9c, 0x0000 },
  { 0x1a00, 0x2f9e, 0x0000 },
  { 0x9a00, 0x2ff9, 0x7000 },
  { 0x9a00, 0x2fbf, 0x6000 },
  { 0x9a00, 0x2faf, 0x5000 },
  { 0x9a00, 0x2fa7, 0x4000 },
  { 0x9a00, 0x2fa3, 0x3000 },
  { 0x9a00, 0x2fa1, 0x2000 },
  { 0x1a00, 0x2fa0, 0x0000 },
  { 0x1a00, 0x2fa2, 0x0000 },
  { 0x9a00, 0x2fa5, 0x2000 },
  { 0x1a00, 0x2fa4, 0x0000 },
  { 0x1a00, 0x2fa6, 0x0000 },
  { 0x9a00, 0x2fab, 0x3000 },
  { 0x9a00, 0x2fa9, 0x2000 },
  { 0x1a00, 0x2fa8, 0x0000 },
  { 0x1a00, 0x2faa, 0x0000 },
  { 0x9a00, 0x2fad, 0x2000 },
  { 0x1a00, 0x2fac, 0x0000 },
  { 0x1a00, 0x2fae, 0x0000 },
  { 0x9a00, 0x2fb7, 0x4000 },
  { 0x9a00, 0x2fb3, 0x3000 },
  { 0x9a00, 0x2fb1, 0x2000 },
  { 0x1a00, 0x2fb0, 0x0000 },
  { 0x1a00, 0x2fb2, 0x0000 },
  { 0x9a00, 0x2fb5, 0x2000 },
  { 0x1a00, 0x2fb4, 0x0000 },
  { 0x1a00, 0x2fb6, 0x0000 },
  { 0x9a00, 0x2fbb, 0x3000 },
  { 0x9a00, 0x2fb9, 0x2000 },
  { 0x1a00, 0x2fb8, 0x0000 },
  { 0x1a00, 0x2fba, 0x0000 },
  { 0x9a00, 0x2fbd, 0x2000 },
  { 0x1a00, 0x2fbc, 0x0000 },
  { 0x1a00, 0x2fbe, 0x0000 },
  { 0x9a00, 0x2fcf, 0x5000 },
  { 0x9a00, 0x2fc7, 0x4000 },
  { 0x9a00, 0x2fc3, 0x3000 },
  { 0x9a00, 0x2fc1, 0x2000 },
  { 0x1a00, 0x2fc0, 0x0000 },
  { 0x1a00, 0x2fc2, 0x0000 },
  { 0x9a00, 0x2fc5, 0x2000 },
  { 0x1a00, 0x2fc4, 0x0000 },
  { 0x1a00, 0x2fc6, 0x0000 },
  { 0x9a00, 0x2fcb, 0x3000 },
  { 0x9a00, 0x2fc9, 0x2000 },
  { 0x1a00, 0x2fc8, 0x0000 },
  { 0x1a00, 0x2fca, 0x0000 },
  { 0x9a00, 0x2fcd, 0x2000 },
  { 0x1a00, 0x2fcc, 0x0000 },
  { 0x1a00, 0x2fce, 0x0000 },
  { 0x9a00, 0x2ff1, 0x4000 },
  { 0x9a00, 0x2fd3, 0x3000 },
  { 0x9a00, 0x2fd1, 0x2000 },
  { 0x1a00, 0x2fd0, 0x0000 },
  { 0x1a00, 0x2fd2, 0x0000 },
  { 0x9a00, 0x2fd5, 0x2000 },
  { 0x1a00, 0x2fd4, 0x0000 },
  { 0x1a00, 0x2ff0, 0x0000 },
  { 0x9a00, 0x2ff5, 0x3000 },
  { 0x9a00, 0x2ff3, 0x2000 },
  { 0x1a00, 0x2ff2, 0x0000 },
  { 0x1a00, 0x2ff4, 0x0000 },
  { 0x9a00, 0x2ff7, 0x2000 },
  { 0x1a00, 0x2ff6, 0x0000 },
  { 0x1a00, 0x2ff8, 0x0000 },
  { 0x9600, 0x301d, 0x6000 },
  { 0x9200, 0x300d, 0x5000 },
  { 0x8600, 0x3005, 0x4000 },
  { 0x9500, 0x3001, 0x3000 },
  { 0x9a00, 0x2ffb, 0x2000 },
  { 0x1a00, 0x2ffa, 0x0000 },
  { 0x1d00, 0x3000, 0x0000 },
  { 0x9500, 0x3003, 0x2000 },
  { 0x1500, 0x3002, 0x0000 },
  { 0x1a00, 0x3004, 0x0000 },
  { 0x9200, 0x3009, 0x3000 },
  { 0x8e00, 0x3007, 0x2000 },
  { 0x0700, 0x3006, 0x0000 },
  { 0x1600, 0x3008, 0x0000 },
  { 0x9200, 0x300b, 0x2000 },
  { 0x1600, 0x300a, 0x0000 },
  { 0x1600, 0x300c, 0x0000 },
  { 0x9200, 0x3015, 0x4000 },
  { 0x9200, 0x3011, 0x3000 },
  { 0x9200, 0x300f, 0x2000 },
  { 0x1600, 0x300e, 0x0000 },
  { 0x1600, 0x3010, 0x0000 },
  { 0x9a00, 0x3013, 0x2000 },
  { 0x1a00, 0x3012, 0x0000 },
  { 0x1600, 0x3014, 0x0000 },
  { 0x9200, 0x3019, 0x3000 },
  { 0x9200, 0x3017, 0x2000 },
  { 0x1600, 0x3016, 0x0000 },
  { 0x1600, 0x3018, 0x0000 },
  { 0x9200, 0x301b, 0x2000 },
  { 0x1600, 0x301a, 0x0000 },
  { 0x1100, 0x301c, 0x0000 },
  { 0x8c00, 0x302d, 0x5000 },
  { 0x8e00, 0x3025, 0x4000 },
  { 0x8e00, 0x3021, 0x3000 },
  { 0x9200, 0x301f, 0x2000 },
  { 0x1200, 0x301e, 0x0000 },
  { 0x1a00, 0x3020, 0x0000 },
  { 0x8e00, 0x3023, 0x2000 },
  { 0x0e00, 0x3022, 0x0000 },
  { 0x0e00, 0x3024, 0x0000 },
  { 0x8e00, 0x3029, 0x3000 },
  { 0x8e00, 0x3027, 0x2000 },
  { 0x0e00, 0x3026, 0x0000 },
  { 0x0e00, 0x3028, 0x0000 },
  { 0x8c00, 0x302b, 0x2000 },
  { 0x0c00, 0x302a, 0x0000 },
  { 0x0c00, 0x302c, 0x0000 },
  { 0x8600, 0x3035, 0x4000 },
  { 0x8600, 0x3031, 0x3000 },
  { 0x8c00, 0x302f, 0x2000 },
  { 0x0c00, 0x302e, 0x0000 },
  { 0x1100, 0x3030, 0x0000 },
  { 0x8600, 0x3033, 0x2000 },
  { 0x0600, 0x3032, 0x0000 },
  { 0x0600, 0x3034, 0x0000 },
  { 0x8e00, 0x3039, 0x3000 },
  { 0x9a00, 0x3037, 0x2000 },
  { 0x1a00, 0x3036, 0x0000 },
  { 0x0e00, 0x3038, 0x0000 },
  { 0x8600, 0x303b, 0x2000 },
  { 0x0e00, 0x303a, 0x0000 },
  { 0x0700, 0x303c, 0x0000 },
  { 0x8700, 0x30c0, 0x8000 },
  { 0x8700, 0x307e, 0x7000 },
  { 0x8700, 0x305e, 0x6000 },
  { 0x8700, 0x304e, 0x5000 },
  { 0x8700, 0x3046, 0x4000 },
  { 0x8700, 0x3042, 0x3000 },
  { 0x9a00, 0x303f, 0x2000 },
  { 0x1a00, 0x303e, 0x0000 },
  { 0x0700, 0x3041, 0x0000 },
  { 0x8700, 0x3044, 0x2000 },
  { 0x0700, 0x3043, 0x0000 },
  { 0x0700, 0x3045, 0x0000 },
  { 0x8700, 0x304a, 0x3000 },
  { 0x8700, 0x3048, 0x2000 },
  { 0x0700, 0x3047, 0x0000 },
  { 0x0700, 0x3049, 0x0000 },
  { 0x8700, 0x304c, 0x2000 },
  { 0x0700, 0x304b, 0x0000 },
  { 0x0700, 0x304d, 0x0000 },
  { 0x8700, 0x3056, 0x4000 },
  { 0x8700, 0x3052, 0x3000 },
  { 0x8700, 0x3050, 0x2000 },
  { 0x0700, 0x304f, 0x0000 },
  { 0x0700, 0x3051, 0x0000 },
  { 0x8700, 0x3054, 0x2000 },
  { 0x0700, 0x3053, 0x0000 },
  { 0x0700, 0x3055, 0x0000 },
  { 0x8700, 0x305a, 0x3000 },
  { 0x8700, 0x3058, 0x2000 },
  { 0x0700, 0x3057, 0x0000 },
  { 0x0700, 0x3059, 0x0000 },
  { 0x8700, 0x305c, 0x2000 },
  { 0x0700, 0x305b, 0x0000 },
  { 0x0700, 0x305d, 0x0000 },
  { 0x8700, 0x306e, 0x5000 },
  { 0x8700, 0x3066, 0x4000 },
  { 0x8700, 0x3062, 0x3000 },
  { 0x8700, 0x3060, 0x2000 },
  { 0x0700, 0x305f, 0x0000 },
  { 0x0700, 0x3061, 0x0000 },
  { 0x8700, 0x3064, 0x2000 },
  { 0x0700, 0x3063, 0x0000 },
  { 0x0700, 0x3065, 0x0000 },
  { 0x8700, 0x306a, 0x3000 },
  { 0x8700, 0x3068, 0x2000 },
  { 0x0700, 0x3067, 0x0000 },
  { 0x0700, 0x3069, 0x0000 },
  { 0x8700, 0x306c, 0x2000 },
  { 0x0700, 0x306b, 0x0000 },
  { 0x0700, 0x306d, 0x0000 },
  { 0x8700, 0x3076, 0x4000 },
  { 0x8700, 0x3072, 0x3000 },
  { 0x8700, 0x3070, 0x2000 },
  { 0x0700, 0x306f, 0x0000 },
  { 0x0700, 0x3071, 0x0000 },
  { 0x8700, 0x3074, 0x2000 },
  { 0x0700, 0x3073, 0x0000 },
  { 0x0700, 0x3075, 0x0000 },
  { 0x8700, 0x307a, 0x3000 },
  { 0x8700, 0x3078, 0x2000 },
  { 0x0700, 0x3077, 0x0000 },
  { 0x0700, 0x3079, 0x0000 },
  { 0x8700, 0x307c, 0x2000 },
  { 0x0700, 0x307b, 0x0000 },
  { 0x0700, 0x307d, 0x0000 },
  { 0x9100, 0x30a0, 0x6000 },
  { 0x8700, 0x308e, 0x5000 },
  { 0x8700, 0x3086, 0x4000 },
  { 0x8700, 0x3082, 0x3000 },
  { 0x8700, 0x3080, 0x2000 },
  { 0x0700, 0x307f, 0x0000 },
  { 0x0700, 0x3081, 0x0000 },
  { 0x8700, 0x3084, 0x2000 },
  { 0x0700, 0x3083, 0x0000 },
  { 0x0700, 0x3085, 0x0000 },
  { 0x8700, 0x308a, 0x3000 },
  { 0x8700, 0x3088, 0x2000 },
  { 0x0700, 0x3087, 0x0000 },
  { 0x0700, 0x3089, 0x0000 },
  { 0x8700, 0x308c, 0x2000 },
  { 0x0700, 0x308b, 0x0000 },
  { 0x0700, 0x308d, 0x0000 },
  { 0x8700, 0x3096, 0x4000 },
  { 0x8700, 0x3092, 0x3000 },
  { 0x8700, 0x3090, 0x2000 },
  { 0x0700, 0x308f, 0x0000 },
  { 0x0700, 0x3091, 0x0000 },
  { 0x8700, 0x3094, 0x2000 },
  { 0x0700, 0x3093, 0x0000 },
  { 0x0700, 0x3095, 0x0000 },
  { 0x9800, 0x309c, 0x3000 },
  { 0x8c00, 0x309a, 0x2000 },
  { 0x0c00, 0x3099, 0x0000 },
  { 0x1800, 0x309b, 0x0000 },
  { 0x8600, 0x309e, 0x2000 },
  { 0x0600, 0x309d, 0x0000 },
  { 0x0700, 0x309f, 0x0000 },
  { 0x8700, 0x30b0, 0x5000 },
  { 0x8700, 0x30a8, 0x4000 },
  { 0x8700, 0x30a4, 0x3000 },
  { 0x8700, 0x30a2, 0x2000 },
  { 0x0700, 0x30a1, 0x0000 },
  { 0x0700, 0x30a3, 0x0000 },
  { 0x8700, 0x30a6, 0x2000 },
  { 0x0700, 0x30a5, 0x0000 },
  { 0x0700, 0x30a7, 0x0000 },
  { 0x8700, 0x30ac, 0x3000 },
  { 0x8700, 0x30aa, 0x2000 },
  { 0x0700, 0x30a9, 0x0000 },
  { 0x0700, 0x30ab, 0x0000 },
  { 0x8700, 0x30ae, 0x2000 },
  { 0x0700, 0x30ad, 0x0000 },
  { 0x0700, 0x30af, 0x0000 },
  { 0x8700, 0x30b8, 0x4000 },
  { 0x8700, 0x30b4, 0x3000 },
  { 0x8700, 0x30b2, 0x2000 },
  { 0x0700, 0x30b1, 0x0000 },
  { 0x0700, 0x30b3, 0x0000 },
  { 0x8700, 0x30b6, 0x2000 },
  { 0x0700, 0x30b5, 0x0000 },
  { 0x0700, 0x30b7, 0x0000 },
  { 0x8700, 0x30bc, 0x3000 },
  { 0x8700, 0x30ba, 0x2000 },
  { 0x0700, 0x30b9, 0x0000 },
  { 0x0700, 0x30bb, 0x0000 },
  { 0x8700, 0x30be, 0x2000 },
  { 0x0700, 0x30bd, 0x0000 },
  { 0x0700, 0x30bf, 0x0000 },
  { 0x8700, 0x3105, 0x7000 },
  { 0x8700, 0x30e0, 0x6000 },
  { 0x8700, 0x30d0, 0x5000 },
  { 0x8700, 0x30c8, 0x4000 },
  { 0x8700, 0x30c4, 0x3000 },
  { 0x8700, 0x30c2, 0x2000 },
  { 0x0700, 0x30c1, 0x0000 },
  { 0x0700, 0x30c3, 0x0000 },
  { 0x8700, 0x30c6, 0x2000 },
  { 0x0700, 0x30c5, 0x0000 },
  { 0x0700, 0x30c7, 0x0000 },
  { 0x8700, 0x30cc, 0x3000 },
  { 0x8700, 0x30ca, 0x2000 },
  { 0x0700, 0x30c9, 0x0000 },
  { 0x0700, 0x30cb, 0x0000 },
  { 0x8700, 0x30ce, 0x2000 },
  { 0x0700, 0x30cd, 0x0000 },
  { 0x0700, 0x30cf, 0x0000 },
  { 0x8700, 0x30d8, 0x4000 },
  { 0x8700, 0x30d4, 0x3000 },
  { 0x8700, 0x30d2, 0x2000 },
  { 0x0700, 0x30d1, 0x0000 },
  { 0x0700, 0x30d3, 0x0000 },
  { 0x8700, 0x30d6, 0x2000 },
  { 0x0700, 0x30d5, 0x0000 },
  { 0x0700, 0x30d7, 0x0000 },
  { 0x8700, 0x30dc, 0x3000 },
  { 0x8700, 0x30da, 0x2000 },
  { 0x0700, 0x30d9, 0x0000 },
  { 0x0700, 0x30db, 0x0000 },
  { 0x8700, 0x30de, 0x2000 },
  { 0x0700, 0x30dd, 0x0000 },
  { 0x0700, 0x30df, 0x0000 },
  { 0x8700, 0x30f0, 0x5000 },
  { 0x8700, 0x30e8, 0x4000 },
  { 0x8700, 0x30e4, 0x3000 },
  { 0x8700, 0x30e2, 0x2000 },
  { 0x0700, 0x30e1, 0x0000 },
  { 0x0700, 0x30e3, 0x0000 },
  { 0x8700, 0x30e6, 0x2000 },
  { 0x0700, 0x30e5, 0x0000 },
  { 0x0700, 0x30e7, 0x0000 },
  { 0x8700, 0x30ec, 0x3000 },
  { 0x8700, 0x30ea, 0x2000 },
  { 0x0700, 0x30e9, 0x0000 },
  { 0x0700, 0x30eb, 0x0000 },
  { 0x8700, 0x30ee, 0x2000 },
  { 0x0700, 0x30ed, 0x0000 },
  { 0x0700, 0x30ef, 0x0000 },
  { 0x8700, 0x30f8, 0x4000 },
  { 0x8700, 0x30f4, 0x3000 },
  { 0x8700, 0x30f2, 0x2000 },
  { 0x0700, 0x30f1, 0x0000 },
  { 0x0700, 0x30f3, 0x0000 },
  { 0x8700, 0x30f6, 0x2000 },
  { 0x0700, 0x30f5, 0x0000 },
  { 0x0700, 0x30f7, 0x0000 },
  { 0x8600, 0x30fc, 0x3000 },
  { 0x8700, 0x30fa, 0x2000 },
  { 0x0700, 0x30f9, 0x0000 },
  { 0x1000, 0x30fb, 0x0000 },
  { 0x8600, 0x30fe, 0x2000 },
  { 0x0600, 0x30fd, 0x0000 },
  { 0x0700, 0x30ff, 0x0000 },
  { 0x8700, 0x3125, 0x6000 },
  { 0x8700, 0x3115, 0x5000 },
  { 0x8700, 0x310d, 0x4000 },
  { 0x8700, 0x3109, 0x3000 },
  { 0x8700, 0x3107, 0x2000 },
  { 0x0700, 0x3106, 0x0000 },
  { 0x0700, 0x3108, 0x0000 },
  { 0x8700, 0x310b, 0x2000 },
  { 0x0700, 0x310a, 0x0000 },
  { 0x0700, 0x310c, 0x0000 },
  { 0x8700, 0x3111, 0x3000 },
  { 0x8700, 0x310f, 0x2000 },
  { 0x0700, 0x310e, 0x0000 },
  { 0x0700, 0x3110, 0x0000 },
  { 0x8700, 0x3113, 0x2000 },
  { 0x0700, 0x3112, 0x0000 },
  { 0x0700, 0x3114, 0x0000 },
  { 0x8700, 0x311d, 0x4000 },
  { 0x8700, 0x3119, 0x3000 },
  { 0x8700, 0x3117, 0x2000 },
  { 0x0700, 0x3116, 0x0000 },
  { 0x0700, 0x3118, 0x0000 },
  { 0x8700, 0x311b, 0x2000 },
  { 0x0700, 0x311a, 0x0000 },
  { 0x0700, 0x311c, 0x0000 },
  { 0x8700, 0x3121, 0x3000 },
  { 0x8700, 0x311f, 0x2000 },
  { 0x0700, 0x311e, 0x0000 },
  { 0x0700, 0x3120, 0x0000 },
  { 0x8700, 0x3123, 0x2000 },
  { 0x0700, 0x3122, 0x0000 },
  { 0x0700, 0x3124, 0x0000 },
  { 0x8700, 0x3139, 0x5000 },
  { 0x8700, 0x3131, 0x4000 },
  { 0x8700, 0x3129, 0x3000 },
  { 0x8700, 0x3127, 0x2000 },
  { 0x0700, 0x3126, 0x0000 },
  { 0x0700, 0x3128, 0x0000 },
  { 0x8700, 0x312b, 0x2000 },
  { 0x0700, 0x312a, 0x0000 },
  { 0x0700, 0x312c, 0x0000 },
  { 0x8700, 0x3135, 0x3000 },
  { 0x8700, 0x3133, 0x2000 },
  { 0x0700, 0x3132, 0x0000 },
  { 0x0700, 0x3134, 0x0000 },
  { 0x8700, 0x3137, 0x2000 },
  { 0x0700, 0x3136, 0x0000 },
  { 0x0700, 0x3138, 0x0000 },
  { 0x8700, 0x3141, 0x4000 },
  { 0x8700, 0x313d, 0x3000 },
  { 0x8700, 0x313b, 0x2000 },
  { 0x0700, 0x313a, 0x0000 },
  { 0x0700, 0x313c, 0x0000 },
  { 0x8700, 0x313f, 0x2000 },
  { 0x0700, 0x313e, 0x0000 },
  { 0x0700, 0x3140, 0x0000 },
  { 0x8700, 0x3145, 0x3000 },
  { 0x8700, 0x3143, 0x2000 },
  { 0x0700, 0x3142, 0x0000 },
  { 0x0700, 0x3144, 0x0000 },
  { 0x8700, 0x3147, 0x2000 },
  { 0x0700, 0x3146, 0x0000 },
  { 0x0700, 0x3148, 0x0000 },
  { 0x9a00, 0x3290, 0x9000 },
  { 0x9a00, 0x3202, 0x8000 },
  { 0x8700, 0x3189, 0x7000 },
  { 0x8700, 0x3169, 0x6000 },
  { 0x8700, 0x3159, 0x5000 },
  { 0x8700, 0x3151, 0x4000 },
  { 0x8700, 0x314d, 0x3000 },
  { 0x8700, 0x314b, 0x2000 },
  { 0x0700, 0x314a, 0x0000 },
  { 0x0700, 0x314c, 0x0000 },
  { 0x8700, 0x314f, 0x2000 },
  { 0x0700, 0x314e, 0x0000 },
  { 0x0700, 0x3150, 0x0000 },
  { 0x8700, 0x3155, 0x3000 },
  { 0x8700, 0x3153, 0x2000 },
  { 0x0700, 0x3152, 0x0000 },
  { 0x0700, 0x3154, 0x0000 },
  { 0x8700, 0x3157, 0x2000 },
  { 0x0700, 0x3156, 0x0000 },
  { 0x0700, 0x3158, 0x0000 },
  { 0x8700, 0x3161, 0x4000 },
  { 0x8700, 0x315d, 0x3000 },
  { 0x8700, 0x315b, 0x2000 },
  { 0x0700, 0x315a, 0x0000 },
  { 0x0700, 0x315c, 0x0000 },
  { 0x8700, 0x315f, 0x2000 },
  { 0x0700, 0x315e, 0x0000 },
  { 0x0700, 0x3160, 0x0000 },
  { 0x8700, 0x3165, 0x3000 },
  { 0x8700, 0x3163, 0x2000 },
  { 0x0700, 0x3162, 0x0000 },
  { 0x0700, 0x3164, 0x0000 },
  { 0x8700, 0x3167, 0x2000 },
  { 0x0700, 0x3166, 0x0000 },
  { 0x0700, 0x3168, 0x0000 },
  { 0x8700, 0x3179, 0x5000 },
  { 0x8700, 0x3171, 0x4000 },
  { 0x8700, 0x316d, 0x3000 },
  { 0x8700, 0x316b, 0x2000 },
  { 0x0700, 0x316a, 0x0000 },
  { 0x0700, 0x316c, 0x0000 },
  { 0x8700, 0x316f, 0x2000 },
  { 0x0700, 0x316e, 0x0000 },
  { 0x0700, 0x3170, 0x0000 },
  { 0x8700, 0x3175, 0x3000 },
  { 0x8700, 0x3173, 0x2000 },
  { 0x0700, 0x3172, 0x0000 },
  { 0x0700, 0x3174, 0x0000 },
  { 0x8700, 0x3177, 0x2000 },
  { 0x0700, 0x3176, 0x0000 },
  { 0x0700, 0x3178, 0x0000 },
  { 0x8700, 0x3181, 0x4000 },
  { 0x8700, 0x317d, 0x3000 },
  { 0x8700, 0x317b, 0x2000 },
  { 0x0700, 0x317a, 0x0000 },
  { 0x0700, 0x317c, 0x0000 },
  { 0x8700, 0x317f, 0x2000 },
  { 0x0700, 0x317e, 0x0000 },
  { 0x0700, 0x3180, 0x0000 },
  { 0x8700, 0x3185, 0x3000 },
  { 0x8700, 0x3183, 0x2000 },
  { 0x0700, 0x3182, 0x0000 },
  { 0x0700, 0x3184, 0x0000 },
  { 0x8700, 0x3187, 0x2000 },
  { 0x0700, 0x3186, 0x0000 },
  { 0x0700, 0x3188, 0x0000 },
  { 0x8700, 0x31aa, 0x6000 },
  { 0x9a00, 0x319a, 0x5000 },
  { 0x8f00, 0x3192, 0x4000 },
  { 0x8700, 0x318d, 0x3000 },
  { 0x8700, 0x318b, 0x2000 },
  { 0x0700, 0x318a, 0x0000 },
  { 0x0700, 0x318c, 0x0000 },
  { 0x9a00, 0x3190, 0x2000 },
  { 0x0700, 0x318e, 0x0000 },
  { 0x1a00, 0x3191, 0x0000 },
  { 0x9a00, 0x3196, 0x3000 },
  { 0x8f00, 0x3194, 0x2000 },
  { 0x0f00, 0x3193, 0x0000 },
  { 0x0f00, 0x3195, 0x0000 },
  { 0x9a00, 0x3198, 0x2000 },
  { 0x1a00, 0x3197, 0x0000 },
  { 0x1a00, 0x3199, 0x0000 },
  { 0x8700, 0x31a2, 0x4000 },
  { 0x9a00, 0x319e, 0x3000 },
  { 0x9a00, 0x319c, 0x2000 },
  { 0x1a00, 0x319b, 0x0000 },
  { 0x1a00, 0x319d, 0x0000 },
  { 0x8700, 0x31a0, 0x2000 },
  { 0x1a00, 0x319f, 0x0000 },
  { 0x0700, 0x31a1, 0x0000 },
  { 0x8700, 0x31a6, 0x3000 },
  { 0x8700, 0x31a4, 0x2000 },
  { 0x0700, 0x31a3, 0x0000 },
  { 0x0700, 0x31a5, 0x0000 },
  { 0x8700, 0x31a8, 0x2000 },
  { 0x0700, 0x31a7, 0x0000 },
  { 0x0700, 0x31a9, 0x0000 },
  { 0x8700, 0x31f2, 0x5000 },
  { 0x8700, 0x31b2, 0x4000 },
  { 0x8700, 0x31ae, 0x3000 },
  { 0x8700, 0x31ac, 0x2000 },
  { 0x0700, 0x31ab, 0x0000 },
  { 0x0700, 0x31ad, 0x0000 },
  { 0x8700, 0x31b0, 0x2000 },
  { 0x0700, 0x31af, 0x0000 },
  { 0x0700, 0x31b1, 0x0000 },
  { 0x8700, 0x31b6, 0x3000 },
  { 0x8700, 0x31b4, 0x2000 },
  { 0x0700, 0x31b3, 0x0000 },
  { 0x0700, 0x31b5, 0x0000 },
  { 0x8700, 0x31f0, 0x2000 },
  { 0x0700, 0x31b7, 0x0000 },
  { 0x0700, 0x31f1, 0x0000 },
  { 0x8700, 0x31fa, 0x4000 },
  { 0x8700, 0x31f6, 0x3000 },
  { 0x8700, 0x31f4, 0x2000 },
  { 0x0700, 0x31f3, 0x0000 },
  { 0x0700, 0x31f5, 0x0000 },
  { 0x8700, 0x31f8, 0x2000 },
  { 0x0700, 0x31f7, 0x0000 },
  { 0x0700, 0x31f9, 0x0000 },
  { 0x8700, 0x31fe, 0x3000 },
  { 0x8700, 0x31fc, 0x2000 },
  { 0x0700, 0x31fb, 0x0000 },
  { 0x0700, 0x31fd, 0x0000 },
  { 0x9a00, 0x3200, 0x2000 },
  { 0x0700, 0x31ff, 0x0000 },
  { 0x1a00, 0x3201, 0x0000 },
  { 0x9a00, 0x3243, 0x7000 },
  { 0x8f00, 0x3223, 0x6000 },
  { 0x9a00, 0x3212, 0x5000 },
  { 0x9a00, 0x320a, 0x4000 },
  { 0x9a00, 0x3206, 0x3000 },
  { 0x9a00, 0x3204, 0x2000 },
  { 0x1a00, 0x3203, 0x0000 },
  { 0x1a00, 0x3205, 0x0000 },
  { 0x9a00, 0x3208, 0x2000 },
  { 0x1a00, 0x3207, 0x0000 },
  { 0x1a00, 0x3209, 0x0000 },
  { 0x9a00, 0x320e, 0x3000 },
  { 0x9a00, 0x320c, 0x2000 },
  { 0x1a00, 0x320b, 0x0000 },
  { 0x1a00, 0x320d, 0x0000 },
  { 0x9a00, 0x3210, 0x2000 },
  { 0x1a00, 0x320f, 0x0000 },
  { 0x1a00, 0x3211, 0x0000 },
  { 0x9a00, 0x321a, 0x4000 },
  { 0x9a00, 0x3216, 0x3000 },
  { 0x9a00, 0x3214, 0x2000 },
  { 0x1a00, 0x3213, 0x0000 },
  { 0x1a00, 0x3215, 0x0000 },
  { 0x9a00, 0x3218, 0x2000 },
  { 0x1a00, 0x3217, 0x0000 },
  { 0x1a00, 0x3219, 0x0000 },
  { 0x9a00, 0x321e, 0x3000 },
  { 0x9a00, 0x321c, 0x2000 },
  { 0x1a00, 0x321b, 0x0000 },
  { 0x1a00, 0x321d, 0x0000 },
  { 0x8f00, 0x3221, 0x2000 },
  { 0x0f00, 0x3220, 0x0000 },
  { 0x0f00, 0x3222, 0x0000 },
  { 0x9a00, 0x3233, 0x5000 },
  { 0x9a00, 0x322b, 0x4000 },
  { 0x8f00, 0x3227, 0x3000 },
  { 0x8f00, 0x3225, 0x2000 },
  { 0x0f00, 0x3224, 0x0000 },
  { 0x0f00, 0x3226, 0x0000 },
  { 0x8f00, 0x3229, 0x2000 },
  { 0x0f00, 0x3228, 0x0000 },
  { 0x1a00, 0x322a, 0x0000 },
  { 0x9a00, 0x322f, 0x3000 },
  { 0x9a00, 0x322d, 0x2000 },
  { 0x1a00, 0x322c, 0x0000 },
  { 0x1a00, 0x322e, 0x0000 },
  { 0x9a00, 0x3231, 0x2000 },
  { 0x1a00, 0x3230, 0x0000 },
  { 0x1a00, 0x3232, 0x0000 },
  { 0x9a00, 0x323b, 0x4000 },
  { 0x9a00, 0x3237, 0x3000 },
  { 0x9a00, 0x3235, 0x2000 },
  { 0x1a00, 0x3234, 0x0000 },
  { 0x1a00, 0x3236, 0x0000 },
  { 0x9a00, 0x3239, 0x2000 },
  { 0x1a00, 0x3238, 0x0000 },
  { 0x1a00, 0x323a, 0x0000 },
  { 0x9a00, 0x323f, 0x3000 },
  { 0x9a00, 0x323d, 0x2000 },
  { 0x1a00, 0x323c, 0x0000 },
  { 0x1a00, 0x323e, 0x0000 },
  { 0x9a00, 0x3241, 0x2000 },
  { 0x1a00, 0x3240, 0x0000 },
  { 0x1a00, 0x3242, 0x0000 },
  { 0x9a00, 0x326f, 0x6000 },
  { 0x8f00, 0x325f, 0x5000 },
  { 0x8f00, 0x3257, 0x4000 },
  { 0x8f00, 0x3253, 0x3000 },
  { 0x8f00, 0x3251, 0x2000 },
  { 0x1a00, 0x3250, 0x0000 },
  { 0x0f00, 0x3252, 0x0000 },
  { 0x8f00, 0x3255, 0x2000 },
  { 0x0f00, 0x3254, 0x0000 },
  { 0x0f00, 0x3256, 0x0000 },
  { 0x8f00, 0x325b, 0x3000 },
  { 0x8f00, 0x3259, 0x2000 },
  { 0x0f00, 0x3258, 0x0000 },
  { 0x0f00, 0x325a, 0x0000 },
  { 0x8f00, 0x325d, 0x2000 },
  { 0x0f00, 0x325c, 0x0000 },
  { 0x0f00, 0x325e, 0x0000 },
  { 0x9a00, 0x3267, 0x4000 },
  { 0x9a00, 0x3263, 0x3000 },
  { 0x9a00, 0x3261, 0x2000 },
  { 0x1a00, 0x3260, 0x0000 },
  { 0x1a00, 0x3262, 0x0000 },
  { 0x9a00, 0x3265, 0x2000 },
  { 0x1a00, 0x3264, 0x0000 },
  { 0x1a00, 0x3266, 0x0000 },
  { 0x9a00, 0x326b, 0x3000 },
  { 0x9a00, 0x3269, 0x2000 },
  { 0x1a00, 0x3268, 0x0000 },
  { 0x1a00, 0x326a, 0x0000 },
  { 0x9a00, 0x326d, 0x2000 },
  { 0x1a00, 0x326c, 0x0000 },
  { 0x1a00, 0x326e, 0x0000 },
  { 0x8f00, 0x3280, 0x5000 },
  { 0x9a00, 0x3277, 0x4000 },
  { 0x9a00, 0x3273, 0x3000 },
  { 0x9a00, 0x3271, 0x2000 },
  { 0x1a00, 0x3270, 0x0000 },
  { 0x1a00, 0x3272, 0x0000 },
  { 0x9a00, 0x3275, 0x2000 },
  { 0x1a00, 0x3274, 0x0000 },
  { 0x1a00, 0x3276, 0x0000 },
  { 0x9a00, 0x327b, 0x3000 },
  { 0x9a00, 0x3279, 0x2000 },
  { 0x1a00, 0x3278, 0x0000 },
  { 0x1a00, 0x327a, 0x0000 },
  { 0x9a00, 0x327d, 0x2000 },
  { 0x1a00, 0x327c, 0x0000 },
  { 0x1a00, 0x327f, 0x0000 },
  { 0x8f00, 0x3288, 0x4000 },
  { 0x8f00, 0x3284, 0x3000 },
  { 0x8f00, 0x3282, 0x2000 },
  { 0x0f00, 0x3281, 0x0000 },
  { 0x0f00, 0x3283, 0x0000 },
  { 0x8f00, 0x3286, 0x2000 },
  { 0x0f00, 0x3285, 0x0000 },
  { 0x0f00, 0x3287, 0x0000 },
  { 0x9a00, 0x328c, 0x3000 },
  { 0x9a00, 0x328a, 0x2000 },
  { 0x0f00, 0x3289, 0x0000 },
  { 0x1a00, 0x328b, 0x0000 },
  { 0x9a00, 0x328e, 0x2000 },
  { 0x1a00, 0x328d, 0x0000 },
  { 0x1a00, 0x328f, 0x0000 },
  { 0x9a00, 0x3311, 0x8000 },
  { 0x9a00, 0x32d0, 0x7000 },
  { 0x9a00, 0x32b0, 0x6000 },
  { 0x9a00, 0x32a0, 0x5000 },
  { 0x9a00, 0x3298, 0x4000 },
  { 0x9a00, 0x3294, 0x3000 },
  { 0x9a00, 0x3292, 0x2000 },
  { 0x1a00, 0x3291, 0x0000 },
  { 0x1a00, 0x3293, 0x0000 },
  { 0x9a00, 0x3296, 0x2000 },
  { 0x1a00, 0x3295, 0x0000 },
  { 0x1a00, 0x3297, 0x0000 },
  { 0x9a00, 0x329c, 0x3000 },
  { 0x9a00, 0x329a, 0x2000 },
  { 0x1a00, 0x3299, 0x0000 },
  { 0x1a00, 0x329b, 0x0000 },
  { 0x9a00, 0x329e, 0x2000 },
  { 0x1a00, 0x329d, 0x0000 },
  { 0x1a00, 0x329f, 0x0000 },
  { 0x9a00, 0x32a8, 0x4000 },
  { 0x9a00, 0x32a4, 0x3000 },
  { 0x9a00, 0x32a2, 0x2000 },
  { 0x1a00, 0x32a1, 0x0000 },
  { 0x1a00, 0x32a3, 0x0000 },
  { 0x9a00, 0x32a6, 0x2000 },
  { 0x1a00, 0x32a5, 0x0000 },
  { 0x1a00, 0x32a7, 0x0000 },
  { 0x9a00, 0x32ac, 0x3000 },
  { 0x9a00, 0x32aa, 0x2000 },
  { 0x1a00, 0x32a9, 0x0000 },
  { 0x1a00, 0x32ab, 0x0000 },
  { 0x9a00, 0x32ae, 0x2000 },
  { 0x1a00, 0x32ad, 0x0000 },
  { 0x1a00, 0x32af, 0x0000 },
  { 0x9a00, 0x32c0, 0x5000 },
  { 0x8f00, 0x32b8, 0x4000 },
  { 0x8f00, 0x32b4, 0x3000 },
  { 0x8f00, 0x32b2, 0x2000 },
  { 0x0f00, 0x32b1, 0x0000 },
  { 0x0f00, 0x32b3, 0x0000 },
  { 0x8f00, 0x32b6, 0x2000 },
  { 0x0f00, 0x32b5, 0x0000 },
  { 0x0f00, 0x32b7, 0x0000 },
  { 0x8f00, 0x32bc, 0x3000 },
  { 0x8f00, 0x32ba, 0x2000 },
  { 0x0f00, 0x32b9, 0x0000 },
  { 0x0f00, 0x32bb, 0x0000 },
  { 0x8f00, 0x32be, 0x2000 },
  { 0x0f00, 0x32bd, 0x0000 },
  { 0x0f00, 0x32bf, 0x0000 },
  { 0x9a00, 0x32c8, 0x4000 },
  { 0x9a00, 0x32c4, 0x3000 },
  { 0x9a00, 0x32c2, 0x2000 },
  { 0x1a00, 0x32c1, 0x0000 },
  { 0x1a00, 0x32c3, 0x0000 },
  { 0x9a00, 0x32c6, 0x2000 },
  { 0x1a00, 0x32c5, 0x0000 },
  { 0x1a00, 0x32c7, 0x0000 },
  { 0x9a00, 0x32cc, 0x3000 },
  { 0x9a00, 0x32ca, 0x2000 },
  { 0x1a00, 0x32c9, 0x0000 },
  { 0x1a00, 0x32cb, 0x0000 },
  { 0x9a00, 0x32ce, 0x2000 },
  { 0x1a00, 0x32cd, 0x0000 },
  { 0x1a00, 0x32cf, 0x0000 },
  { 0x9a00, 0x32f0, 0x6000 },
  { 0x9a00, 0x32e0, 0x5000 },
  { 0x9a00, 0x32d8, 0x4000 },
  { 0x9a00, 0x32d4, 0x3000 },
  { 0x9a00, 0x32d2, 0x2000 },
  { 0x1a00, 0x32d1, 0x0000 },
  { 0x1a00, 0x32d3, 0x0000 },
  { 0x9a00, 0x32d6, 0x2000 },
  { 0x1a00, 0x32d5, 0x0000 },
  { 0x1a00, 0x32d7, 0x0000 },
  { 0x9a00, 0x32dc, 0x3000 },
  { 0x9a00, 0x32da, 0x2000 },
  { 0x1a00, 0x32d9, 0x0000 },
  { 0x1a00, 0x32db, 0x0000 },
  { 0x9a00, 0x32de, 0x2000 },
  { 0x1a00, 0x32dd, 0x0000 },
  { 0x1a00, 0x32df, 0x0000 },
  { 0x9a00, 0x32e8, 0x4000 },
  { 0x9a00, 0x32e4, 0x3000 },
  { 0x9a00, 0x32e2, 0x2000 },
  { 0x1a00, 0x32e1, 0x0000 },
  { 0x1a00, 0x32e3, 0x0000 },
  { 0x9a00, 0x32e6, 0x2000 },
  { 0x1a00, 0x32e5, 0x0000 },
  { 0x1a00, 0x32e7, 0x0000 },
  { 0x9a00, 0x32ec, 0x3000 },
  { 0x9a00, 0x32ea, 0x2000 },
  { 0x1a00, 0x32e9, 0x0000 },
  { 0x1a00, 0x32eb, 0x0000 },
  { 0x9a00, 0x32ee, 0x2000 },
  { 0x1a00, 0x32ed, 0x0000 },
  { 0x1a00, 0x32ef, 0x0000 },
  { 0x9a00, 0x3301, 0x5000 },
  { 0x9a00, 0x32f8, 0x4000 },
  { 0x9a00, 0x32f4, 0x3000 },
  { 0x9a00, 0x32f2, 0x2000 },
  { 0x1a00, 0x32f1, 0x0000 },
  { 0x1a00, 0x32f3, 0x0000 },
  { 0x9a00, 0x32f6, 0x2000 },
  { 0x1a00, 0x32f5, 0x0000 },
  { 0x1a00, 0x32f7, 0x0000 },
  { 0x9a00, 0x32fc, 0x3000 },
  { 0x9a00, 0x32fa, 0x2000 },
  { 0x1a00, 0x32f9, 0x0000 },
  { 0x1a00, 0x32fb, 0x0000 },
  { 0x9a00, 0x32fe, 0x2000 },
  { 0x1a00, 0x32fd, 0x0000 },
  { 0x1a00, 0x3300, 0x0000 },
  { 0x9a00, 0x3309, 0x4000 },
  { 0x9a00, 0x3305, 0x3000 },
  { 0x9a00, 0x3303, 0x2000 },
  { 0x1a00, 0x3302, 0x0000 },
  { 0x1a00, 0x3304, 0x0000 },
  { 0x9a00, 0x3307, 0x2000 },
  { 0x1a00, 0x3306, 0x0000 },
  { 0x1a00, 0x3308, 0x0000 },
  { 0x9a00, 0x330d, 0x3000 },
  { 0x9a00, 0x330b, 0x2000 },
  { 0x1a00, 0x330a, 0x0000 },
  { 0x1a00, 0x330c, 0x0000 },
  { 0x9a00, 0x330f, 0x2000 },
  { 0x1a00, 0x330e, 0x0000 },
  { 0x1a00, 0x3310, 0x0000 },
  { 0x9a00, 0x3351, 0x7000 },
  { 0x9a00, 0x3331, 0x6000 },
  { 0x9a00, 0x3321, 0x5000 },
  { 0x9a00, 0x3319, 0x4000 },
  { 0x9a00, 0x3315, 0x3000 },
  { 0x9a00, 0x3313, 0x2000 },
  { 0x1a00, 0x3312, 0x0000 },
  { 0x1a00, 0x3314, 0x0000 },
  { 0x9a00, 0x3317, 0x2000 },
  { 0x1a00, 0x3316, 0x0000 },
  { 0x1a00, 0x3318, 0x0000 },
  { 0x9a00, 0x331d, 0x3000 },
  { 0x9a00, 0x331b, 0x2000 },
  { 0x1a00, 0x331a, 0x0000 },
  { 0x1a00, 0x331c, 0x0000 },
  { 0x9a00, 0x331f, 0x2000 },
  { 0x1a00, 0x331e, 0x0000 },
  { 0x1a00, 0x3320, 0x0000 },
  { 0x9a00, 0x3329, 0x4000 },
  { 0x9a00, 0x3325, 0x3000 },
  { 0x9a00, 0x3323, 0x2000 },
  { 0x1a00, 0x3322, 0x0000 },
  { 0x1a00, 0x3324, 0x0000 },
  { 0x9a00, 0x3327, 0x2000 },
  { 0x1a00, 0x3326, 0x0000 },
  { 0x1a00, 0x3328, 0x0000 },
  { 0x9a00, 0x332d, 0x3000 },
  { 0x9a00, 0x332b, 0x2000 },
  { 0x1a00, 0x332a, 0x0000 },
  { 0x1a00, 0x332c, 0x0000 },
  { 0x9a00, 0x332f, 0x2000 },
  { 0x1a00, 0x332e, 0x0000 },
  { 0x1a00, 0x3330, 0x0000 },
  { 0x9a00, 0x3341, 0x5000 },
  { 0x9a00, 0x3339, 0x4000 },
  { 0x9a00, 0x3335, 0x3000 },
  { 0x9a00, 0x3333, 0x2000 },
  { 0x1a00, 0x3332, 0x0000 },
  { 0x1a00, 0x3334, 0x0000 },
  { 0x9a00, 0x3337, 0x2000 },
  { 0x1a00, 0x3336, 0x0000 },
  { 0x1a00, 0x3338, 0x0000 },
  { 0x9a00, 0x333d, 0x3000 },
  { 0x9a00, 0x333b, 0x2000 },
  { 0x1a00, 0x333a, 0x0000 },
  { 0x1a00, 0x333c, 0x0000 },
  { 0x9a00, 0x333f, 0x2000 },
  { 0x1a00, 0x333e, 0x0000 },
  { 0x1a00, 0x3340, 0x0000 },
  { 0x9a00, 0x3349, 0x4000 },
  { 0x9a00, 0x3345, 0x3000 },
  { 0x9a00, 0x3343, 0x2000 },
  { 0x1a00, 0x3342, 0x0000 },
  { 0x1a00, 0x3344, 0x0000 },
  { 0x9a00, 0x3347, 0x2000 },
  { 0x1a00, 0x3346, 0x0000 },
  { 0x1a00, 0x3348, 0x0000 },
  { 0x9a00, 0x334d, 0x3000 },
  { 0x9a00, 0x334b, 0x2000 },
  { 0x1a00, 0x334a, 0x0000 },
  { 0x1a00, 0x334c, 0x0000 },
  { 0x9a00, 0x334f, 0x2000 },
  { 0x1a00, 0x334e, 0x0000 },
  { 0x1a00, 0x3350, 0x0000 },
  { 0x9a00, 0x3371, 0x6000 },
  { 0x9a00, 0x3361, 0x5000 },
  { 0x9a00, 0x3359, 0x4000 },
  { 0x9a00, 0x3355, 0x3000 },
  { 0x9a00, 0x3353, 0x2000 },
  { 0x1a00, 0x3352, 0x0000 },
  { 0x1a00, 0x3354, 0x0000 },
  { 0x9a00, 0x3357, 0x2000 },
  { 0x1a00, 0x3356, 0x0000 },
  { 0x1a00, 0x3358, 0x0000 },
  { 0x9a00, 0x335d, 0x3000 },
  { 0x9a00, 0x335b, 0x2000 },
  { 0x1a00, 0x335a, 0x0000 },
  { 0x1a00, 0x335c, 0x0000 },
  { 0x9a00, 0x335f, 0x2000 },
  { 0x1a00, 0x335e, 0x0000 },
  { 0x1a00, 0x3360, 0x0000 },
  { 0x9a00, 0x3369, 0x4000 },
  { 0x9a00, 0x3365, 0x3000 },
  { 0x9a00, 0x3363, 0x2000 },
  { 0x1a00, 0x3362, 0x0000 },
  { 0x1a00, 0x3364, 0x0000 },
  { 0x9a00, 0x3367, 0x2000 },
  { 0x1a00, 0x3366, 0x0000 },
  { 0x1a00, 0x3368, 0x0000 },
  { 0x9a00, 0x336d, 0x3000 },
  { 0x9a00, 0x336b, 0x2000 },
  { 0x1a00, 0x336a, 0x0000 },
  { 0x1a00, 0x336c, 0x0000 },
  { 0x9a00, 0x336f, 0x2000 },
  { 0x1a00, 0x336e, 0x0000 },
  { 0x1a00, 0x3370, 0x0000 },
  { 0x9a00, 0x3381, 0x5000 },
  { 0x9a00, 0x3379, 0x4000 },
  { 0x9a00, 0x3375, 0x3000 },
  { 0x9a00, 0x3373, 0x2000 },
  { 0x1a00, 0x3372, 0x0000 },
  { 0x1a00, 0x3374, 0x0000 },
  { 0x9a00, 0x3377, 0x2000 },
  { 0x1a00, 0x3376, 0x0000 },
  { 0x1a00, 0x3378, 0x0000 },
  { 0x9a00, 0x337d, 0x3000 },
  { 0x9a00, 0x337b, 0x2000 },
  { 0x1a00, 0x337a, 0x0000 },
  { 0x1a00, 0x337c, 0x0000 },
  { 0x9a00, 0x337f, 0x2000 },
  { 0x1a00, 0x337e, 0x0000 },
  { 0x1a00, 0x3380, 0x0000 },
  { 0x9a00, 0x3389, 0x4000 },
  { 0x9a00, 0x3385, 0x3000 },
  { 0x9a00, 0x3383, 0x2000 },
  { 0x1a00, 0x3382, 0x0000 },
  { 0x1a00, 0x3384, 0x0000 },
  { 0x9a00, 0x3387, 0x2000 },
  { 0x1a00, 0x3386, 0x0000 },
  { 0x1a00, 0x3388, 0x0000 },
  { 0x9a00, 0x338d, 0x3000 },
  { 0x9a00, 0x338b, 0x2000 },
  { 0x1a00, 0x338a, 0x0000 },
  { 0x1a00, 0x338c, 0x0000 },
  { 0x9a00, 0x338f, 0x2000 },
  { 0x1a00, 0x338e, 0x0000 },
  { 0x1a00, 0x3390, 0x0000 },
  { 0x8700, 0xa14d, 0xa000 },
  { 0x8700, 0xa04d, 0x9000 },
  { 0x9a00, 0x4dcf, 0x8000 },
  { 0x9a00, 0x33d1, 0x7000 },
  { 0x9a00, 0x33b1, 0x6000 },
  { 0x9a00, 0x33a1, 0x5000 },
  { 0x9a00, 0x3399, 0x4000 },
  { 0x9a00, 0x3395, 0x3000 },
  { 0x9a00, 0x3393, 0x2000 },
  { 0x1a00, 0x3392, 0x0000 },
  { 0x1a00, 0x3394, 0x0000 },
  { 0x9a00, 0x3397, 0x2000 },
  { 0x1a00, 0x3396, 0x0000 },
  { 0x1a00, 0x3398, 0x0000 },
  { 0x9a00, 0x339d, 0x3000 },
  { 0x9a00, 0x339b, 0x2000 },
  { 0x1a00, 0x339a, 0x0000 },
  { 0x1a00, 0x339c, 0x0000 },
  { 0x9a00, 0x339f, 0x2000 },
  { 0x1a00, 0x339e, 0x0000 },
  { 0x1a00, 0x33a0, 0x0000 },
  { 0x9a00, 0x33a9, 0x4000 },
  { 0x9a00, 0x33a5, 0x3000 },
  { 0x9a00, 0x33a3, 0x2000 },
  { 0x1a00, 0x33a2, 0x0000 },
  { 0x1a00, 0x33a4, 0x0000 },
  { 0x9a00, 0x33a7, 0x2000 },
  { 0x1a00, 0x33a6, 0x0000 },
  { 0x1a00, 0x33a8, 0x0000 },
  { 0x9a00, 0x33ad, 0x3000 },
  { 0x9a00, 0x33ab, 0x2000 },
  { 0x1a00, 0x33aa, 0x0000 },
  { 0x1a00, 0x33ac, 0x0000 },
  { 0x9a00, 0x33af, 0x2000 },
  { 0x1a00, 0x33ae, 0x0000 },
  { 0x1a00, 0x33b0, 0x0000 },
  { 0x9a00, 0x33c1, 0x5000 },
  { 0x9a00, 0x33b9, 0x4000 },
  { 0x9a00, 0x33b5, 0x3000 },
  { 0x9a00, 0x33b3, 0x2000 },
  { 0x1a00, 0x33b2, 0x0000 },
  { 0x1a00, 0x33b4, 0x0000 },
  { 0x9a00, 0x33b7, 0x2000 },
  { 0x1a00, 0x33b6, 0x0000 },
  { 0x1a00, 0x33b8, 0x0000 },
  { 0x9a00, 0x33bd, 0x3000 },
  { 0x9a00, 0x33bb, 0x2000 },
  { 0x1a00, 0x33ba, 0x0000 },
  { 0x1a00, 0x33bc, 0x0000 },
  { 0x9a00, 0x33bf, 0x2000 },
  { 0x1a00, 0x33be, 0x0000 },
  { 0x1a00, 0x33c0, 0x0000 },
  { 0x9a00, 0x33c9, 0x4000 },
  { 0x9a00, 0x33c5, 0x3000 },
  { 0x9a00, 0x33c3, 0x2000 },
  { 0x1a00, 0x33c2, 0x0000 },
  { 0x1a00, 0x33c4, 0x0000 },
  { 0x9a00, 0x33c7, 0x2000 },
  { 0x1a00, 0x33c6, 0x0000 },
  { 0x1a00, 0x33c8, 0x0000 },
  { 0x9a00, 0x33cd, 0x3000 },
  { 0x9a00, 0x33cb, 0x2000 },
  { 0x1a00, 0x33ca, 0x0000 },
  { 0x1a00, 0x33cc, 0x0000 },
  { 0x9a00, 0x33cf, 0x2000 },
  { 0x1a00, 0x33ce, 0x0000 },
  { 0x1a00, 0x33d0, 0x0000 },
  { 0x9a00, 0x33f1, 0x6000 },
  { 0x9a00, 0x33e1, 0x5000 },
  { 0x9a00, 0x33d9, 0x4000 },
  { 0x9a00, 0x33d5, 0x3000 },
  { 0x9a00, 0x33d3, 0x2000 },
  { 0x1a00, 0x33d2, 0x0000 },
  { 0x1a00, 0x33d4, 0x0000 },
  { 0x9a00, 0x33d7, 0x2000 },
  { 0x1a00, 0x33d6, 0x0000 },
  { 0x1a00, 0x33d8, 0x0000 },
  { 0x9a00, 0x33dd, 0x3000 },
  { 0x9a00, 0x33db, 0x2000 },
  { 0x1a00, 0x33da, 0x0000 },
  { 0x1a00, 0x33dc, 0x0000 },
  { 0x9a00, 0x33df, 0x2000 },
  { 0x1a00, 0x33de, 0x0000 },
  { 0x1a00, 0x33e0, 0x0000 },
  { 0x9a00, 0x33e9, 0x4000 },
  { 0x9a00, 0x33e5, 0x3000 },
  { 0x9a00, 0x33e3, 0x2000 },
  { 0x1a00, 0x33e2, 0x0000 },
  { 0x1a00, 0x33e4, 0x0000 },
  { 0x9a00, 0x33e7, 0x2000 },
  { 0x1a00, 0x33e6, 0x0000 },
  { 0x1a00, 0x33e8, 0x0000 },
  { 0x9a00, 0x33ed, 0x3000 },
  { 0x9a00, 0x33eb, 0x2000 },
  { 0x1a00, 0x33ea, 0x0000 },
  { 0x1a00, 0x33ec, 0x0000 },
  { 0x9a00, 0x33ef, 0x2000 },
  { 0x1a00, 0x33ee, 0x0000 },
  { 0x1a00, 0x33f0, 0x0000 },
  { 0x8700, 0x4db5, 0x5000 },
  { 0x9a00, 0x33f9, 0x4000 },
  { 0x9a00, 0x33f5, 0x3000 },
  { 0x9a00, 0x33f3, 0x2000 },
  { 0x1a00, 0x33f2, 0x0000 },
  { 0x1a00, 0x33f4, 0x0000 },
  { 0x9a00, 0x33f7, 0x2000 },
  { 0x1a00, 0x33f6, 0x0000 },
  { 0x1a00, 0x33f8, 0x0000 },
  { 0x9a00, 0x33fd, 0x3000 },
  { 0x9a00, 0x33fb, 0x2000 },
  { 0x1a00, 0x33fa, 0x0000 },
  { 0x1a00, 0x33fc, 0x0000 },
  { 0x9a00, 0x33ff, 0x2000 },
  { 0x1a00, 0x33fe, 0x0000 },
  { 0x0700, 0x3400, 0x0000 },
  { 0x9a00, 0x4dc7, 0x4000 },
  { 0x9a00, 0x4dc3, 0x3000 },
  { 0x9a00, 0x4dc1, 0x2000 },
  { 0x1a00, 0x4dc0, 0x0000 },
  { 0x1a00, 0x4dc2, 0x0000 },
  { 0x9a00, 0x4dc5, 0x2000 },
  { 0x1a00, 0x4dc4, 0x0000 },
  { 0x1a00, 0x4dc6, 0x0000 },
  { 0x9a00, 0x4dcb, 0x3000 },
  { 0x9a00, 0x4dc9, 0x2000 },
  { 0x1a00, 0x4dc8, 0x0000 },
  { 0x1a00, 0x4dca, 0x0000 },
  { 0x9a00, 0x4dcd, 0x2000 },
  { 0x1a00, 0x4dcc, 0x0000 },
  { 0x1a00, 0x4dce, 0x0000 },
  { 0x8700, 0xa00d, 0x7000 },
  { 0x9a00, 0x4def, 0x6000 },
  { 0x9a00, 0x4ddf, 0x5000 },
  { 0x9a00, 0x4dd7, 0x4000 },
  { 0x9a00, 0x4dd3, 0x3000 },
  { 0x9a00, 0x4dd1, 0x2000 },
  { 0x1a00, 0x4dd0, 0x0000 },
  { 0x1a00, 0x4dd2, 0x0000 },
  { 0x9a00, 0x4dd5, 0x2000 },
  { 0x1a00, 0x4dd4, 0x0000 },
  { 0x1a00, 0x4dd6, 0x0000 },
  { 0x9a00, 0x4ddb, 0x3000 },
  { 0x9a00, 0x4dd9, 0x2000 },
  { 0x1a00, 0x4dd8, 0x0000 },
  { 0x1a00, 0x4dda, 0x0000 },
  { 0x9a00, 0x4ddd, 0x2000 },
  { 0x1a00, 0x4ddc, 0x0000 },
  { 0x1a00, 0x4dde, 0x0000 },
  { 0x9a00, 0x4de7, 0x4000 },
  { 0x9a00, 0x4de3, 0x3000 },
  { 0x9a00, 0x4de1, 0x2000 },
  { 0x1a00, 0x4de0, 0x0000 },
  { 0x1a00, 0x4de2, 0x0000 },
  { 0x9a00, 0x4de5, 0x2000 },
  { 0x1a00, 0x4de4, 0x0000 },
  { 0x1a00, 0x4de6, 0x0000 },
  { 0x9a00, 0x4deb, 0x3000 },
  { 0x9a00, 0x4de9, 0x2000 },
  { 0x1a00, 0x4de8, 0x0000 },
  { 0x1a00, 0x4dea, 0x0000 },
  { 0x9a00, 0x4ded, 0x2000 },
  { 0x1a00, 0x4dec, 0x0000 },
  { 0x1a00, 0x4dee, 0x0000 },
  { 0x9a00, 0x4dff, 0x5000 },
  { 0x9a00, 0x4df7, 0x4000 },
  { 0x9a00, 0x4df3, 0x3000 },
  { 0x9a00, 0x4df1, 0x2000 },
  { 0x1a00, 0x4df0, 0x0000 },
  { 0x1a00, 0x4df2, 0x0000 },
  { 0x9a00, 0x4df5, 0x2000 },
  { 0x1a00, 0x4df4, 0x0000 },
  { 0x1a00, 0x4df6, 0x0000 },
  { 0x9a00, 0x4dfb, 0x3000 },
  { 0x9a00, 0x4df9, 0x2000 },
  { 0x1a00, 0x4df8, 0x0000 },
  { 0x1a00, 0x4dfa, 0x0000 },
  { 0x9a00, 0x4dfd, 0x2000 },
  { 0x1a00, 0x4dfc, 0x0000 },
  { 0x1a00, 0x4dfe, 0x0000 },
  { 0x8700, 0xa005, 0x4000 },
  { 0x8700, 0xa001, 0x3000 },
  { 0x8700, 0x9fa5, 0x2000 },
  { 0x0700, 0x4e00, 0x0000 },
  { 0x0700, 0xa000, 0x0000 },
  { 0x8700, 0xa003, 0x2000 },
  { 0x0700, 0xa002, 0x0000 },
  { 0x0700, 0xa004, 0x0000 },
  { 0x8700, 0xa009, 0x3000 },
  { 0x8700, 0xa007, 0x2000 },
  { 0x0700, 0xa006, 0x0000 },
  { 0x0700, 0xa008, 0x0000 },
  { 0x8700, 0xa00b, 0x2000 },
  { 0x0700, 0xa00a, 0x0000 },
  { 0x0700, 0xa00c, 0x0000 },
  { 0x8700, 0xa02d, 0x6000 },
  { 0x8700, 0xa01d, 0x5000 },
  { 0x8700, 0xa015, 0x4000 },
  { 0x8700, 0xa011, 0x3000 },
  { 0x8700, 0xa00f, 0x2000 },
  { 0x0700, 0xa00e, 0x0000 },
  { 0x0700, 0xa010, 0x0000 },
  { 0x8700, 0xa013, 0x2000 },
  { 0x0700, 0xa012, 0x0000 },
  { 0x0700, 0xa014, 0x0000 },
  { 0x8700, 0xa019, 0x3000 },
  { 0x8700, 0xa017, 0x2000 },
  { 0x0700, 0xa016, 0x0000 },
  { 0x0700, 0xa018, 0x0000 },
  { 0x8700, 0xa01b, 0x2000 },
  { 0x0700, 0xa01a, 0x0000 },
  { 0x0700, 0xa01c, 0x0000 },
  { 0x8700, 0xa025, 0x4000 },
  { 0x8700, 0xa021, 0x3000 },
  { 0x8700, 0xa01f, 0x2000 },
  { 0x0700, 0xa01e, 0x0000 },
  { 0x0700, 0xa020, 0x0000 },
  { 0x8700, 0xa023, 0x2000 },
  { 0x0700, 0xa022, 0x0000 },
  { 0x0700, 0xa024, 0x0000 },
  { 0x8700, 0xa029, 0x3000 },
  { 0x8700, 0xa027, 0x2000 },
  { 0x0700, 0xa026, 0x0000 },
  { 0x0700, 0xa028, 0x0000 },
  { 0x8700, 0xa02b, 0x2000 },
  { 0x0700, 0xa02a, 0x0000 },
  { 0x0700, 0xa02c, 0x0000 },
  { 0x8700, 0xa03d, 0x5000 },
  { 0x8700, 0xa035, 0x4000 },
  { 0x8700, 0xa031, 0x3000 },
  { 0x8700, 0xa02f, 0x2000 },
  { 0x0700, 0xa02e, 0x0000 },
  { 0x0700, 0xa030, 0x0000 },
  { 0x8700, 0xa033, 0x2000 },
  { 0x0700, 0xa032, 0x0000 },
  { 0x0700, 0xa034, 0x0000 },
  { 0x8700, 0xa039, 0x3000 },
  { 0x8700, 0xa037, 0x2000 },
  { 0x0700, 0xa036, 0x0000 },
  { 0x0700, 0xa038, 0x0000 },
  { 0x8700, 0xa03b, 0x2000 },
  { 0x0700, 0xa03a, 0x0000 },
  { 0x0700, 0xa03c, 0x0000 },
  { 0x8700, 0xa045, 0x4000 },
  { 0x8700, 0xa041, 0x3000 },
  { 0x8700, 0xa03f, 0x2000 },
  { 0x0700, 0xa03e, 0x0000 },
  { 0x0700, 0xa040, 0x0000 },
  { 0x8700, 0xa043, 0x2000 },
  { 0x0700, 0xa042, 0x0000 },
  { 0x0700, 0xa044, 0x0000 },
  { 0x8700, 0xa049, 0x3000 },
  { 0x8700, 0xa047, 0x2000 },
  { 0x0700, 0xa046, 0x0000 },
  { 0x0700, 0xa048, 0x0000 },
  { 0x8700, 0xa04b, 0x2000 },
  { 0x0700, 0xa04a, 0x0000 },
  { 0x0700, 0xa04c, 0x0000 },
  { 0x8700, 0xa0cd, 0x8000 },
  { 0x8700, 0xa08d, 0x7000 },
  { 0x8700, 0xa06d, 0x6000 },
  { 0x8700, 0xa05d, 0x5000 },
  { 0x8700, 0xa055, 0x4000 },
  { 0x8700, 0xa051, 0x3000 },
  { 0x8700, 0xa04f, 0x2000 },
  { 0x0700, 0xa04e, 0x0000 },
  { 0x0700, 0xa050, 0x0000 },
  { 0x8700, 0xa053, 0x2000 },
  { 0x0700, 0xa052, 0x0000 },
  { 0x0700, 0xa054, 0x0000 },
  { 0x8700, 0xa059, 0x3000 },
  { 0x8700, 0xa057, 0x2000 },
  { 0x0700, 0xa056, 0x0000 },
  { 0x0700, 0xa058, 0x0000 },
  { 0x8700, 0xa05b, 0x2000 },
  { 0x0700, 0xa05a, 0x0000 },
  { 0x0700, 0xa05c, 0x0000 },
  { 0x8700, 0xa065, 0x4000 },
  { 0x8700, 0xa061, 0x3000 },
  { 0x8700, 0xa05f, 0x2000 },
  { 0x0700, 0xa05e, 0x0000 },
  { 0x0700, 0xa060, 0x0000 },
  { 0x8700, 0xa063, 0x2000 },
  { 0x0700, 0xa062, 0x0000 },
  { 0x0700, 0xa064, 0x0000 },
  { 0x8700, 0xa069, 0x3000 },
  { 0x8700, 0xa067, 0x2000 },
  { 0x0700, 0xa066, 0x0000 },
  { 0x0700, 0xa068, 0x0000 },
  { 0x8700, 0xa06b, 0x2000 },
  { 0x0700, 0xa06a, 0x0000 },
  { 0x0700, 0xa06c, 0x0000 },
  { 0x8700, 0xa07d, 0x5000 },
  { 0x8700, 0xa075, 0x4000 },
  { 0x8700, 0xa071, 0x3000 },
  { 0x8700, 0xa06f, 0x2000 },
  { 0x0700, 0xa06e, 0x0000 },
  { 0x0700, 0xa070, 0x0000 },
  { 0x8700, 0xa073, 0x2000 },
  { 0x0700, 0xa072, 0x0000 },
  { 0x0700, 0xa074, 0x0000 },
  { 0x8700, 0xa079, 0x3000 },
  { 0x8700, 0xa077, 0x2000 },
  { 0x0700, 0xa076, 0x0000 },
  { 0x0700, 0xa078, 0x0000 },
  { 0x8700, 0xa07b, 0x2000 },
  { 0x0700, 0xa07a, 0x0000 },
  { 0x0700, 0xa07c, 0x0000 },
  { 0x8700, 0xa085, 0x4000 },
  { 0x8700, 0xa081, 0x3000 },
  { 0x8700, 0xa07f, 0x2000 },
  { 0x0700, 0xa07e, 0x0000 },
  { 0x0700, 0xa080, 0x0000 },
  { 0x8700, 0xa083, 0x2000 },
  { 0x0700, 0xa082, 0x0000 },
  { 0x0700, 0xa084, 0x0000 },
  { 0x8700, 0xa089, 0x3000 },
  { 0x8700, 0xa087, 0x2000 },
  { 0x0700, 0xa086, 0x0000 },
  { 0x0700, 0xa088, 0x0000 },
  { 0x8700, 0xa08b, 0x2000 },
  { 0x0700, 0xa08a, 0x0000 },
  { 0x0700, 0xa08c, 0x0000 },
  { 0x8700, 0xa0ad, 0x6000 },
  { 0x8700, 0xa09d, 0x5000 },
  { 0x8700, 0xa095, 0x4000 },
  { 0x8700, 0xa091, 0x3000 },
  { 0x8700, 0xa08f, 0x2000 },
  { 0x0700, 0xa08e, 0x0000 },
  { 0x0700, 0xa090, 0x0000 },
  { 0x8700, 0xa093, 0x2000 },
  { 0x0700, 0xa092, 0x0000 },
  { 0x0700, 0xa094, 0x0000 },
  { 0x8700, 0xa099, 0x3000 },
  { 0x8700, 0xa097, 0x2000 },
  { 0x0700, 0xa096, 0x0000 },
  { 0x0700, 0xa098, 0x0000 },
  { 0x8700, 0xa09b, 0x2000 },
  { 0x0700, 0xa09a, 0x0000 },
  { 0x0700, 0xa09c, 0x0000 },
  { 0x8700, 0xa0a5, 0x4000 },
  { 0x8700, 0xa0a1, 0x3000 },
  { 0x8700, 0xa09f, 0x2000 },
  { 0x0700, 0xa09e, 0x0000 },
  { 0x0700, 0xa0a0, 0x0000 },
  { 0x8700, 0xa0a3, 0x2000 },
  { 0x0700, 0xa0a2, 0x0000 },
  { 0x0700, 0xa0a4, 0x0000 },
  { 0x8700, 0xa0a9, 0x3000 },
  { 0x8700, 0xa0a7, 0x2000 },
  { 0x0700, 0xa0a6, 0x0000 },
  { 0x0700, 0xa0a8, 0x0000 },
  { 0x8700, 0xa0ab, 0x2000 },
  { 0x0700, 0xa0aa, 0x0000 },
  { 0x0700, 0xa0ac, 0x0000 },
  { 0x8700, 0xa0bd, 0x5000 },
  { 0x8700, 0xa0b5, 0x4000 },
  { 0x8700, 0xa0b1, 0x3000 },
  { 0x8700, 0xa0af, 0x2000 },
  { 0x0700, 0xa0ae, 0x0000 },
  { 0x0700, 0xa0b0, 0x0000 },
  { 0x8700, 0xa0b3, 0x2000 },
  { 0x0700, 0xa0b2, 0x0000 },
  { 0x0700, 0xa0b4, 0x0000 },
  { 0x8700, 0xa0b9, 0x3000 },
  { 0x8700, 0xa0b7, 0x2000 },
  { 0x0700, 0xa0b6, 0x0000 },
  { 0x0700, 0xa0b8, 0x0000 },
  { 0x8700, 0xa0bb, 0x2000 },
  { 0x0700, 0xa0ba, 0x0000 },
  { 0x0700, 0xa0bc, 0x0000 },
  { 0x8700, 0xa0c5, 0x4000 },
  { 0x8700, 0xa0c1, 0x3000 },
  { 0x8700, 0xa0bf, 0x2000 },
  { 0x0700, 0xa0be, 0x0000 },
  { 0x0700, 0xa0c0, 0x0000 },
  { 0x8700, 0xa0c3, 0x2000 },
  { 0x0700, 0xa0c2, 0x0000 },
  { 0x0700, 0xa0c4, 0x0000 },
  { 0x8700, 0xa0c9, 0x3000 },
  { 0x8700, 0xa0c7, 0x2000 },
  { 0x0700, 0xa0c6, 0x0000 },
  { 0x0700, 0xa0c8, 0x0000 },
  { 0x8700, 0xa0cb, 0x2000 },
  { 0x0700, 0xa0ca, 0x0000 },
  { 0x0700, 0xa0cc, 0x0000 },
  { 0x8700, 0xa10d, 0x7000 },
  { 0x8700, 0xa0ed, 0x6000 },
  { 0x8700, 0xa0dd, 0x5000 },
  { 0x8700, 0xa0d5, 0x4000 },
  { 0x8700, 0xa0d1, 0x3000 },
  { 0x8700, 0xa0cf, 0x2000 },
  { 0x0700, 0xa0ce, 0x0000 },
  { 0x0700, 0xa0d0, 0x0000 },
  { 0x8700, 0xa0d3, 0x2000 },
  { 0x0700, 0xa0d2, 0x0000 },
  { 0x0700, 0xa0d4, 0x0000 },
  { 0x8700, 0xa0d9, 0x3000 },
  { 0x8700, 0xa0d7, 0x2000 },
  { 0x0700, 0xa0d6, 0x0000 },
  { 0x0700, 0xa0d8, 0x0000 },
  { 0x8700, 0xa0db, 0x2000 },
  { 0x0700, 0xa0da, 0x0000 },
  { 0x0700, 0xa0dc, 0x0000 },
  { 0x8700, 0xa0e5, 0x4000 },
  { 0x8700, 0xa0e1, 0x3000 },
  { 0x8700, 0xa0df, 0x2000 },
  { 0x0700, 0xa0de, 0x0000 },
  { 0x0700, 0xa0e0, 0x0000 },
  { 0x8700, 0xa0e3, 0x2000 },
  { 0x0700, 0xa0e2, 0x0000 },
  { 0x0700, 0xa0e4, 0x0000 },
  { 0x8700, 0xa0e9, 0x3000 },
  { 0x8700, 0xa0e7, 0x2000 },
  { 0x0700, 0xa0e6, 0x0000 },
  { 0x0700, 0xa0e8, 0x0000 },
  { 0x8700, 0xa0eb, 0x2000 },
  { 0x0700, 0xa0ea, 0x0000 },
  { 0x0700, 0xa0ec, 0x0000 },
  { 0x8700, 0xa0fd, 0x5000 },
  { 0x8700, 0xa0f5, 0x4000 },
  { 0x8700, 0xa0f1, 0x3000 },
  { 0x8700, 0xa0ef, 0x2000 },
  { 0x0700, 0xa0ee, 0x0000 },
  { 0x0700, 0xa0f0, 0x0000 },
  { 0x8700, 0xa0f3, 0x2000 },
  { 0x0700, 0xa0f2, 0x0000 },
  { 0x0700, 0xa0f4, 0x0000 },
  { 0x8700, 0xa0f9, 0x3000 },
  { 0x8700, 0xa0f7, 0x2000 },
  { 0x0700, 0xa0f6, 0x0000 },
  { 0x0700, 0xa0f8, 0x0000 },
  { 0x8700, 0xa0fb, 0x2000 },
  { 0x0700, 0xa0fa, 0x0000 },
  { 0x0700, 0xa0fc, 0x0000 },
  { 0x8700, 0xa105, 0x4000 },
  { 0x8700, 0xa101, 0x3000 },
  { 0x8700, 0xa0ff, 0x2000 },
  { 0x0700, 0xa0fe, 0x0000 },
  { 0x0700, 0xa100, 0x0000 },
  { 0x8700, 0xa103, 0x2000 },
  { 0x0700, 0xa102, 0x0000 },
  { 0x0700, 0xa104, 0x0000 },
  { 0x8700, 0xa109, 0x3000 },
  { 0x8700, 0xa107, 0x2000 },
  { 0x0700, 0xa106, 0x0000 },
  { 0x0700, 0xa108, 0x0000 },
  { 0x8700, 0xa10b, 0x2000 },
  { 0x0700, 0xa10a, 0x0000 },
  { 0x0700, 0xa10c, 0x0000 },
  { 0x8700, 0xa12d, 0x6000 },
  { 0x8700, 0xa11d, 0x5000 },
  { 0x8700, 0xa115, 0x4000 },
  { 0x8700, 0xa111, 0x3000 },
  { 0x8700, 0xa10f, 0x2000 },
  { 0x0700, 0xa10e, 0x0000 },
  { 0x0700, 0xa110, 0x0000 },
  { 0x8700, 0xa113, 0x2000 },
  { 0x0700, 0xa112, 0x0000 },
  { 0x0700, 0xa114, 0x0000 },
  { 0x8700, 0xa119, 0x3000 },
  { 0x8700, 0xa117, 0x2000 },
  { 0x0700, 0xa116, 0x0000 },
  { 0x0700, 0xa118, 0x0000 },
  { 0x8700, 0xa11b, 0x2000 },
  { 0x0700, 0xa11a, 0x0000 },
  { 0x0700, 0xa11c, 0x0000 },
  { 0x8700, 0xa125, 0x4000 },
  { 0x8700, 0xa121, 0x3000 },
  { 0x8700, 0xa11f, 0x2000 },
  { 0x0700, 0xa11e, 0x0000 },
  { 0x0700, 0xa120, 0x0000 },
  { 0x8700, 0xa123, 0x2000 },
  { 0x0700, 0xa122, 0x0000 },
  { 0x0700, 0xa124, 0x0000 },
  { 0x8700, 0xa129, 0x3000 },
  { 0x8700, 0xa127, 0x2000 },
  { 0x0700, 0xa126, 0x0000 },
  { 0x0700, 0xa128, 0x0000 },
  { 0x8700, 0xa12b, 0x2000 },
  { 0x0700, 0xa12a, 0x0000 },
  { 0x0700, 0xa12c, 0x0000 },
  { 0x8700, 0xa13d, 0x5000 },
  { 0x8700, 0xa135, 0x4000 },
  { 0x8700, 0xa131, 0x3000 },
  { 0x8700, 0xa12f, 0x2000 },
  { 0x0700, 0xa12e, 0x0000 },
  { 0x0700, 0xa130, 0x0000 },
  { 0x8700, 0xa133, 0x2000 },
  { 0x0700, 0xa132, 0x0000 },
  { 0x0700, 0xa134, 0x0000 },
  { 0x8700, 0xa139, 0x3000 },
  { 0x8700, 0xa137, 0x2000 },
  { 0x0700, 0xa136, 0x0000 },
  { 0x0700, 0xa138, 0x0000 },
  { 0x8700, 0xa13b, 0x2000 },
  { 0x0700, 0xa13a, 0x0000 },
  { 0x0700, 0xa13c, 0x0000 },
  { 0x8700, 0xa145, 0x4000 },
  { 0x8700, 0xa141, 0x3000 },
  { 0x8700, 0xa13f, 0x2000 },
  { 0x0700, 0xa13e, 0x0000 },
  { 0x0700, 0xa140, 0x0000 },
  { 0x8700, 0xa143, 0x2000 },
  { 0x0700, 0xa142, 0x0000 },
  { 0x0700, 0xa144, 0x0000 },
  { 0x8700, 0xa149, 0x3000 },
  { 0x8700, 0xa147, 0x2000 },
  { 0x0700, 0xa146, 0x0000 },
  { 0x0700, 0xa148, 0x0000 },
  { 0x8700, 0xa14b, 0x2000 },
  { 0x0700, 0xa14a, 0x0000 },
  { 0x0700, 0xa14c, 0x0000 },
  { 0x8700, 0xa24d, 0x9000 },
  { 0x8700, 0xa1cd, 0x8000 },
  { 0x8700, 0xa18d, 0x7000 },
  { 0x8700, 0xa16d, 0x6000 },
  { 0x8700, 0xa15d, 0x5000 },
  { 0x8700, 0xa155, 0x4000 },
  { 0x8700, 0xa151, 0x3000 },
  { 0x8700, 0xa14f, 0x2000 },
  { 0x0700, 0xa14e, 0x0000 },
  { 0x0700, 0xa150, 0x0000 },
  { 0x8700, 0xa153, 0x2000 },
  { 0x0700, 0xa152, 0x0000 },
  { 0x0700, 0xa154, 0x0000 },
  { 0x8700, 0xa159, 0x3000 },
  { 0x8700, 0xa157, 0x2000 },
  { 0x0700, 0xa156, 0x0000 },
  { 0x0700, 0xa158, 0x0000 },
  { 0x8700, 0xa15b, 0x2000 },
  { 0x0700, 0xa15a, 0x0000 },
  { 0x0700, 0xa15c, 0x0000 },
  { 0x8700, 0xa165, 0x4000 },
  { 0x8700, 0xa161, 0x3000 },
  { 0x8700, 0xa15f, 0x2000 },
  { 0x0700, 0xa15e, 0x0000 },
  { 0x0700, 0xa160, 0x0000 },
  { 0x8700, 0xa163, 0x2000 },
  { 0x0700, 0xa162, 0x0000 },
  { 0x0700, 0xa164, 0x0000 },
  { 0x8700, 0xa169, 0x3000 },
  { 0x8700, 0xa167, 0x2000 },
  { 0x0700, 0xa166, 0x0000 },
  { 0x0700, 0xa168, 0x0000 },
  { 0x8700, 0xa16b, 0x2000 },
  { 0x0700, 0xa16a, 0x0000 },
  { 0x0700, 0xa16c, 0x0000 },
  { 0x8700, 0xa17d, 0x5000 },
  { 0x8700, 0xa175, 0x4000 },
  { 0x8700, 0xa171, 0x3000 },
  { 0x8700, 0xa16f, 0x2000 },
  { 0x0700, 0xa16e, 0x0000 },
  { 0x0700, 0xa170, 0x0000 },
  { 0x8700, 0xa173, 0x2000 },
  { 0x0700, 0xa172, 0x0000 },
  { 0x0700, 0xa174, 0x0000 },
  { 0x8700, 0xa179, 0x3000 },
  { 0x8700, 0xa177, 0x2000 },
  { 0x0700, 0xa176, 0x0000 },
  { 0x0700, 0xa178, 0x0000 },
  { 0x8700, 0xa17b, 0x2000 },
  { 0x0700, 0xa17a, 0x0000 },
  { 0x0700, 0xa17c, 0x0000 },
  { 0x8700, 0xa185, 0x4000 },
  { 0x8700, 0xa181, 0x3000 },
  { 0x8700, 0xa17f, 0x2000 },
  { 0x0700, 0xa17e, 0x0000 },
  { 0x0700, 0xa180, 0x0000 },
  { 0x8700, 0xa183, 0x2000 },
  { 0x0700, 0xa182, 0x0000 },
  { 0x0700, 0xa184, 0x0000 },
  { 0x8700, 0xa189, 0x3000 },
  { 0x8700, 0xa187, 0x2000 },
  { 0x0700, 0xa186, 0x0000 },
  { 0x0700, 0xa188, 0x0000 },
  { 0x8700, 0xa18b, 0x2000 },
  { 0x0700, 0xa18a, 0x0000 },
  { 0x0700, 0xa18c, 0x0000 },
  { 0x8700, 0xa1ad, 0x6000 },
  { 0x8700, 0xa19d, 0x5000 },
  { 0x8700, 0xa195, 0x4000 },
  { 0x8700, 0xa191, 0x3000 },
  { 0x8700, 0xa18f, 0x2000 },
  { 0x0700, 0xa18e, 0x0000 },
  { 0x0700, 0xa190, 0x0000 },
  { 0x8700, 0xa193, 0x2000 },
  { 0x0700, 0xa192, 0x0000 },
  { 0x0700, 0xa194, 0x0000 },
  { 0x8700, 0xa199, 0x3000 },
  { 0x8700, 0xa197, 0x2000 },
  { 0x0700, 0xa196, 0x0000 },
  { 0x0700, 0xa198, 0x0000 },
  { 0x8700, 0xa19b, 0x2000 },
  { 0x0700, 0xa19a, 0x0000 },
  { 0x0700, 0xa19c, 0x0000 },
  { 0x8700, 0xa1a5, 0x4000 },
  { 0x8700, 0xa1a1, 0x3000 },
  { 0x8700, 0xa19f, 0x2000 },
  { 0x0700, 0xa19e, 0x0000 },
  { 0x0700, 0xa1a0, 0x0000 },
  { 0x8700, 0xa1a3, 0x2000 },
  { 0x0700, 0xa1a2, 0x0000 },
  { 0x0700, 0xa1a4, 0x0000 },
  { 0x8700, 0xa1a9, 0x3000 },
  { 0x8700, 0xa1a7, 0x2000 },
  { 0x0700, 0xa1a6, 0x0000 },
  { 0x0700, 0xa1a8, 0x0000 },
  { 0x8700, 0xa1ab, 0x2000 },
  { 0x0700, 0xa1aa, 0x0000 },
  { 0x0700, 0xa1ac, 0x0000 },
  { 0x8700, 0xa1bd, 0x5000 },
  { 0x8700, 0xa1b5, 0x4000 },
  { 0x8700, 0xa1b1, 0x3000 },
  { 0x8700, 0xa1af, 0x2000 },
  { 0x0700, 0xa1ae, 0x0000 },
  { 0x0700, 0xa1b0, 0x0000 },
  { 0x8700, 0xa1b3, 0x2000 },
  { 0x0700, 0xa1b2, 0x0000 },
  { 0x0700, 0xa1b4, 0x0000 },
  { 0x8700, 0xa1b9, 0x3000 },
  { 0x8700, 0xa1b7, 0x2000 },
  { 0x0700, 0xa1b6, 0x0000 },
  { 0x0700, 0xa1b8, 0x0000 },
  { 0x8700, 0xa1bb, 0x2000 },
  { 0x0700, 0xa1ba, 0x0000 },
  { 0x0700, 0xa1bc, 0x0000 },
  { 0x8700, 0xa1c5, 0x4000 },
  { 0x8700, 0xa1c1, 0x3000 },
  { 0x8700, 0xa1bf, 0x2000 },
  { 0x0700, 0xa1be, 0x0000 },
  { 0x0700, 0xa1c0, 0x0000 },
  { 0x8700, 0xa1c3, 0x2000 },
  { 0x0700, 0xa1c2, 0x0000 },
  { 0x0700, 0xa1c4, 0x0000 },
  { 0x8700, 0xa1c9, 0x3000 },
  { 0x8700, 0xa1c7, 0x2000 },
  { 0x0700, 0xa1c6, 0x0000 },
  { 0x0700, 0xa1c8, 0x0000 },
  { 0x8700, 0xa1cb, 0x2000 },
  { 0x0700, 0xa1ca, 0x0000 },
  { 0x0700, 0xa1cc, 0x0000 },
  { 0x8700, 0xa20d, 0x7000 },
  { 0x8700, 0xa1ed, 0x6000 },
  { 0x8700, 0xa1dd, 0x5000 },
  { 0x8700, 0xa1d5, 0x4000 },
  { 0x8700, 0xa1d1, 0x3000 },
  { 0x8700, 0xa1cf, 0x2000 },
  { 0x0700, 0xa1ce, 0x0000 },
  { 0x0700, 0xa1d0, 0x0000 },
  { 0x8700, 0xa1d3, 0x2000 },
  { 0x0700, 0xa1d2, 0x0000 },
  { 0x0700, 0xa1d4, 0x0000 },
  { 0x8700, 0xa1d9, 0x3000 },
  { 0x8700, 0xa1d7, 0x2000 },
  { 0x0700, 0xa1d6, 0x0000 },
  { 0x0700, 0xa1d8, 0x0000 },
  { 0x8700, 0xa1db, 0x2000 },
  { 0x0700, 0xa1da, 0x0000 },
  { 0x0700, 0xa1dc, 0x0000 },
  { 0x8700, 0xa1e5, 0x4000 },
  { 0x8700, 0xa1e1, 0x3000 },
  { 0x8700, 0xa1df, 0x2000 },
  { 0x0700, 0xa1de, 0x0000 },
  { 0x0700, 0xa1e0, 0x0000 },
  { 0x8700, 0xa1e3, 0x2000 },
  { 0x0700, 0xa1e2, 0x0000 },
  { 0x0700, 0xa1e4, 0x0000 },
  { 0x8700, 0xa1e9, 0x3000 },
  { 0x8700, 0xa1e7, 0x2000 },
  { 0x0700, 0xa1e6, 0x0000 },
  { 0x0700, 0xa1e8, 0x0000 },
  { 0x8700, 0xa1eb, 0x2000 },
  { 0x0700, 0xa1ea, 0x0000 },
  { 0x0700, 0xa1ec, 0x0000 },
  { 0x8700, 0xa1fd, 0x5000 },
  { 0x8700, 0xa1f5, 0x4000 },
  { 0x8700, 0xa1f1, 0x3000 },
  { 0x8700, 0xa1ef, 0x2000 },
  { 0x0700, 0xa1ee, 0x0000 },
  { 0x0700, 0xa1f0, 0x0000 },
  { 0x8700, 0xa1f3, 0x2000 },
  { 0x0700, 0xa1f2, 0x0000 },
  { 0x0700, 0xa1f4, 0x0000 },
  { 0x8700, 0xa1f9, 0x3000 },
  { 0x8700, 0xa1f7, 0x2000 },
  { 0x0700, 0xa1f6, 0x0000 },
  { 0x0700, 0xa1f8, 0x0000 },
  { 0x8700, 0xa1fb, 0x2000 },
  { 0x0700, 0xa1fa, 0x0000 },
  { 0x0700, 0xa1fc, 0x0000 },
  { 0x8700, 0xa205, 0x4000 },
  { 0x8700, 0xa201, 0x3000 },
  { 0x8700, 0xa1ff, 0x2000 },
  { 0x0700, 0xa1fe, 0x0000 },
  { 0x0700, 0xa200, 0x0000 },
  { 0x8700, 0xa203, 0x2000 },
  { 0x0700, 0xa202, 0x0000 },
  { 0x0700, 0xa204, 0x0000 },
  { 0x8700, 0xa209, 0x3000 },
  { 0x8700, 0xa207, 0x2000 },
  { 0x0700, 0xa206, 0x0000 },
  { 0x0700, 0xa208, 0x0000 },
  { 0x8700, 0xa20b, 0x2000 },
  { 0x0700, 0xa20a, 0x0000 },
  { 0x0700, 0xa20c, 0x0000 },
  { 0x8700, 0xa22d, 0x6000 },
  { 0x8700, 0xa21d, 0x5000 },
  { 0x8700, 0xa215, 0x4000 },
  { 0x8700, 0xa211, 0x3000 },
  { 0x8700, 0xa20f, 0x2000 },
  { 0x0700, 0xa20e, 0x0000 },
  { 0x0700, 0xa210, 0x0000 },
  { 0x8700, 0xa213, 0x2000 },
  { 0x0700, 0xa212, 0x0000 },
  { 0x0700, 0xa214, 0x0000 },
  { 0x8700, 0xa219, 0x3000 },
  { 0x8700, 0xa217, 0x2000 },
  { 0x0700, 0xa216, 0x0000 },
  { 0x0700, 0xa218, 0x0000 },
  { 0x8700, 0xa21b, 0x2000 },
  { 0x0700, 0xa21a, 0x0000 },
  { 0x0700, 0xa21c, 0x0000 },
  { 0x8700, 0xa225, 0x4000 },
  { 0x8700, 0xa221, 0x3000 },
  { 0x8700, 0xa21f, 0x2000 },
  { 0x0700, 0xa21e, 0x0000 },
  { 0x0700, 0xa220, 0x0000 },
  { 0x8700, 0xa223, 0x2000 },
  { 0x0700, 0xa222, 0x0000 },
  { 0x0700, 0xa224, 0x0000 },
  { 0x8700, 0xa229, 0x3000 },
  { 0x8700, 0xa227, 0x2000 },
  { 0x0700, 0xa226, 0x0000 },
  { 0x0700, 0xa228, 0x0000 },
  { 0x8700, 0xa22b, 0x2000 },
  { 0x0700, 0xa22a, 0x0000 },
  { 0x0700, 0xa22c, 0x0000 },
  { 0x8700, 0xa23d, 0x5000 },
  { 0x8700, 0xa235, 0x4000 },
  { 0x8700, 0xa231, 0x3000 },
  { 0x8700, 0xa22f, 0x2000 },
  { 0x0700, 0xa22e, 0x0000 },
  { 0x0700, 0xa230, 0x0000 },
  { 0x8700, 0xa233, 0x2000 },
  { 0x0700, 0xa232, 0x0000 },
  { 0x0700, 0xa234, 0x0000 },
  { 0x8700, 0xa239, 0x3000 },
  { 0x8700, 0xa237, 0x2000 },
  { 0x0700, 0xa236, 0x0000 },
  { 0x0700, 0xa238, 0x0000 },
  { 0x8700, 0xa23b, 0x2000 },
  { 0x0700, 0xa23a, 0x0000 },
  { 0x0700, 0xa23c, 0x0000 },
  { 0x8700, 0xa245, 0x4000 },
  { 0x8700, 0xa241, 0x3000 },
  { 0x8700, 0xa23f, 0x2000 },
  { 0x0700, 0xa23e, 0x0000 },
  { 0x0700, 0xa240, 0x0000 },
  { 0x8700, 0xa243, 0x2000 },
  { 0x0700, 0xa242, 0x0000 },
  { 0x0700, 0xa244, 0x0000 },
  { 0x8700, 0xa249, 0x3000 },
  { 0x8700, 0xa247, 0x2000 },
  { 0x0700, 0xa246, 0x0000 },
  { 0x0700, 0xa248, 0x0000 },
  { 0x8700, 0xa24b, 0x2000 },
  { 0x0700, 0xa24a, 0x0000 },
  { 0x0700, 0xa24c, 0x0000 },
  { 0x8700, 0xa2cd, 0x8000 },
  { 0x8700, 0xa28d, 0x7000 },
  { 0x8700, 0xa26d, 0x6000 },
  { 0x8700, 0xa25d, 0x5000 },
  { 0x8700, 0xa255, 0x4000 },
  { 0x8700, 0xa251, 0x3000 },
  { 0x8700, 0xa24f, 0x2000 },
  { 0x0700, 0xa24e, 0x0000 },
  { 0x0700, 0xa250, 0x0000 },
  { 0x8700, 0xa253, 0x2000 },
  { 0x0700, 0xa252, 0x0000 },
  { 0x0700, 0xa254, 0x0000 },
  { 0x8700, 0xa259, 0x3000 },
  { 0x8700, 0xa257, 0x2000 },
  { 0x0700, 0xa256, 0x0000 },
  { 0x0700, 0xa258, 0x0000 },
  { 0x8700, 0xa25b, 0x2000 },
  { 0x0700, 0xa25a, 0x0000 },
  { 0x0700, 0xa25c, 0x0000 },
  { 0x8700, 0xa265, 0x4000 },
  { 0x8700, 0xa261, 0x3000 },
  { 0x8700, 0xa25f, 0x2000 },
  { 0x0700, 0xa25e, 0x0000 },
  { 0x0700, 0xa260, 0x0000 },
  { 0x8700, 0xa263, 0x2000 },
  { 0x0700, 0xa262, 0x0000 },
  { 0x0700, 0xa264, 0x0000 },
  { 0x8700, 0xa269, 0x3000 },
  { 0x8700, 0xa267, 0x2000 },
  { 0x0700, 0xa266, 0x0000 },
  { 0x0700, 0xa268, 0x0000 },
  { 0x8700, 0xa26b, 0x2000 },
  { 0x0700, 0xa26a, 0x0000 },
  { 0x0700, 0xa26c, 0x0000 },
  { 0x8700, 0xa27d, 0x5000 },
  { 0x8700, 0xa275, 0x4000 },
  { 0x8700, 0xa271, 0x3000 },
  { 0x8700, 0xa26f, 0x2000 },
  { 0x0700, 0xa26e, 0x0000 },
  { 0x0700, 0xa270, 0x0000 },
  { 0x8700, 0xa273, 0x2000 },
  { 0x0700, 0xa272, 0x0000 },
  { 0x0700, 0xa274, 0x0000 },
  { 0x8700, 0xa279, 0x3000 },
  { 0x8700, 0xa277, 0x2000 },
  { 0x0700, 0xa276, 0x0000 },
  { 0x0700, 0xa278, 0x0000 },
  { 0x8700, 0xa27b, 0x2000 },
  { 0x0700, 0xa27a, 0x0000 },
  { 0x0700, 0xa27c, 0x0000 },
  { 0x8700, 0xa285, 0x4000 },
  { 0x8700, 0xa281, 0x3000 },
  { 0x8700, 0xa27f, 0x2000 },
  { 0x0700, 0xa27e, 0x0000 },
  { 0x0700, 0xa280, 0x0000 },
  { 0x8700, 0xa283, 0x2000 },
  { 0x0700, 0xa282, 0x0000 },
  { 0x0700, 0xa284, 0x0000 },
  { 0x8700, 0xa289, 0x3000 },
  { 0x8700, 0xa287, 0x2000 },
  { 0x0700, 0xa286, 0x0000 },
  { 0x0700, 0xa288, 0x0000 },
  { 0x8700, 0xa28b, 0x2000 },
  { 0x0700, 0xa28a, 0x0000 },
  { 0x0700, 0xa28c, 0x0000 },
  { 0x8700, 0xa2ad, 0x6000 },
  { 0x8700, 0xa29d, 0x5000 },
  { 0x8700, 0xa295, 0x4000 },
  { 0x8700, 0xa291, 0x3000 },
  { 0x8700, 0xa28f, 0x2000 },
  { 0x0700, 0xa28e, 0x0000 },
  { 0x0700, 0xa290, 0x0000 },
  { 0x8700, 0xa293, 0x2000 },
  { 0x0700, 0xa292, 0x0000 },
  { 0x0700, 0xa294, 0x0000 },
  { 0x8700, 0xa299, 0x3000 },
  { 0x8700, 0xa297, 0x2000 },
  { 0x0700, 0xa296, 0x0000 },
  { 0x0700, 0xa298, 0x0000 },
  { 0x8700, 0xa29b, 0x2000 },
  { 0x0700, 0xa29a, 0x0000 },
  { 0x0700, 0xa29c, 0x0000 },
  { 0x8700, 0xa2a5, 0x4000 },
  { 0x8700, 0xa2a1, 0x3000 },
  { 0x8700, 0xa29f, 0x2000 },
  { 0x0700, 0xa29e, 0x0000 },
  { 0x0700, 0xa2a0, 0x0000 },
  { 0x8700, 0xa2a3, 0x2000 },
  { 0x0700, 0xa2a2, 0x0000 },
  { 0x0700, 0xa2a4, 0x0000 },
  { 0x8700, 0xa2a9, 0x3000 },
  { 0x8700, 0xa2a7, 0x2000 },
  { 0x0700, 0xa2a6, 0x0000 },
  { 0x0700, 0xa2a8, 0x0000 },
  { 0x8700, 0xa2ab, 0x2000 },
  { 0x0700, 0xa2aa, 0x0000 },
  { 0x0700, 0xa2ac, 0x0000 },
  { 0x8700, 0xa2bd, 0x5000 },
  { 0x8700, 0xa2b5, 0x4000 },
  { 0x8700, 0xa2b1, 0x3000 },
  { 0x8700, 0xa2af, 0x2000 },
  { 0x0700, 0xa2ae, 0x0000 },
  { 0x0700, 0xa2b0, 0x0000 },
  { 0x8700, 0xa2b3, 0x2000 },
  { 0x0700, 0xa2b2, 0x0000 },
  { 0x0700, 0xa2b4, 0x0000 },
  { 0x8700, 0xa2b9, 0x3000 },
  { 0x8700, 0xa2b7, 0x2000 },
  { 0x0700, 0xa2b6, 0x0000 },
  { 0x0700, 0xa2b8, 0x0000 },
  { 0x8700, 0xa2bb, 0x2000 },
  { 0x0700, 0xa2ba, 0x0000 },
  { 0x0700, 0xa2bc, 0x0000 },
  { 0x8700, 0xa2c5, 0x4000 },
  { 0x8700, 0xa2c1, 0x3000 },
  { 0x8700, 0xa2bf, 0x2000 },
  { 0x0700, 0xa2be, 0x0000 },
  { 0x0700, 0xa2c0, 0x0000 },
  { 0x8700, 0xa2c3, 0x2000 },
  { 0x0700, 0xa2c2, 0x0000 },
  { 0x0700, 0xa2c4, 0x0000 },
  { 0x8700, 0xa2c9, 0x3000 },
  { 0x8700, 0xa2c7, 0x2000 },
  { 0x0700, 0xa2c6, 0x0000 },
  { 0x0700, 0xa2c8, 0x0000 },
  { 0x8700, 0xa2cb, 0x2000 },
  { 0x0700, 0xa2ca, 0x0000 },
  { 0x0700, 0xa2cc, 0x0000 },
  { 0x8700, 0xa30d, 0x7000 },
  { 0x8700, 0xa2ed, 0x6000 },
  { 0x8700, 0xa2dd, 0x5000 },
  { 0x8700, 0xa2d5, 0x4000 },
  { 0x8700, 0xa2d1, 0x3000 },
  { 0x8700, 0xa2cf, 0x2000 },
  { 0x0700, 0xa2ce, 0x0000 },
  { 0x0700, 0xa2d0, 0x0000 },
  { 0x8700, 0xa2d3, 0x2000 },
  { 0x0700, 0xa2d2, 0x0000 },
  { 0x0700, 0xa2d4, 0x0000 },
  { 0x8700, 0xa2d9, 0x3000 },
  { 0x8700, 0xa2d7, 0x2000 },
  { 0x0700, 0xa2d6, 0x0000 },
  { 0x0700, 0xa2d8, 0x0000 },
  { 0x8700, 0xa2db, 0x2000 },
  { 0x0700, 0xa2da, 0x0000 },
  { 0x0700, 0xa2dc, 0x0000 },
  { 0x8700, 0xa2e5, 0x4000 },
  { 0x8700, 0xa2e1, 0x3000 },
  { 0x8700, 0xa2df, 0x2000 },
  { 0x0700, 0xa2de, 0x0000 },
  { 0x0700, 0xa2e0, 0x0000 },
  { 0x8700, 0xa2e3, 0x2000 },
  { 0x0700, 0xa2e2, 0x0000 },
  { 0x0700, 0xa2e4, 0x0000 },
  { 0x8700, 0xa2e9, 0x3000 },
  { 0x8700, 0xa2e7, 0x2000 },
  { 0x0700, 0xa2e6, 0x0000 },
  { 0x0700, 0xa2e8, 0x0000 },
  { 0x8700, 0xa2eb, 0x2000 },
  { 0x0700, 0xa2ea, 0x0000 },
  { 0x0700, 0xa2ec, 0x0000 },
  { 0x8700, 0xa2fd, 0x5000 },
  { 0x8700, 0xa2f5, 0x4000 },
  { 0x8700, 0xa2f1, 0x3000 },
  { 0x8700, 0xa2ef, 0x2000 },
  { 0x0700, 0xa2ee, 0x0000 },
  { 0x0700, 0xa2f0, 0x0000 },
  { 0x8700, 0xa2f3, 0x2000 },
  { 0x0700, 0xa2f2, 0x0000 },
  { 0x0700, 0xa2f4, 0x0000 },
  { 0x8700, 0xa2f9, 0x3000 },
  { 0x8700, 0xa2f7, 0x2000 },
  { 0x0700, 0xa2f6, 0x0000 },
  { 0x0700, 0xa2f8, 0x0000 },
  { 0x8700, 0xa2fb, 0x2000 },
  { 0x0700, 0xa2fa, 0x0000 },
  { 0x0700, 0xa2fc, 0x0000 },
  { 0x8700, 0xa305, 0x4000 },
  { 0x8700, 0xa301, 0x3000 },
  { 0x8700, 0xa2ff, 0x2000 },
  { 0x0700, 0xa2fe, 0x0000 },
  { 0x0700, 0xa300, 0x0000 },
  { 0x8700, 0xa303, 0x2000 },
  { 0x0700, 0xa302, 0x0000 },
  { 0x0700, 0xa304, 0x0000 },
  { 0x8700, 0xa309, 0x3000 },
  { 0x8700, 0xa307, 0x2000 },
  { 0x0700, 0xa306, 0x0000 },
  { 0x0700, 0xa308, 0x0000 },
  { 0x8700, 0xa30b, 0x2000 },
  { 0x0700, 0xa30a, 0x0000 },
  { 0x0700, 0xa30c, 0x0000 },
  { 0x8700, 0xa32d, 0x6000 },
  { 0x8700, 0xa31d, 0x5000 },
  { 0x8700, 0xa315, 0x4000 },
  { 0x8700, 0xa311, 0x3000 },
  { 0x8700, 0xa30f, 0x2000 },
  { 0x0700, 0xa30e, 0x0000 },
  { 0x0700, 0xa310, 0x0000 },
  { 0x8700, 0xa313, 0x2000 },
  { 0x0700, 0xa312, 0x0000 },
  { 0x0700, 0xa314, 0x0000 },
  { 0x8700, 0xa319, 0x3000 },
  { 0x8700, 0xa317, 0x2000 },
  { 0x0700, 0xa316, 0x0000 },
  { 0x0700, 0xa318, 0x0000 },
  { 0x8700, 0xa31b, 0x2000 },
  { 0x0700, 0xa31a, 0x0000 },
  { 0x0700, 0xa31c, 0x0000 },
  { 0x8700, 0xa325, 0x4000 },
  { 0x8700, 0xa321, 0x3000 },
  { 0x8700, 0xa31f, 0x2000 },
  { 0x0700, 0xa31e, 0x0000 },
  { 0x0700, 0xa320, 0x0000 },
  { 0x8700, 0xa323, 0x2000 },
  { 0x0700, 0xa322, 0x0000 },
  { 0x0700, 0xa324, 0x0000 },
  { 0x8700, 0xa329, 0x3000 },
  { 0x8700, 0xa327, 0x2000 },
  { 0x0700, 0xa326, 0x0000 },
  { 0x0700, 0xa328, 0x0000 },
  { 0x8700, 0xa32b, 0x2000 },
  { 0x0700, 0xa32a, 0x0000 },
  { 0x0700, 0xa32c, 0x0000 },
  { 0x8700, 0xa33d, 0x5000 },
  { 0x8700, 0xa335, 0x4000 },
  { 0x8700, 0xa331, 0x3000 },
  { 0x8700, 0xa32f, 0x2000 },
  { 0x0700, 0xa32e, 0x0000 },
  { 0x0700, 0xa330, 0x0000 },
  { 0x8700, 0xa333, 0x2000 },
  { 0x0700, 0xa332, 0x0000 },
  { 0x0700, 0xa334, 0x0000 },
  { 0x8700, 0xa339, 0x3000 },
  { 0x8700, 0xa337, 0x2000 },
  { 0x0700, 0xa336, 0x0000 },
  { 0x0700, 0xa338, 0x0000 },
  { 0x8700, 0xa33b, 0x2000 },
  { 0x0700, 0xa33a, 0x0000 },
  { 0x0700, 0xa33c, 0x0000 },
  { 0x8700, 0xa345, 0x4000 },
  { 0x8700, 0xa341, 0x3000 },
  { 0x8700, 0xa33f, 0x2000 },
  { 0x0700, 0xa33e, 0x0000 },
  { 0x0700, 0xa340, 0x0000 },
  { 0x8700, 0xa343, 0x2000 },
  { 0x0700, 0xa342, 0x0000 },
  { 0x0700, 0xa344, 0x0000 },
  { 0x8700, 0xa349, 0x3000 },
  { 0x8700, 0xa347, 0x2000 },
  { 0x0700, 0xa346, 0x0000 },
  { 0x0700, 0xa348, 0x0000 },
  { 0x8700, 0xa34b, 0x2000 },
  { 0x0700, 0xa34a, 0x0000 },
  { 0x0700, 0xa34c, 0x0000 },
  { 0x8700, 0xfc4d, 0xb000 },
  { 0x8700, 0xf97f, 0xa000 },
  { 0x8700, 0xa44d, 0x9000 },
  { 0x8700, 0xa3cd, 0x8000 },
  { 0x8700, 0xa38d, 0x7000 },
  { 0x8700, 0xa36d, 0x6000 },
  { 0x8700, 0xa35d, 0x5000 },
  { 0x8700, 0xa355, 0x4000 },
  { 0x8700, 0xa351, 0x3000 },
  { 0x8700, 0xa34f, 0x2000 },
  { 0x0700, 0xa34e, 0x0000 },
  { 0x0700, 0xa350, 0x0000 },
  { 0x8700, 0xa353, 0x2000 },
  { 0x0700, 0xa352, 0x0000 },
  { 0x0700, 0xa354, 0x0000 },
  { 0x8700, 0xa359, 0x3000 },
  { 0x8700, 0xa357, 0x2000 },
  { 0x0700, 0xa356, 0x0000 },
  { 0x0700, 0xa358, 0x0000 },
  { 0x8700, 0xa35b, 0x2000 },
  { 0x0700, 0xa35a, 0x0000 },
  { 0x0700, 0xa35c, 0x0000 },
  { 0x8700, 0xa365, 0x4000 },
  { 0x8700, 0xa361, 0x3000 },
  { 0x8700, 0xa35f, 0x2000 },
  { 0x0700, 0xa35e, 0x0000 },
  { 0x0700, 0xa360, 0x0000 },
  { 0x8700, 0xa363, 0x2000 },
  { 0x0700, 0xa362, 0x0000 },
  { 0x0700, 0xa364, 0x0000 },
  { 0x8700, 0xa369, 0x3000 },
  { 0x8700, 0xa367, 0x2000 },
  { 0x0700, 0xa366, 0x0000 },
  { 0x0700, 0xa368, 0x0000 },
  { 0x8700, 0xa36b, 0x2000 },
  { 0x0700, 0xa36a, 0x0000 },
  { 0x0700, 0xa36c, 0x0000 },
  { 0x8700, 0xa37d, 0x5000 },
  { 0x8700, 0xa375, 0x4000 },
  { 0x8700, 0xa371, 0x3000 },
  { 0x8700, 0xa36f, 0x2000 },
  { 0x0700, 0xa36e, 0x0000 },
  { 0x0700, 0xa370, 0x0000 },
  { 0x8700, 0xa373, 0x2000 },
  { 0x0700, 0xa372, 0x0000 },
  { 0x0700, 0xa374, 0x0000 },
  { 0x8700, 0xa379, 0x3000 },
  { 0x8700, 0xa377, 0x2000 },
  { 0x0700, 0xa376, 0x0000 },
  { 0x0700, 0xa378, 0x0000 },
  { 0x8700, 0xa37b, 0x2000 },
  { 0x0700, 0xa37a, 0x0000 },
  { 0x0700, 0xa37c, 0x0000 },
  { 0x8700, 0xa385, 0x4000 },
  { 0x8700, 0xa381, 0x3000 },
  { 0x8700, 0xa37f, 0x2000 },
  { 0x0700, 0xa37e, 0x0000 },
  { 0x0700, 0xa380, 0x0000 },
  { 0x8700, 0xa383, 0x2000 },
  { 0x0700, 0xa382, 0x0000 },
  { 0x0700, 0xa384, 0x0000 },
  { 0x8700, 0xa389, 0x3000 },
  { 0x8700, 0xa387, 0x2000 },
  { 0x0700, 0xa386, 0x0000 },
  { 0x0700, 0xa388, 0x0000 },
  { 0x8700, 0xa38b, 0x2000 },
  { 0x0700, 0xa38a, 0x0000 },
  { 0x0700, 0xa38c, 0x0000 },
  { 0x8700, 0xa3ad, 0x6000 },
  { 0x8700, 0xa39d, 0x5000 },
  { 0x8700, 0xa395, 0x4000 },
  { 0x8700, 0xa391, 0x3000 },
  { 0x8700, 0xa38f, 0x2000 },
  { 0x0700, 0xa38e, 0x0000 },
  { 0x0700, 0xa390, 0x0000 },
  { 0x8700, 0xa393, 0x2000 },
  { 0x0700, 0xa392, 0x0000 },
  { 0x0700, 0xa394, 0x0000 },
  { 0x8700, 0xa399, 0x3000 },
  { 0x8700, 0xa397, 0x2000 },
  { 0x0700, 0xa396, 0x0000 },
  { 0x0700, 0xa398, 0x0000 },
  { 0x8700, 0xa39b, 0x2000 },
  { 0x0700, 0xa39a, 0x0000 },
  { 0x0700, 0xa39c, 0x0000 },
  { 0x8700, 0xa3a5, 0x4000 },
  { 0x8700, 0xa3a1, 0x3000 },
  { 0x8700, 0xa39f, 0x2000 },
  { 0x0700, 0xa39e, 0x0000 },
  { 0x0700, 0xa3a0, 0x0000 },
  { 0x8700, 0xa3a3, 0x2000 },
  { 0x0700, 0xa3a2, 0x0000 },
  { 0x0700, 0xa3a4, 0x0000 },
  { 0x8700, 0xa3a9, 0x3000 },
  { 0x8700, 0xa3a7, 0x2000 },
  { 0x0700, 0xa3a6, 0x0000 },
  { 0x0700, 0xa3a8, 0x0000 },
  { 0x8700, 0xa3ab, 0x2000 },
  { 0x0700, 0xa3aa, 0x0000 },
  { 0x0700, 0xa3ac, 0x0000 },
  { 0x8700, 0xa3bd, 0x5000 },
  { 0x8700, 0xa3b5, 0x4000 },
  { 0x8700, 0xa3b1, 0x3000 },
  { 0x8700, 0xa3af, 0x2000 },
  { 0x0700, 0xa3ae, 0x0000 },
  { 0x0700, 0xa3b0, 0x0000 },
  { 0x8700, 0xa3b3, 0x2000 },
  { 0x0700, 0xa3b2, 0x0000 },
  { 0x0700, 0xa3b4, 0x0000 },
  { 0x8700, 0xa3b9, 0x3000 },
  { 0x8700, 0xa3b7, 0x2000 },
  { 0x0700, 0xa3b6, 0x0000 },
  { 0x0700, 0xa3b8, 0x0000 },
  { 0x8700, 0xa3bb, 0x2000 },
  { 0x0700, 0xa3ba, 0x0000 },
  { 0x0700, 0xa3bc, 0x0000 },
  { 0x8700, 0xa3c5, 0x4000 },
  { 0x8700, 0xa3c1, 0x3000 },
  { 0x8700, 0xa3bf, 0x2000 },
  { 0x0700, 0xa3be, 0x0000 },
  { 0x0700, 0xa3c0, 0x0000 },
  { 0x8700, 0xa3c3, 0x2000 },
  { 0x0700, 0xa3c2, 0x0000 },
  { 0x0700, 0xa3c4, 0x0000 },
  { 0x8700, 0xa3c9, 0x3000 },
  { 0x8700, 0xa3c7, 0x2000 },
  { 0x0700, 0xa3c6, 0x0000 },
  { 0x0700, 0xa3c8, 0x0000 },
  { 0x8700, 0xa3cb, 0x2000 },
  { 0x0700, 0xa3ca, 0x0000 },
  { 0x0700, 0xa3cc, 0x0000 },
  { 0x8700, 0xa40d, 0x7000 },
  { 0x8700, 0xa3ed, 0x6000 },
  { 0x8700, 0xa3dd, 0x5000 },
  { 0x8700, 0xa3d5, 0x4000 },
  { 0x8700, 0xa3d1, 0x3000 },
  { 0x8700, 0xa3cf, 0x2000 },
  { 0x0700, 0xa3ce, 0x0000 },
  { 0x0700, 0xa3d0, 0x0000 },
  { 0x8700, 0xa3d3, 0x2000 },
  { 0x0700, 0xa3d2, 0x0000 },
  { 0x0700, 0xa3d4, 0x0000 },
  { 0x8700, 0xa3d9, 0x3000 },
  { 0x8700, 0xa3d7, 0x2000 },
  { 0x0700, 0xa3d6, 0x0000 },
  { 0x0700, 0xa3d8, 0x0000 },
  { 0x8700, 0xa3db, 0x2000 },
  { 0x0700, 0xa3da, 0x0000 },
  { 0x0700, 0xa3dc, 0x0000 },
  { 0x8700, 0xa3e5, 0x4000 },
  { 0x8700, 0xa3e1, 0x3000 },
  { 0x8700, 0xa3df, 0x2000 },
  { 0x0700, 0xa3de, 0x0000 },
  { 0x0700, 0xa3e0, 0x0000 },
  { 0x8700, 0xa3e3, 0x2000 },
  { 0x0700, 0xa3e2, 0x0000 },
  { 0x0700, 0xa3e4, 0x0000 },
  { 0x8700, 0xa3e9, 0x3000 },
  { 0x8700, 0xa3e7, 0x2000 },
  { 0x0700, 0xa3e6, 0x0000 },
  { 0x0700, 0xa3e8, 0x0000 },
  { 0x8700, 0xa3eb, 0x2000 },
  { 0x0700, 0xa3ea, 0x0000 },
  { 0x0700, 0xa3ec, 0x0000 },
  { 0x8700, 0xa3fd, 0x5000 },
  { 0x8700, 0xa3f5, 0x4000 },
  { 0x8700, 0xa3f1, 0x3000 },
  { 0x8700, 0xa3ef, 0x2000 },
  { 0x0700, 0xa3ee, 0x0000 },
  { 0x0700, 0xa3f0, 0x0000 },
  { 0x8700, 0xa3f3, 0x2000 },
  { 0x0700, 0xa3f2, 0x0000 },
  { 0x0700, 0xa3f4, 0x0000 },
  { 0x8700, 0xa3f9, 0x3000 },
  { 0x8700, 0xa3f7, 0x2000 },
  { 0x0700, 0xa3f6, 0x0000 },
  { 0x0700, 0xa3f8, 0x0000 },
  { 0x8700, 0xa3fb, 0x2000 },
  { 0x0700, 0xa3fa, 0x0000 },
  { 0x0700, 0xa3fc, 0x0000 },
  { 0x8700, 0xa405, 0x4000 },
  { 0x8700, 0xa401, 0x3000 },
  { 0x8700, 0xa3ff, 0x2000 },
  { 0x0700, 0xa3fe, 0x0000 },
  { 0x0700, 0xa400, 0x0000 },
  { 0x8700, 0xa403, 0x2000 },
  { 0x0700, 0xa402, 0x0000 },
  { 0x0700, 0xa404, 0x0000 },
  { 0x8700, 0xa409, 0x3000 },
  { 0x8700, 0xa407, 0x2000 },
  { 0x0700, 0xa406, 0x0000 },
  { 0x0700, 0xa408, 0x0000 },
  { 0x8700, 0xa40b, 0x2000 },
  { 0x0700, 0xa40a, 0x0000 },
  { 0x0700, 0xa40c, 0x0000 },
  { 0x8700, 0xa42d, 0x6000 },
  { 0x8700, 0xa41d, 0x5000 },
  { 0x8700, 0xa415, 0x4000 },
  { 0x8700, 0xa411, 0x3000 },
  { 0x8700, 0xa40f, 0x2000 },
  { 0x0700, 0xa40e, 0x0000 },
  { 0x0700, 0xa410, 0x0000 },
  { 0x8700, 0xa413, 0x2000 },
  { 0x0700, 0xa412, 0x0000 },
  { 0x0700, 0xa414, 0x0000 },
  { 0x8700, 0xa419, 0x3000 },
  { 0x8700, 0xa417, 0x2000 },
  { 0x0700, 0xa416, 0x0000 },
  { 0x0700, 0xa418, 0x0000 },
  { 0x8700, 0xa41b, 0x2000 },
  { 0x0700, 0xa41a, 0x0000 },
  { 0x0700, 0xa41c, 0x0000 },
  { 0x8700, 0xa425, 0x4000 },
  { 0x8700, 0xa421, 0x3000 },
  { 0x8700, 0xa41f, 0x2000 },
  { 0x0700, 0xa41e, 0x0000 },
  { 0x0700, 0xa420, 0x0000 },
  { 0x8700, 0xa423, 0x2000 },
  { 0x0700, 0xa422, 0x0000 },
  { 0x0700, 0xa424, 0x0000 },
  { 0x8700, 0xa429, 0x3000 },
  { 0x8700, 0xa427, 0x2000 },
  { 0x0700, 0xa426, 0x0000 },
  { 0x0700, 0xa428, 0x0000 },
  { 0x8700, 0xa42b, 0x2000 },
  { 0x0700, 0xa42a, 0x0000 },
  { 0x0700, 0xa42c, 0x0000 },
  { 0x8700, 0xa43d, 0x5000 },
  { 0x8700, 0xa435, 0x4000 },
  { 0x8700, 0xa431, 0x3000 },
  { 0x8700, 0xa42f, 0x2000 },
  { 0x0700, 0xa42e, 0x0000 },
  { 0x0700, 0xa430, 0x0000 },
  { 0x8700, 0xa433, 0x2000 },
  { 0x0700, 0xa432, 0x0000 },
  { 0x0700, 0xa434, 0x0000 },
  { 0x8700, 0xa439, 0x3000 },
  { 0x8700, 0xa437, 0x2000 },
  { 0x0700, 0xa436, 0x0000 },
  { 0x0700, 0xa438, 0x0000 },
  { 0x8700, 0xa43b, 0x2000 },
  { 0x0700, 0xa43a, 0x0000 },
  { 0x0700, 0xa43c, 0x0000 },
  { 0x8700, 0xa445, 0x4000 },
  { 0x8700, 0xa441, 0x3000 },
  { 0x8700, 0xa43f, 0x2000 },
  { 0x0700, 0xa43e, 0x0000 },
  { 0x0700, 0xa440, 0x0000 },
  { 0x8700, 0xa443, 0x2000 },
  { 0x0700, 0xa442, 0x0000 },
  { 0x0700, 0xa444, 0x0000 },
  { 0x8700, 0xa449, 0x3000 },
  { 0x8700, 0xa447, 0x2000 },
  { 0x0700, 0xa446, 0x0000 },
  { 0x0700, 0xa448, 0x0000 },
  { 0x8700, 0xa44b, 0x2000 },
  { 0x0700, 0xa44a, 0x0000 },
  { 0x0700, 0xa44c, 0x0000 },
  { 0x8300, 0xf8ff, 0x8000 },
  { 0x9a00, 0xa490, 0x7000 },
  { 0x8700, 0xa46d, 0x6000 },
  { 0x8700, 0xa45d, 0x5000 },
  { 0x8700, 0xa455, 0x4000 },
  { 0x8700, 0xa451, 0x3000 },
  { 0x8700, 0xa44f, 0x2000 },
  { 0x0700, 0xa44e, 0x0000 },
  { 0x0700, 0xa450, 0x0000 },
  { 0x8700, 0xa453, 0x2000 },
  { 0x0700, 0xa452, 0x0000 },
  { 0x0700, 0xa454, 0x0000 },
  { 0x8700, 0xa459, 0x3000 },
  { 0x8700, 0xa457, 0x2000 },
  { 0x0700, 0xa456, 0x0000 },
  { 0x0700, 0xa458, 0x0000 },
  { 0x8700, 0xa45b, 0x2000 },
  { 0x0700, 0xa45a, 0x0000 },
  { 0x0700, 0xa45c, 0x0000 },
  { 0x8700, 0xa465, 0x4000 },
  { 0x8700, 0xa461, 0x3000 },
  { 0x8700, 0xa45f, 0x2000 },
  { 0x0700, 0xa45e, 0x0000 },
  { 0x0700, 0xa460, 0x0000 },
  { 0x8700, 0xa463, 0x2000 },
  { 0x0700, 0xa462, 0x0000 },
  { 0x0700, 0xa464, 0x0000 },
  { 0x8700, 0xa469, 0x3000 },
  { 0x8700, 0xa467, 0x2000 },
  { 0x0700, 0xa466, 0x0000 },
  { 0x0700, 0xa468, 0x0000 },
  { 0x8700, 0xa46b, 0x2000 },
  { 0x0700, 0xa46a, 0x0000 },
  { 0x0700, 0xa46c, 0x0000 },
  { 0x8700, 0xa47d, 0x5000 },
  { 0x8700, 0xa475, 0x4000 },
  { 0x8700, 0xa471, 0x3000 },
  { 0x8700, 0xa46f, 0x2000 },
  { 0x0700, 0xa46e, 0x0000 },
  { 0x0700, 0xa470, 0x0000 },
  { 0x8700, 0xa473, 0x2000 },
  { 0x0700, 0xa472, 0x0000 },
  { 0x0700, 0xa474, 0x0000 },
  { 0x8700, 0xa479, 0x3000 },
  { 0x8700, 0xa477, 0x2000 },
  { 0x0700, 0xa476, 0x0000 },
  { 0x0700, 0xa478, 0x0000 },
  { 0x8700, 0xa47b, 0x2000 },
  { 0x0700, 0xa47a, 0x0000 },
  { 0x0700, 0xa47c, 0x0000 },
  { 0x8700, 0xa485, 0x4000 },
  { 0x8700, 0xa481, 0x3000 },
  { 0x8700, 0xa47f, 0x2000 },
  { 0x0700, 0xa47e, 0x0000 },
  { 0x0700, 0xa480, 0x0000 },
  { 0x8700, 0xa483, 0x2000 },
  { 0x0700, 0xa482, 0x0000 },
  { 0x0700, 0xa484, 0x0000 },
  { 0x8700, 0xa489, 0x3000 },
  { 0x8700, 0xa487, 0x2000 },
  { 0x0700, 0xa486, 0x0000 },
  { 0x0700, 0xa488, 0x0000 },
  { 0x8700, 0xa48b, 0x2000 },
  { 0x0700, 0xa48a, 0x0000 },
  { 0x0700, 0xa48c, 0x0000 },
  { 0x9a00, 0xa4b0, 0x6000 },
  { 0x9a00, 0xa4a0, 0x5000 },
  { 0x9a00, 0xa498, 0x4000 },
  { 0x9a00, 0xa494, 0x3000 },
  { 0x9a00, 0xa492, 0x2000 },
  { 0x1a00, 0xa491, 0x0000 },
  { 0x1a00, 0xa493, 0x0000 },
  { 0x9a00, 0xa496, 0x2000 },
  { 0x1a00, 0xa495, 0x0000 },
  { 0x1a00, 0xa497, 0x0000 },
  { 0x9a00, 0xa49c, 0x3000 },
  { 0x9a00, 0xa49a, 0x2000 },
  { 0x1a00, 0xa499, 0x0000 },
  { 0x1a00, 0xa49b, 0x0000 },
  { 0x9a00, 0xa49e, 0x2000 },
  { 0x1a00, 0xa49d, 0x0000 },
  { 0x1a00, 0xa49f, 0x0000 },
  { 0x9a00, 0xa4a8, 0x4000 },
  { 0x9a00, 0xa4a4, 0x3000 },
  { 0x9a00, 0xa4a2, 0x2000 },
  { 0x1a00, 0xa4a1, 0x0000 },
  { 0x1a00, 0xa4a3, 0x0000 },
  { 0x9a00, 0xa4a6, 0x2000 },
  { 0x1a00, 0xa4a5, 0x0000 },
  { 0x1a00, 0xa4a7, 0x0000 },
  { 0x9a00, 0xa4ac, 0x3000 },
  { 0x9a00, 0xa4aa, 0x2000 },
  { 0x1a00, 0xa4a9, 0x0000 },
  { 0x1a00, 0xa4ab, 0x0000 },
  { 0x9a00, 0xa4ae, 0x2000 },
  { 0x1a00, 0xa4ad, 0x0000 },
  { 0x1a00, 0xa4af, 0x0000 },
  { 0x9a00, 0xa4c0, 0x5000 },
  { 0x9a00, 0xa4b8, 0x4000 },
  { 0x9a00, 0xa4b4, 0x3000 },
  { 0x9a00, 0xa4b2, 0x2000 },
  { 0x1a00, 0xa4b1, 0x0000 },
  { 0x1a00, 0xa4b3, 0x0000 },
  { 0x9a00, 0xa4b6, 0x2000 },
  { 0x1a00, 0xa4b5, 0x0000 },
  { 0x1a00, 0xa4b7, 0x0000 },
  { 0x9a00, 0xa4bc, 0x3000 },
  { 0x9a00, 0xa4ba, 0x2000 },
  { 0x1a00, 0xa4b9, 0x0000 },
  { 0x1a00, 0xa4bb, 0x0000 },
  { 0x9a00, 0xa4be, 0x2000 },
  { 0x1a00, 0xa4bd, 0x0000 },
  { 0x1a00, 0xa4bf, 0x0000 },
  { 0x8700, 0xd7a3, 0x4000 },
  { 0x9a00, 0xa4c4, 0x3000 },
  { 0x9a00, 0xa4c2, 0x2000 },
  { 0x1a00, 0xa4c1, 0x0000 },
  { 0x1a00, 0xa4c3, 0x0000 },
  { 0x9a00, 0xa4c6, 0x2000 },
  { 0x1a00, 0xa4c5, 0x0000 },
  { 0x0700, 0xac00, 0x0000 },
  { 0x8400, 0xdbff, 0x3000 },
  { 0x8400, 0xdb7f, 0x2000 },
  { 0x0400, 0xd800, 0x0000 },
  { 0x0400, 0xdb80, 0x0000 },
  { 0x8400, 0xdfff, 0x2000 },
  { 0x0400, 0xdc00, 0x0000 },
  { 0x0300, 0xe000, 0x0000 },
  { 0x8700, 0xf93f, 0x7000 },
  { 0x8700, 0xf91f, 0x6000 },
  { 0x8700, 0xf90f, 0x5000 },
  { 0x8700, 0xf907, 0x4000 },
  { 0x8700, 0xf903, 0x3000 },
  { 0x8700, 0xf901, 0x2000 },
  { 0x0700, 0xf900, 0x0000 },
  { 0x0700, 0xf902, 0x0000 },
  { 0x8700, 0xf905, 0x2000 },
  { 0x0700, 0xf904, 0x0000 },
  { 0x0700, 0xf906, 0x0000 },
  { 0x8700, 0xf90b, 0x3000 },
  { 0x8700, 0xf909, 0x2000 },
  { 0x0700, 0xf908, 0x0000 },
  { 0x0700, 0xf90a, 0x0000 },
  { 0x8700, 0xf90d, 0x2000 },
  { 0x0700, 0xf90c, 0x0000 },
  { 0x0700, 0xf90e, 0x0000 },
  { 0x8700, 0xf917, 0x4000 },
  { 0x8700, 0xf913, 0x3000 },
  { 0x8700, 0xf911, 0x2000 },
  { 0x0700, 0xf910, 0x0000 },
  { 0x0700, 0xf912, 0x0000 },
  { 0x8700, 0xf915, 0x2000 },
  { 0x0700, 0xf914, 0x0000 },
  { 0x0700, 0xf916, 0x0000 },
  { 0x8700, 0xf91b, 0x3000 },
  { 0x8700, 0xf919, 0x2000 },
  { 0x0700, 0xf918, 0x0000 },
  { 0x0700, 0xf91a, 0x0000 },
  { 0x8700, 0xf91d, 0x2000 },
  { 0x0700, 0xf91c, 0x0000 },
  { 0x0700, 0xf91e, 0x0000 },
  { 0x8700, 0xf92f, 0x5000 },
  { 0x8700, 0xf927, 0x4000 },
  { 0x8700, 0xf923, 0x3000 },
  { 0x8700, 0xf921, 0x2000 },
  { 0x0700, 0xf920, 0x0000 },
  { 0x0700, 0xf922, 0x0000 },
  { 0x8700, 0xf925, 0x2000 },
  { 0x0700, 0xf924, 0x0000 },
  { 0x0700, 0xf926, 0x0000 },
  { 0x8700, 0xf92b, 0x3000 },
  { 0x8700, 0xf929, 0x2000 },
  { 0x0700, 0xf928, 0x0000 },
  { 0x0700, 0xf92a, 0x0000 },
  { 0x8700, 0xf92d, 0x2000 },
  { 0x0700, 0xf92c, 0x0000 },
  { 0x0700, 0xf92e, 0x0000 },
  { 0x8700, 0xf937, 0x4000 },
  { 0x8700, 0xf933, 0x3000 },
  { 0x8700, 0xf931, 0x2000 },
  { 0x0700, 0xf930, 0x0000 },
  { 0x0700, 0xf932, 0x0000 },
  { 0x8700, 0xf935, 0x2000 },
  { 0x0700, 0xf934, 0x0000 },
  { 0x0700, 0xf936, 0x0000 },
  { 0x8700, 0xf93b, 0x3000 },
  { 0x8700, 0xf939, 0x2000 },
  { 0x0700, 0xf938, 0x0000 },
  { 0x0700, 0xf93a, 0x0000 },
  { 0x8700, 0xf93d, 0x2000 },
  { 0x0700, 0xf93c, 0x0000 },
  { 0x0700, 0xf93e, 0x0000 },
  { 0x8700, 0xf95f, 0x6000 },
  { 0x8700, 0xf94f, 0x5000 },
  { 0x8700, 0xf947, 0x4000 },
  { 0x8700, 0xf943, 0x3000 },
  { 0x8700, 0xf941, 0x2000 },
  { 0x0700, 0xf940, 0x0000 },
  { 0x0700, 0xf942, 0x0000 },
  { 0x8700, 0xf945, 0x2000 },
  { 0x0700, 0xf944, 0x0000 },
  { 0x0700, 0xf946, 0x0000 },
  { 0x8700, 0xf94b, 0x3000 },
  { 0x8700, 0xf949, 0x2000 },
  { 0x0700, 0xf948, 0x0000 },
  { 0x0700, 0xf94a, 0x0000 },
  { 0x8700, 0xf94d, 0x2000 },
  { 0x0700, 0xf94c, 0x0000 },
  { 0x0700, 0xf94e, 0x0000 },
  { 0x8700, 0xf957, 0x4000 },
  { 0x8700, 0xf953, 0x3000 },
  { 0x8700, 0xf951, 0x2000 },
  { 0x0700, 0xf950, 0x0000 },
  { 0x0700, 0xf952, 0x0000 },
  { 0x8700, 0xf955, 0x2000 },
  { 0x0700, 0xf954, 0x0000 },
  { 0x0700, 0xf956, 0x0000 },
  { 0x8700, 0xf95b, 0x3000 },
  { 0x8700, 0xf959, 0x2000 },
  { 0x0700, 0xf958, 0x0000 },
  { 0x0700, 0xf95a, 0x0000 },
  { 0x8700, 0xf95d, 0x2000 },
  { 0x0700, 0xf95c, 0x0000 },
  { 0x0700, 0xf95e, 0x0000 },
  { 0x8700, 0xf96f, 0x5000 },
  { 0x8700, 0xf967, 0x4000 },
  { 0x8700, 0xf963, 0x3000 },
  { 0x8700, 0xf961, 0x2000 },
  { 0x0700, 0xf960, 0x0000 },
  { 0x0700, 0xf962, 0x0000 },
  { 0x8700, 0xf965, 0x2000 },
  { 0x0700, 0xf964, 0x0000 },
  { 0x0700, 0xf966, 0x0000 },
  { 0x8700, 0xf96b, 0x3000 },
  { 0x8700, 0xf969, 0x2000 },
  { 0x0700, 0xf968, 0x0000 },
  { 0x0700, 0xf96a, 0x0000 },
  { 0x8700, 0xf96d, 0x2000 },
  { 0x0700, 0xf96c, 0x0000 },
  { 0x0700, 0xf96e, 0x0000 },
  { 0x8700, 0xf977, 0x4000 },
  { 0x8700, 0xf973, 0x3000 },
  { 0x8700, 0xf971, 0x2000 },
  { 0x0700, 0xf970, 0x0000 },
  { 0x0700, 0xf972, 0x0000 },
  { 0x8700, 0xf975, 0x2000 },
  { 0x0700, 0xf974, 0x0000 },
  { 0x0700, 0xf976, 0x0000 },
  { 0x8700, 0xf97b, 0x3000 },
  { 0x8700, 0xf979, 0x2000 },
  { 0x0700, 0xf978, 0x0000 },
  { 0x0700, 0xf97a, 0x0000 },
  { 0x8700, 0xf97d, 0x2000 },
  { 0x0700, 0xf97c, 0x0000 },
  { 0x0700, 0xf97e, 0x0000 },
  { 0x8700, 0xfb27, 0x9000 },
  { 0x8700, 0xf9ff, 0x8000 },
  { 0x8700, 0xf9bf, 0x7000 },
  { 0x8700, 0xf99f, 0x6000 },
  { 0x8700, 0xf98f, 0x5000 },
  { 0x8700, 0xf987, 0x4000 },
  { 0x8700, 0xf983, 0x3000 },
  { 0x8700, 0xf981, 0x2000 },
  { 0x0700, 0xf980, 0x0000 },
  { 0x0700, 0xf982, 0x0000 },
  { 0x8700, 0xf985, 0x2000 },
  { 0x0700, 0xf984, 0x0000 },
  { 0x0700, 0xf986, 0x0000 },
  { 0x8700, 0xf98b, 0x3000 },
  { 0x8700, 0xf989, 0x2000 },
  { 0x0700, 0xf988, 0x0000 },
  { 0x0700, 0xf98a, 0x0000 },
  { 0x8700, 0xf98d, 0x2000 },
  { 0x0700, 0xf98c, 0x0000 },
  { 0x0700, 0xf98e, 0x0000 },
  { 0x8700, 0xf997, 0x4000 },
  { 0x8700, 0xf993, 0x3000 },
  { 0x8700, 0xf991, 0x2000 },
  { 0x0700, 0xf990, 0x0000 },
  { 0x0700, 0xf992, 0x0000 },
  { 0x8700, 0xf995, 0x2000 },
  { 0x0700, 0xf994, 0x0000 },
  { 0x0700, 0xf996, 0x0000 },
  { 0x8700, 0xf99b, 0x3000 },
  { 0x8700, 0xf999, 0x2000 },
  { 0x0700, 0xf998, 0x0000 },
  { 0x0700, 0xf99a, 0x0000 },
  { 0x8700, 0xf99d, 0x2000 },
  { 0x0700, 0xf99c, 0x0000 },
  { 0x0700, 0xf99e, 0x0000 },
  { 0x8700, 0xf9af, 0x5000 },
  { 0x8700, 0xf9a7, 0x4000 },
  { 0x8700, 0xf9a3, 0x3000 },
  { 0x8700, 0xf9a1, 0x2000 },
  { 0x0700, 0xf9a0, 0x0000 },
  { 0x0700, 0xf9a2, 0x0000 },
  { 0x8700, 0xf9a5, 0x2000 },
  { 0x0700, 0xf9a4, 0x0000 },
  { 0x0700, 0xf9a6, 0x0000 },
  { 0x8700, 0xf9ab, 0x3000 },
  { 0x8700, 0xf9a9, 0x2000 },
  { 0x0700, 0xf9a8, 0x0000 },
  { 0x0700, 0xf9aa, 0x0000 },
  { 0x8700, 0xf9ad, 0x2000 },
  { 0x0700, 0xf9ac, 0x0000 },
  { 0x0700, 0xf9ae, 0x0000 },
  { 0x8700, 0xf9b7, 0x4000 },
  { 0x8700, 0xf9b3, 0x3000 },
  { 0x8700, 0xf9b1, 0x2000 },
  { 0x0700, 0xf9b0, 0x0000 },
  { 0x0700, 0xf9b2, 0x0000 },
  { 0x8700, 0xf9b5, 0x2000 },
  { 0x0700, 0xf9b4, 0x0000 },
  { 0x0700, 0xf9b6, 0x0000 },
  { 0x8700, 0xf9bb, 0x3000 },
  { 0x8700, 0xf9b9, 0x2000 },
  { 0x0700, 0xf9b8, 0x0000 },
  { 0x0700, 0xf9ba, 0x0000 },
  { 0x8700, 0xf9bd, 0x2000 },
  { 0x0700, 0xf9bc, 0x0000 },
  { 0x0700, 0xf9be, 0x0000 },
  { 0x8700, 0xf9df, 0x6000 },
  { 0x8700, 0xf9cf, 0x5000 },
  { 0x8700, 0xf9c7, 0x4000 },
  { 0x8700, 0xf9c3, 0x3000 },
  { 0x8700, 0xf9c1, 0x2000 },
  { 0x0700, 0xf9c0, 0x0000 },
  { 0x0700, 0xf9c2, 0x0000 },
  { 0x8700, 0xf9c5, 0x2000 },
  { 0x0700, 0xf9c4, 0x0000 },
  { 0x0700, 0xf9c6, 0x0000 },
  { 0x8700, 0xf9cb, 0x3000 },
  { 0x8700, 0xf9c9, 0x2000 },
  { 0x0700, 0xf9c8, 0x0000 },
  { 0x0700, 0xf9ca, 0x0000 },
  { 0x8700, 0xf9cd, 0x2000 },
  { 0x0700, 0xf9cc, 0x0000 },
  { 0x0700, 0xf9ce, 0x0000 },
  { 0x8700, 0xf9d7, 0x4000 },
  { 0x8700, 0xf9d3, 0x3000 },
  { 0x8700, 0xf9d1, 0x2000 },
  { 0x0700, 0xf9d0, 0x0000 },
  { 0x0700, 0xf9d2, 0x0000 },
  { 0x8700, 0xf9d5, 0x2000 },
  { 0x0700, 0xf9d4, 0x0000 },
  { 0x0700, 0xf9d6, 0x0000 },
  { 0x8700, 0xf9db, 0x3000 },
  { 0x8700, 0xf9d9, 0x2000 },
  { 0x0700, 0xf9d8, 0x0000 },
  { 0x0700, 0xf9da, 0x0000 },
  { 0x8700, 0xf9dd, 0x2000 },
  { 0x0700, 0xf9dc, 0x0000 },
  { 0x0700, 0xf9de, 0x0000 },
  { 0x8700, 0xf9ef, 0x5000 },
  { 0x8700, 0xf9e7, 0x4000 },
  { 0x8700, 0xf9e3, 0x3000 },
  { 0x8700, 0xf9e1, 0x2000 },
  { 0x0700, 0xf9e0, 0x0000 },
  { 0x0700, 0xf9e2, 0x0000 },
  { 0x8700, 0xf9e5, 0x2000 },
  { 0x0700, 0xf9e4, 0x0000 },
  { 0x0700, 0xf9e6, 0x0000 },
  { 0x8700, 0xf9eb, 0x3000 },
  { 0x8700, 0xf9e9, 0x2000 },
  { 0x0700, 0xf9e8, 0x0000 },
  { 0x0700, 0xf9ea, 0x0000 },
  { 0x8700, 0xf9ed, 0x2000 },
  { 0x0700, 0xf9ec, 0x0000 },
  { 0x0700, 0xf9ee, 0x0000 },
  { 0x8700, 0xf9f7, 0x4000 },
  { 0x8700, 0xf9f3, 0x3000 },
  { 0x8700, 0xf9f1, 0x2000 },
  { 0x0700, 0xf9f0, 0x0000 },
  { 0x0700, 0xf9f2, 0x0000 },
  { 0x8700, 0xf9f5, 0x2000 },
  { 0x0700, 0xf9f4, 0x0000 },
  { 0x0700, 0xf9f6, 0x0000 },
  { 0x8700, 0xf9fb, 0x3000 },
  { 0x8700, 0xf9f9, 0x2000 },
  { 0x0700, 0xf9f8, 0x0000 },
  { 0x0700, 0xf9fa, 0x0000 },
  { 0x8700, 0xf9fd, 0x2000 },
  { 0x0700, 0xf9fc, 0x0000 },
  { 0x0700, 0xf9fe, 0x0000 },
  { 0x8700, 0xfa41, 0x7000 },
  { 0x8700, 0xfa1f, 0x6000 },
  { 0x8700, 0xfa0f, 0x5000 },
  { 0x8700, 0xfa07, 0x4000 },
  { 0x8700, 0xfa03, 0x3000 },
  { 0x8700, 0xfa01, 0x2000 },
  { 0x0700, 0xfa00, 0x0000 },
  { 0x0700, 0xfa02, 0x0000 },
  { 0x8700, 0xfa05, 0x2000 },
  { 0x0700, 0xfa04, 0x0000 },
  { 0x0700, 0xfa06, 0x0000 },
  { 0x8700, 0xfa0b, 0x3000 },
  { 0x8700, 0xfa09, 0x2000 },
  { 0x0700, 0xfa08, 0x0000 },
  { 0x0700, 0xfa0a, 0x0000 },
  { 0x8700, 0xfa0d, 0x2000 },
  { 0x0700, 0xfa0c, 0x0000 },
  { 0x0700, 0xfa0e, 0x0000 },
  { 0x8700, 0xfa17, 0x4000 },
  { 0x8700, 0xfa13, 0x3000 },
  { 0x8700, 0xfa11, 0x2000 },
  { 0x0700, 0xfa10, 0x0000 },
  { 0x0700, 0xfa12, 0x0000 },
  { 0x8700, 0xfa15, 0x2000 },
  { 0x0700, 0xfa14, 0x0000 },
  { 0x0700, 0xfa16, 0x0000 },
  { 0x8700, 0xfa1b, 0x3000 },
  { 0x8700, 0xfa19, 0x2000 },
  { 0x0700, 0xfa18, 0x0000 },
  { 0x0700, 0xfa1a, 0x0000 },
  { 0x8700, 0xfa1d, 0x2000 },
  { 0x0700, 0xfa1c, 0x0000 },
  { 0x0700, 0xfa1e, 0x0000 },
  { 0x8700, 0xfa31, 0x5000 },
  { 0x8700, 0xfa27, 0x4000 },
  { 0x8700, 0xfa23, 0x3000 },
  { 0x8700, 0xfa21, 0x2000 },
  { 0x0700, 0xfa20, 0x0000 },
  { 0x0700, 0xfa22, 0x0000 },
  { 0x8700, 0xfa25, 0x2000 },
  { 0x0700, 0xfa24, 0x0000 },
  { 0x0700, 0xfa26, 0x0000 },
  { 0x8700, 0xfa2b, 0x3000 },
  { 0x8700, 0xfa29, 0x2000 },
  { 0x0700, 0xfa28, 0x0000 },
  { 0x0700, 0xfa2a, 0x0000 },
  { 0x8700, 0xfa2d, 0x2000 },
  { 0x0700, 0xfa2c, 0x0000 },
  { 0x0700, 0xfa30, 0x0000 },
  { 0x8700, 0xfa39, 0x4000 },
  { 0x8700, 0xfa35, 0x3000 },
  { 0x8700, 0xfa33, 0x2000 },
  { 0x0700, 0xfa32, 0x0000 },
  { 0x0700, 0xfa34, 0x0000 },
  { 0x8700, 0xfa37, 0x2000 },
  { 0x0700, 0xfa36, 0x0000 },
  { 0x0700, 0xfa38, 0x0000 },
  { 0x8700, 0xfa3d, 0x3000 },
  { 0x8700, 0xfa3b, 0x2000 },
  { 0x0700, 0xfa3a, 0x0000 },
  { 0x0700, 0xfa3c, 0x0000 },
  { 0x8700, 0xfa3f, 0x2000 },
  { 0x0700, 0xfa3e, 0x0000 },
  { 0x0700, 0xfa40, 0x0000 },
  { 0x8700, 0xfa61, 0x6000 },
  { 0x8700, 0xfa51, 0x5000 },
  { 0x8700, 0xfa49, 0x4000 },
  { 0x8700, 0xfa45, 0x3000 },
  { 0x8700, 0xfa43, 0x2000 },
  { 0x0700, 0xfa42, 0x0000 },
  { 0x0700, 0xfa44, 0x0000 },
  { 0x8700, 0xfa47, 0x2000 },
  { 0x0700, 0xfa46, 0x0000 },
  { 0x0700, 0xfa48, 0x0000 },
  { 0x8700, 0xfa4d, 0x3000 },
  { 0x8700, 0xfa4b, 0x2000 },
  { 0x0700, 0xfa4a, 0x0000 },
  { 0x0700, 0xfa4c, 0x0000 },
  { 0x8700, 0xfa4f, 0x2000 },
  { 0x0700, 0xfa4e, 0x0000 },
  { 0x0700, 0xfa50, 0x0000 },
  { 0x8700, 0xfa59, 0x4000 },
  { 0x8700, 0xfa55, 0x3000 },
  { 0x8700, 0xfa53, 0x2000 },
  { 0x0700, 0xfa52, 0x0000 },
  { 0x0700, 0xfa54, 0x0000 },
  { 0x8700, 0xfa57, 0x2000 },
  { 0x0700, 0xfa56, 0x0000 },
  { 0x0700, 0xfa58, 0x0000 },
  { 0x8700, 0xfa5d, 0x3000 },
  { 0x8700, 0xfa5b, 0x2000 },
  { 0x0700, 0xfa5a, 0x0000 },
  { 0x0700, 0xfa5c, 0x0000 },
  { 0x8700, 0xfa5f, 0x2000 },
  { 0x0700, 0xfa5e, 0x0000 },
  { 0x0700, 0xfa60, 0x0000 },
  { 0x8500, 0xfb06, 0x5000 },
  { 0x8700, 0xfa69, 0x4000 },
  { 0x8700, 0xfa65, 0x3000 },
  { 0x8700, 0xfa63, 0x2000 },
  { 0x0700, 0xfa62, 0x0000 },
  { 0x0700, 0xfa64, 0x0000 },
  { 0x8700, 0xfa67, 0x2000 },
  { 0x0700, 0xfa66, 0x0000 },
  { 0x0700, 0xfa68, 0x0000 },
  { 0x8500, 0xfb02, 0x3000 },
  { 0x8500, 0xfb00, 0x2000 },
  { 0x0700, 0xfa6a, 0x0000 },
  { 0x0500, 0xfb01, 0x0000 },
  { 0x8500, 0xfb04, 0x2000 },
  { 0x0500, 0xfb03, 0x0000 },
  { 0x0500, 0xfb05, 0x0000 },
  { 0x8700, 0xfb1f, 0x4000 },
  { 0x8500, 0xfb16, 0x3000 },
  { 0x8500, 0xfb14, 0x2000 },
  { 0x0500, 0xfb13, 0x0000 },
  { 0x0500, 0xfb15, 0x0000 },
  { 0x8700, 0xfb1d, 0x2000 },
  { 0x0500, 0xfb17, 0x0000 },
  { 0x0c00, 0xfb1e, 0x0000 },
  { 0x8700, 0xfb23, 0x3000 },
  { 0x8700, 0xfb21, 0x2000 },
  { 0x0700, 0xfb20, 0x0000 },
  { 0x0700, 0xfb22, 0x0000 },
  { 0x8700, 0xfb25, 0x2000 },
  { 0x0700, 0xfb24, 0x0000 },
  { 0x0700, 0xfb26, 0x0000 },
  { 0x8700, 0xfbac, 0x8000 },
  { 0x8700, 0xfb6c, 0x7000 },
  { 0x8700, 0xfb4c, 0x6000 },
  { 0x8700, 0xfb38, 0x5000 },
  { 0x8700, 0xfb2f, 0x4000 },
  { 0x8700, 0xfb2b, 0x3000 },
  { 0x9900, 0xfb29, 0x2000 },
  { 0x0700, 0xfb28, 0x0000 },
  { 0x0700, 0xfb2a, 0x0000 },
  { 0x8700, 0xfb2d, 0x2000 },
  { 0x0700, 0xfb2c, 0x0000 },
  { 0x0700, 0xfb2e, 0x0000 },
  { 0x8700, 0xfb33, 0x3000 },
  { 0x8700, 0xfb31, 0x2000 },
  { 0x0700, 0xfb30, 0x0000 },
  { 0x0700, 0xfb32, 0x0000 },
  { 0x8700, 0xfb35, 0x2000 },
  { 0x0700, 0xfb34, 0x0000 },
  { 0x0700, 0xfb36, 0x0000 },
  { 0x8700, 0xfb43, 0x4000 },
  { 0x8700, 0xfb3c, 0x3000 },
  { 0x8700, 0xfb3a, 0x2000 },
  { 0x0700, 0xfb39, 0x0000 },
  { 0x0700, 0xfb3b, 0x0000 },
  { 0x8700, 0xfb40, 0x2000 },
  { 0x0700, 0xfb3e, 0x0000 },
  { 0x0700, 0xfb41, 0x0000 },
  { 0x8700, 0xfb48, 0x3000 },
  { 0x8700, 0xfb46, 0x2000 },
  { 0x0700, 0xfb44, 0x0000 },
  { 0x0700, 0xfb47, 0x0000 },
  { 0x8700, 0xfb4a, 0x2000 },
  { 0x0700, 0xfb49, 0x0000 },
  { 0x0700, 0xfb4b, 0x0000 },
  { 0x8700, 0xfb5c, 0x5000 },
  { 0x8700, 0xfb54, 0x4000 },
  { 0x8700, 0xfb50, 0x3000 },
  { 0x8700, 0xfb4e, 0x2000 },
  { 0x0700, 0xfb4d, 0x0000 },
  { 0x0700, 0xfb4f, 0x0000 },
  { 0x8700, 0xfb52, 0x2000 },
  { 0x0700, 0xfb51, 0x0000 },
  { 0x0700, 0xfb53, 0x0000 },
  { 0x8700, 0xfb58, 0x3000 },
  { 0x8700, 0xfb56, 0x2000 },
  { 0x0700, 0xfb55, 0x0000 },
  { 0x0700, 0xfb57, 0x0000 },
  { 0x8700, 0xfb5a, 0x2000 },
  { 0x0700, 0xfb59, 0x0000 },
  { 0x0700, 0xfb5b, 0x0000 },
  { 0x8700, 0xfb64, 0x4000 },
  { 0x8700, 0xfb60, 0x3000 },
  { 0x8700, 0xfb5e, 0x2000 },
  { 0x0700, 0xfb5d, 0x0000 },
  { 0x0700, 0xfb5f, 0x0000 },
  { 0x8700, 0xfb62, 0x2000 },
  { 0x0700, 0xfb61, 0x0000 },
  { 0x0700, 0xfb63, 0x0000 },
  { 0x8700, 0xfb68, 0x3000 },
  { 0x8700, 0xfb66, 0x2000 },
  { 0x0700, 0xfb65, 0x0000 },
  { 0x0700, 0xfb67, 0x0000 },
  { 0x8700, 0xfb6a, 0x2000 },
  { 0x0700, 0xfb69, 0x0000 },
  { 0x0700, 0xfb6b, 0x0000 },
  { 0x8700, 0xfb8c, 0x6000 },
  { 0x8700, 0xfb7c, 0x5000 },
  { 0x8700, 0xfb74, 0x4000 },
  { 0x8700, 0xfb70, 0x3000 },
  { 0x8700, 0xfb6e, 0x2000 },
  { 0x0700, 0xfb6d, 0x0000 },
  { 0x0700, 0xfb6f, 0x0000 },
  { 0x8700, 0xfb72, 0x2000 },
  { 0x0700, 0xfb71, 0x0000 },
  { 0x0700, 0xfb73, 0x0000 },
  { 0x8700, 0xfb78, 0x3000 },
  { 0x8700, 0xfb76, 0x2000 },
  { 0x0700, 0xfb75, 0x0000 },
  { 0x0700, 0xfb77, 0x0000 },
  { 0x8700, 0xfb7a, 0x2000 },
  { 0x0700, 0xfb79, 0x0000 },
  { 0x0700, 0xfb7b, 0x0000 },
  { 0x8700, 0xfb84, 0x4000 },
  { 0x8700, 0xfb80, 0x3000 },
  { 0x8700, 0xfb7e, 0x2000 },
  { 0x0700, 0xfb7d, 0x0000 },
  { 0x0700, 0xfb7f, 0x0000 },
  { 0x8700, 0xfb82, 0x2000 },
  { 0x0700, 0xfb81, 0x0000 },
  { 0x0700, 0xfb83, 0x0000 },
  { 0x8700, 0xfb88, 0x3000 },
  { 0x8700, 0xfb86, 0x2000 },
  { 0x0700, 0xfb85, 0x0000 },
  { 0x0700, 0xfb87, 0x0000 },
  { 0x8700, 0xfb8a, 0x2000 },
  { 0x0700, 0xfb89, 0x0000 },
  { 0x0700, 0xfb8b, 0x0000 },
  { 0x8700, 0xfb9c, 0x5000 },
  { 0x8700, 0xfb94, 0x4000 },
  { 0x8700, 0xfb90, 0x3000 },
  { 0x8700, 0xfb8e, 0x2000 },
  { 0x0700, 0xfb8d, 0x0000 },
  { 0x0700, 0xfb8f, 0x0000 },
  { 0x8700, 0xfb92, 0x2000 },
  { 0x0700, 0xfb91, 0x0000 },
  { 0x0700, 0xfb93, 0x0000 },
  { 0x8700, 0xfb98, 0x3000 },
  { 0x8700, 0xfb96, 0x2000 },
  { 0x0700, 0xfb95, 0x0000 },
  { 0x0700, 0xfb97, 0x0000 },
  { 0x8700, 0xfb9a, 0x2000 },
  { 0x0700, 0xfb99, 0x0000 },
  { 0x0700, 0xfb9b, 0x0000 },
  { 0x8700, 0xfba4, 0x4000 },
  { 0x8700, 0xfba0, 0x3000 },
  { 0x8700, 0xfb9e, 0x2000 },
  { 0x0700, 0xfb9d, 0x0000 },
  { 0x0700, 0xfb9f, 0x0000 },
  { 0x8700, 0xfba2, 0x2000 },
  { 0x0700, 0xfba1, 0x0000 },
  { 0x0700, 0xfba3, 0x0000 },
  { 0x8700, 0xfba8, 0x3000 },
  { 0x8700, 0xfba6, 0x2000 },
  { 0x0700, 0xfba5, 0x0000 },
  { 0x0700, 0xfba7, 0x0000 },
  { 0x8700, 0xfbaa, 0x2000 },
  { 0x0700, 0xfba9, 0x0000 },
  { 0x0700, 0xfbab, 0x0000 },
  { 0x8700, 0xfc0d, 0x7000 },
  { 0x8700, 0xfbed, 0x6000 },
  { 0x8700, 0xfbdd, 0x5000 },
  { 0x8700, 0xfbd5, 0x4000 },
  { 0x8700, 0xfbb0, 0x3000 },
  { 0x8700, 0xfbae, 0x2000 },
  { 0x0700, 0xfbad, 0x0000 },
  { 0x0700, 0xfbaf, 0x0000 },
  { 0x8700, 0xfbd3, 0x2000 },
  { 0x0700, 0xfbb1, 0x0000 },
  { 0x0700, 0xfbd4, 0x0000 },
  { 0x8700, 0xfbd9, 0x3000 },
  { 0x8700, 0xfbd7, 0x2000 },
  { 0x0700, 0xfbd6, 0x0000 },
  { 0x0700, 0xfbd8, 0x0000 },
  { 0x8700, 0xfbdb, 0x2000 },
  { 0x0700, 0xfbda, 0x0000 },
  { 0x0700, 0xfbdc, 0x0000 },
  { 0x8700, 0xfbe5, 0x4000 },
  { 0x8700, 0xfbe1, 0x3000 },
  { 0x8700, 0xfbdf, 0x2000 },
  { 0x0700, 0xfbde, 0x0000 },
  { 0x0700, 0xfbe0, 0x0000 },
  { 0x8700, 0xfbe3, 0x2000 },
  { 0x0700, 0xfbe2, 0x0000 },
  { 0x0700, 0xfbe4, 0x0000 },
  { 0x8700, 0xfbe9, 0x3000 },
  { 0x8700, 0xfbe7, 0x2000 },
  { 0x0700, 0xfbe6, 0x0000 },
  { 0x0700, 0xfbe8, 0x0000 },
  { 0x8700, 0xfbeb, 0x2000 },
  { 0x0700, 0xfbea, 0x0000 },
  { 0x0700, 0xfbec, 0x0000 },
  { 0x8700, 0xfbfd, 0x5000 },
  { 0x8700, 0xfbf5, 0x4000 },
  { 0x8700, 0xfbf1, 0x3000 },
  { 0x8700, 0xfbef, 0x2000 },
  { 0x0700, 0xfbee, 0x0000 },
  { 0x0700, 0xfbf0, 0x0000 },
  { 0x8700, 0xfbf3, 0x2000 },
  { 0x0700, 0xfbf2, 0x0000 },
  { 0x0700, 0xfbf4, 0x0000 },
  { 0x8700, 0xfbf9, 0x3000 },
  { 0x8700, 0xfbf7, 0x2000 },
  { 0x0700, 0xfbf6, 0x0000 },
  { 0x0700, 0xfbf8, 0x0000 },
  { 0x8700, 0xfbfb, 0x2000 },
  { 0x0700, 0xfbfa, 0x0000 },
  { 0x0700, 0xfbfc, 0x0000 },
  { 0x8700, 0xfc05, 0x4000 },
  { 0x8700, 0xfc01, 0x3000 },
  { 0x8700, 0xfbff, 0x2000 },
  { 0x0700, 0xfbfe, 0x0000 },
  { 0x0700, 0xfc00, 0x0000 },
  { 0x8700, 0xfc03, 0x2000 },
  { 0x0700, 0xfc02, 0x0000 },
  { 0x0700, 0xfc04, 0x0000 },
  { 0x8700, 0xfc09, 0x3000 },
  { 0x8700, 0xfc07, 0x2000 },
  { 0x0700, 0xfc06, 0x0000 },
  { 0x0700, 0xfc08, 0x0000 },
  { 0x8700, 0xfc0b, 0x2000 },
  { 0x0700, 0xfc0a, 0x0000 },
  { 0x0700, 0xfc0c, 0x0000 },
  { 0x8700, 0xfc2d, 0x6000 },
  { 0x8700, 0xfc1d, 0x5000 },
  { 0x8700, 0xfc15, 0x4000 },
  { 0x8700, 0xfc11, 0x3000 },
  { 0x8700, 0xfc0f, 0x2000 },
  { 0x0700, 0xfc0e, 0x0000 },
  { 0x0700, 0xfc10, 0x0000 },
  { 0x8700, 0xfc13, 0x2000 },
  { 0x0700, 0xfc12, 0x0000 },
  { 0x0700, 0xfc14, 0x0000 },
  { 0x8700, 0xfc19, 0x3000 },
  { 0x8700, 0xfc17, 0x2000 },
  { 0x0700, 0xfc16, 0x0000 },
  { 0x0700, 0xfc18, 0x0000 },
  { 0x8700, 0xfc1b, 0x2000 },
  { 0x0700, 0xfc1a, 0x0000 },
  { 0x0700, 0xfc1c, 0x0000 },
  { 0x8700, 0xfc25, 0x4000 },
  { 0x8700, 0xfc21, 0x3000 },
  { 0x8700, 0xfc1f, 0x2000 },
  { 0x0700, 0xfc1e, 0x0000 },
  { 0x0700, 0xfc20, 0x0000 },
  { 0x8700, 0xfc23, 0x2000 },
  { 0x0700, 0xfc22, 0x0000 },
  { 0x0700, 0xfc24, 0x0000 },
  { 0x8700, 0xfc29, 0x3000 },
  { 0x8700, 0xfc27, 0x2000 },
  { 0x0700, 0xfc26, 0x0000 },
  { 0x0700, 0xfc28, 0x0000 },
  { 0x8700, 0xfc2b, 0x2000 },
  { 0x0700, 0xfc2a, 0x0000 },
  { 0x0700, 0xfc2c, 0x0000 },
  { 0x8700, 0xfc3d, 0x5000 },
  { 0x8700, 0xfc35, 0x4000 },
  { 0x8700, 0xfc31, 0x3000 },
  { 0x8700, 0xfc2f, 0x2000 },
  { 0x0700, 0xfc2e, 0x0000 },
  { 0x0700, 0xfc30, 0x0000 },
  { 0x8700, 0xfc33, 0x2000 },
  { 0x0700, 0xfc32, 0x0000 },
  { 0x0700, 0xfc34, 0x0000 },
  { 0x8700, 0xfc39, 0x3000 },
  { 0x8700, 0xfc37, 0x2000 },
  { 0x0700, 0xfc36, 0x0000 },
  { 0x0700, 0xfc38, 0x0000 },
  { 0x8700, 0xfc3b, 0x2000 },
  { 0x0700, 0xfc3a, 0x0000 },
  { 0x0700, 0xfc3c, 0x0000 },
  { 0x8700, 0xfc45, 0x4000 },
  { 0x8700, 0xfc41, 0x3000 },
  { 0x8700, 0xfc3f, 0x2000 },
  { 0x0700, 0xfc3e, 0x0000 },
  { 0x0700, 0xfc40, 0x0000 },
  { 0x8700, 0xfc43, 0x2000 },
  { 0x0700, 0xfc42, 0x0000 },
  { 0x0700, 0xfc44, 0x0000 },
  { 0x8700, 0xfc49, 0x3000 },
  { 0x8700, 0xfc47, 0x2000 },
  { 0x0700, 0xfc46, 0x0000 },
  { 0x0700, 0xfc48, 0x0000 },
  { 0x8700, 0xfc4b, 0x2000 },
  { 0x0700, 0xfc4a, 0x0000 },
  { 0x0700, 0xfc4c, 0x0000 },
  { 0x8700, 0xfeac, 0xa000 },
  { 0x8700, 0xfd5d, 0x9000 },
  { 0x8700, 0xfccd, 0x8000 },
  { 0x8700, 0xfc8d, 0x7000 },
  { 0x8700, 0xfc6d, 0x6000 },
  { 0x8700, 0xfc5d, 0x5000 },
  { 0x8700, 0xfc55, 0x4000 },
  { 0x8700, 0xfc51, 0x3000 },
  { 0x8700, 0xfc4f, 0x2000 },
  { 0x0700, 0xfc4e, 0x0000 },
  { 0x0700, 0xfc50, 0x0000 },
  { 0x8700, 0xfc53, 0x2000 },
  { 0x0700, 0xfc52, 0x0000 },
  { 0x0700, 0xfc54, 0x0000 },
  { 0x8700, 0xfc59, 0x3000 },
  { 0x8700, 0xfc57, 0x2000 },
  { 0x0700, 0xfc56, 0x0000 },
  { 0x0700, 0xfc58, 0x0000 },
  { 0x8700, 0xfc5b, 0x2000 },
  { 0x0700, 0xfc5a, 0x0000 },
  { 0x0700, 0xfc5c, 0x0000 },
  { 0x8700, 0xfc65, 0x4000 },
  { 0x8700, 0xfc61, 0x3000 },
  { 0x8700, 0xfc5f, 0x2000 },
  { 0x0700, 0xfc5e, 0x0000 },
  { 0x0700, 0xfc60, 0x0000 },
  { 0x8700, 0xfc63, 0x2000 },
  { 0x0700, 0xfc62, 0x0000 },
  { 0x0700, 0xfc64, 0x0000 },
  { 0x8700, 0xfc69, 0x3000 },
  { 0x8700, 0xfc67, 0x2000 },
  { 0x0700, 0xfc66, 0x0000 },
  { 0x0700, 0xfc68, 0x0000 },
  { 0x8700, 0xfc6b, 0x2000 },
  { 0x0700, 0xfc6a, 0x0000 },
  { 0x0700, 0xfc6c, 0x0000 },
  { 0x8700, 0xfc7d, 0x5000 },
  { 0x8700, 0xfc75, 0x4000 },
  { 0x8700, 0xfc71, 0x3000 },
  { 0x8700, 0xfc6f, 0x2000 },
  { 0x0700, 0xfc6e, 0x0000 },
  { 0x0700, 0xfc70, 0x0000 },
  { 0x8700, 0xfc73, 0x2000 },
  { 0x0700, 0xfc72, 0x0000 },
  { 0x0700, 0xfc74, 0x0000 },
  { 0x8700, 0xfc79, 0x3000 },
  { 0x8700, 0xfc77, 0x2000 },
  { 0x0700, 0xfc76, 0x0000 },
  { 0x0700, 0xfc78, 0x0000 },
  { 0x8700, 0xfc7b, 0x2000 },
  { 0x0700, 0xfc7a, 0x0000 },
  { 0x0700, 0xfc7c, 0x0000 },
  { 0x8700, 0xfc85, 0x4000 },
  { 0x8700, 0xfc81, 0x3000 },
  { 0x8700, 0xfc7f, 0x2000 },
  { 0x0700, 0xfc7e, 0x0000 },
  { 0x0700, 0xfc80, 0x0000 },
  { 0x8700, 0xfc83, 0x2000 },
  { 0x0700, 0xfc82, 0x0000 },
  { 0x0700, 0xfc84, 0x0000 },
  { 0x8700, 0xfc89, 0x3000 },
  { 0x8700, 0xfc87, 0x2000 },
  { 0x0700, 0xfc86, 0x0000 },
  { 0x0700, 0xfc88, 0x0000 },
  { 0x8700, 0xfc8b, 0x2000 },
  { 0x0700, 0xfc8a, 0x0000 },
  { 0x0700, 0xfc8c, 0x0000 },
  { 0x8700, 0xfcad, 0x6000 },
  { 0x8700, 0xfc9d, 0x5000 },
  { 0x8700, 0xfc95, 0x4000 },
  { 0x8700, 0xfc91, 0x3000 },
  { 0x8700, 0xfc8f, 0x2000 },
  { 0x0700, 0xfc8e, 0x0000 },
  { 0x0700, 0xfc90, 0x0000 },
  { 0x8700, 0xfc93, 0x2000 },
  { 0x0700, 0xfc92, 0x0000 },
  { 0x0700, 0xfc94, 0x0000 },
  { 0x8700, 0xfc99, 0x3000 },
  { 0x8700, 0xfc97, 0x2000 },
  { 0x0700, 0xfc96, 0x0000 },
  { 0x0700, 0xfc98, 0x0000 },
  { 0x8700, 0xfc9b, 0x2000 },
  { 0x0700, 0xfc9a, 0x0000 },
  { 0x0700, 0xfc9c, 0x0000 },
  { 0x8700, 0xfca5, 0x4000 },
  { 0x8700, 0xfca1, 0x3000 },
  { 0x8700, 0xfc9f, 0x2000 },
  { 0x0700, 0xfc9e, 0x0000 },
  { 0x0700, 0xfca0, 0x0000 },
  { 0x8700, 0xfca3, 0x2000 },
  { 0x0700, 0xfca2, 0x0000 },
  { 0x0700, 0xfca4, 0x0000 },
  { 0x8700, 0xfca9, 0x3000 },
  { 0x8700, 0xfca7, 0x2000 },
  { 0x0700, 0xfca6, 0x0000 },
  { 0x0700, 0xfca8, 0x0000 },
  { 0x8700, 0xfcab, 0x2000 },
  { 0x0700, 0xfcaa, 0x0000 },
  { 0x0700, 0xfcac, 0x0000 },
  { 0x8700, 0xfcbd, 0x5000 },
  { 0x8700, 0xfcb5, 0x4000 },
  { 0x8700, 0xfcb1, 0x3000 },
  { 0x8700, 0xfcaf, 0x2000 },
  { 0x0700, 0xfcae, 0x0000 },
  { 0x0700, 0xfcb0, 0x0000 },
  { 0x8700, 0xfcb3, 0x2000 },
  { 0x0700, 0xfcb2, 0x0000 },
  { 0x0700, 0xfcb4, 0x0000 },
  { 0x8700, 0xfcb9, 0x3000 },
  { 0x8700, 0xfcb7, 0x2000 },
  { 0x0700, 0xfcb6, 0x0000 },
  { 0x0700, 0xfcb8, 0x0000 },
  { 0x8700, 0xfcbb, 0x2000 },
  { 0x0700, 0xfcba, 0x0000 },
  { 0x0700, 0xfcbc, 0x0000 },
  { 0x8700, 0xfcc5, 0x4000 },
  { 0x8700, 0xfcc1, 0x3000 },
  { 0x8700, 0xfcbf, 0x2000 },
  { 0x0700, 0xfcbe, 0x0000 },
  { 0x0700, 0xfcc0, 0x0000 },
  { 0x8700, 0xfcc3, 0x2000 },
  { 0x0700, 0xfcc2, 0x0000 },
  { 0x0700, 0xfcc4, 0x0000 },
  { 0x8700, 0xfcc9, 0x3000 },
  { 0x8700, 0xfcc7, 0x2000 },
  { 0x0700, 0xfcc6, 0x0000 },
  { 0x0700, 0xfcc8, 0x0000 },
  { 0x8700, 0xfccb, 0x2000 },
  { 0x0700, 0xfcca, 0x0000 },
  { 0x0700, 0xfccc, 0x0000 },
  { 0x8700, 0xfd0d, 0x7000 },
  { 0x8700, 0xfced, 0x6000 },
  { 0x8700, 0xfcdd, 0x5000 },
  { 0x8700, 0xfcd5, 0x4000 },
  { 0x8700, 0xfcd1, 0x3000 },
  { 0x8700, 0xfccf, 0x2000 },
  { 0x0700, 0xfcce, 0x0000 },
  { 0x0700, 0xfcd0, 0x0000 },
  { 0x8700, 0xfcd3, 0x2000 },
  { 0x0700, 0xfcd2, 0x0000 },
  { 0x0700, 0xfcd4, 0x0000 },
  { 0x8700, 0xfcd9, 0x3000 },
  { 0x8700, 0xfcd7, 0x2000 },
  { 0x0700, 0xfcd6, 0x0000 },
  { 0x0700, 0xfcd8, 0x0000 },
  { 0x8700, 0xfcdb, 0x2000 },
  { 0x0700, 0xfcda, 0x0000 },
  { 0x0700, 0xfcdc, 0x0000 },
  { 0x8700, 0xfce5, 0x4000 },
  { 0x8700, 0xfce1, 0x3000 },
  { 0x8700, 0xfcdf, 0x2000 },
  { 0x0700, 0xfcde, 0x0000 },
  { 0x0700, 0xfce0, 0x0000 },
  { 0x8700, 0xfce3, 0x2000 },
  { 0x0700, 0xfce2, 0x0000 },
  { 0x0700, 0xfce4, 0x0000 },
  { 0x8700, 0xfce9, 0x3000 },
  { 0x8700, 0xfce7, 0x2000 },
  { 0x0700, 0xfce6, 0x0000 },
  { 0x0700, 0xfce8, 0x0000 },
  { 0x8700, 0xfceb, 0x2000 },
  { 0x0700, 0xfcea, 0x0000 },
  { 0x0700, 0xfcec, 0x0000 },
  { 0x8700, 0xfcfd, 0x5000 },
  { 0x8700, 0xfcf5, 0x4000 },
  { 0x8700, 0xfcf1, 0x3000 },
  { 0x8700, 0xfcef, 0x2000 },
  { 0x0700, 0xfcee, 0x0000 },
  { 0x0700, 0xfcf0, 0x0000 },
  { 0x8700, 0xfcf3, 0x2000 },
  { 0x0700, 0xfcf2, 0x0000 },
  { 0x0700, 0xfcf4, 0x0000 },
  { 0x8700, 0xfcf9, 0x3000 },
  { 0x8700, 0xfcf7, 0x2000 },
  { 0x0700, 0xfcf6, 0x0000 },
  { 0x0700, 0xfcf8, 0x0000 },
  { 0x8700, 0xfcfb, 0x2000 },
  { 0x0700, 0xfcfa, 0x0000 },
  { 0x0700, 0xfcfc, 0x0000 },
  { 0x8700, 0xfd05, 0x4000 },
  { 0x8700, 0xfd01, 0x3000 },
  { 0x8700, 0xfcff, 0x2000 },
  { 0x0700, 0xfcfe, 0x0000 },
  { 0x0700, 0xfd00, 0x0000 },
  { 0x8700, 0xfd03, 0x2000 },
  { 0x0700, 0xfd02, 0x0000 },
  { 0x0700, 0xfd04, 0x0000 },
  { 0x8700, 0xfd09, 0x3000 },
  { 0x8700, 0xfd07, 0x2000 },
  { 0x0700, 0xfd06, 0x0000 },
  { 0x0700, 0xfd08, 0x0000 },
  { 0x8700, 0xfd0b, 0x2000 },
  { 0x0700, 0xfd0a, 0x0000 },
  { 0x0700, 0xfd0c, 0x0000 },
  { 0x8700, 0xfd2d, 0x6000 },
  { 0x8700, 0xfd1d, 0x5000 },
  { 0x8700, 0xfd15, 0x4000 },
  { 0x8700, 0xfd11, 0x3000 },
  { 0x8700, 0xfd0f, 0x2000 },
  { 0x0700, 0xfd0e, 0x0000 },
  { 0x0700, 0xfd10, 0x0000 },
  { 0x8700, 0xfd13, 0x2000 },
  { 0x0700, 0xfd12, 0x0000 },
  { 0x0700, 0xfd14, 0x0000 },
  { 0x8700, 0xfd19, 0x3000 },
  { 0x8700, 0xfd17, 0x2000 },
  { 0x0700, 0xfd16, 0x0000 },
  { 0x0700, 0xfd18, 0x0000 },
  { 0x8700, 0xfd1b, 0x2000 },
  { 0x0700, 0xfd1a, 0x0000 },
  { 0x0700, 0xfd1c, 0x0000 },
  { 0x8700, 0xfd25, 0x4000 },
  { 0x8700, 0xfd21, 0x3000 },
  { 0x8700, 0xfd1f, 0x2000 },
  { 0x0700, 0xfd1e, 0x0000 },
  { 0x0700, 0xfd20, 0x0000 },
  { 0x8700, 0xfd23, 0x2000 },
  { 0x0700, 0xfd22, 0x0000 },
  { 0x0700, 0xfd24, 0x0000 },
  { 0x8700, 0xfd29, 0x3000 },
  { 0x8700, 0xfd27, 0x2000 },
  { 0x0700, 0xfd26, 0x0000 },
  { 0x0700, 0xfd28, 0x0000 },
  { 0x8700, 0xfd2b, 0x2000 },
  { 0x0700, 0xfd2a, 0x0000 },
  { 0x0700, 0xfd2c, 0x0000 },
  { 0x8700, 0xfd3d, 0x5000 },
  { 0x8700, 0xfd35, 0x4000 },
  { 0x8700, 0xfd31, 0x3000 },
  { 0x8700, 0xfd2f, 0x2000 },
  { 0x0700, 0xfd2e, 0x0000 },
  { 0x0700, 0xfd30, 0x0000 },
  { 0x8700, 0xfd33, 0x2000 },
  { 0x0700, 0xfd32, 0x0000 },
  { 0x0700, 0xfd34, 0x0000 },
  { 0x8700, 0xfd39, 0x3000 },
  { 0x8700, 0xfd37, 0x2000 },
  { 0x0700, 0xfd36, 0x0000 },
  { 0x0700, 0xfd38, 0x0000 },
  { 0x8700, 0xfd3b, 0x2000 },
  { 0x0700, 0xfd3a, 0x0000 },
  { 0x0700, 0xfd3c, 0x0000 },
  { 0x8700, 0xfd55, 0x4000 },
  { 0x8700, 0xfd51, 0x3000 },
  { 0x9200, 0xfd3f, 0x2000 },
  { 0x1600, 0xfd3e, 0x0000 },
  { 0x0700, 0xfd50, 0x0000 },
  { 0x8700, 0xfd53, 0x2000 },
  { 0x0700, 0xfd52, 0x0000 },
  { 0x0700, 0xfd54, 0x0000 },
  { 0x8700, 0xfd59, 0x3000 },
  { 0x8700, 0xfd57, 0x2000 },
  { 0x0700, 0xfd56, 0x0000 },
  { 0x0700, 0xfd58, 0x0000 },
  { 0x8700, 0xfd5b, 0x2000 },
  { 0x0700, 0xfd5a, 0x0000 },
  { 0x0700, 0xfd5c, 0x0000 },
  { 0x8c00, 0xfe09, 0x8000 },
  { 0x8700, 0xfd9f, 0x7000 },
  { 0x8700, 0xfd7d, 0x6000 },
  { 0x8700, 0xfd6d, 0x5000 },
  { 0x8700, 0xfd65, 0x4000 },
  { 0x8700, 0xfd61, 0x3000 },
  { 0x8700, 0xfd5f, 0x2000 },
  { 0x0700, 0xfd5e, 0x0000 },
  { 0x0700, 0xfd60, 0x0000 },
  { 0x8700, 0xfd63, 0x2000 },
  { 0x0700, 0xfd62, 0x0000 },
  { 0x0700, 0xfd64, 0x0000 },
  { 0x8700, 0xfd69, 0x3000 },
  { 0x8700, 0xfd67, 0x2000 },
  { 0x0700, 0xfd66, 0x0000 },
  { 0x0700, 0xfd68, 0x0000 },
  { 0x8700, 0xfd6b, 0x2000 },
  { 0x0700, 0xfd6a, 0x0000 },
  { 0x0700, 0xfd6c, 0x0000 },
  { 0x8700, 0xfd75, 0x4000 },
  { 0x8700, 0xfd71, 0x3000 },
  { 0x8700, 0xfd6f, 0x2000 },
  { 0x0700, 0xfd6e, 0x0000 },
  { 0x0700, 0xfd70, 0x0000 },
  { 0x8700, 0xfd73, 0x2000 },
  { 0x0700, 0xfd72, 0x0000 },
  { 0x0700, 0xfd74, 0x0000 },
  { 0x8700, 0xfd79, 0x3000 },
  { 0x8700, 0xfd77, 0x2000 },
  { 0x0700, 0xfd76, 0x0000 },
  { 0x0700, 0xfd78, 0x0000 },
  { 0x8700, 0xfd7b, 0x2000 },
  { 0x0700, 0xfd7a, 0x0000 },
  { 0x0700, 0xfd7c, 0x0000 },
  { 0x8700, 0xfd8d, 0x5000 },
  { 0x8700, 0xfd85, 0x4000 },
  { 0x8700, 0xfd81, 0x3000 },
  { 0x8700, 0xfd7f, 0x2000 },
  { 0x0700, 0xfd7e, 0x0000 },
  { 0x0700, 0xfd80, 0x0000 },
  { 0x8700, 0xfd83, 0x2000 },
  { 0x0700, 0xfd82, 0x0000 },
  { 0x0700, 0xfd84, 0x0000 },
  { 0x8700, 0xfd89, 0x3000 },
  { 0x8700, 0xfd87, 0x2000 },
  { 0x0700, 0xfd86, 0x0000 },
  { 0x0700, 0xfd88, 0x0000 },
  { 0x8700, 0xfd8b, 0x2000 },
  { 0x0700, 0xfd8a, 0x0000 },
  { 0x0700, 0xfd8c, 0x0000 },
  { 0x8700, 0xfd97, 0x4000 },
  { 0x8700, 0xfd93, 0x3000 },
  { 0x8700, 0xfd8f, 0x2000 },
  { 0x0700, 0xfd8e, 0x0000 },
  { 0x0700, 0xfd92, 0x0000 },
  { 0x8700, 0xfd95, 0x2000 },
  { 0x0700, 0xfd94, 0x0000 },
  { 0x0700, 0xfd96, 0x0000 },
  { 0x8700, 0xfd9b, 0x3000 },
  { 0x8700, 0xfd99, 0x2000 },
  { 0x0700, 0xfd98, 0x0000 },
  { 0x0700, 0xfd9a, 0x0000 },
  { 0x8700, 0xfd9d, 0x2000 },
  { 0x0700, 0xfd9c, 0x0000 },
  { 0x0700, 0xfd9e, 0x0000 },
  { 0x8700, 0xfdbf, 0x6000 },
  { 0x8700, 0xfdaf, 0x5000 },
  { 0x8700, 0xfda7, 0x4000 },
  { 0x8700, 0xfda3, 0x3000 },
  { 0x8700, 0xfda1, 0x2000 },
  { 0x0700, 0xfda0, 0x0000 },
  { 0x0700, 0xfda2, 0x0000 },
  { 0x8700, 0xfda5, 0x2000 },
  { 0x0700, 0xfda4, 0x0000 },
  { 0x0700, 0xfda6, 0x0000 },
  { 0x8700, 0xfdab, 0x3000 },
  { 0x8700, 0xfda9, 0x2000 },
  { 0x0700, 0xfda8, 0x0000 },
  { 0x0700, 0xfdaa, 0x0000 },
  { 0x8700, 0xfdad, 0x2000 },
  { 0x0700, 0xfdac, 0x0000 },
  { 0x0700, 0xfdae, 0x0000 },
  { 0x8700, 0xfdb7, 0x4000 },
  { 0x8700, 0xfdb3, 0x3000 },
  { 0x8700, 0xfdb1, 0x2000 },
  { 0x0700, 0xfdb0, 0x0000 },
  { 0x0700, 0xfdb2, 0x0000 },
  { 0x8700, 0xfdb5, 0x2000 },
  { 0x0700, 0xfdb4, 0x0000 },
  { 0x0700, 0xfdb6, 0x0000 },
  { 0x8700, 0xfdbb, 0x3000 },
  { 0x8700, 0xfdb9, 0x2000 },
  { 0x0700, 0xfdb8, 0x0000 },
  { 0x0700, 0xfdba, 0x0000 },
  { 0x8700, 0xfdbd, 0x2000 },
  { 0x0700, 0xfdbc, 0x0000 },
  { 0x0700, 0xfdbe, 0x0000 },
  { 0x8700, 0xfdf7, 0x5000 },
  { 0x8700, 0xfdc7, 0x4000 },
  { 0x8700, 0xfdc3, 0x3000 },
  { 0x8700, 0xfdc1, 0x2000 },
  { 0x0700, 0xfdc0, 0x0000 },
  { 0x0700, 0xfdc2, 0x0000 },
  { 0x8700, 0xfdc5, 0x2000 },
  { 0x0700, 0xfdc4, 0x0000 },
  { 0x0700, 0xfdc6, 0x0000 },
  { 0x8700, 0xfdf3, 0x3000 },
  { 0x8700, 0xfdf1, 0x2000 },
  { 0x0700, 0xfdf0, 0x0000 },
  { 0x0700, 0xfdf2, 0x0000 },
  { 0x8700, 0xfdf5, 0x2000 },
  { 0x0700, 0xfdf4, 0x0000 },
  { 0x0700, 0xfdf6, 0x0000 },
  { 0x8c00, 0xfe01, 0x4000 },
  { 0x8700, 0xfdfb, 0x3000 },
  { 0x8700, 0xfdf9, 0x2000 },
  { 0x0700, 0xfdf8, 0x0000 },
  { 0x0700, 0xfdfa, 0x0000 },
  { 0x9a00, 0xfdfd, 0x2000 },
  { 0x1700, 0xfdfc, 0x0000 },
  { 0x0c00, 0xfe00, 0x0000 },
  { 0x8c00, 0xfe05, 0x3000 },
  { 0x8c00, 0xfe03, 0x2000 },
  { 0x0c00, 0xfe02, 0x0000 },
  { 0x0c00, 0xfe04, 0x0000 },
  { 0x8c00, 0xfe07, 0x2000 },
  { 0x0c00, 0xfe06, 0x0000 },
  { 0x0c00, 0xfe08, 0x0000 },
  { 0x9900, 0xfe66, 0x7000 },
  { 0x9500, 0xfe45, 0x6000 },
  { 0x9600, 0xfe35, 0x5000 },
  { 0x8c00, 0xfe21, 0x4000 },
  { 0x8c00, 0xfe0d, 0x3000 },
  { 0x8c00, 0xfe0b, 0x2000 },
  { 0x0c00, 0xfe0a, 0x0000 },
  { 0x0c00, 0xfe0c, 0x0000 },
  { 0x8c00, 0xfe0f, 0x2000 },
  { 0x0c00, 0xfe0e, 0x0000 },
  { 0x0c00, 0xfe20, 0x0000 },
  { 0x9100, 0xfe31, 0x3000 },
  { 0x8c00, 0xfe23, 0x2000 },
  { 0x0c00, 0xfe22, 0x0000 },
  { 0x1500, 0xfe30, 0x0000 },
  { 0x9000, 0xfe33, 0x2000 },
  { 0x1100, 0xfe32, 0x0000 },
  { 0x1000, 0xfe34, 0x0000 },
  { 0x9600, 0xfe3d, 0x4000 },
  { 0x9600, 0xfe39, 0x3000 },
  { 0x9600, 0xfe37, 0x2000 },
  { 0x1200, 0xfe36, 0x0000 },
  { 0x1200, 0xfe38, 0x0000 },
  { 0x9600, 0xfe3b, 0x2000 },
  { 0x1200, 0xfe3a, 0x0000 },
  { 0x1200, 0xfe3c, 0x0000 },
  { 0x9600, 0xfe41, 0x3000 },
  { 0x9600, 0xfe3f, 0x2000 },
  { 0x1200, 0xfe3e, 0x0000 },
  { 0x1200, 0xfe40, 0x0000 },
  { 0x9600, 0xfe43, 0x2000 },
  { 0x1200, 0xfe42, 0x0000 },
  { 0x1200, 0xfe44, 0x0000 },
  { 0x9500, 0xfe56, 0x5000 },
  { 0x9000, 0xfe4d, 0x4000 },
  { 0x9500, 0xfe49, 0x3000 },
  { 0x9600, 0xfe47, 0x2000 },
  { 0x1500, 0xfe46, 0x0000 },
  { 0x1200, 0xfe48, 0x0000 },
  { 0x9500, 0xfe4b, 0x2000 },
  { 0x1500, 0xfe4a, 0x0000 },
  { 0x1500, 0xfe4c, 0x0000 },
  { 0x9500, 0xfe51, 0x3000 },
  { 0x9000, 0xfe4f, 0x2000 },
  { 0x1000, 0xfe4e, 0x0000 },
  { 0x1500, 0xfe50, 0x0000 },
  { 0x9500, 0xfe54, 0x2000 },
  { 0x1500, 0xfe52, 0x0000 },
  { 0x1500, 0xfe55, 0x0000 },
  { 0x9200, 0xfe5e, 0x4000 },
  { 0x9200, 0xfe5a, 0x3000 },
  { 0x9100, 0xfe58, 0x2000 },
  { 0x1500, 0xfe57, 0x0000 },
  { 0x1600, 0xfe59, 0x0000 },
  { 0x9200, 0xfe5c, 0x2000 },
  { 0x1600, 0xfe5b, 0x0000 },
  { 0x1600, 0xfe5d, 0x0000 },
  { 0x9900, 0xfe62, 0x3000 },
  { 0x9500, 0xfe60, 0x2000 },
  { 0x1500, 0xfe5f, 0x0000 },
  { 0x1500, 0xfe61, 0x0000 },
  { 0x9900, 0xfe64, 0x2000 },
  { 0x1100, 0xfe63, 0x0000 },
  { 0x1900, 0xfe65, 0x0000 },
  { 0x8700, 0xfe8c, 0x6000 },
  { 0x8700, 0xfe7c, 0x5000 },
  { 0x8700, 0xfe73, 0x4000 },
  { 0x9500, 0xfe6b, 0x3000 },
  { 0x9700, 0xfe69, 0x2000 },
  { 0x1500, 0xfe68, 0x0000 },
  { 0x1500, 0xfe6a, 0x0000 },
  { 0x8700, 0xfe71, 0x2000 },
  { 0x0700, 0xfe70, 0x0000 },
  { 0x0700, 0xfe72, 0x0000 },
  { 0x8700, 0xfe78, 0x3000 },
  { 0x8700, 0xfe76, 0x2000 },
  { 0x0700, 0xfe74, 0x0000 },
  { 0x0700, 0xfe77, 0x0000 },
  { 0x8700, 0xfe7a, 0x2000 },
  { 0x0700, 0xfe79, 0x0000 },
  { 0x0700, 0xfe7b, 0x0000 },
  { 0x8700, 0xfe84, 0x4000 },
  { 0x8700, 0xfe80, 0x3000 },
  { 0x8700, 0xfe7e, 0x2000 },
  { 0x0700, 0xfe7d, 0x0000 },
  { 0x0700, 0xfe7f, 0x0000 },
  { 0x8700, 0xfe82, 0x2000 },
  { 0x0700, 0xfe81, 0x0000 },
  { 0x0700, 0xfe83, 0x0000 },
  { 0x8700, 0xfe88, 0x3000 },
  { 0x8700, 0xfe86, 0x2000 },
  { 0x0700, 0xfe85, 0x0000 },
  { 0x0700, 0xfe87, 0x0000 },
  { 0x8700, 0xfe8a, 0x2000 },
  { 0x0700, 0xfe89, 0x0000 },
  { 0x0700, 0xfe8b, 0x0000 },
  { 0x8700, 0xfe9c, 0x5000 },
  { 0x8700, 0xfe94, 0x4000 },
  { 0x8700, 0xfe90, 0x3000 },
  { 0x8700, 0xfe8e, 0x2000 },
  { 0x0700, 0xfe8d, 0x0000 },
  { 0x0700, 0xfe8f, 0x0000 },
  { 0x8700, 0xfe92, 0x2000 },
  { 0x0700, 0xfe91, 0x0000 },
  { 0x0700, 0xfe93, 0x0000 },
  { 0x8700, 0xfe98, 0x3000 },
  { 0x8700, 0xfe96, 0x2000 },
  { 0x0700, 0xfe95, 0x0000 },
  { 0x0700, 0xfe97, 0x0000 },
  { 0x8700, 0xfe9a, 0x2000 },
  { 0x0700, 0xfe99, 0x0000 },
  { 0x0700, 0xfe9b, 0x0000 },
  { 0x8700, 0xfea4, 0x4000 },
  { 0x8700, 0xfea0, 0x3000 },
  { 0x8700, 0xfe9e, 0x2000 },
  { 0x0700, 0xfe9d, 0x0000 },
  { 0x0700, 0xfe9f, 0x0000 },
  { 0x8700, 0xfea2, 0x2000 },
  { 0x0700, 0xfea1, 0x0000 },
  { 0x0700, 0xfea3, 0x0000 },
  { 0x8700, 0xfea8, 0x3000 },
  { 0x8700, 0xfea6, 0x2000 },
  { 0x0700, 0xfea5, 0x0000 },
  { 0x0700, 0xfea7, 0x0000 },
  { 0x8700, 0xfeaa, 0x2000 },
  { 0x0700, 0xfea9, 0x0000 },
  { 0x0700, 0xfeab, 0x0000 },
  { 0x8700, 0xffaf, 0x9000 },
  { 0x8900, 0xff2f, 0x8020 },
  { 0x8700, 0xfeec, 0x7000 },
  { 0x8700, 0xfecc, 0x6000 },
  { 0x8700, 0xfebc, 0x5000 },
  { 0x8700, 0xfeb4, 0x4000 },
  { 0x8700, 0xfeb0, 0x3000 },
  { 0x8700, 0xfeae, 0x2000 },
  { 0x0700, 0xfead, 0x0000 },
  { 0x0700, 0xfeaf, 0x0000 },
  { 0x8700, 0xfeb2, 0x2000 },
  { 0x0700, 0xfeb1, 0x0000 },
  { 0x0700, 0xfeb3, 0x0000 },
  { 0x8700, 0xfeb8, 0x3000 },
  { 0x8700, 0xfeb6, 0x2000 },
  { 0x0700, 0xfeb5, 0x0000 },
  { 0x0700, 0xfeb7, 0x0000 },
  { 0x8700, 0xfeba, 0x2000 },
  { 0x0700, 0xfeb9, 0x0000 },
  { 0x0700, 0xfebb, 0x0000 },
  { 0x8700, 0xfec4, 0x4000 },
  { 0x8700, 0xfec0, 0x3000 },
  { 0x8700, 0xfebe, 0x2000 },
  { 0x0700, 0xfebd, 0x0000 },
  { 0x0700, 0xfebf, 0x0000 },
  { 0x8700, 0xfec2, 0x2000 },
  { 0x0700, 0xfec1, 0x0000 },
  { 0x0700, 0xfec3, 0x0000 },
  { 0x8700, 0xfec8, 0x3000 },
  { 0x8700, 0xfec6, 0x2000 },
  { 0x0700, 0xfec5, 0x0000 },
  { 0x0700, 0xfec7, 0x0000 },
  { 0x8700, 0xfeca, 0x2000 },
  { 0x0700, 0xfec9, 0x0000 },
  { 0x0700, 0xfecb, 0x0000 },
  { 0x8700, 0xfedc, 0x5000 },
  { 0x8700, 0xfed4, 0x4000 },
  { 0x8700, 0xfed0, 0x3000 },
  { 0x8700, 0xfece, 0x2000 },
  { 0x0700, 0xfecd, 0x0000 },
  { 0x0700, 0xfecf, 0x0000 },
  { 0x8700, 0xfed2, 0x2000 },
  { 0x0700, 0xfed1, 0x0000 },
  { 0x0700, 0xfed3, 0x0000 },
  { 0x8700, 0xfed8, 0x3000 },
  { 0x8700, 0xfed6, 0x2000 },
  { 0x0700, 0xfed5, 0x0000 },
  { 0x0700, 0xfed7, 0x0000 },
  { 0x8700, 0xfeda, 0x2000 },
  { 0x0700, 0xfed9, 0x0000 },
  { 0x0700, 0xfedb, 0x0000 },
  { 0x8700, 0xfee4, 0x4000 },
  { 0x8700, 0xfee0, 0x3000 },
  { 0x8700, 0xfede, 0x2000 },
  { 0x0700, 0xfedd, 0x0000 },
  { 0x0700, 0xfedf, 0x0000 },
  { 0x8700, 0xfee2, 0x2000 },
  { 0x0700, 0xfee1, 0x0000 },
  { 0x0700, 0xfee3, 0x0000 },
  { 0x8700, 0xfee8, 0x3000 },
  { 0x8700, 0xfee6, 0x2000 },
  { 0x0700, 0xfee5, 0x0000 },
  { 0x0700, 0xfee7, 0x0000 },
  { 0x8700, 0xfeea, 0x2000 },
  { 0x0700, 0xfee9, 0x0000 },
  { 0x0700, 0xfeeb, 0x0000 },
  { 0x9500, 0xff0f, 0x6000 },
  { 0x8700, 0xfefc, 0x5000 },
  { 0x8700, 0xfef4, 0x4000 },
  { 0x8700, 0xfef0, 0x3000 },
  { 0x8700, 0xfeee, 0x2000 },
  { 0x0700, 0xfeed, 0x0000 },
  { 0x0700, 0xfeef, 0x0000 },
  { 0x8700, 0xfef2, 0x2000 },
  { 0x0700, 0xfef1, 0x0000 },
  { 0x0700, 0xfef3, 0x0000 },
  { 0x8700, 0xfef8, 0x3000 },
  { 0x8700, 0xfef6, 0x2000 },
  { 0x0700, 0xfef5, 0x0000 },
  { 0x0700, 0xfef7, 0x0000 },
  { 0x8700, 0xfefa, 0x2000 },
  { 0x0700, 0xfef9, 0x0000 },
  { 0x0700, 0xfefb, 0x0000 },
  { 0x9500, 0xff07, 0x4000 },
  { 0x9500, 0xff03, 0x3000 },
  { 0x9500, 0xff01, 0x2000 },
  { 0x0100, 0xfeff, 0x0000 },
  { 0x1500, 0xff02, 0x0000 },
  { 0x9500, 0xff05, 0x2000 },
  { 0x1700, 0xff04, 0x0000 },
  { 0x1500, 0xff06, 0x0000 },
  { 0x9900, 0xff0b, 0x3000 },
  { 0x9200, 0xff09, 0x2000 },
  { 0x1600, 0xff08, 0x0000 },
  { 0x1500, 0xff0a, 0x0000 },
  { 0x9100, 0xff0d, 0x2000 },
  { 0x1500, 0xff0c, 0x0000 },
  { 0x1500, 0xff0e, 0x0000 },
  { 0x9500, 0xff1f, 0x5000 },
  { 0x8d00, 0xff17, 0x4000 },
  { 0x8d00, 0xff13, 0x3000 },
  { 0x8d00, 0xff11, 0x2000 },
  { 0x0d00, 0xff10, 0x0000 },
  { 0x0d00, 0xff12, 0x0000 },
  { 0x8d00, 0xff15, 0x2000 },
  { 0x0d00, 0xff14, 0x0000 },
  { 0x0d00, 0xff16, 0x0000 },
  { 0x9500, 0xff1b, 0x3000 },
  { 0x8d00, 0xff19, 0x2000 },
  { 0x0d00, 0xff18, 0x0000 },
  { 0x1500, 0xff1a, 0x0000 },
  { 0x9900, 0xff1d, 0x2000 },
  { 0x1900, 0xff1c, 0x0000 },
  { 0x1900, 0xff1e, 0x0000 },
  { 0x8900, 0xff27, 0x4020 },
  { 0x8900, 0xff23, 0x3020 },
  { 0x8900, 0xff21, 0x2020 },
  { 0x1500, 0xff20, 0x0000 },
  { 0x0900, 0xff22, 0x0020 },
  { 0x8900, 0xff25, 0x2020 },
  { 0x0900, 0xff24, 0x0020 },
  { 0x0900, 0xff26, 0x0020 },
  { 0x8900, 0xff2b, 0x3020 },
  { 0x8900, 0xff29, 0x2020 },
  { 0x0900, 0xff28, 0x0020 },
  { 0x0900, 0xff2a, 0x0020 },
  { 0x8900, 0xff2d, 0x2020 },
  { 0x0900, 0xff2c, 0x0020 },
  { 0x0900, 0xff2e, 0x0020 },
  { 0x8700, 0xff6f, 0x7000 },
  { 0x8500, 0xff4f, 0x6fe0 },
  { 0x9000, 0xff3f, 0x5000 },
  { 0x8900, 0xff37, 0x4020 },
  { 0x8900, 0xff33, 0x3020 },
  { 0x8900, 0xff31, 0x2020 },
  { 0x0900, 0xff30, 0x0020 },
  { 0x0900, 0xff32, 0x0020 },
  { 0x8900, 0xff35, 0x2020 },
  { 0x0900, 0xff34, 0x0020 },
  { 0x0900, 0xff36, 0x0020 },
  { 0x9600, 0xff3b, 0x3000 },
  { 0x8900, 0xff39, 0x2020 },
  { 0x0900, 0xff38, 0x0020 },
  { 0x0900, 0xff3a, 0x0020 },
  { 0x9200, 0xff3d, 0x2000 },
  { 0x1500, 0xff3c, 0x0000 },
  { 0x1800, 0xff3e, 0x0000 },
  { 0x8500, 0xff47, 0x4fe0 },
  { 0x8500, 0xff43, 0x3fe0 },
  { 0x8500, 0xff41, 0x2fe0 },
  { 0x1800, 0xff40, 0x0000 },
  { 0x0500, 0xff42, 0x0fe0 },
  { 0x8500, 0xff45, 0x2fe0 },
  { 0x0500, 0xff44, 0x0fe0 },
  { 0x0500, 0xff46, 0x0fe0 },
  { 0x8500, 0xff4b, 0x3fe0 },
  { 0x8500, 0xff49, 0x2fe0 },
  { 0x0500, 0xff48, 0x0fe0 },
  { 0x0500, 0xff4a, 0x0fe0 },
  { 0x8500, 0xff4d, 0x2fe0 },
  { 0x0500, 0xff4c, 0x0fe0 },
  { 0x0500, 0xff4e, 0x0fe0 },
  { 0x9600, 0xff5f, 0x5000 },
  { 0x8500, 0xff57, 0x4fe0 },
  { 0x8500, 0xff53, 0x3fe0 },
  { 0x8500, 0xff51, 0x2fe0 },
  { 0x0500, 0xff50, 0x0fe0 },
  { 0x0500, 0xff52, 0x0fe0 },
  { 0x8500, 0xff55, 0x2fe0 },
  { 0x0500, 0xff54, 0x0fe0 },
  { 0x0500, 0xff56, 0x0fe0 },
  { 0x9600, 0xff5b, 0x3000 },
  { 0x8500, 0xff59, 0x2fe0 },
  { 0x0500, 0xff58, 0x0fe0 },
  { 0x0500, 0xff5a, 0x0fe0 },
  { 0x9200, 0xff5d, 0x2000 },
  { 0x1900, 0xff5c, 0x0000 },
  { 0x1900, 0xff5e, 0x0000 },
  { 0x8700, 0xff67, 0x4000 },
  { 0x9200, 0xff63, 0x3000 },
  { 0x9500, 0xff61, 0x2000 },
  { 0x1200, 0xff60, 0x0000 },
  { 0x1600, 0xff62, 0x0000 },
  { 0x9000, 0xff65, 0x2000 },
  { 0x1500, 0xff64, 0x0000 },
  { 0x0700, 0xff66, 0x0000 },
  { 0x8700, 0xff6b, 0x3000 },
  { 0x8700, 0xff69, 0x2000 },
  { 0x0700, 0xff68, 0x0000 },
  { 0x0700, 0xff6a, 0x0000 },
  { 0x8700, 0xff6d, 0x2000 },
  { 0x0700, 0xff6c, 0x0000 },
  { 0x0700, 0xff6e, 0x0000 },
  { 0x8700, 0xff8f, 0x6000 },
  { 0x8700, 0xff7f, 0x5000 },
  { 0x8700, 0xff77, 0x4000 },
  { 0x8700, 0xff73, 0x3000 },
  { 0x8700, 0xff71, 0x2000 },
  { 0x0600, 0xff70, 0x0000 },
  { 0x0700, 0xff72, 0x0000 },
  { 0x8700, 0xff75, 0x2000 },
  { 0x0700, 0xff74, 0x0000 },
  { 0x0700, 0xff76, 0x0000 },
  { 0x8700, 0xff7b, 0x3000 },
  { 0x8700, 0xff79, 0x2000 },
  { 0x0700, 0xff78, 0x0000 },
  { 0x0700, 0xff7a, 0x0000 },
  { 0x8700, 0xff7d, 0x2000 },
  { 0x0700, 0xff7c, 0x0000 },
  { 0x0700, 0xff7e, 0x0000 },
  { 0x8700, 0xff87, 0x4000 },
  { 0x8700, 0xff83, 0x3000 },
  { 0x8700, 0xff81, 0x2000 },
  { 0x0700, 0xff80, 0x0000 },
  { 0x0700, 0xff82, 0x0000 },
  { 0x8700, 0xff85, 0x2000 },
  { 0x0700, 0xff84, 0x0000 },
  { 0x0700, 0xff86, 0x0000 },
  { 0x8700, 0xff8b, 0x3000 },
  { 0x8700, 0xff89, 0x2000 },
  { 0x0700, 0xff88, 0x0000 },
  { 0x0700, 0xff8a, 0x0000 },
  { 0x8700, 0xff8d, 0x2000 },
  { 0x0700, 0xff8c, 0x0000 },
  { 0x0700, 0xff8e, 0x0000 },
  { 0x8600, 0xff9f, 0x5000 },
  { 0x8700, 0xff97, 0x4000 },
  { 0x8700, 0xff93, 0x3000 },
  { 0x8700, 0xff91, 0x2000 },
  { 0x0700, 0xff90, 0x0000 },
  { 0x0700, 0xff92, 0x0000 },
  { 0x8700, 0xff95, 0x2000 },
  { 0x0700, 0xff94, 0x0000 },
  { 0x0700, 0xff96, 0x0000 },
  { 0x8700, 0xff9b, 0x3000 },
  { 0x8700, 0xff99, 0x2000 },
  { 0x0700, 0xff98, 0x0000 },
  { 0x0700, 0xff9a, 0x0000 },
  { 0x8700, 0xff9d, 0x2000 },
  { 0x0700, 0xff9c, 0x0000 },
  { 0x0600, 0xff9e, 0x0000 },
  { 0x8700, 0xffa7, 0x4000 },
  { 0x8700, 0xffa3, 0x3000 },
  { 0x8700, 0xffa1, 0x2000 },
  { 0x0700, 0xffa0, 0x0000 },
  { 0x0700, 0xffa2, 0x0000 },
  { 0x8700, 0xffa5, 0x2000 },
  { 0x0700, 0xffa4, 0x0000 },
  { 0x0700, 0xffa6, 0x0000 },
  { 0x8700, 0xffab, 0x3000 },
  { 0x8700, 0xffa9, 0x2000 },
  { 0x0700, 0xffa8, 0x0000 },
  { 0x0700, 0xffaa, 0x0000 },
  { 0x8700, 0xffad, 0x2000 },
  { 0x0700, 0xffac, 0x0000 },
  { 0x0700, 0xffae, 0x0000 },
  { 0x8701, 0x004c, 0x8000 },
  { 0x8701, 0x0008, 0x7000 },
  { 0x8700, 0xffd6, 0x6000 },
  { 0x8700, 0xffc2, 0x5000 },
  { 0x8700, 0xffb7, 0x4000 },
  { 0x8700, 0xffb3, 0x3000 },
  { 0x8700, 0xffb1, 0x2000 },
  { 0x0700, 0xffb0, 0x0000 },
  { 0x0700, 0xffb2, 0x0000 },
  { 0x8700, 0xffb5, 0x2000 },
  { 0x0700, 0xffb4, 0x0000 },
  { 0x0700, 0xffb6, 0x0000 },
  { 0x8700, 0xffbb, 0x3000 },
  { 0x8700, 0xffb9, 0x2000 },
  { 0x0700, 0xffb8, 0x0000 },
  { 0x0700, 0xffba, 0x0000 },
  { 0x8700, 0xffbd, 0x2000 },
  { 0x0700, 0xffbc, 0x0000 },
  { 0x0700, 0xffbe, 0x0000 },
  { 0x8700, 0xffcc, 0x4000 },
  { 0x8700, 0xffc6, 0x3000 },
  { 0x8700, 0xffc4, 0x2000 },
  { 0x0700, 0xffc3, 0x0000 },
  { 0x0700, 0xffc5, 0x0000 },
  { 0x8700, 0xffca, 0x2000 },
  { 0x0700, 0xffc7, 0x0000 },
  { 0x0700, 0xffcb, 0x0000 },
  { 0x8700, 0xffd2, 0x3000 },
  { 0x8700, 0xffce, 0x2000 },
  { 0x0700, 0xffcd, 0x0000 },
  { 0x0700, 0xffcf, 0x0000 },
  { 0x8700, 0xffd4, 0x2000 },
  { 0x0700, 0xffd3, 0x0000 },
  { 0x0700, 0xffd5, 0x0000 },
  { 0x9900, 0xffec, 0x5000 },
  { 0x9800, 0xffe3, 0x4000 },
  { 0x8700, 0xffdc, 0x3000 },
  { 0x8700, 0xffda, 0x2000 },
  { 0x0700, 0xffd7, 0x0000 },
  { 0x0700, 0xffdb, 0x0000 },
  { 0x9700, 0xffe1, 0x2000 },
  { 0x1700, 0xffe0, 0x0000 },
  { 0x1900, 0xffe2, 0x0000 },
  { 0x9a00, 0xffe8, 0x3000 },
  { 0x9700, 0xffe5, 0x2000 },
  { 0x1a00, 0xffe4, 0x0000 },
  { 0x1700, 0xffe6, 0x0000 },
  { 0x9900, 0xffea, 0x2000 },
  { 0x1900, 0xffe9, 0x0000 },
  { 0x1900, 0xffeb, 0x0000 },
  { 0x8701, 0x0000, 0x4000 },
  { 0x8100, 0xfffa, 0x3000 },
  { 0x9a00, 0xffee, 0x2000 },
  { 0x1a00, 0xffed, 0x0000 },
  { 0x0100, 0xfff9, 0x0000 },
  { 0x9a00, 0xfffc, 0x2000 },
  { 0x0100, 0xfffb, 0x0000 },
  { 0x1a00, 0xfffd, 0x0000 },
  { 0x8701, 0x0004, 0x3000 },
  { 0x8701, 0x0002, 0x2000 },
  { 0x0701, 0x0001, 0x0000 },
  { 0x0701, 0x0003, 0x0000 },
  { 0x8701, 0x0006, 0x2000 },
  { 0x0701, 0x0005, 0x0000 },
  { 0x0701, 0x0007, 0x0000 },
  { 0x8701, 0x002a, 0x6000 },
  { 0x8701, 0x0019, 0x5000 },
  { 0x8701, 0x0011, 0x4000 },
  { 0x8701, 0x000d, 0x3000 },
  { 0x8701, 0x000a, 0x2000 },
  { 0x0701, 0x0009, 0x0000 },
  { 0x0701, 0x000b, 0x0000 },
  { 0x8701, 0x000f, 0x2000 },
  { 0x0701, 0x000e, 0x0000 },
  { 0x0701, 0x0010, 0x0000 },
  { 0x8701, 0x0015, 0x3000 },
  { 0x8701, 0x0013, 0x2000 },
  { 0x0701, 0x0012, 0x0000 },
  { 0x0701, 0x0014, 0x0000 },
  { 0x8701, 0x0017, 0x2000 },
  { 0x0701, 0x0016, 0x0000 },
  { 0x0701, 0x0018, 0x0000 },
  { 0x8701, 0x0021, 0x4000 },
  { 0x8701, 0x001d, 0x3000 },
  { 0x8701, 0x001b, 0x2000 },
  { 0x0701, 0x001a, 0x0000 },
  { 0x0701, 0x001c, 0x0000 },
  { 0x8701, 0x001f, 0x2000 },
  { 0x0701, 0x001e, 0x0000 },
  { 0x0701, 0x0020, 0x0000 },
  { 0x8701, 0x0025, 0x3000 },
  { 0x8701, 0x0023, 0x2000 },
  { 0x0701, 0x0022, 0x0000 },
  { 0x0701, 0x0024, 0x0000 },
  { 0x8701, 0x0028, 0x2000 },
  { 0x0701, 0x0026, 0x0000 },
  { 0x0701, 0x0029, 0x0000 },
  { 0x8701, 0x003a, 0x5000 },
  { 0x8701, 0x0032, 0x4000 },
  { 0x8701, 0x002e, 0x3000 },
  { 0x8701, 0x002c, 0x2000 },
  { 0x0701, 0x002b, 0x0000 },
  { 0x0701, 0x002d, 0x0000 },
  { 0x8701, 0x0030, 0x2000 },
  { 0x0701, 0x002f, 0x0000 },
  { 0x0701, 0x0031, 0x0000 },
  { 0x8701, 0x0036, 0x3000 },
  { 0x8701, 0x0034, 0x2000 },
  { 0x0701, 0x0033, 0x0000 },
  { 0x0701, 0x0035, 0x0000 },
  { 0x8701, 0x0038, 0x2000 },
  { 0x0701, 0x0037, 0x0000 },
  { 0x0701, 0x0039, 0x0000 },
  { 0x8701, 0x0044, 0x4000 },
  { 0x8701, 0x0040, 0x3000 },
  { 0x8701, 0x003d, 0x2000 },
  { 0x0701, 0x003c, 0x0000 },
  { 0x0701, 0x003f, 0x0000 },
  { 0x8701, 0x0042, 0x2000 },
  { 0x0701, 0x0041, 0x0000 },
  { 0x0701, 0x0043, 0x0000 },
  { 0x8701, 0x0048, 0x3000 },
  { 0x8701, 0x0046, 0x2000 },
  { 0x0701, 0x0045, 0x0000 },
  { 0x0701, 0x0047, 0x0000 },
  { 0x8701, 0x004a, 0x2000 },
  { 0x0701, 0x0049, 0x0000 },
  { 0x0701, 0x004b, 0x0000 },
  { 0x8701, 0x00b0, 0x7000 },
  { 0x8701, 0x0090, 0x6000 },
  { 0x8701, 0x0080, 0x5000 },
  { 0x8701, 0x0056, 0x4000 },
  { 0x8701, 0x0052, 0x3000 },
  { 0x8701, 0x0050, 0x2000 },
  { 0x0701, 0x004d, 0x0000 },
  { 0x0701, 0x0051, 0x0000 },
  { 0x8701, 0x0054, 0x2000 },
  { 0x0701, 0x0053, 0x0000 },
  { 0x0701, 0x0055, 0x0000 },
  { 0x8701, 0x005a, 0x3000 },
  { 0x8701, 0x0058, 0x2000 },
  { 0x0701, 0x0057, 0x0000 },
  { 0x0701, 0x0059, 0x0000 },
  { 0x8701, 0x005c, 0x2000 },
  { 0x0701, 0x005b, 0x0000 },
  { 0x0701, 0x005d, 0x0000 },
  { 0x8701, 0x0088, 0x4000 },
  { 0x8701, 0x0084, 0x3000 },
  { 0x8701, 0x0082, 0x2000 },
  { 0x0701, 0x0081, 0x0000 },
  { 0x0701, 0x0083, 0x0000 },
  { 0x8701, 0x0086, 0x2000 },
  { 0x0701, 0x0085, 0x0000 },
  { 0x0701, 0x0087, 0x0000 },
  { 0x8701, 0x008c, 0x3000 },
  { 0x8701, 0x008a, 0x2000 },
  { 0x0701, 0x0089, 0x0000 },
  { 0x0701, 0x008b, 0x0000 },
  { 0x8701, 0x008e, 0x2000 },
  { 0x0701, 0x008d, 0x0000 },
  { 0x0701, 0x008f, 0x0000 },
  { 0x8701, 0x00a0, 0x5000 },
  { 0x8701, 0x0098, 0x4000 },
  { 0x8701, 0x0094, 0x3000 },
  { 0x8701, 0x0092, 0x2000 },
  { 0x0701, 0x0091, 0x0000 },
  { 0x0701, 0x0093, 0x0000 },
  { 0x8701, 0x0096, 0x2000 },
  { 0x0701, 0x0095, 0x0000 },
  { 0x0701, 0x0097, 0x0000 },
  { 0x8701, 0x009c, 0x3000 },
  { 0x8701, 0x009a, 0x2000 },
  { 0x0701, 0x0099, 0x0000 },
  { 0x0701, 0x009b, 0x0000 },
  { 0x8701, 0x009e, 0x2000 },
  { 0x0701, 0x009d, 0x0000 },
  { 0x0701, 0x009f, 0x0000 },
  { 0x8701, 0x00a8, 0x4000 },
  { 0x8701, 0x00a4, 0x3000 },
  { 0x8701, 0x00a2, 0x2000 },
  { 0x0701, 0x00a1, 0x0000 },
  { 0x0701, 0x00a3, 0x0000 },
  { 0x8701, 0x00a6, 0x2000 },
  { 0x0701, 0x00a5, 0x0000 },
  { 0x0701, 0x00a7, 0x0000 },
  { 0x8701, 0x00ac, 0x3000 },
  { 0x8701, 0x00aa, 0x2000 },
  { 0x0701, 0x00a9, 0x0000 },
  { 0x0701, 0x00ab, 0x0000 },
  { 0x8701, 0x00ae, 0x2000 },
  { 0x0701, 0x00ad, 0x0000 },
  { 0x0701, 0x00af, 0x0000 },
  { 0x8701, 0x00d0, 0x6000 },
  { 0x8701, 0x00c0, 0x5000 },
  { 0x8701, 0x00b8, 0x4000 },
  { 0x8701, 0x00b4, 0x3000 },
  { 0x8701, 0x00b2, 0x2000 },
  { 0x0701, 0x00b1, 0x0000 },
  { 0x0701, 0x00b3, 0x0000 },
  { 0x8701, 0x00b6, 0x2000 },
  { 0x0701, 0x00b5, 0x0000 },
  { 0x0701, 0x00b7, 0x0000 },
  { 0x8701, 0x00bc, 0x3000 },
  { 0x8701, 0x00ba, 0x2000 },
  { 0x0701, 0x00b9, 0x0000 },
  { 0x0701, 0x00bb, 0x0000 },
  { 0x8701, 0x00be, 0x2000 },
  { 0x0701, 0x00bd, 0x0000 },
  { 0x0701, 0x00bf, 0x0000 },
  { 0x8701, 0x00c8, 0x4000 },
  { 0x8701, 0x00c4, 0x3000 },
  { 0x8701, 0x00c2, 0x2000 },
  { 0x0701, 0x00c1, 0x0000 },
  { 0x0701, 0x00c3, 0x0000 },
  { 0x8701, 0x00c6, 0x2000 },
  { 0x0701, 0x00c5, 0x0000 },
  { 0x0701, 0x00c7, 0x0000 },
  { 0x8701, 0x00cc, 0x3000 },
  { 0x8701, 0x00ca, 0x2000 },
  { 0x0701, 0x00c9, 0x0000 },
  { 0x0701, 0x00cb, 0x0000 },
  { 0x8701, 0x00ce, 0x2000 },
  { 0x0701, 0x00cd, 0x0000 },
  { 0x0701, 0x00cf, 0x0000 },
  { 0x8701, 0x00e0, 0x5000 },
  { 0x8701, 0x00d8, 0x4000 },
  { 0x8701, 0x00d4, 0x3000 },
  { 0x8701, 0x00d2, 0x2000 },
  { 0x0701, 0x00d1, 0x0000 },
  { 0x0701, 0x00d3, 0x0000 },
  { 0x8701, 0x00d6, 0x2000 },
  { 0x0701, 0x00d5, 0x0000 },
  { 0x0701, 0x00d7, 0x0000 },
  { 0x8701, 0x00dc, 0x3000 },
  { 0x8701, 0x00da, 0x2000 },
  { 0x0701, 0x00d9, 0x0000 },
  { 0x0701, 0x00db, 0x0000 },
  { 0x8701, 0x00de, 0x2000 },
  { 0x0701, 0x00dd, 0x0000 },
  { 0x0701, 0x00df, 0x0000 },
  { 0x8701, 0x00e8, 0x4000 },
  { 0x8701, 0x00e4, 0x3000 },
  { 0x8701, 0x00e2, 0x2000 },
  { 0x0701, 0x00e1, 0x0000 },
  { 0x0701, 0x00e3, 0x0000 },
  { 0x8701, 0x00e6, 0x2000 },
  { 0x0701, 0x00e5, 0x0000 },
  { 0x0701, 0x00e7, 0x0000 },
  { 0x8701, 0x00ec, 0x3000 },
  { 0x8701, 0x00ea, 0x2000 },
  { 0x0701, 0x00e9, 0x0000 },
  { 0x0701, 0x00eb, 0x0000 },
  { 0x8701, 0x00ee, 0x2000 },
  { 0x0701, 0x00ed, 0x0000 },
  { 0x0701, 0x00ef, 0x0000 },
  { 0x8501, 0xd459, 0xb000 },
  { 0x9a01, 0xd080, 0xa000 },
  { 0x8701, 0x045f, 0x9000 },
  { 0x8701, 0x0349, 0x8000 },
  { 0x9a01, 0x013c, 0x7000 },
  { 0x8f01, 0x0119, 0x6000 },
  { 0x8f01, 0x0109, 0x5000 },
  { 0x8701, 0x00f8, 0x4000 },
  { 0x8701, 0x00f4, 0x3000 },
  { 0x8701, 0x00f2, 0x2000 },
  { 0x0701, 0x00f1, 0x0000 },
  { 0x0701, 0x00f3, 0x0000 },
  { 0x8701, 0x00f6, 0x2000 },
  { 0x0701, 0x00f5, 0x0000 },
  { 0x0701, 0x00f7, 0x0000 },
  { 0x9501, 0x0101, 0x3000 },
  { 0x8701, 0x00fa, 0x2000 },
  { 0x0701, 0x00f9, 0x0000 },
  { 0x1501, 0x0100, 0x0000 },
  { 0x8f01, 0x0107, 0x2000 },
  { 0x1a01, 0x0102, 0x0000 },
  { 0x0f01, 0x0108, 0x0000 },
  { 0x8f01, 0x0111, 0x4000 },
  { 0x8f01, 0x010d, 0x3000 },
  { 0x8f01, 0x010b, 0x2000 },
  { 0x0f01, 0x010a, 0x0000 },
  { 0x0f01, 0x010c, 0x0000 },
  { 0x8f01, 0x010f, 0x2000 },
  { 0x0f01, 0x010e, 0x0000 },
  { 0x0f01, 0x0110, 0x0000 },
  { 0x8f01, 0x0115, 0x3000 },
  { 0x8f01, 0x0113, 0x2000 },
  { 0x0f01, 0x0112, 0x0000 },
  { 0x0f01, 0x0114, 0x0000 },
  { 0x8f01, 0x0117, 0x2000 },
  { 0x0f01, 0x0116, 0x0000 },
  { 0x0f01, 0x0118, 0x0000 },
  { 0x8f01, 0x0129, 0x5000 },
  { 0x8f01, 0x0121, 0x4000 },
  { 0x8f01, 0x011d, 0x3000 },
  { 0x8f01, 0x011b, 0x2000 },
  { 0x0f01, 0x011a, 0x0000 },
  { 0x0f01, 0x011c, 0x0000 },
  { 0x8f01, 0x011f, 0x2000 },
  { 0x0f01, 0x011e, 0x0000 },
  { 0x0f01, 0x0120, 0x0000 },
  { 0x8f01, 0x0125, 0x3000 },
  { 0x8f01, 0x0123, 0x2000 },
  { 0x0f01, 0x0122, 0x0000 },
  { 0x0f01, 0x0124, 0x0000 },
  { 0x8f01, 0x0127, 0x2000 },
  { 0x0f01, 0x0126, 0x0000 },
  { 0x0f01, 0x0128, 0x0000 },
  { 0x8f01, 0x0131, 0x4000 },
  { 0x8f01, 0x012d, 0x3000 },
  { 0x8f01, 0x012b, 0x2000 },
  { 0x0f01, 0x012a, 0x0000 },
  { 0x0f01, 0x012c, 0x0000 },
  { 0x8f01, 0x012f, 0x2000 },
  { 0x0f01, 0x012e, 0x0000 },
  { 0x0f01, 0x0130, 0x0000 },
  { 0x9a01, 0x0138, 0x3000 },
  { 0x8f01, 0x0133, 0x2000 },
  { 0x0f01, 0x0132, 0x0000 },
  { 0x1a01, 0x0137, 0x0000 },
  { 0x9a01, 0x013a, 0x2000 },
  { 0x1a01, 0x0139, 0x0000 },
  { 0x1a01, 0x013b, 0x0000 },
  { 0x8701, 0x031c, 0x6000 },
  { 0x8701, 0x030c, 0x5000 },
  { 0x8701, 0x0304, 0x4000 },
  { 0x8701, 0x0300, 0x3000 },
  { 0x9a01, 0x013e, 0x2000 },
  { 0x1a01, 0x013d, 0x0000 },
  { 0x1a01, 0x013f, 0x0000 },
  { 0x8701, 0x0302, 0x2000 },
  { 0x0701, 0x0301, 0x0000 },
  { 0x0701, 0x0303, 0x0000 },
  { 0x8701, 0x0308, 0x3000 },
  { 0x8701, 0x0306, 0x2000 },
  { 0x0701, 0x0305, 0x0000 },
  { 0x0701, 0x0307, 0x0000 },
  { 0x8701, 0x030a, 0x2000 },
  { 0x0701, 0x0309, 0x0000 },
  { 0x0701, 0x030b, 0x0000 },
  { 0x8701, 0x0314, 0x4000 },
  { 0x8701, 0x0310, 0x3000 },
  { 0x8701, 0x030e, 0x2000 },
  { 0x0701, 0x030d, 0x0000 },
  { 0x0701, 0x030f, 0x0000 },
  { 0x8701, 0x0312, 0x2000 },
  { 0x0701, 0x0311, 0x0000 },
  { 0x0701, 0x0313, 0x0000 },
  { 0x8701, 0x0318, 0x3000 },
  { 0x8701, 0x0316, 0x2000 },
  { 0x0701, 0x0315, 0x0000 },
  { 0x0701, 0x0317, 0x0000 },
  { 0x8701, 0x031a, 0x2000 },
  { 0x0701, 0x0319, 0x0000 },
  { 0x0701, 0x031b, 0x0000 },
  { 0x8701, 0x0339, 0x5000 },
  { 0x8701, 0x0331, 0x4000 },
  { 0x8f01, 0x0321, 0x3000 },
  { 0x8701, 0x031e, 0x2000 },
  { 0x0701, 0x031d, 0x0000 },
  { 0x0f01, 0x0320, 0x0000 },
  { 0x8f01, 0x0323, 0x2000 },
  { 0x0f01, 0x0322, 0x0000 },
  { 0x0701, 0x0330, 0x0000 },
  { 0x8701, 0x0335, 0x3000 },
  { 0x8701, 0x0333, 0x2000 },
  { 0x0701, 0x0332, 0x0000 },
  { 0x0701, 0x0334, 0x0000 },
  { 0x8701, 0x0337, 0x2000 },
  { 0x0701, 0x0336, 0x0000 },
  { 0x0701, 0x0338, 0x0000 },
  { 0x8701, 0x0341, 0x4000 },
  { 0x8701, 0x033d, 0x3000 },
  { 0x8701, 0x033b, 0x2000 },
  { 0x0701, 0x033a, 0x0000 },
  { 0x0701, 0x033c, 0x0000 },
  { 0x8701, 0x033f, 0x2000 },
  { 0x0701, 0x033e, 0x0000 },
  { 0x0701, 0x0340, 0x0000 },
  { 0x8701, 0x0345, 0x3000 },
  { 0x8701, 0x0343, 0x2000 },
  { 0x0701, 0x0342, 0x0000 },
  { 0x0701, 0x0344, 0x0000 },
  { 0x8701, 0x0347, 0x2000 },
  { 0x0701, 0x0346, 0x0000 },
  { 0x0701, 0x0348, 0x0000 },
  { 0x8901, 0x041f, 0x7028 },
  { 0x9501, 0x039f, 0x6000 },
  { 0x8701, 0x038e, 0x5000 },
  { 0x8701, 0x0386, 0x4000 },
  { 0x8701, 0x0382, 0x3000 },
  { 0x8701, 0x0380, 0x2000 },
  { 0x0e01, 0x034a, 0x0000 },
  { 0x0701, 0x0381, 0x0000 },
  { 0x8701, 0x0384, 0x2000 },
  { 0x0701, 0x0383, 0x0000 },
  { 0x0701, 0x0385, 0x0000 },
  { 0x8701, 0x038a, 0x3000 },
  { 0x8701, 0x0388, 0x2000 },
  { 0x0701, 0x0387, 0x0000 },
  { 0x0701, 0x0389, 0x0000 },
  { 0x8701, 0x038c, 0x2000 },
  { 0x0701, 0x038b, 0x0000 },
  { 0x0701, 0x038d, 0x0000 },
  { 0x8701, 0x0396, 0x4000 },
  { 0x8701, 0x0392, 0x3000 },
  { 0x8701, 0x0390, 0x2000 },
  { 0x0701, 0x038f, 0x0000 },
  { 0x0701, 0x0391, 0x0000 },
  { 0x8701, 0x0394, 0x2000 },
  { 0x0701, 0x0393, 0x0000 },
  { 0x0701, 0x0395, 0x0000 },
  { 0x8701, 0x039a, 0x3000 },
  { 0x8701, 0x0398, 0x2000 },
  { 0x0701, 0x0397, 0x0000 },
  { 0x0701, 0x0399, 0x0000 },
  { 0x8701, 0x039c, 0x2000 },
  { 0x0701, 0x039b, 0x0000 },
  { 0x0701, 0x039d, 0x0000 },
  { 0x8901, 0x040f, 0x5028 },
  { 0x8901, 0x0407, 0x4028 },
  { 0x8901, 0x0403, 0x3028 },
  { 0x8901, 0x0401, 0x2028 },
  { 0x0901, 0x0400, 0x0028 },
  { 0x0901, 0x0402, 0x0028 },
  { 0x8901, 0x0405, 0x2028 },
  { 0x0901, 0x0404, 0x0028 },
  { 0x0901, 0x0406, 0x0028 },
  { 0x8901, 0x040b, 0x3028 },
  { 0x8901, 0x0409, 0x2028 },
  { 0x0901, 0x0408, 0x0028 },
  { 0x0901, 0x040a, 0x0028 },
  { 0x8901, 0x040d, 0x2028 },
  { 0x0901, 0x040c, 0x0028 },
  { 0x0901, 0x040e, 0x0028 },
  { 0x8901, 0x0417, 0x4028 },
  { 0x8901, 0x0413, 0x3028 },
  { 0x8901, 0x0411, 0x2028 },
  { 0x0901, 0x0410, 0x0028 },
  { 0x0901, 0x0412, 0x0028 },
  { 0x8901, 0x0415, 0x2028 },
  { 0x0901, 0x0414, 0x0028 },
  { 0x0901, 0x0416, 0x0028 },
  { 0x8901, 0x041b, 0x3028 },
  { 0x8901, 0x0419, 0x2028 },
  { 0x0901, 0x0418, 0x0028 },
  { 0x0901, 0x041a, 0x0028 },
  { 0x8901, 0x041d, 0x2028 },
  { 0x0901, 0x041c, 0x0028 },
  { 0x0901, 0x041e, 0x0028 },
  { 0x8501, 0x043f, 0x6fd8 },
  { 0x8501, 0x042f, 0x5fd8 },
  { 0x8901, 0x0427, 0x4028 },
  { 0x8901, 0x0423, 0x3028 },
  { 0x8901, 0x0421, 0x2028 },
  { 0x0901, 0x0420, 0x0028 },
  { 0x0901, 0x0422, 0x0028 },
  { 0x8901, 0x0425, 0x2028 },
  { 0x0901, 0x0424, 0x0028 },
  { 0x0901, 0x0426, 0x0028 },
  { 0x8501, 0x042b, 0x3fd8 },
  { 0x8501, 0x0429, 0x2fd8 },
  { 0x0501, 0x0428, 0x0fd8 },
  { 0x0501, 0x042a, 0x0fd8 },
  { 0x8501, 0x042d, 0x2fd8 },
  { 0x0501, 0x042c, 0x0fd8 },
  { 0x0501, 0x042e, 0x0fd8 },
  { 0x8501, 0x0437, 0x4fd8 },
  { 0x8501, 0x0433, 0x3fd8 },
  { 0x8501, 0x0431, 0x2fd8 },
  { 0x0501, 0x0430, 0x0fd8 },
  { 0x0501, 0x0432, 0x0fd8 },
  { 0x8501, 0x0435, 0x2fd8 },
  { 0x0501, 0x0434, 0x0fd8 },
  { 0x0501, 0x0436, 0x0fd8 },
  { 0x8501, 0x043b, 0x3fd8 },
  { 0x8501, 0x0439, 0x2fd8 },
  { 0x0501, 0x0438, 0x0fd8 },
  { 0x0501, 0x043a, 0x0fd8 },
  { 0x8501, 0x043d, 0x2fd8 },
  { 0x0501, 0x043c, 0x0fd8 },
  { 0x0501, 0x043e, 0x0fd8 },
  { 0x8501, 0x044f, 0x5fd8 },
  { 0x8501, 0x0447, 0x4fd8 },
  { 0x8501, 0x0443, 0x3fd8 },
  { 0x8501, 0x0441, 0x2fd8 },
  { 0x0501, 0x0440, 0x0fd8 },
  { 0x0501, 0x0442, 0x0fd8 },
  { 0x8501, 0x0445, 0x2fd8 },
  { 0x0501, 0x0444, 0x0fd8 },
  { 0x0501, 0x0446, 0x0fd8 },
  { 0x8501, 0x044b, 0x3fd8 },
  { 0x8501, 0x0449, 0x2fd8 },
  { 0x0501, 0x0448, 0x0fd8 },
  { 0x0501, 0x044a, 0x0fd8 },
  { 0x8501, 0x044d, 0x2fd8 },
  { 0x0501, 0x044c, 0x0fd8 },
  { 0x0501, 0x044e, 0x0fd8 },
  { 0x8701, 0x0457, 0x4000 },
  { 0x8701, 0x0453, 0x3000 },
  { 0x8701, 0x0451, 0x2000 },
  { 0x0701, 0x0450, 0x0000 },
  { 0x0701, 0x0452, 0x0000 },
  { 0x8701, 0x0455, 0x2000 },
  { 0x0701, 0x0454, 0x0000 },
  { 0x0701, 0x0456, 0x0000 },
  { 0x8701, 0x045b, 0x3000 },
  { 0x8701, 0x0459, 0x2000 },
  { 0x0701, 0x0458, 0x0000 },
  { 0x0701, 0x045a, 0x0000 },
  { 0x8701, 0x045d, 0x2000 },
  { 0x0701, 0x045c, 0x0000 },
  { 0x0701, 0x045e, 0x0000 },
  { 0x9a01, 0xd000, 0x8000 },
  { 0x8d01, 0x04a1, 0x7000 },
  { 0x8701, 0x047f, 0x6000 },
  { 0x8701, 0x046f, 0x5000 },
  { 0x8701, 0x0467, 0x4000 },
  { 0x8701, 0x0463, 0x3000 },
  { 0x8701, 0x0461, 0x2000 },
  { 0x0701, 0x0460, 0x0000 },
  { 0x0701, 0x0462, 0x0000 },
  { 0x8701, 0x0465, 0x2000 },
  { 0x0701, 0x0464, 0x0000 },
  { 0x0701, 0x0466, 0x0000 },
  { 0x8701, 0x046b, 0x3000 },
  { 0x8701, 0x0469, 0x2000 },
  { 0x0701, 0x0468, 0x0000 },
  { 0x0701, 0x046a, 0x0000 },
  { 0x8701, 0x046d, 0x2000 },
  { 0x0701, 0x046c, 0x0000 },
  { 0x0701, 0x046e, 0x0000 },
  { 0x8701, 0x0477, 0x4000 },
  { 0x8701, 0x0473, 0x3000 },
  { 0x8701, 0x0471, 0x2000 },
  { 0x0701, 0x0470, 0x0000 },
  { 0x0701, 0x0472, 0x0000 },
  { 0x8701, 0x0475, 0x2000 },
  { 0x0701, 0x0474, 0x0000 },
  { 0x0701, 0x0476, 0x0000 },
  { 0x8701, 0x047b, 0x3000 },
  { 0x8701, 0x0479, 0x2000 },
  { 0x0701, 0x0478, 0x0000 },
  { 0x0701, 0x047a, 0x0000 },
  { 0x8701, 0x047d, 0x2000 },
  { 0x0701, 0x047c, 0x0000 },
  { 0x0701, 0x047e, 0x0000 },
  { 0x8701, 0x048f, 0x5000 },
  { 0x8701, 0x0487, 0x4000 },
  { 0x8701, 0x0483, 0x3000 },
  { 0x8701, 0x0481, 0x2000 },
  { 0x0701, 0x0480, 0x0000 },
  { 0x0701, 0x0482, 0x0000 },
  { 0x8701, 0x0485, 0x2000 },
  { 0x0701, 0x0484, 0x0000 },
  { 0x0701, 0x0486, 0x0000 },
  { 0x8701, 0x048b, 0x3000 },
  { 0x8701, 0x0489, 0x2000 },
  { 0x0701, 0x0488, 0x0000 },
  { 0x0701, 0x048a, 0x0000 },
  { 0x8701, 0x048d, 0x2000 },
  { 0x0701, 0x048c, 0x0000 },
  { 0x0701, 0x048e, 0x0000 },
  { 0x8701, 0x0497, 0x4000 },
  { 0x8701, 0x0493, 0x3000 },
  { 0x8701, 0x0491, 0x2000 },
  { 0x0701, 0x0490, 0x0000 },
  { 0x0701, 0x0492, 0x0000 },
  { 0x8701, 0x0495, 0x2000 },
  { 0x0701, 0x0494, 0x0000 },
  { 0x0701, 0x0496, 0x0000 },
  { 0x8701, 0x049b, 0x3000 },
  { 0x8701, 0x0499, 0x2000 },
  { 0x0701, 0x0498, 0x0000 },
  { 0x0701, 0x049a, 0x0000 },
  { 0x8701, 0x049d, 0x2000 },
  { 0x0701, 0x049c, 0x0000 },
  { 0x0d01, 0x04a0, 0x0000 },
  { 0x8701, 0x081a, 0x6000 },
  { 0x8701, 0x080a, 0x5000 },
  { 0x8d01, 0x04a9, 0x4000 },
  { 0x8d01, 0x04a5, 0x3000 },
  { 0x8d01, 0x04a3, 0x2000 },
  { 0x0d01, 0x04a2, 0x0000 },
  { 0x0d01, 0x04a4, 0x0000 },
  { 0x8d01, 0x04a7, 0x2000 },
  { 0x0d01, 0x04a6, 0x0000 },
  { 0x0d01, 0x04a8, 0x0000 },
  { 0x8701, 0x0803, 0x3000 },
  { 0x8701, 0x0801, 0x2000 },
  { 0x0701, 0x0800, 0x0000 },
  { 0x0701, 0x0802, 0x0000 },
  { 0x8701, 0x0805, 0x2000 },
  { 0x0701, 0x0804, 0x0000 },
  { 0x0701, 0x0808, 0x0000 },
  { 0x8701, 0x0812, 0x4000 },
  { 0x8701, 0x080e, 0x3000 },
  { 0x8701, 0x080c, 0x2000 },
  { 0x0701, 0x080b, 0x0000 },
  { 0x0701, 0x080d, 0x0000 },
  { 0x8701, 0x0810, 0x2000 },
  { 0x0701, 0x080f, 0x0000 },
  { 0x0701, 0x0811, 0x0000 },
  { 0x8701, 0x0816, 0x3000 },
  { 0x8701, 0x0814, 0x2000 },
  { 0x0701, 0x0813, 0x0000 },
  { 0x0701, 0x0815, 0x0000 },
  { 0x8701, 0x0818, 0x2000 },
  { 0x0701, 0x0817, 0x0000 },
  { 0x0701, 0x0819, 0x0000 },
  { 0x8701, 0x082a, 0x5000 },
  { 0x8701, 0x0822, 0x4000 },
  { 0x8701, 0x081e, 0x3000 },
  { 0x8701, 0x081c, 0x2000 },
  { 0x0701, 0x081b, 0x0000 },
  { 0x0701, 0x081d, 0x0000 },
  { 0x8701, 0x0820, 0x2000 },
  { 0x0701, 0x081f, 0x0000 },
  { 0x0701, 0x0821, 0x0000 },
  { 0x8701, 0x0826, 0x3000 },
  { 0x8701, 0x0824, 0x2000 },
  { 0x0701, 0x0823, 0x0000 },
  { 0x0701, 0x0825, 0x0000 },
  { 0x8701, 0x0828, 0x2000 },
  { 0x0701, 0x0827, 0x0000 },
  { 0x0701, 0x0829, 0x0000 },
  { 0x8701, 0x0832, 0x4000 },
  { 0x8701, 0x082e, 0x3000 },
  { 0x8701, 0x082c, 0x2000 },
  { 0x0701, 0x082b, 0x0000 },
  { 0x0701, 0x082d, 0x0000 },
  { 0x8701, 0x0830, 0x2000 },
  { 0x0701, 0x082f, 0x0000 },
  { 0x0701, 0x0831, 0x0000 },
  { 0x8701, 0x0837, 0x3000 },
  { 0x8701, 0x0834, 0x2000 },
  { 0x0701, 0x0833, 0x0000 },
  { 0x0701, 0x0835, 0x0000 },
  { 0x8701, 0x083c, 0x2000 },
  { 0x0701, 0x0838, 0x0000 },
  { 0x0701, 0x083f, 0x0000 },
  { 0x9a01, 0xd040, 0x7000 },
  { 0x9a01, 0xd020, 0x6000 },
  { 0x9a01, 0xd010, 0x5000 },
  { 0x9a01, 0xd008, 0x4000 },
  { 0x9a01, 0xd004, 0x3000 },
  { 0x9a01, 0xd002, 0x2000 },
  { 0x1a01, 0xd001, 0x0000 },
  { 0x1a01, 0xd003, 0x0000 },
  { 0x9a01, 0xd006, 0x2000 },
  { 0x1a01, 0xd005, 0x0000 },
  { 0x1a01, 0xd007, 0x0000 },
  { 0x9a01, 0xd00c, 0x3000 },
  { 0x9a01, 0xd00a, 0x2000 },
  { 0x1a01, 0xd009, 0x0000 },
  { 0x1a01, 0xd00b, 0x0000 },
  { 0x9a01, 0xd00e, 0x2000 },
  { 0x1a01, 0xd00d, 0x0000 },
  { 0x1a01, 0xd00f, 0x0000 },
  { 0x9a01, 0xd018, 0x4000 },
  { 0x9a01, 0xd014, 0x3000 },
  { 0x9a01, 0xd012, 0x2000 },
  { 0x1a01, 0xd011, 0x0000 },
  { 0x1a01, 0xd013, 0x0000 },
  { 0x9a01, 0xd016, 0x2000 },
  { 0x1a01, 0xd015, 0x0000 },
  { 0x1a01, 0xd017, 0x0000 },
  { 0x9a01, 0xd01c, 0x3000 },
  { 0x9a01, 0xd01a, 0x2000 },
  { 0x1a01, 0xd019, 0x0000 },
  { 0x1a01, 0xd01b, 0x0000 },
  { 0x9a01, 0xd01e, 0x2000 },
  { 0x1a01, 0xd01d, 0x0000 },
  { 0x1a01, 0xd01f, 0x0000 },
  { 0x9a01, 0xd030, 0x5000 },
  { 0x9a01, 0xd028, 0x4000 },
  { 0x9a01, 0xd024, 0x3000 },
  { 0x9a01, 0xd022, 0x2000 },
  { 0x1a01, 0xd021, 0x0000 },
  { 0x1a01, 0xd023, 0x0000 },
  { 0x9a01, 0xd026, 0x2000 },
  { 0x1a01, 0xd025, 0x0000 },
  { 0x1a01, 0xd027, 0x0000 },
  { 0x9a01, 0xd02c, 0x3000 },
  { 0x9a01, 0xd02a, 0x2000 },
  { 0x1a01, 0xd029, 0x0000 },
  { 0x1a01, 0xd02b, 0x0000 },
  { 0x9a01, 0xd02e, 0x2000 },
  { 0x1a01, 0xd02d, 0x0000 },
  { 0x1a01, 0xd02f, 0x0000 },
  { 0x9a01, 0xd038, 0x4000 },
  { 0x9a01, 0xd034, 0x3000 },
  { 0x9a01, 0xd032, 0x2000 },
  { 0x1a01, 0xd031, 0x0000 },
  { 0x1a01, 0xd033, 0x0000 },
  { 0x9a01, 0xd036, 0x2000 },
  { 0x1a01, 0xd035, 0x0000 },
  { 0x1a01, 0xd037, 0x0000 },
  { 0x9a01, 0xd03c, 0x3000 },
  { 0x9a01, 0xd03a, 0x2000 },
  { 0x1a01, 0xd039, 0x0000 },
  { 0x1a01, 0xd03b, 0x0000 },
  { 0x9a01, 0xd03e, 0x2000 },
  { 0x1a01, 0xd03d, 0x0000 },
  { 0x1a01, 0xd03f, 0x0000 },
  { 0x9a01, 0xd060, 0x6000 },
  { 0x9a01, 0xd050, 0x5000 },
  { 0x9a01, 0xd048, 0x4000 },
  { 0x9a01, 0xd044, 0x3000 },
  { 0x9a01, 0xd042, 0x2000 },
  { 0x1a01, 0xd041, 0x0000 },
  { 0x1a01, 0xd043, 0x0000 },
  { 0x9a01, 0xd046, 0x2000 },
  { 0x1a01, 0xd045, 0x0000 },
  { 0x1a01, 0xd047, 0x0000 },
  { 0x9a01, 0xd04c, 0x3000 },
  { 0x9a01, 0xd04a, 0x2000 },
  { 0x1a01, 0xd049, 0x0000 },
  { 0x1a01, 0xd04b, 0x0000 },
  { 0x9a01, 0xd04e, 0x2000 },
  { 0x1a01, 0xd04d, 0x0000 },
  { 0x1a01, 0xd04f, 0x0000 },
  { 0x9a01, 0xd058, 0x4000 },
  { 0x9a01, 0xd054, 0x3000 },
  { 0x9a01, 0xd052, 0x2000 },
  { 0x1a01, 0xd051, 0x0000 },
  { 0x1a01, 0xd053, 0x0000 },
  { 0x9a01, 0xd056, 0x2000 },
  { 0x1a01, 0xd055, 0x0000 },
  { 0x1a01, 0xd057, 0x0000 },
  { 0x9a01, 0xd05c, 0x3000 },
  { 0x9a01, 0xd05a, 0x2000 },
  { 0x1a01, 0xd059, 0x0000 },
  { 0x1a01, 0xd05b, 0x0000 },
  { 0x9a01, 0xd05e, 0x2000 },
  { 0x1a01, 0xd05d, 0x0000 },
  { 0x1a01, 0xd05f, 0x0000 },
  { 0x9a01, 0xd070, 0x5000 },
  { 0x9a01, 0xd068, 0x4000 },
  { 0x9a01, 0xd064, 0x3000 },
  { 0x9a01, 0xd062, 0x2000 },
  { 0x1a01, 0xd061, 0x0000 },
  { 0x1a01, 0xd063, 0x0000 },
  { 0x9a01, 0xd066, 0x2000 },
  { 0x1a01, 0xd065, 0x0000 },
  { 0x1a01, 0xd067, 0x0000 },
  { 0x9a01, 0xd06c, 0x3000 },
  { 0x9a01, 0xd06a, 0x2000 },
  { 0x1a01, 0xd069, 0x0000 },
  { 0x1a01, 0xd06b, 0x0000 },
  { 0x9a01, 0xd06e, 0x2000 },
  { 0x1a01, 0xd06d, 0x0000 },
  { 0x1a01, 0xd06f, 0x0000 },
  { 0x9a01, 0xd078, 0x4000 },
  { 0x9a01, 0xd074, 0x3000 },
  { 0x9a01, 0xd072, 0x2000 },
  { 0x1a01, 0xd071, 0x0000 },
  { 0x1a01, 0xd073, 0x0000 },
  { 0x9a01, 0xd076, 0x2000 },
  { 0x1a01, 0xd075, 0x0000 },
  { 0x1a01, 0xd077, 0x0000 },
  { 0x9a01, 0xd07c, 0x3000 },
  { 0x9a01, 0xd07a, 0x2000 },
  { 0x1a01, 0xd079, 0x0000 },
  { 0x1a01, 0xd07b, 0x0000 },
  { 0x9a01, 0xd07e, 0x2000 },
  { 0x1a01, 0xd07d, 0x0000 },
  { 0x1a01, 0xd07f, 0x0000 },
  { 0x9a01, 0xd18d, 0x9000 },
  { 0x9a01, 0xd10a, 0x8000 },
  { 0x9a01, 0xd0c0, 0x7000 },
  { 0x9a01, 0xd0a0, 0x6000 },
  { 0x9a01, 0xd090, 0x5000 },
  { 0x9a01, 0xd088, 0x4000 },
  { 0x9a01, 0xd084, 0x3000 },
  { 0x9a01, 0xd082, 0x2000 },
  { 0x1a01, 0xd081, 0x0000 },
  { 0x1a01, 0xd083, 0x0000 },
  { 0x9a01, 0xd086, 0x2000 },
  { 0x1a01, 0xd085, 0x0000 },
  { 0x1a01, 0xd087, 0x0000 },
  { 0x9a01, 0xd08c, 0x3000 },
  { 0x9a01, 0xd08a, 0x2000 },
  { 0x1a01, 0xd089, 0x0000 },
  { 0x1a01, 0xd08b, 0x0000 },
  { 0x9a01, 0xd08e, 0x2000 },
  { 0x1a01, 0xd08d, 0x0000 },
  { 0x1a01, 0xd08f, 0x0000 },
  { 0x9a01, 0xd098, 0x4000 },
  { 0x9a01, 0xd094, 0x3000 },
  { 0x9a01, 0xd092, 0x2000 },
  { 0x1a01, 0xd091, 0x0000 },
  { 0x1a01, 0xd093, 0x0000 },
  { 0x9a01, 0xd096, 0x2000 },
  { 0x1a01, 0xd095, 0x0000 },
  { 0x1a01, 0xd097, 0x0000 },
  { 0x9a01, 0xd09c, 0x3000 },
  { 0x9a01, 0xd09a, 0x2000 },
  { 0x1a01, 0xd099, 0x0000 },
  { 0x1a01, 0xd09b, 0x0000 },
  { 0x9a01, 0xd09e, 0x2000 },
  { 0x1a01, 0xd09d, 0x0000 },
  { 0x1a01, 0xd09f, 0x0000 },
  { 0x9a01, 0xd0b0, 0x5000 },
  { 0x9a01, 0xd0a8, 0x4000 },
  { 0x9a01, 0xd0a4, 0x3000 },
  { 0x9a01, 0xd0a2, 0x2000 },
  { 0x1a01, 0xd0a1, 0x0000 },
  { 0x1a01, 0xd0a3, 0x0000 },
  { 0x9a01, 0xd0a6, 0x2000 },
  { 0x1a01, 0xd0a5, 0x0000 },
  { 0x1a01, 0xd0a7, 0x0000 },
  { 0x9a01, 0xd0ac, 0x3000 },
  { 0x9a01, 0xd0aa, 0x2000 },
  { 0x1a01, 0xd0a9, 0x0000 },
  { 0x1a01, 0xd0ab, 0x0000 },
  { 0x9a01, 0xd0ae, 0x2000 },
  { 0x1a01, 0xd0ad, 0x0000 },
  { 0x1a01, 0xd0af, 0x0000 },
  { 0x9a01, 0xd0b8, 0x4000 },
  { 0x9a01, 0xd0b4, 0x3000 },
  { 0x9a01, 0xd0b2, 0x2000 },
  { 0x1a01, 0xd0b1, 0x0000 },
  { 0x1a01, 0xd0b3, 0x0000 },
  { 0x9a01, 0xd0b6, 0x2000 },
  { 0x1a01, 0xd0b5, 0x0000 },
  { 0x1a01, 0xd0b7, 0x0000 },
  { 0x9a01, 0xd0bc, 0x3000 },
  { 0x9a01, 0xd0ba, 0x2000 },
  { 0x1a01, 0xd0b9, 0x0000 },
  { 0x1a01, 0xd0bb, 0x0000 },
  { 0x9a01, 0xd0be, 0x2000 },
  { 0x1a01, 0xd0bd, 0x0000 },
  { 0x1a01, 0xd0bf, 0x0000 },
  { 0x9a01, 0xd0e0, 0x6000 },
  { 0x9a01, 0xd0d0, 0x5000 },
  { 0x9a01, 0xd0c8, 0x4000 },
  { 0x9a01, 0xd0c4, 0x3000 },
  { 0x9a01, 0xd0c2, 0x2000 },
  { 0x1a01, 0xd0c1, 0x0000 },
  { 0x1a01, 0xd0c3, 0x0000 },
  { 0x9a01, 0xd0c6, 0x2000 },
  { 0x1a01, 0xd0c5, 0x0000 },
  { 0x1a01, 0xd0c7, 0x0000 },
  { 0x9a01, 0xd0cc, 0x3000 },
  { 0x9a01, 0xd0ca, 0x2000 },
  { 0x1a01, 0xd0c9, 0x0000 },
  { 0x1a01, 0xd0cb, 0x0000 },
  { 0x9a01, 0xd0ce, 0x2000 },
  { 0x1a01, 0xd0cd, 0x0000 },
  { 0x1a01, 0xd0cf, 0x0000 },
  { 0x9a01, 0xd0d8, 0x4000 },
  { 0x9a01, 0xd0d4, 0x3000 },
  { 0x9a01, 0xd0d2, 0x2000 },
  { 0x1a01, 0xd0d1, 0x0000 },
  { 0x1a01, 0xd0d3, 0x0000 },
  { 0x9a01, 0xd0d6, 0x2000 },
  { 0x1a01, 0xd0d5, 0x0000 },
  { 0x1a01, 0xd0d7, 0x0000 },
  { 0x9a01, 0xd0dc, 0x3000 },
  { 0x9a01, 0xd0da, 0x2000 },
  { 0x1a01, 0xd0d9, 0x0000 },
  { 0x1a01, 0xd0db, 0x0000 },
  { 0x9a01, 0xd0de, 0x2000 },
  { 0x1a01, 0xd0dd, 0x0000 },
  { 0x1a01, 0xd0df, 0x0000 },
  { 0x9a01, 0xd0f0, 0x5000 },
  { 0x9a01, 0xd0e8, 0x4000 },
  { 0x9a01, 0xd0e4, 0x3000 },
  { 0x9a01, 0xd0e2, 0x2000 },
  { 0x1a01, 0xd0e1, 0x0000 },
  { 0x1a01, 0xd0e3, 0x0000 },
  { 0x9a01, 0xd0e6, 0x2000 },
  { 0x1a01, 0xd0e5, 0x0000 },
  { 0x1a01, 0xd0e7, 0x0000 },
  { 0x9a01, 0xd0ec, 0x3000 },
  { 0x9a01, 0xd0ea, 0x2000 },
  { 0x1a01, 0xd0e9, 0x0000 },
  { 0x1a01, 0xd0eb, 0x0000 },
  { 0x9a01, 0xd0ee, 0x2000 },
  { 0x1a01, 0xd0ed, 0x0000 },
  { 0x1a01, 0xd0ef, 0x0000 },
  { 0x9a01, 0xd102, 0x4000 },
  { 0x9a01, 0xd0f4, 0x3000 },
  { 0x9a01, 0xd0f2, 0x2000 },
  { 0x1a01, 0xd0f1, 0x0000 },
  { 0x1a01, 0xd0f3, 0x0000 },
  { 0x9a01, 0xd100, 0x2000 },
  { 0x1a01, 0xd0f5, 0x0000 },
  { 0x1a01, 0xd101, 0x0000 },
  { 0x9a01, 0xd106, 0x3000 },
  { 0x9a01, 0xd104, 0x2000 },
  { 0x1a01, 0xd103, 0x0000 },
  { 0x1a01, 0xd105, 0x0000 },
  { 0x9a01, 0xd108, 0x2000 },
  { 0x1a01, 0xd107, 0x0000 },
  { 0x1a01, 0xd109, 0x0000 },
  { 0x9a01, 0xd14d, 0x7000 },
  { 0x9a01, 0xd12d, 0x6000 },
  { 0x9a01, 0xd11a, 0x5000 },
  { 0x9a01, 0xd112, 0x4000 },
  { 0x9a01, 0xd10e, 0x3000 },
  { 0x9a01, 0xd10c, 0x2000 },
  { 0x1a01, 0xd10b, 0x0000 },
  { 0x1a01, 0xd10d, 0x0000 },
  { 0x9a01, 0xd110, 0x2000 },
  { 0x1a01, 0xd10f, 0x0000 },
  { 0x1a01, 0xd111, 0x0000 },
  { 0x9a01, 0xd116, 0x3000 },
  { 0x9a01, 0xd114, 0x2000 },
  { 0x1a01, 0xd113, 0x0000 },
  { 0x1a01, 0xd115, 0x0000 },
  { 0x9a01, 0xd118, 0x2000 },
  { 0x1a01, 0xd117, 0x0000 },
  { 0x1a01, 0xd119, 0x0000 },
  { 0x9a01, 0xd122, 0x4000 },
  { 0x9a01, 0xd11e, 0x3000 },
  { 0x9a01, 0xd11c, 0x2000 },
  { 0x1a01, 0xd11b, 0x0000 },
  { 0x1a01, 0xd11d, 0x0000 },
  { 0x9a01, 0xd120, 0x2000 },
  { 0x1a01, 0xd11f, 0x0000 },
  { 0x1a01, 0xd121, 0x0000 },
  { 0x9a01, 0xd126, 0x3000 },
  { 0x9a01, 0xd124, 0x2000 },
  { 0x1a01, 0xd123, 0x0000 },
  { 0x1a01, 0xd125, 0x0000 },
  { 0x9a01, 0xd12b, 0x2000 },
  { 0x1a01, 0xd12a, 0x0000 },
  { 0x1a01, 0xd12c, 0x0000 },
  { 0x9a01, 0xd13d, 0x5000 },
  { 0x9a01, 0xd135, 0x4000 },
  { 0x9a01, 0xd131, 0x3000 },
  { 0x9a01, 0xd12f, 0x2000 },
  { 0x1a01, 0xd12e, 0x0000 },
  { 0x1a01, 0xd130, 0x0000 },
  { 0x9a01, 0xd133, 0x2000 },
  { 0x1a01, 0xd132, 0x0000 },
  { 0x1a01, 0xd134, 0x0000 },
  { 0x9a01, 0xd139, 0x3000 },
  { 0x9a01, 0xd137, 0x2000 },
  { 0x1a01, 0xd136, 0x0000 },
  { 0x1a01, 0xd138, 0x0000 },
  { 0x9a01, 0xd13b, 0x2000 },
  { 0x1a01, 0xd13a, 0x0000 },
  { 0x1a01, 0xd13c, 0x0000 },
  { 0x9a01, 0xd145, 0x4000 },
  { 0x9a01, 0xd141, 0x3000 },
  { 0x9a01, 0xd13f, 0x2000 },
  { 0x1a01, 0xd13e, 0x0000 },
  { 0x1a01, 0xd140, 0x0000 },
  { 0x9a01, 0xd143, 0x2000 },
  { 0x1a01, 0xd142, 0x0000 },
  { 0x1a01, 0xd144, 0x0000 },
  { 0x9a01, 0xd149, 0x3000 },
  { 0x9a01, 0xd147, 0x2000 },
  { 0x1a01, 0xd146, 0x0000 },
  { 0x1a01, 0xd148, 0x0000 },
  { 0x9a01, 0xd14b, 0x2000 },
  { 0x1a01, 0xd14a, 0x0000 },
  { 0x1a01, 0xd14c, 0x0000 },
  { 0x8a01, 0xd16d, 0x6000 },
  { 0x9a01, 0xd15d, 0x5000 },
  { 0x9a01, 0xd155, 0x4000 },
  { 0x9a01, 0xd151, 0x3000 },
  { 0x9a01, 0xd14f, 0x2000 },
  { 0x1a01, 0xd14e, 0x0000 },
  { 0x1a01, 0xd150, 0x0000 },
  { 0x9a01, 0xd153, 0x2000 },
  { 0x1a01, 0xd152, 0x0000 },
  { 0x1a01, 0xd154, 0x0000 },
  { 0x9a01, 0xd159, 0x3000 },
  { 0x9a01, 0xd157, 0x2000 },
  { 0x1a01, 0xd156, 0x0000 },
  { 0x1a01, 0xd158, 0x0000 },
  { 0x9a01, 0xd15b, 0x2000 },
  { 0x1a01, 0xd15a, 0x0000 },
  { 0x1a01, 0xd15c, 0x0000 },
  { 0x8a01, 0xd165, 0x4000 },
  { 0x9a01, 0xd161, 0x3000 },
  { 0x9a01, 0xd15f, 0x2000 },
  { 0x1a01, 0xd15e, 0x0000 },
  { 0x1a01, 0xd160, 0x0000 },
  { 0x9a01, 0xd163, 0x2000 },
  { 0x1a01, 0xd162, 0x0000 },
  { 0x1a01, 0xd164, 0x0000 },
  { 0x8c01, 0xd169, 0x3000 },
  { 0x8c01, 0xd167, 0x2000 },
  { 0x0a01, 0xd166, 0x0000 },
  { 0x0c01, 0xd168, 0x0000 },
  { 0x9a01, 0xd16b, 0x2000 },
  { 0x1a01, 0xd16a, 0x0000 },
  { 0x1a01, 0xd16c, 0x0000 },
  { 0x8c01, 0xd17d, 0x5000 },
  { 0x8101, 0xd175, 0x4000 },
  { 0x8a01, 0xd171, 0x3000 },
  { 0x8a01, 0xd16f, 0x2000 },
  { 0x0a01, 0xd16e, 0x0000 },
  { 0x0a01, 0xd170, 0x0000 },
  { 0x8101, 0xd173, 0x2000 },
  { 0x0a01, 0xd172, 0x0000 },
  { 0x0101, 0xd174, 0x0000 },
  { 0x8101, 0xd179, 0x3000 },
  { 0x8101, 0xd177, 0x2000 },
  { 0x0101, 0xd176, 0x0000 },
  { 0x0101, 0xd178, 0x0000 },
  { 0x8c01, 0xd17b, 0x2000 },
  { 0x0101, 0xd17a, 0x0000 },
  { 0x0c01, 0xd17c, 0x0000 },
  { 0x8c01, 0xd185, 0x4000 },
  { 0x8c01, 0xd181, 0x3000 },
  { 0x8c01, 0xd17f, 0x2000 },
  { 0x0c01, 0xd17e, 0x0000 },
  { 0x0c01, 0xd180, 0x0000 },
  { 0x9a01, 0xd183, 0x2000 },
  { 0x0c01, 0xd182, 0x0000 },
  { 0x1a01, 0xd184, 0x0000 },
  { 0x8c01, 0xd189, 0x3000 },
  { 0x8c01, 0xd187, 0x2000 },
  { 0x0c01, 0xd186, 0x0000 },
  { 0x0c01, 0xd188, 0x0000 },
  { 0x8c01, 0xd18b, 0x2000 },
  { 0x0c01, 0xd18a, 0x0000 },
  { 0x1a01, 0xd18c, 0x0000 },
  { 0x9a01, 0xd32f, 0x8000 },
  { 0x9a01, 0xd1cd, 0x7000 },
  { 0x8c01, 0xd1ad, 0x6000 },
  { 0x9a01, 0xd19d, 0x5000 },
  { 0x9a01, 0xd195, 0x4000 },
  { 0x9a01, 0xd191, 0x3000 },
  { 0x9a01, 0xd18f, 0x2000 },
  { 0x1a01, 0xd18e, 0x0000 },
  { 0x1a01, 0xd190, 0x0000 },
  { 0x9a01, 0xd193, 0x2000 },
  { 0x1a01, 0xd192, 0x0000 },
  { 0x1a01, 0xd194, 0x0000 },
  { 0x9a01, 0xd199, 0x3000 },
  { 0x9a01, 0xd197, 0x2000 },
  { 0x1a01, 0xd196, 0x0000 },
  { 0x1a01, 0xd198, 0x0000 },
  { 0x9a01, 0xd19b, 0x2000 },
  { 0x1a01, 0xd19a, 0x0000 },
  { 0x1a01, 0xd19c, 0x0000 },
  { 0x9a01, 0xd1a5, 0x4000 },
  { 0x9a01, 0xd1a1, 0x3000 },
  { 0x9a01, 0xd19f, 0x2000 },
  { 0x1a01, 0xd19e, 0x0000 },
  { 0x1a01, 0xd1a0, 0x0000 },
  { 0x9a01, 0xd1a3, 0x2000 },
  { 0x1a01, 0xd1a2, 0x0000 },
  { 0x1a01, 0xd1a4, 0x0000 },
  { 0x9a01, 0xd1a9, 0x3000 },
  { 0x9a01, 0xd1a7, 0x2000 },
  { 0x1a01, 0xd1a6, 0x0000 },
  { 0x1a01, 0xd1a8, 0x0000 },
  { 0x8c01, 0xd1ab, 0x2000 },
  { 0x0c01, 0xd1aa, 0x0000 },
  { 0x0c01, 0xd1ac, 0x0000 },
  { 0x9a01, 0xd1bd, 0x5000 },
  { 0x9a01, 0xd1b5, 0x4000 },
  { 0x9a01, 0xd1b1, 0x3000 },
  { 0x9a01, 0xd1af, 0x2000 },
  { 0x1a01, 0xd1ae, 0x0000 },
  { 0x1a01, 0xd1b0, 0x0000 },
  { 0x9a01, 0xd1b3, 0x2000 },
  { 0x1a01, 0xd1b2, 0x0000 },
  { 0x1a01, 0xd1b4, 0x0000 },
  { 0x9a01, 0xd1b9, 0x3000 },
  { 0x9a01, 0xd1b7, 0x2000 },
  { 0x1a01, 0xd1b6, 0x0000 },
  { 0x1a01, 0xd1b8, 0x0000 },
  { 0x9a01, 0xd1bb, 0x2000 },
  { 0x1a01, 0xd1ba, 0x0000 },
  { 0x1a01, 0xd1bc, 0x0000 },
  { 0x9a01, 0xd1c5, 0x4000 },
  { 0x9a01, 0xd1c1, 0x3000 },
  { 0x9a01, 0xd1bf, 0x2000 },
  { 0x1a01, 0xd1be, 0x0000 },
  { 0x1a01, 0xd1c0, 0x0000 },
  { 0x9a01, 0xd1c3, 0x2000 },
  { 0x1a01, 0xd1c2, 0x0000 },
  { 0x1a01, 0xd1c4, 0x0000 },
  { 0x9a01, 0xd1c9, 0x3000 },
  { 0x9a01, 0xd1c7, 0x2000 },
  { 0x1a01, 0xd1c6, 0x0000 },
  { 0x1a01, 0xd1c8, 0x0000 },
  { 0x9a01, 0xd1cb, 0x2000 },
  { 0x1a01, 0xd1ca, 0x0000 },
  { 0x1a01, 0xd1cc, 0x0000 },
  { 0x9a01, 0xd30f, 0x6000 },
  { 0x9a01, 0xd1dd, 0x5000 },
  { 0x9a01, 0xd1d5, 0x4000 },
  { 0x9a01, 0xd1d1, 0x3000 },
  { 0x9a01, 0xd1cf, 0x2000 },
  { 0x1a01, 0xd1ce, 0x0000 },
  { 0x1a01, 0xd1d0, 0x0000 },
  { 0x9a01, 0xd1d3, 0x2000 },
  { 0x1a01, 0xd1d2, 0x0000 },
  { 0x1a01, 0xd1d4, 0x0000 },
  { 0x9a01, 0xd1d9, 0x3000 },
  { 0x9a01, 0xd1d7, 0x2000 },
  { 0x1a01, 0xd1d6, 0x0000 },
  { 0x1a01, 0xd1d8, 0x0000 },
  { 0x9a01, 0xd1db, 0x2000 },
  { 0x1a01, 0xd1da, 0x0000 },
  { 0x1a01, 0xd1dc, 0x0000 },
  { 0x9a01, 0xd307, 0x4000 },
  { 0x9a01, 0xd303, 0x3000 },
  { 0x9a01, 0xd301, 0x2000 },
  { 0x1a01, 0xd300, 0x0000 },
  { 0x1a01, 0xd302, 0x0000 },
  { 0x9a01, 0xd305, 0x2000 },
  { 0x1a01, 0xd304, 0x0000 },
  { 0x1a01, 0xd306, 0x0000 },
  { 0x9a01, 0xd30b, 0x3000 },
  { 0x9a01, 0xd309, 0x2000 },
  { 0x1a01, 0xd308, 0x0000 },
  { 0x1a01, 0xd30a, 0x0000 },
  { 0x9a01, 0xd30d, 0x2000 },
  { 0x1a01, 0xd30c, 0x0000 },
  { 0x1a01, 0xd30e, 0x0000 },
  { 0x9a01, 0xd31f, 0x5000 },
  { 0x9a01, 0xd317, 0x4000 },
  { 0x9a01, 0xd313, 0x3000 },
  { 0x9a01, 0xd311, 0x2000 },
  { 0x1a01, 0xd310, 0x0000 },
  { 0x1a01, 0xd312, 0x0000 },
  { 0x9a01, 0xd315, 0x2000 },
  { 0x1a01, 0xd314, 0x0000 },
  { 0x1a01, 0xd316, 0x0000 },
  { 0x9a01, 0xd31b, 0x3000 },
  { 0x9a01, 0xd319, 0x2000 },
  { 0x1a01, 0xd318, 0x0000 },
  { 0x1a01, 0xd31a, 0x0000 },
  { 0x9a01, 0xd31d, 0x2000 },
  { 0x1a01, 0xd31c, 0x0000 },
  { 0x1a01, 0xd31e, 0x0000 },
  { 0x9a01, 0xd327, 0x4000 },
  { 0x9a01, 0xd323, 0x3000 },
  { 0x9a01, 0xd321, 0x2000 },
  { 0x1a01, 0xd320, 0x0000 },
  { 0x1a01, 0xd322, 0x0000 },
  { 0x9a01, 0xd325, 0x2000 },
  { 0x1a01, 0xd324, 0x0000 },
  { 0x1a01, 0xd326, 0x0000 },
  { 0x9a01, 0xd32b, 0x3000 },
  { 0x9a01, 0xd329, 0x2000 },
  { 0x1a01, 0xd328, 0x0000 },
  { 0x1a01, 0xd32a, 0x0000 },
  { 0x9a01, 0xd32d, 0x2000 },
  { 0x1a01, 0xd32c, 0x0000 },
  { 0x1a01, 0xd32e, 0x0000 },
  { 0x8901, 0xd418, 0x7000 },
  { 0x9a01, 0xd34f, 0x6000 },
  { 0x9a01, 0xd33f, 0x5000 },
  { 0x9a01, 0xd337, 0x4000 },
  { 0x9a01, 0xd333, 0x3000 },
  { 0x9a01, 0xd331, 0x2000 },
  { 0x1a01, 0xd330, 0x0000 },
  { 0x1a01, 0xd332, 0x0000 },
  { 0x9a01, 0xd335, 0x2000 },
  { 0x1a01, 0xd334, 0x0000 },
  { 0x1a01, 0xd336, 0x0000 },
  { 0x9a01, 0xd33b, 0x3000 },
  { 0x9a01, 0xd339, 0x2000 },
  { 0x1a01, 0xd338, 0x0000 },
  { 0x1a01, 0xd33a, 0x0000 },
  { 0x9a01, 0xd33d, 0x2000 },
  { 0x1a01, 0xd33c, 0x0000 },
  { 0x1a01, 0xd33e, 0x0000 },
  { 0x9a01, 0xd347, 0x4000 },
  { 0x9a01, 0xd343, 0x3000 },
  { 0x9a01, 0xd341, 0x2000 },
  { 0x1a01, 0xd340, 0x0000 },
  { 0x1a01, 0xd342, 0x0000 },
  { 0x9a01, 0xd345, 0x2000 },
  { 0x1a01, 0xd344, 0x0000 },
  { 0x1a01, 0xd346, 0x0000 },
  { 0x9a01, 0xd34b, 0x3000 },
  { 0x9a01, 0xd349, 0x2000 },
  { 0x1a01, 0xd348, 0x0000 },
  { 0x1a01, 0xd34a, 0x0000 },
  { 0x9a01, 0xd34d, 0x2000 },
  { 0x1a01, 0xd34c, 0x0000 },
  { 0x1a01, 0xd34e, 0x0000 },
  { 0x8901, 0xd408, 0x5000 },
  { 0x8901, 0xd400, 0x4000 },
  { 0x9a01, 0xd353, 0x3000 },
  { 0x9a01, 0xd351, 0x2000 },
  { 0x1a01, 0xd350, 0x0000 },
  { 0x1a01, 0xd352, 0x0000 },
  { 0x9a01, 0xd355, 0x2000 },
  { 0x1a01, 0xd354, 0x0000 },
  { 0x1a01, 0xd356, 0x0000 },
  { 0x8901, 0xd404, 0x3000 },
  { 0x8901, 0xd402, 0x2000 },
  { 0x0901, 0xd401, 0x0000 },
  { 0x0901, 0xd403, 0x0000 },
  { 0x8901, 0xd406, 0x2000 },
  { 0x0901, 0xd405, 0x0000 },
  { 0x0901, 0xd407, 0x0000 },
  { 0x8901, 0xd410, 0x4000 },
  { 0x8901, 0xd40c, 0x3000 },
  { 0x8901, 0xd40a, 0x2000 },
  { 0x0901, 0xd409, 0x0000 },
  { 0x0901, 0xd40b, 0x0000 },
  { 0x8901, 0xd40e, 0x2000 },
  { 0x0901, 0xd40d, 0x0000 },
  { 0x0901, 0xd40f, 0x0000 },
  { 0x8901, 0xd414, 0x3000 },
  { 0x8901, 0xd412, 0x2000 },
  { 0x0901, 0xd411, 0x0000 },
  { 0x0901, 0xd413, 0x0000 },
  { 0x8901, 0xd416, 0x2000 },
  { 0x0901, 0xd415, 0x0000 },
  { 0x0901, 0xd417, 0x0000 },
  { 0x8901, 0xd438, 0x6000 },
  { 0x8501, 0xd428, 0x5000 },
  { 0x8501, 0xd420, 0x4000 },
  { 0x8501, 0xd41c, 0x3000 },
  { 0x8501, 0xd41a, 0x2000 },
  { 0x0901, 0xd419, 0x0000 },
  { 0x0501, 0xd41b, 0x0000 },
  { 0x8501, 0xd41e, 0x2000 },
  { 0x0501, 0xd41d, 0x0000 },
  { 0x0501, 0xd41f, 0x0000 },
  { 0x8501, 0xd424, 0x3000 },
  { 0x8501, 0xd422, 0x2000 },
  { 0x0501, 0xd421, 0x0000 },
  { 0x0501, 0xd423, 0x0000 },
  { 0x8501, 0xd426, 0x2000 },
  { 0x0501, 0xd425, 0x0000 },
  { 0x0501, 0xd427, 0x0000 },
  { 0x8501, 0xd430, 0x4000 },
  { 0x8501, 0xd42c, 0x3000 },
  { 0x8501, 0xd42a, 0x2000 },
  { 0x0501, 0xd429, 0x0000 },
  { 0x0501, 0xd42b, 0x0000 },
  { 0x8501, 0xd42e, 0x2000 },
  { 0x0501, 0xd42d, 0x0000 },
  { 0x0501, 0xd42f, 0x0000 },
  { 0x8901, 0xd434, 0x3000 },
  { 0x8501, 0xd432, 0x2000 },
  { 0x0501, 0xd431, 0x0000 },
  { 0x0501, 0xd433, 0x0000 },
  { 0x8901, 0xd436, 0x2000 },
  { 0x0901, 0xd435, 0x0000 },
  { 0x0901, 0xd437, 0x0000 },
  { 0x8901, 0xd448, 0x5000 },
  { 0x8901, 0xd440, 0x4000 },
  { 0x8901, 0xd43c, 0x3000 },
  { 0x8901, 0xd43a, 0x2000 },
  { 0x0901, 0xd439, 0x0000 },
  { 0x0901, 0xd43b, 0x0000 },
  { 0x8901, 0xd43e, 0x2000 },
  { 0x0901, 0xd43d, 0x0000 },
  { 0x0901, 0xd43f, 0x0000 },
  { 0x8901, 0xd444, 0x3000 },
  { 0x8901, 0xd442, 0x2000 },
  { 0x0901, 0xd441, 0x0000 },
  { 0x0901, 0xd443, 0x0000 },
  { 0x8901, 0xd446, 0x2000 },
  { 0x0901, 0xd445, 0x0000 },
  { 0x0901, 0xd447, 0x0000 },
  { 0x8501, 0xd450, 0x4000 },
  { 0x8901, 0xd44c, 0x3000 },
  { 0x8901, 0xd44a, 0x2000 },
  { 0x0901, 0xd449, 0x0000 },
  { 0x0901, 0xd44b, 0x0000 },
  { 0x8501, 0xd44e, 0x2000 },
  { 0x0901, 0xd44d, 0x0000 },
  { 0x0501, 0xd44f, 0x0000 },
  { 0x8501, 0xd454, 0x3000 },
  { 0x8501, 0xd452, 0x2000 },
  { 0x0501, 0xd451, 0x0000 },
  { 0x0501, 0xd453, 0x0000 },
  { 0x8501, 0xd457, 0x2000 },
  { 0x0501, 0xd456, 0x0000 },
  { 0x0501, 0xd458, 0x0000 },
  { 0x8702, 0xf876, 0xb000 },
  { 0x8901, 0xd670, 0xa000 },
  { 0x8901, 0xd570, 0x9000 },
  { 0x8901, 0xd4e4, 0x8000 },
  { 0x8501, 0xd499, 0x7000 },
  { 0x8901, 0xd479, 0x6000 },
  { 0x8901, 0xd469, 0x5000 },
  { 0x8501, 0xd461, 0x4000 },
  { 0x8501, 0xd45d, 0x3000 },
  { 0x8501, 0xd45b, 0x2000 },
  { 0x0501, 0xd45a, 0x0000 },
  { 0x0501, 0xd45c, 0x0000 },
  { 0x8501, 0xd45f, 0x2000 },
  { 0x0501, 0xd45e, 0x0000 },
  { 0x0501, 0xd460, 0x0000 },
  { 0x8501, 0xd465, 0x3000 },
  { 0x8501, 0xd463, 0x2000 },
  { 0x0501, 0xd462, 0x0000 },
  { 0x0501, 0xd464, 0x0000 },
  { 0x8501, 0xd467, 0x2000 },
  { 0x0501, 0xd466, 0x0000 },
  { 0x0901, 0xd468, 0x0000 },
  { 0x8901, 0xd471, 0x4000 },
  { 0x8901, 0xd46d, 0x3000 },
  { 0x8901, 0xd46b, 0x2000 },
  { 0x0901, 0xd46a, 0x0000 },
  { 0x0901, 0xd46c, 0x0000 },
  { 0x8901, 0xd46f, 0x2000 },
  { 0x0901, 0xd46e, 0x0000 },
  { 0x0901, 0xd470, 0x0000 },
  { 0x8901, 0xd475, 0x3000 },
  { 0x8901, 0xd473, 0x2000 },
  { 0x0901, 0xd472, 0x0000 },
  { 0x0901, 0xd474, 0x0000 },
  { 0x8901, 0xd477, 0x2000 },
  { 0x0901, 0xd476, 0x0000 },
  { 0x0901, 0xd478, 0x0000 },
  { 0x8501, 0xd489, 0x5000 },
  { 0x8901, 0xd481, 0x4000 },
  { 0x8901, 0xd47d, 0x3000 },
  { 0x8901, 0xd47b, 0x2000 },
  { 0x0901, 0xd47a, 0x0000 },
  { 0x0901, 0xd47c, 0x0000 },
  { 0x8901, 0xd47f, 0x2000 },
  { 0x0901, 0xd47e, 0x0000 },
  { 0x0901, 0xd480, 0x0000 },
  { 0x8501, 0xd485, 0x3000 },
  { 0x8501, 0xd483, 0x2000 },
  { 0x0501, 0xd482, 0x0000 },
  { 0x0501, 0xd484, 0x0000 },
  { 0x8501, 0xd487, 0x2000 },
  { 0x0501, 0xd486, 0x0000 },
  { 0x0501, 0xd488, 0x0000 },
  { 0x8501, 0xd491, 0x4000 },
  { 0x8501, 0xd48d, 0x3000 },
  { 0x8501, 0xd48b, 0x2000 },
  { 0x0501, 0xd48a, 0x0000 },
  { 0x0501, 0xd48c, 0x0000 },
  { 0x8501, 0xd48f, 0x2000 },
  { 0x0501, 0xd48e, 0x0000 },
  { 0x0501, 0xd490, 0x0000 },
  { 0x8501, 0xd495, 0x3000 },
  { 0x8501, 0xd493, 0x2000 },
  { 0x0501, 0xd492, 0x0000 },
  { 0x0501, 0xd494, 0x0000 },
  { 0x8501, 0xd497, 0x2000 },
  { 0x0501, 0xd496, 0x0000 },
  { 0x0501, 0xd498, 0x0000 },
  { 0x8501, 0xd4c3, 0x6000 },
  { 0x8901, 0xd4b1, 0x5000 },
  { 0x8901, 0xd4a6, 0x4000 },
  { 0x8901, 0xd49e, 0x3000 },
  { 0x8501, 0xd49b, 0x2000 },
  { 0x0501, 0xd49a, 0x0000 },
  { 0x0901, 0xd49c, 0x0000 },
  { 0x8901, 0xd4a2, 0x2000 },
  { 0x0901, 0xd49f, 0x0000 },
  { 0x0901, 0xd4a5, 0x0000 },
  { 0x8901, 0xd4ac, 0x3000 },
  { 0x8901, 0xd4aa, 0x2000 },
  { 0x0901, 0xd4a9, 0x0000 },
  { 0x0901, 0xd4ab, 0x0000 },
  { 0x8901, 0xd4af, 0x2000 },
  { 0x0901, 0xd4ae, 0x0000 },
  { 0x0901, 0xd4b0, 0x0000 },
  { 0x8501, 0xd4b9, 0x4000 },
  { 0x8901, 0xd4b5, 0x3000 },
  { 0x8901, 0xd4b3, 0x2000 },
  { 0x0901, 0xd4b2, 0x0000 },
  { 0x0901, 0xd4b4, 0x0000 },
  { 0x8501, 0xd4b7, 0x2000 },
  { 0x0501, 0xd4b6, 0x0000 },
  { 0x0501, 0xd4b8, 0x0000 },
  { 0x8501, 0xd4bf, 0x3000 },
  { 0x8501, 0xd4bd, 0x2000 },
  { 0x0501, 0xd4bb, 0x0000 },
  { 0x0501, 0xd4be, 0x0000 },
  { 0x8501, 0xd4c1, 0x2000 },
  { 0x0501, 0xd4c0, 0x0000 },
  { 0x0501, 0xd4c2, 0x0000 },
  { 0x8901, 0xd4d4, 0x5000 },
  { 0x8501, 0xd4cc, 0x4000 },
  { 0x8501, 0xd4c8, 0x3000 },
  { 0x8501, 0xd4c6, 0x2000 },
  { 0x0501, 0xd4c5, 0x0000 },
  { 0x0501, 0xd4c7, 0x0000 },
  { 0x8501, 0xd4ca, 0x2000 },
  { 0x0501, 0xd4c9, 0x0000 },
  { 0x0501, 0xd4cb, 0x0000 },
  { 0x8901, 0xd4d0, 0x3000 },
  { 0x8501, 0xd4ce, 0x2000 },
  { 0x0501, 0xd4cd, 0x0000 },
  { 0x0501, 0xd4cf, 0x0000 },
  { 0x8901, 0xd4d2, 0x2000 },
  { 0x0901, 0xd4d1, 0x0000 },
  { 0x0901, 0xd4d3, 0x0000 },
  { 0x8901, 0xd4dc, 0x4000 },
  { 0x8901, 0xd4d8, 0x3000 },
  { 0x8901, 0xd4d6, 0x2000 },
  { 0x0901, 0xd4d5, 0x0000 },
  { 0x0901, 0xd4d7, 0x0000 },
  { 0x8901, 0xd4da, 0x2000 },
  { 0x0901, 0xd4d9, 0x0000 },
  { 0x0901, 0xd4db, 0x0000 },
  { 0x8901, 0xd4e0, 0x3000 },
  { 0x8901, 0xd4de, 0x2000 },
  { 0x0901, 0xd4dd, 0x0000 },
  { 0x0901, 0xd4df, 0x0000 },
  { 0x8901, 0xd4e2, 0x2000 },
  { 0x0901, 0xd4e1, 0x0000 },
  { 0x0901, 0xd4e3, 0x0000 },
  { 0x8501, 0xd529, 0x7000 },
  { 0x8901, 0xd504, 0x6000 },
  { 0x8501, 0xd4f4, 0x5000 },
  { 0x8501, 0xd4ec, 0x4000 },
  { 0x8901, 0xd4e8, 0x3000 },
  { 0x8901, 0xd4e6, 0x2000 },
  { 0x0901, 0xd4e5, 0x0000 },
  { 0x0901, 0xd4e7, 0x0000 },
  { 0x8501, 0xd4ea, 0x2000 },
  { 0x0901, 0xd4e9, 0x0000 },
  { 0x0501, 0xd4eb, 0x0000 },
  { 0x8501, 0xd4f0, 0x3000 },
  { 0x8501, 0xd4ee, 0x2000 },
  { 0x0501, 0xd4ed, 0x0000 },
  { 0x0501, 0xd4ef, 0x0000 },
  { 0x8501, 0xd4f2, 0x2000 },
  { 0x0501, 0xd4f1, 0x0000 },
  { 0x0501, 0xd4f3, 0x0000 },
  { 0x8501, 0xd4fc, 0x4000 },
  { 0x8501, 0xd4f8, 0x3000 },
  { 0x8501, 0xd4f6, 0x2000 },
  { 0x0501, 0xd4f5, 0x0000 },
  { 0x0501, 0xd4f7, 0x0000 },
  { 0x8501, 0xd4fa, 0x2000 },
  { 0x0501, 0xd4f9, 0x0000 },
  { 0x0501, 0xd4fb, 0x0000 },
  { 0x8501, 0xd500, 0x3000 },
  { 0x8501, 0xd4fe, 0x2000 },
  { 0x0501, 0xd4fd, 0x0000 },
  { 0x0501, 0xd4ff, 0x0000 },
  { 0x8501, 0xd502, 0x2000 },
  { 0x0501, 0xd501, 0x0000 },
  { 0x0501, 0xd503, 0x0000 },
  { 0x8901, 0xd518, 0x5000 },
  { 0x8901, 0xd50f, 0x4000 },
  { 0x8901, 0xd509, 0x3000 },
  { 0x8901, 0xd507, 0x2000 },
  { 0x0901, 0xd505, 0x0000 },
  { 0x0901, 0xd508, 0x0000 },
  { 0x8901, 0xd50d, 0x2000 },
  { 0x0901, 0xd50a, 0x0000 },
  { 0x0901, 0xd50e, 0x0000 },
  { 0x8901, 0xd513, 0x3000 },
  { 0x8901, 0xd511, 0x2000 },
  { 0x0901, 0xd510, 0x0000 },
  { 0x0901, 0xd512, 0x0000 },
  { 0x8901, 0xd516, 0x2000 },
  { 0x0901, 0xd514, 0x0000 },
  { 0x0901, 0xd517, 0x0000 },
  { 0x8501, 0xd521, 0x4000 },
  { 0x8901, 0xd51c, 0x3000 },
  { 0x8901, 0xd51a, 0x2000 },
  { 0x0901, 0xd519, 0x0000 },
  { 0x0901, 0xd51b, 0x0000 },
  { 0x8501, 0xd51f, 0x2000 },
  { 0x0501, 0xd51e, 0x0000 },
  { 0x0501, 0xd520, 0x0000 },
  { 0x8501, 0xd525, 0x3000 },
  { 0x8501, 0xd523, 0x2000 },
  { 0x0501, 0xd522, 0x0000 },
  { 0x0501, 0xd524, 0x0000 },
  { 0x8501, 0xd527, 0x2000 },
  { 0x0501, 0xd526, 0x0000 },
  { 0x0501, 0xd528, 0x0000 },
  { 0x8901, 0xd54f, 0x6000 },
  { 0x8901, 0xd539, 0x5000 },
  { 0x8501, 0xd531, 0x4000 },
  { 0x8501, 0xd52d, 0x3000 },
  { 0x8501, 0xd52b, 0x2000 },
  { 0x0501, 0xd52a, 0x0000 },
  { 0x0501, 0xd52c, 0x0000 },
  { 0x8501, 0xd52f, 0x2000 },
  { 0x0501, 0xd52e, 0x0000 },
  { 0x0501, 0xd530, 0x0000 },
  { 0x8501, 0xd535, 0x3000 },
  { 0x8501, 0xd533, 0x2000 },
  { 0x0501, 0xd532, 0x0000 },
  { 0x0501, 0xd534, 0x0000 },
  { 0x8501, 0xd537, 0x2000 },
  { 0x0501, 0xd536, 0x0000 },
  { 0x0901, 0xd538, 0x0000 },
  { 0x8901, 0xd543, 0x4000 },
  { 0x8901, 0xd53e, 0x3000 },
  { 0x8901, 0xd53c, 0x2000 },
  { 0x0901, 0xd53b, 0x0000 },
  { 0x0901, 0xd53d, 0x0000 },
  { 0x8901, 0xd541, 0x2000 },
  { 0x0901, 0xd540, 0x0000 },
  { 0x0901, 0xd542, 0x0000 },
  { 0x8901, 0xd54b, 0x3000 },
  { 0x8901, 0xd546, 0x2000 },
  { 0x0901, 0xd544, 0x0000 },
  { 0x0901, 0xd54a, 0x0000 },
  { 0x8901, 0xd54d, 0x2000 },
  { 0x0901, 0xd54c, 0x0000 },
  { 0x0901, 0xd54e, 0x0000 },
  { 0x8501, 0xd560, 0x5000 },
  { 0x8501, 0xd558, 0x4000 },
  { 0x8501, 0xd554, 0x3000 },
  { 0x8501, 0xd552, 0x2000 },
  { 0x0901, 0xd550, 0x0000 },
  { 0x0501, 0xd553, 0x0000 },
  { 0x8501, 0xd556, 0x2000 },
  { 0x0501, 0xd555, 0x0000 },
  { 0x0501, 0xd557, 0x0000 },
  { 0x8501, 0xd55c, 0x3000 },
  { 0x8501, 0xd55a, 0x2000 },
  { 0x0501, 0xd559, 0x0000 },
  { 0x0501, 0xd55b, 0x0000 },
  { 0x8501, 0xd55e, 0x2000 },
  { 0x0501, 0xd55d, 0x0000 },
  { 0x0501, 0xd55f, 0x0000 },
  { 0x8501, 0xd568, 0x4000 },
  { 0x8501, 0xd564, 0x3000 },
  { 0x8501, 0xd562, 0x2000 },
  { 0x0501, 0xd561, 0x0000 },
  { 0x0501, 0xd563, 0x0000 },
  { 0x8501, 0xd566, 0x2000 },
  { 0x0501, 0xd565, 0x0000 },
  { 0x0501, 0xd567, 0x0000 },
  { 0x8901, 0xd56c, 0x3000 },
  { 0x8501, 0xd56a, 0x2000 },
  { 0x0501, 0xd569, 0x0000 },
  { 0x0501, 0xd56b, 0x0000 },
  { 0x8901, 0xd56e, 0x2000 },
  { 0x0901, 0xd56d, 0x0000 },
  { 0x0901, 0xd56f, 0x0000 },
  { 0x8501, 0xd5f0, 0x8000 },
  { 0x8901, 0xd5b0, 0x7000 },
  { 0x8501, 0xd590, 0x6000 },
  { 0x8901, 0xd580, 0x5000 },
  { 0x8901, 0xd578, 0x4000 },
  { 0x8901, 0xd574, 0x3000 },
  { 0x8901, 0xd572, 0x2000 },
  { 0x0901, 0xd571, 0x0000 },
  { 0x0901, 0xd573, 0x0000 },
  { 0x8901, 0xd576, 0x2000 },
  { 0x0901, 0xd575, 0x0000 },
  { 0x0901, 0xd577, 0x0000 },
  { 0x8901, 0xd57c, 0x3000 },
  { 0x8901, 0xd57a, 0x2000 },
  { 0x0901, 0xd579, 0x0000 },
  { 0x0901, 0xd57b, 0x0000 },
  { 0x8901, 0xd57e, 0x2000 },
  { 0x0901, 0xd57d, 0x0000 },
  { 0x0901, 0xd57f, 0x0000 },
  { 0x8501, 0xd588, 0x4000 },
  { 0x8901, 0xd584, 0x3000 },
  { 0x8901, 0xd582, 0x2000 },
  { 0x0901, 0xd581, 0x0000 },
  { 0x0901, 0xd583, 0x0000 },
  { 0x8501, 0xd586, 0x2000 },
  { 0x0901, 0xd585, 0x0000 },
  { 0x0501, 0xd587, 0x0000 },
  { 0x8501, 0xd58c, 0x3000 },
  { 0x8501, 0xd58a, 0x2000 },
  { 0x0501, 0xd589, 0x0000 },
  { 0x0501, 0xd58b, 0x0000 },
  { 0x8501, 0xd58e, 0x2000 },
  { 0x0501, 0xd58d, 0x0000 },
  { 0x0501, 0xd58f, 0x0000 },
  { 0x8901, 0xd5a0, 0x5000 },
  { 0x8501, 0xd598, 0x4000 },
  { 0x8501, 0xd594, 0x3000 },
  { 0x8501, 0xd592, 0x2000 },
  { 0x0501, 0xd591, 0x0000 },
  { 0x0501, 0xd593, 0x0000 },
  { 0x8501, 0xd596, 0x2000 },
  { 0x0501, 0xd595, 0x0000 },
  { 0x0501, 0xd597, 0x0000 },
  { 0x8501, 0xd59c, 0x3000 },
  { 0x8501, 0xd59a, 0x2000 },
  { 0x0501, 0xd599, 0x0000 },
  { 0x0501, 0xd59b, 0x0000 },
  { 0x8501, 0xd59e, 0x2000 },
  { 0x0501, 0xd59d, 0x0000 },
  { 0x0501, 0xd59f, 0x0000 },
  { 0x8901, 0xd5a8, 0x4000 },
  { 0x8901, 0xd5a4, 0x3000 },
  { 0x8901, 0xd5a2, 0x2000 },
  { 0x0901, 0xd5a1, 0x0000 },
  { 0x0901, 0xd5a3, 0x0000 },
  { 0x8901, 0xd5a6, 0x2000 },
  { 0x0901, 0xd5a5, 0x0000 },
  { 0x0901, 0xd5a7, 0x0000 },
  { 0x8901, 0xd5ac, 0x3000 },
  { 0x8901, 0xd5aa, 0x2000 },
  { 0x0901, 0xd5a9, 0x0000 },
  { 0x0901, 0xd5ab, 0x0000 },
  { 0x8901, 0xd5ae, 0x2000 },
  { 0x0901, 0xd5ad, 0x0000 },
  { 0x0901, 0xd5af, 0x0000 },
  { 0x8501, 0xd5d0, 0x6000 },
  { 0x8501, 0xd5c0, 0x5000 },
  { 0x8901, 0xd5b8, 0x4000 },
  { 0x8901, 0xd5b4, 0x3000 },
  { 0x8901, 0xd5b2, 0x2000 },
  { 0x0901, 0xd5b1, 0x0000 },
  { 0x0901, 0xd5b3, 0x0000 },
  { 0x8901, 0xd5b6, 0x2000 },
  { 0x0901, 0xd5b5, 0x0000 },
  { 0x0901, 0xd5b7, 0x0000 },
  { 0x8501, 0xd5bc, 0x3000 },
  { 0x8501, 0xd5ba, 0x2000 },
  { 0x0901, 0xd5b9, 0x0000 },
  { 0x0501, 0xd5bb, 0x0000 },
  { 0x8501, 0xd5be, 0x2000 },
  { 0x0501, 0xd5bd, 0x0000 },
  { 0x0501, 0xd5bf, 0x0000 },
  { 0x8501, 0xd5c8, 0x4000 },
  { 0x8501, 0xd5c4, 0x3000 },
  { 0x8501, 0xd5c2, 0x2000 },
  { 0x0501, 0xd5c1, 0x0000 },
  { 0x0501, 0xd5c3, 0x0000 },
  { 0x8501, 0xd5c6, 0x2000 },
  { 0x0501, 0xd5c5, 0x0000 },
  { 0x0501, 0xd5c7, 0x0000 },
  { 0x8501, 0xd5cc, 0x3000 },
  { 0x8501, 0xd5ca, 0x2000 },
  { 0x0501, 0xd5c9, 0x0000 },
  { 0x0501, 0xd5cb, 0x0000 },
  { 0x8501, 0xd5ce, 0x2000 },
  { 0x0501, 0xd5cd, 0x0000 },
  { 0x0501, 0xd5cf, 0x0000 },
  { 0x8901, 0xd5e0, 0x5000 },
  { 0x8901, 0xd5d8, 0x4000 },
  { 0x8901, 0xd5d4, 0x3000 },
  { 0x8501, 0xd5d2, 0x2000 },
  { 0x0501, 0xd5d1, 0x0000 },
  { 0x0501, 0xd5d3, 0x0000 },
  { 0x8901, 0xd5d6, 0x2000 },
  { 0x0901, 0xd5d5, 0x0000 },
  { 0x0901, 0xd5d7, 0x0000 },
  { 0x8901, 0xd5dc, 0x3000 },
  { 0x8901, 0xd5da, 0x2000 },
  { 0x0901, 0xd5d9, 0x0000 },
  { 0x0901, 0xd5db, 0x0000 },
  { 0x8901, 0xd5de, 0x2000 },
  { 0x0901, 0xd5dd, 0x0000 },
  { 0x0901, 0xd5df, 0x0000 },
  { 0x8901, 0xd5e8, 0x4000 },
  { 0x8901, 0xd5e4, 0x3000 },
  { 0x8901, 0xd5e2, 0x2000 },
  { 0x0901, 0xd5e1, 0x0000 },
  { 0x0901, 0xd5e3, 0x0000 },
  { 0x8901, 0xd5e6, 0x2000 },
  { 0x0901, 0xd5e5, 0x0000 },
  { 0x0901, 0xd5e7, 0x0000 },
  { 0x8901, 0xd5ec, 0x3000 },
  { 0x8901, 0xd5ea, 0x2000 },
  { 0x0901, 0xd5e9, 0x0000 },
  { 0x0901, 0xd5eb, 0x0000 },
  { 0x8501, 0xd5ee, 0x2000 },
  { 0x0901, 0xd5ed, 0x0000 },
  { 0x0501, 0xd5ef, 0x0000 },
  { 0x8501, 0xd630, 0x7000 },
  { 0x8901, 0xd610, 0x6000 },
  { 0x8501, 0xd600, 0x5000 },
  { 0x8501, 0xd5f8, 0x4000 },
  { 0x8501, 0xd5f4, 0x3000 },
  { 0x8501, 0xd5f2, 0x2000 },
  { 0x0501, 0xd5f1, 0x0000 },
  { 0x0501, 0xd5f3, 0x0000 },
  { 0x8501, 0xd5f6, 0x2000 },
  { 0x0501, 0xd5f5, 0x0000 },
  { 0x0501, 0xd5f7, 0x0000 },
  { 0x8501, 0xd5fc, 0x3000 },
  { 0x8501, 0xd5fa, 0x2000 },
  { 0x0501, 0xd5f9, 0x0000 },
  { 0x0501, 0xd5fb, 0x0000 },
  { 0x8501, 0xd5fe, 0x2000 },
  { 0x0501, 0xd5fd, 0x0000 },
  { 0x0501, 0xd5ff, 0x0000 },
  { 0x8901, 0xd608, 0x4000 },
  { 0x8501, 0xd604, 0x3000 },
  { 0x8501, 0xd602, 0x2000 },
  { 0x0501, 0xd601, 0x0000 },
  { 0x0501, 0xd603, 0x0000 },
  { 0x8501, 0xd606, 0x2000 },
  { 0x0501, 0xd605, 0x0000 },
  { 0x0501, 0xd607, 0x0000 },
  { 0x8901, 0xd60c, 0x3000 },
  { 0x8901, 0xd60a, 0x2000 },
  { 0x0901, 0xd609, 0x0000 },
  { 0x0901, 0xd60b, 0x0000 },
  { 0x8901, 0xd60e, 0x2000 },
  { 0x0901, 0xd60d, 0x0000 },
  { 0x0901, 0xd60f, 0x0000 },
  { 0x8901, 0xd620, 0x5000 },
  { 0x8901, 0xd618, 0x4000 },
  { 0x8901, 0xd614, 0x3000 },
  { 0x8901, 0xd612, 0x2000 },
  { 0x0901, 0xd611, 0x0000 },
  { 0x0901, 0xd613, 0x0000 },
  { 0x8901, 0xd616, 0x2000 },
  { 0x0901, 0xd615, 0x0000 },
  { 0x0901, 0xd617, 0x0000 },
  { 0x8901, 0xd61c, 0x3000 },
  { 0x8901, 0xd61a, 0x2000 },
  { 0x0901, 0xd619, 0x0000 },
  { 0x0901, 0xd61b, 0x0000 },
  { 0x8901, 0xd61e, 0x2000 },
  { 0x0901, 0xd61d, 0x0000 },
  { 0x0901, 0xd61f, 0x0000 },
  { 0x8501, 0xd628, 0x4000 },
  { 0x8501, 0xd624, 0x3000 },
  { 0x8501, 0xd622, 0x2000 },
  { 0x0901, 0xd621, 0x0000 },
  { 0x0501, 0xd623, 0x0000 },
  { 0x8501, 0xd626, 0x2000 },
  { 0x0501, 0xd625, 0x0000 },
  { 0x0501, 0xd627, 0x0000 },
  { 0x8501, 0xd62c, 0x3000 },
  { 0x8501, 0xd62a, 0x2000 },
  { 0x0501, 0xd629, 0x0000 },
  { 0x0501, 0xd62b, 0x0000 },
  { 0x8501, 0xd62e, 0x2000 },
  { 0x0501, 0xd62d, 0x0000 },
  { 0x0501, 0xd62f, 0x0000 },
  { 0x8901, 0xd650, 0x6000 },
  { 0x8901, 0xd640, 0x5000 },
  { 0x8501, 0xd638, 0x4000 },
  { 0x8501, 0xd634, 0x3000 },
  { 0x8501, 0xd632, 0x2000 },
  { 0x0501, 0xd631, 0x0000 },
  { 0x0501, 0xd633, 0x0000 },
  { 0x8501, 0xd636, 0x2000 },
  { 0x0501, 0xd635, 0x0000 },
  { 0x0501, 0xd637, 0x0000 },
  { 0x8901, 0xd63c, 0x3000 },
  { 0x8501, 0xd63a, 0x2000 },
  { 0x0501, 0xd639, 0x0000 },
  { 0x0501, 0xd63b, 0x0000 },
  { 0x8901, 0xd63e, 0x2000 },
  { 0x0901, 0xd63d, 0x0000 },
  { 0x0901, 0xd63f, 0x0000 },
  { 0x8901, 0xd648, 0x4000 },
  { 0x8901, 0xd644, 0x3000 },
  { 0x8901, 0xd642, 0x2000 },
  { 0x0901, 0xd641, 0x0000 },
  { 0x0901, 0xd643, 0x0000 },
  { 0x8901, 0xd646, 0x2000 },
  { 0x0901, 0xd645, 0x0000 },
  { 0x0901, 0xd647, 0x0000 },
  { 0x8901, 0xd64c, 0x3000 },
  { 0x8901, 0xd64a, 0x2000 },
  { 0x0901, 0xd649, 0x0000 },
  { 0x0901, 0xd64b, 0x0000 },
  { 0x8901, 0xd64e, 0x2000 },
  { 0x0901, 0xd64d, 0x0000 },
  { 0x0901, 0xd64f, 0x0000 },
  { 0x8501, 0xd660, 0x5000 },
  { 0x8501, 0xd658, 0x4000 },
  { 0x8901, 0xd654, 0x3000 },
  { 0x8901, 0xd652, 0x2000 },
  { 0x0901, 0xd651, 0x0000 },
  { 0x0901, 0xd653, 0x0000 },
  { 0x8501, 0xd656, 0x2000 },
  { 0x0901, 0xd655, 0x0000 },
  { 0x0501, 0xd657, 0x0000 },
  { 0x8501, 0xd65c, 0x3000 },
  { 0x8501, 0xd65a, 0x2000 },
  { 0x0501, 0xd659, 0x0000 },
  { 0x0501, 0xd65b, 0x0000 },
  { 0x8501, 0xd65e, 0x2000 },
  { 0x0501, 0xd65d, 0x0000 },
  { 0x0501, 0xd65f, 0x0000 },
  { 0x8501, 0xd668, 0x4000 },
  { 0x8501, 0xd664, 0x3000 },
  { 0x8501, 0xd662, 0x2000 },
  { 0x0501, 0xd661, 0x0000 },
  { 0x0501, 0xd663, 0x0000 },
  { 0x8501, 0xd666, 0x2000 },
  { 0x0501, 0xd665, 0x0000 },
  { 0x0501, 0xd667, 0x0000 },
  { 0x8501, 0xd66c, 0x3000 },
  { 0x8501, 0xd66a, 0x2000 },
  { 0x0501, 0xd669, 0x0000 },
  { 0x0501, 0xd66b, 0x0000 },
  { 0x8501, 0xd66e, 0x2000 },
  { 0x0501, 0xd66d, 0x0000 },
  { 0x0501, 0xd66f, 0x0000 },
  { 0x8501, 0xd774, 0x9000 },
  { 0x8901, 0xd6f4, 0x8000 },
  { 0x8901, 0xd6b4, 0x7000 },
  { 0x8501, 0xd690, 0x6000 },
  { 0x8901, 0xd680, 0x5000 },
  { 0x8901, 0xd678, 0x4000 },
  { 0x8901, 0xd674, 0x3000 },
  { 0x8901, 0xd672, 0x2000 },
  { 0x0901, 0xd671, 0x0000 },
  { 0x0901, 0xd673, 0x0000 },
  { 0x8901, 0xd676, 0x2000 },
  { 0x0901, 0xd675, 0x0000 },
  { 0x0901, 0xd677, 0x0000 },
  { 0x8901, 0xd67c, 0x3000 },
  { 0x8901, 0xd67a, 0x2000 },
  { 0x0901, 0xd679, 0x0000 },
  { 0x0901, 0xd67b, 0x0000 },
  { 0x8901, 0xd67e, 0x2000 },
  { 0x0901, 0xd67d, 0x0000 },
  { 0x0901, 0xd67f, 0x0000 },
  { 0x8901, 0xd688, 0x4000 },
  { 0x8901, 0xd684, 0x3000 },
  { 0x8901, 0xd682, 0x2000 },
  { 0x0901, 0xd681, 0x0000 },
  { 0x0901, 0xd683, 0x0000 },
  { 0x8901, 0xd686, 0x2000 },
  { 0x0901, 0xd685, 0x0000 },
  { 0x0901, 0xd687, 0x0000 },
  { 0x8501, 0xd68c, 0x3000 },
  { 0x8501, 0xd68a, 0x2000 },
  { 0x0901, 0xd689, 0x0000 },
  { 0x0501, 0xd68b, 0x0000 },
  { 0x8501, 0xd68e, 0x2000 },
  { 0x0501, 0xd68d, 0x0000 },
  { 0x0501, 0xd68f, 0x0000 },
  { 0x8501, 0xd6a0, 0x5000 },
  { 0x8501, 0xd698, 0x4000 },
  { 0x8501, 0xd694, 0x3000 },
  { 0x8501, 0xd692, 0x2000 },
  { 0x0501, 0xd691, 0x0000 },
  { 0x0501, 0xd693, 0x0000 },
  { 0x8501, 0xd696, 0x2000 },
  { 0x0501, 0xd695, 0x0000 },
  { 0x0501, 0xd697, 0x0000 },
  { 0x8501, 0xd69c, 0x3000 },
  { 0x8501, 0xd69a, 0x2000 },
  { 0x0501, 0xd699, 0x0000 },
  { 0x0501, 0xd69b, 0x0000 },
  { 0x8501, 0xd69e, 0x2000 },
  { 0x0501, 0xd69d, 0x0000 },
  { 0x0501, 0xd69f, 0x0000 },
  { 0x8901, 0xd6ac, 0x4000 },
  { 0x8901, 0xd6a8, 0x3000 },
  { 0x8501, 0xd6a2, 0x2000 },
  { 0x0501, 0xd6a1, 0x0000 },
  { 0x0501, 0xd6a3, 0x0000 },
  { 0x8901, 0xd6aa, 0x2000 },
  { 0x0901, 0xd6a9, 0x0000 },
  { 0x0901, 0xd6ab, 0x0000 },
  { 0x8901, 0xd6b0, 0x3000 },
  { 0x8901, 0xd6ae, 0x2000 },
  { 0x0901, 0xd6ad, 0x0000 },
  { 0x0901, 0xd6af, 0x0000 },
  { 0x8901, 0xd6b2, 0x2000 },
  { 0x0901, 0xd6b1, 0x0000 },
  { 0x0901, 0xd6b3, 0x0000 },
  { 0x8501, 0xd6d4, 0x6000 },
  { 0x8501, 0xd6c4, 0x5000 },
  { 0x8901, 0xd6bc, 0x4000 },
  { 0x8901, 0xd6b8, 0x3000 },
  { 0x8901, 0xd6b6, 0x2000 },
  { 0x0901, 0xd6b5, 0x0000 },
  { 0x0901, 0xd6b7, 0x0000 },
  { 0x8901, 0xd6ba, 0x2000 },
  { 0x0901, 0xd6b9, 0x0000 },
  { 0x0901, 0xd6bb, 0x0000 },
  { 0x8901, 0xd6c0, 0x3000 },
  { 0x8901, 0xd6be, 0x2000 },
  { 0x0901, 0xd6bd, 0x0000 },
  { 0x0901, 0xd6bf, 0x0000 },
  { 0x8501, 0xd6c2, 0x2000 },
  { 0x1901, 0xd6c1, 0x0000 },
  { 0x0501, 0xd6c3, 0x0000 },
  { 0x8501, 0xd6cc, 0x4000 },
  { 0x8501, 0xd6c8, 0x3000 },
  { 0x8501, 0xd6c6, 0x2000 },
  { 0x0501, 0xd6c5, 0x0000 },
  { 0x0501, 0xd6c7, 0x0000 },
  { 0x8501, 0xd6ca, 0x2000 },
  { 0x0501, 0xd6c9, 0x0000 },
  { 0x0501, 0xd6cb, 0x0000 },
  { 0x8501, 0xd6d0, 0x3000 },
  { 0x8501, 0xd6ce, 0x2000 },
  { 0x0501, 0xd6cd, 0x0000 },
  { 0x0501, 0xd6cf, 0x0000 },
  { 0x8501, 0xd6d2, 0x2000 },
  { 0x0501, 0xd6d1, 0x0000 },
  { 0x0501, 0xd6d3, 0x0000 },
  { 0x8901, 0xd6e4, 0x5000 },
  { 0x8501, 0xd6dc, 0x4000 },
  { 0x8501, 0xd6d8, 0x3000 },
  { 0x8501, 0xd6d6, 0x2000 },
  { 0x0501, 0xd6d5, 0x0000 },
  { 0x0501, 0xd6d7, 0x0000 },
  { 0x8501, 0xd6da, 0x2000 },
  { 0x0501, 0xd6d9, 0x0000 },
  { 0x1901, 0xd6db, 0x0000 },
  { 0x8501, 0xd6e0, 0x3000 },
  { 0x8501, 0xd6de, 0x2000 },
  { 0x0501, 0xd6dd, 0x0000 },
  { 0x0501, 0xd6df, 0x0000 },
  { 0x8901, 0xd6e2, 0x2000 },
  { 0x0501, 0xd6e1, 0x0000 },
  { 0x0901, 0xd6e3, 0x0000 },
  { 0x8901, 0xd6ec, 0x4000 },
  { 0x8901, 0xd6e8, 0x3000 },
  { 0x8901, 0xd6e6, 0x2000 },
  { 0x0901, 0xd6e5, 0x0000 },
  { 0x0901, 0xd6e7, 0x0000 },
  { 0x8901, 0xd6ea, 0x2000 },
  { 0x0901, 0xd6e9, 0x0000 },
  { 0x0901, 0xd6eb, 0x0000 },
  { 0x8901, 0xd6f0, 0x3000 },
  { 0x8901, 0xd6ee, 0x2000 },
  { 0x0901, 0xd6ed, 0x0000 },
  { 0x0901, 0xd6ef, 0x0000 },
  { 0x8901, 0xd6f2, 0x2000 },
  { 0x0901, 0xd6f1, 0x0000 },
  { 0x0901, 0xd6f3, 0x0000 },
  { 0x8901, 0xd734, 0x7000 },
  { 0x8501, 0xd714, 0x6000 },
  { 0x8501, 0xd704, 0x5000 },
  { 0x8501, 0xd6fc, 0x4000 },
  { 0x8901, 0xd6f8, 0x3000 },
  { 0x8901, 0xd6f6, 0x2000 },
  { 0x0901, 0xd6f5, 0x0000 },
  { 0x0901, 0xd6f7, 0x0000 },
  { 0x8901, 0xd6fa, 0x2000 },
  { 0x0901, 0xd6f9, 0x0000 },
  { 0x1901, 0xd6fb, 0x0000 },
  { 0x8501, 0xd700, 0x3000 },
  { 0x8501, 0xd6fe, 0x2000 },
  { 0x0501, 0xd6fd, 0x0000 },
  { 0x0501, 0xd6ff, 0x0000 },
  { 0x8501, 0xd702, 0x2000 },
  { 0x0501, 0xd701, 0x0000 },
  { 0x0501, 0xd703, 0x0000 },
  { 0x8501, 0xd70c, 0x4000 },
  { 0x8501, 0xd708, 0x3000 },
  { 0x8501, 0xd706, 0x2000 },
  { 0x0501, 0xd705, 0x0000 },
  { 0x0501, 0xd707, 0x0000 },
  { 0x8501, 0xd70a, 0x2000 },
  { 0x0501, 0xd709, 0x0000 },
  { 0x0501, 0xd70b, 0x0000 },
  { 0x8501, 0xd710, 0x3000 },
  { 0x8501, 0xd70e, 0x2000 },
  { 0x0501, 0xd70d, 0x0000 },
  { 0x0501, 0xd70f, 0x0000 },
  { 0x8501, 0xd712, 0x2000 },
  { 0x0501, 0xd711, 0x0000 },
  { 0x0501, 0xd713, 0x0000 },
  { 0x8901, 0xd724, 0x5000 },
  { 0x8901, 0xd71c, 0x4000 },
  { 0x8501, 0xd718, 0x3000 },
  { 0x8501, 0xd716, 0x2000 },
  { 0x1901, 0xd715, 0x0000 },
  { 0x0501, 0xd717, 0x0000 },
  { 0x8501, 0xd71a, 0x2000 },
  { 0x0501, 0xd719, 0x0000 },
  { 0x0501, 0xd71b, 0x0000 },
  { 0x8901, 0xd720, 0x3000 },
  { 0x8901, 0xd71e, 0x2000 },
  { 0x0901, 0xd71d, 0x0000 },
  { 0x0901, 0xd71f, 0x0000 },
  { 0x8901, 0xd722, 0x2000 },
  { 0x0901, 0xd721, 0x0000 },
  { 0x0901, 0xd723, 0x0000 },
  { 0x8901, 0xd72c, 0x4000 },
  { 0x8901, 0xd728, 0x3000 },
  { 0x8901, 0xd726, 0x2000 },
  { 0x0901, 0xd725, 0x0000 },
  { 0x0901, 0xd727, 0x0000 },
  { 0x8901, 0xd72a, 0x2000 },
  { 0x0901, 0xd729, 0x0000 },
  { 0x0901, 0xd72b, 0x0000 },
  { 0x8901, 0xd730, 0x3000 },
  { 0x8901, 0xd72e, 0x2000 },
  { 0x0901, 0xd72d, 0x0000 },
  { 0x0901, 0xd72f, 0x0000 },
  { 0x8901, 0xd732, 0x2000 },
  { 0x0901, 0xd731, 0x0000 },
  { 0x0901, 0xd733, 0x0000 },
  { 0x8501, 0xd754, 0x6000 },
  { 0x8501, 0xd744, 0x5000 },
  { 0x8501, 0xd73c, 0x4000 },
  { 0x8501, 0xd738, 0x3000 },
  { 0x8501, 0xd736, 0x2000 },
  { 0x1901, 0xd735, 0x0000 },
  { 0x0501, 0xd737, 0x0000 },
  { 0x8501, 0xd73a, 0x2000 },
  { 0x0501, 0xd739, 0x0000 },
  { 0x0501, 0xd73b, 0x0000 },
  { 0x8501, 0xd740, 0x3000 },
  { 0x8501, 0xd73e, 0x2000 },
  { 0x0501, 0xd73d, 0x0000 },
  { 0x0501, 0xd73f, 0x0000 },
  { 0x8501, 0xd742, 0x2000 },
  { 0x0501, 0xd741, 0x0000 },
  { 0x0501, 0xd743, 0x0000 },
  { 0x8501, 0xd74c, 0x4000 },
  { 0x8501, 0xd748, 0x3000 },
  { 0x8501, 0xd746, 0x2000 },
  { 0x0501, 0xd745, 0x0000 },
  { 0x0501, 0xd747, 0x0000 },
  { 0x8501, 0xd74a, 0x2000 },
  { 0x0501, 0xd749, 0x0000 },
  { 0x0501, 0xd74b, 0x0000 },
  { 0x8501, 0xd750, 0x3000 },
  { 0x8501, 0xd74e, 0x2000 },
  { 0x0501, 0xd74d, 0x0000 },
  { 0x1901, 0xd74f, 0x0000 },
  { 0x8501, 0xd752, 0x2000 },
  { 0x0501, 0xd751, 0x0000 },
  { 0x0501, 0xd753, 0x0000 },
  { 0x8901, 0xd764, 0x5000 },
  { 0x8901, 0xd75c, 0x4000 },
  { 0x8901, 0xd758, 0x3000 },
  { 0x8901, 0xd756, 0x2000 },
  { 0x0501, 0xd755, 0x0000 },
  { 0x0901, 0xd757, 0x0000 },
  { 0x8901, 0xd75a, 0x2000 },
  { 0x0901, 0xd759, 0x0000 },
  { 0x0901, 0xd75b, 0x0000 },
  { 0x8901, 0xd760, 0x3000 },
  { 0x8901, 0xd75e, 0x2000 },
  { 0x0901, 0xd75d, 0x0000 },
  { 0x0901, 0xd75f, 0x0000 },
  { 0x8901, 0xd762, 0x2000 },
  { 0x0901, 0xd761, 0x0000 },
  { 0x0901, 0xd763, 0x0000 },
  { 0x8901, 0xd76c, 0x4000 },
  { 0x8901, 0xd768, 0x3000 },
  { 0x8901, 0xd766, 0x2000 },
  { 0x0901, 0xd765, 0x0000 },
  { 0x0901, 0xd767, 0x0000 },
  { 0x8901, 0xd76a, 0x2000 },
  { 0x0901, 0xd769, 0x0000 },
  { 0x0901, 0xd76b, 0x0000 },
  { 0x8501, 0xd770, 0x3000 },
  { 0x8901, 0xd76e, 0x2000 },
  { 0x0901, 0xd76d, 0x0000 },
  { 0x1901, 0xd76f, 0x0000 },
  { 0x8501, 0xd772, 0x2000 },
  { 0x0501, 0xd771, 0x0000 },
  { 0x0501, 0xd773, 0x0000 },
  { 0x8d01, 0xd7f8, 0x8000 },
  { 0x8501, 0xd7b4, 0x7000 },
  { 0x8901, 0xd794, 0x6000 },
  { 0x8501, 0xd784, 0x5000 },
  { 0x8501, 0xd77c, 0x4000 },
  { 0x8501, 0xd778, 0x3000 },
  { 0x8501, 0xd776, 0x2000 },
  { 0x0501, 0xd775, 0x0000 },
  { 0x0501, 0xd777, 0x0000 },
  { 0x8501, 0xd77a, 0x2000 },
  { 0x0501, 0xd779, 0x0000 },
  { 0x0501, 0xd77b, 0x0000 },
  { 0x8501, 0xd780, 0x3000 },
  { 0x8501, 0xd77e, 0x2000 },
  { 0x0501, 0xd77d, 0x0000 },
  { 0x0501, 0xd77f, 0x0000 },
  { 0x8501, 0xd782, 0x2000 },
  { 0x0501, 0xd781, 0x0000 },
  { 0x0501, 0xd783, 0x0000 },
  { 0x8501, 0xd78c, 0x4000 },
  { 0x8501, 0xd788, 0x3000 },
  { 0x8501, 0xd786, 0x2000 },
  { 0x0501, 0xd785, 0x0000 },
  { 0x0501, 0xd787, 0x0000 },
  { 0x8501, 0xd78a, 0x2000 },
  { 0x1901, 0xd789, 0x0000 },
  { 0x0501, 0xd78b, 0x0000 },
  { 0x8901, 0xd790, 0x3000 },
  { 0x8501, 0xd78e, 0x2000 },
  { 0x0501, 0xd78d, 0x0000 },
  { 0x0501, 0xd78f, 0x0000 },
  { 0x8901, 0xd792, 0x2000 },
  { 0x0901, 0xd791, 0x0000 },
  { 0x0901, 0xd793, 0x0000 },
  { 0x8901, 0xd7a4, 0x5000 },
  { 0x8901, 0xd79c, 0x4000 },
  { 0x8901, 0xd798, 0x3000 },
  { 0x8901, 0xd796, 0x2000 },
  { 0x0901, 0xd795, 0x0000 },
  { 0x0901, 0xd797, 0x0000 },
  { 0x8901, 0xd79a, 0x2000 },
  { 0x0901, 0xd799, 0x0000 },
  { 0x0901, 0xd79b, 0x0000 },
  { 0x8901, 0xd7a0, 0x3000 },
  { 0x8901, 0xd79e, 0x2000 },
  { 0x0901, 0xd79d, 0x0000 },
  { 0x0901, 0xd79f, 0x0000 },
  { 0x8901, 0xd7a2, 0x2000 },
  { 0x0901, 0xd7a1, 0x0000 },
  { 0x0901, 0xd7a3, 0x0000 },
  { 0x8501, 0xd7ac, 0x4000 },
  { 0x8901, 0xd7a8, 0x3000 },
  { 0x8901, 0xd7a6, 0x2000 },
  { 0x0901, 0xd7a5, 0x0000 },
  { 0x0901, 0xd7a7, 0x0000 },
  { 0x8501, 0xd7aa, 0x2000 },
  { 0x1901, 0xd7a9, 0x0000 },
  { 0x0501, 0xd7ab, 0x0000 },
  { 0x8501, 0xd7b0, 0x3000 },
  { 0x8501, 0xd7ae, 0x2000 },
  { 0x0501, 0xd7ad, 0x0000 },
  { 0x0501, 0xd7af, 0x0000 },
  { 0x8501, 0xd7b2, 0x2000 },
  { 0x0501, 0xd7b1, 0x0000 },
  { 0x0501, 0xd7b3, 0x0000 },
  { 0x8d01, 0xd7d8, 0x6000 },
  { 0x8501, 0xd7c4, 0x5000 },
  { 0x8501, 0xd7bc, 0x4000 },
  { 0x8501, 0xd7b8, 0x3000 },
  { 0x8501, 0xd7b6, 0x2000 },
  { 0x0501, 0xd7b5, 0x0000 },
  { 0x0501, 0xd7b7, 0x0000 },
  { 0x8501, 0xd7ba, 0x2000 },
  { 0x0501, 0xd7b9, 0x0000 },
  { 0x0501, 0xd7bb, 0x0000 },
  { 0x8501, 0xd7c0, 0x3000 },
  { 0x8501, 0xd7be, 0x2000 },
  { 0x0501, 0xd7bd, 0x0000 },
  { 0x0501, 0xd7bf, 0x0000 },
  { 0x8501, 0xd7c2, 0x2000 },
  { 0x0501, 0xd7c1, 0x0000 },
  { 0x1901, 0xd7c3, 0x0000 },
  { 0x8d01, 0xd7d0, 0x4000 },
  { 0x8501, 0xd7c8, 0x3000 },
  { 0x8501, 0xd7c6, 0x2000 },
  { 0x0501, 0xd7c5, 0x0000 },
  { 0x0501, 0xd7c7, 0x0000 },
  { 0x8d01, 0xd7ce, 0x2000 },
  { 0x0501, 0xd7c9, 0x0000 },
  { 0x0d01, 0xd7cf, 0x0000 },
  { 0x8d01, 0xd7d4, 0x3000 },
  { 0x8d01, 0xd7d2, 0x2000 },
  { 0x0d01, 0xd7d1, 0x0000 },
  { 0x0d01, 0xd7d3, 0x0000 },
  { 0x8d01, 0xd7d6, 0x2000 },
  { 0x0d01, 0xd7d5, 0x0000 },
  { 0x0d01, 0xd7d7, 0x0000 },
  { 0x8d01, 0xd7e8, 0x5000 },
  { 0x8d01, 0xd7e0, 0x4000 },
  { 0x8d01, 0xd7dc, 0x3000 },
  { 0x8d01, 0xd7da, 0x2000 },
  { 0x0d01, 0xd7d9, 0x0000 },
  { 0x0d01, 0xd7db, 0x0000 },
  { 0x8d01, 0xd7de, 0x2000 },
  { 0x0d01, 0xd7dd, 0x0000 },
  { 0x0d01, 0xd7df, 0x0000 },
  { 0x8d01, 0xd7e4, 0x3000 },
  { 0x8d01, 0xd7e2, 0x2000 },
  { 0x0d01, 0xd7e1, 0x0000 },
  { 0x0d01, 0xd7e3, 0x0000 },
  { 0x8d01, 0xd7e6, 0x2000 },
  { 0x0d01, 0xd7e5, 0x0000 },
  { 0x0d01, 0xd7e7, 0x0000 },
  { 0x8d01, 0xd7f0, 0x4000 },
  { 0x8d01, 0xd7ec, 0x3000 },
  { 0x8d01, 0xd7ea, 0x2000 },
  { 0x0d01, 0xd7e9, 0x0000 },
  { 0x0d01, 0xd7eb, 0x0000 },
  { 0x8d01, 0xd7ee, 0x2000 },
  { 0x0d01, 0xd7ed, 0x0000 },
  { 0x0d01, 0xd7ef, 0x0000 },
  { 0x8d01, 0xd7f4, 0x3000 },
  { 0x8d01, 0xd7f2, 0x2000 },
  { 0x0d01, 0xd7f1, 0x0000 },
  { 0x0d01, 0xd7f3, 0x0000 },
  { 0x8d01, 0xd7f6, 0x2000 },
  { 0x0d01, 0xd7f5, 0x0000 },
  { 0x0d01, 0xd7f7, 0x0000 },
  { 0x8702, 0xf836, 0x7000 },
  { 0x8702, 0xf816, 0x6000 },
  { 0x8702, 0xf806, 0x5000 },
  { 0x8702, 0x0000, 0x4000 },
  { 0x8d01, 0xd7fc, 0x3000 },
  { 0x8d01, 0xd7fa, 0x2000 },
  { 0x0d01, 0xd7f9, 0x0000 },
  { 0x0d01, 0xd7fb, 0x0000 },
  { 0x8d01, 0xd7fe, 0x2000 },
  { 0x0d01, 0xd7fd, 0x0000 },
  { 0x0d01, 0xd7ff, 0x0000 },
  { 0x8702, 0xf802, 0x3000 },
  { 0x8702, 0xf800, 0x2000 },
  { 0x0702, 0xa6d6, 0x0000 },
  { 0x0702, 0xf801, 0x0000 },
  { 0x8702, 0xf804, 0x2000 },
  { 0x0702, 0xf803, 0x0000 },
  { 0x0702, 0xf805, 0x0000 },
  { 0x8702, 0xf80e, 0x4000 },
  { 0x8702, 0xf80a, 0x3000 },
  { 0x8702, 0xf808, 0x2000 },
  { 0x0702, 0xf807, 0x0000 },
  { 0x0702, 0xf809, 0x0000 },
  { 0x8702, 0xf80c, 0x2000 },
  { 0x0702, 0xf80b, 0x0000 },
  { 0x0702, 0xf80d, 0x0000 },
  { 0x8702, 0xf812, 0x3000 },
  { 0x8702, 0xf810, 0x2000 },
  { 0x0702, 0xf80f, 0x0000 },
  { 0x0702, 0xf811, 0x0000 },
  { 0x8702, 0xf814, 0x2000 },
  { 0x0702, 0xf813, 0x0000 },
  { 0x0702, 0xf815, 0x0000 },
  { 0x8702, 0xf826, 0x5000 },
  { 0x8702, 0xf81e, 0x4000 },
  { 0x8702, 0xf81a, 0x3000 },
  { 0x8702, 0xf818, 0x2000 },
  { 0x0702, 0xf817, 0x0000 },
  { 0x0702, 0xf819, 0x0000 },
  { 0x8702, 0xf81c, 0x2000 },
  { 0x0702, 0xf81b, 0x0000 },
  { 0x0702, 0xf81d, 0x0000 },
  { 0x8702, 0xf822, 0x3000 },
  { 0x8702, 0xf820, 0x2000 },
  { 0x0702, 0xf81f, 0x0000 },
  { 0x0702, 0xf821, 0x0000 },
  { 0x8702, 0xf824, 0x2000 },
  { 0x0702, 0xf823, 0x0000 },
  { 0x0702, 0xf825, 0x0000 },
  { 0x8702, 0xf82e, 0x4000 },
  { 0x8702, 0xf82a, 0x3000 },
  { 0x8702, 0xf828, 0x2000 },
  { 0x0702, 0xf827, 0x0000 },
  { 0x0702, 0xf829, 0x0000 },
  { 0x8702, 0xf82c, 0x2000 },
  { 0x0702, 0xf82b, 0x0000 },
  { 0x0702, 0xf82d, 0x0000 },
  { 0x8702, 0xf832, 0x3000 },
  { 0x8702, 0xf830, 0x2000 },
  { 0x0702, 0xf82f, 0x0000 },
  { 0x0702, 0xf831, 0x0000 },
  { 0x8702, 0xf834, 0x2000 },
  { 0x0702, 0xf833, 0x0000 },
  { 0x0702, 0xf835, 0x0000 },
  { 0x8702, 0xf856, 0x6000 },
  { 0x8702, 0xf846, 0x5000 },
  { 0x8702, 0xf83e, 0x4000 },
  { 0x8702, 0xf83a, 0x3000 },
  { 0x8702, 0xf838, 0x2000 },
  { 0x0702, 0xf837, 0x0000 },
  { 0x0702, 0xf839, 0x0000 },
  { 0x8702, 0xf83c, 0x2000 },
  { 0x0702, 0xf83b, 0x0000 },
  { 0x0702, 0xf83d, 0x0000 },
  { 0x8702, 0xf842, 0x3000 },
  { 0x8702, 0xf840, 0x2000 },
  { 0x0702, 0xf83f, 0x0000 },
  { 0x0702, 0xf841, 0x0000 },
  { 0x8702, 0xf844, 0x2000 },
  { 0x0702, 0xf843, 0x0000 },
  { 0x0702, 0xf845, 0x0000 },
  { 0x8702, 0xf84e, 0x4000 },
  { 0x8702, 0xf84a, 0x3000 },
  { 0x8702, 0xf848, 0x2000 },
  { 0x0702, 0xf847, 0x0000 },
  { 0x0702, 0xf849, 0x0000 },
  { 0x8702, 0xf84c, 0x2000 },
  { 0x0702, 0xf84b, 0x0000 },
  { 0x0702, 0xf84d, 0x0000 },
  { 0x8702, 0xf852, 0x3000 },
  { 0x8702, 0xf850, 0x2000 },
  { 0x0702, 0xf84f, 0x0000 },
  { 0x0702, 0xf851, 0x0000 },
  { 0x8702, 0xf854, 0x2000 },
  { 0x0702, 0xf853, 0x0000 },
  { 0x0702, 0xf855, 0x0000 },
  { 0x8702, 0xf866, 0x5000 },
  { 0x8702, 0xf85e, 0x4000 },
  { 0x8702, 0xf85a, 0x3000 },
  { 0x8702, 0xf858, 0x2000 },
  { 0x0702, 0xf857, 0x0000 },
  { 0x0702, 0xf859, 0x0000 },
  { 0x8702, 0xf85c, 0x2000 },
  { 0x0702, 0xf85b, 0x0000 },
  { 0x0702, 0xf85d, 0x0000 },
  { 0x8702, 0xf862, 0x3000 },
  { 0x8702, 0xf860, 0x2000 },
  { 0x0702, 0xf85f, 0x0000 },
  { 0x0702, 0xf861, 0x0000 },
  { 0x8702, 0xf864, 0x2000 },
  { 0x0702, 0xf863, 0x0000 },
  { 0x0702, 0xf865, 0x0000 },
  { 0x8702, 0xf86e, 0x4000 },
  { 0x8702, 0xf86a, 0x3000 },
  { 0x8702, 0xf868, 0x2000 },
  { 0x0702, 0xf867, 0x0000 },
  { 0x0702, 0xf869, 0x0000 },
  { 0x8702, 0xf86c, 0x2000 },
  { 0x0702, 0xf86b, 0x0000 },
  { 0x0702, 0xf86d, 0x0000 },
  { 0x8702, 0xf872, 0x3000 },
  { 0x8702, 0xf870, 0x2000 },
  { 0x0702, 0xf86f, 0x0000 },
  { 0x0702, 0xf871, 0x0000 },
  { 0x8702, 0xf874, 0x2000 },
  { 0x0702, 0xf873, 0x0000 },
  { 0x0702, 0xf875, 0x0000 },
  { 0x8702, 0xf976, 0x9000 },
  { 0x8702, 0xf8f6, 0x8000 },
  { 0x8702, 0xf8b6, 0x7000 },
  { 0x8702, 0xf896, 0x6000 },
  { 0x8702, 0xf886, 0x5000 },
  { 0x8702, 0xf87e, 0x4000 },
  { 0x8702, 0xf87a, 0x3000 },
  { 0x8702, 0xf878, 0x2000 },
  { 0x0702, 0xf877, 0x0000 },
  { 0x0702, 0xf879, 0x0000 },
  { 0x8702, 0xf87c, 0x2000 },
  { 0x0702, 0xf87b, 0x0000 },
  { 0x0702, 0xf87d, 0x0000 },
  { 0x8702, 0xf882, 0x3000 },
  { 0x8702, 0xf880, 0x2000 },
  { 0x0702, 0xf87f, 0x0000 },
  { 0x0702, 0xf881, 0x0000 },
  { 0x8702, 0xf884, 0x2000 },
  { 0x0702, 0xf883, 0x0000 },
  { 0x0702, 0xf885, 0x0000 },
  { 0x8702, 0xf88e, 0x4000 },
  { 0x8702, 0xf88a, 0x3000 },
  { 0x8702, 0xf888, 0x2000 },
  { 0x0702, 0xf887, 0x0000 },
  { 0x0702, 0xf889, 0x0000 },
  { 0x8702, 0xf88c, 0x2000 },
  { 0x0702, 0xf88b, 0x0000 },
  { 0x0702, 0xf88d, 0x0000 },
  { 0x8702, 0xf892, 0x3000 },
  { 0x8702, 0xf890, 0x2000 },
  { 0x0702, 0xf88f, 0x0000 },
  { 0x0702, 0xf891, 0x0000 },
  { 0x8702, 0xf894, 0x2000 },
  { 0x0702, 0xf893, 0x0000 },
  { 0x0702, 0xf895, 0x0000 },
  { 0x8702, 0xf8a6, 0x5000 },
  { 0x8702, 0xf89e, 0x4000 },
  { 0x8702, 0xf89a, 0x3000 },
  { 0x8702, 0xf898, 0x2000 },
  { 0x0702, 0xf897, 0x0000 },
  { 0x0702, 0xf899, 0x0000 },
  { 0x8702, 0xf89c, 0x2000 },
  { 0x0702, 0xf89b, 0x0000 },
  { 0x0702, 0xf89d, 0x0000 },
  { 0x8702, 0xf8a2, 0x3000 },
  { 0x8702, 0xf8a0, 0x2000 },
  { 0x0702, 0xf89f, 0x0000 },
  { 0x0702, 0xf8a1, 0x0000 },
  { 0x8702, 0xf8a4, 0x2000 },
  { 0x0702, 0xf8a3, 0x0000 },
  { 0x0702, 0xf8a5, 0x0000 },
  { 0x8702, 0xf8ae, 0x4000 },
  { 0x8702, 0xf8aa, 0x3000 },
  { 0x8702, 0xf8a8, 0x2000 },
  { 0x0702, 0xf8a7, 0x0000 },
  { 0x0702, 0xf8a9, 0x0000 },
  { 0x8702, 0xf8ac, 0x2000 },
  { 0x0702, 0xf8ab, 0x0000 },
  { 0x0702, 0xf8ad, 0x0000 },
  { 0x8702, 0xf8b2, 0x3000 },
  { 0x8702, 0xf8b0, 0x2000 },
  { 0x0702, 0xf8af, 0x0000 },
  { 0x0702, 0xf8b1, 0x0000 },
  { 0x8702, 0xf8b4, 0x2000 },
  { 0x0702, 0xf8b3, 0x0000 },
  { 0x0702, 0xf8b5, 0x0000 },
  { 0x8702, 0xf8d6, 0x6000 },
  { 0x8702, 0xf8c6, 0x5000 },
  { 0x8702, 0xf8be, 0x4000 },
  { 0x8702, 0xf8ba, 0x3000 },
  { 0x8702, 0xf8b8, 0x2000 },
  { 0x0702, 0xf8b7, 0x0000 },
  { 0x0702, 0xf8b9, 0x0000 },
  { 0x8702, 0xf8bc, 0x2000 },
  { 0x0702, 0xf8bb, 0x0000 },
  { 0x0702, 0xf8bd, 0x0000 },
  { 0x8702, 0xf8c2, 0x3000 },
  { 0x8702, 0xf8c0, 0x2000 },
  { 0x0702, 0xf8bf, 0x0000 },
  { 0x0702, 0xf8c1, 0x0000 },
  { 0x8702, 0xf8c4, 0x2000 },
  { 0x0702, 0xf8c3, 0x0000 },
  { 0x0702, 0xf8c5, 0x0000 },
  { 0x8702, 0xf8ce, 0x4000 },
  { 0x8702, 0xf8ca, 0x3000 },
  { 0x8702, 0xf8c8, 0x2000 },
  { 0x0702, 0xf8c7, 0x0000 },
  { 0x0702, 0xf8c9, 0x0000 },
  { 0x8702, 0xf8cc, 0x2000 },
  { 0x0702, 0xf8cb, 0x0000 },
  { 0x0702, 0xf8cd, 0x0000 },
  { 0x8702, 0xf8d2, 0x3000 },
  { 0x8702, 0xf8d0, 0x2000 },
  { 0x0702, 0xf8cf, 0x0000 },
  { 0x0702, 0xf8d1, 0x0000 },
  { 0x8702, 0xf8d4, 0x2000 },
  { 0x0702, 0xf8d3, 0x0000 },
  { 0x0702, 0xf8d5, 0x0000 },
  { 0x8702, 0xf8e6, 0x5000 },
  { 0x8702, 0xf8de, 0x4000 },
  { 0x8702, 0xf8da, 0x3000 },
  { 0x8702, 0xf8d8, 0x2000 },
  { 0x0702, 0xf8d7, 0x0000 },
  { 0x0702, 0xf8d9, 0x0000 },
  { 0x8702, 0xf8dc, 0x2000 },
  { 0x0702, 0xf8db, 0x0000 },
  { 0x0702, 0xf8dd, 0x0000 },
  { 0x8702, 0xf8e2, 0x3000 },
  { 0x8702, 0xf8e0, 0x2000 },
  { 0x0702, 0xf8df, 0x0000 },
  { 0x0702, 0xf8e1, 0x0000 },
  { 0x8702, 0xf8e4, 0x2000 },
  { 0x0702, 0xf8e3, 0x0000 },
  { 0x0702, 0xf8e5, 0x0000 },
  { 0x8702, 0xf8ee, 0x4000 },
  { 0x8702, 0xf8ea, 0x3000 },
  { 0x8702, 0xf8e8, 0x2000 },
  { 0x0702, 0xf8e7, 0x0000 },
  { 0x0702, 0xf8e9, 0x0000 },
  { 0x8702, 0xf8ec, 0x2000 },
  { 0x0702, 0xf8eb, 0x0000 },
  { 0x0702, 0xf8ed, 0x0000 },
  { 0x8702, 0xf8f2, 0x3000 },
  { 0x8702, 0xf8f0, 0x2000 },
  { 0x0702, 0xf8ef, 0x0000 },
  { 0x0702, 0xf8f1, 0x0000 },
  { 0x8702, 0xf8f4, 0x2000 },
  { 0x0702, 0xf8f3, 0x0000 },
  { 0x0702, 0xf8f5, 0x0000 },
  { 0x8702, 0xf936, 0x7000 },
  { 0x8702, 0xf916, 0x6000 },
  { 0x8702, 0xf906, 0x5000 },
  { 0x8702, 0xf8fe, 0x4000 },
  { 0x8702, 0xf8fa, 0x3000 },
  { 0x8702, 0xf8f8, 0x2000 },
  { 0x0702, 0xf8f7, 0x0000 },
  { 0x0702, 0xf8f9, 0x0000 },
  { 0x8702, 0xf8fc, 0x2000 },
  { 0x0702, 0xf8fb, 0x0000 },
  { 0x0702, 0xf8fd, 0x0000 },
  { 0x8702, 0xf902, 0x3000 },
  { 0x8702, 0xf900, 0x2000 },
  { 0x0702, 0xf8ff, 0x0000 },
  { 0x0702, 0xf901, 0x0000 },
  { 0x8702, 0xf904, 0x2000 },
  { 0x0702, 0xf903, 0x0000 },
  { 0x0702, 0xf905, 0x0000 },
  { 0x8702, 0xf90e, 0x4000 },
  { 0x8702, 0xf90a, 0x3000 },
  { 0x8702, 0xf908, 0x2000 },
  { 0x0702, 0xf907, 0x0000 },
  { 0x0702, 0xf909, 0x0000 },
  { 0x8702, 0xf90c, 0x2000 },
  { 0x0702, 0xf90b, 0x0000 },
  { 0x0702, 0xf90d, 0x0000 },
  { 0x8702, 0xf912, 0x3000 },
  { 0x8702, 0xf910, 0x2000 },
  { 0x0702, 0xf90f, 0x0000 },
  { 0x0702, 0xf911, 0x0000 },
  { 0x8702, 0xf914, 0x2000 },
  { 0x0702, 0xf913, 0x0000 },
  { 0x0702, 0xf915, 0x0000 },
  { 0x8702, 0xf926, 0x5000 },
  { 0x8702, 0xf91e, 0x4000 },
  { 0x8702, 0xf91a, 0x3000 },
  { 0x8702, 0xf918, 0x2000 },
  { 0x0702, 0xf917, 0x0000 },
  { 0x0702, 0xf919, 0x0000 },
  { 0x8702, 0xf91c, 0x2000 },
  { 0x0702, 0xf91b, 0x0000 },
  { 0x0702, 0xf91d, 0x0000 },
  { 0x8702, 0xf922, 0x3000 },
  { 0x8702, 0xf920, 0x2000 },
  { 0x0702, 0xf91f, 0x0000 },
  { 0x0702, 0xf921, 0x0000 },
  { 0x8702, 0xf924, 0x2000 },
  { 0x0702, 0xf923, 0x0000 },
  { 0x0702, 0xf925, 0x0000 },
  { 0x8702, 0xf92e, 0x4000 },
  { 0x8702, 0xf92a, 0x3000 },
  { 0x8702, 0xf928, 0x2000 },
  { 0x0702, 0xf927, 0x0000 },
  { 0x0702, 0xf929, 0x0000 },
  { 0x8702, 0xf92c, 0x2000 },
  { 0x0702, 0xf92b, 0x0000 },
  { 0x0702, 0xf92d, 0x0000 },
  { 0x8702, 0xf932, 0x3000 },
  { 0x8702, 0xf930, 0x2000 },
  { 0x0702, 0xf92f, 0x0000 },
  { 0x0702, 0xf931, 0x0000 },
  { 0x8702, 0xf934, 0x2000 },
  { 0x0702, 0xf933, 0x0000 },
  { 0x0702, 0xf935, 0x0000 },
  { 0x8702, 0xf956, 0x6000 },
  { 0x8702, 0xf946, 0x5000 },
  { 0x8702, 0xf93e, 0x4000 },
  { 0x8702, 0xf93a, 0x3000 },
  { 0x8702, 0xf938, 0x2000 },
  { 0x0702, 0xf937, 0x0000 },
  { 0x0702, 0xf939, 0x0000 },
  { 0x8702, 0xf93c, 0x2000 },
  { 0x0702, 0xf93b, 0x0000 },
  { 0x0702, 0xf93d, 0x0000 },
  { 0x8702, 0xf942, 0x3000 },
  { 0x8702, 0xf940, 0x2000 },
  { 0x0702, 0xf93f, 0x0000 },
  { 0x0702, 0xf941, 0x0000 },
  { 0x8702, 0xf944, 0x2000 },
  { 0x0702, 0xf943, 0x0000 },
  { 0x0702, 0xf945, 0x0000 },
  { 0x8702, 0xf94e, 0x4000 },
  { 0x8702, 0xf94a, 0x3000 },
  { 0x8702, 0xf948, 0x2000 },
  { 0x0702, 0xf947, 0x0000 },
  { 0x0702, 0xf949, 0x0000 },
  { 0x8702, 0xf94c, 0x2000 },
  { 0x0702, 0xf94b, 0x0000 },
  { 0x0702, 0xf94d, 0x0000 },
  { 0x8702, 0xf952, 0x3000 },
  { 0x8702, 0xf950, 0x2000 },
  { 0x0702, 0xf94f, 0x0000 },
  { 0x0702, 0xf951, 0x0000 },
  { 0x8702, 0xf954, 0x2000 },
  { 0x0702, 0xf953, 0x0000 },
  { 0x0702, 0xf955, 0x0000 },
  { 0x8702, 0xf966, 0x5000 },
  { 0x8702, 0xf95e, 0x4000 },
  { 0x8702, 0xf95a, 0x3000 },
  { 0x8702, 0xf958, 0x2000 },
  { 0x0702, 0xf957, 0x0000 },
  { 0x0702, 0xf959, 0x0000 },
  { 0x8702, 0xf95c, 0x2000 },
  { 0x0702, 0xf95b, 0x0000 },
  { 0x0702, 0xf95d, 0x0000 },
  { 0x8702, 0xf962, 0x3000 },
  { 0x8702, 0xf960, 0x2000 },
  { 0x0702, 0xf95f, 0x0000 },
  { 0x0702, 0xf961, 0x0000 },
  { 0x8702, 0xf964, 0x2000 },
  { 0x0702, 0xf963, 0x0000 },
  { 0x0702, 0xf965, 0x0000 },
  { 0x8702, 0xf96e, 0x4000 },
  { 0x8702, 0xf96a, 0x3000 },
  { 0x8702, 0xf968, 0x2000 },
  { 0x0702, 0xf967, 0x0000 },
  { 0x0702, 0xf969, 0x0000 },
  { 0x8702, 0xf96c, 0x2000 },
  { 0x0702, 0xf96b, 0x0000 },
  { 0x0702, 0xf96d, 0x0000 },
  { 0x8702, 0xf972, 0x3000 },
  { 0x8702, 0xf970, 0x2000 },
  { 0x0702, 0xf96f, 0x0000 },
  { 0x0702, 0xf971, 0x0000 },
  { 0x8702, 0xf974, 0x2000 },
  { 0x0702, 0xf973, 0x0000 },
  { 0x0702, 0xf975, 0x0000 },
  { 0x810e, 0x0077, 0x9000 },
  { 0x8702, 0xf9f6, 0x8000 },
  { 0x8702, 0xf9b6, 0x7000 },
  { 0x8702, 0xf996, 0x6000 },
  { 0x8702, 0xf986, 0x5000 },
  { 0x8702, 0xf97e, 0x4000 },
  { 0x8702, 0xf97a, 0x3000 },
  { 0x8702, 0xf978, 0x2000 },
  { 0x0702, 0xf977, 0x0000 },
  { 0x0702, 0xf979, 0x0000 },
  { 0x8702, 0xf97c, 0x2000 },
  { 0x0702, 0xf97b, 0x0000 },
  { 0x0702, 0xf97d, 0x0000 },
  { 0x8702, 0xf982, 0x3000 },
  { 0x8702, 0xf980, 0x2000 },
  { 0x0702, 0xf97f, 0x0000 },
  { 0x0702, 0xf981, 0x0000 },
  { 0x8702, 0xf984, 0x2000 },
  { 0x0702, 0xf983, 0x0000 },
  { 0x0702, 0xf985, 0x0000 },
  { 0x8702, 0xf98e, 0x4000 },
  { 0x8702, 0xf98a, 0x3000 },
  { 0x8702, 0xf988, 0x2000 },
  { 0x0702, 0xf987, 0x0000 },
  { 0x0702, 0xf989, 0x0000 },
  { 0x8702, 0xf98c, 0x2000 },
  { 0x0702, 0xf98b, 0x0000 },
  { 0x0702, 0xf98d, 0x0000 },
  { 0x8702, 0xf992, 0x3000 },
  { 0x8702, 0xf990, 0x2000 },
  { 0x0702, 0xf98f, 0x0000 },
  { 0x0702, 0xf991, 0x0000 },
  { 0x8702, 0xf994, 0x2000 },
  { 0x0702, 0xf993, 0x0000 },
  { 0x0702, 0xf995, 0x0000 },
  { 0x8702, 0xf9a6, 0x5000 },
  { 0x8702, 0xf99e, 0x4000 },
  { 0x8702, 0xf99a, 0x3000 },
  { 0x8702, 0xf998, 0x2000 },
  { 0x0702, 0xf997, 0x0000 },
  { 0x0702, 0xf999, 0x0000 },
  { 0x8702, 0xf99c, 0x2000 },
  { 0x0702, 0xf99b, 0x0000 },
  { 0x0702, 0xf99d, 0x0000 },
  { 0x8702, 0xf9a2, 0x3000 },
  { 0x8702, 0xf9a0, 0x2000 },
  { 0x0702, 0xf99f, 0x0000 },
  { 0x0702, 0xf9a1, 0x0000 },
  { 0x8702, 0xf9a4, 0x2000 },
  { 0x0702, 0xf9a3, 0x0000 },
  { 0x0702, 0xf9a5, 0x0000 },
  { 0x8702, 0xf9ae, 0x4000 },
  { 0x8702, 0xf9aa, 0x3000 },
  { 0x8702, 0xf9a8, 0x2000 },
  { 0x0702, 0xf9a7, 0x0000 },
  { 0x0702, 0xf9a9, 0x0000 },
  { 0x8702, 0xf9ac, 0x2000 },
  { 0x0702, 0xf9ab, 0x0000 },
  { 0x0702, 0xf9ad, 0x0000 },
  { 0x8702, 0xf9b2, 0x3000 },
  { 0x8702, 0xf9b0, 0x2000 },
  { 0x0702, 0xf9af, 0x0000 },
  { 0x0702, 0xf9b1, 0x0000 },
  { 0x8702, 0xf9b4, 0x2000 },
  { 0x0702, 0xf9b3, 0x0000 },
  { 0x0702, 0xf9b5, 0x0000 },
  { 0x8702, 0xf9d6, 0x6000 },
  { 0x8702, 0xf9c6, 0x5000 },
  { 0x8702, 0xf9be, 0x4000 },
  { 0x8702, 0xf9ba, 0x3000 },
  { 0x8702, 0xf9b8, 0x2000 },
  { 0x0702, 0xf9b7, 0x0000 },
  { 0x0702, 0xf9b9, 0x0000 },
  { 0x8702, 0xf9bc, 0x2000 },
  { 0x0702, 0xf9bb, 0x0000 },
  { 0x0702, 0xf9bd, 0x0000 },
  { 0x8702, 0xf9c2, 0x3000 },
  { 0x8702, 0xf9c0, 0x2000 },
  { 0x0702, 0xf9bf, 0x0000 },
  { 0x0702, 0xf9c1, 0x0000 },
  { 0x8702, 0xf9c4, 0x2000 },
  { 0x0702, 0xf9c3, 0x0000 },
  { 0x0702, 0xf9c5, 0x0000 },
  { 0x8702, 0xf9ce, 0x4000 },
  { 0x8702, 0xf9ca, 0x3000 },
  { 0x8702, 0xf9c8, 0x2000 },
  { 0x0702, 0xf9c7, 0x0000 },
  { 0x0702, 0xf9c9, 0x0000 },
  { 0x8702, 0xf9cc, 0x2000 },
  { 0x0702, 0xf9cb, 0x0000 },
  { 0x0702, 0xf9cd, 0x0000 },
  { 0x8702, 0xf9d2, 0x3000 },
  { 0x8702, 0xf9d0, 0x2000 },
  { 0x0702, 0xf9cf, 0x0000 },
  { 0x0702, 0xf9d1, 0x0000 },
  { 0x8702, 0xf9d4, 0x2000 },
  { 0x0702, 0xf9d3, 0x0000 },
  { 0x0702, 0xf9d5, 0x0000 },
  { 0x8702, 0xf9e6, 0x5000 },
  { 0x8702, 0xf9de, 0x4000 },
  { 0x8702, 0xf9da, 0x3000 },
  { 0x8702, 0xf9d8, 0x2000 },
  { 0x0702, 0xf9d7, 0x0000 },
  { 0x0702, 0xf9d9, 0x0000 },
  { 0x8702, 0xf9dc, 0x2000 },
  { 0x0702, 0xf9db, 0x0000 },
  { 0x0702, 0xf9dd, 0x0000 },
  { 0x8702, 0xf9e2, 0x3000 },
  { 0x8702, 0xf9e0, 0x2000 },
  { 0x0702, 0xf9df, 0x0000 },
  { 0x0702, 0xf9e1, 0x0000 },
  { 0x8702, 0xf9e4, 0x2000 },
  { 0x0702, 0xf9e3, 0x0000 },
  { 0x0702, 0xf9e5, 0x0000 },
  { 0x8702, 0xf9ee, 0x4000 },
  { 0x8702, 0xf9ea, 0x3000 },
  { 0x8702, 0xf9e8, 0x2000 },
  { 0x0702, 0xf9e7, 0x0000 },
  { 0x0702, 0xf9e9, 0x0000 },
  { 0x8702, 0xf9ec, 0x2000 },
  { 0x0702, 0xf9eb, 0x0000 },
  { 0x0702, 0xf9ed, 0x0000 },
  { 0x8702, 0xf9f2, 0x3000 },
  { 0x8702, 0xf9f0, 0x2000 },
  { 0x0702, 0xf9ef, 0x0000 },
  { 0x0702, 0xf9f1, 0x0000 },
  { 0x8702, 0xf9f4, 0x2000 },
  { 0x0702, 0xf9f3, 0x0000 },
  { 0x0702, 0xf9f5, 0x0000 },
  { 0x810e, 0x0037, 0x7000 },
  { 0x8702, 0xfa16, 0x6000 },
  { 0x8702, 0xfa06, 0x5000 },
  { 0x8702, 0xf9fe, 0x4000 },
  { 0x8702, 0xf9fa, 0x3000 },
  { 0x8702, 0xf9f8, 0x2000 },
  { 0x0702, 0xf9f7, 0x0000 },
  { 0x0702, 0xf9f9, 0x0000 },
  { 0x8702, 0xf9fc, 0x2000 },
  { 0x0702, 0xf9fb, 0x0000 },
  { 0x0702, 0xf9fd, 0x0000 },
  { 0x8702, 0xfa02, 0x3000 },
  { 0x8702, 0xfa00, 0x2000 },
  { 0x0702, 0xf9ff, 0x0000 },
  { 0x0702, 0xfa01, 0x0000 },
  { 0x8702, 0xfa04, 0x2000 },
  { 0x0702, 0xfa03, 0x0000 },
  { 0x0702, 0xfa05, 0x0000 },
  { 0x8702, 0xfa0e, 0x4000 },
  { 0x8702, 0xfa0a, 0x3000 },
  { 0x8702, 0xfa08, 0x2000 },
  { 0x0702, 0xfa07, 0x0000 },
  { 0x0702, 0xfa09, 0x0000 },
  { 0x8702, 0xfa0c, 0x2000 },
  { 0x0702, 0xfa0b, 0x0000 },
  { 0x0702, 0xfa0d, 0x0000 },
  { 0x8702, 0xfa12, 0x3000 },
  { 0x8702, 0xfa10, 0x2000 },
  { 0x0702, 0xfa0f, 0x0000 },
  { 0x0702, 0xfa11, 0x0000 },
  { 0x8702, 0xfa14, 0x2000 },
  { 0x0702, 0xfa13, 0x0000 },
  { 0x0702, 0xfa15, 0x0000 },
  { 0x810e, 0x0027, 0x5000 },
  { 0x810e, 0x0001, 0x4000 },
  { 0x8702, 0xfa1a, 0x3000 },
  { 0x8702, 0xfa18, 0x2000 },
  { 0x0702, 0xfa17, 0x0000 },
  { 0x0702, 0xfa19, 0x0000 },
  { 0x8702, 0xfa1c, 0x2000 },
  { 0x0702, 0xfa1b, 0x0000 },
  { 0x0702, 0xfa1d, 0x0000 },
  { 0x810e, 0x0023, 0x3000 },
  { 0x810e, 0x0021, 0x2000 },
  { 0x010e, 0x0020, 0x0000 },
  { 0x010e, 0x0022, 0x0000 },
  { 0x810e, 0x0025, 0x2000 },
  { 0x010e, 0x0024, 0x0000 },
  { 0x010e, 0x0026, 0x0000 },
  { 0x810e, 0x002f, 0x4000 },
  { 0x810e, 0x002b, 0x3000 },
  { 0x810e, 0x0029, 0x2000 },
  { 0x010e, 0x0028, 0x0000 },
  { 0x010e, 0x002a, 0x0000 },
  { 0x810e, 0x002d, 0x2000 },
  { 0x010e, 0x002c, 0x0000 },
  { 0x010e, 0x002e, 0x0000 },
  { 0x810e, 0x0033, 0x3000 },
  { 0x810e, 0x0031, 0x2000 },
  { 0x010e, 0x0030, 0x0000 },
  { 0x010e, 0x0032, 0x0000 },
  { 0x810e, 0x0035, 0x2000 },
  { 0x010e, 0x0034, 0x0000 },
  { 0x010e, 0x0036, 0x0000 },
  { 0x810e, 0x0057, 0x6000 },
  { 0x810e, 0x0047, 0x5000 },
  { 0x810e, 0x003f, 0x4000 },
  { 0x810e, 0x003b, 0x3000 },
  { 0x810e, 0x0039, 0x2000 },
  { 0x010e, 0x0038, 0x0000 },
  { 0x010e, 0x003a, 0x0000 },
  { 0x810e, 0x003d, 0x2000 },
  { 0x010e, 0x003c, 0x0000 },
  { 0x010e, 0x003e, 0x0000 },
  { 0x810e, 0x0043, 0x3000 },
  { 0x810e, 0x0041, 0x2000 },
  { 0x010e, 0x0040, 0x0000 },
  { 0x010e, 0x0042, 0x0000 },
  { 0x810e, 0x0045, 0x2000 },
  { 0x010e, 0x0044, 0x0000 },
  { 0x010e, 0x0046, 0x0000 },
  { 0x810e, 0x004f, 0x4000 },
  { 0x810e, 0x004b, 0x3000 },
  { 0x810e, 0x0049, 0x2000 },
  { 0x010e, 0x0048, 0x0000 },
  { 0x010e, 0x004a, 0x0000 },
  { 0x810e, 0x004d, 0x2000 },
  { 0x010e, 0x004c, 0x0000 },
  { 0x010e, 0x004e, 0x0000 },
  { 0x810e, 0x0053, 0x3000 },
  { 0x810e, 0x0051, 0x2000 },
  { 0x010e, 0x0050, 0x0000 },
  { 0x010e, 0x0052, 0x0000 },
  { 0x810e, 0x0055, 0x2000 },
  { 0x010e, 0x0054, 0x0000 },
  { 0x010e, 0x0056, 0x0000 },
  { 0x810e, 0x0067, 0x5000 },
  { 0x810e, 0x005f, 0x4000 },
  { 0x810e, 0x005b, 0x3000 },
  { 0x810e, 0x0059, 0x2000 },
  { 0x010e, 0x0058, 0x0000 },
  { 0x010e, 0x005a, 0x0000 },
  { 0x810e, 0x005d, 0x2000 },
  { 0x010e, 0x005c, 0x0000 },
  { 0x010e, 0x005e, 0x0000 },
  { 0x810e, 0x0063, 0x3000 },
  { 0x810e, 0x0061, 0x2000 },
  { 0x010e, 0x0060, 0x0000 },
  { 0x010e, 0x0062, 0x0000 },
  { 0x810e, 0x0065, 0x2000 },
  { 0x010e, 0x0064, 0x0000 },
  { 0x010e, 0x0066, 0x0000 },
  { 0x810e, 0x006f, 0x4000 },
  { 0x810e, 0x006b, 0x3000 },
  { 0x810e, 0x0069, 0x2000 },
  { 0x010e, 0x0068, 0x0000 },
  { 0x010e, 0x006a, 0x0000 },
  { 0x810e, 0x006d, 0x2000 },
  { 0x010e, 0x006c, 0x0000 },
  { 0x010e, 0x006e, 0x0000 },
  { 0x810e, 0x0073, 0x3000 },
  { 0x810e, 0x0071, 0x2000 },
  { 0x010e, 0x0070, 0x0000 },
  { 0x010e, 0x0072, 0x0000 },
  { 0x810e, 0x0075, 0x2000 },
  { 0x010e, 0x0074, 0x0000 },
  { 0x010e, 0x0076, 0x0000 },
  { 0x8c0e, 0x0177, 0x8000 },
  { 0x8c0e, 0x0137, 0x7000 },
  { 0x8c0e, 0x0117, 0x6000 },
  { 0x8c0e, 0x0107, 0x5000 },
  { 0x810e, 0x007f, 0x4000 },
  { 0x810e, 0x007b, 0x3000 },
  { 0x810e, 0x0079, 0x2000 },
  { 0x010e, 0x0078, 0x0000 },
  { 0x010e, 0x007a, 0x0000 },
  { 0x810e, 0x007d, 0x2000 },
  { 0x010e, 0x007c, 0x0000 },
  { 0x010e, 0x007e, 0x0000 },
  { 0x8c0e, 0x0103, 0x3000 },
  { 0x8c0e, 0x0101, 0x2000 },
  { 0x0c0e, 0x0100, 0x0000 },
  { 0x0c0e, 0x0102, 0x0000 },
  { 0x8c0e, 0x0105, 0x2000 },
  { 0x0c0e, 0x0104, 0x0000 },
  { 0x0c0e, 0x0106, 0x0000 },
  { 0x8c0e, 0x010f, 0x4000 },
  { 0x8c0e, 0x010b, 0x3000 },
  { 0x8c0e, 0x0109, 0x2000 },
  { 0x0c0e, 0x0108, 0x0000 },
  { 0x0c0e, 0x010a, 0x0000 },
  { 0x8c0e, 0x010d, 0x2000 },
  { 0x0c0e, 0x010c, 0x0000 },
  { 0x0c0e, 0x010e, 0x0000 },
  { 0x8c0e, 0x0113, 0x3000 },
  { 0x8c0e, 0x0111, 0x2000 },
  { 0x0c0e, 0x0110, 0x0000 },
  { 0x0c0e, 0x0112, 0x0000 },
  { 0x8c0e, 0x0115, 0x2000 },
  { 0x0c0e, 0x0114, 0x0000 },
  { 0x0c0e, 0x0116, 0x0000 },
  { 0x8c0e, 0x0127, 0x5000 },
  { 0x8c0e, 0x011f, 0x4000 },
  { 0x8c0e, 0x011b, 0x3000 },
  { 0x8c0e, 0x0119, 0x2000 },
  { 0x0c0e, 0x0118, 0x0000 },
  { 0x0c0e, 0x011a, 0x0000 },
  { 0x8c0e, 0x011d, 0x2000 },
  { 0x0c0e, 0x011c, 0x0000 },
  { 0x0c0e, 0x011e, 0x0000 },
  { 0x8c0e, 0x0123, 0x3000 },
  { 0x8c0e, 0x0121, 0x2000 },
  { 0x0c0e, 0x0120, 0x0000 },
  { 0x0c0e, 0x0122, 0x0000 },
  { 0x8c0e, 0x0125, 0x2000 },
  { 0x0c0e, 0x0124, 0x0000 },
  { 0x0c0e, 0x0126, 0x0000 },
  { 0x8c0e, 0x012f, 0x4000 },
  { 0x8c0e, 0x012b, 0x3000 },
  { 0x8c0e, 0x0129, 0x2000 },
  { 0x0c0e, 0x0128, 0x0000 },
  { 0x0c0e, 0x012a, 0x0000 },
  { 0x8c0e, 0x012d, 0x2000 },
  { 0x0c0e, 0x012c, 0x0000 },
  { 0x0c0e, 0x012e, 0x0000 },
  { 0x8c0e, 0x0133, 0x3000 },
  { 0x8c0e, 0x0131, 0x2000 },
  { 0x0c0e, 0x0130, 0x0000 },
  { 0x0c0e, 0x0132, 0x0000 },
  { 0x8c0e, 0x0135, 0x2000 },
  { 0x0c0e, 0x0134, 0x0000 },
  { 0x0c0e, 0x0136, 0x0000 },
  { 0x8c0e, 0x0157, 0x6000 },
  { 0x8c0e, 0x0147, 0x5000 },
  { 0x8c0e, 0x013f, 0x4000 },
  { 0x8c0e, 0x013b, 0x3000 },
  { 0x8c0e, 0x0139, 0x2000 },
  { 0x0c0e, 0x0138, 0x0000 },
  { 0x0c0e, 0x013a, 0x0000 },
  { 0x8c0e, 0x013d, 0x2000 },
  { 0x0c0e, 0x013c, 0x0000 },
  { 0x0c0e, 0x013e, 0x0000 },
  { 0x8c0e, 0x0143, 0x3000 },
  { 0x8c0e, 0x0141, 0x2000 },
  { 0x0c0e, 0x0140, 0x0000 },
  { 0x0c0e, 0x0142, 0x0000 },
  { 0x8c0e, 0x0145, 0x2000 },
  { 0x0c0e, 0x0144, 0x0000 },
  { 0x0c0e, 0x0146, 0x0000 },
  { 0x8c0e, 0x014f, 0x4000 },
  { 0x8c0e, 0x014b, 0x3000 },
  { 0x8c0e, 0x0149, 0x2000 },
  { 0x0c0e, 0x0148, 0x0000 },
  { 0x0c0e, 0x014a, 0x0000 },
  { 0x8c0e, 0x014d, 0x2000 },
  { 0x0c0e, 0x014c, 0x0000 },
  { 0x0c0e, 0x014e, 0x0000 },
  { 0x8c0e, 0x0153, 0x3000 },
  { 0x8c0e, 0x0151, 0x2000 },
  { 0x0c0e, 0x0150, 0x0000 },
  { 0x0c0e, 0x0152, 0x0000 },
  { 0x8c0e, 0x0155, 0x2000 },
  { 0x0c0e, 0x0154, 0x0000 },
  { 0x0c0e, 0x0156, 0x0000 },
  { 0x8c0e, 0x0167, 0x5000 },
  { 0x8c0e, 0x015f, 0x4000 },
  { 0x8c0e, 0x015b, 0x3000 },
  { 0x8c0e, 0x0159, 0x2000 },
  { 0x0c0e, 0x0158, 0x0000 },
  { 0x0c0e, 0x015a, 0x0000 },
  { 0x8c0e, 0x015d, 0x2000 },
  { 0x0c0e, 0x015c, 0x0000 },
  { 0x0c0e, 0x015e, 0x0000 },
  { 0x8c0e, 0x0163, 0x3000 },
  { 0x8c0e, 0x0161, 0x2000 },
  { 0x0c0e, 0x0160, 0x0000 },
  { 0x0c0e, 0x0162, 0x0000 },
  { 0x8c0e, 0x0165, 0x2000 },
  { 0x0c0e, 0x0164, 0x0000 },
  { 0x0c0e, 0x0166, 0x0000 },
  { 0x8c0e, 0x016f, 0x4000 },
  { 0x8c0e, 0x016b, 0x3000 },
  { 0x8c0e, 0x0169, 0x2000 },
  { 0x0c0e, 0x0168, 0x0000 },
  { 0x0c0e, 0x016a, 0x0000 },
  { 0x8c0e, 0x016d, 0x2000 },
  { 0x0c0e, 0x016c, 0x0000 },
  { 0x0c0e, 0x016e, 0x0000 },
  { 0x8c0e, 0x0173, 0x3000 },
  { 0x8c0e, 0x0171, 0x2000 },
  { 0x0c0e, 0x0170, 0x0000 },
  { 0x0c0e, 0x0172, 0x0000 },
  { 0x8c0e, 0x0175, 0x2000 },
  { 0x0c0e, 0x0174, 0x0000 },
  { 0x0c0e, 0x0176, 0x0000 },
  { 0x8c0e, 0x01b7, 0x7000 },
  { 0x8c0e, 0x0197, 0x6000 },
  { 0x8c0e, 0x0187, 0x5000 },
  { 0x8c0e, 0x017f, 0x4000 },
  { 0x8c0e, 0x017b, 0x3000 },
  { 0x8c0e, 0x0179, 0x2000 },
  { 0x0c0e, 0x0178, 0x0000 },
  { 0x0c0e, 0x017a, 0x0000 },
  { 0x8c0e, 0x017d, 0x2000 },
  { 0x0c0e, 0x017c, 0x0000 },
  { 0x0c0e, 0x017e, 0x0000 },
  { 0x8c0e, 0x0183, 0x3000 },
  { 0x8c0e, 0x0181, 0x2000 },
  { 0x0c0e, 0x0180, 0x0000 },
  { 0x0c0e, 0x0182, 0x0000 },
  { 0x8c0e, 0x0185, 0x2000 },
  { 0x0c0e, 0x0184, 0x0000 },
  { 0x0c0e, 0x0186, 0x0000 },
  { 0x8c0e, 0x018f, 0x4000 },
  { 0x8c0e, 0x018b, 0x3000 },
  { 0x8c0e, 0x0189, 0x2000 },
  { 0x0c0e, 0x0188, 0x0000 },
  { 0x0c0e, 0x018a, 0x0000 },
  { 0x8c0e, 0x018d, 0x2000 },
  { 0x0c0e, 0x018c, 0x0000 },
  { 0x0c0e, 0x018e, 0x0000 },
  { 0x8c0e, 0x0193, 0x3000 },
  { 0x8c0e, 0x0191, 0x2000 },
  { 0x0c0e, 0x0190, 0x0000 },
  { 0x0c0e, 0x0192, 0x0000 },
  { 0x8c0e, 0x0195, 0x2000 },
  { 0x0c0e, 0x0194, 0x0000 },
  { 0x0c0e, 0x0196, 0x0000 },
  { 0x8c0e, 0x01a7, 0x5000 },
  { 0x8c0e, 0x019f, 0x4000 },
  { 0x8c0e, 0x019b, 0x3000 },
  { 0x8c0e, 0x0199, 0x2000 },
  { 0x0c0e, 0x0198, 0x0000 },
  { 0x0c0e, 0x019a, 0x0000 },
  { 0x8c0e, 0x019d, 0x2000 },
  { 0x0c0e, 0x019c, 0x0000 },
  { 0x0c0e, 0x019e, 0x0000 },
  { 0x8c0e, 0x01a3, 0x3000 },
  { 0x8c0e, 0x01a1, 0x2000 },
  { 0x0c0e, 0x01a0, 0x0000 },
  { 0x0c0e, 0x01a2, 0x0000 },
  { 0x8c0e, 0x01a5, 0x2000 },
  { 0x0c0e, 0x01a4, 0x0000 },
  { 0x0c0e, 0x01a6, 0x0000 },
  { 0x8c0e, 0x01af, 0x4000 },
  { 0x8c0e, 0x01ab, 0x3000 },
  { 0x8c0e, 0x01a9, 0x2000 },
  { 0x0c0e, 0x01a8, 0x0000 },
  { 0x0c0e, 0x01aa, 0x0000 },
  { 0x8c0e, 0x01ad, 0x2000 },
  { 0x0c0e, 0x01ac, 0x0000 },
  { 0x0c0e, 0x01ae, 0x0000 },
  { 0x8c0e, 0x01b3, 0x3000 },
  { 0x8c0e, 0x01b1, 0x2000 },
  { 0x0c0e, 0x01b0, 0x0000 },
  { 0x0c0e, 0x01b2, 0x0000 },
  { 0x8c0e, 0x01b5, 0x2000 },
  { 0x0c0e, 0x01b4, 0x0000 },
  { 0x0c0e, 0x01b6, 0x0000 },
  { 0x8c0e, 0x01d7, 0x6000 },
  { 0x8c0e, 0x01c7, 0x5000 },
  { 0x8c0e, 0x01bf, 0x4000 },
  { 0x8c0e, 0x01bb, 0x3000 },
  { 0x8c0e, 0x01b9, 0x2000 },
  { 0x0c0e, 0x01b8, 0x0000 },
  { 0x0c0e, 0x01ba, 0x0000 },
  { 0x8c0e, 0x01bd, 0x2000 },
  { 0x0c0e, 0x01bc, 0x0000 },
  { 0x0c0e, 0x01be, 0x0000 },
  { 0x8c0e, 0x01c3, 0x3000 },
  { 0x8c0e, 0x01c1, 0x2000 },
  { 0x0c0e, 0x01c0, 0x0000 },
  { 0x0c0e, 0x01c2, 0x0000 },
  { 0x8c0e, 0x01c5, 0x2000 },
  { 0x0c0e, 0x01c4, 0x0000 },
  { 0x0c0e, 0x01c6, 0x0000 },
  { 0x8c0e, 0x01cf, 0x4000 },
  { 0x8c0e, 0x01cb, 0x3000 },
  { 0x8c0e, 0x01c9, 0x2000 },
  { 0x0c0e, 0x01c8, 0x0000 },
  { 0x0c0e, 0x01ca, 0x0000 },
  { 0x8c0e, 0x01cd, 0x2000 },
  { 0x0c0e, 0x01cc, 0x0000 },
  { 0x0c0e, 0x01ce, 0x0000 },
  { 0x8c0e, 0x01d3, 0x3000 },
  { 0x8c0e, 0x01d1, 0x2000 },
  { 0x0c0e, 0x01d0, 0x0000 },
  { 0x0c0e, 0x01d2, 0x0000 },
  { 0x8c0e, 0x01d5, 0x2000 },
  { 0x0c0e, 0x01d4, 0x0000 },
  { 0x0c0e, 0x01d6, 0x0000 },
  { 0x8c0e, 0x01e7, 0x5000 },
  { 0x8c0e, 0x01df, 0x4000 },
  { 0x8c0e, 0x01db, 0x3000 },
  { 0x8c0e, 0x01d9, 0x2000 },
  { 0x0c0e, 0x01d8, 0x0000 },
  { 0x0c0e, 0x01da, 0x0000 },
  { 0x8c0e, 0x01dd, 0x2000 },
  { 0x0c0e, 0x01dc, 0x0000 },
  { 0x0c0e, 0x01de, 0x0000 },
  { 0x8c0e, 0x01e3, 0x3000 },
  { 0x8c0e, 0x01e1, 0x2000 },
  { 0x0c0e, 0x01e0, 0x0000 },
  { 0x0c0e, 0x01e2, 0x0000 },
  { 0x8c0e, 0x01e5, 0x2000 },
  { 0x0c0e, 0x01e4, 0x0000 },
  { 0x0c0e, 0x01e6, 0x0000 },
  { 0x8c0e, 0x01ef, 0x4000 },
  { 0x8c0e, 0x01eb, 0x3000 },
  { 0x8c0e, 0x01e9, 0x2000 },
  { 0x0c0e, 0x01e8, 0x0000 },
  { 0x0c0e, 0x01ea, 0x0000 },
  { 0x8c0e, 0x01ed, 0x2000 },
  { 0x0c0e, 0x01ec, 0x0000 },
  { 0x0c0e, 0x01ee, 0x0000 },
  { 0x830f, 0xfffd, 0x2000 },
  { 0x030f, 0x0000, 0x0000 },
  { 0x0310, 0x0000, 0x1000 },
  { 0x0310, 0xfffd, 0x0000 },
};


/* In some environments, external functions have to be preceded by some magic.
In my world (Unix), they do not. Use a macro to deal with this. */

#ifndef EXPORT
#define EXPORT
#endif



/*************************************************
*         Search table and return data           *
*************************************************/

/* Two values are returned: the category is ucp_C, ucp_L, etc. The detailed
character type is ucp_Lu, ucp_Nd, etc.

Arguments:
  c           the character value
  type_ptr    the detailed character type is returned here
  case_ptr    for letters, the opposite case is returned here, if there
                is one, else zero

Returns:      the character type category or -1 if not found
*/

EXPORT int
ucp_findchar(const int c, int *type_ptr, int *case_ptr)
{
cnode *node = ucp_table;
register int cc = c;
int case_offset;

for (;;)
  {
  register int d = node->f1 | ((node->f0 & f0_chhmask) << 16);
  if (cc == d) break;
  if (cc < d)
    {
    if ((node->f0 & f0_leftexists) == 0) return -1;
    node ++;
    }
  else
    {
    register int roffset = (node->f2 & f2_rightmask) >> f2_rightshift;
    if (roffset == 0) return -1;
    node += 1 << (roffset - 1);
    }
  }

switch ((*type_ptr = ((node->f0 & f0_typemask) >> f0_typeshift)))
  {
  case ucp_Cc:
  case ucp_Cf:
  case ucp_Cn:
  case ucp_Co:
  case ucp_Cs:
  return ucp_C;
  break;

  case ucp_Ll:
  case ucp_Lu:
  case_offset = node->f2 & f2_casemask;
  if ((case_offset & 0x0100) != 0) case_offset |= 0xfffff000;
  *case_ptr = (case_offset == 0)? 0 : cc + case_offset;
  return ucp_L;

  case ucp_Lm:
  case ucp_Lo:
  case ucp_Lt:
  *case_ptr = 0;
  return ucp_L;
  break;

  case ucp_Mc:
  case ucp_Me:
  case ucp_Mn:
  return ucp_M;
  break;

  case ucp_Nd:
  case ucp_Nl:
  case ucp_No:
  return ucp_N;
  break;

  case ucp_Pc:
  case ucp_Pd:
  case ucp_Pe:
  case ucp_Pf:
  case ucp_Pi:
  case ucp_Ps:
  case ucp_Po:
  return ucp_P;
  break;

  case ucp_Sc:
  case ucp_Sk:
  case ucp_Sm:
  case ucp_So:
  return ucp_S;
  break;

  case ucp_Zl:
  case ucp_Zp:
  case ucp_Zs:
  return ucp_Z;
  break;

  default:         /* "Should never happen" */
  return -1;
  break;
  }
}

/* End of ucp_findchar.c */


/* End of pcre_ucp_findchar.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains an internal function for validating UTF-8 character
strings. */




/*************************************************
*         Validate a UTF-8 string                *
*************************************************/

/* This function is called (optionally) at the start of compile or match, to
validate that a supposed UTF-8 string is actually valid. The early check means
that subsequent code can assume it is dealing with a valid string. The check
can be turned off for maximum performance, but the consequences of supplying
an invalid string are then undefined.

Arguments:
  string       points to the string
  length       length of string, or -1 if the string is zero-terminated

Returns:       < 0    if the string is a valid UTF-8 string
               >= 0   otherwise; the value is the offset of the bad byte
*/

EXPORT int
_pcre_valid_utf8(const uschar *string, int length)
{
register const uschar *p;

if (length < 0)
  {
  for (p = string; *p != 0; p++);
  length = p - string;
  }

for (p = string; length-- > 0; p++)
  {
  register int ab;
  register int c = *p;
  if (c < 128) continue;
  if ((c & 0xc0) != 0xc0) return p - string;
  ab = _pcre_utf8_table4[c & 0x3f];  /* Number of additional bytes */
  if (length < ab) return p - string;
  length -= ab;

  /* Check top bits in the second byte */
  if ((*(++p) & 0xc0) != 0x80) return p - string;

  /* Check for overlong sequences for each different length */
  switch (ab)
    {
    /* Check for xx00 000x */
    case 1:
    if ((c & 0x3e) == 0) return p - string;
    continue;   /* We know there aren't any more bytes to check */

    /* Check for 1110 0000, xx0x xxxx */
    case 2:
    if (c == 0xe0 && (*p & 0x20) == 0) return p - string;
    break;

    /* Check for 1111 0000, xx00 xxxx */
    case 3:
    if (c == 0xf0 && (*p & 0x30) == 0) return p - string;
    break;

    /* Check for 1111 1000, xx00 0xxx */
    case 4:
    if (c == 0xf8 && (*p & 0x38) == 0) return p - string;
    break;

    /* Check for leading 0xfe or 0xff, and then for 1111 1100, xx00 00xx */
    case 5:
    if (c == 0xfe || c == 0xff ||
       (c == 0xfc && (*p & 0x3c) == 0)) return p - string;
    break;
    }

  /* Check for valid bytes after the 2nd, if any; all must start 10 */
  while (--ab > 0)
    {
    if ((*(++p) & 0xc0) != 0x80) return p - string;
    }
  }

return -1;
}

/* End of pcre_valid_utf8.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains the external function pcre_version(), which returns a
string that identifies the PCRE version that is in use. */




/*************************************************
*          Return version string                 *
*************************************************/

#define STRING(a)  # a
#define XSTRING(s) STRING(s)

EXPORT const char *
pcre_version(void)
{
return XSTRING(PCRE_MAJOR) "." XSTRING(PCRE_MINOR) " " XSTRING(PCRE_DATE);
}

/* End of pcre_version.c */
/*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language.

                       Written by Philip Hazel
           Copyright (c) 1997-2005 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/


/* This module contains an internal function that is used to match an extended
class (one that contains characters whose values are > 255). It is used by both
pcre_exec() and pcre_def_exec(). */




/*************************************************
*       Match character against an XCLASS        *
*************************************************/

/* This function is called to match a character against an extended class that
might contain values > 255.

Arguments:
  c           the character
  data        points to the flag byte of the XCLASS data

Returns:      TRUE if character matches, else FALSE
*/

EXPORT BOOL
_pcre_xclass(int c, const uschar *data)
{
int t;
BOOL negated = (*data & XCL_NOT) != 0;

/* Character values < 256 are matched against a bitmap, if one is present. If
not, we still carry on, because there may be ranges that start below 256 in the
additional data. */

if (c < 256)
  {
  if ((*data & XCL_MAP) != 0 && (data[1 + c/8] & (1 << (c&7))) != 0)
    return !negated;   /* char found */
  }

/* First skip the bit map if present. Then match against the list of Unicode
properties or large chars or ranges that end with a large char. We won't ever
encounter XCL_PROP or XCL_NOTPROP when UCP support is not compiled. */

if ((*data++ & XCL_MAP) != 0) data += 32;

while ((t = *data++) != XCL_END)
  {
  int x, y;
  if (t == XCL_SINGLE)
    {
    GETCHARINC(x, data);
    if (c == x) return !negated;
    }
  else if (t == XCL_RANGE)
    {
    GETCHARINC(x, data);
    GETCHARINC(y, data);
    if (c >= x && c <= y) return !negated;
    }

#ifdef SUPPORT_UCP
  else  /* XCL_PROP & XCL_NOTPROP */
    {
    int chartype, othercase;
    int rqdtype = *data++;
    int category = ucp_findchar(c, &chartype, &othercase);
    if (rqdtype >= 128)
      {
      if ((rqdtype - 128 == category) == (t == XCL_PROP)) return !negated;
      }
    else
      {
      if ((rqdtype == chartype) == (t == XCL_PROP)) return !negated;
      }
    }
#endif  /* SUPPORT_UCP */
  }

return negated;   /* char did not match */
}

/* End of pcre_xclass.c */
