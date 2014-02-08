#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module is a wrapper for the `mongodb`:idx: client C library.
## It allows you to connect to a mongo-server instance, send commands and
## receive replies.

# 
#    Copyright 2009-2011 10gen Inc.
# 
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
# 

import oids, times

{.deadCodeElim: on.}

when defined(windows):
  const
    mongodll* = "mongoc.dll"
    bsondll* = "bson.dll"
elif defined(macosx):
  const 
    mongodll* = "libmongoc.dylib"
    bsondll* = "libbson.dylib"
else:
  const 
    mongodll* = "libmongoc.so"
    bsondll* = "libbson.so"

#
#  This package supports both compile-time and run-time determination of CPU
#  byte order.  If ARCH_IS_BIG_ENDIAN is defined as 0, the code will be
#  compiled to run only on little-endian CPUs; if ARCH_IS_BIG_ENDIAN is
#  defined as non-zero, the code will be compiled to run only on big-endian
#  CPUs; if ARCH_IS_BIG_ENDIAN is not defined, the code will be compiled to
#  run on either big- or little-endian CPUs, but will run slightly less
#  efficiently on either one than if ARCH_IS_BIG_ENDIAN is defined.
# 

type 
  Tmd5_state*{.pure, final.} = object 
    count*: array[0..2 - 1, int32] # message length in bits, lsw first 
    abcd*: array[0..4 - 1, int32] # digest buffer 
    buf*: array[0..64 - 1, byte] # accumulate block 
  

proc sock_init*(): cint{.stdcall, importc: "mongo_sock_init", dynlib: mongodll.}
const 
  OK* = 0
  ERROR* = - 1
  SIZE_OVERFLOW* = 1
  defaultHost* = "127.0.0.1"
  defaultPort* = 27017

type 
  TValidity* = enum ## validity
    VALID = 0,                ## BSON is valid and UTF-8 compliant. 
    NOT_UTF8 = (1 shl 1),     ## A key or a string is not valid UTF-8. 
    FIELD_HAS_DOT = (1 shl 2),  ## Warning: key contains '.' character. 
    FIELD_INIT_DOLLAR = (1 shl 3),  ## Warning: key starts with '$' character. 
    ALREADY_FINISHED = (1 shl 4) ## Trying to modify a finished BSON object. 
  TBinarySubtype* = enum 
    BIN_BINARY = 0, BIN_FUNC = 1, BIN_BINARY_OLD = 2, BIN_UUID = 3, BIN_MD5 = 5, 
    BIN_USER = 128
  TBsonKind* {.size: sizeof(cint).} = enum 
    bkEOO = 0, 
    bkDOUBLE = 1, 
    bkSTRING = 2, 
    bkOBJECT = 3, 
    bkARRAY = 4, 
    bkBINDATA = 5, 
    bkUNDEFINED = 6, 
    bkOID = 7, 
    bkBOOL = 8, 
    bkDATE = 9, 
    bkNULL = 10, 
    bkREGEX = 11, 
    bkDBREF = 12,  #*< Deprecated. 
    bkCODE = 13, 
    bkSYMBOL = 14, 
    bkCODEWSCOPE = 15, 
    bkINT = 16, 
    bkTIMESTAMP = 17, 
    bkLONG = 18
  TBsonBool* = cint
  TIter* {.pure, final.} = object 
    cur*: cstring
    first*: TBsonBool

  TBson* {.pure, final.} = object 
    data*: cstring
    cur*: cstring
    dataSize*: cint
    finished*: TBsonBool
    ownsData*: TBsonBool
    err*: cint
    stackSize*: cint
    stackPos*: cint
    stackPtr*: ptr csize
    stack*: array[0..32 - 1, csize]
  
  TDate* = int64

# milliseconds since epoch UTC 

type
  TTimestamp*{.pure, final.} = object ## a timestamp
    i*: cint                  # increment 
    t*: cint                  # time in seconds 

proc create*(): ptr TBson{.stdcall, importc: "bson_create", dynlib: bsondll.}
proc dispose*(b: ptr TBson){.stdcall, importc: "bson_dispose", dynlib: bsondll.}

proc size*(b: var TBson): cint {.stdcall, importc: "bson_size", dynlib: bsondll.}
  ## Size of a BSON object.

proc bufferSize*(b: var TBson): cint{.stdcall, importc: "bson_buffer_size", 
                                      dynlib: bsondll.}
  ## Buffer size of a BSON object.

proc print*(b: var TBson){.stdcall, importc: "bson_print", dynlib: bsondll.}
  ## Print a string representation of a BSON object.

proc print*(TBson: cstring, depth: cint) {.stdcall, 
    importc: "bson_print_raw", dynlib: bsondll.}
  ## Print a string representation of a BSON object up to `depth`.


proc data*(b: var TBson): cstring{.stdcall, importc: "bson_data", 
                                   dynlib: bsondll.}
  ## Return a pointer to the raw buffer stored by this bson object.

proc find*(it: var TIter, obj: var TBson, name: cstring): TBsonKind {.stdcall, 
    importc: "bson_find", dynlib: bsondll.}
  ## Advance `it` to the named field. `obj` is the BSON object to use.
  ## `name` is the name of the field to find. Returns the type of the found
  ## object or ``bkEOO`` if it is not found.
  
proc createIter*(): ptr TIter{.stdcall, importc: "bson_iterator_create", 
                               dynlib: bsondll.}
proc dispose*(a2: ptr TIter){.stdcall, importc: "bson_iterator_dispose", 
                              dynlib: bsondll.}

proc initIter*(b: var TBson): TIter =
  ## Initialize a bson iterator from the value `b`.
  proc iterator_init(i: var TIter, b: var TBson){.stdcall, 
      importc: "bson_iterator_init", dynlib: bsondll.}

  iterator_init(result, b)

proc fromBuffer*(i: var TIter, buffer: cstring) {.stdcall, 
    importc: "bson_iterator_from_buffer", dynlib: bsondll.}
  ## Initialize a bson iterator from a cstring buffer. Note
  ## that this is mostly used internally.

proc more*(i: var TIter): bool = 
  ## Check to see if the bson_iterator has more data.
  proc iterator_more(i: var TIter): TBsonBool{.stdcall, 
      importc: "bson_iterator_more", dynlib: bsondll.}
  result = iterator_more(i) != 0'i32
  
proc next*(i: var TIter): TBsonKind {.stdcall, 
    importc: "bson_iterator_next", dynlib: bsondll.}
  ## Point the iterator at the next BSON object.

proc kind*(i: var TIter): TBsonKind{.stdcall, 
    importc: "bson_iterator_type", dynlib: bsondll.}
  ## Get the type of the BSON object currently pointed to by the iterator.

proc key*(i: var TIter): cstring{.stdcall, 
    importc: "bson_iterator_key", dynlib: bsondll.}
  ##  Get the key of the BSON object currently pointed to by the iterator.
  
proc value*(i: var TIter): cstring{.stdcall, 
    importc: "bson_iterator_value", dynlib: bsondll.}
  ## Get the value of the BSON object currently pointed to by the iterator.
  
proc floatVal*(i: var TIter): float {.stdcall, 
    importc: "bson_iterator_double", dynlib: bsondll.}
  ## Get the double value of the BSON object currently pointed to by the
  ## iterator.

proc intVal*(i: var TIter): cint{.stdcall, importc: "bson_iterator_int", 
                                  dynlib: bsondll.}
  ## Get the int value of the BSON object currently pointed to by the iterator.

proc int64Val*(i: var TIter): int64{.stdcall, 
    importc: "bson_iterator_long", dynlib: bsondll.}
  ## Get the long value of the BSON object currently pointed to by the iterator.

proc timestamp*(i: var TIter): Ttimestamp {.stdcall, 
    importc: "bson_iterator_timestamp", dynlib: bsondll.}
  # return the bson timestamp as a whole or in parts 

proc timestampTime*(i: var TIter): cint {.stdcall, 
    importc: "bson_iterator_timestamp_time", dynlib: bsondll.}
  # return the bson timestamp as a whole or in parts 
proc timestampIncrement*(i: var TIter): cint{.stdcall, 
    importc: "bson_iterator_timestamp_increment", dynlib: bsondll.}
  # return the bson timestamp as a whole or in parts 

proc boolVal*(i: var TIter): TBsonBool{.stdcall, 
    importc: "bson_iterator_bool", dynlib: bsondll.}
  ## Get the boolean value of the BSON object currently pointed to by
  ## the iterator.
  ##
  ## | false: boolean false, 0 in any type, or null 
  ## | true: anything else (even empty strings and objects) 

proc floatRaw*(i: var TIter): cdouble{.stdcall, 
    importc: "bson_iterator_double_raw", dynlib: bsondll.}
  ## Get the double value of the BSON object currently pointed to by the
  ## iterator. Assumes the correct type is used.
      
proc intRaw*(i: var TIter): cint{.stdcall, 
    importc: "bson_iterator_int_raw", dynlib: bsondll.}
  ## Get the int value of the BSON object currently pointed to by the
  ## iterator. Assumes the correct type is used.
    
proc int64Raw*(i: var TIter): int64{.stdcall, 
    importc: "bson_iterator_long_raw", dynlib: bsondll.}
  ## Get the long value of the BSON object currently pointed to by the
  ## iterator. Assumes the correct type is used.

proc boolRaw*(i: var TIter): TBsonBool{.stdcall, 
    importc: "bson_iterator_bool_raw", dynlib: bsondll.}
  ## Get the bson_bool_t value of the BSON object currently pointed to by the
  ## iterator. Assumes the correct type is used.

proc oidVal*(i: var TIter): ptr TOid {.stdcall, 
    importc: "bson_iterator_oid", dynlib: bsondll.}
  ## Get the bson_oid_t value of the BSON object currently pointed to by the
  ## iterator.

proc strVal*(i: var TIter): cstring {.stdcall, 
    importc: "bson_iterator_string", dynlib: bsondll.}
  ## Get the string value of the BSON object currently pointed to by the
  ## iterator.

proc strLen*(i: var TIter): cint {.stdcall, 
    importc: "bson_iterator_string_len", dynlib: bsondll.}
  ## Get the string length of the BSON object currently pointed to by the
  ## iterator.

proc code*(i: var TIter): cstring {.stdcall, 
    importc: "bson_iterator_code", dynlib: bsondll.}
  ## Get the code value of the BSON object currently pointed to by the
  ## iterator. Works with bson_code, bson_codewscope, and BSON_STRING
  ## returns ``nil`` for everything else.
    
proc codeScope*(i: var TIter, scope: var TBson) {.stdcall, 
    importc: "bson_iterator_code_scope", dynlib: bsondll.}
  ## Calls bson_empty on scope if not a bson_codewscope
  
proc date*(i: var TIter): Tdate {.stdcall, 
    importc: "bson_iterator_date", dynlib: bsondll.}
  ## Get the date value of the BSON object currently pointed to by the
  ## iterator.

proc time*(i: var TIter): TTime {.stdcall, 
    importc: "bson_iterator_time_t", dynlib: bsondll.}
  ## Get the time value of the BSON object currently pointed to by the
  ## iterator.

proc binLen*(i: var TIter): cint {.stdcall, 
    importc: "bson_iterator_bin_len", dynlib: bsondll.}
  ## Get the length of the BSON binary object currently pointed to by the
  ## iterator.

proc binType*(i: var TIter): char {.stdcall, 
    importc: "bson_iterator_bin_type", dynlib: bsondll.}
  ## Get the type of the BSON binary object currently pointed to by the
  ## iterator.

proc binData*(i: var TIter): cstring {.stdcall, 
    importc: "bson_iterator_bin_data", dynlib: bsondll.}
  ## Get the value of the BSON binary object currently pointed to by the
  ## iterator.

proc regex*(i: var TIter): cstring {.stdcall, 
    importc: "bson_iterator_regex", dynlib: bsondll.}
  ## Get the value of the BSON regex object currently pointed to by the
  ## iterator.

proc regexOpts*(i: var TIter): cstring {.stdcall, 
    importc: "bson_iterator_regex_opts", dynlib: bsondll.}
  ## Get the options of the BSON regex object currently pointed to by the
  ## iterator.

proc subobject*(i: var TIter, sub: var TBson) {.stdcall, 
    importc: "bson_iterator_subobject", dynlib: bsondll.}
  ## Get the BSON subobject currently pointed to by the
  ## iterator.

proc subiterator*(i: var TIter, sub: var TIter) {.stdcall, 
    importc: "bson_iterator_subiterator", dynlib: bsondll.}
  ## Get a bson_iterator that on the BSON subobject.


# ----------------------------
#   BUILDING
# ----------------------------

proc init*(b: var TBson) {.stdcall, importc: "bson_init", dynlib: bsondll.}
  ## Initialize a new bson object. If not created
  ## with bson_new, you must initialize each new bson
  ## object using this function.
  ##
  ## When finished, you must pass the bson object to bson_destroy().

proc init*(b: var TBson, data: cstring): cint {.stdcall, 
    importc: "bson_init_data", dynlib: bsondll.}
  ## Initialize a BSON object, and point its data
  ## pointer to the provided `data`.
  ## Returns OK or ERROR.

proc initFinished*(b: var TBson, data: cstring): cint {.stdcall, 
    importc: "bson_init_finished_data", dynlib: bsondll.}

proc initSize*(b: var TBson, size: cint) {.stdcall, importc: "bson_init_size", 
    dynlib: bsondll.}
  ## Initialize a BSON object, and set its buffer to the given size.
  ## Returns OK or ERROR.

proc ensureSpace*(b: var TBson, bytesNeeded: cint): cint {.stdcall, 
    importc: "bson_ensure_space", dynlib: bsondll.}
  ## Grow a bson object. `bytesNeeded` is the additional number of bytes needed.

proc finish*(b: var TBson): cint{.stdcall, importc: "bson_finish", 
                                  dynlib: bsondll, discardable.}
  ## Finalize a bson object. Returns the standard error code.
  ## To deallocate memory, call destroy on the bson object.

proc destroy*(b: var TBson){.stdcall, importc: "bson_destroy", dynlib: bsondll.}
  ## Destroy a bson object.

proc empty*(obj: var TBson) {.stdcall, importc: "bson_empty", 
                              dynlib: bsondll.}
  ## Sets a pointer to a static empty BSON object.
  ## `obj` is the BSON object to initialize. 

proc copy*(outp, inp: var TBson): cint{.stdcall, importc: "bson_copy", 
    dynlib: bsondll.}
  ## Make a complete copy of the a BSON object.
  ## The source bson object must be in a finished
  ## state; otherwise, the copy will fail.

proc add*(b: var TBson, name: cstring, oid: TOid) =
  ## adds an OID to `b`.
  proc appendOid(b: var TBson, name: cstring, oid: ptr TOid): cint {.stdcall, 
      importc: "bson_append_oid", dynlib: bsondll.}
  
  var oid = oid
  discard appendOid(b, name, addr(oid))

proc add*(b: var TBson, name: cstring, i: cint): cint{.stdcall, 
    importc: "bson_append_int", dynlib: bsondll, discardable.}
  ## Append an int to a bson.

proc add*(b: var TBson, name: cstring, i: int64): cint{.stdcall, 
    importc: "bson_append_long", dynlib: bsondll, discardable.}
  ## Append an long to a bson.

proc add*(b: var TBson, name: cstring, d: float): cint{.stdcall, 
    importc: "bson_append_double", dynlib: bsondll, discardable.}
  ## Append an double to a bson.

proc add*(b: var TBson, name: cstring, str: cstring): cint {.stdcall, 
    importc: "bson_append_string", dynlib: bsondll, discardable.}
  ## Append a string to a bson.

proc add*(b: var TBson, name: cstring, str: cstring, len: cint): cint{.
    stdcall, importc: "bson_append_string_n", dynlib: bsondll, discardable.}
  ## Append len bytes of a string to a bson.

proc add*(b: var TBson, name: cstring, str: string) =
  ## Append a Nimrod string `str` to a bson.
  discard add(b, name, str, str.len.cint)

proc addSymbol*(b: var TBson, name: cstring, str: cstring): cint{.stdcall, 
    importc: "bson_append_symbol", dynlib: bsondll, discardable.}
  ##  Append a symbol to a bson.

proc addSymbol*(b: var TBson, name: cstring, str: cstring, len: cint): cint{.
    stdcall, importc: "bson_append_symbol_n", dynlib: bsondll, discardable.}
  ## Append len bytes of a symbol to a bson.

proc addCode*(b: var TBson, name: cstring, str: cstring): cint{.stdcall, 
    importc: "bson_append_code", dynlib: bsondll, discardable.}
  ## Append code to a bson.

proc addCode*(b: var TBson, name: cstring, str: cstring, len: cint): cint{.
    stdcall, importc: "bson_append_code_n", dynlib: bsondll, discardable.}
  ## Append len bytes of code to a bson.

proc addCode*(b: var TBson, name: cstring, code: cstring, 
                          scope: var TBson): cint{.stdcall, 
    importc: "bson_append_code_w_scope", dynlib: bsondll, discardable.}
  ## Append code to a bson with scope.

proc addCode*(b: var TBson, name: cstring, code: cstring, 
              size: cint, scope: var TBson): cint{.stdcall, 
    importc: "bson_append_code_w_scope_n", dynlib: bsondll, discardable.}
  ## Append len bytes of code to a bson with scope.

proc addBinary*(b: var TBson, name: cstring, typ: char, str: cstring, 
                len: cint): cint{.stdcall, importc: "bson_append_binary", 
                                 dynlib: bsondll, discardable.}
  ## Append binary data to a bson.

proc addBinary*(b: var TBson, name: cstring, data: string) =
  ## Append binary data to a bson.
  addBinary(b, name, '\5', data, data.len.cint)

proc addBool*(b: var TBson, name: cstring, v: TBsonBool): cint{.stdcall, 
    importc: "bson_append_bool", dynlib: bsondll, discardable.}
  ## Append a bson_bool_t to a bson.

proc addNull*(b: var TBson, name: cstring): cint {.stdcall, 
    importc: "bson_append_null", dynlib: bsondll, discardable.}
  ## Append a null value to a bson.

proc addUndefined*(b: var TBson, name: cstring): cint{.stdcall, 
    importc: "bson_append_undefined", dynlib: bsondll, discardable.}
  ## Append an undefined value to a bson.

proc addRegex*(b: var TBson, name: cstring, pattern: cstring, opts: cstring): cint{.
    stdcall, importc: "bson_append_regex", dynlib: bsondll, discardable.}
  ## Append a regex value to a bson.

proc add*(b: var TBson, name: cstring, TBson: var TBson): cint {.stdcall, 
    importc: "bson_append_bson", dynlib: bsondll, discardable.}
  ## Append bson data to a bson.

proc addElement*(b: var TBson, name_or_null: cstring, elem: var TIter): cint{.
    stdcall, importc: "bson_append_element", dynlib: bsondll, discardable.}
  ## Append a BSON element to a bson from the current point of an iterator.

proc addTimestamp*(b: var TBson, name: cstring, ts: var TTimestamp): cint{.
    stdcall, importc: "bson_append_timestamp", dynlib: bsondll, discardable.}
  ## Append a bson_timestamp_t value to a bson.

proc addTimestamp2*(b: var TBson, name: cstring, time: cint, increment: cint): cint{.
    stdcall, importc: "bson_append_timestamp2", dynlib: bsondll, discardable.}
proc addDate*(b: var TBson, name: cstring, millis: TDate): cint{.stdcall, 
    importc: "bson_append_date", dynlib: bsondll, discardable.}
  ## Append a bson_date_t value to a bson.

proc addTime*(b: var TBson, name: cstring, secs: TTime): cint{.stdcall, 
    importc: "bson_append_time_t", dynlib: bsondll, discardable.}
  ## Append a time_t value to a bson.

proc addStartObject*(b: var TBson, name: cstring): cint {.stdcall, 
    importc: "bson_append_start_object", dynlib: bsondll, discardable.}
  ## Start appending a new object to a bson.

proc addStartArray*(b: var TBson, name: cstring): cint {.stdcall, 
    importc: "bson_append_start_array", dynlib: bsondll, discardable.}
  ## Start appending a new array to a bson.

proc addFinishObject*(b: var TBson): cint {.stdcall, 
    importc: "bson_append_finish_object", dynlib: bsondll, discardable.}
  ## Finish appending a new object or array to a bson.

proc addFinishArray*(b: var TBson): cint {.stdcall, 
    importc: "bson_append_finish_array", dynlib: bsondll, discardable.}
  ## Finish appending a new object or array to a bson. This
  ## is simply an alias for bson_append_finish_object.

proc numstr*(str: cstring, i: cint){.stdcall, importc: "bson_numstr", 
                                     dynlib: bsondll.}
proc incnumstr*(str: cstring){.stdcall, importc: "bson_incnumstr", 
                               dynlib: bsondll.}

type 
  TErrHandler* = proc (errmsg: cstring){.
    stdcall.} ## an error handler. Error handlers shouldn't return!

proc setBsonErrHandler*(func: TErrHandler): TErrHandler {.stdcall, 
    importc: "set_bson_err_handler", dynlib: bsondll.}
  ## Set a function for error handling.
  ## Returns the old error handling function, or nil.

proc fatal*(ok: cint){.stdcall, importc: "bson_fatal", dynlib: bsondll.}
  ## does nothing if ok != 0. Exit fatally.

proc fatal*(ok: cint, msg: cstring){.stdcall, importc: "bson_fatal_msg", 
    dynlib: bsondll.}
  ## Exit fatally with an error message.

proc builderError*(b: var TBson){.stdcall, importc: "bson_builder_error", 
                                   dynlib: bsondll.}
  ## Invoke the error handler, but do not exit.

proc int64ToDouble*(i64: int64): cdouble {.stdcall, 
    importc: "bson_int64_to_double", dynlib: bsondll.}
  ## Cast an int64_t to double. This is necessary for embedding in
  ## certain environments.

const 
  MAJOR* = 0
  MINOR* = 4
  PATCH* = 0

type 
  TError*{.size: sizeof(cint).} = enum ## connection errors
    CONN_SUCCESS = 0,         ## Connection success! 
    CONN_NO_SOCKET,           ## Could not create a socket. 
    CONN_FAIL,                ## An error occured while calling connect(). 
    CONN_ADDR_FAIL,           ## An error occured while calling getaddrinfo(). 
    CONN_NOT_MASTER,          ## Warning: connected to a non-master node (read-only). 
    CONN_BAD_SET_NAME,        ## Given rs name doesn't match this replica set. 
    CONN_NO_PRIMARY,          ## Can't find primary in replica set. Connection closed. 
    IO_ERROR,                 ## An error occurred while reading or writing on the socket. 
    READ_SIZE_ERROR,          ## The response is not the expected length. 
    COMMAND_FAILED,           ## The command returned with 'ok' value of 0. 
    BSON_INVALID,             ## BSON not valid for the specified op. 
    BSON_NOT_FINISHED         ## BSON object has not been finished. 
  TCursorError*{.size: sizeof(cint).} = enum ## cursor error 
    CURSOR_EXHAUSTED,         ## The cursor has no more results. 
    CURSOR_INVALID,           ## The cursor has timed out or is not recognized. 
    CURSOR_PENDING,           ## Tailable cursor still alive but no data. 
    CURSOR_QUERY_FAIL,  ## The server returned an '$err' object, indicating query failure.
                        ## See conn.lasterrcode and conn.lasterrstr for details. 
    CURSOR_BSON_ERROR ## Something is wrong with the BSON provided. See conn.err
                      ## for details. 
  TCursorFlags* = enum ## cursor flags
    CURSOR_MUST_FREE = 1,     ## mongo_cursor_destroy should free cursor. 
    CURSOR_QUERY_SENT = (1 shl 1) ## Initial query has been sent. 
  TindexOpts* = enum 
    INDEX_UNIQUE = (1 shl 0), INDEX_DROP_DUPS = (1 shl 2), 
    INDEX_BACKGROUND = (1 shl 3), INDEX_SPARSE = (1 shl 4)
  TupdateOpts* = enum 
    UPDATE_UPSERT = 0x00000001, 
    UPDATE_MULTI = 0x00000002, 
    UPDATE_BASIC = 0x00000004
  TCursorOpts* = enum 
    TAILABLE = (1 shl 1),     ## Create a tailable cursor. 
    SLAVE_OK = (1 shl 2),     ## Allow queries on a non-primary node. 
    NO_CURSOR_TIMEOUT = (1 shl 4),  ## Disable cursor timeouts. 
    AWAIT_DATA = (1 shl 5),   ## Momentarily block for more data. 
    EXHAUST = (1 shl 6),      ## Stream in multiple 'more' packages. 
    PARTIAL = (1 shl 7)       ## Allow reads even if a shard is down. 
  Toperations* = enum 
    OP_MSG = 1000, OP_UPDATE = 2001, OP_INSERT = 2002, OP_QUERY = 2004, 
    OP_GET_MORE = 2005, OP_DELETE = 2006, OP_KILL_CURSORS = 2007
  THeader* {.pure, final.} = object 
    len*: cint
    id*: cint
    responseTo*: cint
    op*: cint

  TMessage* {.pure, final.} = object 
    head*: Theader
    data*: char

  TReplyFields*{.pure, final.} = object 
    flag*: cint               # FIX THIS COMMENT non-zero on failure 
    cursorID*: int64
    start*: cint
    num*: cint

  TReply*{.pure, final.} = object 
    head*: Theader
    fields*: Treply_fields
    objs*: char

  THostPort*{.pure, final.} = object 
    host*: array[0..255 - 1, char]
    port*: cint
    next*: ptr THostPort

  TReplset*{.pure, final.} = object ## replset
    seeds*: ptr THostPort    ## List of seeds provided by the user. 
    hosts*: ptr THostPort    ## List of host/ports given by the replica set 
    name*: cstring           ## Name of the replica set. 
    primary_connected*: TBsonBool ## Primary node connection status. 

  TWriteConcern*{.pure, final.} = object ## mongo_write_concern
    w*: cint
    wtimeout*: cint
    j*: cint
    fsync*: cint
    mode*: cstring
    cmd*: TBson
  
  TMongo*{.pure, final.} = object ## mongo
    primary*: ptr THostPort              ## Primary connection info. 
    replset*: ptr TReplSet               ## replset object if connected to a replica set. 
    sock*: cint                          ## Socket file descriptor. 
    flags*: cint                         ## Flags on this connection object. 
    conn_timeout_ms*: cint               ## Connection timeout in milliseconds. 
    op_timeout_ms*: cint                 ## Read and write timeout in milliseconds. 
    max_bson_size*: cint                 ## Largest BSON object allowed on this connection. 
    connected*: TBsonBool                ## Connection status. 
    write_concern*: TWriteConcern        ## The default write concern.
    err*: TError                         ## Most recent driver error code. 
    errcode*: cint                       ## Most recent errno or WSAGetLastError().
    errstr*: array[0..128 - 1, char]     ## String version of most recent driver error code. 
    lasterrcode*: cint                   ## getlasterror code given by the server on error. 
    lasterrstr*: array[0..128 - 1, char] ## getlasterror string generated by server. 
  
  TCursor*{.pure, final.} = object ## cursor
    reply*: ptr TReply        ## reply is owned by cursor 
    conn*: ptr TMongo         ## connection is *not* owned by cursor 
    ns*: cstring              ## owned by cursor 
    flags*: cint              ## Flags used internally by this drivers. 
    seen*: cint               ## Number returned so far. 
    current*: TBson           ## This cursor's current bson object. 
    err*: TCursorError        ## Errors on this cursor. 
    query*: ptr TBson         ## Bitfield containing cursor options. 
    fields*: ptr TBson        ## Bitfield containing cursor options. 
    options*: cint            ## Bitfield containing cursor options. 
    limit*: cint              ## Bitfield containing cursor options. 
    skip*: cint               ## Bitfield containing cursor options. 
  

# Connection API 

proc createMongo*(): ptr TMongo{.stdcall, importc: "mongo_create", dynlib: mongodll.}
proc dispose*(conn: ptr TMongo){.stdcall, importc: "mongo_dispose", 
                                 dynlib: mongodll.}
proc getErr*(conn: var TMongo): cint{.stdcall, importc: "mongo_get_err", 
                                     dynlib: mongodll.}
proc isConnected*(conn: var TMongo): cint{.stdcall, 
    importc: "mongo_is_connected", dynlib: mongodll.}
proc getOpTimeout*(conn: var TMongo): cint{.stdcall, 
    importc: "mongo_get_op_timeout", dynlib: mongodll.}
proc getPrimary*(conn: var TMongo): cstring{.stdcall, 
    importc: "mongo_get_primary", dynlib: mongodll.}
proc getSocket*(conn: var TMongo): cint {.stdcall, importc: "mongo_get_socket", 
    dynlib: mongodll.}
proc getHostCount*(conn: var TMongo): cint{.stdcall, 
    importc: "mongo_get_host_count", dynlib: mongodll.}
proc getHost*(conn: var TMongo, i: cint): cstring {.stdcall, 
    importc: "mongo_get_host", dynlib: mongodll.}
proc createCursor*(): ptr TCursor{.stdcall, importc: "mongo_cursor_create", 
                                  dynlib: mongodll.}
proc dispose*(cursor: ptr TCursor){.stdcall, 
    importc: "mongo_cursor_dispose", dynlib: mongodll.}
proc getServerErr*(conn: var TMongo): cint{.stdcall, 
    importc: "mongo_get_server_err", dynlib: mongodll.}
proc getServerErrString*(conn: var TMongo): cstring{.stdcall, 
    importc: "mongo_get_server_err_string", dynlib: mongodll.}

proc init*(conn: var TMongo){.stdcall, importc: "mongo_init", dynlib: mongodll.}
  ## Initialize a new mongo connection object. You must initialize each mongo
  ## object using this function.
  ## When finished, you must pass this object to ``destroy``.

proc connect*(conn: var TMongo, host: cstring = defaultHost, 
              port: cint = defaultPort): cint {.stdcall, 
    importc: "mongo_connect", dynlib: mongodll, deprecated.}
  ## Connect to a single MongoDB server.
proc client*(conn: var TMongo, host: cstring = defaultHost, 
              port: cint = defaultPort): cint {.stdcall, 
    importc: "mongo_client", dynlib: mongodll.}
  ## Connect to a single MongoDB server.

proc replsetInit*(conn: var TMongo, name: cstring){.stdcall, 
    importc: "mongo_replset_init", dynlib: mongodll.}
  ## Set up this connection object for connecting to a replica set.
  ## To connect, pass the object to replsetConnect.
  ## `name` is the name of the replica set to connect to.

proc replsetAddSeed*(conn: var TMongo, host: cstring = defaultHost, 
  port: cint = defaultPort){.stdcall,
  importc: "mongo_replset_add_seed", dynlib: mongodll.}
  ## Add a seed node to the replica set connection object.
  ## You must specify at least one seed node before connecting
  ## to a replica set.

proc parseHost*(hostString: cstring, hostPort: var ThostPort){.stdcall, 
    importc: "mongo_parse_host", dynlib: mongodll.}
  ## Utility function for converting a host-port string to a mongo_host_port.
  ## `hostString` is a string containing either a host or a host and port
  ## separated by a colon.
  ## `hostPort` is the mongo_host_port object to write the result to.

proc replsetConnect*(conn: var TMongo): cint{.stdcall, 
    importc: "mongo_replset_connect", dynlib: mongodll.}
  ## Connect to a replica set.
  ## Before passing a connection object to this function, you must already
  ## have called setReplset and replsetAddSeed.

proc setOpTimeout*(conn: var TMongo, millis: cint): cint{.stdcall, 
    importc: "mongo_set_op_timeout", dynlib: mongodll.}
  ## Set a timeout for operations on this connection. This
  ## is a platform-specific feature, and only work on Unix-like
  ## systems. You must also compile for linux to support this.

proc checkConnection*(conn: var TMongo): cint {.stdcall, 
    importc: "mongo_check_connection", dynlib: mongodll.}
  ## Ensure that this connection is healthy by performing
  ## a round-trip to the server.
  ## Returns OK if connected; otherwise ERROR.

proc reconnect*(conn: var TMongo): cint {.stdcall, importc: "mongo_reconnect", 
    dynlib: mongodll.}
  ## Try reconnecting to the server using the existing connection settings.
  ## This function will disconnect the current socket. If you've authenticated,
  ## you'll need to re-authenticate after calling this function.

proc disconnect*(conn: var TMongo){.stdcall, importc: "mongo_disconnect", 
                                    dynlib: mongodll.}
  ## Close the current connection to the server. After calling
  ## this function, you may call reconnect with the same
  ## connection object.

proc destroy*(conn: var TMongo){.stdcall, importc: "mongo_destroy", 
                                 dynlib: mongodll.}
  ## Close any existing connection to the server and free all allocated
  ## memory associated with the conn object.
  ## You must always call this function when finished with the connection
  ## object.

proc insert*(conn: var TMongo, ns: cstring, data: var TBson,
             custom_write_concern: ptr TWriteConcern): cint{.stdcall, 
    importc: "mongo_insert", dynlib: mongodll, discardable.}
  ## Insert a BSON document into a MongoDB server. This function
  ## will fail if the supplied BSON struct is not UTF-8 or if
  ## the keys are invalid for insert (contain '.' or start with '$').

proc insertBatch*(conn: var TMongo, ns: cstring, 
                  data: ptr ptr TBson, num: cint): cint{.
    stdcall, importc: "mongo_insert_batch", dynlib: mongodll, discardable.}
  ## Insert a batch of BSON documents into a MongoDB server. This function
  ## will fail if any of the documents to be inserted is invalid.
  ## `num` is the number of documents in data.

proc update*(conn: var TMongo, ns: cstring, cond, op: var TBson, 
             flags: cint): cint{.stdcall, importc: "mongo_update", 
                                 dynlib: mongodll, discardable.}
  ## Update a document in a MongoDB server.
  ## 
  ## | conn a mongo object.
  ## | ns the namespace.
  ## | cond the bson update query.
  ## | op the bson update data.
  ## | flags flags for the update.
  ## | returns OK or ERROR with error stored in conn object.

proc remove*(conn: var TMongo, namespace: cstring, cond: var TBson): cint{.stdcall, 
    importc: "mongo_remove", dynlib: mongodll.}
  ## Remove a document from a MongoDB server.
  ##
  ## | conn a mongo object.
  ## | ns the namespace.
  ## | cond the bson query.
  ## | returns OK or ERROR with error stored in conn object.

proc find*(conn: var TMongo, namespace: cstring, query, fields: var TBson, 
           limit, skip: cint, options: cint): ptr TCursor{.stdcall, 
    importc: "mongo_find", dynlib: mongodll.}
  ## Find documents in a MongoDB server.
  ##
  ## | conn a mongo object.
  ## | ns the namespace.
  ## | query the bson query.
  ## | fields a bson document of fields to be returned.
  ## | limit the maximum number of documents to return.
  ## | skip the number of documents to skip.
  ## | options A bitfield containing cursor options.
  ## | returns A cursor object allocated on the heap or nil if
  ##   an error has occurred. For finer-grained error checking,
  ##   use the cursor builder API instead.

proc init*(cursor: var TCursor, conn: var TMongo, namespace: cstring){.stdcall, 
    importc: "mongo_cursor_init", dynlib: mongodll.}
  ## Initalize a new cursor object.
  ##
  ## The namespace is represented as the database
  ## name and collection name separated by a dot. e.g., "test.users".

proc setQuery*(cursor: var TCursor, query: var TBson) {.stdcall, 
    importc: "mongo_cursor_set_query", dynlib: mongodll.}
  ##  Set the bson object specifying this cursor's query spec. If
  ## your query is the empty bson object "{}", then you need not
  ## set this value.
  ##
  ## `query` is a bson object representing the query spec. This may
  ## be either a simple query spec or a complex spec storing values for
  ## $query, $orderby, $hint, and/or $explain. See
  ## http://www.mongodb.org/display/DOCS/Mongo+Wire+Protocol for details.

proc setFields*(cursor: var TCursor, fields: var TBson){.stdcall, 
    importc: "mongo_cursor_set_fields", dynlib: mongodll.}
  ## Set the fields to return for this cursor. If you want to return
  ## all fields, you need not set this value.
  ## `fields` is a bson object representing the fields to return.
  ## See http://www.mongodb.org/display/DOCS/Retrieving+a+Subset+of+Fields.

proc setSkip*(cursor: var TCursor, skip: cint){.stdcall, 
    importc: "mongo_cursor_set_skip", dynlib: mongodll.}
  ##  Set the number of documents to skip.

proc setLimit*(cursor: var TCursor, limit: cint){.stdcall, 
    importc: "mongo_cursor_set_limit", dynlib: mongodll.}
  ## Set the number of documents to return.

proc setOptions*(cursor: var TCursor, options: cint){.stdcall, 
    importc: "mongo_cursor_set_options", dynlib: mongodll.}
  ## Set any of the available query options (e.g., TAILABLE).
  ## See `TCursorOpts` for available constants.

proc data*(cursor: var TCursor): cstring {.stdcall, 
    importc: "mongo_cursor_data", dynlib: mongodll.}
  ## Return the current BSON object data as a ``cstring``. This is useful
  ## for creating bson iterators.

proc bson*(cursor: var TCursor): ptr TBson{.stdcall, 
    importc: "mongo_cursor_bson", dynlib: mongodll.}
  ## Return the current BSON object.

proc next*(cursor: var TCursor): cint {.stdcall, 
    importc: "mongo_cursor_next", dynlib: mongodll.}
  ## Iterate the cursor, returning the next item. When successful,
  ## the returned object will be stored in cursor.current;

proc destroy*(cursor: var TCursor): cint {.stdcall,
    importc: "mongo_cursor_destroy", dynlib: mongodll, discardable.}
  ## Destroy a cursor object. When finished with a cursor, you
  ## must pass it to this function.

proc findOne*(conn: var TMongo, namespace: cstring, query: var TBson, 
              fields: var TBson, outp: var TBson): cint{.stdcall, 
    importc: "mongo_find_one", dynlib: mongodll.}
  ## Find a single document in a MongoDB server.
  ##
  ## | conn a mongo object.
  ## | ns the namespace.
  ## | query the bson query.
  ## | fields a bson document of the fields to be returned.
  ## | outp a bson document in which to put the query result.
  ##   outp can be nil if you don't care about results. Useful for commands.

proc count*(conn: var TMongo, db: cstring, coll: cstring, query: var TBson): cdouble{.
    stdcall, importc: "mongo_count", dynlib: mongodll.}
  ## Count the number of documents in a collection matching a query.
  ##
  ## | conn a mongo object.
  ## | db the db name.
  ## | coll the collection name.
  ## | query the BSON query.
  ## | returns the number of matching documents. If the command fails,
  ##   ERROR is returned.

proc createIndex*(conn: var TMongo, namespace: cstring, key: var TBson, 
                   options: cint, outp: var TBson): cint {.stdcall, 
    importc: "mongo_create_index", dynlib: mongodll.}
  ##  Create a compouned index.
  ##
  ## | conn a mongo object.
  ## | ns the namespace.
  ## | data the bson index data.
  ## | options a bitfield for setting index options. Possibilities include
  ##   INDEX_UNIQUE, INDEX_DROP_DUPS, INDEX_BACKGROUND,
  ##   and INDEX_SPARSE.
  ## | out a bson document containing errors, if any.
  ## | returns MONGO_OK if index is created successfully; otherwise, MONGO_ERROR.

proc createSimpleIndex*(conn: var TMongo, namespace, field: cstring, 
                        options: cint, outp: var TBson): TBsonBool {.stdcall, 
    importc: "mongo_create_simple_index", dynlib: mongodll.}
  ## Create an index with a single key.
  ##
  ## | conn a mongo object.
  ## | ns the namespace.
  ## | field the index key.
  ## | options index options.
  ## | out a BSON document containing errors, if any.
  ## | returns true if the index was created.


# ----------------------------
#   COMMANDS
# ----------------------------


proc runCommand*(conn: var TMongo, db: cstring, command: var TBson, 
                  outp: var TBson): cint{.stdcall, importc: "mongo_run_command", 
    dynlib: mongodll.}
  ## Run a command on a MongoDB server.
  ## 
  ## | conn a mongo object.
  ## | db the name of the database.
  ## | command the BSON command to run.
  ## | out the BSON result of the command.
  ## | returns OK if the command ran without error.

proc simpleIntCommand*(conn: var TMongo, db: cstring, cmd: cstring, arg: cint, 
                         outp: var TBson): cint{.stdcall, 
    importc: "mongo_simple_int_command", dynlib: mongodll.}
  ## Run a command that accepts a simple string key and integer value.
  ##
  ## | conn a mongo object.
  ## | db the name of the database.
  ## | cmd the command to run.
  ## | arg the integer argument to the command.
  ## | out the BSON result of the command.
  ## | returns OK or an error code.

proc simpleStrCommand*(conn: var TMongo, db: cstring, cmd: cstring, 
                         arg: cstring, outp: var TBson): cint{.stdcall, 
    importc: "mongo_simple_str_command", dynlib: mongodll.}
  ## Run a command that accepts a simple string key and value.
  ##
  ## | conn a mongo object.
  ## | db the name of the database.
  ## | cmd the command to run.
  ## | arg the string argument to the command.
  ## | out the BSON result of the command.
  ## | returns true if the command ran without error.

proc cmdDropDb*(conn: var TMongo, db: cstring): cint{.stdcall, 
    importc: "mongo_cmd_drop_db", dynlib: mongodll.}
  ## Drop a database.
  ##
  ## | conn a mongo object.
  ## | db the name of the database to drop.
  ## | returns OK or an error code.

proc cmdDropCollection*(conn: var TMongo, db: cstring, collection: cstring, 
                          outp: var TBson): cint{.stdcall, 
    importc: "mongo_cmd_drop_collection", dynlib: mongodll.}
  ## Drop a collection.
  ##
  ## | conn a mongo object.
  ## | db the name of the database.
  ## | collection the name of the collection to drop.
  ## | out a BSON document containing the result of the command.
  ## | returns true if the collection drop was successful.

proc cmdAddUser*(conn: var TMongo, db: cstring, user: cstring, pass: cstring): cint{.
    stdcall, importc: "mongo_cmd_add_user", dynlib: mongodll.}
  ## Add a database user.
  ##
  ## | conn a mongo object.
  ## | db the database in which to add the user.
  ## | user the user name
  ## | pass the user password
  ## | returns OK or ERROR.

proc cmdAuthenticate*(conn: var TMongo, db: cstring, user: cstring, 
                      pass: cstring): cint{.stdcall, 
    importc: "mongo_cmd_authenticate", dynlib: mongodll.}
  ## Authenticate a user.
  ##
  ## | conn a mongo object.
  ## | db the database to authenticate against.
  ## | user the user name to authenticate.
  ## | pass the user's password.
  ## | returns OK on sucess and ERROR on failure.

proc cmdIsMaster*(conn: var TMongo, outp: var TBson): TBsonBool {.stdcall, 
    importc: "mongo_cmd_ismaster", dynlib: mongodll.}
  ## Check if the current server is a master.
  ##
  ## | conn a mongo object.
  ## | outp a BSON result of the command.
  ## | returns true if the server is a master.

proc cmdGetLastError*(conn: var TMongo, db: cstring, outp: var TBson): cint{.
    stdcall, importc: "mongo_cmd_get_last_error", dynlib: mongodll.}
  ## Get the error for the last command with the current connection.
  ##
  ## | conn a mongo object.
  ## | db the name of the database.
  ## | outp a BSON object containing the error details.
  ## | returns OK or ERROR

proc cmdGetPrevError*(conn: var TMongo, db: cstring, outp: var TBson): cint{.
    stdcall, importc: "mongo_cmd_get_prev_error", dynlib: mongodll.}
  ## Get the most recent error with the current connection.
  ##
  ## | conn a mongo object.
  ## | db the name of the database.
  ## | outp a BSON object containing the error details.
  ## | returns OK or ERROR.
  
proc cmdResetError*(conn: var TMongo, db: cstring){.stdcall, 
    importc: "mongo_cmd_reset_error", dynlib: mongodll.}
  ## Reset the error state for the connection. `db` is the name of the database.

# gridfs.h 

const 
  DEFAULT_CHUNK_SIZE* = 262144

type 
  TOffset* = int64

# A GridFS represents a single collection of GridFS files in the database. 

type 
  TGridfs*{.pure, final.} = object 
    client*: ptr TMongo       ## The client to db-connection. 
    dbname*: cstring          ## The root database name 
    prefix*: cstring          ## The prefix of the GridFS's collections,
                              ## default is nil 
    files_ns*: cstring        ## The namespace where the file's metadata
                              ## is stored
    chunks_ns*: cstring       ## The namespace where the files's data is
                              ## stored in chunks

# A GridFile is a single GridFS file. 

type 
  TGridFile*{.pure, final.} = object 
    gfs*: ptr TGridfs         ## GridFS where the GridFile is located 
    meta*: ptr TBson          ## GridFile's bson object where all
                              ## its metadata is located 
    pos*: TOffset             ## position is the offset in the file 
    id*: TOid                 ## files_id of the gridfile 
    remote_name*: cstring     ## name of the gridfile as a string 
    content_type*: cstring    ## gridfile's content type 
    length*: TOffset          ## length of this gridfile 
    chunk_num*: cint          ## number of the current chunk being written to 
    pending_data*: cstring    ## buffer storing data still to be
                              ## written to chunks 
    pending_len*: cint        ## length of pending_data buffer 
  

proc createGridfs*(): ptr TGridfs{.stdcall, importc: "gridfs_create", dynlib: mongodll.}
proc dispose*(gfs: ptr TGridfs){.stdcall, importc: "gridfs_dispose", 
                                 dynlib: mongodll.}
proc createGridfile*(): ptr TGridFile{.stdcall, importc: "gridfile_create", 
                               dynlib: mongodll.}
proc dispose*(gf: ptr TGridFile){.stdcall, importc: "gridfile_dispose", 
                                  dynlib: mongodll.}
proc getDescriptor*(gf: var TGridFile, outp: var TBson){.stdcall, 
    importc: "gridfile_get_descriptor", dynlib: mongodll.}


proc init*(client: var TMongo, dbname: cstring, prefix: cstring, 
           gfs: var TGridfs): cint{.stdcall, importc: "gridfs_init", 
                                    dynlib: mongodll.}
  ## Initializes a GridFS object
  ## 
  ## | client - db connection
  ## | dbname - database name
  ## | prefix - collection prefix, default is fs if NULL or empty
  ## | gfs - the GridFS object to initialize
  ## | returns - OK or ERROR.

proc destroy*(gfs: var TGridfs){.stdcall, importc: "gridfs_destroy", 
                                 dynlib: mongodll.}
  ## Destroys a GridFS object. Call this when finished with the object.

proc writerInit*(gfile: var TGridFile, gfs: var TGridfs, remote_name: cstring, 
                  content_type: cstring){.stdcall, 
    importc: "gridfile_writer_init", dynlib: mongodll.}
  ## Initializes a gridfile for writing incrementally with ``writeBuffer``.
  ## Once initialized, you can write any number of buffers with ``writeBuffer``.
  ## When done, you must call ``writerDone`` to save the file metadata.

proc writeBuffer*(gfile: var TGridFile, data: cstring, length: TOffset){.
    stdcall, importc: "gridfile_write_buffer", dynlib: mongodll.}
  ## Write to a GridFS file incrementally. You can call this function any number
  ## of times with a new buffer each time. This allows you to effectively
  ## stream to a GridFS file. When finished, be sure to call ``writerDone``.

proc writerDone*(gfile: var TGridFile): cint{.stdcall, 
    importc: "gridfile_writer_done", dynlib: mongodll.}
  ## Signal that writing of this gridfile is complete by
  ## writing any buffered chunks along with the entry in the
  ## files collection. Returns OK or ERROR.

proc storeBuffer*(gfs: var TGridfs, data: cstring, length: TOffset, 
                   remotename: cstring, contenttype: cstring): cint{.stdcall, 
    importc: "gridfs_store_buffer", dynlib: mongodll.}
  ## Store a buffer as a GridFS file.
  ##
  ## | gfs - the working GridFS
  ## | data - pointer to buffer to store in GridFS
  ## | length - length of the buffer
  ## | remotename - filename for use in the database
  ## | contenttype - optional MIME type for this object
  ## | returns - MONGO_OK or MONGO_ERROR.

proc storeFile*(gfs: var TGridfs, filename: cstring, remotename: cstring, 
                 contenttype: cstring): cint{.stdcall, 
    importc: "gridfs_store_file", dynlib: mongodll.}
  ## Open the file referenced by filename and store it as a GridFS file.
  ## 
  ## | gfs - the working GridFS
  ## | filename - local filename relative to the process
  ## | remotename - optional filename for use in the database
  ## | contenttype - optional MIME type for this object
  ## | returns - OK or ERROR.

proc removeFilename*(gfs: var TGridfs, filename: cstring){.stdcall, 
    importc: "gridfs_remove_filename", dynlib: mongodll.}
  ## Removes the files referenced by filename from the db.

proc findQuery*(gfs: var TGridfs, query: var TBson, gfile: var TGridFile): cint{.
    stdcall, importc: "gridfs_find_query", dynlib: mongodll.}
  ## Find the first file matching the provided query within the
  ## GridFS files collection, and return the file as a GridFile.
  ## Returns OK if successful, ERROR otherwise.
  
proc findFilename*(gfs: var TGridfs, filename: cstring, gfile: var TGridFile): cint{.
    stdcall, importc: "gridfs_find_filename", dynlib: mongodll.}
  ## Find the first file referenced by filename within the GridFS
  ## and return it as a GridFile. Returns OK or ERROR.

proc init*(gfs: var TGridfs, meta: var TBson, gfile: var TGridFile): cint{.
    stdcall, importc: "gridfile_init", dynlib: mongodll.}
  ## Initializes a GridFile containing the GridFS and file bson.

proc destroy*(gfile: var TGridFile){.stdcall, importc: "gridfile_destroy", 
                                     dynlib: mongodll.}
  ## Destroys the GridFile.

proc exists*(gfile: var TGridFile): TBsonBool{.stdcall, 
    importc: "gridfile_exists", dynlib: mongodll.}
  ## Returns whether or not the GridFile exists.

proc getFilename*(gfile: var TGridFile): cstring{.stdcall, 
    importc: "gridfile_get_filename", dynlib: mongodll.}
  ## Returns the filename of GridFile.

proc getChunksize*(gfile: var TGridFile): cint{.stdcall, 
    importc: "gridfile_get_chunksize", dynlib: mongodll.}
  ## Returns the size of the chunks of the GridFile.

proc getContentlength*(gfile: var TGridFile): TOffset{.stdcall, 
    importc: "gridfile_get_contentlength", dynlib: mongodll.}
  ## Returns the length of GridFile's data.

proc getContenttype*(gfile: var TGridFile): cstring{.stdcall, 
    importc: "gridfile_get_contenttype", dynlib: mongodll.}
  ## Returns the MIME type of the GridFile (nil if no type specified).

proc getUploaddate*(gfile: var TGridFile): Tdate{.stdcall, 
    importc: "gridfile_get_uploaddate", dynlib: mongodll.}
  ## Returns the upload date of GridFile.

proc getMd5*(gfile: var TGridFile): cstring {.stdcall, 
    importc: "gridfile_get_md5", dynlib: mongodll.}
  ## Returns the MD5 of GridFile.

proc getField*(gfile: var TGridFile, name: cstring): cstring{.stdcall, 
    importc: "gridfile_get_field", dynlib: mongodll.}
  ## Returns the field in GridFile specified by name. Returns the data of the
  ## field specified (nil if none exists).

proc getBoolean*(gfile: var TGridFile, name: cstring): TBsonBool{.stdcall, 
    importc: "gridfile_get_boolean", dynlib: mongodll.}
  ## Returns a boolean field in GridFile specified by name.

proc getMetadata*(gfile: var TGridFile, outp: var TBson){.stdcall, 
    importc: "gridfile_get_metadata", dynlib: mongodll.}
  ## Returns the metadata of GridFile (an empty bson is returned if none
  ## exists).

proc getNumchunks*(gfile: var TGridFile): cint{.stdcall, 
    importc: "gridfile_get_numchunks", dynlib: mongodll.}
  ## Returns the number of chunks in the GridFile.

proc getChunk*(gfile: var TGridFile, n: cint, outp: var TBson){.stdcall, 
    importc: "gridfile_get_chunk", dynlib: mongodll.}
  ## Returns chunk `n` of GridFile.

proc getChunks*(gfile: var TGridFile, start: cint, size: cint): ptr TCursor{.
    stdcall, importc: "gridfile_get_chunks", dynlib: mongodll.}
  ## Returns a mongo_cursor of `size` chunks starting with chunk `start`.
  ## The cursor must be destroyed after use.

proc writeFile*(gfile: ptr TGridFile, stream: TFile): TOffset{.stdcall, 
    importc: "gridfile_write_file", dynlib: mongodll.}
  ## Writes the GridFile to a stream.

proc read*(gfile: var TGridFile, size: TOffset, buf: cstring): TOffset{.stdcall, 
    importc: "gridfile_read", dynlib: mongodll.}
  ## Reads length bytes from the GridFile to a buffer
  ## and updates the position in the file.
  ## (assumes the buffer is large enough)
  ## (if size is greater than EOF gridfile_read reads until EOF).
  ## Returns the number of bytes read.

proc seek*(gfile: var TGridFile, offset: TOffset): TOffset{.stdcall, 
    importc: "gridfile_seek", dynlib: mongodll.}
  ## Updates the position in the file
  ## (If the offset goes beyond the contentlength,
  ## the position is updated to the end of the file.)
  ## Returns the offset location
