/*
 * stdio.h
 *
 * Definitions of types and prototypes of functions for standard input and
 * output.
 *
 * NOTE: The file manipulation functions provided by Microsoft seem to
 * work with either slash (/) or backslash (\) as the path separator.
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

#ifndef _STDIO_H_
#define	_STDIO_H_

/* All the headers include this file. */
#include <_mingw.h>

#define __need_size_t
#define __need_NULL
#define __need_wchar_t
#define	__need_wint_t
#ifndef RC_INVOKED
#include <stddef.h>
#endif	/* Not RC_INVOKED */


/* Flags for the iobuf structure  */
#define	_IOREAD	1
#define	_IOWRT	2
#define	_IORW	0x0080 /* opened as "r+w" */


/*
 * The three standard file pointers provided by the run time library.
 * NOTE: These will go to the bit-bucket silently in GUI applications!
 */
#define	STDIN_FILENO	0
#define	STDOUT_FILENO	1
#define	STDERR_FILENO	2

/* Returned by various functions on end of file condition or error. */
#define	EOF	(-1)

/*
 * The maximum length of a file name. You should use GetVolumeInformation
 * instead of this constant. But hey, this works.
 *
 * NOTE: This is used in the structure _finddata_t (see io.h) so changing it
 *       is probably not a good idea.
 */
#define	FILENAME_MAX	(260)

/*
 * The maximum number of files that may be open at once. I have set this to
 * a conservative number. The actual value may be higher.
 */
#define FOPEN_MAX	(20)

/* After creating this many names, tmpnam and tmpfile return NULL */
#define TMP_MAX	32767
/*
 * Tmpnam, tmpfile and, sometimes, _tempnam try to create
 * temp files in the root directory of the current drive
 * (not in pwd, as suggested by some older MS doc's).
 * Redefining these macros does not effect the CRT functions.
 */
#define _P_tmpdir   "\\"
#define _wP_tmpdir  L"\\"

/*
 * The maximum size of name (including NUL) that will be put in the user
 * supplied buffer caName for tmpnam.
 * Inferred from the size of the static buffer returned by tmpnam
 * when passed a NULL argument. May actually be smaller.
 */
#define L_tmpnam (16)

#define _IOFBF		0x0000
#define _IOLBF		0x0040
#define _IONBF		0x0004

/*
 * The buffer size as used by setbuf such that it is equivalent to
 * (void) setvbuf(fileSetBuffer, caBuffer, _IOFBF, BUFSIZ).
 */
#define	BUFSIZ	512

/* Constants for nOrigin indicating the position relative to which fseek
 * sets the file position. Enclosed in ifdefs because io.h could also
 * define them. (Though not anymore since io.h includes this file now.) */
#ifndef	SEEK_SET
#define SEEK_SET	(0)
#endif

#ifndef	SEEK_CUR
#define	SEEK_CUR	(1)
#endif

#ifndef	SEEK_END
#define SEEK_END	(2)
#endif


#ifndef	RC_INVOKED

/*
 * I used to include stdarg.h at this point, in order to allow for the
 * functions later on in the file which use va_list. That conflicts with
 * using stdio.h and varargs.h in the same file, so I do the typedef myself.
 */
#ifndef	_VA_LIST
#define _VA_LIST
#if defined __GNUC__ && __GNUC__ >= 3
typedef __builtin_va_list va_list;
#else
typedef char* va_list;
#endif
#endif
/*
 * The structure underlying the FILE type.
 *
 * I still believe that nobody in their right mind should make use of the
 * internals of this structure. Provided by Pedro A. Aranda Gutiirrez
 * <paag@tid.es>.
 */
#ifndef _FILE_DEFINED
#define	_FILE_DEFINED
typedef struct _iobuf
{
	char*	_ptr;
	int	_cnt;
	char*	_base;
	int	_flag;
	int	_file;
	int	_charbuf;
	int	_bufsiz;
	char*	_tmpfname;
} FILE;
#endif	/* Not _FILE_DEFINED */


/*
 * The standard file handles
 */
#ifndef __DECLSPEC_SUPPORTED

extern FILE (*__imp__iob)[];	/* A pointer to an array of FILE */

#define _iob	(*__imp__iob)	/* An array of FILE */

#else /* __DECLSPEC_SUPPORTED */

__MINGW_IMPORT FILE _iob[];	/* An array of FILE imported from DLL. */

#endif /* __DECLSPEC_SUPPORTED */

#define stdin	(&_iob[STDIN_FILENO])
#define stdout	(&_iob[STDOUT_FILENO])
#define stderr	(&_iob[STDERR_FILENO])

#ifdef __cplusplus
extern "C" {
#endif

/*
 * File Operations
 */
FILE*	fopen (const char*, const char*);
FILE*	freopen (const char*, const char*, FILE*);
int	fflush (FILE*);
int	fclose (FILE*);
/* MS puts remove & rename (but not wide versions) in io.h  also */
int	remove (const char*);
int	rename (const char*, const char*);
FILE*	tmpfile (void);
char*	tmpnam (char*);
char*	_tempnam (const char*, const char*);

#ifndef	NO_OLDNAMES
char*	tempnam (const char*, const char*);
#endif

int	setvbuf (FILE*, char*, int, size_t);

void	setbuf (FILE*, char*);

/*
 * Formatted Output
 */

int	fprintf (FILE*, const char*, ...);
int	printf (const char*, ...);
int	sprintf (char*, const char*, ...);
int	_snprintf (char*, size_t, const char*, ...);
int	vfprintf (FILE*, const char*, va_list);
int	vprintf (const char*, va_list);
int	vsprintf (char*, const char*, va_list);
int	_vsnprintf (char*, size_t, const char*, va_list);

#ifndef __NO_ISOCEXT  /* externs in libmingwex.a */
int snprintf(char* s, size_t n, const char*  format, ...);
extern inline int vsnprintf (char* s, size_t n, const char* format,
			   va_list arg)
  { return _vsnprintf ( s, n, format, arg); }
#endif

/*
 * Formatted Input
 */

int	fscanf (FILE*, const char*, ...);
int	scanf (const char*, ...);
int	sscanf (const char*, const char*, ...);
/*
 * Character Input and Output Functions
 */

int	fgetc (FILE*);
char*	fgets (char*, int, FILE*);
int	fputc (int, FILE*);
int	fputs (const char*, FILE*);
int	getc (FILE*);
int	getchar (void);
char*	gets (char*);
int	putc (int, FILE*);
int	putchar (int);
int	puts (const char*);
int	ungetc (int, FILE*);

/*
 * Direct Input and Output Functions
 */

size_t	fread (void*, size_t, size_t, FILE*);
size_t	fwrite (const void*, size_t, size_t, FILE*);

/*
 * File Positioning Functions
 */

int	fseek (FILE*, long, int);
long	ftell (FILE*);
void	rewind (FILE*);

#ifdef __USE_MINGW_FSEEK  /* These are in libmingwex.a */
/*
 * Workaround for limitations on win9x where a file contents are
 * not zero'd out if you seek past the end and then write.
 */

int __mingw_fseek (FILE *, long, int);
int __mingw_fwrite (const void*, size_t, size_t, FILE*);
#define fseek(fp, offset, whence)  __mingw_fseek(fp, offset, whence)
#define fwrite(buffer, size, count, fp)  __mingw_fwrite(buffer, size, count, fp)
#endif /* __USE_MINGW_FSEEK */


/*
 * An opaque data type used for storing file positions... The contents of
 * this type are unknown, but we (the compiler) need to know the size
 * because the programmer using fgetpos and fsetpos will be setting aside
 * storage for fpos_t structres. Actually I tested using a byte array and
 * it is fairly evident that the fpos_t type is a long (in CRTDLL.DLL).
 * Perhaps an unsigned long? TODO? It's definitely a 64-bit number in
 * MSVCRT however, and for now `long long' will do.
 */
#ifdef __MSVCRT__
typedef long long fpos_t;
#else
typedef long	fpos_t;
#endif

int	fgetpos	(FILE*, fpos_t*);
int	fsetpos (FILE*, const fpos_t*);

/*
 * Error Functions
 */

void	clearerr (FILE*);
int	feof (FILE*);
int	ferror (FILE*);
void	perror (const char*);


#ifndef __STRICT_ANSI__
/*
 * Pipes
 */
FILE*	_popen (const char*, const char*);
int	_pclose (FILE*);

#ifndef NO_OLDNAMES
FILE*	popen (const char*, const char*);
int	pclose (FILE*);
#endif

/*
 * Other Non ANSI functions
 */
int	_flushall (void);
int	_fgetchar (void);
int	_fputchar (int);
FILE*	_fdopen (int, const char*);
int	_fileno (FILE*);

#ifndef _NO_OLDNAMES
int	fgetchar (void);
int	fputchar (int);
FILE*	fdopen (int, const char*);
int	fileno (FILE*);
#endif	/* Not _NO_OLDNAMES */

#endif	/* Not __STRICT_ANSI__ */

/* Wide  versions */

#ifndef _WSTDIO_DEFINED
/*  also in wchar.h - keep in sync */
int	fwprintf (FILE*, const wchar_t*, ...);
int	wprintf (const wchar_t*, ...);
int	swprintf (wchar_t*, const wchar_t*, ...);
int	_snwprintf (wchar_t*, size_t, const wchar_t*, ...);
int	vfwprintf (FILE*, const wchar_t*, va_list);
int	vwprintf (const wchar_t*, va_list);
int	vswprintf (wchar_t*, const wchar_t*, va_list);
int	_vsnwprintf (wchar_t*, size_t, const wchar_t*, va_list);
int	fwscanf (FILE*, const wchar_t*, ...);
int	wscanf (const wchar_t*, ...);
int	swscanf (const wchar_t*, const wchar_t*, ...);
wint_t	fgetwc (FILE*);
wint_t	fputwc (wchar_t, FILE*);
wint_t	ungetwc (wchar_t, FILE*);
#ifdef __MSVCRT__ 
wchar_t* fgetws (wchar_t*, int, FILE*);
int	fputws (const wchar_t*, FILE*);
wint_t	getwc (FILE*);
wint_t	getwchar (void);
wchar_t* _getws (wchar_t*);
wint_t	putwc (wint_t, FILE*);
int	_putws (const wchar_t*);
wint_t	putwchar (wint_t);
FILE*	_wfopen (const wchar_t*, const wchar_t*);
FILE*	_wfreopen (const wchar_t*, const wchar_t*, FILE*);
FILE*	_wfsopen (const wchar_t*, const wchar_t*, int);
wchar_t* _wtmpnam (wchar_t*);
wchar_t* _wtempnam (const wchar_t*, const wchar_t*);
int	_wrename (const wchar_t*, const wchar_t*);
int	_wremove (const wchar_t*);
void	_wperror (const wchar_t*);
FILE*	_wpopen (const wchar_t*, const wchar_t*);
#endif	/* __MSVCRT__ */

#ifndef __NO_ISOCEXT  /* externs in libmingwex.a */
int snwprintf(wchar_t* s, size_t n, const wchar_t*  format, ...);
extern inline int vsnwprintf (wchar_t* s, size_t n, const wchar_t* format,
			   va_list arg)
  { return _vsnwprintf ( s, n, format, arg); }
#endif

#define _WSTDIO_DEFINED
#endif /* _WSTDIO_DEFINED */

#ifndef __STRICT_ANSI__
#ifdef __MSVCRT__
#ifndef NO_OLDNAMES
FILE*	wpopen (const wchar_t*, const wchar_t*);
#endif /* not NO_OLDNAMES */
#endif /* MSVCRT runtime */

/*
 * Other Non ANSI wide functions
 */
wint_t	_fgetwchar (void);
wint_t	_fputwchar (wint_t);
int	_getw (FILE*);
int	_putw (int, FILE*);

#ifndef _NO_OLDNAMES
wint_t	fgetwchar (void);
wint_t	fputwchar (wint_t);
int	getw (FILE*);
int	putw (int, FILE*);
#endif	/* Not _NO_OLDNAMES */

#endif /* __STRICT_ANSI */

#ifdef __cplusplus
}
#endif

#endif	/* Not RC_INVOKED */

#endif /* _STDIO_H_ */
