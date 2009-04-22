#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

{.deadCodeElim: on.}

when defined(windows): 
  const Sqlite3Lib = "sqlite3.dll"
elif defined(macosx):
  const Sqlite3Lib = "sqlite-3.6.13.dylib"
else: 
  const Sqlite3Lib = "libsqlite3.so"

const 
  SQLITE_INTEGER* = 1
  SQLITE_FLOAT* = 2
  SQLITE_BLOB* = 4
  SQLITE_NULL* = 5
  SQLITE_TEXT* = 3
  SQLITE3_TEXT* = 3
  SQLITE_UTF8* = 1
  SQLITE_UTF16LE* = 2
  SQLITE_UTF16BE* = 3         # Use native byte order  
  SQLITE_UTF16* = 4           # sqlite3_create_function only  
  SQLITE_ANY* = 5             #sqlite_exec return values
  SQLITE_OK* = 0
  SQLITE_ERROR* = 1           # SQL error or missing database  
  SQLITE_INTERNAL* = 2        # An internal logic error in SQLite  
  SQLITE_PERM* = 3            # Access permission denied  
  SQLITE_ABORT* = 4           # Callback routine requested an abort  
  SQLITE_BUSY* = 5            # The database file is locked  
  SQLITE_LOCKED* = 6          # A table in the database is locked  
  SQLITE_NOMEM* = 7           # A malloc() failed  
  SQLITE_READONLY* = 8        # Attempt to write a readonly database  
  SQLITE_INTERRUPT* = 9       # Operation terminated by sqlite3_interrupt() 
  SQLITE_IOERR* = 10          # Some kind of disk I/O error occurred  
  SQLITE_CORRUPT* = 11        # The database disk image is malformed  
  SQLITE_NOTFOUND* = 12       # (Internal Only) Table or record not found  
  SQLITE_FULL* = 13           # Insertion failed because database is full  
  SQLITE_CANTOPEN* = 14       # Unable to open the database file  
  SQLITE_PROTOCOL* = 15       # Database lock protocol error  
  SQLITE_EMPTY* = 16          # Database is empty  
  SQLITE_SCHEMA* = 17         # The database schema changed  
  SQLITE_TOOBIG* = 18         # Too much data for one row of a table  
  SQLITE_CONSTRAINT* = 19     # Abort due to contraint violation  
  SQLITE_MISMATCH* = 20       # Data type mismatch  
  SQLITE_MISUSE* = 21         # Library used incorrectly  
  SQLITE_NOLFS* = 22          # Uses OS features not supported on host  
  SQLITE_AUTH* = 23           # Authorization denied  
  SQLITE_FORMAT* = 24         # Auxiliary database format error  
  SQLITE_RANGE* = 25          # 2nd parameter to sqlite3_bind out of range  
  SQLITE_NOTADB* = 26         # File opened that is not a database file  
  SQLITE_ROW* = 100           # sqlite3_step() has another row ready  
  SQLITE_DONE* = 101          # sqlite3_step() has finished executing  
  SQLITE_COPY* = 0
  SQLITE_CREATE_INDEX* = 1
  SQLITE_CREATE_TABLE* = 2
  SQLITE_CREATE_TEMP_INDEX* = 3
  SQLITE_CREATE_TEMP_TABLE* = 4
  SQLITE_CREATE_TEMP_TRIGGER* = 5
  SQLITE_CREATE_TEMP_VIEW* = 6
  SQLITE_CREATE_TRIGGER* = 7
  SQLITE_CREATE_VIEW* = 8
  SQLITE_DELETE* = 9
  SQLITE_DROP_INDEX* = 10
  SQLITE_DROP_TABLE* = 11
  SQLITE_DROP_TEMP_INDEX* = 12
  SQLITE_DROP_TEMP_TABLE* = 13
  SQLITE_DROP_TEMP_TRIGGER* = 14
  SQLITE_DROP_TEMP_VIEW* = 15
  SQLITE_DROP_TRIGGER* = 16
  SQLITE_DROP_VIEW* = 17
  SQLITE_INSERT* = 18
  SQLITE_PRAGMA* = 19
  SQLITE_READ* = 20
  SQLITE_SELECT* = 21
  SQLITE_TRANSACTION* = 22
  SQLITE_UPDATE* = 23
  SQLITE_ATTACH* = 24
  SQLITE_DETACH* = 25
  SQLITE_ALTER_TABLE* = 26
  SQLITE_REINDEX* = 27
  SQLITE_DENY* = 1
  SQLITE_IGNORE* = 2          # Original from sqlite3.h: 
                              ##define SQLITE_STATIC      ((void(*)(void *))0)
                              ##define SQLITE_TRANSIENT   ((void(*)(void *))-1)

const 
  SQLITE_STATIC* = nil
  SQLITE_TRANSIENT* = cast[pointer](-1)

type 
  sqlite_int64* = int64
  PPPChar* = ptr ptr cstring
  TSqlite3 {.pure, final.} = object
  Psqlite3* = ptr TSqlite3
  PPSqlite3* = ptr PSqlite3
  TSqlLite3Context {.pure, final.} = object
  Psqlite3_context* = ptr TSqlLite3Context
  Tsqlite3_stmt {.pure, final.} = object
  Psqlite3_stmt* = ptr TSqlite3_stmt
  PPsqlite3_stmt* = ptr Psqlite3_stmt
  Tsqlite3_value {.pure, final.} = object
  Psqlite3_value* = ptr Tsqlite3_value
  PPsqlite3_value* = ptr Psqlite3_value #Callback function types
                                        #Notice that most functions 
                                        #were named using as prefix the 
                                        #function name that uses them,
                                        #rather than describing their functions  
  Tsqlite3_callback* = proc (para1: pointer, para2: int32, para3: var cstring, 
                             para4: var cstring): int32{.cdecl.}
  Tbind_destructor_func* = proc (para1: pointer){.cdecl.}
  Tcreate_function_step_func* = proc (para1: Psqlite3_context, para2: int32, 
                                     para3: PPsqlite3_value){.cdecl.}
  Tcreate_function_func_func* = proc (para1: Psqlite3_context, para2: int32, 
                                     para3: PPsqlite3_value){.cdecl.}
  Tcreate_function_final_func* = proc (para1: Psqlite3_context){.cdecl.}
  Tsqlite3_result_func* = proc (para1: pointer){.cdecl.}
  Tsqlite3_create_collation_func* = proc (para1: pointer, para2: int32, 
      para3: pointer, para4: int32, para5: pointer): int32{.cdecl.}
  Tsqlite3_collation_needed_func* = proc (para1: pointer, para2: Psqlite3, 
      eTextRep: int32, para4: cstring){.cdecl.}

proc sqlite3_close*(para1: Psqlite3): int32{.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_close".}
proc sqlite3_exec*(para1: Psqlite3, sql: cstring, para3: Tsqlite3_callback, 
                   para4: pointer, errmsg: var cstring): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_exec".}
proc sqlite3_last_insert_rowid*(para1: Psqlite3): sqlite_int64{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_last_insert_rowid".}
proc sqlite3_changes*(para1: Psqlite3): int32{.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_changes".}
proc sqlite3_total_changes*(para1: Psqlite3): int32{.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_total_changes".}
proc sqlite3_interrupt*(para1: Psqlite3){.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_interrupt".}
proc sqlite3_complete*(sql: cstring): int32{.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_complete".}
proc sqlite3_complete16*(sql: pointer): int32{.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_complete16".}
proc sqlite3_busy_handler*(para1: Psqlite3, 
    para2: proc (para1: pointer, para2: int32): int32 {.cdecl.}, 
    para3: pointer): int32{.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_busy_handler".}
proc sqlite3_busy_timeout*(para1: Psqlite3, ms: int32): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_busy_timeout".}
proc sqlite3_get_table*(para1: Psqlite3, sql: cstring, resultp: var cstringArray, 
                        nrow, ncolumn: var cint, errmsg: ptr cstring): int32{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_get_table".}
proc sqlite3_free_table*(result: cstringArray){.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_free_table".}
  # Todo: see how translate sqlite3_mprintf, sqlite3_vmprintf, sqlite3_snprintf
  # function sqlite3_mprintf(_para1:Pchar; args:array of const):Pchar;cdecl; external Sqlite3Lib name 'sqlite3_mprintf';
proc sqlite3_mprintf*(para1: cstring): cstring{.cdecl, varargs, dynlib: Sqlite3Lib, 
    importc: "sqlite3_mprintf".}
  #function sqlite3_vmprintf(_para1:Pchar; _para2:va_list):Pchar;cdecl; external Sqlite3Lib name 'sqlite3_vmprintf';
proc sqlite3_free*(z: cstring){.cdecl, dynlib: Sqlite3Lib, 
                                importc: "sqlite3_free".}
  #function sqlite3_snprintf(_para1:longint; _para2:Pchar; _para3:Pchar; args:array of const):Pchar;cdecl; external Sqlite3Lib name 'sqlite3_snprintf';
proc sqlite3_snprintf*(para1: int32, para2: cstring, para3: cstring): cstring{.
    cdecl, dynlib: Sqlite3Lib, varargs, importc: "sqlite3_snprintf".}
proc sqlite3_set_authorizer*(para1: Psqlite3, 
                             xAuth: proc (para1: pointer, para2: int32, 
                                      para3: cstring, para4: cstring, 
                                      para5: cstring, 
                                      para6: cstring): int32{.cdecl.}, 
                             pUserData: pointer): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_set_authorizer".}
proc sqlite3_trace*(para1: Psqlite3, 
                    xTrace: proc (para1: pointer, para2: cstring){.cdecl.}, 
                    para3: pointer): pointer{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_trace".}
proc sqlite3_progress_handler*(para1: Psqlite3, para2: int32, 
                               para3: proc (para1: pointer): int32 {.cdecl.}, 
                               para4: pointer){.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_progress_handler".}
proc sqlite3_commit_hook*(para1: Psqlite3, 
                          para2: proc (para1: pointer): int32{.cdecl.}, 
                          para3: pointer): pointer{.cdecl, dynlib: Sqlite3Lib,
    importc: "sqlite3_commit_hook".}
proc sqlite3_open*(filename: cstring, ppDb: var Psqlite3): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_open".}
proc sqlite3_open16*(filename: pointer, ppDb: var Psqlite3): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_open16".}
proc sqlite3_errcode*(db: Psqlite3): int32{.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_errcode".}
proc sqlite3_errmsg*(para1: Psqlite3): cstring{.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_errmsg".}
proc sqlite3_errmsg16*(para1: Psqlite3): pointer{.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_errmsg16".}
proc sqlite3_prepare*(db: Psqlite3, zSql: cstring, nBytes: int32, 
                      ppStmt: PPsqlite3_stmt, pzTail: ptr cstring): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_prepare".}
proc sqlite3_prepare16*(db: Psqlite3, zSql: pointer, nBytes: int32, 
                        ppStmt: PPsqlite3_stmt, pzTail: var pointer): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_prepare16".}
proc sqlite3_bind_blob*(para1: Psqlite3_stmt, para2: int32, para3: pointer, 
                        n: int32, para5: Tbind_destructor_func): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_bind_blob".}
proc sqlite3_bind_double*(para1: Psqlite3_stmt, para2: int32, para3: float64): int32{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_bind_double".}
proc sqlite3_bind_int*(para1: Psqlite3_stmt, para2: int32, para3: int32): int32{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_bind_int".}
proc sqlite3_bind_int64*(para1: Psqlite3_stmt, para2: int32, para3: sqlite_int64): int32{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_bind_int64".}
proc sqlite3_bind_null*(para1: Psqlite3_stmt, para2: int32): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_bind_null".}
proc sqlite3_bind_text*(para1: Psqlite3_stmt, para2: int32, para3: cstring, 
                        n: int32, para5: Tbind_destructor_func): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_bind_text".}
proc sqlite3_bind_text16*(para1: Psqlite3_stmt, para2: int32, para3: pointer, 
                          para4: int32, para5: Tbind_destructor_func): int32{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_bind_text16".}
  #function sqlite3_bind_value(_para1:Psqlite3_stmt; _para2:longint; _para3:Psqlite3_value):longint;cdecl; external Sqlite3Lib name 'sqlite3_bind_value';
  #These overloaded functions were introduced to allow the use of SQLITE_STATIC and SQLITE_TRANSIENT
  #It's the c world man ;-)
proc sqlite3_bind_blob*(para1: Psqlite3_stmt, para2: int32, para3: pointer, 
                        n: int32, para5: int32): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_bind_blob".}
proc sqlite3_bind_text*(para1: Psqlite3_stmt, para2: int32, para3: cstring, 
                        n: int32, para5: int32): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_bind_text".}
proc sqlite3_bind_text16*(para1: Psqlite3_stmt, para2: int32, para3: pointer, 
                          para4: int32, para5: int32): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_bind_text16".}
proc sqlite3_bind_parameter_count*(para1: Psqlite3_stmt): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_bind_parameter_count".}
proc sqlite3_bind_parameter_name*(para1: Psqlite3_stmt, para2: int32): cstring{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_bind_parameter_name".}
proc sqlite3_bind_parameter_index*(para1: Psqlite3_stmt, zName: cstring): int32{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_bind_parameter_index".}
  #function sqlite3_clear_bindings(_para1:Psqlite3_stmt):longint;cdecl; external Sqlite3Lib name 'sqlite3_clear_bindings';
proc sqlite3_column_count*(pStmt: Psqlite3_stmt): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_column_count".}
proc sqlite3_column_name*(para1: Psqlite3_stmt, para2: int32): cstring{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_column_name".}
proc sqlite3_column_name16*(para1: Psqlite3_stmt, para2: int32): pointer{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_column_name16".}
proc sqlite3_column_decltype*(para1: Psqlite3_stmt, i: int32): cstring{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_column_decltype".}
proc sqlite3_column_decltype16*(para1: Psqlite3_stmt, para2: int32): pointer{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_column_decltype16".}
proc sqlite3_step*(para1: Psqlite3_stmt): int32{.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_step".}
proc sqlite3_data_count*(pStmt: Psqlite3_stmt): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_data_count".}
proc sqlite3_column_blob*(para1: Psqlite3_stmt, iCol: int32): pointer{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_column_blob".}
proc sqlite3_column_bytes*(para1: Psqlite3_stmt, iCol: int32): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_column_bytes".}
proc sqlite3_column_bytes16*(para1: Psqlite3_stmt, iCol: int32): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_column_bytes16".}
proc sqlite3_column_double*(para1: Psqlite3_stmt, iCol: int32): float64{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_column_double".}
proc sqlite3_column_int*(para1: Psqlite3_stmt, iCol: int32): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_column_int".}
proc sqlite3_column_int64*(para1: Psqlite3_stmt, iCol: int32): sqlite_int64{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_column_int64".}
proc sqlite3_column_text*(para1: Psqlite3_stmt, iCol: int32): cstring{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_column_text".}
proc sqlite3_column_text16*(para1: Psqlite3_stmt, iCol: int32): pointer{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_column_text16".}
proc sqlite3_column_type*(para1: Psqlite3_stmt, iCol: int32): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_column_type".}
proc sqlite3_finalize*(pStmt: Psqlite3_stmt): int32{.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_finalize".}
proc sqlite3_reset*(pStmt: Psqlite3_stmt): int32{.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_reset".}
proc sqlite3_create_function*(para1: Psqlite3, zFunctionName: cstring, 
                              nArg: int32, eTextRep: int32, para5: pointer, 
                              xFunc: Tcreate_function_func_func, 
                              xStep: Tcreate_function_step_func, 
                              xFinal: Tcreate_function_final_func): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_create_function".}
proc sqlite3_create_function16*(para1: Psqlite3, zFunctionName: pointer, 
                                nArg: int32, eTextRep: int32, para5: pointer, 
                                xFunc: Tcreate_function_func_func, 
                                xStep: Tcreate_function_step_func, 
                                xFinal: Tcreate_function_final_func): int32{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_create_function16".}
proc sqlite3_aggregate_count*(para1: Psqlite3_context): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_aggregate_count".}
proc sqlite3_value_blob*(para1: Psqlite3_value): pointer{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_value_blob".}
proc sqlite3_value_bytes*(para1: Psqlite3_value): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_value_bytes".}
proc sqlite3_value_bytes16*(para1: Psqlite3_value): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_value_bytes16".}
proc sqlite3_value_double*(para1: Psqlite3_value): float64{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_value_double".}
proc sqlite3_value_int*(para1: Psqlite3_value): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_value_int".}
proc sqlite3_value_int64*(para1: Psqlite3_value): sqlite_int64{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_value_int64".}
proc sqlite3_value_text*(para1: Psqlite3_value): cstring{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_value_text".}
proc sqlite3_value_text16*(para1: Psqlite3_value): pointer{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_value_text16".}
proc sqlite3_value_text16le*(para1: Psqlite3_value): pointer{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_value_text16le".}
proc sqlite3_value_text16be*(para1: Psqlite3_value): pointer{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_value_text16be".}
proc sqlite3_value_type*(para1: Psqlite3_value): int32{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_value_type".}
proc sqlite3_aggregate_context*(para1: Psqlite3_context, nBytes: int32): pointer{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_aggregate_context".}
proc sqlite3_user_data*(para1: Psqlite3_context): pointer{.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_user_data".}
proc sqlite3_get_auxdata*(para1: Psqlite3_context, para2: int32): pointer{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_get_auxdata".}
proc sqlite3_set_auxdata*(para1: Psqlite3_context, para2: int32, para3: pointer, 
                          para4: proc (para1: pointer) {.cdecl.}){.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_set_auxdata".}
proc sqlite3_result_blob*(para1: Psqlite3_context, para2: pointer, para3: int32, 
                          para4: Tsqlite3_result_func){.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_result_blob".}
proc sqlite3_result_double*(para1: Psqlite3_context, para2: float64){.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_result_double".}
proc sqlite3_result_error*(para1: Psqlite3_context, para2: cstring, para3: int32){.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_result_error".}
proc sqlite3_result_error16*(para1: Psqlite3_context, para2: pointer, 
                             para3: int32){.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_result_error16".}
proc sqlite3_result_int*(para1: Psqlite3_context, para2: int32){.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_result_int".}
proc sqlite3_result_int64*(para1: Psqlite3_context, para2: sqlite_int64){.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_result_int64".}
proc sqlite3_result_null*(para1: Psqlite3_context){.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_result_null".}
proc sqlite3_result_text*(para1: Psqlite3_context, para2: cstring, para3: int32, 
                          para4: Tsqlite3_result_func){.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_result_text".}
proc sqlite3_result_text16*(para1: Psqlite3_context, para2: pointer, 
                            para3: int32, para4: Tsqlite3_result_func){.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_result_text16".}
proc sqlite3_result_text16le*(para1: Psqlite3_context, para2: pointer, 
                              para3: int32, para4: Tsqlite3_result_func){.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_result_text16le".}
proc sqlite3_result_text16be*(para1: Psqlite3_context, para2: pointer, 
                              para3: int32, para4: Tsqlite3_result_func){.cdecl, 
    dynlib: Sqlite3Lib, importc: "sqlite3_result_text16be".}
proc sqlite3_result_value*(para1: Psqlite3_context, para2: Psqlite3_value){.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_result_value".}
proc sqlite3_create_collation*(para1: Psqlite3, zName: cstring, eTextRep: int32, 
                               para4: pointer, 
                               xCompare: Tsqlite3_create_collation_func): int32{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_create_collation".}
proc sqlite3_create_collation16*(para1: Psqlite3, zName: cstring, 
                                 eTextRep: int32, para4: pointer, 
                                 xCompare: Tsqlite3_create_collation_func): int32{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_create_collation16".}
proc sqlite3_collation_needed*(para1: Psqlite3, para2: pointer, 
                               para3: Tsqlite3_collation_needed_func): int32{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_collation_needed".}
proc sqlite3_collation_needed16*(para1: Psqlite3, para2: pointer, 
                                 para3: Tsqlite3_collation_needed_func): int32{.
    cdecl, dynlib: Sqlite3Lib, importc: "sqlite3_collation_needed16".}
proc sqlite3_libversion*(): cstring{.cdecl, dynlib: Sqlite3Lib, 
                                     importc: "sqlite3_libversion".}
  #Alias for allowing better code portability (win32 is not working with external variables) 
proc sqlite3_version*(): cstring{.cdecl, dynlib: Sqlite3Lib, 
                                  importc: "sqlite3_libversion".}
  # Not published functions
proc sqlite3_libversion_number*(): int32{.cdecl, dynlib: Sqlite3Lib, 
    importc: "sqlite3_libversion_number".}
  #function sqlite3_key(db:Psqlite3; pKey:pointer; nKey:longint):longint;cdecl; external Sqlite3Lib name 'sqlite3_key';
  #function sqlite3_rekey(db:Psqlite3; pKey:pointer; nKey:longint):longint;cdecl; external Sqlite3Lib name 'sqlite3_rekey';
  #function sqlite3_sleep(_para1:longint):longint;cdecl; external Sqlite3Lib name 'sqlite3_sleep';
  #function sqlite3_expired(_para1:Psqlite3_stmt):longint;cdecl; external Sqlite3Lib name 'sqlite3_expired';
  #function sqlite3_global_recover:longint;cdecl; external Sqlite3Lib name 'sqlite3_global_recover';
# implementation
