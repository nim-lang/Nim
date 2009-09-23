/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.ac by autoheader.  */

/* Define to one of `_getb67', `GETB67', `getb67' for Cray-2 and Cray-YMP
   systems. This function is required for `alloca.c' support on those systems.
   */
/* #undef CRAY_STACKSEG_END */

/* Define to 1 if using `alloca.c'. */
/* #undef C_ALLOCA */

/* Define to 1 if translation of program messages to the user's native
   language is requested. */
#define ENABLE_NLS 1

/* Define to 1 if you have `alloca', as a function or macro. */
/* #undef HAVE_ALLOCA */

/* Define to 1 if you have <alloca.h> and it should be used (not on Ultrix).
   */
/* #undef HAVE_ALLOCA_H */

/* Define to 1 if you have the MacOS X function CFLocaleCopyCurrent in the
   CoreFoundation framework. */
#define HAVE_CFLOCALECOPYCURRENT 1

/* Define to 1 if you have the MacOS X function CFPreferencesCopyAppValue in
   the CoreFoundation framework. */
#define HAVE_CFPREFERENCESCOPYAPPVALUE 1

/* Define if the GNU dcgettext() function is already present or preinstalled.
   */
#define HAVE_DCGETTEXT 1

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* Define to 1 if you have the <getopt.h> header file. */
#define HAVE_GETOPT_H 1

/* Define to 1 if you have the `getopt_long' function. */
#define HAVE_GETOPT_LONG 1

/* Define if the GNU gettext() function is already present or preinstalled. */
#define HAVE_GETTEXT 1

/* Define if you have the iconv() function and it works. */
#define HAVE_ICONV 1

/* Define to 1 if you have the <inttypes.h> header file. */
/* #undef HAVE_INTTYPES_H */

/* Define to 1 if you have the `isascii' function. */
#define HAVE_ISASCII 1

/* Define to 1 if you have the `isblank' function. */
#define HAVE_ISBLANK 1

/* Define to 1 if you have the `iswascii' function or macro. */
/* #undef HAVE_ISWASCII */

/* Define to 1 if you have the `iswblank' function or macro. */
/* #undef HAVE_ISWBLANK */

/* Define to 1 if you have the `iswctype' function or macro. */
/* #undef HAVE_ISWCTYPE */

/* Define to 1 if you have the `iswlower' function or macro. */
/* #undef HAVE_ISWLOWER */

/* Define to 1 if you have the `iswupper' function or macro. */
/* #undef HAVE_ISWUPPER */

/* Define to 1 if you have the <libutf8.h> header file. */
/* #undef HAVE_LIBUTF8_H */

/* Define to 1 if you have the `mbrtowc' function or macro. */
/* #undef HAVE_MBRTOWC */

/* Define to 1 if the system has the type `mbstate_t'. */
/* #undef HAVE_MBSTATE_T */

/* Define to 1 if you have the `mbtowc' function or macro. */
/* #undef HAVE_MBTOWC */

/* Define to 1 if you have the <memory.h> header file. */
/* #undef HAVE_MEMORY_H */

/* Define to 1 if you have the <regex.h> header file. */
/* #undef HAVE_REGEX_H */

/* Define to 1 if the system has the type `reg_errcode_t'. */
/* #undef HAVE_REG_ERRCODE_T */

/* Define to 1 if you have the <stdint.h> header file. */
/* #undef HAVE_STDINT_H */

/* Define to 1 if you have the <stdlib.h> header file. */
/* #undef HAVE_STDLIB_H */

/* Define to 1 if you have the <strings.h> header file. */
/* #undef HAVE_STRINGS_H */

/* Define to 1 if you have the <string.h> header file. */
/* #undef HAVE_STRING_H */

/* Define to 1 if you have the <sys/stat.h> header file. */
/* #undef HAVE_SYS_STAT_H */

/* Define to 1 if you have the <sys/types.h> header file. */
/* #undef HAVE_SYS_TYPES_H */

/* Define to 1 if you have the `towlower' function or macro. */
/* #undef HAVE_TOWLOWER */

/* Define to 1 if you have the `towupper' function or macro. */
/* #undef HAVE_TOWUPPER */

/* Define to 1 if you have the <unistd.h> header file. */
/* #undef HAVE_UNISTD_H */

/* Define to 1 if you have the <wchar.h> header file. */
/* #undef HAVE_WCHAR_H */

/* Define to 1 if the system has the type `wchar_t'. */
/* #undef HAVE_WCHAR_T */

/* Define to 1 if you have the `wcschr' function or macro. */
/* #undef HAVE_WCSCHR */

/* Define to 1 if you have the `wcscpy' function or macro. */
/* #undef HAVE_WCSCPY */

/* Define to 1 if you have the `wcslen' function or macro. */
/* #undef HAVE_WCSLEN */

/* Define to 1 if you have the `wcsncpy' function or macro. */
/* #undef HAVE_WCSNCPY */

/* Define to 1 if you have the `wcsrtombs' function or macro. */
/* #undef HAVE_WCSRTOMBS */

/* Define to 1 if you have the `wcstombs' function or macro. */
/* #undef HAVE_WCSTOMBS */

/* Define to 1 if you have the `wctype' function or macro. */
/* #undef HAVE_WCTYPE */

/* Define to 1 if you have the <wctype.h> header file. */
/* #undef HAVE_WCTYPE_H */

/* Define to 1 if the system has the type `wint_t'. */
/* #undef HAVE_WINT_T */

/* Define if you want to disable debug assertions. */
#define NDEBUG 1

/* Define to 1 if your C compiler doesn't accept -c and -o together. */
/* #undef NO_MINUS_C_MINUS_O */

/* Name of package */
#define PACKAGE "tre"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "tre-general@lists.laurikari.net"

/* Define to the full name of this package. */
#define PACKAGE_NAME "TRE"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "TRE 0.7.6"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "tre"

/* Define to the version of this package. */
#define PACKAGE_VERSION "0.7.6"

/* If using the C implementation of alloca, define if you know the
   direction of stack growth for your system; otherwise it will be
   automatically deduced at runtime.
	STACK_DIRECTION > 0 => grows toward higher addresses
	STACK_DIRECTION < 0 => grows toward lower addresses
	STACK_DIRECTION = 0 => direction of growth unknown */
/* #undef STACK_DIRECTION */

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Define if you want to enable approximate matching functionality. */
/* #undef TRE_APPROX */

/* Define if you want TRE to print debug messages to stdout. */
/* #undef TRE_DEBUG */

/* Define to enable multibyte character set support. */
/* #undef TRE_MULTIBYTE */

/* Define to a field in the regex_t struct where TRE should store a pointer to
   the internal tre_tnfa_t structure */
#define TRE_REGEX_T_FIELD value

/* Define to the absolute path to the system regex.h */
/* #undef TRE_SYSTEM_REGEX_H_PATH */

/* Define if you want TRE to use alloca() instead of malloc() when allocating
   memory needed for regexec operations. */
/* #undef TRE_USE_ALLOCA */

/* Define to include the system regex.h from TRE regex.h */
/* #undef TRE_USE_SYSTEM_REGEX_H */

/* TRE version string. */
#define TRE_VERSION "0.7.6"

/* TRE version level 1. */
#define TRE_VERSION_1 0

/* TRE version level 2. */
#define TRE_VERSION_2 7

/* TRE version level 3. */
#define TRE_VERSION_3 6

/* Define to enable wide character (wchar_t) support. */
/* #undef TRE_WCHAR */

/* Version number of package */
#define VERSION "0.7.6"

/* Define to the maximum value of wchar_t if not already defined elsewhere */
/* #undef WCHAR_MAX */

/* Define if wchar_t is signed */
/* #undef WCHAR_T_SIGNED */

/* Define if wchar_t is unsigned */
/* #undef WCHAR_T_UNSIGNED */

/* Number of bits in a file offset, on hosts where this is settable. */
/* #undef _FILE_OFFSET_BITS */

/* Define to enable GNU extensions in glibc */
#define _GNU_SOURCE 1

/* Define for large files, on AIX-style hosts. */
/* #undef _LARGE_FILES */

/* Define on IRIX */
/* #undef _REGCOMP_INTERNAL */

/* Define to empty if `const' does not conform to ANSI C. */
/* #undef const */

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus
/* #undef inline */
#endif
