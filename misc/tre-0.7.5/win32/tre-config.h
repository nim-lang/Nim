/* tre-config.h.  This file defines all compile time definitions
   that are needed in `regex.h' for Win32. */

/* Define to 1 if you have `alloca', as a function or macro. */
#define HAVE_ALLOCA 1

/* Define to 1 if you have <alloca.h> and it should be used (not on Ultrix).
 */
#define HAVE_ALLOCA_H 1

/* Define to 1 if you have the <libutf8.h> header file. */
/* #undef HAVE_LIBUTF8_H */

/* Define to 1 if the system has the type `reg_errcode_t'. */
/* #undef HAVE_REG_ERRCODE_T */

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <wchar.h> header file. */
#define HAVE_WCHAR_H 1

/* Define if you want to enable approximate matching functionality. */
#define TRE_APPROX 1

/* Define to enable multibyte character set support. */
#define TRE_MULTIBYTE 1

/* Define to the absolute path to the system regex.h */
/* #undef TRE_SYSTEM_REGEX_H_PATH */

/* Define if you want TRE to use alloca() instead of malloc() when allocating
   memory needed for regexec operations. */
#define TRE_USE_ALLOCA 1

/* Define to include the system regex.h from TRE regex.h */
/* #undef TRE_USE_SYSTEM_REGEX_H */

/* Define to enable wide character (wchar_t) support. */
#define TRE_WCHAR 1

/* TRE version string. */
#define TRE_VERSION "0.7.5"

/* TRE version level 1. */
#define TRE_VERSION_1 0

/* TRE version level 2. */
#define TRE_VERSION_2 7

/* TRE version level 3. */
#define TRE_VERSION_3 5
