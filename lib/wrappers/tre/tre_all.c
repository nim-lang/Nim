/*
  regcomp.c - TRE POSIX compatible regex compilation functions.

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

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


#include <string.h>
#include <errno.h>
#include <stdlib.h>

/*
  regex.h - POSIX.2 compatible regexp interface and TRE extensions

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

#ifndef TRE_REGEX_H
#define TRE_REGEX_H 1

/* lib/tre-config.h.  Generated from tre-config.h.in by configure.  */
/* tre-config.h.in.  This file has all definitions that are needed in
   `regex.h'.  Note that this file must contain only the bare minimum
   of definitions without the TRE_ prefix to avoid conflicts between
   definitions here and definitions included from somewhere else. */

/* Define to 1 if you have the <libutf8.h> header file. */
/* #undef HAVE_LIBUTF8_H */

/* Define to 1 if the system has the type `reg_errcode_t'. */
/* #undef HAVE_REG_ERRCODE_T */

/* Define to 1 if you have the <sys/types.h> header file. */
/* #undef HAVE_SYS_TYPES_H */

/* Define to 1 if you have the <wchar.h> header file. */
/* #undef HAVE_WCHAR_H */

/* Define if you want to enable approximate matching functionality. */
/* #undef TRE_APPROX */

/* Define to enable multibyte character set support. */
/* #undef TRE_MULTIBYTE */

/* Define to the absolute path to the system regex.h */
/* #undef TRE_SYSTEM_REGEX_H_PATH */

/* Define to include the system regex.h from TRE regex.h */
/* #undef TRE_USE_SYSTEM_REGEX_H */

/* Define to enable wide character (wchar_t) support. */
/* #undef TRE_WCHAR */

/* TRE version string. */
#define TRE_VERSION "0.7.6"

/* TRE version level 1. */
#define TRE_VERSION_1 0

/* TRE version level 2. */
#define TRE_VERSION_2 7

/* TRE version level 3. */
#define TRE_VERSION_3 6

#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif /* HAVE_SYS_TYPES_H */

#ifdef HAVE_LIBUTF8_H
#include <libutf8.h>
#endif /* HAVE_LIBUTF8_H */

#ifdef TRE_USE_SYSTEM_REGEX_H
/* Include the system regex.h to make TRE ABI compatible with the
   system regex. */
#include TRE_SYSTEM_REGEX_H_PATH
#endif /* TRE_USE_SYSTEM_REGEX_H */

#ifdef __cplusplus
extern "C" {
#endif

#ifdef TRE_USE_SYSTEM_REGEX_H

#ifndef REG_OK
#define REG_OK 0
#endif /* !REG_OK */

#ifndef HAVE_REG_ERRCODE_T
typedef int reg_errcode_t;
#endif /* !HAVE_REG_ERRCODE_T */

#if !defined(REG_NOSPEC) && !defined(REG_LITERAL)
#define REG_LITERAL 0x1000
#endif

/* Extra regcomp() flags. */
#ifndef REG_BASIC
#define REG_BASIC	0
#endif /* !REG_BASIC */
#define REG_RIGHT_ASSOC (REG_LITERAL << 1)
#define REG_UNGREEDY    (REG_RIGHT_ASSOC << 1)

/* Extra regexec() flags. */
#define REG_APPROX_MATCHER	 0x1000
#define REG_BACKTRACKING_MATCHER (REG_APPROX_MATCHER << 1)

#else /* !TRE_USE_SYSTEM_REGEX_H */

/* If the we're not using system regex.h, we need to define the
   structs and enums ourselves. */

typedef int regoff_t;
typedef struct {
  size_t re_nsub;  /* Number of parenthesized subexpressions. */
  void *value;	   /* For internal use only. */
} regex_t;

typedef struct {
  regoff_t rm_so;
  regoff_t rm_eo;
} regmatch_t;


typedef enum {
  REG_OK = 0,		/* No error. */
  /* POSIX regcomp() return error codes.  (In the order listed in the
     standard.)	 */
  REG_NOMATCH,		/* No match. */
  REG_BADPAT,		/* Invalid regexp. */
  REG_ECOLLATE,		/* Unknown collating element. */
  REG_ECTYPE,		/* Unknown character class name. */
  REG_EESCAPE,		/* Trailing backslash. */
  REG_ESUBREG,		/* Invalid back reference. */
  REG_EBRACK,		/* "[]" imbalance */
  REG_EPAREN,		/* "\(\)" or "()" imbalance */
  REG_EBRACE,		/* "\{\}" or "{}" imbalance */
  REG_BADBR,		/* Invalid content of {} */
  REG_ERANGE,		/* Invalid use of range operator */
  REG_ESPACE,		/* Out of memory.  */
  REG_BADRPT            /* Invalid use of repetition operators. */
} reg_errcode_t;

/* POSIX regcomp() flags. */
#define REG_EXTENDED	1
#define REG_ICASE	(REG_EXTENDED << 1)
#define REG_NEWLINE	(REG_ICASE << 1)
#define REG_NOSUB	(REG_NEWLINE << 1)

/* Extra regcomp() flags. */
#define REG_BASIC	0
#define REG_LITERAL	(REG_NOSUB << 1)
#define REG_RIGHT_ASSOC (REG_LITERAL << 1)
#define REG_UNGREEDY    (REG_RIGHT_ASSOC << 1)

/* POSIX regexec() flags. */
#define REG_NOTBOL 1
#define REG_NOTEOL (REG_NOTBOL << 1)

/* Extra regexec() flags. */
#define REG_APPROX_MATCHER	 (REG_NOTEOL << 1)
#define REG_BACKTRACKING_MATCHER (REG_APPROX_MATCHER << 1)

#endif /* !TRE_USE_SYSTEM_REGEX_H */

/* REG_NOSPEC and REG_LITERAL mean the same thing. */
#if defined(REG_LITERAL) && !defined(REG_NOSPEC)
#define REG_NOSPEC	REG_LITERAL
#elif defined(REG_NOSPEC) && !defined(REG_LITERAL)
#define REG_LITERAL	REG_NOSPEC
#endif /* defined(REG_NOSPEC) */

/* The maximum number of iterations in a bound expression. */
#undef RE_DUP_MAX
#define RE_DUP_MAX 255

/* The POSIX.2 regexp functions */
extern int
regcomp(regex_t *preg, const char *regex, int cflags);

extern int
regexec(const regex_t *preg, const char *string, size_t nmatch,
	regmatch_t pmatch[], int eflags);

extern size_t
regerror(int errcode, const regex_t *preg, char *errbuf,
	 size_t errbuf_size);

extern void
regfree(regex_t *preg);

#ifdef TRE_WCHAR
#ifdef HAVE_WCHAR_H
#include <wchar.h>
#endif /* HAVE_WCHAR_H */

/* Wide character versions (not in POSIX.2). */
extern int
regwcomp(regex_t *preg, const wchar_t *regex, int cflags);

extern int
regwexec(const regex_t *preg, const wchar_t *string,
	 size_t nmatch, regmatch_t pmatch[], int eflags);
#endif /* TRE_WCHAR */

/* Versions with a maximum length argument and therefore the capability to
   handle null characters in the middle of the strings (not in POSIX.2). */
extern int
regncomp(regex_t *preg, const char *regex, size_t len, int cflags);

extern int
regnexec(const regex_t *preg, const char *string, size_t len,
	 size_t nmatch, regmatch_t pmatch[], int eflags);

#ifdef TRE_WCHAR
extern int
regwncomp(regex_t *preg, const wchar_t *regex, size_t len, int cflags);

extern int
regwnexec(const regex_t *preg, const wchar_t *string, size_t len,
	  size_t nmatch, regmatch_t pmatch[], int eflags);
#endif /* TRE_WCHAR */


/* Approximate matching parameter struct. */
typedef struct {
  int cost_ins;	       /* Default cost of an inserted character. */
  int cost_del;	       /* Default cost of a deleted character. */
  int cost_subst;      /* Default cost of a substituted character. */
  int max_cost;	       /* Maximum allowed cost of a match. */

  int max_ins;	       /* Maximum allowed number of inserts. */
  int max_del;	       /* Maximum allowed number of deletes. */
  int max_subst;       /* Maximum allowed number of substitutes. */
  int max_err;	       /* Maximum allowed number of errors total. */
} regaparams_t;

/* Approximate matching result struct. */
typedef struct {
  size_t nmatch;       /* Length of pmatch[] array. */
  regmatch_t *pmatch;  /* Submatch data. */
  int cost;	       /* Cost of the match. */
  int num_ins;	       /* Number of inserts in the match. */
  int num_del;	       /* Number of deletes in the match. */
  int num_subst;       /* Number of substitutes in the match. */
} regamatch_t;

#ifdef TRE_APPROX

/* Approximate matching functions. */
extern int
regaexec(const regex_t *preg, const char *string,
	 regamatch_t *match, regaparams_t params, int eflags);

extern int
reganexec(const regex_t *preg, const char *string, size_t len,
	  regamatch_t *match, regaparams_t params, int eflags);
#ifdef TRE_WCHAR
/* Wide character approximate matching. */
extern int
regawexec(const regex_t *preg, const wchar_t *string,
	  regamatch_t *match, regaparams_t params, int eflags);

extern int
regawnexec(const regex_t *preg, const wchar_t *string, size_t len,
	   regamatch_t *match, regaparams_t params, int eflags);
#endif /* TRE_WCHAR */

/* Sets the parameters to default values. */
extern void
regaparams_default(regaparams_t *params);
#endif /* TRE_APPROX */

#ifdef TRE_WCHAR
typedef wchar_t tre_char_t;
#else /* !TRE_WCHAR */
typedef unsigned char tre_char_t;
#endif /* !TRE_WCHAR */

typedef struct {
  int (*get_next_char)(tre_char_t *c, unsigned int *pos_add, void *context);
  void (*rewind)(size_t pos, void *context);
  int (*compare)(size_t pos1, size_t pos2, size_t len, void *context);
  void *context;
} tre_str_source;

extern int
reguexec(const regex_t *preg, const tre_str_source *string,
	 size_t nmatch, regmatch_t pmatch[], int eflags);

/* Returns the version string.	The returned string is static. */
extern char *
tre_version(void);

/* Returns the value for a config parameter.  The type to which `result'
   must point to depends of the value of `query', see documentation for
   more details. */
extern int
tre_config(int query, void *result);

enum {
  TRE_CONFIG_APPROX,
  TRE_CONFIG_WCHAR,
  TRE_CONFIG_MULTIBYTE,
  TRE_CONFIG_SYSTEM_ABI,
  TRE_CONFIG_VERSION
};

/* Returns 1 if the compiled pattern has back references, 0 if not. */
extern int
tre_have_backrefs(const regex_t *preg);

/* Returns 1 if the compiled pattern uses approximate matching features,
   0 if not. */
extern int
tre_have_approx(const regex_t *preg);

#ifdef __cplusplus
}
#endif
#endif				/* TRE_REGEX_H */

/* EOF */
/*
  tre-internal.h - TRE internal definitions

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

#ifndef TRE_INTERNAL_H
#define TRE_INTERNAL_H 1

#ifdef HAVE_WCHAR_H
#include <wchar.h>
#endif /* HAVE_WCHAR_H */

#ifdef HAVE_WCTYPE_H
#include <wctype.h>
#endif /* !HAVE_WCTYPE_H */

#include <ctype.h>

#ifdef TRE_DEBUG
#include <stdio.h>
#define DPRINT(msg) do {printf msg; fflush(stdout);} while(/*CONSTCOND*/0)
#else /* !TRE_DEBUG */
#define DPRINT(msg) do { } while(/*CONSTCOND*/0)
#endif /* !TRE_DEBUG */

#define elementsof(x)	( sizeof(x) / sizeof(x[0]) )

#ifdef HAVE_MBRTOWC
#define tre_mbrtowc(pwc, s, n, ps) (mbrtowc((pwc), (s), (n), (ps)))
#else /* !HAVE_MBRTOWC */
#ifdef HAVE_MBTOWC
#define tre_mbrtowc(pwc, s, n, ps) (mbtowc((pwc), (s), (n)))
#endif /* HAVE_MBTOWC */
#endif /* !HAVE_MBRTOWC */

#ifdef TRE_MULTIBYTE
#ifdef HAVE_MBSTATE_T
#define TRE_MBSTATE
#endif /* TRE_MULTIBYTE */
#endif /* HAVE_MBSTATE_T */

/* Define the character types and functions. */
#ifdef TRE_WCHAR

/* Wide characters. */
typedef wint_t tre_cint_t;
#define TRE_CHAR_MAX WCHAR_MAX

#ifdef TRE_MULTIBYTE
#define TRE_MB_CUR_MAX MB_CUR_MAX
#else /* !TRE_MULTIBYTE */
#define TRE_MB_CUR_MAX 1
#endif /* !TRE_MULTIBYTE */

#define tre_isalnum iswalnum
#define tre_isalpha iswalpha
#ifdef HAVE_ISWBLANK
#define tre_isblank iswblank
#endif /* HAVE_ISWBLANK */
#define tre_iscntrl iswcntrl
#define tre_isdigit iswdigit
#define tre_isgraph iswgraph
#define tre_islower iswlower
#define tre_isprint iswprint
#define tre_ispunct iswpunct
#define tre_isspace iswspace
#define tre_isupper iswupper
#define tre_isxdigit iswxdigit

#define tre_tolower towlower
#define tre_toupper towupper
#define tre_strlen  wcslen

#else /* !TRE_WCHAR */

/* 8 bit characters. */
typedef short tre_cint_t;
#define TRE_CHAR_MAX 255
#define TRE_MB_CUR_MAX 1

#define tre_isalnum isalnum
#define tre_isalpha isalpha
#ifdef HAVE_ISASCII
#define tre_isascii isascii
#endif /* HAVE_ISASCII */
#ifdef HAVE_ISBLANK
#define tre_isblank isblank
#endif /* HAVE_ISBLANK */
#define tre_iscntrl iscntrl
#define tre_isdigit isdigit
#define tre_isgraph isgraph
#define tre_islower islower
#define tre_isprint isprint
#define tre_ispunct ispunct
#define tre_isspace isspace
#define tre_isupper isupper
#define tre_isxdigit isxdigit

#define tre_tolower(c) (tre_cint_t)(tolower(c))
#define tre_toupper(c) (tre_cint_t)(toupper(c))
#define tre_strlen(s)  (strlen((const char*)s))

#endif /* !TRE_WCHAR */

#if defined(TRE_WCHAR) && defined(HAVE_ISWCTYPE) && defined(HAVE_WCTYPE)
#define TRE_USE_SYSTEM_WCTYPE 1
#endif

#ifdef TRE_USE_SYSTEM_WCTYPE
/* Use system provided iswctype() and wctype(). */
typedef wctype_t tre_ctype_t;
#define tre_isctype iswctype
#define tre_ctype   wctype
#else /* !TRE_USE_SYSTEM_WCTYPE */
/* Define our own versions of iswctype() and wctype(). */
typedef int (*tre_ctype_t)(tre_cint_t);
#define tre_isctype(c, type) ( (type)(c) )
tre_ctype_t tre_ctype(const char *name);
#endif /* !TRE_USE_SYSTEM_WCTYPE */

typedef enum { STR_WIDE, STR_BYTE, STR_MBS, STR_USER } tre_str_type_t;

/* Returns number of bytes to add to (char *)ptr to make it
   properly aligned for the type. */
#define ALIGN(ptr, type) \
  ((((long)ptr) % sizeof(type)) \
   ? (sizeof(type) - (((long)ptr) % sizeof(type))) \
   : 0)

#undef MAX
#undef MIN
#define MAX(a, b) (((a) >= (b)) ? (a) : (b))
#define MIN(a, b) (((a) <= (b)) ? (a) : (b))

/* Define STRF to the correct printf formatter for strings. */
#ifdef TRE_WCHAR
#define STRF "ls"
#else /* !TRE_WCHAR */
#define STRF "s"
#endif /* !TRE_WCHAR */

/* TNFA transition type. A TNFA state is an array of transitions,
   the terminator is a transition with NULL `state'. */
typedef struct tnfa_transition tre_tnfa_transition_t;

struct tnfa_transition {
  /* Range of accepted characters. */
  tre_cint_t code_min;
  tre_cint_t code_max;
  /* Pointer to the destination state. */
  tre_tnfa_transition_t *state;
  /* ID number of the destination state. */
  int state_id;
  /* -1 terminated array of tags (or NULL). */
  int *tags;
  /* Matching parameters settings (or NULL). */
  int *params;
  /* Assertion bitmap. */
  int assertions;
  /* Assertion parameters. */
  union {
    /* Character class assertion. */
    tre_ctype_t class;
    /* Back reference assertion. */
    int backref;
  } u;
  /* Negative character class assertions. */
  tre_ctype_t *neg_classes;
};


/* Assertions. */
#define ASSERT_AT_BOL		  1   /* Beginning of line. */
#define ASSERT_AT_EOL		  2   /* End of line. */
#define ASSERT_CHAR_CLASS	  4   /* Character class in `class'. */
#define ASSERT_CHAR_CLASS_NEG	  8   /* Character classes in `neg_classes'. */
#define ASSERT_AT_BOW		 16   /* Beginning of word. */
#define ASSERT_AT_EOW		 32   /* End of word. */
#define ASSERT_AT_WB		 64   /* Word boundary. */
#define ASSERT_AT_WB_NEG	128   /* Not a word boundary. */
#define ASSERT_BACKREF		256   /* A back reference in `backref'. */
#define ASSERT_LAST		256

/* Tag directions. */
typedef enum {
  TRE_TAG_MINIMIZE = 0,
  TRE_TAG_MAXIMIZE = 1
} tre_tag_direction_t;

/* Parameters that can be changed dynamically while matching. */
typedef enum {
  TRE_PARAM_COST_INS	    = 0,
  TRE_PARAM_COST_DEL	    = 1,
  TRE_PARAM_COST_SUBST	    = 2,
  TRE_PARAM_COST_MAX	    = 3,
  TRE_PARAM_MAX_INS	    = 4,
  TRE_PARAM_MAX_DEL	    = 5,
  TRE_PARAM_MAX_SUBST	    = 6,
  TRE_PARAM_MAX_ERR	    = 7,
  TRE_PARAM_DEPTH	    = 8,
  TRE_PARAM_LAST	    = 9
} tre_param_t;

/* Unset matching parameter */
#define TRE_PARAM_UNSET -1

/* Signifies the default matching parameter value. */
#define TRE_PARAM_DEFAULT -2

/* Instructions to compute submatch register values from tag values
   after a successful match.  */
struct tre_submatch_data {
  /* Tag that gives the value for rm_so (submatch start offset). */
  int so_tag;
  /* Tag that gives the value for rm_eo (submatch end offset). */
  int eo_tag;
  /* List of submatches this submatch is contained in. */
  int *parents;
};

typedef struct tre_submatch_data tre_submatch_data_t;


/* TNFA definition. */
typedef struct tnfa tre_tnfa_t;

struct tnfa {
  tre_tnfa_transition_t *transitions;
  unsigned int num_transitions;
  tre_tnfa_transition_t *initial;
  tre_tnfa_transition_t *final;
  tre_submatch_data_t *submatch_data;
  char *firstpos_chars;
  int first_char;
  unsigned int num_submatches;
  tre_tag_direction_t *tag_directions;
  int *minimal_tags;
  int num_tags;
  int num_minimals;
  int end_tag;
  int num_states;
  int cflags;
  int have_backrefs;
  int have_approx;
  int params_depth;
};

int
tre_compile(regex_t *preg, const tre_char_t *regex, size_t n, int cflags);

void
tre_free(regex_t *preg);

void
tre_fill_pmatch(size_t nmatch, regmatch_t pmatch[], int cflags,
		const tre_tnfa_t *tnfa, int *tags, int match_eo);

reg_errcode_t
tre_tnfa_run_parallel(const tre_tnfa_t *tnfa, const void *string, int len,
		      tre_str_type_t type, int *match_tags, int eflags,
		      int *match_end_ofs);

reg_errcode_t
tre_tnfa_run_parallel(const tre_tnfa_t *tnfa, const void *string, int len,
		      tre_str_type_t type, int *match_tags, int eflags,
		      int *match_end_ofs);

reg_errcode_t
tre_tnfa_run_backtrack(const tre_tnfa_t *tnfa, const void *string,
		       int len, tre_str_type_t type, int *match_tags,
		       int eflags, int *match_end_ofs);

#ifdef TRE_APPROX
reg_errcode_t
tre_tnfa_run_approx(const tre_tnfa_t *tnfa, const void *string, int len,
		    tre_str_type_t type, int *match_tags,
		    regamatch_t *match, regaparams_t params,
		    int eflags, int *match_end_ofs);
#endif /* TRE_APPROX */

#endif /* TRE_INTERNAL_H */

/* EOF */
/*
  xmalloc.h - Simple malloc debugging library API

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

#ifndef _XMALLOC_H
#define _XMALLOC_H 1

void *xmalloc_impl(size_t size, const char *file, int line, const char *func);
void *xcalloc_impl(size_t nmemb, size_t size, const char *file, int line,
		   const char *func);
void xfree_impl(void *ptr, const char *file, int line, const char *func);
void *xrealloc_impl(void *ptr, size_t new_size, const char *file, int line,
		    const char *func);
int xmalloc_dump_leaks(void);
void xmalloc_configure(int fail_after);


#ifndef XMALLOC_INTERNAL
#ifdef MALLOC_DEBUGGING

/* Version 2.4 and later of GCC define a magical variable `__PRETTY_FUNCTION__'
   which contains the name of the function currently being defined.
#  define __XMALLOC_FUNCTION	 __PRETTY_FUNCTION__
   This is broken in G++ before version 2.6.
   C9x has a similar variable called __func__, but prefer the GCC one since
   it demangles C++ function names.  */
# ifdef __GNUC__
#  if __GNUC__ > 2 || (__GNUC__ == 2 \
		       && __GNUC_MINOR__ >= (defined __cplusplus ? 6 : 4))
#   define __XMALLOC_FUNCTION	 __PRETTY_FUNCTION__
#  else
#   define __XMALLOC_FUNCTION	 ((const char *) 0)
#  endif
# else
#  if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
#   define __XMALLOC_FUNCTION	 __func__
#  else
#   define __XMALLOC_FUNCTION	 ((const char *) 0)
#  endif
# endif

#define xmalloc(size) xmalloc_impl(size, __FILE__, __LINE__, \
				   __XMALLOC_FUNCTION)
#define xcalloc(nmemb, size) xcalloc_impl(nmemb, size, __FILE__, __LINE__, \
					  __XMALLOC_FUNCTION)
#define xfree(ptr) xfree_impl(ptr, __FILE__, __LINE__, __XMALLOC_FUNCTION)
#define xrealloc(ptr, new_size) xrealloc_impl(ptr, new_size, __FILE__, \
					      __LINE__, __XMALLOC_FUNCTION)
#undef malloc
#undef calloc
#undef free
#undef realloc

#define malloc	USE_XMALLOC_INSTEAD_OF_MALLOC
#define calloc	USE_XCALLOC_INSTEAD_OF_CALLOC
#define free	USE_XFREE_INSTEAD_OF_FREE
#define realloc USE_XREALLOC_INSTEAD_OF_REALLOC

#else /* !MALLOC_DEBUGGING */

#include <stdlib.h>

#define xmalloc(size) malloc(size)
#define xcalloc(nmemb, size) calloc(nmemb, size)
#define xfree(ptr) free(ptr)
#define xrealloc(ptr, new_size) realloc(ptr, new_size)

#endif /* !MALLOC_DEBUGGING */
#endif /* !XMALLOC_INTERNAL */

#endif /* _XMALLOC_H */

/* EOF */

int
regncomp(regex_t *preg, const char *regex, size_t n, int cflags)
{
  int ret;
#if TRE_WCHAR
  tre_char_t *wregex;
  int wlen;

  wregex = xmalloc(sizeof(tre_char_t) * (n + 1));
  if (wregex == NULL)
    return REG_ESPACE;

  /* If the current locale uses the standard single byte encoding of
     characters, we don't do a multibyte string conversion.  If we did,
     many applications which use the default locale would break since
     the default "C" locale uses the 7-bit ASCII character set, and
     all characters with the eighth bit set would be considered invalid. */
#if TRE_MULTIBYTE
  if (TRE_MB_CUR_MAX == 1)
#endif /* TRE_MULTIBYTE */
    {
      unsigned int i;
      const unsigned char *str = (const unsigned char *)regex;
      tre_char_t *wstr = wregex;

      for (i = 0; i < n; i++)
	*(wstr++) = *(str++);
      wlen = n;
    }
#if TRE_MULTIBYTE
  else
    {
      int consumed;
      tre_char_t *wcptr = wregex;
#ifdef HAVE_MBSTATE_T
      mbstate_t state;
      memset(&state, '\0', sizeof(state));
#endif /* HAVE_MBSTATE_T */
      while (n > 0)
	{
	  consumed = tre_mbrtowc(wcptr, regex, n, &state);

	  switch (consumed)
	    {
	    case 0:
	      if (*regex == '\0')
		consumed = 1;
	      else
		{
		  xfree(wregex);
		  return REG_BADPAT;
		}
	      break;
	    case -1:
	      DPRINT(("mbrtowc: error %d: %s.\n", errno, strerror(errno)));
	      xfree(wregex);
	      return REG_BADPAT;
	    case -2:
	      /* The last character wasn't complete.  Let's not call it a
		 fatal error. */
	      consumed = n;
	      break;
	    }
	  regex += consumed;
	  n -= consumed;
	  wcptr++;
	}
      wlen = wcptr - wregex;
    }
#endif /* TRE_MULTIBYTE */

  wregex[wlen] = L'\0';
  ret = tre_compile(preg, wregex, (unsigned)wlen, cflags);
  xfree(wregex);
#else /* !TRE_WCHAR */
  ret = tre_compile(preg, (const tre_char_t *)regex, n, cflags);
#endif /* !TRE_WCHAR */

  return ret;
}

int
regcomp(regex_t *preg, const char *regex, int cflags)
{
  return regncomp(preg, regex, regex ? strlen(regex) : 0, cflags);
}


#ifdef TRE_WCHAR
int
regwncomp(regex_t *preg, const wchar_t *regex, size_t n, int cflags)
{
  return tre_compile(preg, regex, n, cflags);
}

int
regwcomp(regex_t *preg, const wchar_t *regex, int cflags)
{
  return tre_compile(preg, regex, regex ? wcslen(regex) : 0, cflags);
}
#endif /* TRE_WCHAR */

void
regfree(regex_t *preg)
{
  tre_free(preg);
}

/* EOF */
/*
  regerror.c - POSIX regerror() implementation for TRE.

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */

#include <string.h>
#ifdef HAVE_WCHAR_H
#include <wchar.h>
#endif /* HAVE_WCHAR_H */
#ifdef HAVE_WCTYPE_H
#include <wctype.h>
#endif /* HAVE_WCTYPE_H */

#define dgettext(p, s) s
#define gettext(s) s

#define _(String) dgettext(PACKAGE, String)
#define gettext_noop(String) String

/* Error message strings for error codes listed in `regex.h'.  This list
   needs to be in sync with the codes listed there, naturally. */
static const char *tre_error_messages[] =
  { gettext_noop("No error"),				 /* REG_OK */
    gettext_noop("No match"),				 /* REG_NOMATCH */
    gettext_noop("Invalid regexp"),			 /* REG_BADPAT */
    gettext_noop("Unknown collating element"),		 /* REG_ECOLLATE */
    gettext_noop("Unknown character class name"),	 /* REG_ECTYPE */
    gettext_noop("Trailing backslash"),			 /* REG_EESCAPE */
    gettext_noop("Invalid back reference"),		 /* REG_ESUBREG */
    gettext_noop("Missing ']'"),			 /* REG_EBRACK */
    gettext_noop("Missing ')'"),			 /* REG_EPAREN */
    gettext_noop("Missing '}'"),			 /* REG_EBRACE */
    gettext_noop("Invalid contents of {}"),		 /* REG_BADBR */
    gettext_noop("Invalid character range"),		 /* REG_ERANGE */
    gettext_noop("Out of memory"),			 /* REG_ESPACE */
    gettext_noop("Invalid use of repetition operators")	 /* REG_BADRPT */
  };

size_t
regerror(int errcode, const regex_t *preg, char *errbuf, size_t errbuf_size)
{
  const char *err;
  size_t err_len;

  /*LINTED*/(void)&preg;
  if (errcode >= 0
      && errcode < (int)(sizeof(tre_error_messages)
			 / sizeof(*tre_error_messages)))
    err = gettext(tre_error_messages[errcode]);
  else
    err = gettext("Unknown error");

  err_len = strlen(err) + 1;
  if (errbuf_size > 0 && errbuf != NULL)
    {
      if (err_len > errbuf_size)
	{
	  strncpy(errbuf, err, errbuf_size - 1);
	  errbuf[errbuf_size - 1] = '\0';
	}
      else
	{
	  strcpy(errbuf, err);
	}
    }
  return err_len;
}

/* EOF */
/*
  regexec.c - TRE POSIX compatible matching functions (and more).

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */

#ifdef TRE_USE_ALLOCA
/* AIX requires this to be the first thing in the file.	 */
#ifndef __GNUC__
# if HAVE_ALLOCA_H
#  include <alloca.h>
# else
#  ifdef _AIX
 #pragma alloca
#  else
#   ifndef alloca /* predefined by HP cc +Olibcalls */
char *alloca ();
#   endif
#  endif
# endif
#endif
#endif /* TRE_USE_ALLOCA */

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#ifdef HAVE_WCHAR_H
#include <wchar.h>
#endif /* HAVE_WCHAR_H */
#ifdef HAVE_WCTYPE_H
#include <wctype.h>
#endif /* HAVE_WCTYPE_H */
#ifndef TRE_WCHAR
#include <ctype.h>
#endif /* !TRE_WCHAR */
#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif /* HAVE_MALLOC_H */
#include <limits.h>



/* Fills the POSIX.2 regmatch_t array according to the TNFA tag and match
   endpoint values. */
void
tre_fill_pmatch(size_t nmatch, regmatch_t pmatch[], int cflags,
		const tre_tnfa_t *tnfa, int *tags, int match_eo)
{
  tre_submatch_data_t *submatch_data;
  unsigned int i, j;
  int *parents;

  i = 0;
  if (match_eo >= 0 && !(cflags & REG_NOSUB))
    {
      /* Construct submatch offsets from the tags. */
      DPRINT(("end tag = t%d = %d\n", tnfa->end_tag, match_eo));
      submatch_data = tnfa->submatch_data;
      while (i < tnfa->num_submatches && i < nmatch)
	{
	  if (submatch_data[i].so_tag == tnfa->end_tag)
	    pmatch[i].rm_so = match_eo;
	  else
	    pmatch[i].rm_so = tags[submatch_data[i].so_tag];

	  if (submatch_data[i].eo_tag == tnfa->end_tag)
	    pmatch[i].rm_eo = match_eo;
	  else
	    pmatch[i].rm_eo = tags[submatch_data[i].eo_tag];

	  /* If either of the endpoints were not used, this submatch
	     was not part of the match. */
	  if (pmatch[i].rm_so == -1 || pmatch[i].rm_eo == -1)
	    pmatch[i].rm_so = pmatch[i].rm_eo = -1;

	  DPRINT(("pmatch[%d] = {t%d = %d, t%d = %d}\n", i,
		  submatch_data[i].so_tag, pmatch[i].rm_so,
		  submatch_data[i].eo_tag, pmatch[i].rm_eo));
	  i++;
	}
      /* Reset all submatches that are not within all of their parent
	 submatches. */
      i = 0;
      while (i < tnfa->num_submatches && i < nmatch)
	{
	  if (pmatch[i].rm_eo == -1)
	    assert(pmatch[i].rm_so == -1);
	  assert(pmatch[i].rm_so <= pmatch[i].rm_eo);

	  parents = submatch_data[i].parents;
	  if (parents != NULL)
	    for (j = 0; parents[j] >= 0; j++)
	      {
		DPRINT(("pmatch[%d] parent %d\n", i, parents[j]));
		if (pmatch[i].rm_so < pmatch[parents[j]].rm_so
		    || pmatch[i].rm_eo > pmatch[parents[j]].rm_eo)
		  pmatch[i].rm_so = pmatch[i].rm_eo = -1;
	      }
	  i++;
	}
    }

  while (i < nmatch)
    {
      pmatch[i].rm_so = -1;
      pmatch[i].rm_eo = -1;
      i++;
    }
}


/*
  Wrapper functions for POSIX compatible regexp matching.
*/

int
tre_have_backrefs(const regex_t *preg)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  return tnfa->have_backrefs;
}

int
tre_have_approx(const regex_t *preg)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  return tnfa->have_approx;
}

static int
tre_match(const tre_tnfa_t *tnfa, const void *string, size_t len,
	  tre_str_type_t type, size_t nmatch, regmatch_t pmatch[],
	  int eflags)
{
  reg_errcode_t status;
  int *tags = NULL, eo;
  if (tnfa->num_tags > 0 && nmatch > 0)
    {
#ifdef TRE_USE_ALLOCA
      tags = alloca(sizeof(*tags) * tnfa->num_tags);
#else /* !TRE_USE_ALLOCA */
      tags = xmalloc(sizeof(*tags) * tnfa->num_tags);
#endif /* !TRE_USE_ALLOCA */
      if (tags == NULL)
	return REG_ESPACE;
    }

  /* Dispatch to the appropriate matcher. */
  if (tnfa->have_backrefs || eflags & REG_BACKTRACKING_MATCHER)
    {
      /* The regex has back references, use the backtracking matcher. */
      if (type == STR_USER)
	{
	  const tre_str_source *source = string;
	  if (source->rewind == NULL || source->compare == NULL)
	    /* The backtracking matcher requires rewind and compare
	       capabilities from the input stream. */
	    return REG_BADPAT;
	}
      status = tre_tnfa_run_backtrack(tnfa, string, (int)len, type,
				      tags, eflags, &eo);
    }
#ifdef TRE_APPROX
  else if (tnfa->have_approx || eflags & REG_APPROX_MATCHER)
    {
      /* The regex uses approximate matching, use the approximate matcher. */
      regamatch_t match;
      regaparams_t params;
      regaparams_default(&params);
      params.max_err = 0;
      params.max_cost = 0;
      status = tre_tnfa_run_approx(tnfa, string, (int)len, type, tags,
				   &match, params, eflags, &eo);
    }
#endif /* TRE_APPROX */
  else
    {
      /* Exact matching, no back references, use the parallel matcher. */
      status = tre_tnfa_run_parallel(tnfa, string, (int)len, type,
				     tags, eflags, &eo);
    }

  if (status == REG_OK)
    /* A match was found, so fill the submatch registers. */
    tre_fill_pmatch(nmatch, pmatch, tnfa->cflags, tnfa, tags, eo);
#ifndef TRE_USE_ALLOCA
  if (tags)
    xfree(tags);
#endif /* !TRE_USE_ALLOCA */
  return status;
}

int
regnexec(const regex_t *preg, const char *str, size_t len,
	 size_t nmatch, regmatch_t pmatch[], int eflags)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  tre_str_type_t type = (TRE_MB_CUR_MAX == 1) ? STR_BYTE : STR_MBS;

  return tre_match(tnfa, str, len, type, nmatch, pmatch, eflags);
}

int
regexec(const regex_t *preg, const char *str,
	size_t nmatch, regmatch_t pmatch[], int eflags)
{
  return regnexec(preg, str, (unsigned)-1, nmatch, pmatch, eflags);
}


#ifdef TRE_WCHAR

int
regwnexec(const regex_t *preg, const wchar_t *str, size_t len,
	  size_t nmatch, regmatch_t pmatch[], int eflags)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  return tre_match(tnfa, str, len, STR_WIDE, nmatch, pmatch, eflags);
}

int
regwexec(const regex_t *preg, const wchar_t *str,
	 size_t nmatch, regmatch_t pmatch[], int eflags)
{
  return regwnexec(preg, str, (unsigned)-1, nmatch, pmatch, eflags);
}

#endif /* TRE_WCHAR */

int
reguexec(const regex_t *preg, const tre_str_source *str,
	 size_t nmatch, regmatch_t pmatch[], int eflags)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  return tre_match(tnfa, str, (unsigned)-1, STR_USER, nmatch, pmatch, eflags);
}


#ifdef TRE_APPROX

/*
  Wrapper functions for approximate regexp matching.
*/

static int
tre_match_approx(const tre_tnfa_t *tnfa, const void *string, size_t len,
		 tre_str_type_t type, regamatch_t *match, regaparams_t params,
		 int eflags)
{
  reg_errcode_t status;
  int *tags = NULL, eo;

  /* If the regexp does not use approximate matching features, the
     maximum cost is zero, and the approximate matcher isn't forced,
     use the exact matcher instead. */
  if (params.max_cost == 0 && !tnfa->have_approx
      && !(eflags & REG_APPROX_MATCHER))
    return tre_match(tnfa, string, len, type, match->nmatch, match->pmatch,
		     eflags);

  /* Back references are not supported by the approximate matcher. */
  if (tnfa->have_backrefs)
    return REG_BADPAT;

  if (tnfa->num_tags > 0 && match->nmatch > 0)
    {
#if TRE_USE_ALLOCA
      tags = alloca(sizeof(*tags) * tnfa->num_tags);
#else /* !TRE_USE_ALLOCA */
      tags = xmalloc(sizeof(*tags) * tnfa->num_tags);
#endif /* !TRE_USE_ALLOCA */
      if (tags == NULL)
	return REG_ESPACE;
    }
  status = tre_tnfa_run_approx(tnfa, string, (int)len, type, tags,
			       match, params, eflags, &eo);
  if (status == REG_OK)
    tre_fill_pmatch(match->nmatch, match->pmatch, tnfa->cflags, tnfa, tags, eo);
#ifndef TRE_USE_ALLOCA
  if (tags)
    xfree(tags);
#endif /* !TRE_USE_ALLOCA */
  return status;
}

int
reganexec(const regex_t *preg, const char *str, size_t len,
	  regamatch_t *match, regaparams_t params, int eflags)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  tre_str_type_t type = (TRE_MB_CUR_MAX == 1) ? STR_BYTE : STR_MBS;

  return tre_match_approx(tnfa, str, len, type, match, params, eflags);
}

int
regaexec(const regex_t *preg, const char *str,
	 regamatch_t *match, regaparams_t params, int eflags)
{
  return reganexec(preg, str, (unsigned)-1, match, params, eflags);
}

#ifdef TRE_WCHAR

int
regawnexec(const regex_t *preg, const wchar_t *str, size_t len,
	   regamatch_t *match, regaparams_t params, int eflags)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  return tre_match_approx(tnfa, str, len, STR_WIDE,
			  match, params, eflags);
}

int
regawexec(const regex_t *preg, const wchar_t *str,
	  regamatch_t *match, regaparams_t params, int eflags)
{
  return regawnexec(preg, str, (unsigned)-1, match, params, eflags);
}

#endif /* TRE_WCHAR */

void
regaparams_default(regaparams_t *params)
{
  memset(params, 0, sizeof(*params));
  params->cost_ins = 1;
  params->cost_del = 1;
  params->cost_subst = 1;
  params->max_cost = INT_MAX;
  params->max_ins = INT_MAX;
  params->max_del = INT_MAX;
  params->max_subst = INT_MAX;
  params->max_err = INT_MAX;
}

#endif /* TRE_APPROX */

/* EOF */
/*
  tre-ast.c - Abstract syntax tree (AST) routines

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */
#include <assert.h>

/*
  tre-ast.h - Abstract syntax tree (AST) definitions

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/


#ifndef TRE_AST_H
#define TRE_AST_H 1

/*
  tre-mem.h - TRE memory allocator interface

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

#ifndef TRE_MEM_H
#define TRE_MEM_H 1

#include <stdlib.h>

#define TRE_MEM_BLOCK_SIZE 1024

typedef struct tre_list {
  void *data;
  struct tre_list *next;
} tre_list_t;

typedef struct tre_mem_struct {
  tre_list_t *blocks;
  tre_list_t *current;
  char *ptr;
  size_t n;
  int failed;
  void **provided;
} *tre_mem_t;


tre_mem_t tre_mem_new_impl(int provided, void *provided_block);
void *tre_mem_alloc_impl(tre_mem_t mem, int provided, void *provided_block,
			 int zero, size_t size);

/* Returns a new memory allocator or NULL if out of memory. */
#define tre_mem_new()  tre_mem_new_impl(0, NULL)

/* Allocates a block of `size' bytes from `mem'.  Returns a pointer to the
   allocated block or NULL if an underlying malloc() failed. */
#define tre_mem_alloc(mem, size) tre_mem_alloc_impl(mem, 0, NULL, 0, size)

/* Allocates a block of `size' bytes from `mem'.  Returns a pointer to the
   allocated block or NULL if an underlying malloc() failed.  The memory
   is set to zero. */
#define tre_mem_calloc(mem, size) tre_mem_alloc_impl(mem, 0, NULL, 1, size)

#ifdef TRE_USE_ALLOCA
/* alloca() versions.  Like above, but memory is allocated with alloca()
   instead of malloc(). */

#define tre_mem_newa() \
  tre_mem_new_impl(1, alloca(sizeof(struct tre_mem_struct)))

#define tre_mem_alloca(mem, size)					      \
  ((mem)->n >= (size)							      \
   ? tre_mem_alloc_impl((mem), 1, NULL, 0, (size))			      \
   : tre_mem_alloc_impl((mem), 1, alloca(TRE_MEM_BLOCK_SIZE), 0, (size)))
#endif /* TRE_USE_ALLOCA */


/* Frees the memory allocator and all memory allocated with it. */
void tre_mem_destroy(tre_mem_t mem);

#endif /* TRE_MEM_H */

/* EOF */
/*
  tre-compile.h: Regex compilation definitions

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/


#ifndef TRE_COMPILE_H
#define TRE_COMPILE_H 1

typedef struct {
  int position;
  int code_min;
  int code_max;
  int *tags;
  int assertions;
  tre_ctype_t class;
  tre_ctype_t *neg_classes;
  int backref;
  int *params;
} tre_pos_and_tags_t;

#endif /* TRE_COMPILE_H */

/* EOF */

/* The different AST node types. */
typedef enum {
  LITERAL,
  CATENATION,
  ITERATION,
  UNION
} tre_ast_type_t;

/* Special subtypes of TRE_LITERAL. */
#define EMPTY	  -1   /* Empty leaf (denotes empty string). */
#define ASSERTION -2   /* Assertion leaf. */
#define TAG	  -3   /* Tag leaf. */
#define BACKREF	  -4   /* Back reference leaf. */
#define PARAMETER -5   /* Parameter. */

#define IS_SPECIAL(x)	((x)->code_min < 0)
#define IS_EMPTY(x)	((x)->code_min == EMPTY)
#define IS_ASSERTION(x) ((x)->code_min == ASSERTION)
#define IS_TAG(x)	((x)->code_min == TAG)
#define IS_BACKREF(x)	((x)->code_min == BACKREF)
#define IS_PARAMETER(x) ((x)->code_min == PARAMETER)


/* A generic AST node.  All AST nodes consist of this node on the top
   level with `obj' pointing to the actual content. */
typedef struct {
  tre_ast_type_t type;   /* Type of the node. */
  void *obj;             /* Pointer to actual node. */
  int nullable;
  int submatch_id;
  int num_submatches;
  int num_tags;
  tre_pos_and_tags_t *firstpos;
  tre_pos_and_tags_t *lastpos;
} tre_ast_node_t;


/* A "literal" node.  These are created for assertions, back references,
   tags, matching parameter settings, and all expressions that match one
   character. */
typedef struct {
  long code_min;
  long code_max;
  int position;
  union {
    tre_ctype_t class;
    int *params;
  } u;
  tre_ctype_t *neg_classes;
} tre_literal_t;

/* A "catenation" node.	 These are created when two regexps are concatenated.
   If there are more than one subexpressions in sequence, the `left' part
   holds all but the last, and `right' part holds the last subexpression
   (catenation is left associative). */
typedef struct {
  tre_ast_node_t *left;
  tre_ast_node_t *right;
} tre_catenation_t;

/* An "iteration" node.	 These are created for the "*", "+", "?", and "{m,n}"
   operators. */
typedef struct {
  /* Subexpression to match. */
  tre_ast_node_t *arg;
  /* Minimum number of consecutive matches. */
  int min;
  /* Maximum number of consecutive matches. */
  int max;
  /* If 0, match as many characters as possible, if 1 match as few as
     possible.	Note that this does not always mean the same thing as
     matching as many/few repetitions as possible. */
  unsigned int minimal:1;
  /* Approximate matching parameters (or NULL). */
  int *params;
} tre_iteration_t;

/* An "union" node.  These are created for the "|" operator. */
typedef struct {
  tre_ast_node_t *left;
  tre_ast_node_t *right;
} tre_union_t;

tre_ast_node_t *
tre_ast_new_node(tre_mem_t mem, tre_ast_type_t type, size_t size);

tre_ast_node_t *
tre_ast_new_literal(tre_mem_t mem, int code_min, int code_max, int position);

tre_ast_node_t *
tre_ast_new_iter(tre_mem_t mem, tre_ast_node_t *arg, int min, int max,
		 int minimal);

tre_ast_node_t *
tre_ast_new_union(tre_mem_t mem, tre_ast_node_t *left, tre_ast_node_t *right);

tre_ast_node_t *
tre_ast_new_catenation(tre_mem_t mem, tre_ast_node_t *left,
		       tre_ast_node_t *right);

#ifdef TRE_DEBUG
void
tre_ast_print(tre_ast_node_t *tree);

/* XXX - rethink AST printing API */
void
tre_print_params(int *params);
#endif /* TRE_DEBUG */

#endif /* TRE_AST_H */

/* EOF */

tre_ast_node_t *
tre_ast_new_node(tre_mem_t mem, tre_ast_type_t type, size_t size)
{
  tre_ast_node_t *node;

  node = tre_mem_calloc(mem, sizeof(*node));
  if (!node)
    return NULL;
  node->obj = tre_mem_calloc(mem, size);
  if (!node->obj)
    return NULL;
  node->type = type;
  node->nullable = -1;
  node->submatch_id = -1;

  return node;
}

tre_ast_node_t *
tre_ast_new_literal(tre_mem_t mem, int code_min, int code_max, int position)
{
  tre_ast_node_t *node;
  tre_literal_t *lit;

  node = tre_ast_new_node(mem, LITERAL, sizeof(tre_literal_t));
  if (!node)
    return NULL;
  lit = node->obj;
  lit->code_min = code_min;
  lit->code_max = code_max;
  lit->position = position;

  return node;
}

tre_ast_node_t *
tre_ast_new_iter(tre_mem_t mem, tre_ast_node_t *arg, int min, int max,
		 int minimal)
{
  tre_ast_node_t *node;
  tre_iteration_t *iter;

  node = tre_ast_new_node(mem, ITERATION, sizeof(tre_iteration_t));
  if (!node)
    return NULL;
  iter = node->obj;
  iter->arg = arg;
  iter->min = min;
  iter->max = max;
  iter->minimal = minimal;
  node->num_submatches = arg->num_submatches;

  return node;
}

tre_ast_node_t *
tre_ast_new_union(tre_mem_t mem, tre_ast_node_t *left, tre_ast_node_t *right)
{
  tre_ast_node_t *node;

  node = tre_ast_new_node(mem, UNION, sizeof(tre_union_t));
  if (node == NULL)
    return NULL;
  ((tre_union_t *)node->obj)->left = left;
  ((tre_union_t *)node->obj)->right = right;
  node->num_submatches = left->num_submatches + right->num_submatches;

  return node;
}

tre_ast_node_t *
tre_ast_new_catenation(tre_mem_t mem, tre_ast_node_t *left,
		       tre_ast_node_t *right)
{
  tre_ast_node_t *node;

  node = tre_ast_new_node(mem, CATENATION, sizeof(tre_catenation_t));
  if (node == NULL)
    return NULL;
  ((tre_catenation_t *)node->obj)->left = left;
  ((tre_catenation_t *)node->obj)->right = right;
  node->num_submatches = left->num_submatches + right->num_submatches;

  return node;
}

#ifdef TRE_DEBUG

static void
tre_findent(FILE *stream, int i)
{
  while (i-- > 0)
    fputc(' ', stream);
}

void
tre_print_params(int *params)
{
  int i;
  if (params)
    {
      DPRINT(("params ["));
      for (i = 0; i < TRE_PARAM_LAST; i++)
	{
	  if (params[i] == TRE_PARAM_UNSET)
	    DPRINT(("unset"));
	  else if (params[i] == TRE_PARAM_DEFAULT)
	    DPRINT(("default"));
	  else
	    DPRINT(("%d", params[i]));
	  if (i < TRE_PARAM_LAST - 1)
	    DPRINT((", "));
	}
      DPRINT(("]"));
    }
}

static void
tre_do_print(FILE *stream, tre_ast_node_t *ast, int indent)
{
  int code_min, code_max, pos;
  int num_tags = ast->num_tags;
  tre_literal_t *lit;
  tre_iteration_t *iter;

  tre_findent(stream, indent);
  switch (ast->type)
    {
    case LITERAL:
      lit = ast->obj;
      code_min = lit->code_min;
      code_max = lit->code_max;
      pos = lit->position;
      if (IS_EMPTY(lit))
	{
	  fprintf(stream, "literal empty\n");
	}
      else if (IS_ASSERTION(lit))
	{
	  int i;
	  char *assertions[] = { "bol", "eol", "ctype", "!ctype",
				 "bow", "eow", "wb", "!wb" };
	  if (code_max >= ASSERT_LAST << 1)
	    assert(0);
	  fprintf(stream, "assertions: ");
	  for (i = 0; (1 << i) <= ASSERT_LAST; i++)
	    if (code_max & (1 << i))
	      fprintf(stream, "%s ", assertions[i]);
	  fprintf(stream, "\n");
	}
      else if (IS_TAG(lit))
	{
	  fprintf(stream, "tag %d\n", code_max);
	}
      else if (IS_BACKREF(lit))
	{
	  fprintf(stream, "backref %d, pos %d\n", code_max, pos);
	}
      else if (IS_PARAMETER(lit))
	{
	  tre_print_params(lit->u.params);
	  fprintf(stream, "\n");
	}
      else
	{
	  fprintf(stream, "literal (%c, %c) (%d, %d), pos %d, sub %d, "
		  "%d tags\n", code_min, code_max, code_min, code_max, pos,
		  ast->submatch_id, num_tags);
	}
      break;
    case ITERATION:
      iter = ast->obj;
      fprintf(stream, "iteration {%d, %d}, sub %d, %d tags, %s\n",
	      iter->min, iter->max, ast->submatch_id, num_tags,
	      iter->minimal ? "minimal" : "greedy");
      tre_do_print(stream, iter->arg, indent + 2);
      break;
    case UNION:
      fprintf(stream, "union, sub %d, %d tags\n", ast->submatch_id, num_tags);
      tre_do_print(stream, ((tre_union_t *)ast->obj)->left, indent + 2);
      tre_do_print(stream, ((tre_union_t *)ast->obj)->right, indent + 2);
      break;
    case CATENATION:
      fprintf(stream, "catenation, sub %d, %d tags\n", ast->submatch_id,
	      num_tags);
      tre_do_print(stream, ((tre_catenation_t *)ast->obj)->left, indent + 2);
      tre_do_print(stream, ((tre_catenation_t *)ast->obj)->right, indent + 2);
      break;
    default:
      assert(0);
      break;
    }
}

static void
tre_ast_fprint(FILE *stream, tre_ast_node_t *ast)
{
  tre_do_print(stream, ast, 0);
}

void
tre_ast_print(tre_ast_node_t *tree)
{
  printf("AST:\n");
  tre_ast_fprint(stdout, tree);
}

#endif /* TRE_DEBUG */

/* EOF */
/*
  tre-compile.c - TRE regex compiler

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

/*
  TODO:
   - Fix tre_ast_to_tnfa() to recurse using a stack instead of recursive
     function calls.
*/


#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */
#include <stdio.h>
#include <assert.h>
#include <string.h>

/*
  tre-stack.h: Stack definitions

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/


#ifndef TRE_STACK_H
#define TRE_STACK_H 1


typedef struct tre_stack_rec tre_stack_t;

/* Creates a new stack object.	`size' is initial size in bytes, `max_size'
   is maximum size, and `increment' specifies how much more space will be
   allocated with realloc() if all space gets used up.	Returns the stack
   object or NULL if out of memory. */
tre_stack_t *
tre_stack_new(int size, int max_size, int increment);

/* Frees the stack object. */
void
tre_stack_destroy(tre_stack_t *s);

/* Returns the current number of objects in the stack. */
int
tre_stack_num_objects(tre_stack_t *s);

/* Each tre_stack_push_*(tre_stack_t *s, <type> value) function pushes
   `value' on top of stack `s'.  Returns REG_ESPACE if out of memory.
   This tries to realloc() more space before failing if maximum size
   has not yet been reached.  Returns REG_OK if successful. */
#define declare_pushf(typetag, type)					      \
  reg_errcode_t tre_stack_push_ ## typetag(tre_stack_t *s, type value)

declare_pushf(voidptr, void *);
declare_pushf(int, int);

/* Each tre_stack_pop_*(tre_stack_t *s) function pops the topmost
   element off of stack `s' and returns it.  The stack must not be
   empty. */
#define declare_popf(typetag, type)		  \
  type tre_stack_pop_ ## typetag(tre_stack_t *s)

declare_popf(voidptr, void *);
declare_popf(int, int);

/* Just to save some typing. */
#define STACK_PUSH(s, typetag, value)					      \
  do									      \
    {									      \
      status = tre_stack_push_ ## typetag(s, value);			      \
    }									      \
  while (/*CONSTCOND*/0)

#define STACK_PUSHX(s, typetag, value)					      \
  {									      \
    status = tre_stack_push_ ## typetag(s, value);			      \
    if (status != REG_OK)						      \
      break;								      \
  }

#define STACK_PUSHR(s, typetag, value)					      \
  {									      \
    reg_errcode_t _status;						      \
    _status = tre_stack_push_ ## typetag(s, value);			      \
    if (_status != REG_OK)						      \
      return _status;							      \
  }

#endif /* TRE_STACK_H */

/* EOF */
/*
  tre-parse.c - Regexp parser definitions

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

#ifndef TRE_PARSE_H
#define TRE_PARSE_H 1

/* Parse context. */
typedef struct {
  /* Memory allocator.	The AST is allocated using this. */
  tre_mem_t mem;
  /* Stack used for keeping track of regexp syntax. */
  tre_stack_t *stack;
  /* The parse result. */
  tre_ast_node_t *result;
  /* The regexp to parse and its length. */
  const tre_char_t *re;
  /* The first character of the entire regexp. */
  const tre_char_t *re_start;
  /* The first character after the end of the regexp. */
  const tre_char_t *re_end;
  int len;
  /* Current submatch ID. */
  int submatch_id;
  /* Current position (number of literal). */
  int position;
  /* The highest back reference or -1 if none seen so far. */
  int max_backref;
  /* This flag is set if the regexp uses approximate matching. */
  int have_approx;
  /* Compilation flags. */
  int cflags;
  /* If this flag is set the top-level submatch is not captured. */
  int nofirstsub;
  /* The currently set approximate matching parameters. */
  int params[TRE_PARAM_LAST];
} tre_parse_ctx_t;

/* Parses a wide character regexp pattern into a syntax tree.  This parser
   handles both syntaxes (BRE and ERE), including the TRE extensions. */
reg_errcode_t
tre_parse(tre_parse_ctx_t *ctx);

#endif /* TRE_PARSE_H */

/* EOF */

/*
  Algorithms to setup tags so that submatch addressing can be done.
*/


/* Inserts a catenation node to the root of the tree given in `node'.
   As the left child a new tag with number `tag_id' to `node' is added,
   and the right child is the old root. */
static reg_errcode_t
tre_add_tag_left(tre_mem_t mem, tre_ast_node_t *node, int tag_id)
{
  tre_catenation_t *c;

  DPRINT(("add_tag_left: tag %d\n", tag_id));

  c = tre_mem_alloc(mem, sizeof(*c));
  if (c == NULL)
    return REG_ESPACE;
  c->left = tre_ast_new_literal(mem, TAG, tag_id, -1);
  if (c->left == NULL)
    return REG_ESPACE;
  c->right = tre_mem_alloc(mem, sizeof(tre_ast_node_t));
  if (c->right == NULL)
    return REG_ESPACE;

  c->right->obj = node->obj;
  c->right->type = node->type;
  c->right->nullable = -1;
  c->right->submatch_id = -1;
  c->right->firstpos = NULL;
  c->right->lastpos = NULL;
  c->right->num_tags = 0;
  node->obj = c;
  node->type = CATENATION;
  return REG_OK;
}

/* Inserts a catenation node to the root of the tree given in `node'.
   As the right child a new tag with number `tag_id' to `node' is added,
   and the left child is the old root. */
static reg_errcode_t
tre_add_tag_right(tre_mem_t mem, tre_ast_node_t *node, int tag_id)
{
  tre_catenation_t *c;

  DPRINT(("tre_add_tag_right: tag %d\n", tag_id));

  c = tre_mem_alloc(mem, sizeof(*c));
  if (c == NULL)
    return REG_ESPACE;
  c->right = tre_ast_new_literal(mem, TAG, tag_id, -1);
  if (c->right == NULL)
    return REG_ESPACE;
  c->left = tre_mem_alloc(mem, sizeof(tre_ast_node_t));
  if (c->left == NULL)
    return REG_ESPACE;

  c->left->obj = node->obj;
  c->left->type = node->type;
  c->left->nullable = -1;
  c->left->submatch_id = -1;
  c->left->firstpos = NULL;
  c->left->lastpos = NULL;
  c->left->num_tags = 0;
  node->obj = c;
  node->type = CATENATION;
  return REG_OK;
}

typedef enum {
  ADDTAGS_RECURSE,
  ADDTAGS_AFTER_ITERATION,
  ADDTAGS_AFTER_UNION_LEFT,
  ADDTAGS_AFTER_UNION_RIGHT,
  ADDTAGS_AFTER_CAT_LEFT,
  ADDTAGS_AFTER_CAT_RIGHT,
  ADDTAGS_SET_SUBMATCH_END
} tre_addtags_symbol_t;


typedef struct {
  int tag;
  int next_tag;
} tre_tag_states_t;


/* Go through `regset' and set submatch data for submatches that are
   using this tag. */
static void
tre_purge_regset(int *regset, tre_tnfa_t *tnfa, int tag)
{
  int i;

  for (i = 0; regset[i] >= 0; i++)
    {
      int id = regset[i] / 2;
      int start = !(regset[i] % 2);
      DPRINT(("  Using tag %d for %s offset of "
	      "submatch %d\n", tag,
	      start ? "start" : "end", id));
      if (start)
	tnfa->submatch_data[id].so_tag = tag;
      else
	tnfa->submatch_data[id].eo_tag = tag;
    }
  regset[0] = -1;
}


/* Adds tags to appropriate locations in the parse tree in `tree', so that
   subexpressions marked for submatch addressing can be traced. */
static reg_errcode_t
tre_add_tags(tre_mem_t mem, tre_stack_t *stack, tre_ast_node_t *tree,
	     tre_tnfa_t *tnfa)
{
  reg_errcode_t status = REG_OK;
  tre_addtags_symbol_t symbol;
  tre_ast_node_t *node = tree; /* Tree node we are currently looking at. */
  int bottom = tre_stack_num_objects(stack);
  /* True for first pass (counting number of needed tags) */
  int first_pass = (mem == NULL || tnfa == NULL);
  int *regset, *orig_regset;
  int num_tags = 0; /* Total number of tags. */
  int num_minimals = 0;	 /* Number of special minimal tags. */
  int tag = 0;	    /* The tag that is to be added next. */
  int next_tag = 1; /* Next tag to use after this one. */
  int *parents;	    /* Stack of submatches the current submatch is
		       contained in. */
  int minimal_tag = -1; /* Tag that marks the beginning of a minimal match. */
  tre_tag_states_t *saved_states;

  tre_tag_direction_t direction = TRE_TAG_MINIMIZE;
  if (!first_pass)
    {
      tnfa->end_tag = 0;
      tnfa->minimal_tags[0] = -1;
    }

  regset = xmalloc(sizeof(*regset) * ((tnfa->num_submatches + 1) * 2));
  if (regset == NULL)
    return REG_ESPACE;
  regset[0] = -1;
  orig_regset = regset;

  parents = xmalloc(sizeof(*parents) * (tnfa->num_submatches + 1));
  if (parents == NULL)
    {
      xfree(regset);
      return REG_ESPACE;
    }
  parents[0] = -1;

  saved_states = xmalloc(sizeof(*saved_states) * (tnfa->num_submatches + 1));
  if (saved_states == NULL)
    {
      xfree(regset);
      xfree(parents);
      return REG_ESPACE;
    }
  else
    {
      unsigned int i;
      for (i = 0; i <= tnfa->num_submatches; i++)
	saved_states[i].tag = -1;
    }

  STACK_PUSH(stack, voidptr, node);
  STACK_PUSH(stack, int, ADDTAGS_RECURSE);

  while (tre_stack_num_objects(stack) > bottom)
    {
      if (status != REG_OK)
	break;

      symbol = (tre_addtags_symbol_t)tre_stack_pop_int(stack);
      switch (symbol)
	{

	case ADDTAGS_SET_SUBMATCH_END:
	  {
	    int id = tre_stack_pop_int(stack);
	    int i;

	    /* Add end of this submatch to regset. */
	    for (i = 0; regset[i] >= 0; i++);
	    regset[i] = id * 2 + 1;
	    regset[i + 1] = -1;

	    /* Pop this submatch from the parents stack. */
	    for (i = 0; parents[i] >= 0; i++);
	    parents[i - 1] = -1;
	    break;
	  }

	case ADDTAGS_RECURSE:
	  node = tre_stack_pop_voidptr(stack);

	  if (node->submatch_id >= 0)
	    {
	      int id = node->submatch_id;
	      int i;


	      /* Add start of this submatch to regset. */
	      for (i = 0; regset[i] >= 0; i++);
	      regset[i] = id * 2;
	      regset[i + 1] = -1;

	      if (!first_pass)
		{
		  for (i = 0; parents[i] >= 0; i++);
		  tnfa->submatch_data[id].parents = NULL;
		  if (i > 0)
		    {
		      int *p = xmalloc(sizeof(*p) * (i + 1));
		      if (p == NULL)
			{
			  status = REG_ESPACE;
			  break;
			}
		      assert(tnfa->submatch_data[id].parents == NULL);
		      tnfa->submatch_data[id].parents = p;
		      for (i = 0; parents[i] >= 0; i++)
			p[i] = parents[i];
		      p[i] = -1;
		    }
		}

	      /* Add end of this submatch to regset after processing this
		 node. */
	      STACK_PUSHX(stack, int, node->submatch_id);
	      STACK_PUSHX(stack, int, ADDTAGS_SET_SUBMATCH_END);
	    }

	  switch (node->type)
	    {
	    case LITERAL:
	      {
		tre_literal_t *lit = node->obj;

		if (!IS_SPECIAL(lit) || IS_BACKREF(lit))
		  {
		    int i;
		    DPRINT(("Literal %d-%d\n",
			    (int)lit->code_min, (int)lit->code_max));
		    if (regset[0] >= 0)
		      {
			/* Regset is not empty, so add a tag before the
			   literal or backref. */
			if (!first_pass)
			  {
			    status = tre_add_tag_left(mem, node, tag);
			    tnfa->tag_directions[tag] = direction;
			    if (minimal_tag >= 0)
			      {
				DPRINT(("Minimal %d, %d\n", minimal_tag, tag));
				for (i = 0; tnfa->minimal_tags[i] >= 0; i++);
				tnfa->minimal_tags[i] = tag;
				tnfa->minimal_tags[i + 1] = minimal_tag;
				tnfa->minimal_tags[i + 2] = -1;
				minimal_tag = -1;
				num_minimals++;
			      }
			    tre_purge_regset(regset, tnfa, tag);
			  }
			else
			  {
			    DPRINT(("  num_tags = 1\n"));
			    node->num_tags = 1;
			  }

			DPRINT(("  num_tags++\n"));
			regset[0] = -1;
			tag = next_tag;
			num_tags++;
			next_tag++;
		      }
		  }
		else
		  {
		    assert(!IS_TAG(lit));
		  }
		break;
	      }
	    case CATENATION:
	      {
		tre_catenation_t *cat = node->obj;
		tre_ast_node_t *left = cat->left;
		tre_ast_node_t *right = cat->right;
		int reserved_tag = -1;
		DPRINT(("Catenation, next_tag = %d\n", next_tag));


		/* After processing right child. */
		STACK_PUSHX(stack, voidptr, node);
		STACK_PUSHX(stack, int, ADDTAGS_AFTER_CAT_RIGHT);

		/* Process right child. */
		STACK_PUSHX(stack, voidptr, right);
		STACK_PUSHX(stack, int, ADDTAGS_RECURSE);

		/* After processing left child. */
		STACK_PUSHX(stack, int, next_tag + left->num_tags);
		DPRINT(("  Pushing %d for after left\n",
			next_tag + left->num_tags));
		if (left->num_tags > 0 && right->num_tags > 0)
		  {
		    /* Reserve the next tag to the right child. */
		    DPRINT(("  Reserving next_tag %d to right child\n",
			    next_tag));
		    reserved_tag = next_tag;
		    next_tag++;
		  }
		STACK_PUSHX(stack, int, reserved_tag);
		STACK_PUSHX(stack, int, ADDTAGS_AFTER_CAT_LEFT);

		/* Process left child. */
		STACK_PUSHX(stack, voidptr, left);
		STACK_PUSHX(stack, int, ADDTAGS_RECURSE);

		}
	      break;
	    case ITERATION:
	      {
		tre_iteration_t *iter = node->obj;
		DPRINT(("Iteration\n"));

		if (first_pass)
		  {
		    STACK_PUSHX(stack, int, regset[0] >= 0 || iter->minimal);
		  }
		else
		  {
		    STACK_PUSHX(stack, int, tag);
		    STACK_PUSHX(stack, int, iter->minimal);
		  }
		STACK_PUSHX(stack, voidptr, node);
		STACK_PUSHX(stack, int, ADDTAGS_AFTER_ITERATION);

		STACK_PUSHX(stack, voidptr, iter->arg);
		STACK_PUSHX(stack, int, ADDTAGS_RECURSE);

		/* Regset is not empty, so add a tag here. */
		if (regset[0] >= 0 || iter->minimal)
		  {
		    if (!first_pass)
		      {
			int i;
			status = tre_add_tag_left(mem, node, tag);
			if (iter->minimal)
			  tnfa->tag_directions[tag] = TRE_TAG_MAXIMIZE;
			else
			  tnfa->tag_directions[tag] = direction;
			if (minimal_tag >= 0)
			  {
			    DPRINT(("Minimal %d, %d\n", minimal_tag, tag));
			    for (i = 0; tnfa->minimal_tags[i] >= 0; i++);
			    tnfa->minimal_tags[i] = tag;
			    tnfa->minimal_tags[i + 1] = minimal_tag;
			    tnfa->minimal_tags[i + 2] = -1;
			    minimal_tag = -1;
			    num_minimals++;
			  }
			tre_purge_regset(regset, tnfa, tag);
		      }

		    DPRINT(("  num_tags++\n"));
		    regset[0] = -1;
		    tag = next_tag;
		    num_tags++;
		    next_tag++;
		  }
		direction = TRE_TAG_MINIMIZE;
	      }
	      break;
	    case UNION:
	      {
		tre_union_t *uni = node->obj;
		tre_ast_node_t *left = uni->left;
		tre_ast_node_t *right = uni->right;
		int left_tag;
		int right_tag;

		if (regset[0] >= 0)
		  {
		    left_tag = next_tag;
		    right_tag = next_tag + 1;
		  }
		else
		  {
		    left_tag = tag;
		    right_tag = next_tag;
		  }

		DPRINT(("Union\n"));

		/* After processing right child. */
		STACK_PUSHX(stack, int, right_tag);
		STACK_PUSHX(stack, int, left_tag);
		STACK_PUSHX(stack, voidptr, regset);
		STACK_PUSHX(stack, int, regset[0] >= 0);
		STACK_PUSHX(stack, voidptr, node);
		STACK_PUSHX(stack, voidptr, right);
		STACK_PUSHX(stack, voidptr, left);
		STACK_PUSHX(stack, int, ADDTAGS_AFTER_UNION_RIGHT);

		/* Process right child. */
		STACK_PUSHX(stack, voidptr, right);
		STACK_PUSHX(stack, int, ADDTAGS_RECURSE);

		/* After processing left child. */
		STACK_PUSHX(stack, int, ADDTAGS_AFTER_UNION_LEFT);

		/* Process left child. */
		STACK_PUSHX(stack, voidptr, left);
		STACK_PUSHX(stack, int, ADDTAGS_RECURSE);

		/* Regset is not empty, so add a tag here. */
		if (regset[0] >= 0)
		  {
		    if (!first_pass)
		      {
			int i;
			status = tre_add_tag_left(mem, node, tag);
			tnfa->tag_directions[tag] = direction;
			if (minimal_tag >= 0)
			  {
			    DPRINT(("Minimal %d, %d\n", minimal_tag, tag));
			    for (i = 0; tnfa->minimal_tags[i] >= 0; i++);
			    tnfa->minimal_tags[i] = tag;
			    tnfa->minimal_tags[i + 1] = minimal_tag;
			    tnfa->minimal_tags[i + 2] = -1;
			    minimal_tag = -1;
			    num_minimals++;
			  }
			tre_purge_regset(regset, tnfa, tag);
		      }

		    DPRINT(("  num_tags++\n"));
		    regset[0] = -1;
		    tag = next_tag;
		    num_tags++;
		    next_tag++;
		  }

		if (node->num_submatches > 0)
		  {
		    /* The next two tags are reserved for markers. */
		    next_tag++;
		    tag = next_tag;
		    next_tag++;
		  }

		break;
	      }
	    }

	  if (node->submatch_id >= 0)
	    {
	      int i;
	      /* Push this submatch on the parents stack. */
	      for (i = 0; parents[i] >= 0; i++);
	      parents[i] = node->submatch_id;
	      parents[i + 1] = -1;
	    }

	  break; /* end case: ADDTAGS_RECURSE */

	case ADDTAGS_AFTER_ITERATION:
	  {
	    int minimal = 0;
	    int enter_tag;
	    node = tre_stack_pop_voidptr(stack);
	    if (first_pass)
	      {
		node->num_tags = ((tre_iteration_t *)node->obj)->arg->num_tags
		  + tre_stack_pop_int(stack);
		minimal_tag = -1;
	      }
	    else
	      {
		minimal = tre_stack_pop_int(stack);
		enter_tag = tre_stack_pop_int(stack);
		if (minimal)
		  minimal_tag = enter_tag;
	      }

	    DPRINT(("After iteration\n"));
	    if (!first_pass)
	      {
		DPRINT(("  Setting direction to %s\n",
			minimal ? "minimize" : "maximize"));
		if (minimal)
		  direction = TRE_TAG_MINIMIZE;
		else
		  direction = TRE_TAG_MAXIMIZE;
	      }
	    break;
	  }

	case ADDTAGS_AFTER_CAT_LEFT:
	  {
	    int new_tag = tre_stack_pop_int(stack);
	    next_tag = tre_stack_pop_int(stack);
	    DPRINT(("After cat left, tag = %d, next_tag = %d\n",
		    tag, next_tag));
	    if (new_tag >= 0)
	      {
		DPRINT(("  Setting tag to %d\n", new_tag));
		tag = new_tag;
	      }
	    break;
	  }

	case ADDTAGS_AFTER_CAT_RIGHT:
	  DPRINT(("After cat right\n"));
	  node = tre_stack_pop_voidptr(stack);
	  if (first_pass)
	    node->num_tags = ((tre_catenation_t *)node->obj)->left->num_tags
	      + ((tre_catenation_t *)node->obj)->right->num_tags;
	  break;

	case ADDTAGS_AFTER_UNION_LEFT:
	  DPRINT(("After union left\n"));
	  /* Lift the bottom of the `regset' array so that when processing
	     the right operand the items currently in the array are
	     invisible.	 The original bottom was saved at ADDTAGS_UNION and
	     will be restored at ADDTAGS_AFTER_UNION_RIGHT below. */
	  while (*regset >= 0)
	    regset++;
	  break;

	case ADDTAGS_AFTER_UNION_RIGHT:
	  {
	    int added_tags, tag_left, tag_right;
	    tre_ast_node_t *left = tre_stack_pop_voidptr(stack);
	    tre_ast_node_t *right = tre_stack_pop_voidptr(stack);
	    DPRINT(("After union right\n"));
	    node = tre_stack_pop_voidptr(stack);
	    added_tags = tre_stack_pop_int(stack);
	    if (first_pass)
	      {
		node->num_tags = ((tre_union_t *)node->obj)->left->num_tags
		  + ((tre_union_t *)node->obj)->right->num_tags + added_tags
		  + ((node->num_submatches > 0) ? 2 : 0);
	      }
	    regset = tre_stack_pop_voidptr(stack);
	    tag_left = tre_stack_pop_int(stack);
	    tag_right = tre_stack_pop_int(stack);

	    /* Add tags after both children, the left child gets a smaller
	       tag than the right child.  This guarantees that we prefer
	       the left child over the right child. */
	    /* XXX - This is not always necessary (if the children have
	       tags which must be seen for every match of that child). */
	    /* XXX - Check if this is the only place where tre_add_tag_right
	       is used.	 If so, use tre_add_tag_left (putting the tag before
	       the child as opposed after the child) and throw away
	       tre_add_tag_right. */
	    if (node->num_submatches > 0)
	      {
		if (!first_pass)
		  {
		    status = tre_add_tag_right(mem, left, tag_left);
		    tnfa->tag_directions[tag_left] = TRE_TAG_MAXIMIZE;
		    status = tre_add_tag_right(mem, right, tag_right);
		    tnfa->tag_directions[tag_right] = TRE_TAG_MAXIMIZE;
		  }
		DPRINT(("  num_tags += 2\n"));
		num_tags += 2;
	      }
	    direction = TRE_TAG_MAXIMIZE;
	    break;
	  }

	default:
	  assert(0);
	  break;

	} /* end switch(symbol) */
    } /* end while(tre_stack_num_objects(stack) > bottom) */

  if (!first_pass)
    tre_purge_regset(regset, tnfa, tag);

  if (!first_pass && minimal_tag >= 0)
    {
      int i;
      DPRINT(("Minimal %d, %d\n", minimal_tag, tag));
      for (i = 0; tnfa->minimal_tags[i] >= 0; i++);
      tnfa->minimal_tags[i] = tag;
      tnfa->minimal_tags[i + 1] = minimal_tag;
      tnfa->minimal_tags[i + 2] = -1;
      minimal_tag = -1;
      num_minimals++;
    }

  DPRINT(("tre_add_tags: %s complete.  Number of tags %d.\n",
	  first_pass? "First pass" : "Second pass", num_tags));

  assert(tree->num_tags == num_tags);
  tnfa->end_tag = num_tags;
  tnfa->num_tags = num_tags;
  tnfa->num_minimals = num_minimals;
  xfree(orig_regset);
  xfree(parents);
  xfree(saved_states);
  return status;
}



/*
  AST to TNFA compilation routines.
*/

typedef enum {
  COPY_RECURSE,
  COPY_SET_RESULT_PTR
} tre_copyast_symbol_t;

/* Flags for tre_copy_ast(). */
#define COPY_REMOVE_TAGS	 1
#define COPY_MAXIMIZE_FIRST_TAG	 2

static reg_errcode_t
tre_copy_ast(tre_mem_t mem, tre_stack_t *stack, tre_ast_node_t *ast,
	     int flags, int *pos_add, tre_tag_direction_t *tag_directions,
	     tre_ast_node_t **copy, int *max_pos)
{
  reg_errcode_t status = REG_OK;
  int bottom = tre_stack_num_objects(stack);
  int num_copied = 0;
  int first_tag = 1;
  tre_ast_node_t **result = copy;
  tre_copyast_symbol_t symbol;

  STACK_PUSH(stack, voidptr, ast);
  STACK_PUSH(stack, int, COPY_RECURSE);

  while (status == REG_OK && tre_stack_num_objects(stack) > bottom)
    {
      tre_ast_node_t *node;
      if (status != REG_OK)
	break;

      symbol = (tre_copyast_symbol_t)tre_stack_pop_int(stack);
      switch (symbol)
	{
	case COPY_SET_RESULT_PTR:
	  result = tre_stack_pop_voidptr(stack);
	  break;
	case COPY_RECURSE:
	  node = tre_stack_pop_voidptr(stack);
	  switch (node->type)
	    {
	    case LITERAL:
	      {
		tre_literal_t *lit = node->obj;
		int pos = lit->position;
		int min = lit->code_min;
		int max = lit->code_max;
		if (!IS_SPECIAL(lit) || IS_BACKREF(lit))
		  {
		    /* XXX - e.g. [ab] has only one position but two
		       nodes, so we are creating holes in the state space
		       here.  Not fatal, just wastes memory. */
		    pos += *pos_add;
		    num_copied++;
		  }
		else if (IS_TAG(lit) && (flags & COPY_REMOVE_TAGS))
		  {
		    /* Change this tag to empty. */
		    min = EMPTY;
		    max = pos = -1;
		  }
		else if (IS_TAG(lit) && (flags & COPY_MAXIMIZE_FIRST_TAG)
			 && first_tag)
		  {
		    /* Maximize the first tag. */
		    tag_directions[max] = TRE_TAG_MAXIMIZE;
		    first_tag = 0;
		  }
		*result = tre_ast_new_literal(mem, min, max, pos);
		if (*result == NULL)
		  status = REG_ESPACE;

		if (pos > *max_pos)
		  *max_pos = pos;
		break;
	      }
	    case UNION:
	      {
		tre_union_t *uni = node->obj;
		tre_union_t *tmp;
		*result = tre_ast_new_union(mem, uni->left, uni->right);
		if (*result == NULL)
		  {
		    status = REG_ESPACE;
		    break;
		  }
		tmp = (*result)->obj;
		result = &tmp->left;
		STACK_PUSHX(stack, voidptr, uni->right);
		STACK_PUSHX(stack, int, COPY_RECURSE);
		STACK_PUSHX(stack, voidptr, &tmp->right);
		STACK_PUSHX(stack, int, COPY_SET_RESULT_PTR);
		STACK_PUSHX(stack, voidptr, uni->left);
		STACK_PUSHX(stack, int, COPY_RECURSE);
		break;
	      }
	    case CATENATION:
	      {
		tre_catenation_t *cat = node->obj;
		tre_catenation_t *tmp;
		*result = tre_ast_new_catenation(mem, cat->left, cat->right);
		if (*result == NULL)
		  {
		    status = REG_ESPACE;
		    break;
		  }
		tmp = (*result)->obj;
		tmp->left = NULL;
		tmp->right = NULL;
		result = &tmp->left;

		STACK_PUSHX(stack, voidptr, cat->right);
		STACK_PUSHX(stack, int, COPY_RECURSE);
		STACK_PUSHX(stack, voidptr, &tmp->right);
		STACK_PUSHX(stack, int, COPY_SET_RESULT_PTR);
		STACK_PUSHX(stack, voidptr, cat->left);
		STACK_PUSHX(stack, int, COPY_RECURSE);
		break;
	      }
	    case ITERATION:
	      {
		tre_iteration_t *iter = node->obj;
		STACK_PUSHX(stack, voidptr, iter->arg);
		STACK_PUSHX(stack, int, COPY_RECURSE);
		*result = tre_ast_new_iter(mem, iter->arg, iter->min,
					   iter->max, iter->minimal);
		if (*result == NULL)
		  {
		    status = REG_ESPACE;
		    break;
		  }
		iter = (*result)->obj;
		result = &iter->arg;
		break;
	      }
	    default:
	      assert(0);
	      break;
	    }
	  break;
	}
    }
  *pos_add += num_copied;
  return status;
}

typedef enum {
  EXPAND_RECURSE,
  EXPAND_AFTER_ITER
} tre_expand_ast_symbol_t;

/* Expands each iteration node that has a finite nonzero minimum or maximum
   iteration count to a catenated sequence of copies of the node. */
static reg_errcode_t
tre_expand_ast(tre_mem_t mem, tre_stack_t *stack, tre_ast_node_t *ast,
	       int *position, tre_tag_direction_t *tag_directions,
	       int *max_depth)
{
  reg_errcode_t status = REG_OK;
  int bottom = tre_stack_num_objects(stack);
  int pos_add = 0;
  int pos_add_total = 0;
  int max_pos = 0;
  /* Current approximate matching parameters. */
  int params[TRE_PARAM_LAST];
  /* Approximate parameter nesting level. */
  int params_depth = 0;
  int iter_depth = 0;
  int i;

  for (i = 0; i < TRE_PARAM_LAST; i++)
    params[i] = TRE_PARAM_DEFAULT;

  STACK_PUSHR(stack, voidptr, ast);
  STACK_PUSHR(stack, int, EXPAND_RECURSE);
  while (status == REG_OK && tre_stack_num_objects(stack) > bottom)
    {
      tre_ast_node_t *node;
      tre_expand_ast_symbol_t symbol;

      if (status != REG_OK)
	break;

      DPRINT(("pos_add %d\n", pos_add));

      symbol = (tre_expand_ast_symbol_t)tre_stack_pop_int(stack);
      node = tre_stack_pop_voidptr(stack);
      switch (symbol)
	{
	case EXPAND_RECURSE:
	  switch (node->type)
	    {
	    case LITERAL:
	      {
		tre_literal_t *lit= node->obj;
		if (!IS_SPECIAL(lit) || IS_BACKREF(lit))
		  {
		    lit->position += pos_add;
		    if (lit->position > max_pos)
		      max_pos = lit->position;
		  }
		break;
	      }
	    case UNION:
	      {
		tre_union_t *uni = node->obj;
		STACK_PUSHX(stack, voidptr, uni->right);
		STACK_PUSHX(stack, int, EXPAND_RECURSE);
		STACK_PUSHX(stack, voidptr, uni->left);
		STACK_PUSHX(stack, int, EXPAND_RECURSE);
		break;
	      }
	    case CATENATION:
	      {
		tre_catenation_t *cat = node->obj;
		STACK_PUSHX(stack, voidptr, cat->right);
		STACK_PUSHX(stack, int, EXPAND_RECURSE);
		STACK_PUSHX(stack, voidptr, cat->left);
		STACK_PUSHX(stack, int, EXPAND_RECURSE);
		break;
	      }
	    case ITERATION:
	      {
		tre_iteration_t *iter = node->obj;
		STACK_PUSHX(stack, int, pos_add);
		STACK_PUSHX(stack, voidptr, node);
		STACK_PUSHX(stack, int, EXPAND_AFTER_ITER);
		STACK_PUSHX(stack, voidptr, iter->arg);
		STACK_PUSHX(stack, int, EXPAND_RECURSE);
		/* If we are going to expand this node at EXPAND_AFTER_ITER
		   then don't increase the `pos' fields of the nodes now, it
		   will get done when expanding. */
		if (iter->min > 1 || iter->max > 1)
		  pos_add = 0;
		iter_depth++;
		DPRINT(("iter\n"));
		break;
	      }
	    default:
	      assert(0);
	      break;
	    }
	  break;
	case EXPAND_AFTER_ITER:
	  {
	    tre_iteration_t *iter = node->obj;
	    int pos_add_last;
	    pos_add = tre_stack_pop_int(stack);
	    pos_add_last = pos_add;
	    if (iter->min > 1 || iter->max > 1)
	      {
		tre_ast_node_t *seq1 = NULL, *seq2 = NULL;
		int j;
		int pos_add_save = pos_add;

		/* Create a catenated sequence of copies of the node. */
		for (j = 0; j < iter->min; j++)
		  {
		    tre_ast_node_t *copy;
		    /* Remove tags from all but the last copy. */
		    int flags = ((j + 1 < iter->min)
				 ? COPY_REMOVE_TAGS
				 : COPY_MAXIMIZE_FIRST_TAG);
		    DPRINT(("  pos_add %d\n", pos_add));
		    pos_add_save = pos_add;
		    status = tre_copy_ast(mem, stack, iter->arg, flags,
					  &pos_add, tag_directions, &copy,
					  &max_pos);
		    if (status != REG_OK)
		      return status;
		    if (seq1 != NULL)
		      seq1 = tre_ast_new_catenation(mem, seq1, copy);
		    else
		      seq1 = copy;
		    if (seq1 == NULL)
		      return REG_ESPACE;
		  }

		if (iter->max == -1)
		  {
		    /* No upper limit. */
		    pos_add_save = pos_add;
		    status = tre_copy_ast(mem, stack, iter->arg, 0,
					  &pos_add, NULL, &seq2, &max_pos);
		    if (status != REG_OK)
		      return status;
		    seq2 = tre_ast_new_iter(mem, seq2, 0, -1, 0);
		    if (seq2 == NULL)
		      return REG_ESPACE;
		  }
		else
		  {
		    for (j = iter->min; j < iter->max; j++)
		      {
			tre_ast_node_t *tmp, *copy;
			pos_add_save = pos_add;
			status = tre_copy_ast(mem, stack, iter->arg, 0,
					      &pos_add, NULL, &copy, &max_pos);
			if (status != REG_OK)
			  return status;
			if (seq2 != NULL)
			  seq2 = tre_ast_new_catenation(mem, copy, seq2);
			else
			  seq2 = copy;
			if (seq2 == NULL)
			  return REG_ESPACE;
			tmp = tre_ast_new_literal(mem, EMPTY, -1, -1);
			if (tmp == NULL)
			  return REG_ESPACE;
			seq2 = tre_ast_new_union(mem, tmp, seq2);
			if (seq2 == NULL)
			  return REG_ESPACE;
		      }
		  }

		pos_add = pos_add_save;
		if (seq1 == NULL)
		  seq1 = seq2;
		else if (seq2 != NULL)
		  seq1 = tre_ast_new_catenation(mem, seq1, seq2);
		if (seq1 == NULL)
		  return REG_ESPACE;
		node->obj = seq1->obj;
		node->type = seq1->type;
	      }

	    iter_depth--;
	    pos_add_total += pos_add - pos_add_last;
	    if (iter_depth == 0)
	      pos_add = pos_add_total;

	    /* If approximate parameters are specified, surround the result
	       with two parameter setting nodes.  The one on the left sets
	       the specified parameters, and the one on the right restores
	       the old parameters. */
	    if (iter->params)
	      {
		tre_ast_node_t *tmp_l, *tmp_r, *tmp_node, *node_copy;
		int *old_params;

		tmp_l = tre_ast_new_literal(mem, PARAMETER, 0, -1);
		if (!tmp_l)
		  return REG_ESPACE;
		((tre_literal_t *)tmp_l->obj)->u.params = iter->params;
		iter->params[TRE_PARAM_DEPTH] = params_depth + 1;
		tmp_r = tre_ast_new_literal(mem, PARAMETER, 0, -1);
		if (!tmp_r)
		  return REG_ESPACE;
		old_params = tre_mem_alloc(mem, sizeof(*old_params)
					   * TRE_PARAM_LAST);
		if (!old_params)
		  return REG_ESPACE;
		for (i = 0; i < TRE_PARAM_LAST; i++)
		  old_params[i] = params[i];
		((tre_literal_t *)tmp_r->obj)->u.params = old_params;
		old_params[TRE_PARAM_DEPTH] = params_depth;
		/* XXX - this is the only place where ast_new_node is
		   needed -- should be moved inside AST module. */
		node_copy = tre_ast_new_node(mem, ITERATION,
					     sizeof(tre_iteration_t));
		if (!node_copy)
		  return REG_ESPACE;
		node_copy->obj = node->obj;
		tmp_node = tre_ast_new_catenation(mem, tmp_l, node_copy);
		if (!tmp_node)
		  return REG_ESPACE;
		tmp_node = tre_ast_new_catenation(mem, tmp_node, tmp_r);
		if (!tmp_node)
		  return REG_ESPACE;
		/* Replace the contents of `node' with `tmp_node'. */
		memcpy(node, tmp_node, sizeof(*node));
		node->obj = tmp_node->obj;
		node->type = tmp_node->type;
		params_depth++;
		if (params_depth > *max_depth)
		  *max_depth = params_depth;
	      }
	    break;
	  }
	default:
	  assert(0);
	  break;
	}
    }

  *position += pos_add_total;

  /* `max_pos' should never be larger than `*position' if the above
     code works, but just an extra safeguard let's make sure
     `*position' is set large enough so enough memory will be
     allocated for the transition table. */
  if (max_pos > *position)
    *position = max_pos;

#ifdef TRE_DEBUG
  DPRINT(("Expanded AST:\n"));
  tre_ast_print(ast);
  DPRINT(("*position %d, max_pos %d\n", *position, max_pos));
#endif

  return status;
}

static tre_pos_and_tags_t *
tre_set_empty(tre_mem_t mem)
{
  tre_pos_and_tags_t *new_set;

  new_set = tre_mem_calloc(mem, sizeof(*new_set));
  if (new_set == NULL)
    return NULL;

  new_set[0].position = -1;
  new_set[0].code_min = -1;
  new_set[0].code_max = -1;

  return new_set;
}

static tre_pos_and_tags_t *
tre_set_one(tre_mem_t mem, int position, int code_min, int code_max,
	    tre_ctype_t class, tre_ctype_t *neg_classes, int backref)
{
  tre_pos_and_tags_t *new_set;

  new_set = tre_mem_calloc(mem, sizeof(*new_set) * 2);
  if (new_set == NULL)
    return NULL;

  new_set[0].position = position;
  new_set[0].code_min = code_min;
  new_set[0].code_max = code_max;
  new_set[0].class = class;
  new_set[0].neg_classes = neg_classes;
  new_set[0].backref = backref;
  new_set[1].position = -1;
  new_set[1].code_min = -1;
  new_set[1].code_max = -1;

  return new_set;
}

static tre_pos_and_tags_t *
tre_set_union(tre_mem_t mem, tre_pos_and_tags_t *set1, tre_pos_and_tags_t *set2,
	      int *tags, int assertions, int *params)
{
  int s1, s2, i, j;
  tre_pos_and_tags_t *new_set;
  int *new_tags;
  int num_tags;

  for (num_tags = 0; tags != NULL && tags[num_tags] >= 0; num_tags++);
  for (s1 = 0; set1[s1].position >= 0; s1++);
  for (s2 = 0; set2[s2].position >= 0; s2++);
  new_set = tre_mem_calloc(mem, sizeof(*new_set) * (s1 + s2 + 1));
  if (!new_set )
    return NULL;

  for (s1 = 0; set1[s1].position >= 0; s1++)
    {
      new_set[s1].position = set1[s1].position;
      new_set[s1].code_min = set1[s1].code_min;
      new_set[s1].code_max = set1[s1].code_max;
      new_set[s1].assertions = set1[s1].assertions | assertions;
      new_set[s1].class = set1[s1].class;
      new_set[s1].neg_classes = set1[s1].neg_classes;
      new_set[s1].backref = set1[s1].backref;
      if (set1[s1].tags == NULL && tags == NULL)
	new_set[s1].tags = NULL;
      else
	{
	  for (i = 0; set1[s1].tags != NULL && set1[s1].tags[i] >= 0; i++);
	  new_tags = tre_mem_alloc(mem, (sizeof(*new_tags)
					 * (i + num_tags + 1)));
	  if (new_tags == NULL)
	    return NULL;
	  for (j = 0; j < i; j++)
	    new_tags[j] = set1[s1].tags[j];
	  for (i = 0; i < num_tags; i++)
	    new_tags[j + i] = tags[i];
	  new_tags[j + i] = -1;
	  new_set[s1].tags = new_tags;
	}
      if (set1[s1].params)
	new_set[s1].params = set1[s1].params;
      if (params)
	{
	  if (!new_set[s1].params)
	    new_set[s1].params = params;
	  else
	    {
	      new_set[s1].params = tre_mem_alloc(mem, sizeof(*params) *
						 TRE_PARAM_LAST);
	      if (!new_set[s1].params)
		return NULL;
	      for (i = 0; i < TRE_PARAM_LAST; i++)
		if (params[i] != TRE_PARAM_UNSET)
		  new_set[s1].params[i] = params[i];
	    }
	}
    }

  for (s2 = 0; set2[s2].position >= 0; s2++)
    {
      new_set[s1 + s2].position = set2[s2].position;
      new_set[s1 + s2].code_min = set2[s2].code_min;
      new_set[s1 + s2].code_max = set2[s2].code_max;
      /* XXX - why not | assertions here as well? */
      new_set[s1 + s2].assertions = set2[s2].assertions;
      new_set[s1 + s2].class = set2[s2].class;
      new_set[s1 + s2].neg_classes = set2[s2].neg_classes;
      new_set[s1 + s2].backref = set2[s2].backref;
      if (set2[s2].tags == NULL)
	new_set[s1 + s2].tags = NULL;
      else
	{
	  for (i = 0; set2[s2].tags[i] >= 0; i++);
	  new_tags = tre_mem_alloc(mem, sizeof(*new_tags) * (i + 1));
	  if (new_tags == NULL)
	    return NULL;
	  for (j = 0; j < i; j++)
	    new_tags[j] = set2[s2].tags[j];
	  new_tags[j] = -1;
	  new_set[s1 + s2].tags = new_tags;
	}
      if (set2[s2].params)
	new_set[s1 + s2].params = set2[s2].params;
      if (params)
	{
	  if (!new_set[s1 + s2].params)
	    new_set[s1 + s2].params = params;
	  else
	    {
	      new_set[s1 + s2].params = tre_mem_alloc(mem, sizeof(*params) *
						      TRE_PARAM_LAST);
	      if (!new_set[s1 + s2].params)
		return NULL;
	      for (i = 0; i < TRE_PARAM_LAST; i++)
		if (params[i] != TRE_PARAM_UNSET)
		  new_set[s1 + s2].params[i] = params[i];
	    }
	}
    }
  new_set[s1 + s2].position = -1;
  return new_set;
}

/* Finds the empty path through `node' which is the one that should be
   taken according to POSIX.2 rules, and adds the tags on that path to
   `tags'.   `tags' may be NULL.  If `num_tags_seen' is not NULL, it is
   set to the number of tags seen on the path. */
static reg_errcode_t
tre_match_empty(tre_stack_t *stack, tre_ast_node_t *node, int *tags,
		int *assertions, int *params, int *num_tags_seen,
		int *params_seen)
{
  tre_literal_t *lit;
  tre_union_t *uni;
  tre_catenation_t *cat;
  tre_iteration_t *iter;
  int i;
  int bottom = tre_stack_num_objects(stack);
  reg_errcode_t status = REG_OK;
  if (num_tags_seen)
    *num_tags_seen = 0;
  if (params_seen)
    *params_seen = 0;

  status = tre_stack_push_voidptr(stack, node);

  /* Walk through the tree recursively. */
  while (status == REG_OK && tre_stack_num_objects(stack) > bottom)
    {
      node = tre_stack_pop_voidptr(stack);

      switch (node->type)
	{
	case LITERAL:
	  lit = (tre_literal_t *)node->obj;
	  switch (lit->code_min)
	    {
	    case TAG:
	      if (lit->code_max >= 0)
		{
		  if (tags != NULL)
		    {
		      /* Add the tag to `tags'. */
		      for (i = 0; tags[i] >= 0; i++)
			if (tags[i] == lit->code_max)
			  break;
		      if (tags[i] < 0)
			{
			  tags[i] = lit->code_max;
			  tags[i + 1] = -1;
			}
		    }
		  if (num_tags_seen)
		    (*num_tags_seen)++;
		}
	      break;
	    case ASSERTION:
	      assert(lit->code_max >= 1
		     || lit->code_max <= ASSERT_LAST);
	      if (assertions != NULL)
		*assertions |= lit->code_max;
	      break;
	    case PARAMETER:
	      if (params != NULL)
		for (i = 0; i < TRE_PARAM_LAST; i++)
		  params[i] = lit->u.params[i];
	      if (params_seen != NULL)
		*params_seen = 1;
	      break;
	    case EMPTY:
	      break;
	    default:
	      assert(0);
	      break;
	    }
	  break;

	case UNION:
	  /* Subexpressions starting earlier take priority over ones
	     starting later, so we prefer the left subexpression over the
	     right subexpression. */
	  uni = (tre_union_t *)node->obj;
	  if (uni->left->nullable)
	    STACK_PUSHX(stack, voidptr, uni->left)
	  else if (uni->right->nullable)
	    STACK_PUSHX(stack, voidptr, uni->right)
	  else
	    assert(0);
	  break;

	case CATENATION:
	  /* The path must go through both children. */
	  cat = (tre_catenation_t *)node->obj;
	  assert(cat->left->nullable);
	  assert(cat->right->nullable);
	  STACK_PUSHX(stack, voidptr, cat->left);
	  STACK_PUSHX(stack, voidptr, cat->right);
	  break;

	case ITERATION:
	  /* A match with an empty string is preferred over no match at
	     all, so we go through the argument if possible. */
	  iter = (tre_iteration_t *)node->obj;
	  if (iter->arg->nullable)
	    STACK_PUSHX(stack, voidptr, iter->arg);
	  break;

	default:
	  assert(0);
	  break;
	}
    }

  return status;
}


typedef enum {
  NFL_RECURSE,
  NFL_POST_UNION,
  NFL_POST_CATENATION,
  NFL_POST_ITERATION
} tre_nfl_stack_symbol_t;


/* Computes and fills in the fields `nullable', `firstpos', and `lastpos' for
   the nodes of the AST `tree'. */
static reg_errcode_t
tre_compute_nfl(tre_mem_t mem, tre_stack_t *stack, tre_ast_node_t *tree)
{
  int bottom = tre_stack_num_objects(stack);

  STACK_PUSHR(stack, voidptr, tree);
  STACK_PUSHR(stack, int, NFL_RECURSE);

  while (tre_stack_num_objects(stack) > bottom)
    {
      tre_nfl_stack_symbol_t symbol;
      tre_ast_node_t *node;

      symbol = (tre_nfl_stack_symbol_t)tre_stack_pop_int(stack);
      node = tre_stack_pop_voidptr(stack);
      switch (symbol)
	{
	case NFL_RECURSE:
	  switch (node->type)
	    {
	    case LITERAL:
	      {
		tre_literal_t *lit = (tre_literal_t *)node->obj;
		if (IS_BACKREF(lit))
		  {
		    /* Back references: nullable = false, firstpos = {i},
		       lastpos = {i}. */
		    node->nullable = 0;
		    node->firstpos = tre_set_one(mem, lit->position, 0,
					     TRE_CHAR_MAX, 0, NULL, -1);
		    if (!node->firstpos)
		      return REG_ESPACE;
		    node->lastpos = tre_set_one(mem, lit->position, 0,
						TRE_CHAR_MAX, 0, NULL,
						(int)lit->code_max);
		    if (!node->lastpos)
		      return REG_ESPACE;
		  }
		else if (lit->code_min < 0)
		  {
		    /* Tags, empty strings, params, and zero width assertions:
		       nullable = true, firstpos = {}, and lastpos = {}. */
		    node->nullable = 1;
		    node->firstpos = tre_set_empty(mem);
		    if (!node->firstpos)
		      return REG_ESPACE;
		    node->lastpos = tre_set_empty(mem);
		    if (!node->lastpos)
		      return REG_ESPACE;
		  }
		else
		  {
		    /* Literal at position i: nullable = false, firstpos = {i},
		       lastpos = {i}. */
		    node->nullable = 0;
		    node->firstpos =
		      tre_set_one(mem, lit->position, (int)lit->code_min,
				  (int)lit->code_max, 0, NULL, -1);
		    if (!node->firstpos)
		      return REG_ESPACE;
		    node->lastpos = tre_set_one(mem, lit->position,
						(int)lit->code_min,
						(int)lit->code_max,
						lit->u.class, lit->neg_classes,
						-1);
		    if (!node->lastpos)
		      return REG_ESPACE;
		  }
		break;
	      }

	    case UNION:
	      /* Compute the attributes for the two subtrees, and after that
		 for this node. */
	      STACK_PUSHR(stack, voidptr, node);
	      STACK_PUSHR(stack, int, NFL_POST_UNION);
	      STACK_PUSHR(stack, voidptr, ((tre_union_t *)node->obj)->right);
	      STACK_PUSHR(stack, int, NFL_RECURSE);
	      STACK_PUSHR(stack, voidptr, ((tre_union_t *)node->obj)->left);
	      STACK_PUSHR(stack, int, NFL_RECURSE);
	      break;

	    case CATENATION:
	      /* Compute the attributes for the two subtrees, and after that
		 for this node. */
	      STACK_PUSHR(stack, voidptr, node);
	      STACK_PUSHR(stack, int, NFL_POST_CATENATION);
	      STACK_PUSHR(stack, voidptr, ((tre_catenation_t *)node->obj)->right);
	      STACK_PUSHR(stack, int, NFL_RECURSE);
	      STACK_PUSHR(stack, voidptr, ((tre_catenation_t *)node->obj)->left);
	      STACK_PUSHR(stack, int, NFL_RECURSE);
	      break;

	    case ITERATION:
	      /* Compute the attributes for the subtree, and after that for
		 this node. */
	      STACK_PUSHR(stack, voidptr, node);
	      STACK_PUSHR(stack, int, NFL_POST_ITERATION);
	      STACK_PUSHR(stack, voidptr, ((tre_iteration_t *)node->obj)->arg);
	      STACK_PUSHR(stack, int, NFL_RECURSE);
	      break;
	    }
	  break; /* end case: NFL_RECURSE */

	case NFL_POST_UNION:
	  {
	    tre_union_t *uni = (tre_union_t *)node->obj;
	    node->nullable = uni->left->nullable || uni->right->nullable;
	    node->firstpos = tre_set_union(mem, uni->left->firstpos,
					   uni->right->firstpos, NULL, 0, NULL);
	    if (!node->firstpos)
	      return REG_ESPACE;
	    node->lastpos = tre_set_union(mem, uni->left->lastpos,
					  uni->right->lastpos, NULL, 0, NULL);
	    if (!node->lastpos)
	      return REG_ESPACE;
	    break;
	  }

	case NFL_POST_ITERATION:
	  {
	    tre_iteration_t *iter = (tre_iteration_t *)node->obj;

	    if (iter->min == 0 || iter->arg->nullable)
	      node->nullable = 1;
	    else
	      node->nullable = 0;
	    node->firstpos = iter->arg->firstpos;
	    node->lastpos = iter->arg->lastpos;
	    break;
	  }

	case NFL_POST_CATENATION:
	  {
	    int num_tags, *tags, assertions, params_seen;
	    int *params;
	    reg_errcode_t status;
	    tre_catenation_t *cat = node->obj;
	    node->nullable = cat->left->nullable && cat->right->nullable;

	    /* Compute firstpos. */
	    if (cat->left->nullable)
	      {
		/* The left side matches the empty string.  Make a first pass
		   with tre_match_empty() to get the number of tags and
		   parameters. */
		status = tre_match_empty(stack, cat->left,
					 NULL, NULL, NULL, &num_tags,
					 &params_seen);
		if (status != REG_OK)
		  return status;
		/* Allocate arrays for the tags and parameters. */
		tags = xmalloc(sizeof(*tags) * (num_tags + 1));
		if (!tags)
		  return REG_ESPACE;
		tags[0] = -1;
		assertions = 0;
		params = NULL;
		if (params_seen)
		  {
		    params = tre_mem_alloc(mem, sizeof(*params)
					   * TRE_PARAM_LAST);
		    if (!params)
		      {
			xfree(tags);
			return REG_ESPACE;
		      }
		  }
		/* Second pass with tre_mach_empty() to get the list of
		   tags and parameters. */
		status = tre_match_empty(stack, cat->left, tags,
					 &assertions, params, NULL, NULL);
		if (status != REG_OK)
		  {
		    xfree(tags);
		    return status;
		  }
		node->firstpos =
		  tre_set_union(mem, cat->right->firstpos, cat->left->firstpos,
				tags, assertions, params);
		xfree(tags);
		if (!node->firstpos)
		  return REG_ESPACE;
	      }
	    else
	      {
		node->firstpos = cat->left->firstpos;
	      }

	    /* Compute lastpos. */
	    if (cat->right->nullable)
	      {
		/* The right side matches the empty string.  Make a first pass
		   with tre_match_empty() to get the number of tags and
		   parameters. */
		status = tre_match_empty(stack, cat->right,
					 NULL, NULL, NULL, &num_tags,
					 &params_seen);
		if (status != REG_OK)
		  return status;
		/* Allocate arrays for the tags and parameters. */
		tags = xmalloc(sizeof(int) * (num_tags + 1));
		if (!tags)
		  return REG_ESPACE;
		tags[0] = -1;
		assertions = 0;
		params = NULL;
		if (params_seen)
		  {
		    params = tre_mem_alloc(mem, sizeof(*params)
					   * TRE_PARAM_LAST);
		    if (!params)
		      {
			xfree(tags);
			return REG_ESPACE;
		      }
		  }
		/* Second pass with tre_mach_empty() to get the list of
		   tags and parameters. */
		status = tre_match_empty(stack, cat->right, tags,
					 &assertions, params, NULL, NULL);
		if (status != REG_OK)
		  {
		    xfree(tags);
		    return status;
		  }
		node->lastpos =
		  tre_set_union(mem, cat->left->lastpos, cat->right->lastpos,
				tags, assertions, params);
		xfree(tags);
		if (!node->lastpos)
		  return REG_ESPACE;
	      }
	    else
	      {
		node->lastpos = cat->right->lastpos;
	      }
	    break;
	  }

	default:
	  assert(0);
	  break;
	}
    }

  return REG_OK;
}


/* Adds a transition from each position in `p1' to each position in `p2'. */
static reg_errcode_t
tre_make_trans(tre_pos_and_tags_t *p1, tre_pos_and_tags_t *p2,
	       tre_tnfa_transition_t *transitions,
	       int *counts, int *offs)
{
  tre_pos_and_tags_t *orig_p2 = p2;
  tre_tnfa_transition_t *trans;
  int i, j, k, l, dup, prev_p2_pos;

  if (transitions != NULL)
    while (p1->position >= 0)
      {
	p2 = orig_p2;
	prev_p2_pos = -1;
	while (p2->position >= 0)
	  {
	    /* Optimization: if this position was already handled, skip it. */
	    if (p2->position == prev_p2_pos)
	      {
		p2++;
		continue;
	      }
	    prev_p2_pos = p2->position;
	    /* Set `trans' to point to the next unused transition from
	       position `p1->position'. */
	    trans = transitions + offs[p1->position];
	    while (trans->state != NULL)
	      {
#if 0
		/* If we find a previous transition from `p1->position' to
		   `p2->position', it is overwritten.  This can happen only
		   if there are nested loops in the regexp, like in "((a)*)*".
		   In POSIX.2 repetition using the outer loop is always
		   preferred over using the inner loop.	 Therefore the
		   transition for the inner loop is useless and can be thrown
		   away. */
		/* XXX - The same position is used for all nodes in a bracket
		   expression, so this optimization cannot be used (it will
		   break bracket expressions) unless I figure out a way to
		   detect it here. */
		if (trans->state_id == p2->position)
		  {
		    DPRINT(("*"));
		    break;
		  }
#endif
		trans++;
	      }

	    if (trans->state == NULL)
	      (trans + 1)->state = NULL;
	    /* Use the character ranges, assertions, etc. from `p1' for
	       the transition from `p1' to `p2'. */
	    trans->code_min = p1->code_min;
	    trans->code_max = p1->code_max;
	    trans->state = transitions + offs[p2->position];
	    trans->state_id = p2->position;
	    trans->assertions = p1->assertions | p2->assertions
	      | (p1->class ? ASSERT_CHAR_CLASS : 0)
	      | (p1->neg_classes != NULL ? ASSERT_CHAR_CLASS_NEG : 0);
	    if (p1->backref >= 0)
	      {
		assert((trans->assertions & ASSERT_CHAR_CLASS) == 0);
		assert(p2->backref < 0);
		trans->u.backref = p1->backref;
		trans->assertions |= ASSERT_BACKREF;
	      }
	    else
	      trans->u.class = p1->class;
	    if (p1->neg_classes != NULL)
	      {
		for (i = 0; p1->neg_classes[i] != (tre_ctype_t)0; i++);
		trans->neg_classes =
		  xmalloc(sizeof(*trans->neg_classes) * (i + 1));
		if (trans->neg_classes == NULL)
		  return REG_ESPACE;
		for (i = 0; p1->neg_classes[i] != (tre_ctype_t)0; i++)
		  trans->neg_classes[i] = p1->neg_classes[i];
		trans->neg_classes[i] = (tre_ctype_t)0;
	      }
	    else
	      trans->neg_classes = NULL;

	    /* Find out how many tags this transition has. */
	    i = 0;
	    if (p1->tags != NULL)
	      while(p1->tags[i] >= 0)
		i++;
	    j = 0;
	    if (p2->tags != NULL)
	      while(p2->tags[j] >= 0)
		j++;

	    /* If we are overwriting a transition, free the old tag array. */
	    if (trans->tags != NULL)
	      xfree(trans->tags);
	    trans->tags = NULL;

	    /* If there were any tags, allocate an array and fill it. */
	    if (i + j > 0)
	      {
		trans->tags = xmalloc(sizeof(*trans->tags) * (i + j + 1));
		if (!trans->tags)
		  return REG_ESPACE;
		i = 0;
		if (p1->tags != NULL)
		  while(p1->tags[i] >= 0)
		    {
		      trans->tags[i] = p1->tags[i];
		      i++;
		    }
		l = i;
		j = 0;
		if (p2->tags != NULL)
		  while (p2->tags[j] >= 0)
		    {
		      /* Don't add duplicates. */
		      dup = 0;
		      for (k = 0; k < i; k++)
			if (trans->tags[k] == p2->tags[j])
			  {
			    dup = 1;
			    break;
			  }
		      if (!dup)
			trans->tags[l++] = p2->tags[j];
		      j++;
		    }
		trans->tags[l] = -1;
	      }

	    /* Set the parameter array.	 If both `p2' and `p1' have same
	       parameters, the values in `p2' override those in `p1'. */
	    if (p1->params || p2->params)
	      {
		if (!trans->params)
		  trans->params = xmalloc(sizeof(*trans->params)
					  * TRE_PARAM_LAST);
		if (!trans->params)
		  return REG_ESPACE;
		for (i = 0; i < TRE_PARAM_LAST; i++)
		  {
		    trans->params[i] = TRE_PARAM_UNSET;
		    if (p1->params && p1->params[i] != TRE_PARAM_UNSET)
		      trans->params[i] = p1->params[i];
		    if (p2->params && p2->params[i] != TRE_PARAM_UNSET)
		      trans->params[i] = p2->params[i];
		  }
	      }
	    else
	      {
		if (trans->params)
		  xfree(trans->params);
		trans->params = NULL;
	      }


#ifdef TRE_DEBUG
	    {
	      int *tags;

	      DPRINT(("	 %2d -> %2d on %3d", p1->position, p2->position,
		      p1->code_min));
	      if (p1->code_max != p1->code_min)
		DPRINT(("-%3d", p1->code_max));
	      tags = trans->tags;
	      if (tags)
		{
		  DPRINT((", tags ["));
		  while (*tags >= 0)
		    {
		      DPRINT(("%d", *tags));
		      tags++;
		      if (*tags >= 0)
			DPRINT((","));
		    }
		  DPRINT(("]"));
		}
	      if (trans->assertions)
		DPRINT((", assert %d", trans->assertions));
	      if (trans->assertions & ASSERT_BACKREF)
		DPRINT((", backref %d", trans->u.backref));
	      else if (trans->u.class)
		DPRINT((", class %ld", (long)trans->u.class));
	      if (trans->neg_classes)
		DPRINT((", neg_classes %p", trans->neg_classes));
	      if (trans->params)
		{
		  DPRINT((", "));
		  tre_print_params(trans->params);
		}
	      DPRINT(("\n"));
	    }
#endif /* TRE_DEBUG */
	    p2++;
	  }
	p1++;
      }
  else
    /* Compute a maximum limit for the number of transitions leaving
       from each state. */
    while (p1->position >= 0)
      {
	p2 = orig_p2;
	while (p2->position >= 0)
	  {
	    counts[p1->position]++;
	    p2++;
	  }
	p1++;
      }
  return REG_OK;
}

/* Converts the syntax tree to a TNFA.	All the transitions in the TNFA are
   labelled with one character range (there are no transitions on empty
   strings).  The TNFA takes O(n^2) space in the worst case, `n' is size of
   the regexp. */
static reg_errcode_t
tre_ast_to_tnfa(tre_ast_node_t *node, tre_tnfa_transition_t *transitions,
		int *counts, int *offs)
{
  tre_union_t *uni;
  tre_catenation_t *cat;
  tre_iteration_t *iter;
  reg_errcode_t errcode = REG_OK;

  /* XXX - recurse using a stack!. */
  switch (node->type)
    {
    case LITERAL:
      break;
    case UNION:
      uni = (tre_union_t *)node->obj;
      errcode = tre_ast_to_tnfa(uni->left, transitions, counts, offs);
      if (errcode != REG_OK)
	return errcode;
      errcode = tre_ast_to_tnfa(uni->right, transitions, counts, offs);
      break;

    case CATENATION:
      cat = (tre_catenation_t *)node->obj;
      /* Add a transition from each position in cat->left->lastpos
	 to each position in cat->right->firstpos. */
      errcode = tre_make_trans(cat->left->lastpos, cat->right->firstpos,
			       transitions, counts, offs);
      if (errcode != REG_OK)
	return errcode;
      errcode = tre_ast_to_tnfa(cat->left, transitions, counts, offs);
      if (errcode != REG_OK)
	return errcode;
      errcode = tre_ast_to_tnfa(cat->right, transitions, counts, offs);
      break;

    case ITERATION:
      iter = (tre_iteration_t *)node->obj;
      assert(iter->max == -1 || iter->max == 1);

      if (iter->max == -1)
	{
	  assert(iter->min == 0 || iter->min == 1);
	  /* Add a transition from each last position in the iterated
	     expression to each first position. */
	  errcode = tre_make_trans(iter->arg->lastpos, iter->arg->firstpos,
				   transitions, counts, offs);
	  if (errcode != REG_OK)
	    return errcode;
	}
      errcode = tre_ast_to_tnfa(iter->arg, transitions, counts, offs);
      break;
    }
  return errcode;
}


#define ERROR_EXIT(err)		  \
  do				  \
    {				  \
      errcode = err;		  \
      if (/*CONSTCOND*/1)	  \
      	goto error_exit;	  \
    }				  \
 while (/*CONSTCOND*/0)


int
tre_compile(regex_t *preg, const tre_char_t *regex, size_t n, int cflags)
{
  tre_stack_t *stack;
  tre_ast_node_t *tree, *tmp_ast_l, *tmp_ast_r;
  tre_pos_and_tags_t *p;
  int *counts = NULL, *offs = NULL;
  int i, add = 0;
  tre_tnfa_transition_t *transitions, *initial;
  tre_tnfa_t *tnfa = NULL;
  tre_submatch_data_t *submatch_data;
  tre_tag_direction_t *tag_directions = NULL;
  reg_errcode_t errcode;
  tre_mem_t mem;

  /* Parse context. */
  tre_parse_ctx_t parse_ctx;

  /* Allocate a stack used throughout the compilation process for various
     purposes. */
  stack = tre_stack_new(512, 10240, 128);
  if (!stack)
    return REG_ESPACE;
  /* Allocate a fast memory allocator. */
  mem = tre_mem_new();
  if (!mem)
    {
      tre_stack_destroy(stack);
      return REG_ESPACE;
    }

  /* Parse the regexp. */
  memset(&parse_ctx, 0, sizeof(parse_ctx));
  parse_ctx.mem = mem;
  parse_ctx.stack = stack;
  parse_ctx.re = regex;
  parse_ctx.len = n;
  parse_ctx.cflags = cflags;
  parse_ctx.max_backref = -1;
  DPRINT(("tre_compile: parsing '%.*" STRF "'\n", (int)n, regex));
  errcode = tre_parse(&parse_ctx);
  if (errcode != REG_OK)
    ERROR_EXIT(errcode);
  preg->re_nsub = parse_ctx.submatch_id - 1;
  tree = parse_ctx.result;

  /* Back references and approximate matching cannot currently be used
     in the same regexp. */
  if (parse_ctx.max_backref >= 0 && parse_ctx.have_approx)
    ERROR_EXIT(REG_BADPAT);

#ifdef TRE_DEBUG
  tre_ast_print(tree);
#endif /* TRE_DEBUG */

  /* Referring to nonexistent subexpressions is illegal. */
  if (parse_ctx.max_backref > (int)preg->re_nsub)
    ERROR_EXIT(REG_ESUBREG);

  /* Allocate the TNFA struct. */
  tnfa = xcalloc(1, sizeof(tre_tnfa_t));
  if (tnfa == NULL)
    ERROR_EXIT(REG_ESPACE);
  tnfa->have_backrefs = parse_ctx.max_backref >= 0;
  tnfa->have_approx = parse_ctx.have_approx;
  tnfa->num_submatches = parse_ctx.submatch_id;

  /* Set up tags for submatch addressing.  If REG_NOSUB is set and the
     regexp does not have back references, this can be skipped. */
  if (tnfa->have_backrefs || !(cflags & REG_NOSUB))
    {
      DPRINT(("tre_compile: setting up tags\n"));

      /* Figure out how many tags we will need. */
      errcode = tre_add_tags(NULL, stack, tree, tnfa);
      if (errcode != REG_OK)
	ERROR_EXIT(errcode);
#ifdef TRE_DEBUG
      tre_ast_print(tree);
#endif /* TRE_DEBUG */

      if (tnfa->num_tags > 0)
	{
	  tag_directions = xmalloc(sizeof(*tag_directions)
				   * (tnfa->num_tags + 1));
	  if (tag_directions == NULL)
	    ERROR_EXIT(REG_ESPACE);
	  tnfa->tag_directions = tag_directions;
	  memset(tag_directions, -1,
		 sizeof(*tag_directions) * (tnfa->num_tags + 1));
	}
      tnfa->minimal_tags = xcalloc((unsigned)tnfa->num_tags * 2 + 1,
				   sizeof(tnfa->minimal_tags));
      if (tnfa->minimal_tags == NULL)
	ERROR_EXIT(REG_ESPACE);

      submatch_data = xcalloc((unsigned)parse_ctx.submatch_id,
			      sizeof(*submatch_data));
      if (submatch_data == NULL)
	ERROR_EXIT(REG_ESPACE);
      tnfa->submatch_data = submatch_data;

      errcode = tre_add_tags(mem, stack, tree, tnfa);
      if (errcode != REG_OK)
	ERROR_EXIT(errcode);

#ifdef TRE_DEBUG
      for (i = 0; i < parse_ctx.submatch_id; i++)
	DPRINT(("pmatch[%d] = {t%d, t%d}\n",
		i, submatch_data[i].so_tag, submatch_data[i].eo_tag));
      for (i = 0; i < tnfa->num_tags; i++)
	DPRINT(("t%d is %s\n", i,
		tag_directions[i] == TRE_TAG_MINIMIZE ?
		"minimized" : "maximized"));
#endif /* TRE_DEBUG */
    }

  /* Expand iteration nodes. */
  errcode = tre_expand_ast(mem, stack, tree, &parse_ctx.position,
			   tag_directions, &tnfa->params_depth);
  if (errcode != REG_OK)
    ERROR_EXIT(errcode);

  /* Add a dummy node for the final state.
     XXX - For certain patterns this dummy node can be optimized away,
	   for example "a*" or "ab*".	Figure out a simple way to detect
	   this possibility. */
  tmp_ast_l = tree;
  tmp_ast_r = tre_ast_new_literal(mem, 0, 0, parse_ctx.position++);
  if (tmp_ast_r == NULL)
    ERROR_EXIT(REG_ESPACE);

  tree = tre_ast_new_catenation(mem, tmp_ast_l, tmp_ast_r);
  if (tree == NULL)
    ERROR_EXIT(REG_ESPACE);

#ifdef TRE_DEBUG
  tre_ast_print(tree);
  DPRINT(("Number of states: %d\n", parse_ctx.position));
#endif /* TRE_DEBUG */

  errcode = tre_compute_nfl(mem, stack, tree);
  if (errcode != REG_OK)
    ERROR_EXIT(errcode);

  counts = xmalloc(sizeof(int) * parse_ctx.position);
  if (counts == NULL)
    ERROR_EXIT(REG_ESPACE);

  offs = xmalloc(sizeof(int) * parse_ctx.position);
  if (offs == NULL)
    ERROR_EXIT(REG_ESPACE);

  for (i = 0; i < parse_ctx.position; i++)
    counts[i] = 0;
  tre_ast_to_tnfa(tree, NULL, counts, NULL);

  add = 0;
  for (i = 0; i < parse_ctx.position; i++)
    {
      offs[i] = add;
      add += counts[i] + 1;
      counts[i] = 0;
    }
  transitions = xcalloc((unsigned)add + 1, sizeof(*transitions));
  if (transitions == NULL)
    ERROR_EXIT(REG_ESPACE);
  tnfa->transitions = transitions;
  tnfa->num_transitions = add;

  DPRINT(("Converting to TNFA:\n"));
  errcode = tre_ast_to_tnfa(tree, transitions, counts, offs);
  if (errcode != REG_OK)
    ERROR_EXIT(errcode);

  /* If in eight bit mode, compute a table of characters that can be the
     first character of a match. */
  tnfa->first_char = -1;
  if (TRE_MB_CUR_MAX == 1 && !tmp_ast_l->nullable)
    {
      int count = 0;
      tre_cint_t k;
      DPRINT(("Characters that can start a match:"));
      tnfa->firstpos_chars = xcalloc(256, sizeof(char));
      if (tnfa->firstpos_chars == NULL)
	ERROR_EXIT(REG_ESPACE);
      for (p = tree->firstpos; p->position >= 0; p++)
	{
	  tre_tnfa_transition_t *j = transitions + offs[p->position];
	  while (j->state != NULL)
	    {
	      for (k = j->code_min; k <= j->code_max && k < 256; k++)
		{
		  DPRINT((" %d", k));
		  tnfa->firstpos_chars[k] = 1;
		  count++;
		}
	      j++;
	    }
	}
      DPRINT(("\n"));
#define TRE_OPTIMIZE_FIRST_CHAR 1
#if TRE_OPTIMIZE_FIRST_CHAR
      if (count == 1)
	{
	  for (k = 0; k < 256; k++)
	    if (tnfa->firstpos_chars[k])
	      {
		DPRINT(("first char must be %d\n", k));
		tnfa->first_char = k;
		xfree(tnfa->firstpos_chars);
		tnfa->firstpos_chars = NULL;
		break;
	      }
	}
#endif

    }
  else
    tnfa->firstpos_chars = NULL;


  p = tree->firstpos;
  i = 0;
  while (p->position >= 0)
    {
      i++;

#ifdef TRE_DEBUG
      {
	int *tags;
	DPRINT(("initial: %d", p->position));
	tags = p->tags;
	if (tags != NULL)
	  {
	    if (*tags >= 0)
	      DPRINT(("/"));
	    while (*tags >= 0)
	      {
		DPRINT(("%d", *tags));
		tags++;
		if (*tags >= 0)
		  DPRINT((","));
	      }
	  }
	DPRINT((", assert %d", p->assertions));
	if (p->params)
	  {
	    DPRINT((", "));
	    tre_print_params(p->params);
	  }
	DPRINT(("\n"));
      }
#endif /* TRE_DEBUG */

      p++;
    }

  initial = xcalloc((unsigned)i + 1, sizeof(tre_tnfa_transition_t));
  if (initial == NULL)
    ERROR_EXIT(REG_ESPACE);
  tnfa->initial = initial;

  i = 0;
  for (p = tree->firstpos; p->position >= 0; p++)
    {
      initial[i].state = transitions + offs[p->position];
      initial[i].state_id = p->position;
      initial[i].tags = NULL;
      /* Copy the arrays p->tags, and p->params, they are allocated
	 from a tre_mem object. */
      if (p->tags)
	{
	  int j;
	  for (j = 0; p->tags[j] >= 0; j++);
	  initial[i].tags = xmalloc(sizeof(*p->tags) * (j + 1));
	  if (!initial[i].tags)
	    ERROR_EXIT(REG_ESPACE);
	  memcpy(initial[i].tags, p->tags, sizeof(*p->tags) * (j + 1));
	}
      initial[i].params = NULL;
      if (p->params)
	{
	  initial[i].params = xmalloc(sizeof(*p->params) * TRE_PARAM_LAST);
	  if (!initial[i].params)
	    ERROR_EXIT(REG_ESPACE);
	  memcpy(initial[i].params, p->params,
		 sizeof(*p->params) * TRE_PARAM_LAST);
	}
      initial[i].assertions = p->assertions;
      i++;
    }
  initial[i].state = NULL;

  tnfa->num_transitions = add;
  tnfa->final = transitions + offs[tree->lastpos[0].position];
  tnfa->num_states = parse_ctx.position;
  tnfa->cflags = cflags;

  DPRINT(("final state %p\n", (void *)tnfa->final));

  tre_mem_destroy(mem);
  tre_stack_destroy(stack);
  xfree(counts);
  xfree(offs);

  preg->TRE_REGEX_T_FIELD = (void *)tnfa;
  return REG_OK;

 error_exit:
  /* Free everything that was allocated and return the error code. */
  tre_mem_destroy(mem);
  if (stack != NULL)
    tre_stack_destroy(stack);
  if (counts != NULL)
    xfree(counts);
  if (offs != NULL)
    xfree(offs);
  preg->TRE_REGEX_T_FIELD = (void *)tnfa;
  tre_free(preg);
  return errcode;
}




void
tre_free(regex_t *preg)
{
  tre_tnfa_t *tnfa;
  unsigned int i;
  tre_tnfa_transition_t *trans;

  tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  if (!tnfa)
    return;

  for (i = 0; i < tnfa->num_transitions; i++)
    if (tnfa->transitions[i].state)
      {
	if (tnfa->transitions[i].tags)
	  xfree(tnfa->transitions[i].tags);
	if (tnfa->transitions[i].neg_classes)
	  xfree(tnfa->transitions[i].neg_classes);
	if (tnfa->transitions[i].params)
	  xfree(tnfa->transitions[i].params);
      }
  if (tnfa->transitions)
    xfree(tnfa->transitions);

  if (tnfa->initial)
    {
      for (trans = tnfa->initial; trans->state; trans++)
	{
	  if (trans->tags)
	    xfree(trans->tags);
	  if (trans->params)
	    xfree(trans->params);
	}
      xfree(tnfa->initial);
    }

  if (tnfa->submatch_data)
    {
      for (i = 0; i < tnfa->num_submatches; i++)
	if (tnfa->submatch_data[i].parents)
	  xfree(tnfa->submatch_data[i].parents);
      xfree(tnfa->submatch_data);
    }

  if (tnfa->tag_directions)
    xfree(tnfa->tag_directions);
  if (tnfa->firstpos_chars)
    xfree(tnfa->firstpos_chars);
  if (tnfa->minimal_tags)
    xfree(tnfa->minimal_tags);
  xfree(tnfa);
}

char *
tre_version(void)
{
  static char str[256];
  char *version;

  if (str[0] == 0)
    {
      (void) tre_config(TRE_CONFIG_VERSION, &version);
      (void) snprintf(str, sizeof(str), "TRE %s (BSD)", version);
    }
  return str;
}

int
tre_config(int query, void *result)
{
  int *int_result = result;
  const char **string_result = result;

  switch (query)
    {
    case TRE_CONFIG_APPROX:
#ifdef TRE_APPROX
      *int_result = 1;
#else /* !TRE_APPROX */
      *int_result = 0;
#endif /* !TRE_APPROX */
      return REG_OK;

    case TRE_CONFIG_WCHAR:
#ifdef TRE_WCHAR
      *int_result = 1;
#else /* !TRE_WCHAR */
      *int_result = 0;
#endif /* !TRE_WCHAR */
      return REG_OK;

    case TRE_CONFIG_MULTIBYTE:
#ifdef TRE_MULTIBYTE
      *int_result = 1;
#else /* !TRE_MULTIBYTE */
      *int_result = 0;
#endif /* !TRE_MULTIBYTE */
      return REG_OK;

    case TRE_CONFIG_SYSTEM_ABI:
#ifdef TRE_CONFIG_SYSTEM_ABI
      *int_result = 1;
#else /* !TRE_CONFIG_SYSTEM_ABI */
      *int_result = 0;
#endif /* !TRE_CONFIG_SYSTEM_ABI */
      return REG_OK;

    case TRE_CONFIG_VERSION:
      *string_result = TRE_VERSION;
      return REG_OK;
    }

  return REG_NOMATCH;
}


/* EOF */
/*
  tre-match-approx.c - TRE approximate regex matching engine

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */

/* AIX requires this to be the first thing in the file.	 */
#ifdef TRE_USE_ALLOCA
#ifndef __GNUC__
# if HAVE_ALLOCA_H
#  include <alloca.h>
# else
#  ifdef _AIX
 #pragma alloca
#  else
#   ifndef alloca /* predefined by HP cc +Olibcalls */
char *alloca ();
#   endif
#  endif
# endif
#endif
#endif /* TRE_USE_ALLOCA */

#define __USE_STRING_INLINES
#undef __NO_INLINE__

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#ifdef HAVE_WCHAR_H
#include <wchar.h>
#endif /* HAVE_WCHAR_H */
#ifdef HAVE_WCTYPE_H
#include <wctype.h>
#endif /* HAVE_WCTYPE_H */
#ifndef TRE_WCHAR
#include <ctype.h>
#endif /* !TRE_WCHAR */
#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif /* HAVE_MALLOC_H */

/*
  tre-match-utils.h - TRE matcher helper definitions

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

#define str_source ((const tre_str_source*)string)

#ifdef TRE_WCHAR

#ifdef TRE_MULTIBYTE

/* Wide character and multibyte support. */

#define GET_NEXT_WCHAR()						      \
  do {									      \
    prev_c = next_c;							      \
    if (type == STR_BYTE)						      \
      {									      \
	pos++;								      \
	if (len >= 0 && pos >= len)					      \
	  next_c = '\0';						      \
	else								      \
	  next_c = (unsigned char)(*str_byte++);			      \
      }									      \
    else if (type == STR_WIDE)						      \
      {									      \
	pos++;								      \
	if (len >= 0 && pos >= len)					      \
	  next_c = L'\0';						      \
	else								      \
	  next_c = *str_wide++;						      \
      }									      \
    else if (type == STR_MBS)						      \
      {									      \
        pos += pos_add_next;					      	      \
	if (str_byte == NULL)						      \
	  next_c = L'\0';						      \
	else								      \
	  {								      \
	    size_t w;							      \
	    int max;							      \
	    if (len >= 0)						      \
	      max = len - pos;						      \
	    else							      \
	      max = 32;							      \
	    if (max <= 0)						      \
	      {								      \
		next_c = L'\0';						      \
		pos_add_next = 1;					      \
	      }								      \
	    else							      \
	      {								      \
		w = tre_mbrtowc(&next_c, str_byte, (size_t)max, &mbstate);    \
		if (w == (size_t)-1 || w == (size_t)-2)			      \
		  return REG_NOMATCH;					      \
		if (w == 0 && len >= 0)					      \
		  {							      \
		    pos_add_next = 1;					      \
		    next_c = 0;						      \
		    str_byte++;						      \
		  }							      \
		else							      \
		  {							      \
		    pos_add_next = w;					      \
		    str_byte += w;					      \
		  }							      \
	      }								      \
	  }								      \
      }									      \
    else if (type == STR_USER)						      \
      {									      \
        pos += pos_add_next;					      	      \
	str_user_end = str_source->get_next_char(&next_c, &pos_add_next,      \
                                                 str_source->context);	      \
      }									      \
  } while(/*CONSTCOND*/0)

#else /* !TRE_MULTIBYTE */

/* Wide character support, no multibyte support. */

#define GET_NEXT_WCHAR()						      \
  do {									      \
    prev_c = next_c;							      \
    if (type == STR_BYTE)						      \
      {									      \
	pos++;								      \
	if (len >= 0 && pos >= len)					      \
	  next_c = '\0';						      \
	else								      \
	  next_c = (unsigned char)(*str_byte++);			      \
      }									      \
    else if (type == STR_WIDE)						      \
      {									      \
	pos++;								      \
	if (len >= 0 && pos >= len)					      \
	  next_c = L'\0';						      \
	else								      \
	  next_c = *str_wide++;						      \
      }									      \
    else if (type == STR_USER)						      \
      {									      \
        pos += pos_add_next;					      	      \
	str_user_end = str_source->get_next_char(&next_c, &pos_add_next,      \
                                                 str_source->context);	      \
      }									      \
  } while(/*CONSTCOND*/0)

#endif /* !TRE_MULTIBYTE */

#else /* !TRE_WCHAR */

/* No wide character or multibyte support. */

#define GET_NEXT_WCHAR()						      \
  do {									      \
    prev_c = next_c;							      \
    if (type == STR_BYTE)						      \
      {									      \
	pos++;								      \
	if (len >= 0 && pos >= len)					      \
	  next_c = '\0';						      \
	else								      \
	  next_c = (unsigned char)(*str_byte++);			      \
      }									      \
    else if (type == STR_USER)						      \
      {									      \
	pos += pos_add_next;						      \
	str_user_end = str_source->get_next_char(&next_c, &pos_add_next,      \
						 str_source->context);	      \
      }									      \
  } while(/*CONSTCOND*/0)

#endif /* !TRE_WCHAR */



#define IS_WORD_CHAR(c)	 ((c) == L'_' || tre_isalnum(c))

#define CHECK_ASSERTIONS(assertions)					      \
  (((assertions & ASSERT_AT_BOL)					      \
    && (pos > 0 || reg_notbol)						      \
    && (prev_c != L'\n' || !reg_newline))				      \
   || ((assertions & ASSERT_AT_EOL)					      \
       && (next_c != L'\0' || reg_noteol)				      \
       && (next_c != L'\n' || !reg_newline))				      \
   || ((assertions & ASSERT_AT_BOW)					      \
       && (IS_WORD_CHAR(prev_c) || !IS_WORD_CHAR(next_c)))	              \
   || ((assertions & ASSERT_AT_EOW)					      \
       && (!IS_WORD_CHAR(prev_c) || IS_WORD_CHAR(next_c)))		      \
   || ((assertions & ASSERT_AT_WB)					      \
       && (pos != 0 && next_c != L'\0'					      \
	   && IS_WORD_CHAR(prev_c) == IS_WORD_CHAR(next_c)))		      \
   || ((assertions & ASSERT_AT_WB_NEG)					      \
       && (pos == 0 || next_c == L'\0'					      \
	   || IS_WORD_CHAR(prev_c) != IS_WORD_CHAR(next_c))))

#define CHECK_CHAR_CLASSES(trans_i, tnfa, eflags)                             \
  (((trans_i->assertions & ASSERT_CHAR_CLASS)                                 \
       && !(tnfa->cflags & REG_ICASE)                                         \
       && !tre_isctype((tre_cint_t)prev_c, trans_i->u.class))                 \
    || ((trans_i->assertions & ASSERT_CHAR_CLASS)                             \
        && (tnfa->cflags & REG_ICASE)                                         \
        && !tre_isctype(tre_tolower((tre_cint_t)prev_c),trans_i->u.class)     \
	&& !tre_isctype(tre_toupper((tre_cint_t)prev_c),trans_i->u.class))    \
    || ((trans_i->assertions & ASSERT_CHAR_CLASS_NEG)                         \
        && tre_neg_char_classes_match(trans_i->neg_classes,(tre_cint_t)prev_c,\
                                      tnfa->cflags & REG_ICASE)))




/* Returns 1 if `t1' wins `t2', 0 otherwise. */
inline static int
tre_tag_order(int num_tags, tre_tag_direction_t *tag_directions,
	      int *t1, int *t2)
{
  int i;
  for (i = 0; i < num_tags; i++)
    {
      if (tag_directions[i] == TRE_TAG_MINIMIZE)
	{
	  if (t1[i] < t2[i])
	    return 1;
	  if (t1[i] > t2[i])
	    return 0;
	}
      else
	{
	  if (t1[i] > t2[i])
	    return 1;
	  if (t1[i] < t2[i])
	    return 0;
	}
    }
  /*  assert(0);*/
  return 0;
}

inline static int
tre_neg_char_classes_match(tre_ctype_t *classes, tre_cint_t wc, int icase)
{
  DPRINT(("neg_char_classes_test: %p, %d, %d\n", classes, wc, icase));
  while (*classes != (tre_ctype_t)0)
    if ((!icase && tre_isctype(wc, *classes))
	|| (icase && (tre_isctype(tre_toupper(wc), *classes)
		      || tre_isctype(tre_tolower(wc), *classes))))
      return 1; /* Match. */
    else
      classes++;
  return 0; /* No match. */
}

#define TRE_M_COST	0
#define TRE_M_NUM_INS	1
#define TRE_M_NUM_DEL	2
#define TRE_M_NUM_SUBST 3
#define TRE_M_NUM_ERR	4
#define TRE_M_LAST	5

#define TRE_M_MAX_DEPTH 3

typedef struct {
  /* State in the TNFA transition table. */
  tre_tnfa_transition_t *state;
  /* Position in input string. */
  int pos;
  /* Tag values. */
  int *tags;
  /* Matching parameters. */
  regaparams_t params;
  /* Nesting depth of parameters.  This is used as an index in
     the `costs' array. */
  int depth;
  /* Costs and counter values for different parameter nesting depths. */
  int costs[TRE_M_MAX_DEPTH + 1][TRE_M_LAST];
} tre_tnfa_approx_reach_t;


#ifdef TRE_DEBUG
/* Prints the `reach' array in a readable fashion with DPRINT. */
static void
tre_print_reach(const tre_tnfa_t *tnfa, tre_tnfa_approx_reach_t *reach,
		int pos, int num_tags)
{
  int id;

  /* Print each state on one line. */
  DPRINT(("  reach:\n"));
  for (id = 0; id < tnfa->num_states; id++)
    {
      int i, j;
      if (reach[id].pos < pos)
	continue;  /* Not reached. */
      DPRINT(("	 %03d, costs ", id));
      for (i = 0; i <= reach[id].depth; i++)
	{
	  DPRINT(("["));
	  for (j = 0; j < TRE_M_LAST; j++)
	    {
	      DPRINT(("%2d", reach[id].costs[i][j]));
	      if (j + 1 < TRE_M_LAST)
		DPRINT((","));
	    }
	  DPRINT(("]"));
	  if (i + 1 <= reach[id].depth)
	    DPRINT((", "));
	}
      DPRINT(("\n	tags "));
      for (i = 0; i < num_tags; i++)
	{
	  DPRINT(("%02d", reach[id].tags[i]));
	  if (i + 1 < num_tags)
	    DPRINT((","));
	}
      DPRINT(("\n"));
    }
  DPRINT(("\n"));
}
#endif /* TRE_DEBUG */


/* Sets the matching parameters in `reach' to the ones defined in the `pa'
   array.  If `pa' specifies default values, they are taken from
   `default_params'. */
inline static void
tre_set_params(tre_tnfa_approx_reach_t *reach,
	       int *pa, regaparams_t default_params)
{
  int value;

  /* If depth is increased reset costs and counters to zero for the
     new levels. */
  value = pa[TRE_PARAM_DEPTH];
  assert(value <= TRE_M_MAX_DEPTH);
  if (value > reach->depth)
    {
      int i, j;
      for (i = reach->depth + 1; i <= value; i++)
	for (j = 0; j < TRE_M_LAST; j++)
	  reach->costs[i][j] = 0;
    }
  reach->depth = value;

  /* Set insert cost. */
  value = pa[TRE_PARAM_COST_INS];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.cost_ins = default_params.cost_ins;
  else if (value != TRE_PARAM_UNSET)
    reach->params.cost_ins = value;

  /* Set delete cost. */
  value = pa[TRE_PARAM_COST_DEL];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.cost_del = default_params.cost_del;
  else if (value != TRE_PARAM_UNSET)
    reach->params.cost_del = value;

  /* Set substitute cost. */
  value = pa[TRE_PARAM_COST_SUBST];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.cost_subst = default_params.cost_subst;
  else
    reach->params.cost_subst = value;

  /* Set maximum cost. */
  value = pa[TRE_PARAM_COST_MAX];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.max_cost = default_params.max_cost;
  else if (value != TRE_PARAM_UNSET)
    reach->params.max_cost = value;

  /* Set maximum inserts. */
  value = pa[TRE_PARAM_MAX_INS];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.max_ins = default_params.max_ins;
  else if (value != TRE_PARAM_UNSET)
    reach->params.max_ins = value;

  /* Set maximum deletes. */
  value = pa[TRE_PARAM_MAX_DEL];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.max_del = default_params.max_del;
  else if (value != TRE_PARAM_UNSET)
    reach->params.max_del = value;

  /* Set maximum substitutes. */
  value = pa[TRE_PARAM_MAX_SUBST];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.max_subst = default_params.max_subst;
  else if (value != TRE_PARAM_UNSET)
    reach->params.max_subst = value;

  /* Set maximum number of errors. */
  value = pa[TRE_PARAM_MAX_ERR];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.max_err = default_params.max_err;
  else if (value != TRE_PARAM_UNSET)
    reach->params.max_err = value;
}

reg_errcode_t
tre_tnfa_run_approx(const tre_tnfa_t *tnfa, const void *string, int len,
		    tre_str_type_t type, int *match_tags,
		    regamatch_t *match, regaparams_t default_params,
		    int eflags, int *match_end_ofs)
{
  /* State variables required by GET_NEXT_WCHAR. */
  tre_char_t prev_c = 0, next_c = 0;
  const char *str_byte = string;
  int pos = -1;
  unsigned int pos_add_next = 1;
#ifdef TRE_WCHAR
  const wchar_t *str_wide = string;
#ifdef TRE_MBSTATE
  mbstate_t mbstate;
#endif /* !TRE_WCHAR */
#endif /* TRE_WCHAR */
  int reg_notbol = eflags & REG_NOTBOL;
  int reg_noteol = eflags & REG_NOTEOL;
  int reg_newline = tnfa->cflags & REG_NEWLINE;
  int str_user_end = 0;

  int prev_pos;

  /* Number of tags. */
  int num_tags;
  /* The reach tables. */
  tre_tnfa_approx_reach_t *reach, *reach_next;
  /* Tag array for temporary use. */
  int *tmp_tags;

  /* End offset of best match so far, or -1 if no match found yet. */
  int match_eo = -1;
  /* Costs of the match. */
  int match_costs[TRE_M_LAST];

  /* Space for temporary data required for matching. */
  unsigned char *buf;

  int i, id;

  if (!match_tags)
    num_tags = 0;
  else
    num_tags = tnfa->num_tags;

#ifdef TRE_MBSTATE
  memset(&mbstate, '\0', sizeof(mbstate));
#endif /* TRE_MBSTATE */

  DPRINT(("tre_tnfa_run_approx, input type %d, len %d, eflags %d, "
	  "match_tags %p\n",
	  type, len, eflags,
	  match_tags));
  DPRINT(("max cost %d, ins %d, del %d, subst %d\n",
	  default_params.max_cost,
	  default_params.cost_ins,
	  default_params.cost_del,
	  default_params.cost_subst));

  /* Allocate memory for temporary data required for matching.	This needs to
     be done for every matching operation to be thread safe.  This allocates
     everything in a single large block from the stack frame using alloca()
     or with malloc() if alloca is unavailable. */
  {
    unsigned char *buf_cursor;
    /* Space needed for one array of tags. */
    int tag_bytes = sizeof(*tmp_tags) * num_tags;
    /* Space needed for one reach table. */
    int reach_bytes = sizeof(*reach_next) * tnfa->num_states;
    /* Total space needed. */
    int total_bytes = reach_bytes * 2 + (tnfa->num_states * 2 + 1 ) * tag_bytes;
    /* Add some extra to make sure we can align the pointers.  The multiplier
       used here must be equal to the number of ALIGN calls below. */
    total_bytes += (sizeof(long) - 1) * 3;

    /* Allocate the memory. */
#ifdef TRE_USE_ALLOCA
    buf = alloca(total_bytes);
#else /* !TRE_USE_ALLOCA */
    buf = xmalloc((unsigned)total_bytes);
#endif /* !TRE_USE_ALLOCA */
    if (!buf)
      return REG_ESPACE;
    memset(buf, 0, (size_t)total_bytes);

    /* Allocate `tmp_tags' from `buf'. */
    tmp_tags = (void *)buf;
    buf_cursor = buf + tag_bytes;
    buf_cursor += ALIGN(buf_cursor, long);

    /* Allocate `reach' from `buf'. */
    reach = (void *)buf_cursor;
    buf_cursor += reach_bytes;
    buf_cursor += ALIGN(buf_cursor, long);

    /* Allocate `reach_next' from `buf'. */
    reach_next = (void *)buf_cursor;
    buf_cursor += reach_bytes;
    buf_cursor += ALIGN(buf_cursor, long);

    /* Allocate tag arrays for `reach' and `reach_next' from `buf'. */
    for (i = 0; i < tnfa->num_states; i++)
      {
	reach[i].tags = (void *)buf_cursor;
	buf_cursor += tag_bytes;
	reach_next[i].tags = (void *)buf_cursor;
	buf_cursor += tag_bytes;
      }
    assert(buf_cursor <= buf + total_bytes);
  }

  for (i = 0; i < TRE_M_LAST; i++)
    match_costs[i] = INT_MAX;

  /* Mark the reach arrays empty. */
  for (i = 0; i < tnfa->num_states; i++)
    reach[i].pos = reach_next[i].pos = -2;

  prev_pos = pos;
  GET_NEXT_WCHAR();
  pos = 0;

  while (/*CONSTCOND*/1)
    {
      DPRINT(("%03d:%2lc/%05d\n", pos, (tre_cint_t)next_c, (int)next_c));

      /* Add initial states to `reach_next' if an exact match has not yet
	 been found. */
      if (match_costs[TRE_M_COST] > 0)
	{
	  tre_tnfa_transition_t *trans;
	  DPRINT(("  init"));
	  for (trans = tnfa->initial; trans->state; trans++)
	    {
	      int stateid = trans->state_id;

	      /* If this state is not currently in `reach_next', add it
		 there. */
	      if (reach_next[stateid].pos < pos)
		{
		  if (trans->assertions && CHECK_ASSERTIONS(trans->assertions))
		    {
		      /* Assertions failed, don't add this state. */
		      DPRINT((" !%d (assert)", stateid));
		      continue;
		    }
		  DPRINT((" %d", stateid));
		  reach_next[stateid].state = trans->state;
		  reach_next[stateid].pos = pos;

		  /* Compute tag values after this transition. */
		  for (i = 0; i < num_tags; i++)
		    reach_next[stateid].tags[i] = -1;

		  if (trans->tags)
		    for (i = 0; trans->tags[i] >= 0; i++)
		      if (trans->tags[i] < num_tags)
			reach_next[stateid].tags[trans->tags[i]] = pos;

		  /* Set the parameters, depth, and costs. */
		  reach_next[stateid].params = default_params;
		  reach_next[stateid].depth = 0;
		  for (i = 0; i < TRE_M_LAST; i++)
		    reach_next[stateid].costs[0][i] = 0;
		  if (trans->params)
		    tre_set_params(&reach_next[stateid], trans->params,
				   default_params);

		  /* If this is the final state, mark the exact match. */
		  if (trans->state == tnfa->final)
		    {
		      match_eo = pos;
		      for (i = 0; i < num_tags; i++)
			match_tags[i] = reach_next[stateid].tags[i];
		      for (i = 0; i < TRE_M_LAST; i++)
			match_costs[i] = 0;
		    }
		}
	    }
	    DPRINT(("\n"));
	}


      /* Handle inserts.  This is done by pretending there's an epsilon
	 transition from each state in `reach' back to the same state.
	 We don't need to worry about the final state here; this will never
	 give a better match than what we already have. */
      for (id = 0; id < tnfa->num_states; id++)
	{
	  int depth;
	  int cost, cost0;

	  if (reach[id].pos != prev_pos)
	    {
	      DPRINT(("	 insert: %d not reached\n", id));
	      continue;	 /* Not reached. */
	    }

	  depth = reach[id].depth;

	  /* Compute and check cost at current depth. */
	  cost = reach[id].costs[depth][TRE_M_COST];
	  if (reach[id].params.cost_ins != TRE_PARAM_UNSET)
	    cost += reach[id].params.cost_ins;
	  if (cost > reach[id].params.max_cost)
	    continue;  /* Cost too large. */

	  /* Check number of inserts at current depth. */
	  if (reach[id].costs[depth][TRE_M_NUM_INS] + 1
	      > reach[id].params.max_ins)
	    continue;  /* Too many inserts. */

	  /* Check total number of errors at current depth. */
	  if (reach[id].costs[depth][TRE_M_NUM_ERR] + 1
	      > reach[id].params.max_err)
	    continue;  /* Too many errors. */

	  /* Compute overall cost. */
	  cost0 = cost;
	  if (depth > 0)
	    {
	      cost0 = reach[id].costs[0][TRE_M_COST];
	      if (reach[id].params.cost_ins != TRE_PARAM_UNSET)
		cost0 += reach[id].params.cost_ins;
	      else
		cost0 += default_params.cost_ins;
	    }

	  DPRINT(("  insert: from %d to %d, cost %d: ", id, id,
		  reach[id].costs[depth][TRE_M_COST]));
	  if (reach_next[id].pos == pos
	      && (cost0 >= reach_next[id].costs[0][TRE_M_COST]))
	    {
	      DPRINT(("lose\n"));
	      continue;
	    }
	  DPRINT(("win\n"));

	  /* Copy state, position, tags, parameters, and depth. */
	  reach_next[id].state = reach[id].state;
	  reach_next[id].pos = pos;
	  for (i = 0; i < num_tags; i++)
	    reach_next[id].tags[i] = reach[id].tags[i];
	  reach_next[id].params = reach[id].params;
	  reach_next[id].depth = reach[id].depth;

	  /* Set the costs after this transition. */
	  memcpy(reach_next[id].costs, reach[id].costs,
		 sizeof(reach_next[id].costs[0][0])
		 * TRE_M_LAST * (depth + 1));
	  reach_next[id].costs[depth][TRE_M_COST] = cost;
	  reach_next[id].costs[depth][TRE_M_NUM_INS]++;
	  reach_next[id].costs[depth][TRE_M_NUM_ERR]++;
	  if (depth > 0)
	    {
	      reach_next[id].costs[0][TRE_M_COST] = cost0;
	      reach_next[id].costs[0][TRE_M_NUM_INS]++;
	      reach_next[id].costs[0][TRE_M_NUM_ERR]++;
	    }

	}


      /* Handle deletes.  This is done by traversing through the whole TNFA
	 pretending that all transitions are epsilon transitions, until
	 no more states can be reached with better costs. */
      {
	/* XXX - dynamic ringbuffer size */
	tre_tnfa_approx_reach_t *ringbuffer[512];
	tre_tnfa_approx_reach_t **deque_start, **deque_end;

	deque_start = deque_end = ringbuffer;

	/* Add all states in `reach_next' to the deque. */
	for (id = 0; id < tnfa->num_states; id++)
	  {
	    if (reach_next[id].pos != pos)
	      continue;
	    *deque_end = &reach_next[id];
	    deque_end++;
	    assert(deque_end != deque_start);
	  }

	/* Repeat until the deque is empty. */
	while (deque_end != deque_start)
	  {
	    tre_tnfa_approx_reach_t *reach_p;
	    int depth;
	    int cost, cost0;
	    tre_tnfa_transition_t *trans;

	    /* Pop the first item off the deque. */
	    reach_p = *deque_start;
	    id = reach_p - reach_next;
	    depth = reach_p->depth;

	    /* Compute cost at current depth. */
	    cost = reach_p->costs[depth][TRE_M_COST];
	    if (reach_p->params.cost_del != TRE_PARAM_UNSET)
	      cost += reach_p->params.cost_del;

	    /* Check cost, number of deletes, and total number of errors
	       at current depth. */
	    if (cost > reach_p->params.max_cost
		|| (reach_p->costs[depth][TRE_M_NUM_DEL] + 1
		    > reach_p->params.max_del)
		|| (reach_p->costs[depth][TRE_M_NUM_ERR] + 1
		    > reach_p->params.max_err))
	      {
		/* Too many errors or cost too large. */
		DPRINT(("  delete: from %03d: cost too large\n", id));
		deque_start++;
		if (deque_start >= (ringbuffer + 512))
		  deque_start = ringbuffer;
		continue;
	      }

	    /* Compute overall cost. */
	    cost0 = cost;
	    if (depth > 0)
	      {
		cost0 = reach_p->costs[0][TRE_M_COST];
		if (reach_p->params.cost_del != TRE_PARAM_UNSET)
		  cost0 += reach_p->params.cost_del;
		else
		  cost0 += default_params.cost_del;
	      }

	    for (trans = reach_p->state; trans->state; trans++)
	      {
		int dest_id = trans->state_id;
		DPRINT(("  delete: from %03d to %03d, cost %d (%d): ",
			id, dest_id, cost0, reach_p->params.max_cost));

		if (trans->assertions && CHECK_ASSERTIONS(trans->assertions))
		  {
		    DPRINT(("assertion failed\n"));
		    continue;
		  }

		/* Compute tag values after this transition. */
		for (i = 0; i < num_tags; i++)
		  tmp_tags[i] = reach_p->tags[i];
		if (trans->tags)
		  for (i = 0; trans->tags[i] >= 0; i++)
		    if (trans->tags[i] < num_tags)
		      tmp_tags[trans->tags[i]] = pos;

		/* If another path has also reached this state, choose the one
		   with the smallest cost or best tags if costs are equal. */
		if (reach_next[dest_id].pos == pos
		    && (cost0 > reach_next[dest_id].costs[0][TRE_M_COST]
			|| (cost0 == reach_next[dest_id].costs[0][TRE_M_COST]
			    && (!match_tags
				|| !tre_tag_order(num_tags,
						  tnfa->tag_directions,
						  tmp_tags,
						  reach_next[dest_id].tags)))))
		  {
		    DPRINT(("lose, cost0 %d, have %d\n",
			    cost0, reach_next[dest_id].costs[0][TRE_M_COST]));
		    continue;
		  }
		DPRINT(("win\n"));

		/* Set state, position, tags, parameters, depth, and costs. */
		reach_next[dest_id].state = trans->state;
		reach_next[dest_id].pos = pos;
		for (i = 0; i < num_tags; i++)
		  reach_next[dest_id].tags[i] = tmp_tags[i];

		reach_next[dest_id].params = reach_p->params;
		if (trans->params)
		  tre_set_params(&reach_next[dest_id], trans->params,
				 default_params);

		reach_next[dest_id].depth = reach_p->depth;
		memcpy(&reach_next[dest_id].costs,
		       reach_p->costs,
		       sizeof(reach_p->costs[0][0])
		       * TRE_M_LAST * (depth + 1));
		reach_next[dest_id].costs[depth][TRE_M_COST] = cost;
		reach_next[dest_id].costs[depth][TRE_M_NUM_DEL]++;
		reach_next[dest_id].costs[depth][TRE_M_NUM_ERR]++;
		if (depth > 0)
		  {
		    reach_next[dest_id].costs[0][TRE_M_COST] = cost0;
		    reach_next[dest_id].costs[0][TRE_M_NUM_DEL]++;
		    reach_next[dest_id].costs[0][TRE_M_NUM_ERR]++;
		  }

		if (trans->state == tnfa->final
		    && (match_eo < 0
			|| match_costs[TRE_M_COST] > cost0
			|| (match_costs[TRE_M_COST] == cost0
			    && (num_tags > 0
				&& tmp_tags[0] <= match_tags[0]))))
		  {
		    DPRINT(("	 setting new match at %d, cost %d\n",
			    pos, cost0));
		    match_eo = pos;
		    memcpy(match_costs, reach_next[dest_id].costs[0],
			   sizeof(match_costs[0]) * TRE_M_LAST);
		    for (i = 0; i < num_tags; i++)
		      match_tags[i] = tmp_tags[i];
		  }

		/* Add to the end of the deque. */
		*deque_end = &reach_next[dest_id];
		deque_end++;
		if (deque_end >= (ringbuffer + 512))
		  deque_end = ringbuffer;
		assert(deque_end != deque_start);
	      }
	    deque_start++;
	    if (deque_start >= (ringbuffer + 512))
	      deque_start = ringbuffer;
	  }

      }

#ifdef TRE_DEBUG
      tre_print_reach(tnfa, reach_next, pos, num_tags);
#endif /* TRE_DEBUG */

      /* Check for end of string. */
      if (len < 0)
	{
	  if (type == STR_USER)
	    {
	      if (str_user_end)
		break;
	    }
	  else if (next_c == L'\0')
	    break;
	}
      else
	{
	  if (pos >= len)
	    break;
	}

      prev_pos = pos;
      GET_NEXT_WCHAR();

      /* Swap `reach' and `reach_next'. */
      {
	tre_tnfa_approx_reach_t *tmp;
	tmp = reach;
	reach = reach_next;
	reach_next = tmp;
      }

      /* Handle exact matches and substitutions. */
      for (id = 0; id < tnfa->num_states; id++)
	{
	  tre_tnfa_transition_t *trans;

	  if (reach[id].pos < prev_pos)
	    continue;  /* Not reached. */
	  for (trans = reach[id].state; trans->state; trans++)
	    {
	      int dest_id;
	      int depth;
	      int cost, cost0, err;

	      if (trans->assertions
		  && (CHECK_ASSERTIONS(trans->assertions)
		      || CHECK_CHAR_CLASSES(trans, tnfa, eflags)))
		{
		  DPRINT(("  exact,  from %d: assert failed\n", id));
		  continue;
		}

	      depth = reach[id].depth;
	      dest_id = trans->state_id;

	      cost = reach[id].costs[depth][TRE_M_COST];
	      cost0 = reach[id].costs[0][TRE_M_COST];
	      err = 0;

	      if (trans->code_min > (tre_cint_t)prev_c
		  || trans->code_max < (tre_cint_t)prev_c)
		{
		  /* Handle substitutes.  The required character was not in
		     the string, so match it in place of whatever was supposed
		     to be there and increase costs accordingly. */
		  err = 1;

		  /* Compute and check cost at current depth. */
		  cost = reach[id].costs[depth][TRE_M_COST];
		  if (reach[id].params.cost_subst != TRE_PARAM_UNSET)
		    cost += reach[id].params.cost_subst;
		  if (cost > reach[id].params.max_cost)
		    continue; /* Cost too large. */

		  /* Check number of substitutes at current depth. */
		  if (reach[id].costs[depth][TRE_M_NUM_SUBST] + 1
		      > reach[id].params.max_subst)
		    continue; /* Too many substitutes. */

		  /* Check total number of errors at current depth. */
		  if (reach[id].costs[depth][TRE_M_NUM_ERR] + 1
		      > reach[id].params.max_err)
		    continue; /* Too many errors. */

		  /* Compute overall cost. */
		  cost0 = cost;
		  if (depth > 0)
		    {
		      cost0 = reach[id].costs[0][TRE_M_COST];
		      if (reach[id].params.cost_subst != TRE_PARAM_UNSET)
			cost0 += reach[id].params.cost_subst;
		      else
			cost0 += default_params.cost_subst;
		    }
		  DPRINT(("  subst,  from %03d to %03d, cost %d: ",
			  id, dest_id, cost0));
		}
	      else
		DPRINT(("  exact,  from %03d to %03d, cost %d: ",
			id, dest_id, cost0));

	      /* Compute tag values after this transition. */
	      for (i = 0; i < num_tags; i++)
		tmp_tags[i] = reach[id].tags[i];
	      if (trans->tags)
		for (i = 0; trans->tags[i] >= 0; i++)
		  if (trans->tags[i] < num_tags)
		    tmp_tags[trans->tags[i]] = pos;

	      /* If another path has also reached this state, choose the
		 one with the smallest cost or best tags if costs are equal. */
	      if (reach_next[dest_id].pos == pos
		  && (cost0 > reach_next[dest_id].costs[0][TRE_M_COST]
		      || (cost0 == reach_next[dest_id].costs[0][TRE_M_COST]
			  && !tre_tag_order(num_tags, tnfa->tag_directions,
					    tmp_tags,
					    reach_next[dest_id].tags))))
		{
		  DPRINT(("lose\n"));
		  continue;
		}
	      DPRINT(("win %d %d\n",
		      reach_next[dest_id].pos,
		      reach_next[dest_id].costs[0][TRE_M_COST]));

	      /* Set state, position, tags, and depth. */
	      reach_next[dest_id].state = trans->state;
	      reach_next[dest_id].pos = pos;
	      for (i = 0; i < num_tags; i++)
		reach_next[dest_id].tags[i] = tmp_tags[i];
	      reach_next[dest_id].depth = reach[id].depth;

	      /* Set parameters. */
	      reach_next[dest_id].params = reach[id].params;
	      if (trans->params)
		tre_set_params(&reach_next[dest_id], trans->params,
			       default_params);

	      /* Set the costs after this transition. */
		memcpy(&reach_next[dest_id].costs,
		       reach[id].costs,
		       sizeof(reach[id].costs[0][0])
		       * TRE_M_LAST * (depth + 1));
	      reach_next[dest_id].costs[depth][TRE_M_COST] = cost;
	      reach_next[dest_id].costs[depth][TRE_M_NUM_SUBST] += err;
	      reach_next[dest_id].costs[depth][TRE_M_NUM_ERR] += err;
	      if (depth > 0)
		{
		  reach_next[dest_id].costs[0][TRE_M_COST] = cost0;
		  reach_next[dest_id].costs[0][TRE_M_NUM_SUBST] += err;
		  reach_next[dest_id].costs[0][TRE_M_NUM_ERR] += err;
		}

	      if (trans->state == tnfa->final
		  && (match_eo < 0
		      || cost0 < match_costs[TRE_M_COST]
		      || (cost0 == match_costs[TRE_M_COST]
			  && num_tags > 0 && tmp_tags[0] <= match_tags[0])))
		{
		  DPRINT(("    setting new match at %d, cost %d\n",
			  pos, cost0));
		  match_eo = pos;
		  for (i = 0; i < TRE_M_LAST; i++)
		    match_costs[i] = reach_next[dest_id].costs[0][i];
		  for (i = 0; i < num_tags; i++)
		    match_tags[i] = tmp_tags[i];
		}
	    }
	}
    }

  DPRINT(("match end offset = %d, match cost = %d\n", match_eo,
	  match_costs[TRE_M_COST]));

#ifndef TRE_USE_ALLOCA
  if (buf)
    xfree(buf);
#endif /* !TRE_USE_ALLOCA */

  match->cost = match_costs[TRE_M_COST];
  match->num_ins = match_costs[TRE_M_NUM_INS];
  match->num_del = match_costs[TRE_M_NUM_DEL];
  match->num_subst = match_costs[TRE_M_NUM_SUBST];
  *match_end_ofs = match_eo;

  return match_eo >= 0 ? REG_OK : REG_NOMATCH;
}
/*
  tre-match-backtrack.c - TRE backtracking regex matching engine

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

/*
  This matcher is for regexps that use back referencing.  Regexp matching
  with back referencing is an NP-complete problem on the number of back
  references.  The easiest way to match them is to use a backtracking
  routine which basically goes through all possible paths in the TNFA
  and chooses the one which results in the best (leftmost and longest)
  match.  This can be spectacularly expensive and may run out of stack
  space, but there really is no better known generic algorithm.	 Quoting
  Henry Spencer from comp.compilers:
  <URL: http://compilers.iecc.com/comparch/article/93-03-102>

    POSIX.2 REs require longest match, which is really exciting to
    implement since the obsolete ("basic") variant also includes
    \<digit>.  I haven't found a better way of tackling this than doing
    a preliminary match using a DFA (or simulation) on a modified RE
    that just replicates subREs for \<digit>, and then doing a
    backtracking match to determine whether the subRE matches were
    right.  This can be rather slow, but I console myself with the
    thought that people who use \<digit> deserve very slow execution.
    (Pun unintentional but very appropriate.)

*/


#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */

#ifdef TRE_USE_ALLOCA
/* AIX requires this to be the first thing in the file.	 */
#ifndef __GNUC__
# if HAVE_ALLOCA_H
#  include <alloca.h>
# else
#  ifdef _AIX
 #pragma alloca
#  else
#   ifndef alloca /* predefined by HP cc +Olibcalls */
char *alloca ();
#   endif
#  endif
# endif
#endif
#endif /* TRE_USE_ALLOCA */

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#ifdef HAVE_WCHAR_H
#include <wchar.h>
#endif /* HAVE_WCHAR_H */
#ifdef HAVE_WCTYPE_H
#include <wctype.h>
#endif /* HAVE_WCTYPE_H */
#ifndef TRE_WCHAR
#include <ctype.h>
#endif /* !TRE_WCHAR */
#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif /* HAVE_MALLOC_H */


typedef struct {
  int pos;
  const char *str_byte;
#ifdef TRE_WCHAR
  const wchar_t *str_wide;
#endif /* TRE_WCHAR */
  tre_tnfa_transition_t *state;
  int state_id;
  int next_c;
  int *tags;
#ifdef TRE_MBSTATE
  mbstate_t mbstate;
#endif /* TRE_MBSTATE */
} tre_backtrack_item_t;

typedef struct tre_backtrack_struct {
  tre_backtrack_item_t item;
  struct tre_backtrack_struct *prev;
  struct tre_backtrack_struct *next;
} *tre_backtrack_t;

#ifdef TRE_WCHAR
#define BT_STACK_WIDE_IN(_str_wide)	stack->item.str_wide = (_str_wide)
#define BT_STACK_WIDE_OUT		(str_wide) = stack->item.str_wide
#else /* !TRE_WCHAR */
#define BT_STACK_WIDE_IN(_str_wide)
#define BT_STACK_WIDE_OUT
#endif /* !TRE_WCHAR */

#ifdef TRE_MBSTATE
#define BT_STACK_MBSTATE_IN  stack->item.mbstate = (mbstate)
#define BT_STACK_MBSTATE_OUT (mbstate) = stack->item.mbstate
#else /* !TRE_MBSTATE */
#define BT_STACK_MBSTATE_IN
#define BT_STACK_MBSTATE_OUT
#endif /* !TRE_MBSTATE */


#ifdef TRE_USE_ALLOCA
#define tre_bt_mem_new		  tre_mem_newa
#define tre_bt_mem_alloc	  tre_mem_alloca
#define tre_bt_mem_destroy(obj)	  do { } while (0)
#else /* !TRE_USE_ALLOCA */
#define tre_bt_mem_new		  tre_mem_new
#define tre_bt_mem_alloc	  tre_mem_alloc
#define tre_bt_mem_destroy	  tre_mem_destroy
#endif /* !TRE_USE_ALLOCA */


#define BT_STACK_PUSH(_pos, _str_byte, _str_wide, _state, _state_id, _next_c, _tags, _mbstate) \
  do									      \
    {									      \
      int i;								      \
      if (!stack->next)							      \
	{								      \
	  tre_backtrack_t s;						      \
	  s = tre_bt_mem_alloc(mem, sizeof(*s));			      \
	  if (!s)							      \
	    {								      \
	      tre_bt_mem_destroy(mem);					      \
	      if (tags)							      \
		xfree(tags);						      \
	      if (pmatch)						      \
		xfree(pmatch);						      \
	      if (states_seen)						      \
		xfree(states_seen);					      \
	      return REG_ESPACE;					      \
	    }								      \
	  s->prev = stack;						      \
	  s->next = NULL;						      \
	  s->item.tags = tre_bt_mem_alloc(mem,				      \
					  sizeof(*tags) * tnfa->num_tags);    \
	  if (!s->item.tags)						      \
	    {								      \
	      tre_bt_mem_destroy(mem);					      \
	      if (tags)							      \
		xfree(tags);						      \
	      if (pmatch)						      \
		xfree(pmatch);						      \
	      if (states_seen)						      \
		xfree(states_seen);					      \
	      return REG_ESPACE;					      \
	    }								      \
	  stack->next = s;						      \
	  stack = s;							      \
	}								      \
      else								      \
	stack = stack->next;						      \
      stack->item.pos = (_pos);						      \
      stack->item.str_byte = (_str_byte);				      \
      BT_STACK_WIDE_IN(_str_wide);					      \
      stack->item.state = (_state);					      \
      stack->item.state_id = (_state_id);				      \
      stack->item.next_c = (_next_c);					      \
      for (i = 0; i < tnfa->num_tags; i++)				      \
	stack->item.tags[i] = (_tags)[i];				      \
      BT_STACK_MBSTATE_IN;						      \
    }									      \
  while (/*CONSTCOND*/0)

#define BT_STACK_POP()							      \
  do									      \
    {									      \
      int i;								      \
      assert(stack->prev);						      \
      pos = stack->item.pos;						      \
      if (type == STR_USER)                                                   \
        str_source->rewind(pos + pos_add_next, str_source->context);          \
      str_byte = stack->item.str_byte;					      \
      BT_STACK_WIDE_OUT;						      \
      state = stack->item.state;					      \
      next_c = stack->item.next_c;					      \
      for (i = 0; i < tnfa->num_tags; i++)				      \
	tags[i] = stack->item.tags[i];					      \
      BT_STACK_MBSTATE_OUT;						      \
      stack = stack->prev;						      \
    }									      \
  while (/*CONSTCOND*/0)

#undef MIN
#define MIN(a, b) ((a) <= (b) ? (a) : (b))

reg_errcode_t
tre_tnfa_run_backtrack(const tre_tnfa_t *tnfa, const void *string,
		       int len, tre_str_type_t type, int *match_tags,
		       int eflags, int *match_end_ofs)
{
  /* State variables required by GET_NEXT_WCHAR. */
  tre_char_t prev_c = 0, next_c = 0;
  const char *str_byte = string;
  int pos = 0;
  unsigned int pos_add_next = 1;
#ifdef TRE_WCHAR
  const wchar_t *str_wide = string;
#ifdef TRE_MBSTATE
  mbstate_t mbstate;
#endif /* TRE_MBSTATE */
#endif /* TRE_WCHAR */
  int reg_notbol = eflags & REG_NOTBOL;
  int reg_noteol = eflags & REG_NOTEOL;
  int reg_newline = tnfa->cflags & REG_NEWLINE;
  int str_user_end = 0;

  /* These are used to remember the necessary values of the above
     variables to return to the position where the current search
     started from. */
  int next_c_start;
  const char *str_byte_start;
  int pos_start = -1;
#ifdef TRE_WCHAR
  const wchar_t *str_wide_start;
#endif /* TRE_WCHAR */
#ifdef TRE_MBSTATE
  mbstate_t mbstate_start;
#endif /* TRE_MBSTATE */

  /* End offset of best match so far, or -1 if no match found yet. */
  int match_eo = -1;
  /* Tag arrays. */
  int *next_tags, *tags = NULL;
  /* Current TNFA state. */
  tre_tnfa_transition_t *state;
  int *states_seen = NULL;

  /* Memory allocator to for allocating the backtracking stack. */
  tre_mem_t mem = tre_bt_mem_new();

  /* The backtracking stack. */
  tre_backtrack_t stack;

  tre_tnfa_transition_t *trans_i;
  regmatch_t *pmatch = NULL;
  int ret;

#ifdef TRE_MBSTATE
  memset(&mbstate, '\0', sizeof(mbstate));
#endif /* TRE_MBSTATE */

  if (!mem)
    return REG_ESPACE;
  stack = tre_bt_mem_alloc(mem, sizeof(*stack));
  if (!stack)
    {
      ret = REG_ESPACE;
      goto error_exit;
    }
  stack->prev = NULL;
  stack->next = NULL;

  DPRINT(("tnfa_execute_backtrack, input type %d\n", type));
  DPRINT(("len = %d\n", len));

#ifdef TRE_USE_ALLOCA
  tags = alloca(sizeof(*tags) * tnfa->num_tags);
  pmatch = alloca(sizeof(*pmatch) * tnfa->num_submatches);
  states_seen = alloca(sizeof(*states_seen) * tnfa->num_states);
#else /* !TRE_USE_ALLOCA */
  if (tnfa->num_tags)
    {
      tags = xmalloc(sizeof(*tags) * tnfa->num_tags);
      if (!tags)
	{
	  ret = REG_ESPACE;
	  goto error_exit;
	}
    }
  if (tnfa->num_submatches)
    {
      pmatch = xmalloc(sizeof(*pmatch) * tnfa->num_submatches);
      if (!pmatch)
	{
	  ret = REG_ESPACE;
	  goto error_exit;
	}
    }
  if (tnfa->num_states)
    {
      states_seen = xmalloc(sizeof(*states_seen) * tnfa->num_states);
      if (!states_seen)
	{
	  ret = REG_ESPACE;
	  goto error_exit;
	}
    }
#endif /* !TRE_USE_ALLOCA */

 retry:
  {
    int i;
    for (i = 0; i < tnfa->num_tags; i++)
      {
	tags[i] = -1;
	if (match_tags)
	  match_tags[i] = -1;
      }
    for (i = 0; i < tnfa->num_states; i++)
      states_seen[i] = 0;
  }

  state = NULL;
  pos = pos_start;
  if (type == STR_USER)
    str_source->rewind(pos + pos_add_next, str_source->context);
  GET_NEXT_WCHAR();
  pos_start = pos;
  next_c_start = next_c;
  str_byte_start = str_byte;
#ifdef TRE_WCHAR
  str_wide_start = str_wide;
#endif /* TRE_WCHAR */
#ifdef TRE_MBSTATE
  mbstate_start = mbstate;
#endif /* TRE_MBSTATE */

  /* Handle initial states. */
  next_tags = NULL;
  for (trans_i = tnfa->initial; trans_i->state; trans_i++)
    {
      DPRINT(("> init %p, prev_c %lc\n", trans_i->state, (tre_cint_t)prev_c));
      if (trans_i->assertions && CHECK_ASSERTIONS(trans_i->assertions))
	{
	  DPRINT(("assert failed\n"));
	  continue;
	}
      if (state == NULL)
	{
	  /* Start from this state. */
	  state = trans_i->state;
	  next_tags = trans_i->tags;
	}
      else
	{
	  /* Backtrack to this state. */
	  DPRINT(("saving state %d for backtracking\n", trans_i->state_id));
	  BT_STACK_PUSH(pos, str_byte, str_wide, trans_i->state,
			trans_i->state_id, next_c, tags, mbstate);
	  {
	    int *tmp = trans_i->tags;
	    if (tmp)
	      while (*tmp >= 0)
		stack->item.tags[*tmp++] = pos;
	  }
	}
    }

  if (next_tags)
    for (; *next_tags >= 0; next_tags++)
      tags[*next_tags] = pos;


  DPRINT(("entering match loop, pos %d, str_byte %p\n", pos, str_byte));
  DPRINT(("pos:chr/code | state and tags\n"));
  DPRINT(("-------------+------------------------------------------------\n"));

  if (state == NULL)
    goto backtrack;

  while (/*CONSTCOND*/1)
    {
      tre_tnfa_transition_t *next_state;
      int empty_br_match;

      DPRINT(("start loop\n"));
      if (state == tnfa->final)
	{
	  DPRINT(("  match found, %d %d\n", match_eo, pos));
	  if (match_eo < pos
	      || (match_eo == pos
		  && match_tags
		  && tre_tag_order(tnfa->num_tags, tnfa->tag_directions,
				   tags, match_tags)))
	    {
	      int i;
	      /* This match wins the previous match. */
	      DPRINT(("	 win previous\n"));
	      match_eo = pos;
	      if (match_tags)
		for (i = 0; i < tnfa->num_tags; i++)
		  match_tags[i] = tags[i];
	    }
	  /* Our TNFAs never have transitions leaving from the final state,
	     so we jump right to backtracking. */
	  goto backtrack;
	}

#ifdef TRE_DEBUG
      DPRINT(("%3d:%2lc/%05d | %p ", pos, (tre_cint_t)next_c, (int)next_c,
	      state));
      {
	int i;
	for (i = 0; i < tnfa->num_tags; i++)
	  DPRINT(("%d%s", tags[i], i < tnfa->num_tags - 1 ? ", " : ""));
	DPRINT(("\n"));
      }
#endif /* TRE_DEBUG */

      /* Go to the next character in the input string. */
      empty_br_match = 0;
      trans_i = state;
      if (trans_i->state && trans_i->assertions & ASSERT_BACKREF)
	{
	  /* This is a back reference state.  All transitions leaving from
	     this state have the same back reference "assertion".  Instead
	     of reading the next character, we match the back reference. */
	  int so, eo, bt = trans_i->u.backref;
	  int bt_len;
	  int result;

	  DPRINT(("  should match back reference %d\n", bt));
	  /* Get the substring we need to match against.  Remember to
	     turn off REG_NOSUB temporarily. */
	  tre_fill_pmatch(bt + 1, pmatch, tnfa->cflags & /*LINTED*/!REG_NOSUB,
			  tnfa, tags, pos);
	  so = pmatch[bt].rm_so;
	  eo = pmatch[bt].rm_eo;
	  bt_len = eo - so;

#ifdef TRE_DEBUG
	  {
	    int slen;
	    if (len < 0)
	      slen = bt_len;
	    else
	      slen = MIN(bt_len, len - pos);

	    if (type == STR_BYTE)
	      {
		DPRINT(("  substring (len %d) is [%d, %d[: '%.*s'\n",
			bt_len, so, eo, bt_len, (char*)string + so));
		DPRINT(("  current string is '%.*s'\n", slen, str_byte - 1));
	      }
#ifdef TRE_WCHAR
	    else if (type == STR_WIDE)
	      {
		DPRINT(("  substring (len %d) is [%d, %d[: '%.*" STRF "'\n",
			bt_len, so, eo, bt_len, (wchar_t*)string + so));
		DPRINT(("  current string is '%.*" STRF "'\n",
			slen, str_wide - 1));
	      }
#endif /* TRE_WCHAR */
	  }
#endif

	  if (len < 0)
	    {
	      if (type == STR_USER)
		result = str_source->compare((unsigned)so, (unsigned)pos,
					     (unsigned)bt_len,
					     str_source->context);
#ifdef TRE_WCHAR
	      else if (type == STR_WIDE)
		result = wcsncmp((const wchar_t*)string + so, str_wide - 1,
				 (size_t)bt_len);
#endif /* TRE_WCHAR */
	      else
		result = strncmp((const char*)string + so, str_byte - 1,
				 (size_t)bt_len);
	    }
	  else if (len - pos < bt_len)
	    result = 1;
#ifdef TRE_WCHAR
	  else if (type == STR_WIDE)
	    result = wmemcmp((const wchar_t*)string + so, str_wide - 1,
			     (size_t)bt_len);
#endif /* TRE_WCHAR */
	  else
	    result = memcmp((const char*)string + so, str_byte - 1,
			    (size_t)bt_len);

	  if (result == 0)
	    {
	      /* Back reference matched.  Check for infinite loop. */
	      if (bt_len == 0)
		empty_br_match = 1;
	      if (empty_br_match && states_seen[trans_i->state_id])
		{
		  DPRINT(("  avoid loop\n"));
		  goto backtrack;
		}

	      states_seen[trans_i->state_id] = empty_br_match;

	      /* Advance in input string and resync `prev_c', `next_c'
		 and pos. */
	      DPRINT(("	 back reference matched\n"));
	      str_byte += bt_len - 1;
#ifdef TRE_WCHAR
	      str_wide += bt_len - 1;
#endif /* TRE_WCHAR */
	      pos += bt_len - 1;
	      GET_NEXT_WCHAR();
	      DPRINT(("	 pos now %d\n", pos));
	    }
	  else
	    {
	      DPRINT(("	 back reference did not match\n"));
	      goto backtrack;
	    }
	}
      else
	{
	  /* Check for end of string. */
	  if (len < 0)
	    {
	      if (type == STR_USER)
		{
		  if (str_user_end)
		    goto backtrack;
		}
	      else if (next_c == L'\0')
		goto backtrack;
	    }
	  else
	    {
	      if (pos >= len)
		goto backtrack;
	    }

	  /* Read the next character. */
	  GET_NEXT_WCHAR();
	}

      next_state = NULL;
      for (trans_i = state; trans_i->state; trans_i++)
	{
	  DPRINT(("  transition %d-%d (%c-%c) %d to %d\n",
		  trans_i->code_min, trans_i->code_max,
		  trans_i->code_min, trans_i->code_max,
		  trans_i->assertions, trans_i->state_id));
	  if (trans_i->code_min <= (tre_cint_t)prev_c
	      && trans_i->code_max >= (tre_cint_t)prev_c)
	    {
	      if (trans_i->assertions
		  && (CHECK_ASSERTIONS(trans_i->assertions)
		      || CHECK_CHAR_CLASSES(trans_i, tnfa, eflags)))
		{
		  DPRINT(("  assertion failed\n"));
		  continue;
		}

	      if (next_state == NULL)
		{
		  /* First matching transition. */
		  DPRINT(("  Next state is %d\n", trans_i->state_id));
		  next_state = trans_i->state;
		  next_tags = trans_i->tags;
		}
	      else
		{
		  /* Second matching transition.  We may need to backtrack here
		     to take this transition instead of the first one, so we
		     push this transition in the backtracking stack so we can
		     jump back here if needed. */
		  DPRINT(("  saving state %d for backtracking\n",
			  trans_i->state_id));
		  BT_STACK_PUSH(pos, str_byte, str_wide, trans_i->state,
				trans_i->state_id, next_c, tags, mbstate);
		  {
		    int *tmp;
		    for (tmp = trans_i->tags; tmp && *tmp >= 0; tmp++)
		      stack->item.tags[*tmp] = pos;
		  }
#if 0 /* XXX - it's important not to look at all transitions here to keep
	 the stack small! */
		  break;
#endif
		}
	    }
	}

      if (next_state != NULL)
	{
	  /* Matching transitions were found.  Take the first one. */
	  state = next_state;

	  /* Update the tag values. */
	  if (next_tags)
	    while (*next_tags >= 0)
	      tags[*next_tags++] = pos;
	}
      else
	{
	backtrack:
	  /* A matching transition was not found.  Try to backtrack. */
	  if (stack->prev)
	    {
	      DPRINT(("	 backtracking\n"));
	      if (stack->item.state->assertions && ASSERT_BACKREF)
		{
		  DPRINT(("  states_seen[%d] = 0\n",
			  stack->item.state_id));
		  states_seen[stack->item.state_id] = 0;
		}

	      BT_STACK_POP();
	    }
	  else if (match_eo < 0)
	    {
	      /* Try starting from a later position in the input string. */
	      /* Check for end of string. */
	      if (len < 0)
		{
		  if (next_c == L'\0')
		    {
		      DPRINT(("end of string.\n"));
		      break;
		    }
		}
	      else
		{
		  if (pos >= len)
		    {
		      DPRINT(("end of string.\n"));
		      break;
		    }
		}
	      DPRINT(("restarting from next start position\n"));
	      next_c = next_c_start;
#ifdef TRE_MBSTATE
	      mbstate = mbstate_start;
#endif /* TRE_MBSTATE */
	      str_byte = str_byte_start;
#ifdef TRE_WCHAR
	      str_wide = str_wide_start;
#endif /* TRE_WCHAR */
	      goto retry;
	    }
	  else
	    {
	      DPRINT(("finished\n"));
	      break;
	    }
	}
    }

  ret = match_eo >= 0 ? REG_OK : REG_NOMATCH;
  *match_end_ofs = match_eo;

 error_exit:
  tre_bt_mem_destroy(mem);
#ifndef TRE_USE_ALLOCA
  if (tags)
    xfree(tags);
  if (pmatch)
    xfree(pmatch);
  if (states_seen)
    xfree(states_seen);
#endif /* !TRE_USE_ALLOCA */

  return ret;
}
/*
  tre-match-parallel.c - TRE parallel regex matching engine

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

/*
  This algorithm searches for matches basically by reading characters
  in the searched string one by one, starting at the beginning.	 All
  matching paths in the TNFA are traversed in parallel.	 When two or
  more paths reach the same state, exactly one is chosen according to
  tag ordering rules; if returning submatches is not required it does
  not matter which path is chosen.

  The worst case time required for finding the leftmost and longest
  match, or determining that there is no match, is always linearly
  dependent on the length of the text being searched.

  This algorithm cannot handle TNFAs with back referencing nodes.
  See `tre-match-backtrack.c'.
*/


#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */

#ifdef TRE_USE_ALLOCA
/* AIX requires this to be the first thing in the file.	 */
#ifndef __GNUC__
# if HAVE_ALLOCA_H
#  include <alloca.h>
# else
#  ifdef _AIX
 #pragma alloca
#  else
#   ifndef alloca /* predefined by HP cc +Olibcalls */
char *alloca ();
#   endif
#  endif
# endif
#endif
#endif /* TRE_USE_ALLOCA */

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#ifdef HAVE_WCHAR_H
#include <wchar.h>
#endif /* HAVE_WCHAR_H */
#ifdef HAVE_WCTYPE_H
#include <wctype.h>
#endif /* HAVE_WCTYPE_H */
#ifndef TRE_WCHAR
#include <ctype.h>
#endif /* !TRE_WCHAR */
#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif /* HAVE_MALLOC_H */




typedef struct {
  tre_tnfa_transition_t *state;
  int *tags;
} tre_tnfa_reach_t;

typedef struct {
  int pos;
  int **tags;
} tre_reach_pos_t;


#ifdef TRE_DEBUG
static void
tre_print_reach(const tre_tnfa_t *tnfa, tre_tnfa_reach_t *reach, int num_tags)
{
  int i;

  while (reach->state != NULL)
    {
      DPRINT((" %p", (void *)reach->state));
      if (num_tags > 0)
	{
	  DPRINT(("/"));
	  for (i = 0; i < num_tags; i++)
	    {
	      DPRINT(("%d:%d", i, reach->tags[i]));
	      if (i < (num_tags-1))
		DPRINT((","));
	    }
	}
      reach++;
    }
  DPRINT(("\n"));

}
#endif /* TRE_DEBUG */

reg_errcode_t
tre_tnfa_run_parallel(const tre_tnfa_t *tnfa, const void *string, int len,
		      tre_str_type_t type, int *match_tags, int eflags,
		      int *match_end_ofs)
{
  /* State variables required by GET_NEXT_WCHAR. */
  tre_char_t prev_c = 0, next_c = 0;
  const char *str_byte = string;
  int pos = -1;
  unsigned int pos_add_next = 1;
#ifdef TRE_WCHAR
  const wchar_t *str_wide = string;
#ifdef TRE_MBSTATE
  mbstate_t mbstate;
#endif /* TRE_MBSTATE */
#endif /* TRE_WCHAR */
  int reg_notbol = eflags & REG_NOTBOL;
  int reg_noteol = eflags & REG_NOTEOL;
  int reg_newline = tnfa->cflags & REG_NEWLINE;
  int str_user_end = 0;

  char *buf;
  tre_tnfa_transition_t *trans_i;
  tre_tnfa_reach_t *reach, *reach_next, *reach_i, *reach_next_i;
  tre_reach_pos_t *reach_pos;
  int *tag_i;
  int num_tags, i;

  int match_eo = -1;	   /* end offset of match (-1 if no match found yet) */
  int new_match = 0;
  int *tmp_tags = NULL;
  int *tmp_iptr;

#ifdef TRE_MBSTATE
  memset(&mbstate, '\0', sizeof(mbstate));
#endif /* TRE_MBSTATE */

  DPRINT(("tre_tnfa_run_parallel, input type %d\n", type));

  if (!match_tags)
    num_tags = 0;
  else
    num_tags = tnfa->num_tags;

  /* Allocate memory for temporary data required for matching.	This needs to
     be done for every matching operation to be thread safe.  This allocates
     everything in a single large block from the stack frame using alloca()
     or with malloc() if alloca is unavailable. */
  {
    int tbytes, rbytes, pbytes, xbytes, total_bytes;
    char *tmp_buf;
    /* Compute the length of the block we need. */
    tbytes = sizeof(*tmp_tags) * num_tags;
    rbytes = sizeof(*reach_next) * (tnfa->num_states + 1);
    pbytes = sizeof(*reach_pos) * tnfa->num_states;
    xbytes = sizeof(int) * num_tags;
    total_bytes =
      (sizeof(long) - 1) * 4 /* for alignment paddings */
      + (rbytes + xbytes * tnfa->num_states) * 2 + tbytes + pbytes;

    /* Allocate the memory. */
#ifdef TRE_USE_ALLOCA
    buf = alloca(total_bytes);
#else /* !TRE_USE_ALLOCA */
    buf = xmalloc((unsigned)total_bytes);
#endif /* !TRE_USE_ALLOCA */
    if (buf == NULL)
      return REG_ESPACE;
    memset(buf, 0, (size_t)total_bytes);

    /* Get the various pointers within tmp_buf (properly aligned). */
    tmp_tags = (void *)buf;
    tmp_buf = buf + tbytes;
    tmp_buf += ALIGN(tmp_buf, long);
    reach_next = (void *)tmp_buf;
    tmp_buf += rbytes;
    tmp_buf += ALIGN(tmp_buf, long);
    reach = (void *)tmp_buf;
    tmp_buf += rbytes;
    tmp_buf += ALIGN(tmp_buf, long);
    reach_pos = (void *)tmp_buf;
    tmp_buf += pbytes;
    tmp_buf += ALIGN(tmp_buf, long);
    for (i = 0; i < tnfa->num_states; i++)
      {
	reach[i].tags = (void *)tmp_buf;
	tmp_buf += xbytes;
	reach_next[i].tags = (void *)tmp_buf;
	tmp_buf += xbytes;
      }
  }

  for (i = 0; i < tnfa->num_states; i++)
    reach_pos[i].pos = -1;

  /* If only one character can start a match, find it first. */
  if (tnfa->first_char >= 0 && type == STR_BYTE && str_byte)
    {
      const char *orig_str = str_byte;
      int first = tnfa->first_char;

      if (len >= 0)
	str_byte = memchr(orig_str, first, (size_t)len);
      else
	str_byte = strchr(orig_str, first);
      if (str_byte == NULL)
	{
#ifndef TRE_USE_ALLOCA
	  if (buf)
	    xfree(buf);
#endif /* !TRE_USE_ALLOCA */
	  return REG_NOMATCH;
	}
      DPRINT(("skipped %lu chars\n", (unsigned long)(str_byte - orig_str)));
      if (str_byte >= orig_str + 1)
	prev_c = (unsigned char)*(str_byte - 1);
      next_c = (unsigned char)*str_byte;
      pos = str_byte - orig_str;
      if (len < 0 || pos < len)
	str_byte++;
    }
  else
    {
      GET_NEXT_WCHAR();
      pos = 0;
    }

#if 0
  /* Skip over characters that cannot possibly be the first character
     of a match. */
  if (tnfa->firstpos_chars != NULL)
    {
      char *chars = tnfa->firstpos_chars;

      if (len < 0)
	{
	  const char *orig_str = str_byte;
	  /* XXX - use strpbrk() and wcspbrk() because they might be
	     optimized for the target architecture.  Try also strcspn()
	     and wcscspn() and compare the speeds. */
	  while (next_c != L'\0' && !chars[next_c])
	    {
	      next_c = *str_byte++;
	    }
	  prev_c = *(str_byte - 2);
	  pos += str_byte - orig_str;
	  DPRINT(("skipped %d chars\n", str_byte - orig_str));
	}
      else
	{
	  while (pos <= len && !chars[next_c])
	    {
	      prev_c = next_c;
	      next_c = (unsigned char)(*str_byte++);
	      pos++;
	    }
	}
    }
#endif

  DPRINT(("length: %d\n", len));
  DPRINT(("pos:chr/code | states and tags\n"));
  DPRINT(("-------------+------------------------------------------------\n"));

  reach_next_i = reach_next;
  while (/*CONSTCOND*/1)
    {
      /* If no match found yet, add the initial states to `reach_next'. */
      if (match_eo < 0)
	{
	  DPRINT((" init >"));
	  trans_i = tnfa->initial;
	  while (trans_i->state != NULL)
	    {
	      if (reach_pos[trans_i->state_id].pos < pos)
		{
		  if (trans_i->assertions
		      && CHECK_ASSERTIONS(trans_i->assertions))
		    {
		      DPRINT(("assertion failed\n"));
		      trans_i++;
		      continue;
		    }

		  DPRINT((" %p", (void *)trans_i->state));
		  reach_next_i->state = trans_i->state;
		  for (i = 0; i < num_tags; i++)
		    reach_next_i->tags[i] = -1;
		  tag_i = trans_i->tags;
		  if (tag_i)
		    while (*tag_i >= 0)
		      {
			if (*tag_i < num_tags)
			  reach_next_i->tags[*tag_i] = pos;
			tag_i++;
		      }
		  if (reach_next_i->state == tnfa->final)
		    {
		      DPRINT(("	 found empty match\n"));
		      match_eo = pos;
		      new_match = 1;
		      for (i = 0; i < num_tags; i++)
			match_tags[i] = reach_next_i->tags[i];
		    }
		  reach_pos[trans_i->state_id].pos = pos;
		  reach_pos[trans_i->state_id].tags = &reach_next_i->tags;
		  reach_next_i++;
		}
	      trans_i++;
	    }
	  DPRINT(("\n"));
	  reach_next_i->state = NULL;
	}
      else
	{
	  if (num_tags == 0 || reach_next_i == reach_next)
	    /* We have found a match. */
	    break;
	}

      /* Check for end of string. */
      if (len < 0)
	{
	  if (type == STR_USER)
	    {
	      if (str_user_end)
		break;
	    }
	  else if (next_c == L'\0')
	    break;
	}
      else
	{
	  if (pos >= len)
	    break;
	}

      GET_NEXT_WCHAR();

#ifdef TRE_DEBUG
      DPRINT(("%3d:%2lc/%05d |", pos - 1, (tre_cint_t)prev_c, (int)prev_c));
      tre_print_reach(tnfa, reach_next, num_tags);
      DPRINT(("%3d:%2lc/%05d |", pos, (tre_cint_t)next_c, (int)next_c));
      tre_print_reach(tnfa, reach_next, num_tags);
#endif /* TRE_DEBUG */

      /* Swap `reach' and `reach_next'. */
      reach_i = reach;
      reach = reach_next;
      reach_next = reach_i;

      /* For each state in `reach', weed out states that don't fulfill the
	 minimal matching conditions. */
      if (tnfa->num_minimals && new_match)
	{
	  new_match = 0;
	  reach_next_i = reach_next;
	  for (reach_i = reach; reach_i->state; reach_i++)
	    {
	      int skip = 0;
	      for (i = 0; tnfa->minimal_tags[i] >= 0; i += 2)
		{
		  int end = tnfa->minimal_tags[i];
		  int start = tnfa->minimal_tags[i + 1];
		  DPRINT(("  Minimal start %d, end %d\n", start, end));
		  if (end >= num_tags)
		    {
		      DPRINT(("	 Throwing %p out.\n", reach_i->state));
		      skip = 1;
		      break;
		    }
		  else if (reach_i->tags[start] == match_tags[start]
			   && reach_i->tags[end] < match_tags[end])
		    {
		      DPRINT(("	 Throwing %p out because t%d < %d\n",
			      reach_i->state, end, match_tags[end]));
		      skip = 1;
		      break;
		    }
		}
	      if (!skip)
		{
		  reach_next_i->state = reach_i->state;
		  tmp_iptr = reach_next_i->tags;
		  reach_next_i->tags = reach_i->tags;
		  reach_i->tags = tmp_iptr;
		  reach_next_i++;
		}
	    }
	  reach_next_i->state = NULL;

	  /* Swap `reach' and `reach_next'. */
	  reach_i = reach;
	  reach = reach_next;
	  reach_next = reach_i;
	}

      /* For each state in `reach' see if there is a transition leaving with
	 the current input symbol to a state not yet in `reach_next', and
	 add the destination states to `reach_next'. */
      reach_next_i = reach_next;
      for (reach_i = reach; reach_i->state; reach_i++)
	{
	  for (trans_i = reach_i->state; trans_i->state; trans_i++)
	    {
	      /* Does this transition match the input symbol? */
	      if (trans_i->code_min <= (tre_cint_t)prev_c &&
		  trans_i->code_max >= (tre_cint_t)prev_c)
		{
		  if (trans_i->assertions
		      && (CHECK_ASSERTIONS(trans_i->assertions)
			  || CHECK_CHAR_CLASSES(trans_i, tnfa, eflags)))
		    {
		      DPRINT(("assertion failed\n"));
		      continue;
		    }

		  /* Compute the tags after this transition. */
		  for (i = 0; i < num_tags; i++)
		    tmp_tags[i] = reach_i->tags[i];
		  tag_i = trans_i->tags;
		  if (tag_i != NULL)
		    while (*tag_i >= 0)
		      {
			if (*tag_i < num_tags)
			  tmp_tags[*tag_i] = pos;
			tag_i++;
		      }

		  if (reach_pos[trans_i->state_id].pos < pos)
		    {
		      /* Found an unvisited node. */
		      reach_next_i->state = trans_i->state;
		      tmp_iptr = reach_next_i->tags;
		      reach_next_i->tags = tmp_tags;
		      tmp_tags = tmp_iptr;
		      reach_pos[trans_i->state_id].pos = pos;
		      reach_pos[trans_i->state_id].tags = &reach_next_i->tags;

		      if (reach_next_i->state == tnfa->final
			  && (match_eo == -1
			      || (num_tags > 0
				  && reach_next_i->tags[0] <= match_tags[0])))
			{
			  DPRINT(("  found match %p\n", trans_i->state));
			  match_eo = pos;
			  new_match = 1;
			  for (i = 0; i < num_tags; i++)
			    match_tags[i] = reach_next_i->tags[i];
			}
		      reach_next_i++;

		    }
		  else
		    {
		      assert(reach_pos[trans_i->state_id].pos == pos);
		      /* Another path has also reached this state.  We choose
			 the winner by examining the tag values for both
			 paths. */
		      if (tre_tag_order(num_tags, tnfa->tag_directions,
					tmp_tags,
					*reach_pos[trans_i->state_id].tags))
			{
			  /* The new path wins. */
			  tmp_iptr = *reach_pos[trans_i->state_id].tags;
			  *reach_pos[trans_i->state_id].tags = tmp_tags;
			  if (trans_i->state == tnfa->final)
			    {
			      DPRINT(("	 found better match\n"));
			      match_eo = pos;
			      new_match = 1;
			      for (i = 0; i < num_tags; i++)
				match_tags[i] = tmp_tags[i];
			    }
			  tmp_tags = tmp_iptr;
			}
		    }
		}
	    }
	}
      reach_next_i->state = NULL;
    }

  DPRINT(("match end offset = %d\n", match_eo));

#ifndef TRE_USE_ALLOCA
  if (buf)
    xfree(buf);
#endif /* !TRE_USE_ALLOCA */

  *match_end_ofs = match_eo;
  return match_eo >= 0 ? REG_OK : REG_NOMATCH;
}

/* EOF */
/*
  tre-mem.c - TRE memory allocator

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

/*
  This memory allocator is for allocating small memory blocks efficiently
  in terms of memory overhead and execution speed.  The allocated blocks
  cannot be freed individually, only all at once.  There can be multiple
  allocators, though.
*/

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */
#include <stdlib.h>
#include <string.h>



/* Returns a new memory allocator or NULL if out of memory. */
tre_mem_t
tre_mem_new_impl(int provided, void *provided_block)
{
  tre_mem_t mem;
  if (provided)
    {
      mem = provided_block;
      memset(mem, 0, sizeof(*mem));
    }
  else
    mem = xcalloc(1, sizeof(*mem));
  if (mem == NULL)
    return NULL;
  return mem;
}


/* Frees the memory allocator and all memory allocated with it. */
void
tre_mem_destroy(tre_mem_t mem)
{
  tre_list_t *tmp, *l = mem->blocks;

  while (l != NULL)
    {
      xfree(l->data);
      tmp = l->next;
      xfree(l);
      l = tmp;
    }
  xfree(mem);
}


/* Allocates a block of `size' bytes from `mem'.  Returns a pointer to the
   allocated block or NULL if an underlying malloc() failed. */
void *
tre_mem_alloc_impl(tre_mem_t mem, int provided, void *provided_block,
		   int zero, size_t size)
{
  void *ptr;

  if (mem->failed)
    {
      DPRINT(("tre_mem_alloc: oops, called after failure?!\n"));
      return NULL;
    }

#ifdef MALLOC_DEBUGGING
  if (!provided)
    {
      ptr = xmalloc(1);
      if (ptr == NULL)
	{
	  DPRINT(("tre_mem_alloc: xmalloc forced failure\n"));
	  mem->failed = 1;
	  return NULL;
	}
      xfree(ptr);
    }
#endif /* MALLOC_DEBUGGING */

  if (mem->n < size)
    {
      /* We need more memory than is available in the current block.
	 Allocate a new block. */
      tre_list_t *l;
      if (provided)
	{
	  DPRINT(("tre_mem_alloc: using provided block\n"));
	  if (provided_block == NULL)
	    {
	      DPRINT(("tre_mem_alloc: provided block was NULL\n"));
	      mem->failed = 1;
	      return NULL;
	    }
	  mem->ptr = provided_block;
	  mem->n = TRE_MEM_BLOCK_SIZE;
	}
      else
	{
	  int block_size;
	  if (size * 8 > TRE_MEM_BLOCK_SIZE)
	    block_size = size * 8;
	  else
	    block_size = TRE_MEM_BLOCK_SIZE;
	  DPRINT(("tre_mem_alloc: allocating new %d byte block\n",
		  block_size));
	  l = xmalloc(sizeof(*l));
	  if (l == NULL)
	    {
	      mem->failed = 1;
	      return NULL;
	    }
	  l->data = xmalloc(block_size);
	  if (l->data == NULL)
	    {
	      xfree(l);
	      mem->failed = 1;
	      return NULL;
	    }
	  l->next = NULL;
	  if (mem->current != NULL)
	    mem->current->next = l;
	  if (mem->blocks == NULL)
	    mem->blocks = l;
	  mem->current = l;
	  mem->ptr = l->data;
	  mem->n = block_size;
	}
    }

  /* Make sure the next pointer will be aligned. */
  size += ALIGN(mem->ptr + size, long);

  /* Allocate from current block. */
  ptr = mem->ptr;
  mem->ptr += size;
  mem->n -= size;

  /* Set to zero if needed. */
  if (zero)
    memset(ptr, 0, size);

  return ptr;
}

/* EOF */
/*
  tre-parse.c - Regexp parser

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

/*
  This parser is just a simple recursive descent parser for POSIX.2
  regexps.  The parser supports both the obsolete default syntax and
  the "extended" syntax, and some nonstandard extensions.
*/


#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */
#include <string.h>
#include <assert.h>
#include <limits.h>



/* Characters with special meanings in regexp syntax. */
#define CHAR_PIPE	   L'|'
#define CHAR_LPAREN	   L'('
#define CHAR_RPAREN	   L')'
#define CHAR_LBRACE	   L'{'
#define CHAR_RBRACE	   L'}'
#define CHAR_LBRACKET	   L'['
#define CHAR_RBRACKET	   L']'
#define CHAR_MINUS	   L'-'
#define CHAR_STAR	   L'*'
#define CHAR_QUESTIONMARK  L'?'
#define CHAR_PLUS	   L'+'
#define CHAR_PERIOD	   L'.'
#define CHAR_COLON	   L':'
#define CHAR_EQUAL	   L'='
#define CHAR_COMMA	   L','
#define CHAR_CARET	   L'^'
#define CHAR_DOLLAR	   L'$'
#define CHAR_BACKSLASH	   L'\\'
#define CHAR_HASH	   L'#'
#define CHAR_TILDE	   L'~'


/* Some macros for expanding \w, \s, etc. */
static const struct tre_macro_struct {
  const char c;
  const char *expansion;
} tre_macros[] =
  { {'t', "\t"},	   {'n', "\n"},		   {'r', "\r"},
    {'f', "\f"},	   {'a', "\a"},		   {'e', "\033"},
    {'w', "[[:alnum:]_]"}, {'W', "[^[:alnum:]_]"}, {'s', "[[:space:]]"},
    {'S', "[^[:space:]]"}, {'d', "[[:digit:]]"},   {'D', "[^[:digit:]]"},
    { 0, NULL }
  };


/* Expands a macro delimited by `regex' and `regex_end' to `buf', which
   must have at least `len' items.  Sets buf[0] to zero if the there
   is no match in `tre_macros'. */
static void
tre_expand_macro(const tre_char_t *regex, const tre_char_t *regex_end,
		 tre_char_t *buf, size_t buf_len)
{
  int i;

  buf[0] = 0;
  if (regex >= regex_end)
    return;

  for (i = 0; tre_macros[i].expansion; i++)
    {
      if (tre_macros[i].c == *regex)
	{
	  unsigned int j;
	  DPRINT(("Expanding macro '%c' => '%s'\n",
		  tre_macros[i].c, tre_macros[i].expansion));
	  for (j = 0; tre_macros[i].expansion[j] && j < buf_len; j++)
	    buf[j] = tre_macros[i].expansion[j];
	  buf[j] = 0;
	  break;
	}
    }
}

static reg_errcode_t
tre_new_item(tre_mem_t mem, int min, int max, int *i, int *max_i,
	 tre_ast_node_t ***items)
{
  reg_errcode_t status;
  tre_ast_node_t **array = *items;
  /* Allocate more space if necessary. */
  if (*i >= *max_i)
    {
      tre_ast_node_t **new_items;
      DPRINT(("out of array space, i = %d\n", *i));
      /* If the array is already 1024 items large, give up -- there's
	 probably an error in the regexp (e.g. not a '\0' terminated
	 string and missing ']') */
      if (*max_i > 1024)
	return REG_ESPACE;
      *max_i *= 2;
      new_items = xrealloc(array, sizeof(*items) * *max_i);
      if (new_items == NULL)
	return REG_ESPACE;
      *items = array = new_items;
    }
  array[*i] = tre_ast_new_literal(mem, min, max, -1);
  status = array[*i] == NULL ? REG_ESPACE : REG_OK;
  (*i)++;
  return status;
}


/* Expands a character class to character ranges. */
static reg_errcode_t
tre_expand_ctype(tre_mem_t mem, tre_ctype_t class, tre_ast_node_t ***items,
		 int *i, int *max_i, int cflags)
{
  reg_errcode_t status = REG_OK;
  tre_cint_t c;
  int j, min = -1, max = 0;
  assert(TRE_MB_CUR_MAX == 1);

  DPRINT(("  expanding class to character ranges\n"));
  for (j = 0; (j < 256) && (status == REG_OK); j++)
    {
      c = j;
      if (tre_isctype(c, class)
	  || ((cflags & REG_ICASE)
	      && (tre_isctype(tre_tolower(c), class)
		  || tre_isctype(tre_toupper(c), class))))
{
	  if (min < 0)
	    min = c;
	  max = c;
	}
      else if (min >= 0)
	{
	  DPRINT(("  range %c (%d) to %c (%d)\n", min, min, max, max));
	  status = tre_new_item(mem, min, max, i, max_i, items);
	  min = -1;
	}
    }
  if (min >= 0 && status == REG_OK)
    status = tre_new_item(mem, min, max, i, max_i, items);
  return status;
}


static int
tre_compare_items(const void *a, const void *b)
{
  const tre_ast_node_t *node_a = *(tre_ast_node_t * const *)a;
  const tre_ast_node_t *node_b = *(tre_ast_node_t * const *)b;
  tre_literal_t *l_a = node_a->obj, *l_b = node_b->obj;
  int a_min = l_a->code_min, b_min = l_b->code_min;

  if (a_min < b_min)
    return -1;
  else if (a_min > b_min)
    return 1;
  else
    return 0;
}

#ifndef TRE_USE_SYSTEM_WCTYPE

/* isalnum() and the rest may be macros, so wrap them to functions. */
int tre_isalnum_func(tre_cint_t c) { return tre_isalnum(c); }
int tre_isalpha_func(tre_cint_t c) { return tre_isalpha(c); }

#ifdef tre_isascii
int tre_isascii_func(tre_cint_t c) { return tre_isascii(c); }
#else /* !tre_isascii */
int tre_isascii_func(tre_cint_t c) { return !(c >> 7); }
#endif /* !tre_isascii */

#ifdef tre_isblank
int tre_isblank_func(tre_cint_t c) { return tre_isblank(c); }
#else /* !tre_isblank */
int tre_isblank_func(tre_cint_t c) { return ((c == ' ') || (c == '\t')); }
#endif /* !tre_isblank */

int tre_iscntrl_func(tre_cint_t c) { return tre_iscntrl(c); }
int tre_isdigit_func(tre_cint_t c) { return tre_isdigit(c); }
int tre_isgraph_func(tre_cint_t c) { return tre_isgraph(c); }
int tre_islower_func(tre_cint_t c) { return tre_islower(c); }
int tre_isprint_func(tre_cint_t c) { return tre_isprint(c); }
int tre_ispunct_func(tre_cint_t c) { return tre_ispunct(c); }
int tre_isspace_func(tre_cint_t c) { return tre_isspace(c); }
int tre_isupper_func(tre_cint_t c) { return tre_isupper(c); }
int tre_isxdigit_func(tre_cint_t c) { return tre_isxdigit(c); }

struct {
  char *name;
  int (*func)(tre_cint_t);
} tre_ctype_map[] = {
  { "alnum", &tre_isalnum_func },
  { "alpha", &tre_isalpha_func },
#ifdef tre_isascii
  { "ascii", &tre_isascii_func },
#endif /* tre_isascii */
#ifdef tre_isblank
  { "blank", &tre_isblank_func },
#endif /* tre_isblank */
  { "cntrl", &tre_iscntrl_func },
  { "digit", &tre_isdigit_func },
  { "graph", &tre_isgraph_func },
  { "lower", &tre_islower_func },
  { "print", &tre_isprint_func },
  { "punct", &tre_ispunct_func },
  { "space", &tre_isspace_func },
  { "upper", &tre_isupper_func },
  { "xdigit", &tre_isxdigit_func },
  { NULL, NULL}
};

tre_ctype_t tre_ctype(const char *name)
{
  int i;
  for (i = 0; tre_ctype_map[i].name != NULL; i++)
    {
      if (strcmp(name, tre_ctype_map[i].name) == 0)
	return tre_ctype_map[i].func;
    }
  return (tre_ctype_t)0;
}
#endif /* !TRE_USE_SYSTEM_WCTYPE */

/* Maximum number of character classes that can occur in a negated bracket
   expression.	*/
#define MAX_NEG_CLASSES 64

/* Maximum length of character class names. */
#define MAX_CLASS_NAME

#define REST(re) (int)(ctx->re_end - (re)), (re)

static reg_errcode_t
tre_parse_bracket_items(tre_parse_ctx_t *ctx, int negate,
			tre_ctype_t neg_classes[], int *num_neg_classes,
			tre_ast_node_t ***items, int *num_items,
			int *items_size)
{
  const tre_char_t *re = ctx->re;
  reg_errcode_t status = REG_OK;
  tre_ctype_t class = (tre_ctype_t)0;
  int i = *num_items;
  int max_i = *items_size;
  int skip;

  /* Build an array of the items in the bracket expression. */
  while (status == REG_OK)
    {
      skip = 0;
      if (re == ctx->re_end)
	{
	  status = REG_EBRACK;
	}
      else if (*re == CHAR_RBRACKET && re > ctx->re)
	{
	  DPRINT(("tre_parse_bracket:	done: '%.*" STRF "'\n", REST(re)));
	  re++;
	  break;
	}
      else
	{
	  tre_cint_t min = 0, max = 0;

	  class = (tre_ctype_t)0;
	  if (re + 2 < ctx->re_end
	      && *(re + 1) == CHAR_MINUS && *(re + 2) != CHAR_RBRACKET)
	    {
	      DPRINT(("tre_parse_bracket:  range: '%.*" STRF "'\n", REST(re)));
	      min = *re;
	      max = *(re + 2);
	      re += 3;
	      /* XXX - Should use collation order instead of encoding values
		 in character ranges. */
	      if (min > max)
		status = REG_ERANGE;
	    }
	  else if (re + 1 < ctx->re_end
		   && *re == CHAR_LBRACKET && *(re + 1) == CHAR_PERIOD)
	    status = REG_ECOLLATE;
	  else if (re + 1 < ctx->re_end
		   && *re == CHAR_LBRACKET && *(re + 1) == CHAR_EQUAL)
	    status = REG_ECOLLATE;
	  else if (re + 1 < ctx->re_end
		   && *re == CHAR_LBRACKET && *(re + 1) == CHAR_COLON)
	    {
	      char tmp_str[64];
	      const tre_char_t *endptr = re + 2;
	      int len;
	      DPRINT(("tre_parse_bracket:  class: '%.*" STRF "'\n", REST(re)));
	      while (endptr < ctx->re_end && *endptr != CHAR_COLON)
		endptr++;
	      if (endptr != ctx->re_end)
		{
		  len = MIN(endptr - re - 2, 63);
#ifdef TRE_WCHAR
		  {
		    tre_char_t tmp_wcs[64];
		    wcsncpy(tmp_wcs, re + 2, (size_t)len);
		    tmp_wcs[len] = L'\0';
#if defined HAVE_WCSRTOMBS
		    {
		      mbstate_t state;
		      const tre_char_t *src = tmp_wcs;
		      memset(&state, '\0', sizeof(state));
		      len = wcsrtombs(tmp_str, &src, sizeof(tmp_str), &state);
		    }
#elif defined HAVE_WCSTOMBS
		    len = wcstombs(tmp_str, tmp_wcs, 63);
#endif /* defined HAVE_WCSTOMBS */
		  }
#else /* !TRE_WCHAR */
		  strncpy(tmp_str, (const char*)re + 2, len);
#endif /* !TRE_WCHAR */
		  tmp_str[len] = '\0';
		  DPRINT(("  class name: %s\n", tmp_str));
		  class = tre_ctype(tmp_str);
		  if (!class)
		    status = REG_ECTYPE;
		  /* Optimize character classes for 8 bit character sets. */
		  if (status == REG_OK && TRE_MB_CUR_MAX == 1)
		    {
		      status = tre_expand_ctype(ctx->mem, class, items,
						&i, &max_i, ctx->cflags);
		      class = (tre_ctype_t)0;
		      skip = 1;
		    }
		  re = endptr + 2;
		}
	      else
		status = REG_ECTYPE;
	      min = 0;
	      max = TRE_CHAR_MAX;
	    }
	  else
	    {
	      DPRINT(("tre_parse_bracket:   char: '%.*" STRF "'\n", REST(re)));
	      if (*re == CHAR_MINUS && *(re + 1) != CHAR_RBRACKET
		  && ctx->re != re)
		/* Two ranges are not allowed to share and endpoint. */
		status = REG_ERANGE;
	      min = max = *re++;
	    }

	  if (status != REG_OK)
	    break;

	  if (class && negate)
	    if (*num_neg_classes >= MAX_NEG_CLASSES)
	      status = REG_ESPACE;
	    else
	      neg_classes[(*num_neg_classes)++] = class;
	  else if (!skip)
	    {
	      status = tre_new_item(ctx->mem, min, max, &i, &max_i, items);
	      if (status != REG_OK)
		break;
	      ((tre_literal_t*)((*items)[i-1])->obj)->u.class = class;
	    }

	  /* Add opposite-case counterpoints if REG_ICASE is present.
	     This is broken if there are more than two "same" characters. */
	  if (ctx->cflags & REG_ICASE && !class && status == REG_OK && !skip)
	    {
	      tre_cint_t cmin, ccurr;

	      DPRINT(("adding opposite-case counterpoints\n"));
	      while (min <= max)
		{
		  if (tre_islower(min))
		    {
		      cmin = ccurr = tre_toupper(min++);
		      while (tre_islower(min) && tre_toupper(min) == ccurr + 1
			     && min <= max)
			ccurr = tre_toupper(min++);
		      status = tre_new_item(ctx->mem, cmin, ccurr,
					    &i, &max_i, items);
		    }
		  else if (tre_isupper(min))
		    {
		      cmin = ccurr = tre_tolower(min++);
		      while (tre_isupper(min) && tre_tolower(min) == ccurr + 1
			     && min <= max)
			ccurr = tre_tolower(min++);
		      status = tre_new_item(ctx->mem, cmin, ccurr,
					    &i, &max_i, items);
		    }
		  else min++;
		  if (status != REG_OK)
		    break;
		}
	      if (status != REG_OK)
		break;
	    }
	}
    }
  *num_items = i;
  *items_size = max_i;
  ctx->re = re;
  return status;
}

static reg_errcode_t
tre_parse_bracket(tre_parse_ctx_t *ctx, tre_ast_node_t **result)
{
  tre_ast_node_t *node = NULL;
  int negate = 0;
  reg_errcode_t status = REG_OK;
  tre_ast_node_t **items, *u, *n;
  int i = 0, j, max_i = 32, curr_max, curr_min;
  tre_ctype_t neg_classes[MAX_NEG_CLASSES];
  int num_neg_classes = 0;

  /* Start off with an array of `max_i' elements. */
  items = xmalloc(sizeof(*items) * max_i);
  if (items == NULL)
    return REG_ESPACE;

  if (*ctx->re == CHAR_CARET)
    {
      DPRINT(("tre_parse_bracket: negate: '%.*" STRF "'\n", REST(ctx->re)));
      negate = 1;
      ctx->re++;
    }

  status = tre_parse_bracket_items(ctx, negate, neg_classes, &num_neg_classes,
				   &items, &i, &max_i);

  if (status != REG_OK)
    goto parse_bracket_done;

  /* Sort the array if we need to negate it. */
  if (negate)
    qsort(items, (unsigned)i, sizeof(*items), tre_compare_items);

  curr_max = curr_min = 0;
  /* Build a union of the items in the array, negated if necessary. */
  for (j = 0; j < i && status == REG_OK; j++)
    {
      int min, max;
      tre_literal_t *l = items[j]->obj;
      min = l->code_min;
      max = l->code_max;

      DPRINT(("item: %d - %d, class %ld, curr_max = %d\n",
	      (int)l->code_min, (int)l->code_max, (long)l->u.class, curr_max));

      if (negate)
	{
	  if (min < curr_max)
	    {
	      /* Overlap. */
	      curr_max = MAX(max + 1, curr_max);
	      DPRINT(("overlap, curr_max = %d\n", curr_max));
	      l = NULL;
	    }
	  else
	    {
	      /* No overlap. */
	      curr_max = min - 1;
	      if (curr_max >= curr_min)
		{
		  DPRINT(("no overlap\n"));
		  l->code_min = curr_min;
		  l->code_max = curr_max;
		}
	      else
		{
		  DPRINT(("no overlap, zero room\n"));
		  l = NULL;
		}
	      curr_min = curr_max = max + 1;
	    }
	}

      if (l != NULL)
	{
	  int k;
	  DPRINT(("creating %d - %d\n", (int)l->code_min, (int)l->code_max));
	  l->position = ctx->position;
	  if (num_neg_classes > 0)
	    {
	      l->neg_classes = tre_mem_alloc(ctx->mem,
					     (sizeof(l->neg_classes)
					      * (num_neg_classes + 1)));
	      if (l->neg_classes == NULL)
		{
		  status = REG_ESPACE;
		  break;
		}
	      for (k = 0; k < num_neg_classes; k++)
		l->neg_classes[k] = neg_classes[k];
	      l->neg_classes[k] = (tre_ctype_t)0;
	    }
	  else
	    l->neg_classes = NULL;
	  if (node == NULL)
	    node = items[j];
	  else
	    {
	      u = tre_ast_new_union(ctx->mem, node, items[j]);
	      if (u == NULL)
		status = REG_ESPACE;
	      node = u;
	    }
	}
    }

  if (status != REG_OK)
    goto parse_bracket_done;

  if (negate)
    {
      int k;
      DPRINT(("final: creating %d - %d\n", curr_min, (int)TRE_CHAR_MAX));
      n = tre_ast_new_literal(ctx->mem, curr_min, TRE_CHAR_MAX, ctx->position);
      if (n == NULL)
	status = REG_ESPACE;
      else
	{
	  tre_literal_t *l = n->obj;
	  if (num_neg_classes > 0)
	    {
	      l->neg_classes = tre_mem_alloc(ctx->mem,
					     (sizeof(l->neg_classes)
					      * (num_neg_classes + 1)));
	      if (l->neg_classes == NULL)
		{
		  status = REG_ESPACE;
		  goto parse_bracket_done;
		}
	      for (k = 0; k < num_neg_classes; k++)
		l->neg_classes[k] = neg_classes[k];
	      l->neg_classes[k] = (tre_ctype_t)0;
	    }
	  else
	    l->neg_classes = NULL;
	  if (node == NULL)
	    node = n;
	  else
	    {
	      u = tre_ast_new_union(ctx->mem, node, n);
	      if (u == NULL)
		status = REG_ESPACE;
	      node = u;
	    }
	}
    }

  if (status != REG_OK)
    goto parse_bracket_done;

#ifdef TRE_DEBUG
  tre_ast_print(node);
#endif /* TRE_DEBUG */

 parse_bracket_done:
  xfree(items);
  ctx->position++;
  *result = node;
  return status;
}


/* Parses a positive decimal integer.  Returns -1 if the string does not
   contain a valid number. */
static int
tre_parse_int(const tre_char_t **regex, const tre_char_t *regex_end)
{
  int num = -1;
  const tre_char_t *r = *regex;
  while (r < regex_end && *r >= L'0' && *r <= L'9')
    {
      if (num < 0)
	num = 0;
      num = num * 10 + *r - L'0';
      r++;
    }
  *regex = r;
  return num;
}


static reg_errcode_t
tre_parse_bound(tre_parse_ctx_t *ctx, tre_ast_node_t **result)
{
  int min, max, i;
  int cost_ins, cost_del, cost_subst, cost_max;
  int limit_ins, limit_del, limit_subst, limit_err;
  const tre_char_t *r = ctx->re;
  const tre_char_t *start;
  int minimal = (ctx->cflags & REG_UNGREEDY) ? 1 : 0;
  int approx = 0;
  int costs_set = 0;
  int counts_set = 0;

  cost_ins = cost_del = cost_subst = cost_max = TRE_PARAM_UNSET;
  limit_ins = limit_del = limit_subst = limit_err = TRE_PARAM_UNSET;

  /* Parse number (minimum repetition count). */
  min = -1;
  if (r < ctx->re_end && *r >= L'0' && *r <= L'9') {
    DPRINT(("tre_parse:	  min count: '%.*" STRF "'\n", REST(r)));
    min = tre_parse_int(&r, ctx->re_end);
  }

  /* Parse comma and second number (maximum repetition count). */
  max = min;
  if (r < ctx->re_end && *r == CHAR_COMMA)
    {
      r++;
      DPRINT(("tre_parse:   max count: '%.*" STRF "'\n", REST(r)));
      max = tre_parse_int(&r, ctx->re_end);
    }

  /* Check that the repeat counts are sane. */
  if ((max >= 0 && min > max) || max > RE_DUP_MAX)
    return REG_BADBR;


  /*
   '{'
     optionally followed immediately by a number == minimum repcount
     optionally followed by , then a number == maximum repcount
      + then a number == maximum insertion count
      - then a number == maximum deletion count
      # then a number == maximum substitution count
      ~ then a number == maximum number of errors
      Any of +, -, # or ~ without followed by a number means that
      the maximum count/number of errors is infinite.

      An equation of the form
	Xi + Yd + Zs < C
      can be specified to set costs and the cost limit to a value
      different from the default value:
	- X is the cost of an insertion
	- Y is the cost of a deletion
	- Z is the cost of a substitution
	- C is the maximum cost

      If no count limit or cost is set for an operation, the operation
      is not allowed at all.
  */


  do {
    int done;
    start = r;

    /* Parse count limit settings */
    done = 0;
    if (!counts_set)
      while (r + 1 < ctx->re_end && !done)
	{
	  switch (*r)
	    {
	    case CHAR_PLUS:  /* Insert limit */
	      DPRINT(("tre_parse:   ins limit: '%.*" STRF "'\n", REST(r)));
	      r++;
	      limit_ins = tre_parse_int(&r, ctx->re_end);
	      if (limit_ins < 0)
		limit_ins = INT_MAX;
	      counts_set = 1;
	      break;
	    case CHAR_MINUS: /* Delete limit */
	      DPRINT(("tre_parse:   del limit: '%.*" STRF "'\n", REST(r)));
	      r++;
	      limit_del = tre_parse_int(&r, ctx->re_end);
	      if (limit_del < 0)
		limit_del = INT_MAX;
	      counts_set = 1;
	      break;
	    case CHAR_HASH:  /* Substitute limit */
	      DPRINT(("tre_parse: subst limit: '%.*" STRF "'\n", REST(r)));
	      r++;
	      limit_subst = tre_parse_int(&r, ctx->re_end);
	      if (limit_subst < 0)
		limit_subst = INT_MAX;
	      counts_set = 1;
	      break;
	    case CHAR_TILDE: /* Maximum number of changes */
	      DPRINT(("tre_parse: count limit: '%.*" STRF "'\n", REST(r)));
	      r++;
	      limit_err = tre_parse_int(&r, ctx->re_end);
	      if (limit_err < 0)
		limit_err = INT_MAX;
	      approx = 1;
	      break;
	    case CHAR_COMMA:
	      r++;
	      break;
	    case L' ':
	      r++;
	      break;
	    case L'}':
	      done = 1;
	      break;
	    default:
	      done = 1;
	      break;
	    }
	}

    /* Parse cost restriction equation. */
    done = 0;
    if (!costs_set)
      while (r + 1 < ctx->re_end && !done)
	{
	  switch (*r)
	    {
	    case CHAR_PLUS:
	    case L' ':
	      r++;
	      break;
	    case L'<':
	      DPRINT(("tre_parse:    max cost: '%.*" STRF "'\n", REST(r)));
	      r++;
	      while (*r == L' ')
		r++;
	      cost_max = tre_parse_int(&r, ctx->re_end);
	      if (cost_max < 0)
		cost_max = INT_MAX;
	      else
		cost_max--;
	      approx = 1;
	      break;
	    case CHAR_COMMA:
	      r++;
	      done = 1;
	      break;
	    default:
	      if (*r >= L'0' && *r <= L'9')
		{
#ifdef TRE_DEBUG
		  const tre_char_t *sr = r;
#endif /* TRE_DEBUG */
		  int cost = tre_parse_int(&r, ctx->re_end);
		  /* XXX - make sure r is not past end. */
		  switch (*r)
		    {
		    case L'i':	/* Insert cost */
		      DPRINT(("tre_parse:    ins cost: '%.*" STRF "'\n",
			      REST(sr)));
		      r++;
		      cost_ins = cost;
		      costs_set = 1;
		      break;
		    case L'd':	/* Delete cost */
		      DPRINT(("tre_parse:    del cost: '%.*" STRF "'\n",
			      REST(sr)));
		      r++;
		      cost_del = cost;
		      costs_set = 1;
		      break;
		    case L's':	/* Substitute cost */
		      DPRINT(("tre_parse:  subst cost: '%.*" STRF "'\n",
			      REST(sr)));
		      r++;
		      cost_subst = cost;
		      costs_set = 1;
		      break;
		    default:
		      return REG_BADBR;
		    }
		}
	      else
		{
		  done = 1;
		  break;
		}
	    }
	}
  } while (start != r);

  /* Missing }. */
  if (r >= ctx->re_end)
    return REG_EBRACE;

  /* Empty contents of {}. */
  if (r == ctx->re)
    return REG_BADBR;

  /* Parse the ending '}' or '\}'.*/
  if (ctx->cflags & REG_EXTENDED)
    {
      if (r >= ctx->re_end || *r != CHAR_RBRACE)
	return REG_BADBR;
      r++;
    }
  else
    {
      if (r + 1 >= ctx->re_end
	  || *r != CHAR_BACKSLASH
	  || *(r + 1) != CHAR_RBRACE)
	return REG_BADBR;
      r += 2;
    }


  /* Parse trailing '?' marking minimal repetition. */
  if (r < ctx->re_end)
    {
      if (*r == CHAR_QUESTIONMARK)
	{
	  minimal = !(ctx->cflags & REG_UNGREEDY);
	  r++;
	}
      else if (*r == CHAR_STAR || *r == CHAR_PLUS)
	{
	  /* These are reserved for future extensions. */
	  return REG_BADRPT;
	}
    }

  /* Create the AST node(s). */
  if (min == 0 && max == 0)
    {
      *result = tre_ast_new_literal(ctx->mem, EMPTY, -1, -1);
      if (*result == NULL)
	return REG_ESPACE;
    }
  else
    {
      if (min < 0 && max < 0)
	/* Only approximate parameters set, no repetitions. */
	min = max = 1;

      *result = tre_ast_new_iter(ctx->mem, *result, min, max, minimal);
      if (!*result)
	return REG_ESPACE;

      /* If approximate matching parameters are set, add them to the
	 iteration node. */
      if (approx || costs_set || counts_set)
	{
	  int *params;
	  tre_iteration_t *iter = (*result)->obj;

	  if (costs_set || counts_set)
	    {
	      if (limit_ins == TRE_PARAM_UNSET)
		{
		  if (cost_ins == TRE_PARAM_UNSET)
		    limit_ins = 0;
		  else
		    limit_ins = INT_MAX;
		}

	      if (limit_del == TRE_PARAM_UNSET)
		{
		  if (cost_del == TRE_PARAM_UNSET)
		    limit_del = 0;
		  else
		    limit_del = INT_MAX;
		}

	      if (limit_subst == TRE_PARAM_UNSET)
		{
		  if (cost_subst == TRE_PARAM_UNSET)
		    limit_subst = 0;
		  else
		    limit_subst = INT_MAX;
		}
	    }

	  if (cost_max == TRE_PARAM_UNSET)
	    cost_max = INT_MAX;
	  if (limit_err == TRE_PARAM_UNSET)
	    limit_err = INT_MAX;

	  ctx->have_approx = 1;
	  params = tre_mem_alloc(ctx->mem, sizeof(*params) * TRE_PARAM_LAST);
	  if (!params)
	    return REG_ESPACE;
	  for (i = 0; i < TRE_PARAM_LAST; i++)
	    params[i] = TRE_PARAM_UNSET;
	  params[TRE_PARAM_COST_INS] = cost_ins;
	  params[TRE_PARAM_COST_DEL] = cost_del;
	  params[TRE_PARAM_COST_SUBST] = cost_subst;
	  params[TRE_PARAM_COST_MAX] = cost_max;
	  params[TRE_PARAM_MAX_INS] = limit_ins;
	  params[TRE_PARAM_MAX_DEL] = limit_del;
	  params[TRE_PARAM_MAX_SUBST] = limit_subst;
	  params[TRE_PARAM_MAX_ERR] = limit_err;
	  iter->params = params;
	}
    }

  DPRINT(("tre_parse_bound: min %d, max %d, costs [%d,%d,%d, total %d], "
	  "limits [%d,%d,%d, total %d]\n",
	  min, max, cost_ins, cost_del, cost_subst, cost_max,
	  limit_ins, limit_del, limit_subst, limit_err));


  ctx->re = r;
  return REG_OK;
}

typedef enum {
  PARSE_RE = 0,
  PARSE_ATOM,
  PARSE_MARK_FOR_SUBMATCH,
  PARSE_BRANCH,
  PARSE_PIECE,
  PARSE_CATENATION,
  PARSE_POST_CATENATION,
  PARSE_UNION,
  PARSE_POST_UNION,
  PARSE_POSTFIX,
  PARSE_RESTORE_CFLAGS
} tre_parse_re_stack_symbol_t;


reg_errcode_t
tre_parse(tre_parse_ctx_t *ctx)
{
  tre_ast_node_t *result = NULL;
  tre_parse_re_stack_symbol_t symbol;
  reg_errcode_t status = REG_OK;
  tre_stack_t *stack = ctx->stack;
  int bottom = tre_stack_num_objects(stack);
  int depth = 0;
  int temporary_cflags = 0;

  DPRINT(("tre_parse: parsing '%.*" STRF "', len = %d\n",
	  ctx->len, ctx->re, ctx->len));

  if (!ctx->nofirstsub)
    {
      STACK_PUSH(stack, int, ctx->submatch_id);
      STACK_PUSH(stack, int, PARSE_MARK_FOR_SUBMATCH);
      ctx->submatch_id++;
    }
  STACK_PUSH(stack, int, PARSE_RE);
  ctx->re_start = ctx->re;
  ctx->re_end = ctx->re + ctx->len;


  /* The following is basically just a recursive descent parser.  I use
     an explicit stack instead of recursive functions mostly because of
     two reasons: compatibility with systems which have an overflowable
     call stack, and efficiency (both in lines of code and speed).  */
  while (tre_stack_num_objects(stack) > bottom && status == REG_OK)
    {
      if (status != REG_OK)
	break;
      symbol = tre_stack_pop_int(stack);
      switch (symbol)
	{
	case PARSE_RE:
	  /* Parse a full regexp.  A regexp is one or more branches,
	     separated by the union operator `|'. */
#ifdef REG_LITERAL
	  if (!(ctx->cflags & REG_LITERAL)
	      && ctx->cflags & REG_EXTENDED)
#endif /* REG_LITERAL */
	    STACK_PUSHX(stack, int, PARSE_UNION);
	  STACK_PUSHX(stack, int, PARSE_BRANCH);
	  break;

	case PARSE_BRANCH:
	  /* Parse a branch.  A branch is one or more pieces, concatenated.
	     A piece is an atom possibly followed by a postfix operator. */
	  STACK_PUSHX(stack, int, PARSE_CATENATION);
	  STACK_PUSHX(stack, int, PARSE_PIECE);
	  break;

	case PARSE_PIECE:
	  /* Parse a piece.  A piece is an atom possibly followed by one
	     or more postfix operators. */
#ifdef REG_LITERAL
	  if (!(ctx->cflags & REG_LITERAL))
#endif /* REG_LITERAL */
	    STACK_PUSHX(stack, int, PARSE_POSTFIX);
	  STACK_PUSHX(stack, int, PARSE_ATOM);
	  break;

	case PARSE_CATENATION:
	  /* If the expression has not ended, parse another piece. */
	  {
	    tre_char_t c;
	    if (ctx->re >= ctx->re_end)
	      break;
	    c = *ctx->re;
#ifdef REG_LITERAL
	    if (!(ctx->cflags & REG_LITERAL))
	      {
#endif /* REG_LITERAL */
		if (ctx->cflags & REG_EXTENDED && c == CHAR_PIPE)
		  break;
		if ((ctx->cflags & REG_EXTENDED
		     && c == CHAR_RPAREN && depth > 0)
		    || (!(ctx->cflags & REG_EXTENDED)
			&& (c == CHAR_BACKSLASH
			    && *(ctx->re + 1) == CHAR_RPAREN)))
		  {
		    if (!(ctx->cflags & REG_EXTENDED) && depth == 0)
		      status = REG_EPAREN;
		    DPRINT(("tre_parse:	  group end: '%.*" STRF "'\n",
			    REST(ctx->re)));
		    depth--;
		    if (!(ctx->cflags & REG_EXTENDED))
		      ctx->re += 2;
		    break;
		  }
#ifdef REG_LITERAL
	      }
#endif /* REG_LITERAL */

#ifdef REG_RIGHT_ASSOC
	    if (ctx->cflags & REG_RIGHT_ASSOC)
	      {
		/* Right associative concatenation. */
		STACK_PUSHX(stack, voidptr, result);
		STACK_PUSHX(stack, int, PARSE_POST_CATENATION);
		STACK_PUSHX(stack, int, PARSE_CATENATION);
		STACK_PUSHX(stack, int, PARSE_PIECE);
	      }
	    else
#endif /* REG_RIGHT_ASSOC */
	      {
		/* Default case, left associative concatenation. */
		STACK_PUSHX(stack, int, PARSE_CATENATION);
		STACK_PUSHX(stack, voidptr, result);
		STACK_PUSHX(stack, int, PARSE_POST_CATENATION);
		STACK_PUSHX(stack, int, PARSE_PIECE);
	      }
	    break;
	  }

	case PARSE_POST_CATENATION:
	  {
	    tre_ast_node_t *tree = tre_stack_pop_voidptr(stack);
	    tre_ast_node_t *tmp_node;
	    tmp_node = tre_ast_new_catenation(ctx->mem, tree, result);
	    if (!tmp_node)
	      return REG_ESPACE;
	    result = tmp_node;
	    break;
	  }

	case PARSE_UNION:
	  if (ctx->re >= ctx->re_end)
	    break;
#ifdef REG_LITERAL
	  if (ctx->cflags & REG_LITERAL)
	    break;
#endif /* REG_LITERAL */
	  switch (*ctx->re)
	    {
	    case CHAR_PIPE:
	      DPRINT(("tre_parse:	union: '%.*" STRF "'\n",
		      REST(ctx->re)));
	      STACK_PUSHX(stack, int, PARSE_UNION);
	      STACK_PUSHX(stack, voidptr, result);
	      STACK_PUSHX(stack, int, PARSE_POST_UNION);
	      STACK_PUSHX(stack, int, PARSE_BRANCH);
	      ctx->re++;
	      break;

	    case CHAR_RPAREN:
	      ctx->re++;
	      break;

	    default:
	      break;
	    }
	  break;

	case PARSE_POST_UNION:
	  {
	    tre_ast_node_t *tmp_node;
	    tre_ast_node_t *tree = tre_stack_pop_voidptr(stack);
	    tmp_node = tre_ast_new_union(ctx->mem, tree, result);
	    if (!tmp_node)
	      return REG_ESPACE;
	    result = tmp_node;
	    break;
	  }

	case PARSE_POSTFIX:
	  /* Parse postfix operators. */
	  if (ctx->re >= ctx->re_end)
	    break;
#ifdef REG_LITERAL
	  if (ctx->cflags & REG_LITERAL)
	    break;
#endif /* REG_LITERAL */
	  switch (*ctx->re)
	    {
	    case CHAR_PLUS:
	    case CHAR_QUESTIONMARK:
	      if (!(ctx->cflags & REG_EXTENDED))
		break;
		/*FALLTHROUGH*/
	    case CHAR_STAR:
	      {
		tre_ast_node_t *tmp_node;
		int minimal = (ctx->cflags & REG_UNGREEDY) ? 1 : 0;
		int rep_min = 0;
		int rep_max = -1;
#ifdef TRE_DEBUG
		const tre_char_t *tmp_re;
#endif

		if (*ctx->re == CHAR_PLUS)
		  rep_min = 1;
		if (*ctx->re == CHAR_QUESTIONMARK)
		  rep_max = 1;
#ifdef TRE_DEBUG
		tmp_re = ctx->re;
#endif

		if (ctx->re + 1 < ctx->re_end)
		  {
		    if (*(ctx->re + 1) == CHAR_QUESTIONMARK)
		      {
			minimal = !(ctx->cflags & REG_UNGREEDY);
			ctx->re++;
		      }
		    else if (*(ctx->re + 1) == CHAR_STAR
			     || *(ctx->re + 1) == CHAR_PLUS)
		      {
			/* These are reserved for future extensions. */
			return REG_BADRPT;
		      }
		  }

		DPRINT(("tre_parse: %s star: '%.*" STRF "'\n",
			minimal ? "  minimal" : "greedy", REST(tmp_re)));
		ctx->re++;
		tmp_node = tre_ast_new_iter(ctx->mem, result, rep_min, rep_max,
					    minimal);
		if (tmp_node == NULL)
		  return REG_ESPACE;
		result = tmp_node;
		STACK_PUSHX(stack, int, PARSE_POSTFIX);
	      }
	      break;

	    case CHAR_BACKSLASH:
	      /* "\{" is special without REG_EXTENDED */
	      if (!(ctx->cflags & REG_EXTENDED)
		  && ctx->re + 1 < ctx->re_end
		  && *(ctx->re + 1) == CHAR_LBRACE)
		{
		  ctx->re++;
		  goto parse_brace;
		}
	      else
		break;

	    case CHAR_LBRACE:
	      /* "{" is literal without REG_EXTENDED */
	      if (!(ctx->cflags & REG_EXTENDED))
		break;

	    parse_brace:
	      DPRINT(("tre_parse:	bound: '%.*" STRF "'\n",
		      REST(ctx->re)));
	      ctx->re++;

	      status = tre_parse_bound(ctx, &result);
	      if (status != REG_OK)
		return status;
	      STACK_PUSHX(stack, int, PARSE_POSTFIX);
	      break;
	    }
	  break;

	case PARSE_ATOM:
	  /* Parse an atom.  An atom is a regular expression enclosed in `()',
	     an empty set of `()', a bracket expression, `.', `^', `$',
	     a `\' followed by a character, or a single character. */

	  /* End of regexp? (empty string). */
	  if (ctx->re >= ctx->re_end)
	    goto parse_literal;

#ifdef REG_LITERAL
	  if (ctx->cflags & REG_LITERAL)
	    goto parse_literal;
#endif /* REG_LITERAL */

	  switch (*ctx->re)
	    {
	    case CHAR_LPAREN:  /* parenthesized subexpression */

	      /* Handle "(?...)" extensions.  They work in a way similar
		 to Perls corresponding extensions. */
	      if (ctx->cflags & REG_EXTENDED
		  && *(ctx->re + 1) == CHAR_QUESTIONMARK)
		{
		  int new_cflags = ctx->cflags;
		  int bit = 1;
		  DPRINT(("tre_parse:	extension: '%.*" STRF "\n",
			  REST(ctx->re)));
		  ctx->re += 2;
		  while (/*CONSTCOND*/1)
		    {
		      if (*ctx->re == L'i')
			{
			  DPRINT(("tre_parse:	    icase: '%.*" STRF "\n",
				  REST(ctx->re)));
			  if (bit)
			    new_cflags |= REG_ICASE;
			  else
			    new_cflags &= ~REG_ICASE;
			  ctx->re++;
			}
		      else if (*ctx->re == L'n')
			{
			  DPRINT(("tre_parse:	  newline: '%.*" STRF "\n",
				  REST(ctx->re)));
			  if (bit)
			    new_cflags |= REG_NEWLINE;
			  else
			    new_cflags &= ~REG_NEWLINE;
			  ctx->re++;
			}
#ifdef REG_RIGHT_ASSOC
		      else if (*ctx->re == L'r')
			{
			  DPRINT(("tre_parse: right assoc: '%.*" STRF "\n",
				  REST(ctx->re)));
			  if (bit)
			    new_cflags |= REG_RIGHT_ASSOC;
			  else
			    new_cflags &= ~REG_RIGHT_ASSOC;
			  ctx->re++;
			}
#endif /* REG_RIGHT_ASSOC */
#ifdef REG_UNGREEDY
		      else if (*ctx->re == L'U')
			{
			  DPRINT(("tre_parse:    ungreedy: '%.*" STRF "\n",
				  REST(ctx->re)));
			  if (bit)
			    new_cflags |= REG_UNGREEDY;
			  else
			    new_cflags &= ~REG_UNGREEDY;
			  ctx->re++;
			}
#endif /* REG_UNGREEDY */
		      else if (*ctx->re == CHAR_MINUS)
			{
			  DPRINT(("tre_parse:	 turn off: '%.*" STRF "\n",
				  REST(ctx->re)));
			  ctx->re++;
			  bit = 0;
			}
		      else if (*ctx->re == CHAR_COLON)
			{
			  DPRINT(("tre_parse:	 no group: '%.*" STRF "\n",
				  REST(ctx->re)));
			  ctx->re++;
			  depth++;
			  break;
			}
		      else if (*ctx->re == CHAR_HASH)
			{
			  DPRINT(("tre_parse:    comment: '%.*" STRF "\n",
				  REST(ctx->re)));
			  /* A comment can contain any character except a
			     right parenthesis */
			  while (*ctx->re != CHAR_RPAREN
				 && ctx->re < ctx->re_end)
			    ctx->re++;
			  if (*ctx->re == CHAR_RPAREN && ctx->re < ctx->re_end)
			    {
			      ctx->re++;
			      break;
			    }
			  else
			    return REG_BADPAT;
			}
		      else if (*ctx->re == CHAR_RPAREN)
			{
			  ctx->re++;
			  break;
			}
		      else
			return REG_BADPAT;
		    }

		  /* Turn on the cflags changes for the rest of the
		     enclosing group. */
		  STACK_PUSHX(stack, int, ctx->cflags);
		  STACK_PUSHX(stack, int, PARSE_RESTORE_CFLAGS);
		  STACK_PUSHX(stack, int, PARSE_RE);
		  ctx->cflags = new_cflags;
		  break;
		}

	      if (ctx->cflags & REG_EXTENDED
		  || (ctx->re > ctx->re_start
		      && *(ctx->re - 1) == CHAR_BACKSLASH))
		{
		  depth++;
		  if (ctx->re + 2 < ctx->re_end
		      && *(ctx->re + 1) == CHAR_QUESTIONMARK
		      && *(ctx->re + 2) == CHAR_COLON)
		    {
		      DPRINT(("tre_parse: group begin: '%.*" STRF
			      "', no submatch\n", REST(ctx->re)));
		      /* Don't mark for submatching. */
		      ctx->re += 3;
		      STACK_PUSHX(stack, int, PARSE_RE);
		    }
		  else
		    {
		      DPRINT(("tre_parse: group begin: '%.*" STRF
			      "', submatch %d\n", REST(ctx->re),
			      ctx->submatch_id));
		      ctx->re++;
		      /* First parse a whole RE, then mark the resulting tree
			 for submatching. */
		      STACK_PUSHX(stack, int, ctx->submatch_id);
		      STACK_PUSHX(stack, int, PARSE_MARK_FOR_SUBMATCH);
		      STACK_PUSHX(stack, int, PARSE_RE);
		      ctx->submatch_id++;
		    }
		}
	      else
		goto parse_literal;
	      break;

	    case CHAR_RPAREN:  /* end of current subexpression */
	      if ((ctx->cflags & REG_EXTENDED && depth > 0)
		  || (ctx->re > ctx->re_start
		      && *(ctx->re - 1) == CHAR_BACKSLASH))
		{
		  DPRINT(("tre_parse:	    empty: '%.*" STRF "'\n",
			  REST(ctx->re)));
		  /* We were expecting an atom, but instead the current
		     subexpression was closed.	POSIX leaves the meaning of
		     this to be implementation-defined.	 We interpret this as
		     an empty expression (which matches an empty string).  */
		  result = tre_ast_new_literal(ctx->mem, EMPTY, -1, -1);
		  if (result == NULL)
		    return REG_ESPACE;
		  if (!(ctx->cflags & REG_EXTENDED))
		    ctx->re--;
		}
	      else
		goto parse_literal;
	      break;

	    case CHAR_LBRACKET: /* bracket expression */
	      DPRINT(("tre_parse:     bracket: '%.*" STRF "'\n",
		      REST(ctx->re)));
	      ctx->re++;
	      status = tre_parse_bracket(ctx, &result);
	      if (status != REG_OK)
		return status;
	      break;

	    case CHAR_BACKSLASH:
	      /* If this is "\(" or "\)" chew off the backslash and
		 try again. */
	      if (!(ctx->cflags & REG_EXTENDED)
		  && ctx->re + 1 < ctx->re_end
		  && (*(ctx->re + 1) == CHAR_LPAREN
		      || *(ctx->re + 1) == CHAR_RPAREN))
		{
		  ctx->re++;
		  STACK_PUSHX(stack, int, PARSE_ATOM);
		  break;
		}

	      /* If a macro is used, parse the expanded macro recursively. */
	      {
		tre_char_t buf[64];
		tre_expand_macro(ctx->re + 1, ctx->re_end,
				 buf, elementsof(buf));
		if (buf[0] != 0)
		  {
		    tre_parse_ctx_t subctx;
		    memcpy(&subctx, ctx, sizeof(subctx));
		    subctx.re = buf;
		    subctx.len = tre_strlen(buf);
		    subctx.nofirstsub = 1;
		    status = tre_parse(&subctx);
		    if (status != REG_OK)
		      return status;
		    ctx->re += 2;
		    ctx->position = subctx.position;
		    result = subctx.result;
		    break;
		  }
	      }

	      if (ctx->re + 1 >= ctx->re_end)
		/* Trailing backslash. */
		return REG_EESCAPE;

#ifdef REG_LITERAL
	      if (*(ctx->re + 1) == L'Q')
		{
		  DPRINT(("tre_parse: tmp literal: '%.*" STRF "'\n",
			  REST(ctx->re)));
		  ctx->cflags |= REG_LITERAL;
		  temporary_cflags |= REG_LITERAL;
		  ctx->re += 2;
		  STACK_PUSHX(stack, int, PARSE_ATOM);
		  break;
		}
#endif /* REG_LITERAL */

	      DPRINT(("tre_parse:  bleep: '%.*" STRF "'\n", REST(ctx->re)));
	      ctx->re++;
	      switch (*ctx->re)
		{
		case L'b':
		  result = tre_ast_new_literal(ctx->mem, ASSERTION,
					       ASSERT_AT_WB, -1);
		  ctx->re++;
		  break;
		case L'B':
		  result = tre_ast_new_literal(ctx->mem, ASSERTION,
					       ASSERT_AT_WB_NEG, -1);
		  ctx->re++;
		  break;
		case L'<':
		  result = tre_ast_new_literal(ctx->mem, ASSERTION,
					       ASSERT_AT_BOW, -1);
		  ctx->re++;
		  break;
		case L'>':
		  result = tre_ast_new_literal(ctx->mem, ASSERTION,
					       ASSERT_AT_EOW, -1);
		  ctx->re++;
		  break;
		case L'x':
		  ctx->re++;
		  if (ctx->re[0] != CHAR_LBRACE && ctx->re < ctx->re_end)
		    {
		      /* 8 bit hex char. */
		      char tmp[3] = {0, 0, 0};
		      long val;
		      DPRINT(("tre_parse:  8 bit hex: '%.*" STRF "'\n",
			      REST(ctx->re - 2)));

		      if (tre_isxdigit(ctx->re[0]) && ctx->re < ctx->re_end)
			{
			  tmp[0] = (char)ctx->re[0];
			  ctx->re++;
			}
		      if (tre_isxdigit(ctx->re[0]) && ctx->re < ctx->re_end)
			{
			  tmp[1] = (char)ctx->re[0];
			  ctx->re++;
			}
		      val = strtol(tmp, NULL, 16);
		      result = tre_ast_new_literal(ctx->mem, (int)val,
						   (int)val, ctx->position);
		      ctx->position++;
		      break;
		    }
		  else if (ctx->re < ctx->re_end)
		    {
		      /* Wide char. */
		      char tmp[32];
		      long val;
		      int i = 0;
		      ctx->re++;
		      while (ctx->re_end - ctx->re >= 0)
			{
			  if (ctx->re[0] == CHAR_RBRACE)
			    break;
			  if (tre_isxdigit(ctx->re[0]))
			    {
			      tmp[i] = (char)ctx->re[0];
			      i++;
			      ctx->re++;
			      continue;
			    }
			  return REG_EBRACE;
			}
		      ctx->re++;
		      tmp[i] = 0;
		      val = strtol(tmp, NULL, 16);
		      result = tre_ast_new_literal(ctx->mem, (int)val, (int)val,
						   ctx->position);
		      ctx->position++;
		      break;
		    }
		  /*FALLTHROUGH*/

		default:
		  if (tre_isdigit(*ctx->re))
		    {
		      /* Back reference. */
		      int val = *ctx->re - L'0';
		      DPRINT(("tre_parse:     backref: '%.*" STRF "'\n",
			      REST(ctx->re - 1)));
		      result = tre_ast_new_literal(ctx->mem, BACKREF, val,
						   ctx->position);
		      if (result == NULL)
			return REG_ESPACE;
		      ctx->position++;
		      ctx->max_backref = MAX(val, ctx->max_backref);
		      ctx->re++;
		    }
		  else
		    {
		      /* Escaped character. */
		      DPRINT(("tre_parse:     escaped: '%.*" STRF "'\n",
			      REST(ctx->re - 1)));
		      result = tre_ast_new_literal(ctx->mem, *ctx->re, *ctx->re,
						   ctx->position);
		      ctx->position++;
		      ctx->re++;
		    }
		  break;
		}
	      if (result == NULL)
		return REG_ESPACE;
	      break;

	    case CHAR_PERIOD:	 /* the any-symbol */
	      DPRINT(("tre_parse:	  any: '%.*" STRF "'\n",
		      REST(ctx->re)));
	      if (ctx->cflags & REG_NEWLINE)
		{
		  tre_ast_node_t *tmp1;
		  tre_ast_node_t *tmp2;
		  tmp1 = tre_ast_new_literal(ctx->mem, 0, L'\n' - 1,
					     ctx->position);
		  if (!tmp1)
		    return REG_ESPACE;
		  tmp2 = tre_ast_new_literal(ctx->mem, L'\n' + 1, TRE_CHAR_MAX,
					     ctx->position + 1);
		  if (!tmp2)
		    return REG_ESPACE;
		  result = tre_ast_new_union(ctx->mem, tmp1, tmp2);
		  if (!result)
		    return REG_ESPACE;
		  ctx->position += 2;
		}
	      else
		{
		  result = tre_ast_new_literal(ctx->mem, 0, TRE_CHAR_MAX,
					       ctx->position);
		  if (!result)
		    return REG_ESPACE;
		  ctx->position++;
		}
	      ctx->re++;
	      break;

	    case CHAR_CARET:	 /* beginning of line assertion */
	      /* '^' has a special meaning everywhere in EREs, and in the
		 beginning of the RE and after \( is BREs. */
	      if (ctx->cflags & REG_EXTENDED
		  || (ctx->re - 2 >= ctx->re_start
		      && *(ctx->re - 2) == CHAR_BACKSLASH
		      && *(ctx->re - 1) == CHAR_LPAREN)
		  || ctx->re == ctx->re_start)
		{
		  DPRINT(("tre_parse:	      BOL: '%.*" STRF "'\n",
			  REST(ctx->re)));
		  result = tre_ast_new_literal(ctx->mem, ASSERTION,
					       ASSERT_AT_BOL, -1);
		  if (result == NULL)
		    return REG_ESPACE;
		  ctx->re++;
		}
	      else
		goto parse_literal;
	      break;

	    case CHAR_DOLLAR:	 /* end of line assertion. */
	      /* '$' is special everywhere in EREs, and in the end of the
		 string and before \) is BREs. */
	      if (ctx->cflags & REG_EXTENDED
		  || (ctx->re + 2 < ctx->re_end
		      && *(ctx->re + 1) == CHAR_BACKSLASH
		      && *(ctx->re + 2) == CHAR_RPAREN)
		  || ctx->re + 1 == ctx->re_end)
		{
		  DPRINT(("tre_parse:	      EOL: '%.*" STRF "'\n",
			  REST(ctx->re)));
		  result = tre_ast_new_literal(ctx->mem, ASSERTION,
					       ASSERT_AT_EOL, -1);
		  if (result == NULL)
		    return REG_ESPACE;
		  ctx->re++;
		}
	      else
		goto parse_literal;
	      break;

	    default:
	    parse_literal:

	      if (temporary_cflags && ctx->re + 1 < ctx->re_end
		  && *ctx->re == CHAR_BACKSLASH && *(ctx->re + 1) == L'E')
		{
		  DPRINT(("tre_parse:	 end tmps: '%.*" STRF "'\n",
			  REST(ctx->re)));
		  ctx->cflags &= ~temporary_cflags;
		  temporary_cflags = 0;
		  ctx->re += 2;
		  STACK_PUSHX(stack, int, PARSE_PIECE);
		  break;
		}


	      /* We are expecting an atom.  If the subexpression (or the whole
		 regexp ends here, we interpret it as an empty expression
		 (which matches an empty string).  */
	      if (
#ifdef REG_LITERAL
		  !(ctx->cflags & REG_LITERAL) &&
#endif /* REG_LITERAL */
		  (ctx->re >= ctx->re_end
		   || *ctx->re == CHAR_STAR
		   || (ctx->cflags & REG_EXTENDED
		       && (*ctx->re == CHAR_PIPE
			   || *ctx->re == CHAR_LBRACE
			   || *ctx->re == CHAR_PLUS
			   || *ctx->re == CHAR_QUESTIONMARK))
		   /* Test for "\)" in BRE mode. */
		   || (!(ctx->cflags & REG_EXTENDED)
		       && ctx->re + 1 < ctx->re_end
		       && *ctx->re == CHAR_BACKSLASH
		       && *(ctx->re + 1) == CHAR_LBRACE)))
		{
		  DPRINT(("tre_parse:	    empty: '%.*" STRF "'\n",
			  REST(ctx->re)));
		  result = tre_ast_new_literal(ctx->mem, EMPTY, -1, -1);
		  if (!result)
		    return REG_ESPACE;
		  break;
		}

	      DPRINT(("tre_parse:     literal: '%.*" STRF "'\n",
		      REST(ctx->re)));
	      /* Note that we can't use an tre_isalpha() test here, since there
		 may be characters which are alphabetic but neither upper or
		 lower case. */
	      if (ctx->cflags & REG_ICASE
		  && (tre_isupper(*ctx->re) || tre_islower(*ctx->re)))
		{
		  tre_ast_node_t *tmp1;
		  tre_ast_node_t *tmp2;

		  /* XXX - Can there be more than one opposite-case
		     counterpoints for some character in some locale?  Or
		     more than two characters which all should be regarded
		     the same character if case is ignored?  If yes, there
		     does not seem to be a portable way to detect it.  I guess
		     that at least for multi-character collating elements there
		     could be several opposite-case counterpoints, but they
		     cannot be supported portably anyway. */
		  tmp1 = tre_ast_new_literal(ctx->mem, tre_toupper(*ctx->re),
					     tre_toupper(*ctx->re),
					     ctx->position);
		  if (!tmp1)
		    return REG_ESPACE;
		  tmp2 = tre_ast_new_literal(ctx->mem, tre_tolower(*ctx->re),
					     tre_tolower(*ctx->re),
					     ctx->position);
		  if (!tmp2)
		    return REG_ESPACE;
		  result = tre_ast_new_union(ctx->mem, tmp1, tmp2);
		  if (!result)
		    return REG_ESPACE;
		}
	      else
		{
		  result = tre_ast_new_literal(ctx->mem, *ctx->re, *ctx->re,
					       ctx->position);
		  if (!result)
		    return REG_ESPACE;
		}
	      ctx->position++;
	      ctx->re++;
	      break;
	    }
	  break;

	case PARSE_MARK_FOR_SUBMATCH:
	  {
	    int submatch_id = tre_stack_pop_int(stack);

	    if (result->submatch_id >= 0)
	      {
		tre_ast_node_t *n, *tmp_node;
		n = tre_ast_new_literal(ctx->mem, EMPTY, -1, -1);
		if (n == NULL)
		  return REG_ESPACE;
		tmp_node = tre_ast_new_catenation(ctx->mem, n, result);
		if (tmp_node == NULL)
		  return REG_ESPACE;
		tmp_node->num_submatches = result->num_submatches;
		result = tmp_node;
	      }
	    result->submatch_id = submatch_id;
	    result->num_submatches++;
	    break;
	  }

	case PARSE_RESTORE_CFLAGS:
	  ctx->cflags = tre_stack_pop_int(stack);
	  break;

	default:
	  assert(0);
	  break;
	}
    }

  /* Check for missing closing parentheses. */
  if (depth > 0)
    return REG_EPAREN;

  if (status == REG_OK)
    ctx->result = result;

  return status;
}

/* EOF */
/*
  tre-stack.c - Simple stack implementation

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */
#include <stdlib.h>
#include <assert.h>


union tre_stack_item {
  void *voidptr_value;
  int int_value;
};

struct tre_stack_rec {
  int size;
  int max_size;
  int increment;
  int ptr;
  union tre_stack_item *stack;
};


tre_stack_t *
tre_stack_new(int size, int max_size, int increment)
{
  tre_stack_t *s;

  s = xmalloc(sizeof(*s));
  if (s != NULL)
    {
      s->stack = xmalloc(sizeof(*s->stack) * size);
      if (s->stack == NULL)
	{
	  xfree(s);
	  return NULL;
	}
      s->size = size;
      s->max_size = max_size;
      s->increment = increment;
      s->ptr = 0;
    }
  return s;
}

void
tre_stack_destroy(tre_stack_t *s)
{
  xfree(s->stack);
  xfree(s);
}

int
tre_stack_num_objects(tre_stack_t *s)
{
  return s->ptr;
}

static reg_errcode_t
tre_stack_push(tre_stack_t *s, union tre_stack_item value)
{
  if (s->ptr < s->size)
    {
      s->stack[s->ptr] = value;
      s->ptr++;
    }
  else
    {
      if (s->size >= s->max_size)
	{
	  DPRINT(("tre_stack_push: stack full\n"));
	  return REG_ESPACE;
	}
      else
	{
	  union tre_stack_item *new_buffer;
	  int new_size;
	  DPRINT(("tre_stack_push: trying to realloc more space\n"));
	  new_size = s->size + s->increment;
	  if (new_size > s->max_size)
	    new_size = s->max_size;
	  new_buffer = xrealloc(s->stack, sizeof(*new_buffer) * new_size);
	  if (new_buffer == NULL)
	    {
	      DPRINT(("tre_stack_push: realloc failed.\n"));
	      return REG_ESPACE;
	    }
	  DPRINT(("tre_stack_push: realloc succeeded.\n"));
	  assert(new_size > s->size);
	  s->size = new_size;
	  s->stack = new_buffer;
	  tre_stack_push(s, value);
	}
    }
  return REG_OK;
}

#define define_pushf(typetag, type)  \
  declare_pushf(typetag, type) {     \
    union tre_stack_item item;	     \
    item.typetag ## _value = value;  \
    return tre_stack_push(s, item);  \
}

define_pushf(int, int)
define_pushf(voidptr, void *)

#define define_popf(typetag, type)		    \
  declare_popf(typetag, type) {			    \
    return s->stack[--s->ptr].typetag ## _value;    \
  }

define_popf(int, int)
define_popf(voidptr, void *)

/* EOF */
/*
  xmalloc.c - Simple malloc debugging library implementation

  This software is released under a BSD-style license.
  See the file LICENSE for details and copyright.

*/

/*
  TODO:
   - red zones
   - group dumps by source location
*/

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */

#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#define XMALLOC_INTERNAL 1


/*
  Internal stuff.
*/

typedef struct hashTableItemRec {
  void *ptr;
  int bytes;
  const char *file;
  int line;
  const char *func;
  struct hashTableItemRec *next;
} hashTableItem;

typedef struct {
  hashTableItem **table;
} hashTable;

static int xmalloc_peak;
int xmalloc_current;
static int xmalloc_peak_blocks;
int xmalloc_current_blocks;
static int xmalloc_fail_after;

#define TABLE_BITS 8
#define TABLE_MASK ((1 << TABLE_BITS) - 1)
#define TABLE_SIZE (1 << TABLE_BITS)

static hashTable *
hash_table_new(void)
{
  hashTable *tbl;

  tbl = malloc(sizeof(*tbl));

  if (tbl != NULL)
    {
      tbl->table = calloc(TABLE_SIZE, sizeof(*tbl->table));

      if (tbl->table == NULL)
	{
	  free(tbl);
	  return NULL;
	}
    }

  return tbl;
}

static int
hash_void_ptr(void *ptr)
{
  int hash;
  int i;

  /* I took this hash function just off the top of my head, I have
     no idea whether it is bad or very bad. */
  hash = 0;
  for (i = 0; i < (int)sizeof(ptr)*8 / TABLE_BITS; i++)
    {
      hash ^= (unsigned long)ptr >> i*8;
      hash += i * 17;
      hash &= TABLE_MASK;
    }
  return hash;
}

static void
hash_table_add(hashTable *tbl, void *ptr, int bytes,
	       const char *file, int line, const char *func)
{
  int i;
  hashTableItem *item, *new;

  i = hash_void_ptr(ptr);

  item = tbl->table[i];
  if (item != NULL)
    while (item->next != NULL)
      item = item->next;

  new = malloc(sizeof(*new));
  assert(new != NULL);
  new->ptr = ptr;
  new->bytes = bytes;
  new->file = file;
  new->line = line;
  new->func = func;
  new->next = NULL;
  if (item != NULL)
    item->next = new;
  else
    tbl->table[i] = new;

  xmalloc_current += bytes;
  if (xmalloc_current > xmalloc_peak)
    xmalloc_peak = xmalloc_current;
  xmalloc_current_blocks++;
  if (xmalloc_current_blocks > xmalloc_peak_blocks)
    xmalloc_peak_blocks = xmalloc_current_blocks;
}

static void
hash_table_del(hashTable *tbl, void *ptr)
{
  int i;
  hashTableItem *item, *prev;

  i = hash_void_ptr(ptr);

  item = tbl->table[i];
  if (item == NULL)
    {
      printf("xfree: invalid ptr %p\n", ptr);
      abort();
    }
  prev = NULL;
  while (item->ptr != ptr)
    {
      prev = item;
      item = item->next;
    }
  if (item->ptr != ptr)
    {
      printf("xfree: invalid ptr %p\n", ptr);
      abort();
    }

  xmalloc_current -= item->bytes;
  xmalloc_current_blocks--;

  if (prev != NULL)
    {
      prev->next = item->next;
      free(item);
    }
  else
    {
      tbl->table[i] = item->next;
      free(item);
    }
}

static hashTable *xmalloc_table = NULL;

static void
xmalloc_init(void)
{
  if (xmalloc_table == NULL)
    {
      xmalloc_table = hash_table_new();
      xmalloc_peak = 0;
      xmalloc_peak_blocks = 0;
      xmalloc_current = 0;
      xmalloc_current_blocks = 0;
      xmalloc_fail_after = -1;
    }
  assert(xmalloc_table != NULL);
  assert(xmalloc_table->table != NULL);
}



/*
  Public API.
*/

void
xmalloc_configure(int fail_after)
{
  xmalloc_init();
  xmalloc_fail_after = fail_after;
}

int
xmalloc_dump_leaks(void)
{
  int i;
  int num_leaks = 0;
  int leaked_bytes = 0;
  hashTableItem *item;

  xmalloc_init();

  for (i = 0; i < TABLE_SIZE; i++)
    {
      item = xmalloc_table->table[i];
      while (item != NULL)
	{
	  printf("%s:%d: %s: %d bytes at %p not freed\n",
		 item->file, item->line, item->func, item->bytes, item->ptr);
	  num_leaks++;
	  leaked_bytes += item->bytes;
	  item = item->next;
	}
    }
  if (num_leaks == 0)
    printf("No memory leaks.\n");
  else
    printf("%d unfreed memory chuncks, total %d unfreed bytes.\n",
	   num_leaks, leaked_bytes);
  printf("Peak memory consumption %d bytes (%.1f kB, %.1f MB) in %d blocks ",
	 xmalloc_peak, (double)xmalloc_peak / 1024,
	 (double)xmalloc_peak / (1024*1024), xmalloc_peak_blocks);
  printf("(average ");
  if (xmalloc_peak_blocks)
    printf("%d", ((xmalloc_peak + xmalloc_peak_blocks / 2)
		  / xmalloc_peak_blocks));
  else
    printf("N/A");
  printf(" bytes per block).\n");

  return num_leaks;
}

void *
xmalloc_impl(size_t size, const char *file, int line, const char *func)
{
  void *ptr;

  xmalloc_init();
  assert(size > 0);

  if (xmalloc_fail_after == 0)
    {
      xmalloc_fail_after = -2;
#if 0
      printf("xmalloc: forced failure %s:%d: %s\n", file, line, func);
#endif
      return NULL;
    }
  else if (xmalloc_fail_after == -2)
    {
      printf("xmalloc: called after failure from %s:%d: %s\n",
	     file, line, func);
      assert(0);
    }
  else if (xmalloc_fail_after > 0)
    xmalloc_fail_after--;

  ptr = malloc(size);
  if (ptr != NULL)
    hash_table_add(xmalloc_table, ptr, (int)size, file, line, func);
  return ptr;
}

void *
xcalloc_impl(size_t nmemb, size_t size, const char *file, int line,
	     const char *func)
{
  void *ptr;

  xmalloc_init();
  assert(size > 0);

  if (xmalloc_fail_after == 0)
    {
      xmalloc_fail_after = -2;
#if 0
      printf("xcalloc: forced failure %s:%d: %s\n", file, line, func);
#endif
      return NULL;
    }
  else if (xmalloc_fail_after == -2)
    {
      printf("xcalloc: called after failure from %s:%d: %s\n",
	     file, line, func);
      assert(0);
    }
  else if (xmalloc_fail_after > 0)
    xmalloc_fail_after--;

  ptr = calloc(nmemb, size);
  if (ptr != NULL)
    hash_table_add(xmalloc_table, ptr, (int)(nmemb * size), file, line, func);
  return ptr;
}

void
xfree_impl(void *ptr, const char *file, int line, const char *func)
{
  /*LINTED*/(void)&file;
  /*LINTED*/(void)&line;
  /*LINTED*/(void)&func;
  xmalloc_init();

  if (ptr != NULL)
    hash_table_del(xmalloc_table, ptr);
  free(ptr);
}

void *
xrealloc_impl(void *ptr, size_t new_size, const char *file, int line,
	      const char *func)
{
  void *new_ptr;

  xmalloc_init();
  assert(ptr != NULL);
  assert(new_size > 0);

  if (xmalloc_fail_after == 0)
    {
      xmalloc_fail_after = -2;
      return NULL;
    }
  else if (xmalloc_fail_after == -2)
    {
      printf("xrealloc: called after failure from %s:%d: %s\n",
	     file, line, func);
      assert(0);
    }
  else if (xmalloc_fail_after > 0)
    xmalloc_fail_after--;

  new_ptr = realloc(ptr, new_size);
  if (new_ptr != NULL)
    {
      hash_table_del(xmalloc_table, ptr);
      hash_table_add(xmalloc_table, new_ptr, (int)new_size, file, line, func);
    }
  return new_ptr;
}



/* EOF */
