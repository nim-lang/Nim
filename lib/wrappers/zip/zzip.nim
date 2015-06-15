#
#
#            Nim's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module is an interface to the zzip library. 

#   Author: 
#   Guido Draheim <guidod@gmx.de>
#   Tomi Ollila <Tomi.Ollila@iki.fi>
#   Copyright (c) 1999,2000,2001,2002,2003,2004 Guido Draheim
#          All rights reserved, 
#             usage allowed under the restrictions of the
#         Lesser GNU General Public License 
#             or alternatively the restrictions 
#             of the Mozilla Public License 1.1

when defined(windows):
  const
    dllname = "zzip.dll"
else:
  const 
    dllname = "libzzip.so"

type 
  TZZipError* = int32 # Name conflict if we drop the `T`

const
  ZZIP_ERROR* = -4096'i32
  ZZIP_NO_ERROR* = 0'i32            # no error, may be used if user sets it.
  ZZIP_OUTOFMEM* = ZZIP_ERROR - 20'i32  # out of memory  
  ZZIP_DIR_OPEN* = ZZIP_ERROR - 21'i32  # failed to open zipfile, see errno for details 
  ZZIP_DIR_STAT* = ZZIP_ERROR - 22'i32  # failed to fstat zipfile, see errno for details
  ZZIP_DIR_SEEK* = ZZIP_ERROR - 23'i32  # failed to lseek zipfile, see errno for details
  ZZIP_DIR_READ* = ZZIP_ERROR - 24'i32  # failed to read zipfile, see errno for details  
  ZZIP_DIR_TOO_SHORT* = ZZIP_ERROR - 25'i32
  ZZIP_DIR_EDH_MISSING* = ZZIP_ERROR - 26'i32
  ZZIP_DIRSIZE* = ZZIP_ERROR - 27'i32
  ZZIP_ENOENT* = ZZIP_ERROR - 28'i32
  ZZIP_UNSUPP_COMPR* = ZZIP_ERROR - 29'i32
  ZZIP_CORRUPTED* = ZZIP_ERROR - 31'i32
  ZZIP_UNDEF* = ZZIP_ERROR - 32'i32
  ZZIP_DIR_LARGEFILE* = ZZIP_ERROR - 33'i32

  ZZIP_CASELESS* = 1'i32 shl 12'i32
  ZZIP_NOPATHS* = 1'i32 shl 13'i32
  ZZIP_PREFERZIP* = 1'i32 shl 14'i32
  ZZIP_ONLYZIP* = 1'i32 shl 16'i32
  ZZIP_FACTORY* = 1'i32 shl 17'i32
  ZZIP_ALLOWREAL* = 1'i32 shl 18'i32
  ZZIP_THREADED* = 1'i32 shl 19'i32
  
type
  ZZipDir* {.final, pure.} = object
  ZZipFile* {.final, pure.} = object
  ZZipPluginIO* {.final, pure.} = object

  ZZipDirent* {.final, pure.} = object  
    d_compr*: int32  ## compression method
    d_csize*: int32  ## compressed size  
    st_size*: int32  ## file size / decompressed size
    d_name*: cstring ## file name / strdupped name

  ZZipStat* = ZZipDirent
{.deprecated: [TZZipDir: ZzipDir, TZZipFile: ZzipFile,
              TZZipPluginIO: ZzipPluginIO, TZZipDirent: ZzipDirent,
              TZZipStat: ZZipStat].}

proc zzip_strerror*(errcode: int32): cstring  {.cdecl, dynlib: dllname, 
    importc: "zzip_strerror".}
proc zzip_strerror_of*(dir: ptr ZZipDir): cstring  {.cdecl, dynlib: dllname, 
    importc: "zzip_strerror_of".}
proc zzip_errno*(errcode: int32): int32 {.cdecl, dynlib: dllname, 
    importc: "zzip_errno".}

proc zzip_geterror*(dir: ptr ZZipDir): int32 {.cdecl, dynlib: dllname, 
    importc: "zzip_error".}
proc zzip_seterror*(dir: ptr ZZipDir, errcode: int32) {.cdecl, dynlib: dllname, 
    importc: "zzip_seterror".}
proc zzip_compr_str*(compr: int32): cstring {.cdecl, dynlib: dllname, 
    importc: "zzip_compr_str".}
proc zzip_dirhandle*(fp: ptr ZZipFile): ptr ZZipDir {.cdecl, dynlib: dllname, 
    importc: "zzip_dirhandle".}
proc zzip_dirfd*(dir: ptr ZZipDir): int32 {.cdecl, dynlib: dllname, 
    importc: "zzip_dirfd".}
proc zzip_dir_real*(dir: ptr ZZipDir): int32 {.cdecl, dynlib: dllname, 
    importc: "zzip_dir_real".}
proc zzip_file_real*(fp: ptr ZZipFile): int32 {.cdecl, dynlib: dllname, 
    importc: "zzip_file_real".}
proc zzip_realdir*(dir: ptr ZZipDir): pointer {.cdecl, dynlib: dllname, 
    importc: "zzip_realdir".}
proc zzip_realfd*(fp: ptr ZZipFile): int32 {.cdecl, dynlib: dllname, 
    importc: "zzip_realfd".}

proc zzip_dir_alloc*(fileext: cstringArray): ptr ZZipDir {.cdecl, 
    dynlib: dllname, importc: "zzip_dir_alloc".}
proc zzip_dir_free*(para1: ptr ZZipDir): int32 {.cdecl, dynlib: dllname, 
    importc: "zzip_dir_free".}

proc zzip_dir_fdopen*(fd: int32, errcode_p: ptr TZZipError): ptr ZZipDir {.cdecl, 
    dynlib: dllname, importc: "zzip_dir_fdopen".}
proc zzip_dir_open*(filename: cstring, errcode_p: ptr TZZipError): ptr ZZipDir {.
    cdecl, dynlib: dllname, importc: "zzip_dir_open".}
proc zzip_dir_close*(dir: ptr ZZipDir) {.cdecl, dynlib: dllname, 
    importc: "zzip_dir_close".}
proc zzip_dir_read*(dir: ptr ZZipDir, dirent: ptr ZZipDirent): int32 {.cdecl, 
    dynlib: dllname, importc: "zzip_dir_read".}

proc zzip_opendir*(filename: cstring): ptr ZZipDir {.cdecl, dynlib: dllname, 
    importc: "zzip_opendir".}
proc zzip_closedir*(dir: ptr ZZipDir) {.cdecl, dynlib: dllname, 
    importc: "zzip_closedir".}
proc zzip_readdir*(dir: ptr ZZipDir): ptr ZZipDirent {.cdecl, dynlib: dllname, 
    importc: "zzip_readdir".}
proc zzip_rewinddir*(dir: ptr ZZipDir) {.cdecl, dynlib: dllname, 
                                      importc: "zzip_rewinddir".}
proc zzip_telldir*(dir: ptr ZZipDir): int {.cdecl, dynlib: dllname, 
    importc: "zzip_telldir".}
proc zzip_seekdir*(dir: ptr ZZipDir, offset: int) {.cdecl, dynlib: dllname, 
    importc: "zzip_seekdir".}

proc zzip_file_open*(dir: ptr ZZipDir, name: cstring, flags: int32): ptr ZZipFile {.
    cdecl, dynlib: dllname, importc: "zzip_file_open".}
proc zzip_file_close*(fp: ptr ZZipFile) {.cdecl, dynlib: dllname, 
    importc: "zzip_file_close".}
proc zzip_file_read*(fp: ptr ZZipFile, buf: pointer, length: int): int {.
    cdecl, dynlib: dllname, importc: "zzip_file_read".}
proc zzip_open*(name: cstring, flags: int32): ptr ZZipFile {.cdecl, 
    dynlib: dllname, importc: "zzip_open".}
proc zzip_close*(fp: ptr ZZipFile) {.cdecl, dynlib: dllname, 
    importc: "zzip_close".}
proc zzip_read*(fp: ptr ZZipFile, buf: pointer, length: int): int {.
    cdecl, dynlib: dllname, importc: "zzip_read".}

proc zzip_freopen*(name: cstring, mode: cstring, para3: ptr ZZipFile): ptr ZZipFile {.
    cdecl, dynlib: dllname, importc: "zzip_freopen".}
proc zzip_fopen*(name: cstring, mode: cstring): ptr ZZipFile {.cdecl, 
    dynlib: dllname, importc: "zzip_fopen".}
proc zzip_fread*(p: pointer, size: int, nmemb: int, 
                 file: ptr ZZipFile): int {.cdecl, dynlib: dllname, 
    importc: "zzip_fread".}
proc zzip_fclose*(fp: ptr ZZipFile) {.cdecl, dynlib: dllname, 
    importc: "zzip_fclose".}

proc zzip_rewind*(fp: ptr ZZipFile): int32 {.cdecl, dynlib: dllname, 
    importc: "zzip_rewind".}
proc zzip_seek*(fp: ptr ZZipFile, offset: int, whence: int32): int {.
    cdecl, dynlib: dllname, importc: "zzip_seek".}
proc zzip_tell*(fp: ptr ZZipFile): int {.cdecl, dynlib: dllname, 
    importc: "zzip_tell".}

proc zzip_dir_stat*(dir: ptr ZZipDir, name: cstring, zs: ptr ZZipStat, 
                    flags: int32): int32 {.cdecl, dynlib: dllname, 
    importc: "zzip_dir_stat".}
proc zzip_file_stat*(fp: ptr ZZipFile, zs: ptr ZZipStat): int32 {.cdecl, 
    dynlib: dllname, importc: "zzip_file_stat".}
proc zzip_fstat*(fp: ptr ZZipFile, zs: ptr ZZipStat): int32 {.cdecl, dynlib: dllname, 
    importc: "zzip_fstat".}

proc zzip_open_shared_io*(stream: ptr ZZipFile, name: cstring, 
                          o_flags: int32, o_modes: int32, ext: cstringArray, 
                          io: ptr ZZipPluginIO): ptr ZZipFile {.cdecl, 
    dynlib: dllname, importc: "zzip_open_shared_io".}
proc zzip_open_ext_io*(name: cstring, o_flags: int32, o_modes: int32, 
                       ext: cstringArray, io: ptr ZZipPluginIO): ptr ZZipFile {.
    cdecl, dynlib: dllname, importc: "zzip_open_ext_io".}
proc zzip_opendir_ext_io*(name: cstring, o_modes: int32, 
                          ext: cstringArray, io: ptr ZZipPluginIO): ptr ZZipDir {.
    cdecl, dynlib: dllname, importc: "zzip_opendir_ext_io".}
proc zzip_dir_open_ext_io*(filename: cstring, errcode_p: ptr TZZipError, 
                           ext: cstringArray, io: ptr ZZipPluginIO): ptr ZZipDir {.
    cdecl, dynlib: dllname, importc: "zzip_dir_open_ext_io".}
