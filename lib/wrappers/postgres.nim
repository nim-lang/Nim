#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module contains the definitions for structures and externs for
# functions used by frontend postgres applications. It is based on
# Postgresql's libpq-fe.h.
#
# It is for postgreSQL version 7.4 and higher with support for the v3.0
# connection-protocol.
#

when defined(nimHasStyleChecks):
  {.push styleChecks: off.}

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
  SockAddr* = array[1..112, int8]
  PGresAttDesc*{.pure, final.} = object
    name*: cstring
    adtid*: Oid
    adtsize*: int

  PPGresAttDesc* = ptr PGresAttDesc
  PPPGresAttDesc* = ptr PPGresAttDesc
  PGresAttValue*{.pure, final.} = object
    length*: int32
    value*: cstring

  PPGresAttValue* = ptr PGresAttValue
  PPPGresAttValue* = ptr PPGresAttValue
  PExecStatusType* = ptr ExecStatusType
  ExecStatusType* = enum
    PGRES_EMPTY_QUERY = 0, PGRES_COMMAND_OK, PGRES_TUPLES_OK, PGRES_COPY_OUT,
    PGRES_COPY_IN, PGRES_BAD_RESPONSE, PGRES_NONFATAL_ERROR, PGRES_FATAL_ERROR,
    PGRES_COPY_BOTH, PGRES_SINGLE_TUPLE
  PGlobjfuncs*{.pure, final.} = object
    fn_lo_open*: Oid
    fn_lo_close*: Oid
    fn_lo_creat*: Oid
    fn_lo_unlink*: Oid
    fn_lo_lseek*: Oid
    fn_lo_tell*: Oid
    fn_lo_read*: Oid
    fn_lo_write*: Oid

  PPGlobjfuncs* = ptr PGlobjfuncs
  PConnStatusType* = ptr ConnStatusType
  ConnStatusType* = enum
    CONNECTION_OK, CONNECTION_BAD, CONNECTION_STARTED, CONNECTION_MADE,
    CONNECTION_AWAITING_RESPONSE, CONNECTION_AUTH_OK, CONNECTION_SETENV,
    CONNECTION_SSL_STARTUP, CONNECTION_NEEDED, CONNECTION_CHECK_WRITABLE,
    CONNECTION_CONSUME, CONNECTION_GSS_STARTUP, CONNECTION_CHECK_TARGET
  PGconn*{.pure, final.} = object
    pghost*: cstring
    pgtty*: cstring
    pgport*: cstring
    pgoptions*: cstring
    dbName*: cstring
    status*: ConnStatusType
    errorMessage*: array[0..(ERROR_MSG_LENGTH) - 1, char]
    Pfin*: File
    Pfout*: File
    Pfdebug*: File
    sock*: int32
    laddr*: SockAddr
    raddr*: SockAddr
    salt*: array[0..(2) - 1, char]
    asyncNotifyWaiting*: int32
    notifyList*: pointer
    pguser*: cstring
    pgpass*: cstring
    lobjfuncs*: PPGlobjfuncs

  PPGconn* = ptr PGconn
  PGresult*{.pure, final.} = object
    ntups*: int32
    numAttributes*: int32
    attDescs*: PPGresAttDesc
    tuples*: PPPGresAttValue
    tupArrSize*: int32
    resultStatus*: ExecStatusType
    cmdStatus*: array[0..(CMDSTATUS_LEN) - 1, char]
    binary*: int32
    conn*: PPGconn

  PPGresult* = ptr PGresult
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
    PQERRORS_TERSE, PQERRORS_DEFAULT, PQERRORS_VERBOSE, PQERRORS_SQLSTATE
  PPGNotify* = ptr pgNotify
  pgNotify*{.pure, final.} = object
    relname*: cstring
    be_pid*: int32
    extra*: cstring

  PQnoticeReceiver* = proc (arg: pointer, res: PPGresult){.cdecl.}
  PQnoticeProcessor* = proc (arg: pointer, message: cstring){.cdecl.}
  Ppqbool* = ptr pqbool
  pqbool* = char
  PPQprintOpt* = ptr PQprintOpt
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

  PPQconninfoOption* = ptr PQconninfoOption
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

proc pqinitOpenSSL*(do_ssl: int32, do_crypto: int32) {.cdecl, dynlib: dllName,
    importc: "PQinitOpenSSL".}
proc pqconnectStart*(conninfo: cstring): PPGconn{.cdecl, dynlib: dllName,
    importc: "PQconnectStart".}
proc pqconnectPoll*(conn: PPGconn): PostgresPollingStatusType{.cdecl,
    dynlib: dllName, importc: "PQconnectPoll".}
proc pqconnectdb*(conninfo: cstring): PPGconn{.cdecl, dynlib: dllName,
    importc: "PQconnectdb".}
proc pqsetdbLogin*(pghost: cstring, pgport: cstring, pgoptions: cstring,
                   pgtty: cstring, dbName: cstring, login: cstring, pwd: cstring): PPGconn{.
    cdecl, dynlib: dllName, importc: "PQsetdbLogin".}
proc pqsetdb*(M_PGHOST, M_PGPORT, M_PGOPT, M_PGTTY, M_DBNAME: cstring): PPGconn
proc pqfinish*(conn: PPGconn){.cdecl, dynlib: dllName, importc: "PQfinish".}
proc pqconndefaults*(): PPQconninfoOption{.cdecl, dynlib: dllName,
    importc: "PQconndefaults".}
proc pqconninfoFree*(connOptions: PPQconninfoOption){.cdecl, dynlib: dllName,
    importc: "PQconninfoFree".}
proc pqresetStart*(conn: PPGconn): int32{.cdecl, dynlib: dllName,
    importc: "PQresetStart".}
proc pqresetPoll*(conn: PPGconn): PostgresPollingStatusType{.cdecl,
    dynlib: dllName, importc: "PQresetPoll".}
proc pqreset*(conn: PPGconn){.cdecl, dynlib: dllName, importc: "PQreset".}
proc pqrequestCancel*(conn: PPGconn): int32{.cdecl, dynlib: dllName,
    importc: "PQrequestCancel".}
proc pqdb*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, importc: "PQdb".}
proc pquser*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, importc: "PQuser".}
proc pqpass*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, importc: "PQpass".}
proc pqhost*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, importc: "PQhost".}
proc pqport*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, importc: "PQport".}
proc pqtty*(conn: PPGconn): cstring{.cdecl, dynlib: dllName, importc: "PQtty".}
proc pqoptions*(conn: PPGconn): cstring{.cdecl, dynlib: dllName,
    importc: "PQoptions".}
proc pqstatus*(conn: PPGconn): ConnStatusType{.cdecl, dynlib: dllName,
    importc: "PQstatus".}
proc pqtransactionStatus*(conn: PPGconn): PGTransactionStatusType{.cdecl,
    dynlib: dllName, importc: "PQtransactionStatus".}
proc pqparameterStatus*(conn: PPGconn, paramName: cstring): cstring{.cdecl,
    dynlib: dllName, importc: "PQparameterStatus".}
proc pqserverVersion*(conn: PPGconn): int32{.cdecl,
    dynlib: dllName, importc: "PQserverVersion".}
proc pqprotocolVersion*(conn: PPGconn): int32{.cdecl, dynlib: dllName,
    importc: "PQprotocolVersion".}
proc pqerrorMessage*(conn: PPGconn): cstring{.cdecl, dynlib: dllName,
    importc: "PQerrorMessage".}
proc pqsocket*(conn: PPGconn): int32{.cdecl, dynlib: dllName,
                                      importc: "PQsocket".}
proc pqbackendPID*(conn: PPGconn): int32{.cdecl, dynlib: dllName,
    importc: "PQbackendPID".}
proc pqconnectionNeedsPassword*(conn: PPGconn): int32{.cdecl, dynlib: dllName,
    importc: "PQconnectionNeedsPassword".}
proc pqconnectionUsedPassword*(conn: PPGconn): int32{.cdecl, dynlib: dllName,
    importc: "PQconnectionUsedPassword".}
proc pqclientEncoding*(conn: PPGconn): int32{.cdecl, dynlib: dllName,
    importc: "PQclientEncoding".}
proc pqsetClientEncoding*(conn: PPGconn, encoding: cstring): int32{.cdecl,
    dynlib: dllName, importc: "PQsetClientEncoding".}
when defined(USE_SSL):
  # Get the SSL structure associated with a connection
  proc pqgetssl*(conn: PPGconn): PSSL{.cdecl, dynlib: dllName,
                                       importc: "PQgetssl".}
proc pqsetErrorVerbosity*(conn: PPGconn, verbosity: PGVerbosity): PGVerbosity{.
    cdecl, dynlib: dllName, importc: "PQsetErrorVerbosity".}
proc pqtrace*(conn: PPGconn, debug_port: File){.cdecl, dynlib: dllName,
    importc: "PQtrace".}
proc pquntrace*(conn: PPGconn){.cdecl, dynlib: dllName, importc: "PQuntrace".}
proc pqsetNoticeReceiver*(conn: PPGconn, theProc: PQnoticeReceiver, arg: pointer): PQnoticeReceiver{.
    cdecl, dynlib: dllName, importc: "PQsetNoticeReceiver".}
proc pqsetNoticeProcessor*(conn: PPGconn, theProc: PQnoticeProcessor,
                           arg: pointer): PQnoticeProcessor{.cdecl,
    dynlib: dllName, importc: "PQsetNoticeProcessor".}
proc pqexec*(conn: PPGconn, query: cstring): PPGresult{.cdecl, dynlib: dllName,
    importc: "PQexec".}
proc pqexecParams*(conn: PPGconn, command: cstring, nParams: int32,
                   paramTypes: POid, paramValues: cstringArray,
                   paramLengths, paramFormats: ptr int32, resultFormat: int32): PPGresult{.
    cdecl, dynlib: dllName, importc: "PQexecParams".}
proc pqprepare*(conn: PPGconn, stmtName, query: cstring, nParams: int32,
    paramTypes: POid): PPGresult{.cdecl, dynlib: dllName, importc: "PQprepare".}
proc pqexecPrepared*(conn: PPGconn, stmtName: cstring, nParams: int32,
                     paramValues: cstringArray,
                     paramLengths, paramFormats: ptr int32, resultFormat: int32): PPGresult{.
    cdecl, dynlib: dllName, importc: "PQexecPrepared".}
proc pqsendQuery*(conn: PPGconn, query: cstring): int32{.cdecl, dynlib: dllName,
    importc: "PQsendQuery".}
  ## See also https://www.postgresql.org/docs/current/libpq-async.html
proc pqsendQueryParams*(conn: PPGconn, command: cstring, nParams: int32,
                        paramTypes: POid, paramValues: cstringArray,
                        paramLengths, paramFormats: ptr int32,
                        resultFormat: int32): int32{.cdecl, dynlib: dllName,
    importc: "PQsendQueryParams".}
proc pqsendQueryPrepared*(conn: PPGconn, stmtName: cstring, nParams: int32,
                          paramValues: cstringArray,
                          paramLengths, paramFormats: ptr int32,
                          resultFormat: int32): int32{.cdecl, dynlib: dllName,
    importc: "PQsendQueryPrepared".}
proc pqSetSingleRowMode*(conn: PPGconn): int32{.cdecl, dynlib: dllName,
    importc: "PQsetSingleRowMode".}
  ## See also https://www.postgresql.org/docs/current/libpq-single-row-mode.html
proc pqgetResult*(conn: PPGconn): PPGresult{.cdecl, dynlib: dllName,
    importc: "PQgetResult".}
proc pqisBusy*(conn: PPGconn): int32{.cdecl, dynlib: dllName,
                                      importc: "PQisBusy".}
proc pqconsumeInput*(conn: PPGconn): int32{.cdecl, dynlib: dllName,
    importc: "PQconsumeInput".}
proc pqnotifies*(conn: PPGconn): PPGNotify{.cdecl, dynlib: dllName,
    importc: "PQnotifies".}
proc pqputCopyData*(conn: PPGconn, buffer: cstring, nbytes: int32): int32{.
    cdecl, dynlib: dllName, importc: "PQputCopyData".}
proc pqputCopyEnd*(conn: PPGconn, errormsg: cstring): int32{.cdecl,
    dynlib: dllName, importc: "PQputCopyEnd".}
proc pqgetCopyData*(conn: PPGconn, buffer: cstringArray, async: int32): int32{.
    cdecl, dynlib: dllName, importc: "PQgetCopyData".}
proc pqgetline*(conn: PPGconn, str: cstring, len: int32): int32{.cdecl,
    dynlib: dllName, importc: "PQgetline".}
proc pqputline*(conn: PPGconn, str: cstring): int32{.cdecl, dynlib: dllName,
    importc: "PQputline".}
proc pqgetlineAsync*(conn: PPGconn, buffer: cstring, bufsize: int32): int32{.
    cdecl, dynlib: dllName, importc: "PQgetlineAsync".}
proc pqputnbytes*(conn: PPGconn, buffer: cstring, nbytes: int32): int32{.cdecl,
    dynlib: dllName, importc: "PQputnbytes".}
proc pqendcopy*(conn: PPGconn): int32{.cdecl, dynlib: dllName,
                                       importc: "PQendcopy".}
proc pqsetnonblocking*(conn: PPGconn, arg: int32): int32{.cdecl,
    dynlib: dllName, importc: "PQsetnonblocking".}
proc pqisnonblocking*(conn: PPGconn): int32{.cdecl, dynlib: dllName,
    importc: "PQisnonblocking".}
proc pqflush*(conn: PPGconn): int32{.cdecl, dynlib: dllName, importc: "PQflush".}
proc pqfn*(conn: PPGconn, fnid: int32, result_buf, result_len: ptr int32,
           result_is_int: int32, args: PPQArgBlock, nargs: int32): PPGresult{.
    cdecl, dynlib: dllName, importc: "PQfn".}
proc pqresultStatus*(res: PPGresult): ExecStatusType{.cdecl, dynlib: dllName,
    importc: "PQresultStatus".}
proc pqresStatus*(status: ExecStatusType): cstring{.cdecl, dynlib: dllName,
    importc: "PQresStatus".}
proc pqresultErrorMessage*(res: PPGresult): cstring{.cdecl, dynlib: dllName,
    importc: "PQresultErrorMessage".}
proc pqresultErrorField*(res: PPGresult, fieldcode: int32): cstring{.cdecl,
    dynlib: dllName, importc: "PQresultErrorField".}
proc pqntuples*(res: PPGresult): int32{.cdecl, dynlib: dllName,
                                        importc: "PQntuples".}
proc pqnfields*(res: PPGresult): int32{.cdecl, dynlib: dllName,
                                        importc: "PQnfields".}
proc pqbinaryTuples*(res: PPGresult): int32{.cdecl, dynlib: dllName,
    importc: "PQbinaryTuples".}
proc pqfname*(res: PPGresult, field_num: int32): cstring{.cdecl,
    dynlib: dllName, importc: "PQfname".}
proc pqfnumber*(res: PPGresult, field_name: cstring): int32{.cdecl,
    dynlib: dllName, importc: "PQfnumber".}
proc pqftable*(res: PPGresult, field_num: int32): Oid{.cdecl, dynlib: dllName,
    importc: "PQftable".}
proc pqftablecol*(res: PPGresult, field_num: int32): int32{.cdecl,
    dynlib: dllName, importc: "PQftablecol".}
proc pqfformat*(res: PPGresult, field_num: int32): int32{.cdecl,
    dynlib: dllName, importc: "PQfformat".}
proc pqftype*(res: PPGresult, field_num: int32): Oid{.cdecl, dynlib: dllName,
    importc: "PQftype".}
proc pqfsize*(res: PPGresult, field_num: int32): int32{.cdecl, dynlib: dllName,
    importc: "PQfsize".}
proc pqfmod*(res: PPGresult, field_num: int32): int32{.cdecl, dynlib: dllName,
    importc: "PQfmod".}
proc pqcmdStatus*(res: PPGresult): cstring{.cdecl, dynlib: dllName,
    importc: "PQcmdStatus".}
proc pqoidStatus*(res: PPGresult): cstring{.cdecl, dynlib: dllName,
    importc: "PQoidStatus".}
proc pqoidValue*(res: PPGresult): Oid{.cdecl, dynlib: dllName,
                                       importc: "PQoidValue".}
proc pqcmdTuples*(res: PPGresult): cstring{.cdecl, dynlib: dllName,
    importc: "PQcmdTuples".}
proc pqgetvalue*(res: PPGresult, tup_num: int32, field_num: int32): cstring{.
    cdecl, dynlib: dllName, importc: "PQgetvalue".}
proc pqgetlength*(res: PPGresult, tup_num: int32, field_num: int32): int32{.
    cdecl, dynlib: dllName, importc: "PQgetlength".}
proc pqgetisnull*(res: PPGresult, tup_num: int32, field_num: int32): int32{.
    cdecl, dynlib: dllName, importc: "PQgetisnull".}
proc pqclear*(res: PPGresult){.cdecl, dynlib: dllName, importc: "PQclear".}
proc pqfreemem*(p: pointer){.cdecl, dynlib: dllName, importc: "PQfreemem".}
proc pqmakeEmptyPGresult*(conn: PPGconn, status: ExecStatusType): PPGresult{.
    cdecl, dynlib: dllName, importc: "PQmakeEmptyPGresult".}
proc pqescapeString*(till, `from`: cstring, len: int): int{.cdecl,
    dynlib: dllName, importc: "PQescapeString".}
proc pqescapeBytea*(bintext: cstring, binlen: int, bytealen: var int): cstring{.
    cdecl, dynlib: dllName, importc: "PQescapeBytea".}
proc pqunescapeBytea*(strtext: cstring, retbuflen: var int): cstring{.cdecl,
    dynlib: dllName, importc: "PQunescapeBytea".}
proc pqprint*(fout: File, res: PPGresult, ps: PPQprintOpt){.cdecl,
    dynlib: dllName, importc: "PQprint".}
proc pqdisplayTuples*(res: PPGresult, fp: File, fillAlign: int32,
                      fieldSep: cstring, printHeader: int32, quiet: int32){.
    cdecl, dynlib: dllName, importc: "PQdisplayTuples".}
proc pqprintTuples*(res: PPGresult, fout: File, printAttName: int32,
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
proc pqmblen*(s: cstring, encoding: int32): int32{.cdecl, dynlib: dllName,
    importc: "PQmblen".}
proc pqenv2encoding*(): int32{.cdecl, dynlib: dllName, importc: "PQenv2encoding".}
proc pqsetdb(M_PGHOST, M_PGPORT, M_PGOPT, M_PGTTY, M_DBNAME: cstring): PPGconn =
  result = pqsetdbLogin(M_PGHOST, M_PGPORT, M_PGOPT, M_PGTTY, M_DBNAME, "", "")

when defined(nimHasStyleChecks):
  {.pop.}
