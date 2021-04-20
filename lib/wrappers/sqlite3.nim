#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(nimHasStyleChecks):
  {.push styleChecks: off.}

when defined(windows):
  when defined(nimOldDlls):
    const Lib = "sqlite3.dll"
  elif defined(cpu64):
    const Lib = "sqlite3_64.dll"
  else:
    const Lib = "sqlite3_32.dll"
elif defined(macosx):
  const
    Lib = "libsqlite3(|.0).dylib"
else:
  const
    Lib = "libsqlite3.so(|.0)"

when defined(staticSqlite):
  {.pragma: mylib.}
  {.compile("sqlite3.c", "-O3").}
else:
  {.pragma: mylib, dynlib: Lib.}

const
  SQLITE_INTEGER* = 1
  SQLITE_FLOAT* = 2
  SQLITE_BLOB* = 4
  SQLITE_NULL* = 5
  SQLITE_TEXT* = 3
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
  SQLITE_CONSTRAINT* = 19     # Abort due to constraint violation
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
                              #define SQLITE_STATIC      ((void(*)(void *))0)
                              #define SQLITE_TRANSIENT   ((void(*)(void *))-1)
  SQLITE_DETERMINISTIC* = 0x800

type
  Sqlite3 {.pure, final.} = object
  PSqlite3* = ptr Sqlite3
  PPSqlite3* = ptr PSqlite3
  Sqlite3_Backup {.pure, final.} = object
  PSqlite3_Backup* = ptr Sqlite3_Backup
  PPSqlite3_Backup* = ptr PSqlite3_Backup
  Context{.pure, final.} = object
  Pcontext* = ptr Context
  TStmt{.pure, final.} = object
  PStmt* = ptr TStmt
  Value{.pure, final.} = object
  PValue* = ptr Value
  PValueArg* = array[0..127, PValue]

  Callback* = proc (para1: pointer, para2: int32, para3,
                     para4: cstringArray): int32{.cdecl.}
  Tbind_destructor_func* = proc (para1: pointer){.cdecl, locks: 0, tags: [], gcsafe.}
  Create_function_step_func* = proc (para1: Pcontext, para2: int32,
                                      para3: PValueArg){.cdecl.}
  Create_function_func_func* = proc (para1: Pcontext, para2: int32,
                                      para3: PValueArg){.cdecl.}
  Create_function_final_func* = proc (para1: Pcontext){.cdecl.}
  Result_func* = proc (para1: pointer){.cdecl.}
  Create_collation_func* = proc (para1: pointer, para2: int32, para3: pointer,
                                  para4: int32, para5: pointer): int32{.cdecl.}
  Collation_needed_func* = proc (para1: pointer, para2: PSqlite3, eTextRep: int32,
                                  para4: cstring){.cdecl.}

const
  SQLITE_STATIC* = nil
  SQLITE_TRANSIENT* = cast[Tbind_destructor_func](-1)

proc close*(para1: PSqlite3): int32{.cdecl, mylib, importc: "sqlite3_close".}
proc exec*(para1: PSqlite3, sql: cstring, para3: Callback, para4: pointer,
           errmsg: var cstring): int32{.cdecl, mylib,
                                        importc: "sqlite3_exec".}
proc last_insert_rowid*(para1: PSqlite3): int64{.cdecl, mylib,
    importc: "sqlite3_last_insert_rowid".}
proc changes*(para1: PSqlite3): int32{.cdecl, mylib, importc: "sqlite3_changes".}
proc total_changes*(para1: PSqlite3): int32{.cdecl, mylib,
                                      importc: "sqlite3_total_changes".}
proc interrupt*(para1: PSqlite3){.cdecl, mylib, importc: "sqlite3_interrupt".}
proc complete*(sql: cstring): int32{.cdecl, mylib,
                                     importc: "sqlite3_complete".}
proc complete16*(sql: pointer): int32{.cdecl, mylib,
                                       importc: "sqlite3_complete16".}
proc busy_handler*(para1: PSqlite3,
                   para2: proc (para1: pointer, para2: int32): int32{.cdecl.},
                   para3: pointer): int32{.cdecl, mylib,
    importc: "sqlite3_busy_handler".}
proc busy_timeout*(para1: PSqlite3, ms: int32): int32{.cdecl, mylib,
    importc: "sqlite3_busy_timeout".}
proc get_table*(para1: PSqlite3, sql: cstring, resultp: var cstringArray,
                nrow, ncolumn: var cint, errmsg: ptr cstring): int32{.cdecl,
    mylib, importc: "sqlite3_get_table".}
proc free_table*(result: cstringArray){.cdecl, mylib,
                                        importc: "sqlite3_free_table".}
  # Todo: see how translate sqlite3_mprintf, sqlite3_vmprintf, sqlite3_snprintf
  # function sqlite3_mprintf(_para1:Pchar; args:array of const):Pchar;cdecl; external Sqlite3Lib name 'sqlite3_mprintf';
proc mprintf*(para1: cstring): cstring{.cdecl, varargs, mylib,
                                        importc: "sqlite3_mprintf".}
  #function sqlite3_vmprintf(_para1:Pchar; _para2:va_list):Pchar;cdecl; external Sqlite3Lib name 'sqlite3_vmprintf';
proc free*(z: cstring){.cdecl, mylib, importc: "sqlite3_free".}
  #function sqlite3_snprintf(_para1:longint; _para2:Pchar; _para3:Pchar; args:array of const):Pchar;cdecl; external Sqlite3Lib name 'sqlite3_snprintf';
proc snprintf*(para1: int32, para2: cstring, para3: cstring): cstring{.cdecl,
    mylib, varargs, importc: "sqlite3_snprintf".}
proc set_authorizer*(para1: PSqlite3, xAuth: proc (para1: pointer, para2: int32,
    para3: cstring, para4: cstring, para5: cstring, para6: cstring): int32{.
    cdecl.}, pUserData: pointer): int32{.cdecl, mylib,
    importc: "sqlite3_set_authorizer".}
proc trace*(para1: PSqlite3, xTrace: proc (para1: pointer, para2: cstring){.cdecl.},
            para3: pointer): pointer{.cdecl, mylib,
                                      importc: "sqlite3_trace".}
proc progress_handler*(para1: PSqlite3, para2: int32,
                       para3: proc (para1: pointer): int32{.cdecl.},
                       para4: pointer){.cdecl, mylib,
                                        importc: "sqlite3_progress_handler".}
proc commit_hook*(para1: PSqlite3, para2: proc (para1: pointer): int32{.cdecl.},
                  para3: pointer): pointer{.cdecl, mylib,
    importc: "sqlite3_commit_hook".}
proc open*(filename: cstring, ppDb: var PSqlite3): int32{.cdecl, mylib,
    importc: "sqlite3_open".}
proc open16*(filename: pointer, ppDb: var PSqlite3): int32{.cdecl, mylib,
    importc: "sqlite3_open16".}
proc errcode*(db: PSqlite3): int32{.cdecl, mylib, importc: "sqlite3_errcode".}
proc errmsg*(para1: PSqlite3): cstring{.cdecl, mylib, importc: "sqlite3_errmsg".}
proc errmsg16*(para1: PSqlite3): pointer{.cdecl, mylib,
                                   importc: "sqlite3_errmsg16".}
proc prepare*(db: PSqlite3, zSql: cstring, nBytes: int32, ppStmt: var PStmt,
              pzTail: ptr cstring): int32{.cdecl, mylib,
    importc: "sqlite3_prepare".}

proc prepare_v2*(db: PSqlite3, zSql: cstring, nByte: cint, ppStmt: var PStmt,
                pzTail: ptr cstring): cint {.
                importc: "sqlite3_prepare_v2", cdecl, mylib.}

proc prepare16*(db: PSqlite3, zSql: pointer, nBytes: int32, ppStmt: var PStmt,
                pzTail: var pointer): int32{.cdecl, mylib,
    importc: "sqlite3_prepare16".}
proc bind_blob*(para1: PStmt, para2: int32, para3: pointer, n: int32,
                para5: Tbind_destructor_func): int32{.cdecl, mylib,
    importc: "sqlite3_bind_blob".}
proc bind_double*(para1: PStmt, para2: int32, para3: float64): int32{.cdecl,
    mylib, importc: "sqlite3_bind_double".}
proc bind_int*(para1: PStmt, para2: int32, para3: int32): int32{.cdecl,
    mylib, importc: "sqlite3_bind_int".}
proc bind_int64*(para1: PStmt, para2: int32, para3: int64): int32{.cdecl,
    mylib, importc: "sqlite3_bind_int64".}
proc bind_null*(para1: PStmt, para2: int32): int32{.cdecl, mylib,
    importc: "sqlite3_bind_null".}
proc bind_text*(para1: PStmt, para2: int32, para3: cstring, n: int32,
                para5: Tbind_destructor_func): int32{.cdecl, mylib,
    importc: "sqlite3_bind_text".}
proc bind_text16*(para1: PStmt, para2: int32, para3: pointer, para4: int32,
                  para5: Tbind_destructor_func): int32{.cdecl, mylib,
    importc: "sqlite3_bind_text16".}
  #function sqlite3_bind_value(_para1:Psqlite3_stmt; _para2:longint; _para3:Psqlite3_value):longint;cdecl; external Sqlite3Lib name 'sqlite3_bind_value';
  #These overloaded functions were introduced to allow the use of SQLITE_STATIC and SQLITE_TRANSIENT
  #It's the c world man ;-)
proc bind_blob*(para1: PStmt, para2: int32, para3: pointer, n: int32,
                para5: int32): int32{.cdecl, mylib,
                                      importc: "sqlite3_bind_blob".}
proc bind_text*(para1: PStmt, para2: int32, para3: cstring, n: int32,
                para5: int32): int32{.cdecl, mylib,
                                      importc: "sqlite3_bind_text".}
proc bind_text16*(para1: PStmt, para2: int32, para3: pointer, para4: int32,
                  para5: int32): int32{.cdecl, mylib,
                                        importc: "sqlite3_bind_text16".}
proc bind_parameter_count*(para1: PStmt): int32{.cdecl, mylib,
    importc: "sqlite3_bind_parameter_count".}
proc bind_parameter_name*(para1: PStmt, para2: int32): cstring{.cdecl,
    mylib, importc: "sqlite3_bind_parameter_name".}
proc bind_parameter_index*(para1: PStmt, zName: cstring): int32{.cdecl,
    mylib, importc: "sqlite3_bind_parameter_index".}
proc clear_bindings*(para1: PStmt): int32 {.cdecl,
    mylib, importc: "sqlite3_clear_bindings".}
proc column_count*(PStmt: PStmt): int32{.cdecl, mylib,
    importc: "sqlite3_column_count".}
proc column_name*(para1: PStmt, para2: int32): cstring{.cdecl, mylib,
    importc: "sqlite3_column_name".}
proc column_table_name*(para1: PStmt; para2: int32): cstring{.cdecl, mylib,
    importc: "sqlite3_column_table_name".}
proc column_name16*(para1: PStmt, para2: int32): pointer{.cdecl, mylib,
    importc: "sqlite3_column_name16".}
proc column_decltype*(para1: PStmt, i: int32): cstring{.cdecl, mylib,
    importc: "sqlite3_column_decltype".}
proc column_decltype16*(para1: PStmt, para2: int32): pointer{.cdecl,
    mylib, importc: "sqlite3_column_decltype16".}
proc step*(para1: PStmt): int32{.cdecl, mylib, importc: "sqlite3_step".}
proc data_count*(PStmt: PStmt): int32{.cdecl, mylib,
                                       importc: "sqlite3_data_count".}
proc column_blob*(para1: PStmt, iCol: int32): pointer{.cdecl, mylib,
    importc: "sqlite3_column_blob".}
proc column_bytes*(para1: PStmt, iCol: int32): int32{.cdecl, mylib,
    importc: "sqlite3_column_bytes".}
proc column_bytes16*(para1: PStmt, iCol: int32): int32{.cdecl, mylib,
    importc: "sqlite3_column_bytes16".}
proc column_double*(para1: PStmt, iCol: int32): float64{.cdecl, mylib,
    importc: "sqlite3_column_double".}
proc column_int*(para1: PStmt, iCol: int32): int32{.cdecl, mylib,
    importc: "sqlite3_column_int".}
proc column_int64*(para1: PStmt, iCol: int32): int64{.cdecl, mylib,
    importc: "sqlite3_column_int64".}
proc column_text*(para1: PStmt, iCol: int32): cstring{.cdecl, mylib,
    importc: "sqlite3_column_text".}
proc column_text16*(para1: PStmt, iCol: int32): pointer{.cdecl, mylib,
    importc: "sqlite3_column_text16".}
proc column_type*(para1: PStmt, iCol: int32): int32{.cdecl, mylib,
    importc: "sqlite3_column_type".}
proc finalize*(PStmt: PStmt): int32{.cdecl, mylib,
                                     importc: "sqlite3_finalize".}
proc reset*(PStmt: PStmt): int32{.cdecl, mylib, importc: "sqlite3_reset".}
proc create_function*(para1: PSqlite3, zFunctionName: cstring, nArg: int32,
                      eTextRep: int32, para5: pointer,
                      xFunc: Create_function_func_func,
                      xStep: Create_function_step_func,
                      xFinal: Create_function_final_func): int32{.cdecl,
    mylib, importc: "sqlite3_create_function".}
proc create_function16*(para1: PSqlite3, zFunctionName: pointer, nArg: int32,
                        eTextRep: int32, para5: pointer,
                        xFunc: Create_function_func_func,
                        xStep: Create_function_step_func,
                        xFinal: Create_function_final_func): int32{.cdecl,
    mylib, importc: "sqlite3_create_function16".}
proc aggregate_count*(para1: Pcontext): int32{.cdecl, mylib,
    importc: "sqlite3_aggregate_count".}
proc value_blob*(para1: PValue): pointer{.cdecl, mylib,
    importc: "sqlite3_value_blob".}
proc value_bytes*(para1: PValue): int32{.cdecl, mylib,
    importc: "sqlite3_value_bytes".}
proc value_bytes16*(para1: PValue): int32{.cdecl, mylib,
    importc: "sqlite3_value_bytes16".}
proc value_double*(para1: PValue): float64{.cdecl, mylib,
    importc: "sqlite3_value_double".}
proc value_int*(para1: PValue): int32{.cdecl, mylib,
                                       importc: "sqlite3_value_int".}
proc value_int64*(para1: PValue): int64{.cdecl, mylib,
    importc: "sqlite3_value_int64".}
proc value_text*(para1: PValue): cstring{.cdecl, mylib,
    importc: "sqlite3_value_text".}
proc value_text16*(para1: PValue): pointer{.cdecl, mylib,
    importc: "sqlite3_value_text16".}
proc value_text16le*(para1: PValue): pointer{.cdecl, mylib,
    importc: "sqlite3_value_text16le".}
proc value_text16be*(para1: PValue): pointer{.cdecl, mylib,
    importc: "sqlite3_value_text16be".}
proc value_type*(para1: PValue): int32{.cdecl, mylib,
                                        importc: "sqlite3_value_type".}
proc aggregate_context*(para1: Pcontext, nBytes: int32): pointer{.cdecl,
    mylib, importc: "sqlite3_aggregate_context".}
proc user_data*(para1: Pcontext): pointer{.cdecl, mylib,
    importc: "sqlite3_user_data".}
proc get_auxdata*(para1: Pcontext, para2: int32): pointer{.cdecl, mylib,
    importc: "sqlite3_get_auxdata".}
proc set_auxdata*(para1: Pcontext, para2: int32, para3: pointer,
                  para4: proc (para1: pointer){.cdecl.}){.cdecl, mylib,
    importc: "sqlite3_set_auxdata".}
proc result_blob*(para1: Pcontext, para2: pointer, para3: int32,
                  para4: Result_func){.cdecl, mylib,
                                        importc: "sqlite3_result_blob".}
proc result_double*(para1: Pcontext, para2: float64){.cdecl, mylib,
    importc: "sqlite3_result_double".}
proc result_error*(para1: Pcontext, para2: cstring, para3: int32){.cdecl,
    mylib, importc: "sqlite3_result_error".}
proc result_error16*(para1: Pcontext, para2: pointer, para3: int32){.cdecl,
    mylib, importc: "sqlite3_result_error16".}
proc result_int*(para1: Pcontext, para2: int32){.cdecl, mylib,
    importc: "sqlite3_result_int".}
proc result_int64*(para1: Pcontext, para2: int64){.cdecl, mylib,
    importc: "sqlite3_result_int64".}
proc result_null*(para1: Pcontext){.cdecl, mylib,
                                    importc: "sqlite3_result_null".}
proc result_text*(para1: Pcontext, para2: cstring, para3: int32,
                  para4: Result_func){.cdecl, mylib,
                                        importc: "sqlite3_result_text".}
proc result_text16*(para1: Pcontext, para2: pointer, para3: int32,
                    para4: Result_func){.cdecl, mylib,
    importc: "sqlite3_result_text16".}
proc result_text16le*(para1: Pcontext, para2: pointer, para3: int32,
                      para4: Result_func){.cdecl, mylib,
    importc: "sqlite3_result_text16le".}
proc result_text16be*(para1: Pcontext, para2: pointer, para3: int32,
                      para4: Result_func){.cdecl, mylib,
    importc: "sqlite3_result_text16be".}
proc result_value*(para1: Pcontext, para2: PValue){.cdecl, mylib,
    importc: "sqlite3_result_value".}
proc create_collation*(para1: PSqlite3, zName: cstring, eTextRep: int32,
                       para4: pointer, xCompare: Create_collation_func): int32{.
    cdecl, mylib, importc: "sqlite3_create_collation".}
proc create_collation16*(para1: PSqlite3, zName: cstring, eTextRep: int32,
                         para4: pointer, xCompare: Create_collation_func): int32{.
    cdecl, mylib, importc: "sqlite3_create_collation16".}
proc collation_needed*(para1: PSqlite3, para2: pointer, para3: Collation_needed_func): int32{.
    cdecl, mylib, importc: "sqlite3_collation_needed".}
proc collation_needed16*(para1: PSqlite3, para2: pointer, para3: Collation_needed_func): int32{.
    cdecl, mylib, importc: "sqlite3_collation_needed16".}
proc libversion*(): cstring{.cdecl, mylib, importc: "sqlite3_libversion".}
  #Alias for allowing better code portability (win32 is not working with external variables)
proc version*(): cstring{.cdecl, mylib, importc: "sqlite3_libversion".}
  # Not published functions
proc libversion_number*(): int32{.cdecl, mylib,
                                  importc: "sqlite3_libversion_number".}

proc backup_init*(pDest: PSqlite3, zDestName: cstring, pSource: PSqlite3, zSourceName: cstring): PSqlite3_Backup {.
    cdecl, mylib, importc: "sqlite3_backup_init".}

proc backup_step*(pBackup: PSqlite3_Backup, nPage: int32): int32 {.cdecl, mylib, importc: "sqlite3_backup_step".}

proc backup_finish*(pBackup: PSqlite3_Backup): int32 {.cdecl, mylib, importc: "sqlite3_backup_finish".}

proc backup_pagecount*(pBackup: PSqlite3_Backup): int32 {.cdecl, mylib, importc: "sqlite3_backup_pagecount".}

proc backup_remaining*(pBackup: PSqlite3_Backup): int32 {.cdecl, mylib, importc: "sqlite3_backup_remaining".}

proc sqlite3_sleep*(t: int64): int64 {.cdecl, mylib, importc: "sqlite3_sleep".}

  #function sqlite3_key(db:Psqlite3; pKey:pointer; nKey:longint):longint;cdecl; external Sqlite3Lib name 'sqlite3_key';
  #function sqlite3_rekey(db:Psqlite3; pKey:pointer; nKey:longint):longint;cdecl; external Sqlite3Lib name 'sqlite3_rekey';
  #function sqlite3_sleep(_para1:longint):longint;cdecl; external Sqlite3Lib name 'sqlite3_sleep';
  #function sqlite3_expired(_para1:Psqlite3_stmt):longint;cdecl; external Sqlite3Lib name 'sqlite3_expired';
  #function sqlite3_global_recover:longint;cdecl; external Sqlite3Lib name 'sqlite3_global_recover';
# implementation

when defined(nimHasStyleChecks):
  {.pop.}
