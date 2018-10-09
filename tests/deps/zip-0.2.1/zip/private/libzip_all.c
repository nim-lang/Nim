/*
  zipint.h -- internal declarations.
  Copyright (C) 1999-2008 Dieter Baron and Thomas Klausner

  This file is part of libzip, a library to manipulate ZIP archives.
  The authors can be contacted at <libzip@nih.at>

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:
  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in
     the documentation and/or other materials provided with the
     distribution.
  3. The names of the authors may not be used to endorse or promote
     products derived from this software without specific prior
     written permission.

  THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS
  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <zlib.h>

/*
#ifdef _MSC_VER
#define ZIP_EXTERN __declspec(dllimport)
#endif
*/

/*
  zip.h -- exported declarations.
  Copyright (C) 1999-2008 Dieter Baron and Thomas Klausner

  This file is part of libzip, a library to manipulate ZIP archives.
  The authors can be contacted at <libzip@nih.at>

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:
  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in
     the documentation and/or other materials provided with the
     distribution.
  3. The names of the authors may not be used to endorse or promote
     products derived from this software without specific prior
     written permission.

  THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS
  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#ifndef ZIP_EXTERN
#define ZIP_EXTERN
#endif

#ifdef __cplusplus
extern "C" {
#endif

#include <sys/types.h>
#include <stdio.h>
#include <time.h>

/* flags for zip_open */

#define ZIP_CREATE           1
#define ZIP_EXCL             2
#define ZIP_CHECKCONS        4


/* flags for zip_name_locate, zip_fopen, zip_stat, ... */

#define ZIP_FL_NOCASE                1 /* ignore case on name lookup */
#define ZIP_FL_NODIR                2 /* ignore directory component */
#define ZIP_FL_COMPRESSED        4 /* read compressed data */
#define ZIP_FL_UNCHANGED        8 /* use original data, ignoring changes */
#define ZIP_FL_RECOMPRESS      16 /* force recompression of data */

/* archive global flags flags */

#define ZIP_AFL_TORRENT                1 /* torrent zipped */

/* libzip error codes */

#define ZIP_ER_OK             0  /* N No error */
#define ZIP_ER_MULTIDISK      1  /* N Multi-disk zip archives not supported */
#define ZIP_ER_RENAME         2  /* S Renaming temporary file failed */
#define ZIP_ER_CLOSE          3  /* S Closing zip archive failed */
#define ZIP_ER_SEEK           4  /* S Seek error */
#define ZIP_ER_READ           5  /* S Read error */
#define ZIP_ER_WRITE          6  /* S Write error */
#define ZIP_ER_CRC            7  /* N CRC error */
#define ZIP_ER_ZIPCLOSED      8  /* N Containing zip archive was closed */
#define ZIP_ER_NOENT          9  /* N No such file */
#define ZIP_ER_EXISTS        10  /* N File already exists */
#define ZIP_ER_OPEN          11  /* S Can't open file */
#define ZIP_ER_TMPOPEN       12  /* S Failure to create temporary file */
#define ZIP_ER_ZLIB          13  /* Z Zlib error */
#define ZIP_ER_MEMORY        14  /* N Malloc failure */
#define ZIP_ER_CHANGED       15  /* N Entry has been changed */
#define ZIP_ER_COMPNOTSUPP   16  /* N Compression method not supported */
#define ZIP_ER_EOF           17  /* N Premature EOF */
#define ZIP_ER_INVAL         18  /* N Invalid argument */
#define ZIP_ER_NOZIP         19  /* N Not a zip archive */
#define ZIP_ER_INTERNAL      20  /* N Internal error */
#define ZIP_ER_INCONS        21  /* N Zip archive inconsistent */
#define ZIP_ER_REMOVE        22  /* S Can't remove file */
#define ZIP_ER_DELETED       23  /* N Entry has been deleted */


/* type of system error value */

#define ZIP_ET_NONE              0  /* sys_err unused */
#define ZIP_ET_SYS              1  /* sys_err is errno */
#define ZIP_ET_ZLIB              2  /* sys_err is zlib error code */

/* compression methods */

#define ZIP_CM_DEFAULT              -1  /* better of deflate or store */
#define ZIP_CM_STORE               0  /* stored (uncompressed) */
#define ZIP_CM_SHRINK               1  /* shrunk */
#define ZIP_CM_REDUCE_1               2  /* reduced with factor 1 */
#define ZIP_CM_REDUCE_2               3  /* reduced with factor 2 */
#define ZIP_CM_REDUCE_3               4  /* reduced with factor 3 */
#define ZIP_CM_REDUCE_4               5  /* reduced with factor 4 */
#define ZIP_CM_IMPLODE               6  /* imploded */
/* 7 - Reserved for Tokenizing compression algorithm */
#define ZIP_CM_DEFLATE               8  /* deflated */
#define ZIP_CM_DEFLATE64       9  /* deflate64 */
#define ZIP_CM_PKWARE_IMPLODE 10  /* PKWARE imploding */
/* 11 - Reserved by PKWARE */
#define ZIP_CM_BZIP2          12  /* compressed using BZIP2 algorithm */
/* 13 - Reserved by PKWARE */
#define ZIP_CM_LZMA              14  /* LZMA (EFS) */
/* 15-17 - Reserved by PKWARE */
#define ZIP_CM_TERSE              18  /* compressed using IBM TERSE (new) */
#define ZIP_CM_LZ77           19  /* IBM LZ77 z Architecture (PFS) */
#define ZIP_CM_WAVPACK              97  /* WavPack compressed data */
#define ZIP_CM_PPMD              98  /* PPMd version I, Rev 1 */

/* encryption methods */

#define ZIP_EM_NONE               0  /* not encrypted */
#define ZIP_EM_TRAD_PKWARE     1  /* traditional PKWARE encryption */
#if 0 /* Strong Encryption Header not parsed yet */
#define ZIP_EM_DES        0x6601  /* strong encryption: DES */
#define ZIP_EM_RC2_OLD    0x6602  /* strong encryption: RC2, version < 5.2 */
#define ZIP_EM_3DES_168   0x6603
#define ZIP_EM_3DES_112   0x6609
#define ZIP_EM_AES_128    0x660e
#define ZIP_EM_AES_192    0x660f
#define ZIP_EM_AES_256    0x6610
#define ZIP_EM_RC2        0x6702  /* strong encryption: RC2, version >= 5.2 */
#define ZIP_EM_RC4        0x6801
#endif
#define ZIP_EM_UNKNOWN    0xffff  /* unknown algorithm */

typedef long myoff_t; /* XXX: 64 bit support */

enum zip_source_cmd {
    ZIP_SOURCE_OPEN,        /* prepare for reading */
    ZIP_SOURCE_READ,         /* read data */
    ZIP_SOURCE_CLOSE,        /* reading is done */
    ZIP_SOURCE_STAT,        /* get meta information */
    ZIP_SOURCE_ERROR,        /* get error information */
    ZIP_SOURCE_FREE        /* cleanup and free resources */
};

typedef ssize_t (*zip_source_callback)(void *state, void *data,
                                       size_t len, enum zip_source_cmd cmd);

struct zip_stat {
    const char *name;                        /* name of the file */
    int index;                                /* index within archive */
    unsigned int crc;                        /* crc of file data */
    time_t mtime;                        /* modification time */
    myoff_t size;                                /* size of file (uncompressed) */
    myoff_t comp_size;                        /* size of file (compressed) */
    unsigned short comp_method;                /* compression method used */
    unsigned short encryption_method;        /* encryption method used */
};

struct zip;
struct zip_file;
struct zip_source;


ZIP_EXTERN int zip_add(struct zip *, const char *, struct zip_source *);
ZIP_EXTERN int zip_add_dir(struct zip *, const char *);
ZIP_EXTERN int zip_close(struct zip *);
ZIP_EXTERN int zip_delete(struct zip *, int);
ZIP_EXTERN void zip_error_clear(struct zip *);
ZIP_EXTERN void zip_error_get(struct zip *, int *, int *);
ZIP_EXTERN int zip_error_get_sys_type(int);
ZIP_EXTERN int zip_error_to_str(char *, size_t, int, int);
ZIP_EXTERN int zip_fclose(struct zip_file *);
ZIP_EXTERN void zip_file_error_clear(struct zip_file *);
ZIP_EXTERN void zip_file_error_get(struct zip_file *, int *, int *);
ZIP_EXTERN const char *zip_file_strerror(struct zip_file *);
ZIP_EXTERN struct zip_file *zip_fopen(struct zip *, const char *, int);
ZIP_EXTERN struct zip_file *zip_fopen_index(struct zip *, int, int);
ZIP_EXTERN ssize_t zip_fread(struct zip_file *, void *, size_t);
ZIP_EXTERN const char *zip_get_archive_comment(struct zip *, int *, int);
ZIP_EXTERN int zip_get_archive_flag(struct zip *, int, int);
ZIP_EXTERN const char *zip_get_file_comment(struct zip *, int, int *, int);
ZIP_EXTERN const char *zip_get_name(struct zip *, int, int);
ZIP_EXTERN int zip_get_num_files(struct zip *);
ZIP_EXTERN int zip_name_locate(struct zip *, const char *, int);
ZIP_EXTERN struct zip *zip_open(const char *, int, int *);
ZIP_EXTERN int zip_rename(struct zip *, int, const char *);
ZIP_EXTERN int zip_replace(struct zip *, int, struct zip_source *);
ZIP_EXTERN int zip_set_archive_comment(struct zip *, const char *, int);
ZIP_EXTERN int zip_set_archive_flag(struct zip *, int, int);
ZIP_EXTERN int zip_set_file_comment(struct zip *, int, const char *, int);
ZIP_EXTERN struct zip_source *zip_source_buffer(struct zip *, const void *,
                                                myoff_t, int);
ZIP_EXTERN struct zip_source *zip_source_file(struct zip *, const char *,
                                              myoff_t, myoff_t);
ZIP_EXTERN struct zip_source *zip_source_filep(struct zip *, FILE *,
                                               myoff_t, myoff_t);
ZIP_EXTERN void zip_source_free(struct zip_source *);
ZIP_EXTERN struct zip_source *zip_source_function(struct zip *,
                                                  zip_source_callback, void *);
ZIP_EXTERN struct zip_source *zip_source_zip(struct zip *, struct zip *,
                                             int, int, myoff_t, myoff_t);
ZIP_EXTERN int zip_stat(struct zip *, const char *, int, struct zip_stat *);
ZIP_EXTERN int zip_stat_index(struct zip *, int, int, struct zip_stat *);
ZIP_EXTERN void zip_stat_init(struct zip_stat *);
ZIP_EXTERN const char *zip_strerror(struct zip *);
ZIP_EXTERN int zip_unchange(struct zip *, int);
ZIP_EXTERN int zip_unchange_all(struct zip *);
ZIP_EXTERN int zip_unchange_archive(struct zip *);

#ifdef __cplusplus
}
#endif


/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.ac by autoheader.  */

/* Define to 1 if you have the declaration of `tzname', and to 0 if you don't.
   */
/* #undef HAVE_DECL_TZNAME */

#define HAVE_CONFIG_H 1

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* Define to 1 if you have the `fseeko' function. */
#define HAVE_FSEEKO 1

/* Define to 1 if you have the `ftello' function. */
#define HAVE_FTELLO 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the `z' library (-lz). */
#define HAVE_LIBZ 1

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if you have the `mkstemp' function. */
#define HAVE_MKSTEMP 1

/* Define to 1 if you have the `MoveFileExA' function. */
/* #undef HAVE_MOVEFILEEXA */

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if `tm_zone' is member of `struct tm'. */
#ifdef WIN32
#undef HAVE_STRUCT_TM_TM_ZONE
#else
#define HAVE_STRUCT_TM_TM_ZONE 1
#endif

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if your `struct tm' has `tm_zone'. Deprecated, use
   `HAVE_STRUCT_TM_TM_ZONE' instead. */
#define HAVE_TM_ZONE 1

/* Define to 1 if you don't have `tm_zone' but do have the external array
   `tzname'. */
/* #undef HAVE_TZNAME */

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to 1 if your C compiler doesn't accept -c and -o together. */
/* #undef NO_MINUS_C_MINUS_O */

/* Name of package */
#define PACKAGE "libzip"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "libzip@nih.at"

/* Define to the full name of this package. */
#define PACKAGE_NAME "libzip"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "libzip 0.9"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "libzip"

/* Define to the version of this package. */
#define PACKAGE_VERSION "0.9"

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Define to 1 if your <sys/time.h> declares `struct tm'. */
/* #undef TM_IN_SYS_TIME */

/* Version number of package */
#define VERSION "0.9"


#ifndef HAVE_MKSTEMP
int _zip_mkstemp(char *);
#define mkstemp _zip_mkstemp
#endif

#ifdef HAVE_MOVEFILEEXA
#include <windows.h>
#define _zip_rename(s, t)                                                \
        (!MoveFileExA((s), (t),                                                \
                     MOVEFILE_COPY_ALLOWED|MOVEFILE_REPLACE_EXISTING))
#else
#define _zip_rename        rename
#endif

#ifndef HAVE_FSEEKO
#define fseeko(s, o, w)        (fseek((s), (long int)(o), (w)))
#endif
#ifndef HAVE_FTELLO
#define ftello(s)        ((long)ftell((s)))
#endif


#define CENTRAL_MAGIC "PK\1\2"
#define LOCAL_MAGIC   "PK\3\4"
#define EOCD_MAGIC    "PK\5\6"
#define DATADES_MAGIC "PK\7\8"
#define TORRENT_SIG        "TORRENTZIPPED-"
#define TORRENT_SIG_LEN        14
#define TORRENT_CRC_LEN 8
#define TORRENT_MEM_LEVEL        8
#define CDENTRYSIZE         46u
#define LENTRYSIZE          30
#define MAXCOMLEN        65536
#define EOCDLEN             22
#define CDBUFSIZE       (MAXCOMLEN+EOCDLEN)
#define BUFSIZE                8192


/* state of change of a file in zip archive */

enum zip_state { ZIP_ST_UNCHANGED, ZIP_ST_DELETED, ZIP_ST_REPLACED,
                 ZIP_ST_ADDED, ZIP_ST_RENAMED };

/* constants for struct zip_file's member flags */

#define ZIP_ZF_EOF        1 /* EOF reached */
#define ZIP_ZF_DECOMP        2 /* decompress data */
#define ZIP_ZF_CRC        4 /* compute and compare CRC */

/* directory entry: general purpose bit flags */

#define ZIP_GPBF_ENCRYPTED                0x0001        /* is encrypted */
#define ZIP_GPBF_DATA_DESCRIPTOR        0x0008        /* crc/size after file data */
#define ZIP_GPBF_STRONG_ENCRYPTION        0x0040  /* uses strong encryption */

/* error information */

struct zip_error {
    int zip_err;        /* libzip error code (ZIP_ER_*) */
    int sys_err;        /* copy of errno (E*) or zlib error code */
    char *str;                /* string representation or NULL */
};

/* zip archive, part of API */

struct zip {
    char *zn;                        /* file name */
    FILE *zp;                        /* file */
    struct zip_error error;        /* error information */

    unsigned int flags;                /* archive global flags */
    unsigned int ch_flags;        /* changed archive global flags */

    struct zip_cdir *cdir;        /* central directory */
    char *ch_comment;                /* changed archive comment */
    int ch_comment_len;                /* length of changed zip archive
                                 * comment, -1 if unchanged */
    int nentry;                        /* number of entries */
    int nentry_alloc;                /* number of entries allocated */
    struct zip_entry *entry;        /* entries */
    int nfile;                        /* number of opened files within archive */
    int nfile_alloc;                /* number of files allocated */
    struct zip_file **file;        /* opened files within archive */
};

/* file in zip archive, part of API */

struct zip_file {
    struct zip *za;                /* zip archive containing this file */
    struct zip_error error;        /* error information */
    int flags;                        /* -1: eof, >0: error */

    int method;                        /* compression method */
    myoff_t fpos;                        /* position within zip file (fread/fwrite) */
    unsigned long bytes_left;        /* number of bytes left to read */
    unsigned long cbytes_left;  /* number of bytes of compressed data left */

    unsigned long crc;                /* CRC so far */
    unsigned long crc_orig;        /* CRC recorded in archive */

    char *buffer;
    z_stream *zstr;
};

/* zip archive directory entry (central or local) */

struct zip_dirent {
    unsigned short version_madeby;        /* (c)  version of creator */
    unsigned short version_needed;        /* (cl) version needed to extract */
    unsigned short bitflags;                /* (cl) general purpose bit flag */
    unsigned short comp_method;                /* (cl) compression method used */
    time_t last_mod;                        /* (cl) time of last modification */
    unsigned int crc;                        /* (cl) CRC-32 of uncompressed data */
    unsigned int comp_size;                /* (cl) size of commpressed data */
    unsigned int uncomp_size;                /* (cl) size of uncommpressed data */
    char *filename;                        /* (cl) file name (NUL-terminated) */
    unsigned short filename_len;        /* (cl) length of filename (w/o NUL) */
    char *extrafield;                        /* (cl) extra field */
    unsigned short extrafield_len;        /* (cl) length of extra field */
    char *comment;                        /* (c)  file comment */
    unsigned short comment_len;                /* (c)  length of file comment */
    unsigned short disk_number;                /* (c)  disk number start */
    unsigned short int_attrib;                /* (c)  internal file attributes */
    unsigned int ext_attrib;                /* (c)  external file attributes */
    unsigned int offset;                /* (c)  offset of local header  */
};

/* zip archive central directory */

struct zip_cdir {
    struct zip_dirent *entry;        /* directory entries */
    int nentry;                        /* number of entries */

    unsigned int size;                /* size of central direcotry */
    unsigned int offset;        /* offset of central directory in file */
    char *comment;                /* zip archive comment */
    unsigned short comment_len;        /* length of zip archive comment */
};



struct zip_source {
    zip_source_callback f;
    void *ud;
};

/* entry in zip archive directory */

struct zip_entry {
    enum zip_state state;
    struct zip_source *source;
    char *ch_filename;
    char *ch_comment;
    int ch_comment_len;
};



extern const char * const _zip_err_str[];
extern const int _zip_nerr_str;
extern const int _zip_err_type[];



#define ZIP_ENTRY_DATA_CHANGED(x)        \
                        ((x)->state == ZIP_ST_REPLACED  \
                         || (x)->state == ZIP_ST_ADDED)



int _zip_cdir_compute_crc(struct zip *, uLong *);
void _zip_cdir_free(struct zip_cdir *);
struct zip_cdir *_zip_cdir_new(int, struct zip_error *);
int _zip_cdir_write(struct zip_cdir *, FILE *, struct zip_error *);

void _zip_dirent_finalize(struct zip_dirent *);
void _zip_dirent_init(struct zip_dirent *);
int _zip_dirent_read(struct zip_dirent *, FILE *,
                     unsigned char **, unsigned int, int, struct zip_error *);
void _zip_dirent_torrent_normalize(struct zip_dirent *);
int _zip_dirent_write(struct zip_dirent *, FILE *, int, struct zip_error *);

void _zip_entry_free(struct zip_entry *);
void _zip_entry_init(struct zip *, int);
struct zip_entry *_zip_entry_new(struct zip *);

void _zip_error_clear(struct zip_error *);
void _zip_error_copy(struct zip_error *, struct zip_error *);
void _zip_error_fini(struct zip_error *);
void _zip_error_get(struct zip_error *, int *, int *);
void _zip_error_init(struct zip_error *);
void _zip_error_set(struct zip_error *, int, int);
const char *_zip_error_strerror(struct zip_error *);

int _zip_file_fillbuf(void *, size_t, struct zip_file *);
unsigned int _zip_file_get_offset(struct zip *, int);

int _zip_filerange_crc(FILE *, myoff_t, myoff_t, uLong *, struct zip_error *);

struct zip_source *_zip_source_file_or_p(struct zip *, const char *, FILE *,
                                         myoff_t, myoff_t);

void _zip_free(struct zip *);
const char *_zip_get_name(struct zip *, int, int, struct zip_error *);
int _zip_local_header_read(struct zip *, int);
void *_zip_memdup(const void *, size_t, struct zip_error *);
int _zip_name_locate(struct zip *, const char *, int, struct zip_error *);
struct zip *_zip_new(struct zip_error *);
unsigned short _zip_read2(unsigned char **);
unsigned int _zip_read4(unsigned char **);
int _zip_replace(struct zip *, int, const char *, struct zip_source *);
int _zip_set_name(struct zip *, int, const char *);
int _zip_unchange(struct zip *, int, int);
void _zip_unchange_data(struct zip_entry *);


#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

const char *
_zip_error_strerror(struct zip_error *err)
{
    const char *zs, *ss;
    char buf[128], *s;

    _zip_error_fini(err);

    if (err->zip_err < 0 || err->zip_err >= _zip_nerr_str) {
        sprintf(buf, "Unknown error %d", err->zip_err);
        zs = NULL;
        ss = buf;
    }
    else {
        zs = _zip_err_str[err->zip_err];

        switch (_zip_err_type[err->zip_err]) {
        case ZIP_ET_SYS:
            ss = strerror(err->sys_err);
            break;

        case ZIP_ET_ZLIB:
            ss = zError(err->sys_err);
            break;

        default:
            ss = NULL;
        }
    }

    if (ss == NULL)
        return zs;
    else {
        if ((s=(char *)malloc(strlen(ss)
                              + (zs ? strlen(zs)+2 : 0) + 1)) == NULL)
            return _zip_err_str[ZIP_ER_MEMORY];

        sprintf(s, "%s%s%s",
                (zs ? zs : ""),
                (zs ? ": " : ""),
                ss);
        err->str = s;

        return s;
    }
}

#include <stdlib.h>



void
_zip_error_clear(struct zip_error *err)
{
    err->zip_err = ZIP_ER_OK;
    err->sys_err = 0;
}



void
_zip_error_copy(struct zip_error *dst, struct zip_error *src)
{
    dst->zip_err = src->zip_err;
    dst->sys_err = src->sys_err;
}



void
_zip_error_fini(struct zip_error *err)
{
    free(err->str);
    err->str = NULL;
}



void
_zip_error_get(struct zip_error *err, int *zep, int *sep)
{
    if (zep)
        *zep = err->zip_err;
    if (sep) {
        if (zip_error_get_sys_type(err->zip_err) != ZIP_ET_NONE)
            *sep = err->sys_err;
        else
            *sep = 0;
    }
}



void
_zip_error_init(struct zip_error *err)
{
    err->zip_err = ZIP_ER_OK;
    err->sys_err = 0;
    err->str = NULL;
}



void
_zip_error_set(struct zip_error *err, int ze, int se)
{
    if (err) {
        err->zip_err = ze;
        err->sys_err = se;
    }
}


#include <sys/types.h>
#include <sys/stat.h>

#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef O_BINARY
#define O_BINARY 0
#endif



int
_zip_mkstemp(char *path)
{
        int fd;
        char *start, *trv;
        struct stat sbuf;
        pid_t pid;

        /* To guarantee multiple calls generate unique names even if
           the file is not created. 676 different possibilities with 7
           or more X's, 26 with 6 or less. */
        static char xtra[2] = "aa";
        int xcnt = 0;

        pid = getpid();

        /* Move to end of path and count trailing X's. */
        for (trv = path; *trv; ++trv)
                if (*trv == 'X')
                        xcnt++;
                else
                        xcnt = 0;

        /* Use at least one from xtra.  Use 2 if more than 6 X's. */
        if (*(trv - 1) == 'X')
                *--trv = xtra[0];
        if (xcnt > 6 && *(trv - 1) == 'X')
                *--trv = xtra[1];

        /* Set remaining X's to pid digits with 0's to the left. */
        while (*--trv == 'X') {
                *trv = (pid % 10) + '0';
                pid /= 10;
        }

        /* update xtra for next call. */
        if (xtra[0] != 'z')
                xtra[0]++;
        else {
                xtra[0] = 'a';
                if (xtra[1] != 'z')
                        xtra[1]++;
                else
                        xtra[1] = 'a';
        }

        /*
         * check the target directory; if you have six X's and it
         * doesn't exist this runs for a *very* long time.
         */
        for (start = trv + 1;; --trv) {
                if (trv <= path)
                        break;
                if (*trv == '/') {
                        *trv = '\0';
                        if (stat(path, &sbuf))
                                return (0);
                        if (!S_ISDIR(sbuf.st_mode)) {
                                errno = ENOTDIR;
                                return (0);
                        }
                        *trv = '/';
                        break;
                }
        }

        for (;;) {
                if ((fd=open(path, O_CREAT|O_EXCL|O_RDWR|O_BINARY, 0600)) >= 0)
                        return (fd);
                if (errno != EEXIST)
                        return (0);

                /* tricky little algorithm for backward compatibility */
                for (trv = start;;) {
                        if (!*trv)
                                return (0);
                        if (*trv == 'z')
                                *trv++ = 'a';
                        else {
                                if (isdigit((unsigned char)*trv))
                                        *trv = 'a';
                                else
                                        ++*trv;
                                break;
                        }
                }
        }
        /*NOTREACHED*/
}


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>

static time_t _zip_d2u_time(int, int);
static char *_zip_readfpstr(FILE *, unsigned int, int, struct zip_error *);
static char *_zip_readstr(unsigned char **, int, int, struct zip_error *);
static void _zip_u2d_time(time_t, unsigned short *, unsigned short *);
static void _zip_write2(unsigned short, FILE *);
static void _zip_write4(unsigned int, FILE *);



void
_zip_cdir_free(struct zip_cdir *cd)
{
    int i;

    if (!cd)
        return;

    for (i=0; i<cd->nentry; i++)
        _zip_dirent_finalize(cd->entry+i);
    free(cd->comment);
    free(cd->entry);
    free(cd);
}



struct zip_cdir *
_zip_cdir_new(int nentry, struct zip_error *error)
{
    struct zip_cdir *cd;

    if ((cd=(struct zip_cdir *)malloc(sizeof(*cd))) == NULL) {
        _zip_error_set(error, ZIP_ER_MEMORY, 0);
        return NULL;
    }

    if ((cd->entry=(struct zip_dirent *)malloc(sizeof(*(cd->entry))*nentry))
        == NULL) {
        _zip_error_set(error, ZIP_ER_MEMORY, 0);
        free(cd);
        return NULL;
    }

    /* entries must be initialized by caller */

    cd->nentry = nentry;
    cd->size = cd->offset = 0;
    cd->comment = NULL;
    cd->comment_len = 0;

    return cd;
}



int
_zip_cdir_write(struct zip_cdir *cd, FILE *fp, struct zip_error *error)
{
    int i;

    cd->offset = ftello(fp);

    for (i=0; i<cd->nentry; i++) {
        if (_zip_dirent_write(cd->entry+i, fp, 0, error) != 0)
            return -1;
    }

    cd->size = ftello(fp) - cd->offset;

    /* clearerr(fp); */
    fwrite(EOCD_MAGIC, 1, 4, fp);
    _zip_write4(0, fp);
    _zip_write2((unsigned short)cd->nentry, fp);
    _zip_write2((unsigned short)cd->nentry, fp);
    _zip_write4(cd->size, fp);
    _zip_write4(cd->offset, fp);
    _zip_write2(cd->comment_len, fp);
    fwrite(cd->comment, 1, cd->comment_len, fp);

    if (ferror(fp)) {
        _zip_error_set(error, ZIP_ER_WRITE, errno);
        return -1;
    }

    return 0;
}



void
_zip_dirent_finalize(struct zip_dirent *zde)
{
    free(zde->filename);
    zde->filename = NULL;
    free(zde->extrafield);
    zde->extrafield = NULL;
    free(zde->comment);
    zde->comment = NULL;
}



void
_zip_dirent_init(struct zip_dirent *de)
{
    de->version_madeby = 0;
    de->version_needed = 20; /* 2.0 */
    de->bitflags = 0;
    de->comp_method = 0;
    de->last_mod = 0;
    de->crc = 0;
    de->comp_size = 0;
    de->uncomp_size = 0;
    de->filename = NULL;
    de->filename_len = 0;
    de->extrafield = NULL;
    de->extrafield_len = 0;
    de->comment = NULL;
    de->comment_len = 0;
    de->disk_number = 0;
    de->int_attrib = 0;
    de->ext_attrib = 0;
    de->offset = 0;
}



/* _zip_dirent_read(zde, fp, bufp, left, localp, error):
   Fills the zip directory entry zde.

   If bufp is non-NULL, data is taken from there and bufp is advanced
   by the amount of data used; no more than left bytes are used.
   Otherwise data is read from fp as needed.

   If localp != 0, it reads a local header instead of a central
   directory entry.

   Returns 0 if successful. On error, error is filled in and -1 is
   returned.
*/

int
_zip_dirent_read(struct zip_dirent *zde, FILE *fp,
                 unsigned char **bufp, unsigned int left, int localp,
                 struct zip_error *error)
{
    unsigned char buf[CDENTRYSIZE];
    unsigned char *cur;
    unsigned short dostime, dosdate;
    unsigned int size;

    if (localp)
        size = LENTRYSIZE;
    else
        size = CDENTRYSIZE;

    if (bufp) {
        /* use data from buffer */
        cur = *bufp;
        if (left < size) {
            _zip_error_set(error, ZIP_ER_NOZIP, 0);
            return -1;
        }
    }
    else {
        /* read entry from disk */
        if ((fread(buf, 1, size, fp)<size)) {
            _zip_error_set(error, ZIP_ER_READ, errno);
            return -1;
        }
        left = size;
        cur = buf;
    }

    if (memcmp(cur, (localp ? LOCAL_MAGIC : CENTRAL_MAGIC), 4) != 0) {
        _zip_error_set(error, ZIP_ER_NOZIP, 0);
        return -1;
    }
    cur += 4;


    /* convert buffercontents to zip_dirent */

    if (!localp)
        zde->version_madeby = _zip_read2(&cur);
    else
        zde->version_madeby = 0;
    zde->version_needed = _zip_read2(&cur);
    zde->bitflags = _zip_read2(&cur);
    zde->comp_method = _zip_read2(&cur);

    /* convert to time_t */
    dostime = _zip_read2(&cur);
    dosdate = _zip_read2(&cur);
    zde->last_mod = _zip_d2u_time(dostime, dosdate);

    zde->crc = _zip_read4(&cur);
    zde->comp_size = _zip_read4(&cur);
    zde->uncomp_size = _zip_read4(&cur);

    zde->filename_len = _zip_read2(&cur);
    zde->extrafield_len = _zip_read2(&cur);

    if (localp) {
        zde->comment_len = 0;
        zde->disk_number = 0;
        zde->int_attrib = 0;
        zde->ext_attrib = 0;
        zde->offset = 0;
    } else {
        zde->comment_len = _zip_read2(&cur);
        zde->disk_number = _zip_read2(&cur);
        zde->int_attrib = _zip_read2(&cur);
        zde->ext_attrib = _zip_read4(&cur);
        zde->offset = _zip_read4(&cur);
    }

    zde->filename = NULL;
    zde->extrafield = NULL;
    zde->comment = NULL;

    if (bufp) {
        if (left < CDENTRYSIZE + (zde->filename_len+zde->extrafield_len
                                  +zde->comment_len)) {
            _zip_error_set(error, ZIP_ER_NOZIP, 0);
            return -1;
        }

        if (zde->filename_len) {
            zde->filename = _zip_readstr(&cur, zde->filename_len, 1, error);
            if (!zde->filename)
                    return -1;
        }

        if (zde->extrafield_len) {
            zde->extrafield = _zip_readstr(&cur, zde->extrafield_len, 0,
                                           error);
            if (!zde->extrafield)
                return -1;
        }

        if (zde->comment_len) {
            zde->comment = _zip_readstr(&cur, zde->comment_len, 0, error);
            if (!zde->comment)
                return -1;
        }
    }
    else {
        if (zde->filename_len) {
            zde->filename = _zip_readfpstr(fp, zde->filename_len, 1, error);
            if (!zde->filename)
                    return -1;
        }

        if (zde->extrafield_len) {
            zde->extrafield = _zip_readfpstr(fp, zde->extrafield_len, 0,
                                             error);
            if (!zde->extrafield)
                return -1;
        }

        if (zde->comment_len) {
            zde->comment = _zip_readfpstr(fp, zde->comment_len, 0, error);
            if (!zde->comment)
                return -1;
        }
    }

    if (bufp)
      *bufp = cur;

    return 0;
}



/* _zip_dirent_torrent_normalize(de);
   Set values suitable for torrentzip.
*/

void
_zip_dirent_torrent_normalize(struct zip_dirent *de)
{
    static struct tm torrenttime;
    static time_t last_mod = 0;

    if (last_mod == 0) {
#ifdef HAVE_STRUCT_TM_TM_ZONE
        time_t now;
        struct tm *l;
#endif

        torrenttime.tm_sec = 0;
        torrenttime.tm_min = 32;
        torrenttime.tm_hour = 23;
        torrenttime.tm_mday = 24;
        torrenttime.tm_mon = 11;
        torrenttime.tm_year = 96;
        torrenttime.tm_wday = 0;
        torrenttime.tm_yday = 0;
        torrenttime.tm_isdst = 0;

#ifdef HAVE_STRUCT_TM_TM_ZONE
        time(&now);
        l = localtime(&now);
        torrenttime.tm_gmtoff = l->tm_gmtoff;
        torrenttime.tm_zone = l->tm_zone;
#endif

        last_mod = mktime(&torrenttime);
    }

    de->version_madeby = 0;
    de->version_needed = 20; /* 2.0 */
    de->bitflags = 2; /* maximum compression */
    de->comp_method = ZIP_CM_DEFLATE;
    de->last_mod = last_mod;

    de->disk_number = 0;
    de->int_attrib = 0;
    de->ext_attrib = 0;
    de->offset = 0;

    free(de->extrafield);
    de->extrafield = NULL;
    de->extrafield_len = 0;
    free(de->comment);
    de->comment = NULL;
    de->comment_len = 0;
}



/* _zip_dirent_write(zde, fp, localp, error):
   Writes zip directory entry zde to file fp.

   If localp != 0, it writes a local header instead of a central
   directory entry.

   Returns 0 if successful. On error, error is filled in and -1 is
   returned.
*/

int
_zip_dirent_write(struct zip_dirent *zde, FILE *fp, int localp,
                  struct zip_error *error)
{
    unsigned short dostime, dosdate;

    fwrite(localp ? LOCAL_MAGIC : CENTRAL_MAGIC, 1, 4, fp);

    if (!localp)
        _zip_write2(zde->version_madeby, fp);
    _zip_write2(zde->version_needed, fp);
    _zip_write2(zde->bitflags, fp);
    _zip_write2(zde->comp_method, fp);

    _zip_u2d_time(zde->last_mod, &dostime, &dosdate);
    _zip_write2(dostime, fp);
    _zip_write2(dosdate, fp);

    _zip_write4(zde->crc, fp);
    _zip_write4(zde->comp_size, fp);
    _zip_write4(zde->uncomp_size, fp);

    _zip_write2(zde->filename_len, fp);
    _zip_write2(zde->extrafield_len, fp);

    if (!localp) {
        _zip_write2(zde->comment_len, fp);
        _zip_write2(zde->disk_number, fp);
        _zip_write2(zde->int_attrib, fp);
        _zip_write4(zde->ext_attrib, fp);
        _zip_write4(zde->offset, fp);
    }

    if (zde->filename_len)
        fwrite(zde->filename, 1, zde->filename_len, fp);

    if (zde->extrafield_len)
        fwrite(zde->extrafield, 1, zde->extrafield_len, fp);

    if (!localp) {
        if (zde->comment_len)
            fwrite(zde->comment, 1, zde->comment_len, fp);
    }

    if (ferror(fp)) {
        _zip_error_set(error, ZIP_ER_WRITE, errno);
        return -1;
    }

    return 0;
}



static time_t
_zip_d2u_time(int dtime, int ddate)
{
    struct tm *tm;
    time_t now;

    now = time(NULL);
    tm = localtime(&now);
    /* let mktime decide if DST is in effect */
    tm->tm_isdst = -1;

    tm->tm_year = ((ddate>>9)&127) + 1980 - 1900;
    tm->tm_mon = ((ddate>>5)&15) - 1;
    tm->tm_mday = ddate&31;

    tm->tm_hour = (dtime>>11)&31;
    tm->tm_min = (dtime>>5)&63;
    tm->tm_sec = (dtime<<1)&62;

    return mktime(tm);
}



unsigned short
_zip_read2(unsigned char **a)
{
    unsigned short ret;

    ret = (*a)[0]+((*a)[1]<<8);
    *a += 2;

    return ret;
}



unsigned int
_zip_read4(unsigned char **a)
{
    unsigned int ret;

    ret = ((((((*a)[3]<<8)+(*a)[2])<<8)+(*a)[1])<<8)+(*a)[0];
    *a += 4;

    return ret;
}



static char *
_zip_readfpstr(FILE *fp, unsigned int len, int nulp, struct zip_error *error)
{
    char *r, *o;

    r = (char *)malloc(nulp ? len+1 : len);
    if (!r) {
        _zip_error_set(error, ZIP_ER_MEMORY, 0);
        return NULL;
    }

    if (fread(r, 1, len, fp)<len) {
        free(r);
        _zip_error_set(error, ZIP_ER_READ, errno);
        return NULL;
    }

    if (nulp) {
        /* replace any in-string NUL characters with spaces */
        r[len] = 0;
        for (o=r; o<r+len; o++)
            if (*o == '\0')
                *o = ' ';
    }

    return r;
}



static char *
_zip_readstr(unsigned char **buf, int len, int nulp, struct zip_error *error)
{
    char *r, *o;

    r = (char *)malloc(nulp ? len+1 : len);
    if (!r) {
        _zip_error_set(error, ZIP_ER_MEMORY, 0);
        return NULL;
    }

    memcpy(r, *buf, len);
    *buf += len;

    if (nulp) {
        /* replace any in-string NUL characters with spaces */
        r[len] = 0;
        for (o=r; o<r+len; o++)
            if (*o == '\0')
                *o = ' ';
    }

    return r;
}



static void
_zip_write2(unsigned short i, FILE *fp)
{
    putc(i&0xff, fp);
    putc((i>>8)&0xff, fp);

    return;
}



static void
_zip_write4(unsigned int i, FILE *fp)
{
    putc(i&0xff, fp);
    putc((i>>8)&0xff, fp);
    putc((i>>16)&0xff, fp);
    putc((i>>24)&0xff, fp);

    return;
}



static void
_zip_u2d_time(time_t time, unsigned short *dtime, unsigned short *ddate)
{
    struct tm *tm;

    tm = localtime(&time);
    *ddate = ((tm->tm_year+1900-1980)<<9) + ((tm->tm_mon+1)<<5)
        + tm->tm_mday;
    *dtime = ((tm->tm_hour)<<11) + ((tm->tm_min)<<5)
        + ((tm->tm_sec)>>1);

    return;
}



ZIP_EXTERN int
zip_delete(struct zip *za, int idx)
{
    if (idx < 0 || idx >= za->nentry) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return -1;
    }

    /* allow duplicate file names, because the file will
     * be removed directly afterwards */
    if (_zip_unchange(za, idx, 1) != 0)
        return -1;

    za->entry[idx].state = ZIP_ST_DELETED;

    return 0;
}



ZIP_EXTERN void
zip_error_clear(struct zip *za)
{
    _zip_error_clear(&za->error);
}


ZIP_EXTERN int
zip_add(struct zip *za, const char *name, struct zip_source *source)
{
    if (name == NULL || source == NULL) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return -1;
    }

    return _zip_replace(za, -1, name, source);
}


ZIP_EXTERN int
zip_error_get_sys_type(int ze)
{
    if (ze < 0 || ze >= _zip_nerr_str)
        return 0;

    return _zip_err_type[ze];
}


ZIP_EXTERN void
zip_error_get(struct zip *za, int *zep, int *sep)
{
    _zip_error_get(&za->error, zep, sep);
}


const char * const _zip_err_str[] = {
    "No error",
    "Multi-disk zip archives not supported",
    "Renaming temporary file failed",
    "Closing zip archive failed",
    "Seek error",
    "Read error",
    "Write error",
    "CRC error",
    "Containing zip archive was closed",
    "No such file",
    "File already exists",
    "Can't open file",
    "Failure to create temporary file",
    "Zlib error",
    "Malloc failure",
    "Entry has been changed",
    "Compression method not supported",
    "Premature EOF",
    "Invalid argument",
    "Not a zip archive",
    "Internal error",
    "Zip archive inconsistent",
    "Can't remove file",
    "Entry has been deleted",
};

const int _zip_nerr_str = sizeof(_zip_err_str)/sizeof(_zip_err_str[0]);

#define N ZIP_ET_NONE
#define S ZIP_ET_SYS
#define Z ZIP_ET_ZLIB

const int _zip_err_type[] = {
    N,
    N,
    S,
    S,
    S,
    S,
    S,
    N,
    N,
    N,
    N,
    S,
    S,
    Z,
    N,
    N,
    N,
    N,
    N,
    N,
    N,
    N,
    S,
    N,
};


struct zip_entry *
_zip_entry_new(struct zip *za)
{
    struct zip_entry *ze;
    if (!za) {
        ze = (struct zip_entry *)malloc(sizeof(struct zip_entry));
        if (!ze) {
            _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
            return NULL;
        }
    }
    else {
        if (za->nentry >= za->nentry_alloc-1) {
            za->nentry_alloc += 16;
            za->entry = (struct zip_entry *)realloc(za->entry,
                                                    sizeof(struct zip_entry)
                                                    * za->nentry_alloc);
            if (!za->entry) {
                _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
                return NULL;
            }
        }
        ze = za->entry+za->nentry;
    }

    ze->state = ZIP_ST_UNCHANGED;

    ze->ch_filename = NULL;
    ze->ch_comment = NULL;
    ze->ch_comment_len = -1;
    ze->source = NULL;

    if (za)
        za->nentry++;

    return ze;
}


void
_zip_entry_free(struct zip_entry *ze)
{
    free(ze->ch_filename);
    ze->ch_filename = NULL;
    free(ze->ch_comment);
    ze->ch_comment = NULL;
    ze->ch_comment_len = -1;

    _zip_unchange_data(ze);
}


static int add_data(struct zip *, struct zip_source *, struct zip_dirent *,
                    FILE *);
static int add_data_comp(zip_source_callback, void *, struct zip_stat *,
                         FILE *, struct zip_error *);
static int add_data_uncomp(struct zip *, zip_source_callback, void *,
                           struct zip_stat *, FILE *);
static void ch_set_error(struct zip_error *, zip_source_callback, void *);
static int copy_data(FILE *, myoff_t, FILE *, struct zip_error *);
static int write_cdir(struct zip *, struct zip_cdir *, FILE *);
static int _zip_cdir_set_comment(struct zip_cdir *, struct zip *);
static int _zip_changed(struct zip *, int *);
static char *_zip_create_temp_output(struct zip *, FILE **);
static int _zip_torrentzip_cmp(const void *, const void *);



struct filelist {
    int idx;
    const char *name;
};



ZIP_EXTERN int
zip_close(struct zip *za)
{
    int survivors;
    int i, j, error;
    char *temp;
    FILE *out;
    mode_t mask;
    struct zip_cdir *cd;
    struct zip_dirent de;
    struct filelist *filelist;
    int reopen_on_error;
    int new_torrentzip;

    reopen_on_error = 0;

    if (za == NULL)
        return -1;

    if (!_zip_changed(za, &survivors)) {
        _zip_free(za);
        return 0;
    }

    /* don't create zip files with no entries */
    if (survivors == 0) {
        if (za->zn && za->zp) {
            if (remove(za->zn) != 0) {
                _zip_error_set(&za->error, ZIP_ER_REMOVE, errno);
                return -1;
            }
        }
        _zip_free(za);
        return 0;
    }

    if ((filelist=(struct filelist *)malloc(sizeof(filelist[0])*survivors))
        == NULL)
        return -1;

    if ((cd=_zip_cdir_new(survivors, &za->error)) == NULL) {
        free(filelist);
        return -1;
    }

    for (i=0; i<survivors; i++)
        _zip_dirent_init(&cd->entry[i]);

    /* archive comment is special for torrentzip */
    if (zip_get_archive_flag(za, ZIP_AFL_TORRENT, 0)) {
        cd->comment = _zip_memdup(TORRENT_SIG "XXXXXXXX",
                                  TORRENT_SIG_LEN + TORRENT_CRC_LEN,
                                  &za->error);
        if (cd->comment == NULL) {
            _zip_cdir_free(cd);
            free(filelist);
            return -1;
        }
        cd->comment_len = TORRENT_SIG_LEN + TORRENT_CRC_LEN;
    }
    else if (zip_get_archive_flag(za, ZIP_AFL_TORRENT, ZIP_FL_UNCHANGED) == 0) {
        if (_zip_cdir_set_comment(cd, za) == -1) {
            _zip_cdir_free(cd);
            free(filelist);
            return -1;
        }
    }

    if ((temp=_zip_create_temp_output(za, &out)) == NULL) {
        _zip_cdir_free(cd);
        return -1;
    }


    /* create list of files with index into original archive  */
    for (i=j=0; i<za->nentry; i++) {
        if (za->entry[i].state == ZIP_ST_DELETED)
            continue;

        filelist[j].idx = i;
        filelist[j].name = zip_get_name(za, i, 0);
        j++;
    }
    if (zip_get_archive_flag(za, ZIP_AFL_TORRENT, 0))
        qsort(filelist, survivors, sizeof(filelist[0]),
              _zip_torrentzip_cmp);

    new_torrentzip = (zip_get_archive_flag(za, ZIP_AFL_TORRENT, 0) == 1
                      && zip_get_archive_flag(za, ZIP_AFL_TORRENT,
                                              ZIP_FL_UNCHANGED) == 0);
    error = 0;
    for (j=0; j<survivors; j++) {
        i = filelist[j].idx;

        /* create new local directory entry */
        if (ZIP_ENTRY_DATA_CHANGED(za->entry+i) || new_torrentzip) {
            _zip_dirent_init(&de);

            if (zip_get_archive_flag(za, ZIP_AFL_TORRENT, 0))
                _zip_dirent_torrent_normalize(&de);

            /* use it as central directory entry */
            memcpy(cd->entry+j, &de, sizeof(cd->entry[j]));

            /* set/update file name */
            if (za->entry[i].ch_filename == NULL) {
                if (za->entry[i].state == ZIP_ST_ADDED) {
                    de.filename = strdup("-");
                    de.filename_len = 1;
                    cd->entry[j].filename = "-";
                }
                else {
                    de.filename = strdup(za->cdir->entry[i].filename);
                    de.filename_len = strlen(de.filename);
                    cd->entry[j].filename = za->cdir->entry[i].filename;
                    cd->entry[j].filename_len = de.filename_len;
                }
            }
        }
        else {
            /* copy existing directory entries */
            if (fseeko(za->zp, za->cdir->entry[i].offset, SEEK_SET) != 0) {
                _zip_error_set(&za->error, ZIP_ER_SEEK, errno);
                error = 1;
                break;
            }
            if (_zip_dirent_read(&de, za->zp, NULL, 0, 1, &za->error) != 0) {
                error = 1;
                break;
            }
            if (de.bitflags & ZIP_GPBF_DATA_DESCRIPTOR) {
                de.crc = za->cdir->entry[i].crc;
                de.comp_size = za->cdir->entry[i].comp_size;
                de.uncomp_size = za->cdir->entry[i].uncomp_size;
                de.bitflags &= ~ZIP_GPBF_DATA_DESCRIPTOR;
            }
            memcpy(cd->entry+j, za->cdir->entry+i, sizeof(cd->entry[j]));
        }

        if (za->entry[i].ch_filename) {
            free(de.filename);
            if ((de.filename=strdup(za->entry[i].ch_filename)) == NULL) {
                error = 1;
                break;
            }
            de.filename_len = strlen(de.filename);
            cd->entry[j].filename = za->entry[i].ch_filename;
            cd->entry[j].filename_len = de.filename_len;
        }

        if (zip_get_archive_flag(za, ZIP_AFL_TORRENT, 0) == 0
            && za->entry[i].ch_comment_len != -1) {
            /* as the rest of cd entries, its malloc/free is done by za */
            cd->entry[j].comment = za->entry[i].ch_comment;
            cd->entry[j].comment_len = za->entry[i].ch_comment_len;
        }

        cd->entry[j].offset = ftello(out);

        if (ZIP_ENTRY_DATA_CHANGED(za->entry+i) || new_torrentzip) {
            struct zip_source *zs;

            zs = NULL;
            if (!ZIP_ENTRY_DATA_CHANGED(za->entry+i)) {
                if ((zs=zip_source_zip(za, za, i, ZIP_FL_RECOMPRESS, 0, -1))
                    == NULL) {
                    error = 1;
                    break;
                }
            }

            if (add_data(za, zs ? zs : za->entry[i].source, &de, out) < 0) {
                error = 1;
                break;
            }
            cd->entry[j].last_mod = de.last_mod;
            cd->entry[j].comp_method = de.comp_method;
            cd->entry[j].comp_size = de.comp_size;
            cd->entry[j].uncomp_size = de.uncomp_size;
            cd->entry[j].crc = de.crc;
        }
        else {
            if (_zip_dirent_write(&de, out, 1, &za->error) < 0) {
                error = 1;
                break;
            }
            /* we just read the local dirent, file is at correct position */
            if (copy_data(za->zp, cd->entry[j].comp_size, out,
                          &za->error) < 0) {
                error = 1;
                break;
            }
        }

        _zip_dirent_finalize(&de);
    }

    if (!error) {
        if (write_cdir(za, cd, out) < 0)
            error = 1;
    }

    /* pointers in cd entries are owned by za */
    cd->nentry = 0;
    _zip_cdir_free(cd);

    if (error) {
        _zip_dirent_finalize(&de);
        fclose(out);
        remove(temp);
        free(temp);
        return -1;
    }

    if (fclose(out) != 0) {
        _zip_error_set(&za->error, ZIP_ER_CLOSE, errno);
        remove(temp);
        free(temp);
        return -1;
    }

    if (za->zp) {
        fclose(za->zp);
        za->zp = NULL;
        reopen_on_error = 1;
    }
    if (_zip_rename(temp, za->zn) != 0) {
        _zip_error_set(&za->error, ZIP_ER_RENAME, errno);
        remove(temp);
        free(temp);
        if (reopen_on_error) {
            /* ignore errors, since we're already in an error case */
            za->zp = fopen(za->zn, "rb");
        }
        return -1;
    }
    mask = umask(0);
    umask(mask);
    chmod(za->zn, 0666&~mask);

    _zip_free(za);
    free(temp);

    return 0;
}



static int
add_data(struct zip *za, struct zip_source *zs, struct zip_dirent *de, FILE *ft)
{
    myoff_t offstart, offend;
    zip_source_callback cb;
    void *ud;
    struct zip_stat st;

    cb = zs->f;
    ud = zs->ud;

    if (cb(ud, &st, sizeof(st), ZIP_SOURCE_STAT) < (ssize_t)sizeof(st)) {
        ch_set_error(&za->error, cb, ud);
        return -1;
    }

    if (cb(ud, NULL, 0, ZIP_SOURCE_OPEN) < 0) {
        ch_set_error(&za->error, cb, ud);
        return -1;
    }

    offstart = ftello(ft);

    if (_zip_dirent_write(de, ft, 1, &za->error) < 0)
        return -1;

    if (st.comp_method != ZIP_CM_STORE) {
        if (add_data_comp(cb, ud, &st, ft, &za->error) < 0)
            return -1;
    }
    else {
        if (add_data_uncomp(za, cb, ud, &st, ft) < 0)
            return -1;
    }

    if (cb(ud, NULL, 0, ZIP_SOURCE_CLOSE) < 0) {
        ch_set_error(&za->error, cb, ud);
        return -1;
    }

    offend = ftello(ft);

    if (fseeko(ft, offstart, SEEK_SET) < 0) {
        _zip_error_set(&za->error, ZIP_ER_SEEK, errno);
        return -1;
    }


    de->last_mod = st.mtime;
    de->comp_method = st.comp_method;
    de->crc = st.crc;
    de->uncomp_size = st.size;
    de->comp_size = st.comp_size;

    if (zip_get_archive_flag(za, ZIP_AFL_TORRENT, 0))
        _zip_dirent_torrent_normalize(de);

    if (_zip_dirent_write(de, ft, 1, &za->error) < 0)
        return -1;

    if (fseeko(ft, offend, SEEK_SET) < 0) {
        _zip_error_set(&za->error, ZIP_ER_SEEK, errno);
        return -1;
    }

    return 0;
}



static int
add_data_comp(zip_source_callback cb, void *ud, struct zip_stat *st,FILE *ft,
              struct zip_error *error)
{
    char buf[BUFSIZE];
    ssize_t n;

    st->comp_size = 0;
    while ((n=cb(ud, buf, sizeof(buf), ZIP_SOURCE_READ)) > 0) {
        if (fwrite(buf, 1, n, ft) != (size_t)n) {
            _zip_error_set(error, ZIP_ER_WRITE, errno);
            return -1;
        }

        st->comp_size += n;
    }
    if (n < 0) {
        ch_set_error(error, cb, ud);
        return -1;
    }

    return 0;
}



static int
add_data_uncomp(struct zip *za, zip_source_callback cb, void *ud,
                struct zip_stat *st, FILE *ft)
{
    char b1[BUFSIZE], b2[BUFSIZE];
    int end, flush, ret;
    ssize_t n;
    size_t n2;
    z_stream zstr;
    int mem_level;

    st->comp_method = ZIP_CM_DEFLATE;
    st->comp_size = st->size = 0;
    st->crc = crc32(0, NULL, 0);

    zstr.zalloc = Z_NULL;
    zstr.zfree = Z_NULL;
    zstr.opaque = NULL;
    zstr.avail_in = 0;
    zstr.avail_out = 0;

    if (zip_get_archive_flag(za, ZIP_AFL_TORRENT, 0))
        mem_level = TORRENT_MEM_LEVEL;
    else
        mem_level = MAX_MEM_LEVEL;

    /* -MAX_WBITS: undocumented feature of zlib to _not_ write a zlib header */
    deflateInit2(&zstr, Z_BEST_COMPRESSION, Z_DEFLATED, -MAX_WBITS, mem_level,
                 Z_DEFAULT_STRATEGY);

    zstr.next_out = (Bytef *)b2;
    zstr.avail_out = sizeof(b2);
    zstr.avail_in = 0;

    flush = 0;
    end = 0;
    while (!end) {
        if (zstr.avail_in == 0 && !flush) {
            if ((n=cb(ud, b1, sizeof(b1), ZIP_SOURCE_READ)) < 0) {
                ch_set_error(&za->error, cb, ud);
                deflateEnd(&zstr);
                return -1;
            }
            if (n > 0) {
                zstr.avail_in = n;
                zstr.next_in = (Bytef *)b1;
                st->size += n;
                st->crc = crc32(st->crc, (Bytef *)b1, n);
            }
            else
                flush = Z_FINISH;
        }

        ret = deflate(&zstr, flush);
        if (ret != Z_OK && ret != Z_STREAM_END) {
            _zip_error_set(&za->error, ZIP_ER_ZLIB, ret);
            return -1;
        }

        if (zstr.avail_out != sizeof(b2)) {
            n2 = sizeof(b2) - zstr.avail_out;

            if (fwrite(b2, 1, n2, ft) != n2) {
                _zip_error_set(&za->error, ZIP_ER_WRITE, errno);
                return -1;
            }

            zstr.next_out = (Bytef *)b2;
            zstr.avail_out = sizeof(b2);
            st->comp_size += n2;
        }

        if (ret == Z_STREAM_END) {
            deflateEnd(&zstr);
            end = 1;
        }
    }

    return 0;
}



static void
ch_set_error(struct zip_error *error, zip_source_callback cb, void *ud)
{
    int e[2];

    if ((cb(ud, e, sizeof(e), ZIP_SOURCE_ERROR)) < (ssize_t)sizeof(e)) {
        error->zip_err = ZIP_ER_INTERNAL;
        error->sys_err = 0;
    }
    else {
        error->zip_err = e[0];
        error->sys_err = e[1];
    }
}



static int
copy_data(FILE *fs, myoff_t len, FILE *ft, struct zip_error *error)
{
    char buf[BUFSIZE];
    int n, nn;

    if (len == 0)
        return 0;

    while (len > 0) {
        nn = len > sizeof(buf) ? sizeof(buf) : len;
        if ((n=fread(buf, 1, nn, fs)) < 0) {
            _zip_error_set(error, ZIP_ER_READ, errno);
            return -1;
        }
        else if (n == 0) {
            _zip_error_set(error, ZIP_ER_EOF, 0);
            return -1;
        }

        if (fwrite(buf, 1, n, ft) != (size_t)n) {
            _zip_error_set(error, ZIP_ER_WRITE, errno);
            return -1;
        }

        len -= n;
    }

    return 0;
}



static int
write_cdir(struct zip *za, struct zip_cdir *cd, FILE *out)
{
    myoff_t offset;
    uLong crc;
    char buf[TORRENT_CRC_LEN+1];

    if (_zip_cdir_write(cd, out, &za->error) < 0)
        return -1;

    if (zip_get_archive_flag(za, ZIP_AFL_TORRENT, 0) == 0)
        return 0;


    /* fix up torrentzip comment */

    offset = ftello(out);

    if (_zip_filerange_crc(out, cd->offset, cd->size, &crc, &za->error) < 0)
        return -1;

    snprintf(buf, sizeof(buf), "%08lX", (long)crc);

    if (fseeko(out, offset-TORRENT_CRC_LEN, SEEK_SET) < 0) {
        _zip_error_set(&za->error, ZIP_ER_SEEK, errno);
        return -1;
    }

    if (fwrite(buf, TORRENT_CRC_LEN, 1, out) != 1) {
        _zip_error_set(&za->error, ZIP_ER_WRITE, errno);
        return -1;
    }

    return 0;
}



static int
_zip_cdir_set_comment(struct zip_cdir *dest, struct zip *src)
{
    if (src->ch_comment_len != -1) {
        dest->comment = _zip_memdup(src->ch_comment,
                                    src->ch_comment_len, &src->error);
        if (dest->comment == NULL)
            return -1;
        dest->comment_len = src->ch_comment_len;
    } else {
        if (src->cdir && src->cdir->comment) {
            dest->comment = _zip_memdup(src->cdir->comment,
                                        src->cdir->comment_len, &src->error);
            if (dest->comment == NULL)
                return -1;
            dest->comment_len = src->cdir->comment_len;
        }
    }

    return 0;
}



static int
_zip_changed(struct zip *za, int *survivorsp)
{
    int changed, i, survivors;

    changed = survivors = 0;

    if (za->ch_comment_len != -1
        || za->ch_flags != za->flags)
        changed = 1;

    for (i=0; i<za->nentry; i++) {
        if ((za->entry[i].state != ZIP_ST_UNCHANGED)
            || (za->entry[i].ch_comment_len != -1))
            changed = 1;
        if (za->entry[i].state != ZIP_ST_DELETED)
            survivors++;
    }

    *survivorsp = survivors;

    return changed;
}



static char *
_zip_create_temp_output(struct zip *za, FILE **outp)
{
    char *temp;
    int tfd;
    FILE *tfp;

    if ((temp=(char *)malloc(strlen(za->zn)+8)) == NULL) {
        _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
        return NULL;
    }

    sprintf(temp, "%s.XXXXXX", za->zn);

    if ((tfd=mkstemp(temp)) == -1) {
        _zip_error_set(&za->error, ZIP_ER_TMPOPEN, errno);
        free(temp);
        return NULL;
    }

    if ((tfp=fdopen(tfd, "r+b")) == NULL) {
        _zip_error_set(&za->error, ZIP_ER_TMPOPEN, errno);
        close(tfd);
        remove(temp);
        free(temp);
        return NULL;
    }

    *outp = tfp;
    return temp;
}



static int
_zip_torrentzip_cmp(const void *a, const void *b)
{
    return strcasecmp(((const struct filelist *)a)->name,
                      ((const struct filelist *)b)->name);
}



ZIP_EXTERN int
zip_add_dir(struct zip *za, const char *name)
{
    int len, ret;
    char *s;
    struct zip_source *source;

    if (name == NULL) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return -1;
    }

    s = NULL;
    len = strlen(name);

    if (name[len-1] != '/') {
        if ((s=(char *)malloc(len+2)) == NULL) {
            _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
            return -1;
        }
        strcpy(s, name);
        s[len] = '/';
        s[len+1] = '\0';
    }

    if ((source=zip_source_buffer(za, NULL, 0, 0)) == NULL) {
        free(s);
        return -1;
    }

    ret = _zip_replace(za, -1, s ? s : name, source);

    free(s);
    if (ret < 0)
        zip_source_free(source);

    return ret;
}


ZIP_EXTERN int
zip_error_to_str(char *buf, size_t len, int ze, int se)
{
    const char *zs, *ss;

    if (ze < 0 || ze >= _zip_nerr_str)
        return snprintf(buf, len, "Unknown error %d", ze);

    zs = _zip_err_str[ze];

    switch (_zip_err_type[ze]) {
    case ZIP_ET_SYS:
        ss = strerror(se);
        break;

    case ZIP_ET_ZLIB:
        ss = zError(se);
        break;

    default:
        ss = NULL;
    }

    return snprintf(buf, len, "%s%s%s",
                    zs, (ss ? ": " : ""), (ss ? ss : ""));
}


ZIP_EXTERN void
zip_file_error_clear(struct zip_file *zf)
{
    _zip_error_clear(&zf->error);
}


ZIP_EXTERN int
zip_fclose(struct zip_file *zf)
{
    int i, ret;

    if (zf->zstr)
        inflateEnd(zf->zstr);
    free(zf->buffer);
    free(zf->zstr);

    for (i=0; i<zf->za->nfile; i++) {
        if (zf->za->file[i] == zf) {
            zf->za->file[i] = zf->za->file[zf->za->nfile-1];
            zf->za->nfile--;
            break;
        }
    }

    ret = 0;
    if (zf->error.zip_err)
        ret = zf->error.zip_err;
    else if ((zf->flags & ZIP_ZF_CRC) && (zf->flags & ZIP_ZF_EOF)) {
        /* if EOF, compare CRC */
        if (zf->crc_orig != zf->crc)
            ret = ZIP_ER_CRC;
    }

    free(zf);
    return ret;
}


int
_zip_filerange_crc(FILE *fp, myoff_t start, myoff_t len, uLong *crcp,
                   struct zip_error *errp)
{
    Bytef buf[BUFSIZE];
    size_t n;

    *crcp = crc32(0L, Z_NULL, 0);

    if (fseeko(fp, start, SEEK_SET) != 0) {
        _zip_error_set(errp, ZIP_ER_SEEK, errno);
        return -1;
    }

    while (len > 0) {
        n = len > BUFSIZE ? BUFSIZE : len;
        if ((n=fread(buf, 1, n, fp)) <= 0) {
            _zip_error_set(errp, ZIP_ER_READ, errno);
            return -1;
        }

        *crcp = crc32(*crcp, buf, n);

        len-= n;
    }

    return 0;
}


ZIP_EXTERN const char *
zip_file_strerror(struct zip_file *zf)
{
    return _zip_error_strerror(&zf->error);
}


/* _zip_file_get_offset(za, ze):
   Returns the offset of the file data for entry ze.

   On error, fills in za->error and returns 0.
*/

unsigned int
_zip_file_get_offset(struct zip *za, int idx)
{
    struct zip_dirent de;
    unsigned int offset;

    offset = za->cdir->entry[idx].offset;

    if (fseeko(za->zp, offset, SEEK_SET) != 0) {
        _zip_error_set(&za->error, ZIP_ER_SEEK, errno);
        return 0;
    }

    if (_zip_dirent_read(&de, za->zp, NULL, 0, 1, &za->error) != 0)
        return 0;

    offset += LENTRYSIZE + de.filename_len + de.extrafield_len;

    _zip_dirent_finalize(&de);

    return offset;
}


ZIP_EXTERN void
zip_file_error_get(struct zip_file *zf, int *zep, int *sep)
{
    _zip_error_get(&zf->error, zep, sep);
}


static struct zip_file *_zip_file_new(struct zip *za);



ZIP_EXTERN struct zip_file *
zip_fopen_index(struct zip *za, int fileno, int flags)
{
    int len, ret;
    int zfflags;
    struct zip_file *zf;

    if ((fileno < 0) || (fileno >= za->nentry)) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return NULL;
    }

    if ((flags & ZIP_FL_UNCHANGED) == 0
        && ZIP_ENTRY_DATA_CHANGED(za->entry+fileno)) {
        _zip_error_set(&za->error, ZIP_ER_CHANGED, 0);
        return NULL;
    }

    if (fileno >= za->cdir->nentry) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return NULL;
    }

    zfflags = 0;
    switch (za->cdir->entry[fileno].comp_method) {
    case ZIP_CM_STORE:
        zfflags |= ZIP_ZF_CRC;
        break;

    case ZIP_CM_DEFLATE:
        if ((flags & ZIP_FL_COMPRESSED) == 0)
            zfflags |= ZIP_ZF_CRC | ZIP_ZF_DECOMP;
        break;
    default:
        if ((flags & ZIP_FL_COMPRESSED) == 0) {
            _zip_error_set(&za->error, ZIP_ER_COMPNOTSUPP, 0);
            return NULL;
        }
        break;
    }

    zf = _zip_file_new(za);

    zf->flags = zfflags;
    /* zf->name = za->cdir->entry[fileno].filename; */
    zf->method = za->cdir->entry[fileno].comp_method;
    zf->bytes_left = za->cdir->entry[fileno].uncomp_size;
    zf->cbytes_left = za->cdir->entry[fileno].comp_size;
    zf->crc_orig = za->cdir->entry[fileno].crc;

    if ((zf->fpos=_zip_file_get_offset(za, fileno)) == 0) {
        zip_fclose(zf);
        return NULL;
    }

    if ((zf->flags & ZIP_ZF_DECOMP) == 0)
        zf->bytes_left = zf->cbytes_left;
    else {
        if ((zf->buffer=(char *)malloc(BUFSIZE)) == NULL) {
            _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
            zip_fclose(zf);
            return NULL;
        }

        len = _zip_file_fillbuf(zf->buffer, BUFSIZE, zf);
        if (len <= 0) {
            _zip_error_copy(&za->error, &zf->error);
            zip_fclose(zf);
        return NULL;
        }

        if ((zf->zstr = (z_stream *)malloc(sizeof(z_stream))) == NULL) {
            _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
            zip_fclose(zf);
            return NULL;
        }
        zf->zstr->zalloc = Z_NULL;
        zf->zstr->zfree = Z_NULL;
        zf->zstr->opaque = NULL;
        zf->zstr->next_in = (Bytef *)zf->buffer;
        zf->zstr->avail_in = len;

        /* negative value to tell zlib that there is no header */
        if ((ret=inflateInit2(zf->zstr, -MAX_WBITS)) != Z_OK) {
            _zip_error_set(&za->error, ZIP_ER_ZLIB, ret);
            zip_fclose(zf);
            return NULL;
        }
    }

    return zf;
}



int
_zip_file_fillbuf(void *buf, size_t buflen, struct zip_file *zf)
{
    int i, j;

    if (zf->error.zip_err != ZIP_ER_OK)
        return -1;

    if ((zf->flags & ZIP_ZF_EOF) || zf->cbytes_left <= 0 || buflen <= 0)
        return 0;

    if (fseeko(zf->za->zp, zf->fpos, SEEK_SET) < 0) {
        _zip_error_set(&zf->error, ZIP_ER_SEEK, errno);
        return -1;
    }
    if (buflen < zf->cbytes_left)
        i = buflen;
    else
        i = zf->cbytes_left;

    j = fread(buf, 1, i, zf->za->zp);
    if (j == 0) {
        _zip_error_set(&zf->error, ZIP_ER_EOF, 0);
        j = -1;
    }
    else if (j < 0)
        _zip_error_set(&zf->error, ZIP_ER_READ, errno);
    else {
        zf->fpos += j;
        zf->cbytes_left -= j;
    }

    return j;
}



static struct zip_file *
_zip_file_new(struct zip *za)
{
    struct zip_file *zf, **file;
    int n;

    if ((zf=(struct zip_file *)malloc(sizeof(struct zip_file))) == NULL) {
        _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
        return NULL;
    }

    if (za->nfile >= za->nfile_alloc-1) {
        n = za->nfile_alloc + 10;
        file = (struct zip_file **)realloc(za->file,
                                           n*sizeof(struct zip_file *));
        if (file == NULL) {
            _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
            free(zf);
            return NULL;
        }
        za->nfile_alloc = n;
        za->file = file;
    }

    za->file[za->nfile++] = zf;

    zf->za = za;
    _zip_error_init(&zf->error);
    zf->flags = 0;
    zf->crc = crc32(0L, Z_NULL, 0);
    zf->crc_orig = 0;
    zf->method = -1;
    zf->bytes_left = zf->cbytes_left = 0;
    zf->fpos = 0;
    zf->buffer = NULL;
    zf->zstr = NULL;

    return zf;
}


ZIP_EXTERN struct zip_file *
zip_fopen(struct zip *za, const char *fname, int flags)
{
    int idx;

    if ((idx=zip_name_locate(za, fname, flags)) < 0)
        return NULL;

    return zip_fopen_index(za, idx, flags);
}


ZIP_EXTERN int
zip_set_file_comment(struct zip *za, int idx, const char *comment, int len)
{
    char *tmpcom;

    if (idx < 0 || idx >= za->nentry
        || len < 0 || len > MAXCOMLEN
        || (len > 0 && comment == NULL)) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return -1;
    }

    if (len > 0) {
        if ((tmpcom=(char *)_zip_memdup(comment, len, &za->error)) == NULL)
            return -1;
    }
    else
        tmpcom = NULL;

    free(za->entry[idx].ch_comment);
    za->entry[idx].ch_comment = tmpcom;
    za->entry[idx].ch_comment_len = len;

    return 0;
}


ZIP_EXTERN struct zip_source *
zip_source_file(struct zip *za, const char *fname, myoff_t start, myoff_t len)
{
    if (za == NULL)
        return NULL;

    if (fname == NULL || start < 0 || len < -1) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return NULL;
    }

    return _zip_source_file_or_p(za, fname, NULL, start, len);
}


struct read_data {
    const char *buf, *data, *end;
    time_t mtime;
    int freep;
};

static ssize_t read_data(void *state, void *data, size_t len,
                         enum zip_source_cmd cmd);



ZIP_EXTERN struct zip_source *
zip_source_buffer(struct zip *za, const void *data, myoff_t len, int freep)
{
    struct read_data *f;
    struct zip_source *zs;

    if (za == NULL)
        return NULL;

    if (len < 0 || (data == NULL && len > 0)) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return NULL;
    }

    if ((f=(struct read_data *)malloc(sizeof(*f))) == NULL) {
        _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
        return NULL;
    }

    f->data = (const char *)data;
    f->end = ((const char *)data)+len;
    f->freep = freep;
    f->mtime = time(NULL);

    if ((zs=zip_source_function(za, read_data, f)) == NULL) {
        free(f);
        return NULL;
    }

    return zs;
}



static ssize_t
read_data(void *state, void *data, size_t len, enum zip_source_cmd cmd)
{
    struct read_data *z;
    char *buf;
    size_t n;

    z = (struct read_data *)state;
    buf = (char *)data;

    switch (cmd) {
    case ZIP_SOURCE_OPEN:
        z->buf = z->data;
        return 0;

    case ZIP_SOURCE_READ:
        n = z->end - z->buf;
        if (n > len)
            n = len;

        if (n) {
            memcpy(buf, z->buf, n);
            z->buf += n;
        }

        return n;

    case ZIP_SOURCE_CLOSE:
        return 0;

    case ZIP_SOURCE_STAT:
        {
            struct zip_stat *st;

            if (len < sizeof(*st))
                return -1;

            st = (struct zip_stat *)data;

            zip_stat_init(st);
            st->mtime = z->mtime;
            st->size = z->end - z->data;

            return sizeof(*st);
        }

    case ZIP_SOURCE_ERROR:
        {
            int *e;

            if (len < sizeof(int)*2)
                return -1;

            e = (int *)data;
            e[0] = e[1] = 0;
        }
        return sizeof(int)*2;

    case ZIP_SOURCE_FREE:
        if (z->freep) {
            free((void *)z->data);
            z->data = NULL;
        }
        free(z);
        return 0;

    default:
        ;
    }

    return -1;
}


int
_zip_set_name(struct zip *za, int idx, const char *name)
{
    char *s;
    int i;

    if (idx < 0 || idx >= za->nentry || name == NULL) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return -1;
    }

    if ((i=_zip_name_locate(za, name, 0, NULL)) != -1 && i != idx) {
        _zip_error_set(&za->error, ZIP_ER_EXISTS, 0);
        return -1;
    }

    /* no effective name change */
    if (i == idx)
        return 0;

    if ((s=strdup(name)) == NULL) {
        _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
        return -1;
    }

    if (za->entry[idx].state == ZIP_ST_UNCHANGED)
        za->entry[idx].state = ZIP_ST_RENAMED;

    free(za->entry[idx].ch_filename);
    za->entry[idx].ch_filename = s;

    return 0;
}


ZIP_EXTERN int
zip_set_archive_flag(struct zip *za, int flag, int value)
{
    if (value)
        za->ch_flags |= flag;
    else
        za->ch_flags &= ~flag;

    return 0;
}


void
_zip_unchange_data(struct zip_entry *ze)
{
    if (ze->source) {
        (void)ze->source->f(ze->source->ud, NULL, 0, ZIP_SOURCE_FREE);
        free(ze->source);
        ze->source = NULL;
    }

    ze->state = ze->ch_filename ? ZIP_ST_RENAMED : ZIP_ST_UNCHANGED;
}


ZIP_EXTERN int
zip_unchange_archive(struct zip *za)
{
    free(za->ch_comment);
    za->ch_comment = NULL;
    za->ch_comment_len = -1;

    za->ch_flags = za->flags;

    return 0;
}

ZIP_EXTERN int
zip_unchange(struct zip *za, int idx)
{
    return _zip_unchange(za, idx, 0);
}



int
_zip_unchange(struct zip *za, int idx, int allow_duplicates)
{
    int i;

    if (idx < 0 || idx >= za->nentry) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return -1;
    }

    if (za->entry[idx].ch_filename) {
        if (!allow_duplicates) {
            i = _zip_name_locate(za,
                         _zip_get_name(za, idx, ZIP_FL_UNCHANGED, NULL),
                                 0, NULL);
            if (i != -1 && i != idx) {
                _zip_error_set(&za->error, ZIP_ER_EXISTS, 0);
                return -1;
            }
        }

        free(za->entry[idx].ch_filename);
        za->entry[idx].ch_filename = NULL;
    }

    free(za->entry[idx].ch_comment);
    za->entry[idx].ch_comment = NULL;
    za->entry[idx].ch_comment_len = -1;

    _zip_unchange_data(za->entry+idx);

    return 0;
}

ZIP_EXTERN int
zip_unchange_all(struct zip *za)
{
    int ret, i;

    ret = 0;
    for (i=0; i<za->nentry; i++)
        ret |= _zip_unchange(za, i, 1);

    ret |= zip_unchange_archive(za);

    return ret;
}


ZIP_EXTERN int
zip_set_archive_comment(struct zip *za, const char *comment, int len)
{
    char *tmpcom;

    if (len < 0 || len > MAXCOMLEN
        || (len > 0 && comment == NULL)) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return -1;
    }

    if (len > 0) {
        if ((tmpcom=(char *)_zip_memdup(comment, len, &za->error)) == NULL)
            return -1;
    }
    else
        tmpcom = NULL;

    free(za->ch_comment);
    za->ch_comment = tmpcom;
    za->ch_comment_len = len;

    return 0;
}


ZIP_EXTERN int
zip_replace(struct zip *za, int idx, struct zip_source *source)
{
    if (idx < 0 || idx >= za->nentry || source == NULL) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return -1;
    }

    if (_zip_replace(za, idx, NULL, source) == -1)
        return -1;

    return 0;
}




int
_zip_replace(struct zip *za, int idx, const char *name,
             struct zip_source *source)
{
    if (idx == -1) {
        if (_zip_entry_new(za) == NULL)
            return -1;

        idx = za->nentry - 1;
    }

    _zip_unchange_data(za->entry+idx);

    if (name && _zip_set_name(za, idx, name) != 0)
        return -1;

    za->entry[idx].state = ((za->cdir == NULL || idx >= za->cdir->nentry)
                            ? ZIP_ST_ADDED : ZIP_ST_REPLACED);
    za->entry[idx].source = source;

    return idx;
}


ZIP_EXTERN int
zip_rename(struct zip *za, int idx, const char *name)
{
    const char *old_name;
    int old_is_dir, new_is_dir;

    if (idx >= za->nentry || idx < 0 || name[0] == '\0') {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return -1;
    }

    if ((old_name=zip_get_name(za, idx, 0)) == NULL)
        return -1;

    new_is_dir = (name[strlen(name)-1] == '/');
    old_is_dir = (old_name[strlen(old_name)-1] == '/');

    if (new_is_dir != old_is_dir) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return -1;
    }

    return _zip_set_name(za, idx, name);
}

#include <sys/stat.h>
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void set_error(int *, struct zip_error *, int);
static struct zip *_zip_allocate_new(const char *, int *);
static int _zip_checkcons(FILE *, struct zip_cdir *, struct zip_error *);
static void _zip_check_torrentzip(struct zip *);
static struct zip_cdir *_zip_find_central_dir(FILE *, int, int *, myoff_t);
static int _zip_file_exists(const char *, int, int *);
static int _zip_headercomp(struct zip_dirent *, int,
                           struct zip_dirent *, int);
static unsigned char *_zip_memmem(const unsigned char *, int,
                                  const unsigned char *, int);
static struct zip_cdir *_zip_readcdir(FILE *, unsigned char *, unsigned char *,
                                 int, int, struct zip_error *);



ZIP_EXTERN struct zip *
zip_open(const char *fn, int flags, int *zep)
{
    FILE *fp;
    struct zip *za;
    struct zip_cdir *cdir;
    int i;
    myoff_t len;

    switch (_zip_file_exists(fn, flags, zep)) {
    case -1:
        return NULL;
    case 0:
        return _zip_allocate_new(fn, zep);
    default:
        break;
    }

    if ((fp=fopen(fn, "rb")) == NULL) {
        set_error(zep, NULL, ZIP_ER_OPEN);
        return NULL;
    }

    fseeko(fp, 0, SEEK_END);
    len = ftello(fp);

    /* treat empty files as empty archives */
    if (len == 0) {
        if ((za=_zip_allocate_new(fn, zep)) == NULL)
            fclose(fp);
        else
            za->zp = fp;
        return za;
    }

    cdir = _zip_find_central_dir(fp, flags, zep, len);
    if (cdir == NULL) {
        fclose(fp);
        return NULL;
    }

    if ((za=_zip_allocate_new(fn, zep)) == NULL) {
        _zip_cdir_free(cdir);
        fclose(fp);
        return NULL;
    }

    za->cdir = cdir;
    za->zp = fp;

    if ((za->entry=(struct zip_entry *)malloc(sizeof(*(za->entry))
                                              * cdir->nentry)) == NULL) {
        set_error(zep, NULL, ZIP_ER_MEMORY);
        _zip_free(za);
        return NULL;
    }
    for (i=0; i<cdir->nentry; i++)
        _zip_entry_new(za);

    _zip_check_torrentzip(za);
    za->ch_flags = za->flags;

    return za;
}



static void
set_error(int *zep, struct zip_error *err, int ze)
{
    int se;

    if (err) {
        _zip_error_get(err, &ze, &se);
        if (zip_error_get_sys_type(ze) == ZIP_ET_SYS)
            errno = se;
    }

    if (zep)
        *zep = ze;
}



/* _zip_readcdir:
   tries to find a valid end-of-central-directory at the beginning of
   buf, and then the corresponding central directory entries.
   Returns a struct zip_cdir which contains the central directory
   entries, or NULL if unsuccessful. */

static struct zip_cdir *
_zip_readcdir(FILE *fp, unsigned char *buf, unsigned char *eocd, int buflen,
              int flags, struct zip_error *error)
{
    struct zip_cdir *cd;
    unsigned char *cdp, **bufp;
    int i, comlen, nentry;

    comlen = buf + buflen - eocd - EOCDLEN;
    if (comlen < 0) {
        /* not enough bytes left for comment */
        _zip_error_set(error, ZIP_ER_NOZIP, 0);
        return NULL;
    }

    /* check for end-of-central-dir magic */
    if (memcmp(eocd, EOCD_MAGIC, 4) != 0) {
        _zip_error_set(error, ZIP_ER_NOZIP, 0);
        return NULL;
    }

    if (memcmp(eocd+4, "\0\0\0\0", 4) != 0) {
        _zip_error_set(error, ZIP_ER_MULTIDISK, 0);
        return NULL;
    }

    cdp = eocd + 8;
    /* number of cdir-entries on this disk */
    i = _zip_read2(&cdp);
    /* number of cdir-entries */
    nentry = _zip_read2(&cdp);

    if ((cd=_zip_cdir_new(nentry, error)) == NULL)
        return NULL;

    cd->size = _zip_read4(&cdp);
    cd->offset = _zip_read4(&cdp);
    cd->comment = NULL;
    cd->comment_len = _zip_read2(&cdp);

    if ((comlen < cd->comment_len) || (cd->nentry != i)) {
        _zip_error_set(error, ZIP_ER_NOZIP, 0);
        free(cd);
        return NULL;
    }
    if ((flags & ZIP_CHECKCONS) && comlen != cd->comment_len) {
        _zip_error_set(error, ZIP_ER_INCONS, 0);
        free(cd);
        return NULL;
    }

    if (cd->comment_len) {
        if ((cd->comment=(char *)_zip_memdup(eocd+EOCDLEN,
                                             cd->comment_len, error))
            == NULL) {
            free(cd);
            return NULL;
        }
    }

    cdp = eocd;
    if (cd->size < (unsigned int)(eocd-buf)) {
        /* if buffer already read in, use it */
        cdp = eocd - cd->size;
        bufp = &cdp;
    }
    else {
        /* go to start of cdir and read it entry by entry */
        bufp = NULL;
        clearerr(fp);
        fseeko(fp, cd->offset, SEEK_SET);
        /* possible consistency check: cd->offset =
           len-(cd->size+cd->comment_len+EOCDLEN) ? */
        if (ferror(fp) || ((unsigned long)ftello(fp) != cd->offset)) {
            /* seek error or offset of cdir wrong */
            if (ferror(fp))
                _zip_error_set(error, ZIP_ER_SEEK, errno);
            else
                _zip_error_set(error, ZIP_ER_NOZIP, 0);
            free(cd);
            return NULL;
        }
    }

    for (i=0; i<cd->nentry; i++) {
        if ((_zip_dirent_read(cd->entry+i, fp, bufp, eocd-cdp, 0,
                              error)) < 0) {
            cd->nentry = i;
            _zip_cdir_free(cd);
            return NULL;
        }
    }

    return cd;
}



/* _zip_checkcons:
   Checks the consistency of the central directory by comparing central
   directory entries with local headers and checking for plausible
   file and header offsets. Returns -1 if not plausible, else the
   difference between the lowest and the highest fileposition reached */

static int
_zip_checkcons(FILE *fp, struct zip_cdir *cd, struct zip_error *error)
{
    int i;
    unsigned int min, max, j;
    struct zip_dirent temp;

    if (cd->nentry) {
        max = cd->entry[0].offset;
        min = cd->entry[0].offset;
    }
    else
        min = max = 0;

    for (i=0; i<cd->nentry; i++) {
        if (cd->entry[i].offset < min)
            min = cd->entry[i].offset;
        if (min > cd->offset) {
            _zip_error_set(error, ZIP_ER_NOZIP, 0);
            return -1;
        }

        j = cd->entry[i].offset + cd->entry[i].comp_size
            + cd->entry[i].filename_len + LENTRYSIZE;
        if (j > max)
            max = j;
        if (max > cd->offset) {
            _zip_error_set(error, ZIP_ER_NOZIP, 0);
            return -1;
        }

        if (fseeko(fp, cd->entry[i].offset, SEEK_SET) != 0) {
            _zip_error_set(error, ZIP_ER_SEEK, 0);
            return -1;
        }

        if (_zip_dirent_read(&temp, fp, NULL, 0, 1, error) == -1)
            return -1;

        if (_zip_headercomp(cd->entry+i, 0, &temp, 1) != 0) {
            _zip_error_set(error, ZIP_ER_INCONS, 0);
            _zip_dirent_finalize(&temp);
            return -1;
        }
        _zip_dirent_finalize(&temp);
    }

    return max - min;
}



/* _zip_check_torrentzip:
   check wether ZA has a valid TORRENTZIP comment, i.e. is torrentzipped */

static void
_zip_check_torrentzip(struct zip *za)
{
    uLong crc_got, crc_should;
    char buf[8+1];
    char *end;

    if (za->zp == NULL || za->cdir == NULL)
        return;

    if (za->cdir->comment_len != TORRENT_SIG_LEN+8
        || strncmp(za->cdir->comment, TORRENT_SIG, TORRENT_SIG_LEN) != 0)
        return;

    memcpy(buf, za->cdir->comment+TORRENT_SIG_LEN, 8);
    buf[8] = '\0';
    errno = 0;
    crc_should = strtoul(buf, &end, 16);
    if ((crc_should == UINT_MAX && errno != 0) || (end && *end))
        return;

    if (_zip_filerange_crc(za->zp, za->cdir->offset, za->cdir->size,
                           &crc_got, NULL) < 0)
        return;

    if (crc_got == crc_should)
        za->flags |= ZIP_AFL_TORRENT;
}




/* _zip_headercomp:
   compares two headers h1 and h2; if they are local headers, set
   local1p or local2p respectively to 1, else 0. Return 0 if they
   are identical, -1 if not. */

static int
_zip_headercomp(struct zip_dirent *h1, int local1p, struct zip_dirent *h2,
           int local2p)
{
    if ((h1->version_needed != h2->version_needed)
#if 0
        /* some zip-files have different values in local
           and global headers for the bitflags */
        || (h1->bitflags != h2->bitflags)
#endif
        || (h1->comp_method != h2->comp_method)
        || (h1->last_mod != h2->last_mod)
        || (h1->filename_len != h2->filename_len)
        || !h1->filename || !h2->filename
        || strcmp(h1->filename, h2->filename))
        return -1;

    /* check that CRC and sizes are zero if data descriptor is used */
    if ((h1->bitflags & ZIP_GPBF_DATA_DESCRIPTOR) && local1p
        && (h1->crc != 0
            || h1->comp_size != 0
            || h1->uncomp_size != 0))
        return -1;
    if ((h2->bitflags & ZIP_GPBF_DATA_DESCRIPTOR) && local2p
        && (h2->crc != 0
            || h2->comp_size != 0
            || h2->uncomp_size != 0))
        return -1;

    /* check that CRC and sizes are equal if no data descriptor is used */
    if (((h1->bitflags & ZIP_GPBF_DATA_DESCRIPTOR) == 0 || local1p == 0)
        && ((h2->bitflags & ZIP_GPBF_DATA_DESCRIPTOR) == 0 || local2p == 0)) {
        if ((h1->crc != h2->crc)
            || (h1->comp_size != h2->comp_size)
            || (h1->uncomp_size != h2->uncomp_size))
            return -1;
    }

    if ((local1p == local2p)
        && ((h1->extrafield_len != h2->extrafield_len)
            || (h1->extrafield_len && h2->extrafield
                && memcmp(h1->extrafield, h2->extrafield,
                          h1->extrafield_len))))
        return -1;

    /* if either is local, nothing more to check */
    if (local1p || local2p)
        return 0;

    if ((h1->version_madeby != h2->version_madeby)
        || (h1->disk_number != h2->disk_number)
        || (h1->int_attrib != h2->int_attrib)
        || (h1->ext_attrib != h2->ext_attrib)
        || (h1->offset != h2->offset)
        || (h1->comment_len != h2->comment_len)
        || (h1->comment_len && h2->comment
            && memcmp(h1->comment, h2->comment, h1->comment_len)))
        return -1;

    return 0;
}



static struct zip *
_zip_allocate_new(const char *fn, int *zep)
{
    struct zip *za;
    struct zip_error error;

    if ((za=_zip_new(&error)) == NULL) {
        set_error(zep, &error, 0);
        return NULL;
    }

    za->zn = strdup(fn);
    if (!za->zn) {
        _zip_free(za);
        set_error(zep, NULL, ZIP_ER_MEMORY);
        return NULL;
    }
    return za;
}



static int
_zip_file_exists(const char *fn, int flags, int *zep)
{
    struct stat st;

    if (fn == NULL) {
        set_error(zep, NULL, ZIP_ER_INVAL);
        return -1;
    }

    if (stat(fn, &st) != 0) {
        if (flags & ZIP_CREATE)
            return 0;
        else {
            set_error(zep, NULL, ZIP_ER_OPEN);
            return -1;
        }
    }
    else if ((flags & ZIP_EXCL)) {
        set_error(zep, NULL, ZIP_ER_EXISTS);
        return -1;
    }
    /* ZIP_CREATE gets ignored if file exists and not ZIP_EXCL,
       just like open() */

    return 1;
}



static struct zip_cdir *
_zip_find_central_dir(FILE *fp, int flags, int *zep, myoff_t len)
{
    struct zip_cdir *cdir, *cdirnew;
    unsigned char *buf, *match;
    int a, best, buflen, i;
    struct zip_error zerr;

    i = fseeko(fp, -(len < CDBUFSIZE ? len : CDBUFSIZE), SEEK_END);
    if (i == -1 && errno != EFBIG) {
        /* seek before start of file on my machine */
        set_error(zep, NULL, ZIP_ER_SEEK);
        return NULL;
    }

    /* 64k is too much for stack */
    if ((buf=(unsigned char *)malloc(CDBUFSIZE)) == NULL) {
        set_error(zep, NULL, ZIP_ER_MEMORY);
        return NULL;
    }

    clearerr(fp);
    buflen = fread(buf, 1, CDBUFSIZE, fp);

    if (ferror(fp)) {
        set_error(zep, NULL, ZIP_ER_READ);
        free(buf);
        return NULL;
    }

    best = -1;
    cdir = NULL;
    match = buf;
    _zip_error_set(&zerr, ZIP_ER_NOZIP, 0);

    while ((match=_zip_memmem(match, buflen-(match-buf)-18,
                              (const unsigned char *)EOCD_MAGIC, 4))!=NULL) {
        /* found match -- check, if good */
        /* to avoid finding the same match all over again */
        match++;
        if ((cdirnew=_zip_readcdir(fp, buf, match-1, buflen, flags,
                                   &zerr)) == NULL)
            continue;

        if (cdir) {
            if (best <= 0)
                best = _zip_checkcons(fp, cdir, &zerr);
            a = _zip_checkcons(fp, cdirnew, &zerr);
            if (best < a) {
                _zip_cdir_free(cdir);
                cdir = cdirnew;
                best = a;
            }
            else
                _zip_cdir_free(cdirnew);
        }
        else {
            cdir = cdirnew;
            if (flags & ZIP_CHECKCONS)
                best = _zip_checkcons(fp, cdir, &zerr);
            else
                best = 0;
        }
        cdirnew = NULL;
    }

    free(buf);

    if (best < 0) {
        set_error(zep, &zerr, 0);
        _zip_cdir_free(cdir);
        return NULL;
    }

    return cdir;
}



static unsigned char *
_zip_memmem(const unsigned char *big, int biglen, const unsigned char *little,
       int littlelen)
{
    const unsigned char *p;

    if ((biglen < littlelen) || (littlelen == 0))
        return NULL;
    p = big-1;
    while ((p=(const unsigned char *)
                memchr(p+1, little[0], (size_t)(big-(p+1)+biglen-littlelen+1)))
           != NULL) {
        if (memcmp(p+1, little+1, littlelen-1)==0)
            return (unsigned char *)p;
    }

    return NULL;
}


/* _zip_new:
   creates a new zipfile struct, and sets the contents to zero; returns
   the new struct. */

struct zip *
_zip_new(struct zip_error *error)
{
    struct zip *za;

    za = (struct zip *)malloc(sizeof(struct zip));
    if (!za) {
        _zip_error_set(error, ZIP_ER_MEMORY, 0);
        return NULL;
    }

    za->zn = NULL;
    za->zp = NULL;
    _zip_error_init(&za->error);
    za->cdir = NULL;
    za->ch_comment = NULL;
    za->ch_comment_len = -1;
    za->nentry = za->nentry_alloc = 0;
    za->entry = NULL;
    za->nfile = za->nfile_alloc = 0;
    za->file = NULL;
    za->flags = za->ch_flags = 0;

    return za;
}


void *
_zip_memdup(const void *mem, size_t len, struct zip_error *error)
{
    void *ret;

    ret = malloc(len);
    if (!ret) {
        _zip_error_set(error, ZIP_ER_MEMORY, 0);
        return NULL;
    }

    memcpy(ret, mem, len);

    return ret;
}


ZIP_EXTERN int
zip_get_num_files(struct zip *za)
{
    if (za == NULL)
        return -1;

    return za->nentry;
}

ZIP_EXTERN const char *
zip_get_name(struct zip *za, int idx, int flags)
{
    return _zip_get_name(za, idx, flags, &za->error);
}



const char *
_zip_get_name(struct zip *za, int idx, int flags, struct zip_error *error)
{
    if (idx < 0 || idx >= za->nentry) {
        _zip_error_set(error, ZIP_ER_INVAL, 0);
        return NULL;
    }

    if ((flags & ZIP_FL_UNCHANGED) == 0) {
        if (za->entry[idx].state == ZIP_ST_DELETED) {
            _zip_error_set(error, ZIP_ER_DELETED, 0);
            return NULL;
        }
        if (za->entry[idx].ch_filename)
            return za->entry[idx].ch_filename;
    }

    if (za->cdir == NULL || idx >= za->cdir->nentry) {
        _zip_error_set(error, ZIP_ER_INVAL, 0);
        return NULL;
    }

    return za->cdir->entry[idx].filename;
}


ZIP_EXTERN const char *
zip_get_file_comment(struct zip *za, int idx, int *lenp, int flags)
{
    if (idx < 0 || idx >= za->nentry) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return NULL;
    }

    if ((flags & ZIP_FL_UNCHANGED)
        || (za->entry[idx].ch_comment_len == -1)) {
        if (lenp != NULL)
            *lenp = za->cdir->entry[idx].comment_len;
        return za->cdir->entry[idx].comment;
    }

    if (lenp != NULL)
        *lenp = za->entry[idx].ch_comment_len;
    return za->entry[idx].ch_comment;
}


ZIP_EXTERN int
zip_get_archive_flag(struct zip *za, int flag, int flags)
{
    int fl;

    fl = (flags & ZIP_FL_UNCHANGED) ? za->flags : za->ch_flags;

    return (fl & flag) ? 1 : 0;
}


ZIP_EXTERN const char *
zip_get_archive_comment(struct zip *za, int *lenp, int flags)
{
    if ((flags & ZIP_FL_UNCHANGED)
        || (za->ch_comment_len == -1)) {
        if (za->cdir) {
            if (lenp != NULL)
                *lenp = za->cdir->comment_len;
            return za->cdir->comment;
        }
        else {
            if (lenp != NULL)
                *lenp = -1;
            return NULL;
        }
    }

    if (lenp != NULL)
        *lenp = za->ch_comment_len;
    return za->ch_comment;
}


/* _zip_free:
   frees the space allocated to a zipfile struct, and closes the
   corresponding file. */

void
_zip_free(struct zip *za)
{
    int i;

    if (za == NULL)
        return;

    if (za->zn)
        free(za->zn);

    if (za->zp)
        fclose(za->zp);

    _zip_cdir_free(za->cdir);

    if (za->entry) {
        for (i=0; i<za->nentry; i++) {
            _zip_entry_free(za->entry+i);
        }
        free(za->entry);
    }

    for (i=0; i<za->nfile; i++) {
        if (za->file[i]->error.zip_err == ZIP_ER_OK) {
            _zip_error_set(&za->file[i]->error, ZIP_ER_ZIPCLOSED, 0);
            za->file[i]->za = NULL;
        }
    }

    free(za->file);

    free(za);

    return;
}


ZIP_EXTERN ssize_t
zip_fread(struct zip_file *zf, void *outbuf, size_t toread)
{
    int ret;
    size_t out_before, len;
    int i;

    if (!zf)
        return -1;

    if (zf->error.zip_err != 0)
        return -1;

    if ((zf->flags & ZIP_ZF_EOF) || (toread == 0))
        return 0;

    if (zf->bytes_left == 0) {
        zf->flags |= ZIP_ZF_EOF;
        if (zf->flags & ZIP_ZF_CRC) {
            if (zf->crc != zf->crc_orig) {
                _zip_error_set(&zf->error, ZIP_ER_CRC, 0);
                return -1;
            }
        }
        return 0;
    }

    if ((zf->flags & ZIP_ZF_DECOMP) == 0) {
        ret = _zip_file_fillbuf(outbuf, toread, zf);
        if (ret > 0) {
            if (zf->flags & ZIP_ZF_CRC)
                zf->crc = crc32(zf->crc, (Bytef *)outbuf, ret);
            zf->bytes_left -= ret;
        }
        return ret;
    }

    zf->zstr->next_out = (Bytef *)outbuf;
    zf->zstr->avail_out = toread;
    out_before = zf->zstr->total_out;

    /* endless loop until something has been accomplished */
    for (;;) {
        ret = inflate(zf->zstr, Z_SYNC_FLUSH);

        switch (ret) {
        case Z_OK:
        case Z_STREAM_END:
            /* all ok */
            /* Z_STREAM_END probably won't happen, since we didn't
               have a header */
            len = zf->zstr->total_out - out_before;
            if (len >= zf->bytes_left || len >= toread) {
                if (zf->flags & ZIP_ZF_CRC)
                    zf->crc = crc32(zf->crc, (Bytef *)outbuf, len);
                zf->bytes_left -= len;
                return len;
            }
            break;

        case Z_BUF_ERROR:
            if (zf->zstr->avail_in == 0) {
                i = _zip_file_fillbuf(zf->buffer, BUFSIZE, zf);
                if (i == 0) {
                    _zip_error_set(&zf->error, ZIP_ER_INCONS, 0);
                    return -1;
                }
                else if (i < 0)
                    return -1;
                zf->zstr->next_in = (Bytef *)zf->buffer;
                zf->zstr->avail_in = i;
                continue;
            }
            /* fallthrough */
        case Z_NEED_DICT:
        case Z_DATA_ERROR:
        case Z_STREAM_ERROR:
        case Z_MEM_ERROR:
            _zip_error_set(&zf->error, ZIP_ER_ZLIB, ret);
            return -1;
        }
    }
}


ZIP_EXTERN const char *
zip_strerror(struct zip *za)
{
    return _zip_error_strerror(&za->error);
}


ZIP_EXTERN void
zip_stat_init(struct zip_stat *st)
{
    st->name = NULL;
    st->index = -1;
    st->crc = 0;
    st->mtime = (time_t)-1;
    st->size = -1;
    st->comp_size = -1;
    st->comp_method = ZIP_CM_STORE;
    st->encryption_method = ZIP_EM_NONE;
}


ZIP_EXTERN int
zip_stat_index(struct zip *za, int index, int flags, struct zip_stat *st)
{
    const char *name;

    if (index < 0 || index >= za->nentry) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return -1;
    }

    if ((name=zip_get_name(za, index, flags)) == NULL)
        return -1;


    if ((flags & ZIP_FL_UNCHANGED) == 0
        && ZIP_ENTRY_DATA_CHANGED(za->entry+index)) {
        if (za->entry[index].source->f(za->entry[index].source->ud,
                                     st, sizeof(*st), ZIP_SOURCE_STAT) < 0) {
            _zip_error_set(&za->error, ZIP_ER_CHANGED, 0);
            return -1;
        }
    }
    else {
        if (za->cdir == NULL || index >= za->cdir->nentry) {
            _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
            return -1;
        }

        st->crc = za->cdir->entry[index].crc;
        st->size = za->cdir->entry[index].uncomp_size;
        st->mtime = za->cdir->entry[index].last_mod;
        st->comp_size = za->cdir->entry[index].comp_size;
        st->comp_method = za->cdir->entry[index].comp_method;
        if (za->cdir->entry[index].bitflags & ZIP_GPBF_ENCRYPTED) {
            if (za->cdir->entry[index].bitflags & ZIP_GPBF_STRONG_ENCRYPTION) {
                /* XXX */
                st->encryption_method = ZIP_EM_UNKNOWN;
            }
            else
                st->encryption_method = ZIP_EM_TRAD_PKWARE;
        }
        else
            st->encryption_method = ZIP_EM_NONE;
        /* st->bitflags = za->cdir->entry[index].bitflags; */
    }

    st->index = index;
    st->name = name;

    return 0;
}


ZIP_EXTERN int
zip_stat(struct zip *za, const char *fname, int flags, struct zip_stat *st)
{
    int idx;

    if ((idx=zip_name_locate(za, fname, flags)) < 0)
        return -1;

    return zip_stat_index(za, idx, flags, st);
}


struct read_zip {
    struct zip_file *zf;
    struct zip_stat st;
    myoff_t off, len;
};

static ssize_t read_zip(void *st, void *data, size_t len,
                        enum zip_source_cmd cmd);



ZIP_EXTERN struct zip_source *
zip_source_zip(struct zip *za, struct zip *srcza, int srcidx, int flags,
               myoff_t start, myoff_t len)
{
    struct zip_error error;
    struct zip_source *zs;
    struct read_zip *p;

    /* XXX: ZIP_FL_RECOMPRESS */

    if (za == NULL)
        return NULL;

    if (srcza == NULL || start < 0 || len < -1 || srcidx < 0 || srcidx >= srcza->nentry) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return NULL;
    }

    if ((flags & ZIP_FL_UNCHANGED) == 0
        && ZIP_ENTRY_DATA_CHANGED(srcza->entry+srcidx)) {
        _zip_error_set(&za->error, ZIP_ER_CHANGED, 0);
        return NULL;
    }

    if (len == 0)
        len = -1;

    if (start == 0 && len == -1 && (flags & ZIP_FL_RECOMPRESS) == 0)
        flags |= ZIP_FL_COMPRESSED;
    else
        flags &= ~ZIP_FL_COMPRESSED;

    if ((p=(struct read_zip *)malloc(sizeof(*p))) == NULL) {
        _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
        return NULL;
    }

    _zip_error_copy(&error, &srcza->error);

    if (zip_stat_index(srcza, srcidx, flags, &p->st) < 0
        || (p->zf=zip_fopen_index(srcza, srcidx, flags)) == NULL) {
        free(p);
        _zip_error_copy(&za->error, &srcza->error);
        _zip_error_copy(&srcza->error, &error);

        return NULL;
    }
    p->off = start;
    p->len = len;

    if ((flags & ZIP_FL_COMPRESSED) == 0) {
        p->st.size = p->st.comp_size = len;
        p->st.comp_method = ZIP_CM_STORE;
        p->st.crc = 0;
    }

    if ((zs=zip_source_function(za, read_zip, p)) == NULL) {
        free(p);
        return NULL;
    }

    return zs;
}



static ssize_t
read_zip(void *state, void *data, size_t len, enum zip_source_cmd cmd)
{
    struct read_zip *z;
    char b[8192], *buf;
    int i, n;

    z = (struct read_zip *)state;
    buf = (char *)data;

    switch (cmd) {
    case ZIP_SOURCE_OPEN:
        for (n=0; n<z->off; n+= i) {
            i = (z->off-n > sizeof(b) ? sizeof(b) : z->off-n);
            if ((i=zip_fread(z->zf, b, i)) < 0) {
                zip_fclose(z->zf);
                z->zf = NULL;
                return -1;
            }
        }
        return 0;

    case ZIP_SOURCE_READ:
        if (z->len != -1)
            n = len > z->len ? z->len : len;
        else
            n = len;


        if ((i=zip_fread(z->zf, buf, n)) < 0)
            return -1;

        if (z->len != -1)
            z->len -= i;

        return i;

    case ZIP_SOURCE_CLOSE:
        return 0;

    case ZIP_SOURCE_STAT:
        if (len < sizeof(z->st))
            return -1;
        len = sizeof(z->st);

        memcpy(data, &z->st, len);
        return len;

    case ZIP_SOURCE_ERROR:
        {
            int *e;

            if (len < sizeof(int)*2)
                return -1;

            e = (int *)data;
            zip_file_error_get(z->zf, e, e+1);
        }
        return sizeof(int)*2;

    case ZIP_SOURCE_FREE:
        zip_fclose(z->zf);
        free(z);
        return 0;

    default:
        ;
    }

    return -1;
}


ZIP_EXTERN struct zip_source *
zip_source_function(struct zip *za, zip_source_callback zcb, void *ud)
{
    struct zip_source *zs;

    if (za == NULL)
        return NULL;

    if ((zs=(struct zip_source *)malloc(sizeof(*zs))) == NULL) {
        _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
        return NULL;
    }

    zs->f = zcb;
    zs->ud = ud;

    return zs;
}


ZIP_EXTERN void
zip_source_free(struct zip_source *source)
{
    if (source == NULL)
        return;

    (void)source->f(source->ud, NULL, 0, ZIP_SOURCE_FREE);

    free(source);
}


struct read_file {
    char *fname;        /* name of file to copy from */
    FILE *f;                /* file to copy from */
    myoff_t off;                /* start offset of */
    myoff_t len;                /* lengt of data to copy */
    myoff_t remain;        /* bytes remaining to be copied */
    int e[2];                /* error codes */
};

static ssize_t read_file(void *state, void *data, size_t len,
                     enum zip_source_cmd cmd);



ZIP_EXTERN struct zip_source *
zip_source_filep(struct zip *za, FILE *file, myoff_t start, myoff_t len)
{
    if (za == NULL)
        return NULL;

    if (file == NULL || start < 0 || len < -1) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return NULL;
    }

    return _zip_source_file_or_p(za, NULL, file, start, len);
}



struct zip_source *
_zip_source_file_or_p(struct zip *za, const char *fname, FILE *file,
                      myoff_t start, myoff_t len)
{
    struct read_file *f;
    struct zip_source *zs;

    if (file == NULL && fname == NULL) {
        _zip_error_set(&za->error, ZIP_ER_INVAL, 0);
        return NULL;
    }

    if ((f=(struct read_file *)malloc(sizeof(struct read_file))) == NULL) {
        _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
        return NULL;
    }

    f->fname = NULL;
    if (fname) {
        if ((f->fname=strdup(fname)) == NULL) {
            _zip_error_set(&za->error, ZIP_ER_MEMORY, 0);
            free(f);
            return NULL;
        }
    }
    f->f = file;
    f->off = start;
    f->len = (len ? len : -1);

    if ((zs=zip_source_function(za, read_file, f)) == NULL) {
        free(f);
        return NULL;
    }

    return zs;
}



static ssize_t
read_file(void *state, void *data, size_t len, enum zip_source_cmd cmd)
{
    struct read_file *z;
    char *buf;
    int i, n;

    z = (struct read_file *)state;
    buf = (char *)data;

    switch (cmd) {
    case ZIP_SOURCE_OPEN:
        if (z->fname) {
            if ((z->f=fopen(z->fname, "rb")) == NULL) {
                z->e[0] = ZIP_ER_OPEN;
                z->e[1] = errno;
                return -1;
            }
        }

        if (fseeko(z->f, z->off, SEEK_SET) < 0) {
            z->e[0] = ZIP_ER_SEEK;
            z->e[1] = errno;
            return -1;
        }
        z->remain = z->len;
        return 0;

    case ZIP_SOURCE_READ:
        if (z->remain != -1)
            n = len > z->remain ? z->remain : len;
        else
            n = len;

        if ((i=fread(buf, 1, n, z->f)) < 0) {
            z->e[0] = ZIP_ER_READ;
            z->e[1] = errno;
            return -1;
        }

        if (z->remain != -1)
            z->remain -= i;

        return i;

    case ZIP_SOURCE_CLOSE:
        if (z->fname) {
            fclose(z->f);
            z->f = NULL;
        }
        return 0;

    case ZIP_SOURCE_STAT:
        {
            struct zip_stat *st;
            struct stat fst;
            int err;

            if (len < sizeof(*st))
                return -1;

            if (z->f)
                err = fstat(fileno(z->f), &fst);
            else
                err = stat(z->fname, &fst);

            if (err != 0) {
                z->e[0] = ZIP_ER_READ; /* best match */
                z->e[1] = errno;
                return -1;
            }

            st = (struct zip_stat *)data;

            zip_stat_init(st);
            st->mtime = fst.st_mtime;
            if (z->len != -1)
                st->size = z->len;
            else if ((fst.st_mode&S_IFMT) == S_IFREG)
                st->size = fst.st_size;

            return sizeof(*st);
        }

    case ZIP_SOURCE_ERROR:
        if (len < sizeof(int)*2)
            return -1;

        memcpy(data, z->e, sizeof(int)*2);
        return sizeof(int)*2;

    case ZIP_SOURCE_FREE:
        free(z->fname);
        if (z->f)
            fclose(z->f);
        free(z);
        return 0;

    default:
        ;
    }

    return -1;
}


ZIP_EXTERN int
zip_name_locate(struct zip *za, const char *fname, int flags)
{
    return _zip_name_locate(za, fname, flags, &za->error);
}



int
_zip_name_locate(struct zip *za, const char *fname, int flags,
                 struct zip_error *error)
{
    int (*cmp)(const char *, const char *);
    const char *fn, *p;
    int i, n;

    if (fname == NULL) {
        _zip_error_set(error, ZIP_ER_INVAL, 0);
        return -1;
    }

    cmp = (flags & ZIP_FL_NOCASE) ? strcasecmp : strcmp;

    n = (flags & ZIP_FL_UNCHANGED) ? za->cdir->nentry : za->nentry;
    for (i=0; i<n; i++) {
        if (flags & ZIP_FL_UNCHANGED)
            fn = za->cdir->entry[i].filename;
        else
            fn = _zip_get_name(za, i, flags, error);

        /* newly added (partially filled) entry */
        if (fn == NULL)
            continue;

        if (flags & ZIP_FL_NODIR) {
            p = strrchr(fn, '/');
            if (p)
                fn = p+1;
        }

        if (cmp(fname, fn) == 0)
            return i;
    }

    _zip_error_set(error, ZIP_ER_NOENT, 0);
    return -1;
}

