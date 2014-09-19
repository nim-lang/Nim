# This module contains the definitions for structures and externs for
# functions used by frontend postgres applications. It is based on
# Postgresql's libpq-fe.h.
#
# It is for postgreSQL version 7.4 and higher with support for the v3.0
# connection-protocol.
#

{.deadCodeElim: on.}

when defined(windows): 
  const 
    dllName = "libpq.dll"
elif defined(macosx): 
  const 
    dllName = "libpq.dylib"
else: 
  const 
    dllName = "libpq.so(.5|)"
type 
  POid* = ptr Oid
  Oid* = int32

const 
  ERROR_MSG_LENGTH* = 4096
  CMDSTATUS_LEN* = 40

type 
  TSockAddr* = array[1..112, int8]
  TPGresAttDesc*{.pure, final.} = object 
    name*: cstring
    adtid*: Oid
    adtsize*: int

  PPGresAttDesc* = ptr TPGresAttDesc
  PPPGresAttDesc* = ptr PPGresAttDesc
  TPGresAttValue*{.pure, final.} = object 
    length*: int32
    value*: cstring

  PPGresAttValue* = ptr TPGresAttValue
  PPPGresAttValue* = ptr PPGresAttValue
  PExecStatusType* = ptr TExecStatusType
  TExecStatusType* = enum 
    PGRES_EMPTY_QUERY = 0, PGRES_COMMAND_OK, PGRES_TUPLES_OK, PGRES_COPY_OUT, 
    PGRES_COPY_IN, PGRES_BAD_RESPONSE, PGRES_NONFATAL_ERROR, PGRES_FATAL_ERROR
  TPGlobjfuncs*{.pure, final.} = object 
    fn_lo_open*: Oid
    fn_lo_close*: Oid
    fn_lo_creat*: Oid
    fn_lo_unlink*: Oid
    fn_lo_lseek*: Oid
    fn_lo_tell*: Oid
    fn_lo_read*: Oid
    fn_lo_write*: Oid

  PPGlobjfuncs* = ptr TPGlobjfuncs
  PConnStatusType* = ptr TConnStatusType
  TConnStatusType* = enum 
    CONNECTION_OK, CONNECTION_BAD, CONNECTION_STARTED, CONNECTION_MADE, 
    CONNECTION_AWAITING_RESPONSE, CONNECTION_AUTH_OK, CONNECTION_SETENV, 
    CONNECTION_SSL_STARTUP, CONNECTION_NEEDED
  TPGconn*{.pure, final.} = object 
    pghost*: cstring
    pgtty*: cstring
    pgport*: cstring
    pgoptions*: cstring
    dbName*: cstring
    status*: TConnStatusType
    errorMessage*: array[0..(ERROR_MSG_LENGTH) - 1, char]
    Pfin*: TFile
    Pfout*: TFile
    Pfdebug*: TFile
    sock*: int32
    laddr*: TSockAddr
    raddr*: TSockAddr
    salt*: array[0..(2) - 1, char]
    asyncNotifyWaiting*: int32
    notifyList*: pointer
    pguser*: cstring
    pgpass*: cstring
    lobjfuncs*: PPGlobjfuncs

  PPGconn* = ptr TPGconn
  TPGresult*{.pure, final.} = object 
    ntups*: int32
    numAttributes*: int32
    attDescs*: PPGresAttDesc
    tuples*: PPPGresAttValue
    tupArrSize*: int32
    resultStatus*: TExecStatusType
    cmdStatus*: array[0..(CMDSTATUS_LEN) - 1, char]
    binary*: int32
    conn*: PPGconn

  PPGresult* = ptr TPGresult
  PPostgresPollingStatusType* = ptr PostgresPollingStatusType
  PostgresPollingStatusType* = enum 
    PGRES_POLLING_FAILED = 0, PGRES_POLLING_READING, PGRES_POLLING_WRITING, 
    PGRES_POLLING_OK, PGRES_POLLING_ACTIVE
  PPGTransactionStatusType* = ptr PGTransactionStatusType
  PGTransactionStatusType* = enum 
    PQTRANS_IDLE, PQTRANS_ACTIVE, PQTRANS_INTRANS, PQTRANS_INERROR, 
    PQTRANS_UNKNOWN
  PPGVerbosity* = ptr PGVerbosity
  PGVerbosity* = enum 
    PQERRORS_TERSE, PQERRORS_DEFAULT, PQERRORS_VERBOSE
  PpgNotify* = ptr pgNotify
  pgNotify*{.pure, final.} = object 
    relname*: cstring
    be_pid*: int32
    extra*: cstring

  PQnoticeReceiver* = proc (arg: pointer, res: PPGresult){.cdecl.}
  PQnoticeProcessor* = proc (arg: pointer, message: cstring){.cdecl.}
  Ppqbool* = ptr pqbool
  pqbool* = char
  P_PQprintOpt* = ptr PQprintOpt
  PQprintOpt*{.pure, final.} = object 
    header*: pqbool
    align*: pqbool
    standard*: pqbool
    html3*: pqbool
    expanded*: pqbool
    pager*: pqbool
    fieldSep*: cstring
    tableOpt*: cstring
    caption*: cstring
    fieldName*: ptr cstring

  P_PQconninfoOption* = ptr PQconninfoOption
  PQconninfoOption*{.pure, final.} = object 
    keyword*: cstring
    envvar*: cstring
    compiled*: cstring
    val*: cstring
    label*: cstring
    dispchar*: cstring
    dispsize*: int32

  PPQArgBlock* = ptr PQArgBlock
  PQArgBlock*{.pure, final.} = object 
    length*: int32
    isint*: int32
    p*: pointer


proc PQconnectStart*(conninfo: cstring): PPGconn{.cdecl, dynlib: dllName, 
    importc: "PQconnectStart".}
proc PQconnectPoll*(conn: PPGconn): PostgresPollingStatusType{.cdecl, 
    dynlib: dllName, importc: "PQconnectPoll".}
proc PQconnectdb*(conninfo: cstring): PPGconn{.cdecl, dynlib: dllName, 
    importc: "PQconnectdb".}
proc PQsetdbLogin*(pghost: cstring, pgport: cstring, pgoptions: cstring, 
                   pgtty: cstring, dbName: cstring, login: cstring, pwd: cstring): PPGconn{.
    cdecl, dynlib: dllName, importc: "PQsetdbLogin".}
proc PQsetdb*(M_PGHOST, M_PGPORT, M_PGOPT, M_PGTTY, M_DBNAME: cstring): ppgconn
proc PQfinish*(conn: PPGconn){.cdecl, dynlib: dllName, importc: "PQfinish".}
proc PQconndefaults*(): PPQconninfoOption{.cdecl, dynlib: dllName, 
    importc: "PQconndefaults".}
proc PQconninfoFree*(connOptions: PPQconninfoOption){.cdecl, dynlib: dllName, 
    importc: "PQconninfoFree".}
proc PQresetStart*(conn: PPGconn): int32{.cdecl, dynlib: dllName, 
    importc: "PQresetStart".}
proc PQresetPoll*(conn: PPGconn): PostgresPollingStatusType{.cdecl, 
    dynlib: dllName, importc: "PQresetPoll".}
proc PQreset*(conn: PPGconn){.cdecl, dynlib: dllName, importc: "PQreset".}
proc PQrequestCancel*(conn: PPGconn): int32{.cdecl, dynlib: dllName, 
    importc: "PQrequestCancel".}
proc PQdb*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, importc: "PQdb".}
proc PQuser*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, importc: "PQuser".}
proc PQpass*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, importc: "PQpass".}
proc PQhost*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, importc: "PQhost".}
proc PQport*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, importc: "PQport".}
proc PQtty*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, importc: "PQtty".}
proc PQoptions*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, 
    importc: "PQoptions".}
proc PQstatus*(conn: PPGconn): TConnStatusType{.cdecl, dynlib: dllName, 
    importc: "PQstatus".}
proc PQtransactionStatus*(conn: PPGconn): PGTransactionStatusType{.cdecl, 
    dynlib: dllName, importc: "PQtransactionStatus".}
proc PQparameterStatus*(conn: PPGconn, paramName: cstring): cstring{.cdecl, 
    dynlib: dllName, importc: "PQparameterStatus".}
proc PQprotocolVersion*(conn: PPGconn): int32{.cdecl, dynlib: dllName, 
    importc: "PQprotocolVersion".}
proc PQerrorMessage*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, 
    importc: "PQerrorMessage".}
proc PQsocket*(conn: PPGconn): int32{.cdecl, dynlib: dllName, 
                                      importc: "PQsocket".}
proc PQbackendPID*(conn: PPGconn): int32{.cdecl, dynlib: dllName, 
    importc: "PQbackendPID".}
proc PQclientEncoding*(conn: PPGconn): int32{.cdecl, dynlib: dllName, 
    importc: "PQclientEncoding".}
proc PQsetClientEncoding*(conn: PPGconn, encoding: cstring): int32{.cdecl, 
    dynlib: dllName, importc: "PQsetClientEncoding".}
when defined(USE_SSL): 
  # Get the SSL structure associated with a connection  
  proc PQgetssl*(conn: PPGconn): PSSL{.cdecl, dynlib: dllName, 
                                       importc: "PQgetssl".}
proc PQsetErrorVerbosity*(conn: PPGconn, verbosity: PGVerbosity): PGVerbosity{.
    cdecl, dynlib: dllName, importc: "PQsetErrorVerbosity".}
proc PQtrace*(conn: PPGconn, debug_port: TFile){.cdecl, dynlib: dllName, 
    importc: "PQtrace".}
proc PQuntrace*(conn: PPGconn){.cdecl, dynlib: dllName, importc: "PQuntrace".}
proc PQsetNoticeReceiver*(conn: PPGconn, theProc: PQnoticeReceiver, arg: pointer): PQnoticeReceiver{.
    cdecl, dynlib: dllName, importc: "PQsetNoticeReceiver".}
proc PQsetNoticeProcessor*(conn: PPGconn, theProc: PQnoticeProcessor, 
                           arg: pointer): PQnoticeProcessor{.cdecl, 
    dynlib: dllName, importc: "PQsetNoticeProcessor".}
proc PQexec*(conn: PPGconn, query: cstring): PPGresult{.cdecl, dynlib: dllName, 
    importc: "PQexec".}
proc PQexecParams*(conn: PPGconn, command: cstring, nParams: int32, 
                   paramTypes: POid, paramValues: cstringArray, 
                   paramLengths, paramFormats: ptr int32, resultFormat: int32): PPGresult{.
    cdecl, dynlib: dllName, importc: "PQexecParams".}
proc PQprepare*(conn: PPGconn, stmtName, query: cstring, nParams: int32,
    paramTypes: POid): PPGresult{.cdecl, dynlib: dllName, importc: "PQprepare".}
proc PQexecPrepared*(conn: PPGconn, stmtName: cstring, nParams: int32, 
                     paramValues: cstringArray, 
                     paramLengths, paramFormats: ptr int32, resultFormat: int32): PPGresult{.
    cdecl, dynlib: dllName, importc: "PQexecPrepared".}
proc PQsendQuery*(conn: PPGconn, query: cstring): int32{.cdecl, dynlib: dllName, 
    importc: "PQsendQuery".}
proc PQsendQueryParams*(conn: PPGconn, command: cstring, nParams: int32, 
                        paramTypes: POid, paramValues: cstringArray, 
                        paramLengths, paramFormats: ptr int32, 
                        resultFormat: int32): int32{.cdecl, dynlib: dllName, 
    importc: "PQsendQueryParams".}
proc PQsendQueryPrepared*(conn: PPGconn, stmtName: cstring, nParams: int32, 
                          paramValues: cstringArray, 
                          paramLengths, paramFormats: ptr int32, 
                          resultFormat: int32): int32{.cdecl, dynlib: dllName, 
    importc: "PQsendQueryPrepared".}
proc PQgetResult*(conn: PPGconn): PPGresult{.cdecl, dynlib: dllName, 
    importc: "PQgetResult".}
proc PQisBusy*(conn: PPGconn): int32{.cdecl, dynlib: dllName, 
                                      importc: "PQisBusy".}
proc PQconsumeInput*(conn: PPGconn): int32{.cdecl, dynlib: dllName, 
    importc: "PQconsumeInput".}
proc PQnotifies*(conn: PPGconn): PPGnotify{.cdecl, dynlib: dllName, 
    importc: "PQnotifies".}
proc PQputCopyData*(conn: PPGconn, buffer: cstring, nbytes: int32): int32{.
    cdecl, dynlib: dllName, importc: "PQputCopyData".}
proc PQputCopyEnd*(conn: PPGconn, errormsg: cstring): int32{.cdecl, 
    dynlib: dllName, importc: "PQputCopyEnd".}
proc PQgetCopyData*(conn: PPGconn, buffer: cstringArray, async: int32): int32{.
    cdecl, dynlib: dllName, importc: "PQgetCopyData".}
proc PQgetline*(conn: PPGconn, str: cstring, len: int32): int32{.cdecl, 
    dynlib: dllName, importc: "PQgetline".}
proc PQputline*(conn: PPGconn, str: cstring): int32{.cdecl, dynlib: dllName, 
    importc: "PQputline".}
proc PQgetlineAsync*(conn: PPGconn, buffer: cstring, bufsize: int32): int32{.
    cdecl, dynlib: dllName, importc: "PQgetlineAsync".}
proc PQputnbytes*(conn: PPGconn, buffer: cstring, nbytes: int32): int32{.cdecl, 
    dynlib: dllName, importc: "PQputnbytes".}
proc PQendcopy*(conn: PPGconn): int32{.cdecl, dynlib: dllName, 
                                       importc: "PQendcopy".}
proc PQsetnonblocking*(conn: PPGconn, arg: int32): int32{.cdecl, 
    dynlib: dllName, importc: "PQsetnonblocking".}
proc PQisnonblocking*(conn: PPGconn): int32{.cdecl, dynlib: dllName, 
    importc: "PQisnonblocking".}
proc PQflush*(conn: PPGconn): int32{.cdecl, dynlib: dllName, importc: "PQflush".}
proc PQfn*(conn: PPGconn, fnid: int32, result_buf, result_len: ptr int32, 
           result_is_int: int32, args: PPQArgBlock, nargs: int32): PPGresult{.
    cdecl, dynlib: dllName, importc: "PQfn".}
proc PQresultStatus*(res: PPGresult): TExecStatusType{.cdecl, dynlib: dllName, 
    importc: "PQresultStatus".}
proc PQresStatus*(status: TExecStatusType): cstring{.cdecl, dynlib: dllName, 
    importc: "PQresStatus".}
proc PQresultErrorMessage*(res: PPGresult): cstring{.cdecl, dynlib: dllName, 
    importc: "PQresultErrorMessage".}
proc PQresultErrorField*(res: PPGresult, fieldcode: int32): cstring{.cdecl, 
    dynlib: dllName, importc: "PQresultErrorField".}
proc PQntuples*(res: PPGresult): int32{.cdecl, dynlib: dllName, 
                                        importc: "PQntuples".}
proc PQnfields*(res: PPGresult): int32{.cdecl, dynlib: dllName, 
                                        importc: "PQnfields".}
proc PQbinaryTuples*(res: PPGresult): int32{.cdecl, dynlib: dllName, 
    importc: "PQbinaryTuples".}
proc PQfname*(res: PPGresult, field_num: int32): cstring{.cdecl, 
    dynlib: dllName, importc: "PQfname".}
proc PQfnumber*(res: PPGresult, field_name: cstring): int32{.cdecl, 
    dynlib: dllName, importc: "PQfnumber".}
proc PQftable*(res: PPGresult, field_num: int32): Oid{.cdecl, dynlib: dllName, 
    importc: "PQftable".}
proc PQftablecol*(res: PPGresult, field_num: int32): int32{.cdecl, 
    dynlib: dllName, importc: "PQftablecol".}
proc PQfformat*(res: PPGresult, field_num: int32): int32{.cdecl, 
    dynlib: dllName, importc: "PQfformat".}
proc PQftype*(res: PPGresult, field_num: int32): Oid{.cdecl, dynlib: dllName, 
    importc: "PQftype".}
proc PQfsize*(res: PPGresult, field_num: int32): int32{.cdecl, dynlib: dllName, 
    importc: "PQfsize".}
proc PQfmod*(res: PPGresult, field_num: int32): int32{.cdecl, dynlib: dllName, 
    importc: "PQfmod".}
proc PQcmdStatus*(res: PPGresult): cstring{.cdecl, dynlib: dllName, 
    importc: "PQcmdStatus".}
proc PQoidStatus*(res: PPGresult): cstring{.cdecl, dynlib: dllName, 
    importc: "PQoidStatus".}
proc PQoidValue*(res: PPGresult): Oid{.cdecl, dynlib: dllName, 
                                       importc: "PQoidValue".}
proc PQcmdTuples*(res: PPGresult): cstring{.cdecl, dynlib: dllName, 
    importc: "PQcmdTuples".}
proc PQgetvalue*(res: PPGresult, tup_num: int32, field_num: int32): cstring{.
    cdecl, dynlib: dllName, importc: "PQgetvalue".}
proc PQgetlength*(res: PPGresult, tup_num: int32, field_num: int32): int32{.
    cdecl, dynlib: dllName, importc: "PQgetlength".}
proc PQgetisnull*(res: PPGresult, tup_num: int32, field_num: int32): int32{.
    cdecl, dynlib: dllName, importc: "PQgetisnull".}
proc PQclear*(res: PPGresult){.cdecl, dynlib: dllName, importc: "PQclear".}
proc PQfreemem*(p: pointer){.cdecl, dynlib: dllName, importc: "PQfreemem".}
proc PQmakeEmptyPGresult*(conn: PPGconn, status: TExecStatusType): PPGresult{.
    cdecl, dynlib: dllName, importc: "PQmakeEmptyPGresult".}
proc PQescapeString*(till, `from`: cstring, len: int): int{.cdecl, 
    dynlib: dllName, importc: "PQescapeString".}
proc PQescapeBytea*(bintext: cstring, binlen: int, bytealen: var int): cstring{.
    cdecl, dynlib: dllName, importc: "PQescapeBytea".}
proc PQunescapeBytea*(strtext: cstring, retbuflen: var int): cstring{.cdecl, 
    dynlib: dllName, importc: "PQunescapeBytea".}
proc PQprint*(fout: TFile, res: PPGresult, ps: PPQprintOpt){.cdecl, 
    dynlib: dllName, importc: "PQprint".}
proc PQdisplayTuples*(res: PPGresult, fp: TFile, fillAlign: int32, 
                      fieldSep: cstring, printHeader: int32, quiet: int32){.
    cdecl, dynlib: dllName, importc: "PQdisplayTuples".}
proc PQprintTuples*(res: PPGresult, fout: TFile, printAttName: int32, 
                    terseOutput: int32, width: int32){.cdecl, dynlib: dllName, 
    importc: "PQprintTuples".}
proc lo_open*(conn: PPGconn, lobjId: Oid, mode: int32): int32{.cdecl, 
    dynlib: dllName, importc: "lo_open".}
proc lo_close*(conn: PPGconn, fd: int32): int32{.cdecl, dynlib: dllName, 
    importc: "lo_close".}
proc lo_read*(conn: PPGconn, fd: int32, buf: cstring, length: int): int32{.
    cdecl, dynlib: dllName, importc: "lo_read".}
proc lo_write*(conn: PPGconn, fd: int32, buf: cstring, length: int): int32{.
    cdecl, dynlib: dllName, importc: "lo_write".}
proc lo_lseek*(conn: PPGconn, fd: int32, offset: int32, whence: int32): int32{.
    cdecl, dynlib: dllName, importc: "lo_lseek".}
proc lo_creat*(conn: PPGconn, mode: int32): Oid{.cdecl, dynlib: dllName, 
    importc: "lo_creat".}
proc lo_tell*(conn: PPGconn, fd: int32): int32{.cdecl, dynlib: dllName, 
    importc: "lo_tell".}
proc lo_unlink*(conn: PPGconn, lobjId: Oid): int32{.cdecl, dynlib: dllName, 
    importc: "lo_unlink".}
proc lo_import*(conn: PPGconn, filename: cstring): Oid{.cdecl, dynlib: dllName, 
    importc: "lo_import".}
proc lo_export*(conn: PPGconn, lobjId: Oid, filename: cstring): int32{.cdecl, 
    dynlib: dllName, importc: "lo_export".}
proc PQmblen*(s: cstring, encoding: int32): int32{.cdecl, dynlib: dllName, 
    importc: "PQmblen".}
proc PQenv2encoding*(): int32{.cdecl, dynlib: dllName, importc: "PQenv2encoding".}
proc PQsetdb(M_PGHOST, M_PGPORT, M_PGOPT, M_PGTTY, M_DBNAME: cstring): ppgconn = 
  result = PQsetdbLogin(M_PGHOST, M_PGPORT, M_PGOPT, M_PGTTY, M_DBNAME, "", "")
