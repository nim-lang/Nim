#
#
#            Nim's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Interface to the `libzip <http://www.nih.at/libzip/index.html>`_ library by
## Dieter Baron and Thomas Klausner. This version links
## against ``libzip2.so.2`` unless you define the symbol ``useLibzipSrc``; then
## it is compiled against some old ``libizp_all.c`` file.

#
#  zip.h -- exported declarations.
#  Copyright (C) 1999-2008 Dieter Baron and Thomas Klausner
#
#  This file is part of libzip, a library to manipulate ZIP archives.
#  The authors can be contacted at <libzip@nih.at>
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
#  3. The names of the authors may not be used to endorse or promote
#     products derived from this software without specific prior
#     written permission.
# 
#  THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS
#  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
#  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
#  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
#  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
#  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

import times

when defined(unix) and not defined(useLibzipSrc):
  when defined(macosx):
    {.pragma: mydll, dynlib: "libzip2.dylib".}
  else:
    {.pragma: mydll, dynlib: "libzip(|2).so(|.2|.1|.0)".}
else:
  when defined(unix):
    {.passl: "-lz".}
  {.compile: "libzip_all.c".}
  {.pragma: mydll.}

type 
  ZipSourceCmd* = int32

  ZipSourceCallback* = proc (state: pointer, data: pointer, length: int, 
                              cmd: ZipSourceCmd): int {.cdecl.}
  PZipStat* = ptr ZipStat
  ZipStat* = object           ## the 'zip_stat' struct
    name*: cstring            ## name of the file  
    index*: int32             ## index within archive  
    crc*: int32               ## crc of file data  
    mtime*: Time              ## modification time  
    size*: int                ## size of file (uncompressed)  
    compSize*: int            ## size of file (compressed)  
    compMethod*: int16        ## compression method used  
    encryptionMethod*: int16  ## encryption method used  
  
  Zip = object
  ZipSource = object 
  ZipFile = object

  PZip* = ptr Zip ## represents a zip archive
  PZipFile* = ptr ZipFile ## represents a file within an archive
  PZipSource* = ptr ZipSource ## represents a source for an archive
{.deprecated: [TZipSourceCmd: ZipSourceCmd, TZipStat: ZipStat, TZip: Zip,
              TZipSourceCallback: ZipSourceCallback, TZipSource: ZipSource,
              TZipFile: ZipFile].}

# flags for zip_name_locate, zip_fopen, zip_stat, ...  
const 
  ZIP_CREATE* = 1'i32
  ZIP_EXCL* = 2'i32
  ZIP_CHECKCONS* = 4'i32 
  ZIP_FL_NOCASE* = 1'i32        ## ignore case on name lookup  
  ZIP_FL_NODIR* = 2'i32         ## ignore directory component  
  ZIP_FL_COMPRESSED* = 4'i32    ## read compressed data  
  ZIP_FL_UNCHANGED* = 8'i32     ## use original data, ignoring changes  
  ZIP_FL_RECOMPRESS* = 16'i32   ## force recompression of data  

const  # archive global flags flags  
  ZIP_AFL_TORRENT* = 1'i32      ##  torrent zipped  

const # libzip error codes  
  ZIP_ER_OK* = 0'i32            ## N No error  
  ZIP_ER_MULTIDISK* = 1'i32     ## N Multi-disk zip archives not supported  
  ZIP_ER_RENAME* = 2'i32        ## S Renaming temporary file failed  
  ZIP_ER_CLOSE* = 3'i32         ## S Closing zip archive failed  
  ZIP_ER_SEEK* = 4'i32          ## S Seek error  
  ZIP_ER_READ* = 5'i32          ## S Read error  
  ZIP_ER_WRITE* = 6'i32         ## S Write error  
  ZIP_ER_CRC* = 7'i32           ## N CRC error  
  ZIP_ER_ZIPCLOSED* = 8'i32     ## N Containing zip archive was closed  
  ZIP_ER_NOENT* = 9'i32         ## N No such file  
  ZIP_ER_EXISTS* = 10'i32       ## N File already exists  
  ZIP_ER_OPEN* = 11'i32         ## S Can't open file  
  ZIP_ER_TMPOPEN* = 12'i32      ## S Failure to create temporary file  
  ZIP_ER_ZLIB* = 13'i32         ## Z Zlib error  
  ZIP_ER_MEMORY* = 14'i32       ## N Malloc failure  
  ZIP_ER_CHANGED* = 15'i32      ## N Entry has been changed  
  ZIP_ER_COMPNOTSUPP* = 16'i32  ## N Compression method not supported  
  ZIP_ER_EOF* = 17'i32          ## N Premature EOF  
  ZIP_ER_INVAL* = 18'i32        ## N Invalid argument  
  ZIP_ER_NOZIP* = 19'i32        ## N Not a zip archive  
  ZIP_ER_INTERNAL* = 20'i32     ## N Internal error  
  ZIP_ER_INCONS* = 21'i32       ## N Zip archive inconsistent  
  ZIP_ER_REMOVE* = 22'i32       ## S Can't remove file  
  ZIP_ER_DELETED* = 23'i32      ## N Entry has been deleted  
   
const # type of system error value  
  ZIP_ET_NONE* = 0'i32          ## sys_err unused  
  ZIP_ET_SYS* = 1'i32           ## sys_err is errno  
  ZIP_ET_ZLIB* = 2'i32          ## sys_err is zlib error code  

const # compression methods  
  ZIP_CM_DEFAULT* = -1'i32      ## better of deflate or store  
  ZIP_CM_STORE* = 0'i32         ## stored (uncompressed)  
  ZIP_CM_SHRINK* = 1'i32        ## shrunk  
  ZIP_CM_REDUCE_1* = 2'i32      ## reduced with factor 1  
  ZIP_CM_REDUCE_2* = 3'i32      ## reduced with factor 2  
  ZIP_CM_REDUCE_3* = 4'i32      ## reduced with factor 3  
  ZIP_CM_REDUCE_4* = 5'i32      ## reduced with factor 4  
  ZIP_CM_IMPLODE* = 6'i32       ## imploded  
                                ## 7 - Reserved for Tokenizing compression algorithm  
  ZIP_CM_DEFLATE* = 8'i32       ## deflated  
  ZIP_CM_DEFLATE64* = 9'i32     ## deflate64  
  ZIP_CM_PKWARE_IMPLODE* = 10'i32 ## PKWARE imploding  
                                  ## 11 - Reserved by PKWARE  
  ZIP_CM_BZIP2* = 12'i32        ## compressed using BZIP2 algorithm  
                                ## 13 - Reserved by PKWARE  
  ZIP_CM_LZMA* = 14'i32         ## LZMA (EFS)  
                                ## 15-17 - Reserved by PKWARE  
  ZIP_CM_TERSE* = 18'i32        ## compressed using IBM TERSE (new)  
  ZIP_CM_LZ77* = 19'i32         ## IBM LZ77 z Architecture (PFS)  
  ZIP_CM_WAVPACK* = 97'i32      ## WavPack compressed data  
  ZIP_CM_PPMD* = 98'i32         ## PPMd version I, Rev 1  

const  # encryption methods                              
  ZIP_EM_NONE* = 0'i32            ## not encrypted  
  ZIP_EM_TRAD_PKWARE* = 1'i32     ## traditional PKWARE encryption 

const 
  ZIP_EM_UNKNOWN* = 0x0000FFFF'i32 ## unknown algorithm  

const 
  ZIP_SOURCE_OPEN* = 0'i32        ## prepare for reading  
  ZIP_SOURCE_READ* = 1'i32        ## read data  
  ZIP_SOURCE_CLOSE* = 2'i32       ## reading is done  
  ZIP_SOURCE_STAT* = 3'i32        ## get meta information  
  ZIP_SOURCE_ERROR* = 4'i32       ## get error information  
  constZIP_SOURCE_FREE* = 5'i32   ## cleanup and free resources  

proc zip_add*(para1: PZip, para2: cstring, para3: PZipSource): int32 {.cdecl, 
    importc: "zip_add", mydll.}
proc zip_add_dir*(para1: PZip, para2: cstring): int32 {.cdecl,  
    importc: "zip_add_dir", mydll.}
proc zip_close*(para1: PZip) {.cdecl, importc: "zip_close", mydll.}
proc zip_delete*(para1: PZip, para2: int32): int32 {.cdecl, mydll,
    importc: "zip_delete".}
proc zip_error_clear*(para1: PZip) {.cdecl, importc: "zip_error_clear", mydll.}
proc zip_error_get*(para1: PZip, para2: ptr int32, para3: ptr int32) {.cdecl, 
    importc: "zip_error_get", mydll.}
proc zip_error_get_sys_type*(para1: int32): int32 {.cdecl, mydll,
    importc: "zip_error_get_sys_type".}
proc zip_error_to_str*(para1: cstring, para2: int, para3: int32, 
                       para4: int32): int32 {.cdecl, mydll,
    importc: "zip_error_to_str".}
proc zip_fclose*(para1: PZipFile) {.cdecl, mydll,
    importc: "zip_fclose".}
proc zip_file_error_clear*(para1: PZipFile) {.cdecl, mydll,
    importc: "zip_file_error_clear".}
proc zip_file_error_get*(para1: PZipFile, para2: ptr int32, para3: ptr int32) {.
    cdecl, mydll, importc: "zip_file_error_get".}
proc zip_file_strerror*(para1: PZipFile): cstring {.cdecl, mydll,
    importc: "zip_file_strerror".}
proc zip_fopen*(para1: PZip, para2: cstring, para3: int32): PZipFile {.cdecl, 
    mydll, importc: "zip_fopen".}
proc zip_fopen_index*(para1: PZip, para2: int32, para3: int32): PZipFile {.
    cdecl, mydll, importc: "zip_fopen_index".}
proc zip_fread*(para1: PZipFile, para2: pointer, para3: int): int {.
    cdecl, mydll, importc: "zip_fread".}
proc zip_get_archive_comment*(para1: PZip, para2: ptr int32, para3: int32): cstring {.
    cdecl, mydll, importc: "zip_get_archive_comment".}
proc zip_get_archive_flag*(para1: PZip, para2: int32, para3: int32): int32 {.
    cdecl, mydll, importc: "zip_get_archive_flag".}
proc zip_get_file_comment*(para1: PZip, para2: int32, para3: ptr int32, 
                           para4: int32): cstring {.cdecl, mydll,
    importc: "zip_get_file_comment".}
proc zip_get_name*(para1: PZip, para2: int32, para3: int32): cstring {.cdecl, 
    mydll, importc: "zip_get_name".}
proc zip_get_num_files*(para1: PZip): int32 {.cdecl,
    mydll, importc: "zip_get_num_files".}
proc zip_name_locate*(para1: PZip, para2: cstring, para3: int32): int32 {.cdecl, 
    mydll, importc: "zip_name_locate".}
proc zip_open*(para1: cstring, para2: int32, para3: ptr int32): PZip {.cdecl, 
    mydll, importc: "zip_open".}
proc zip_rename*(para1: PZip, para2: int32, para3: cstring): int32 {.cdecl, 
    mydll, importc: "zip_rename".}
proc zip_replace*(para1: PZip, para2: int32, para3: PZipSource): int32 {.cdecl, 
    mydll, importc: "zip_replace".}
proc zip_set_archive_comment*(para1: PZip, para2: cstring, para3: int32): int32 {.
    cdecl, mydll, importc: "zip_set_archive_comment".}
proc zip_set_archive_flag*(para1: PZip, para2: int32, para3: int32): int32 {.
    cdecl, mydll, importc: "zip_set_archive_flag".}
proc zip_set_file_comment*(para1: PZip, para2: int32, para3: cstring, 
                           para4: int32): int32 {.cdecl, mydll,
    importc: "zip_set_file_comment".}
proc zip_source_buffer*(para1: PZip, para2: pointer, para3: int, para4: int32): PZipSource {.
    cdecl, mydll, importc: "zip_source_buffer".}
proc zip_source_file*(para1: PZip, para2: cstring, para3: int, para4: int): PZipSource {.
    cdecl, mydll, importc: "zip_source_file".}
proc zip_source_filep*(para1: PZip, para2: File, para3: int, para4: int): PZipSource {.
    cdecl, mydll, importc: "zip_source_filep".}
proc zip_source_free*(para1: PZipSource) {.cdecl, mydll,
    importc: "zip_source_free".}
proc zip_source_function*(para1: PZip, para2: ZipSourceCallback, 
                          para3: pointer): PZipSource {.cdecl, mydll,
    importc: "zip_source_function".}
proc zip_source_zip*(para1: PZip, para2: PZip, para3: int32, para4: int32, 
                     para5: int, para6: int): PZipSource {.cdecl, mydll,
    importc: "zip_source_zip".}
proc zip_stat*(para1: PZip, para2: cstring, para3: int32, para4: PZipStat): int32 {.
    cdecl, mydll, importc: "zip_stat".}
proc zip_stat_index*(para1: PZip, para2: int32, para3: int32, para4: PZipStat): int32 {.
    cdecl, mydll, importc: "zip_stat_index".}
proc zip_stat_init*(para1: PZipStat) {.cdecl, mydll, importc: "zip_stat_init".}
proc zip_strerror*(para1: PZip): cstring {.cdecl, mydll, importc: "zip_strerror".}
proc zip_unchange*(para1: PZip, para2: int32): int32 {.cdecl, mydll,
    importc: "zip_unchange".}
proc zip_unchange_all*(para1: PZip): int32 {.cdecl, mydll,
    importc: "zip_unchange_all".}
proc zip_unchange_archive*(para1: PZip): int32 {.cdecl, mydll,
    importc: "zip_unchange_archive".}
