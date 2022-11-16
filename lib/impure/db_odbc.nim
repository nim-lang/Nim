#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## A higher level `ODBC` database wrapper.
##
## This is the same interface that is implemented for other databases.
##
## This has NOT yet been (extensively) tested against ODBC drivers for
## Teradata, Oracle, Sybase, MSSqlvSvr, et. al.  databases.
##
## Currently all queries are ANSI calls, not Unicode.
##
## See also: `db_postgres <db_postgres.html>`_, `db_sqlite <db_sqlite.html>`_,
## `db_mysql <db_mysql.html>`_.
##
## Parameter substitution
## ======================
##
## All `db_*` modules support the same form of parameter substitution.
## That is, using the `?` (question mark) to signify the place where a
## value should be placed. For example:
##
## .. code-block:: Nim
##     sql"INSERT INTO myTable (colA, colB, colC) VALUES (?, ?, ?)"
##
##
## Examples
## ========
##
## Opening a connection to a database
## ----------------------------------
##
## .. code-block:: Nim
##     import std/db_odbc
##     var db = open("localhost", "user", "password", "dbname")
##     db.close()
##
## Creating a table
## ----------------
##
## .. code-block:: Nim
##      db.exec(sql"DROP TABLE IF EXISTS myTable")
##      db.exec(sql("""CREATE TABLE myTable (
##                       id integer,
##                       name varchar(50) not null)"""))
##
## Inserting data
## --------------
##
## .. code-block:: Nim
##     db.exec(sql"INSERT INTO myTable (id, name) VALUES (0, ?)",
##             "Andreas")
##
## Large example
## -------------
##
## .. code-block:: Nim
##
##  import std/[db_odbc, math]
##
##  var theDb = open("localhost", "nim", "nim", "test")
##
##  theDb.exec(sql"Drop table if exists myTestTbl")
##  theDb.exec(sql("create table myTestTbl (" &
##      " Id    INT(11)     NOT NULL AUTO_INCREMENT PRIMARY KEY, " &
##      " Name  VARCHAR(50) NOT NULL, " &
##      " i     INT(11), " &
##      " f     DECIMAL(18,10))"))
##
##  theDb.exec(sql"START TRANSACTION")
##  for i in 1..1000:
##    theDb.exec(sql"INSERT INTO myTestTbl (name,i,f) VALUES (?,?,?)",
##          "Item#" & $i, i, sqrt(i.float))
##  theDb.exec(sql"COMMIT")
##
##  for x in theDb.fastRows(sql"select * from myTestTbl"):
##    echo x
##
##  let id = theDb.tryInsertId(sql"INSERT INTO myTestTbl (name,i,f) VALUES (?,?,?)",
##          "Item#1001", 1001, sqrt(1001.0))
##  echo "Inserted item: ", theDb.getValue(sql"SELECT name FROM myTestTbl WHERE id=?", id)
##
##  theDb.close()

import strutils, odbcsql
import db_common
export db_common

import std/private/since

type
  OdbcConnTyp = tuple[hDb: SqlHDBC, env: SqlHEnv, stmt: SqlHStmt]
  DbConn* = OdbcConnTyp    ## encapsulates a database connection
  Row* = seq[string]   ## a row of a dataset. NULL database values will be
                       ## converted to nil.
  InstantRow* = tuple[row: seq[string], len: int]  ## a handle that can be
                                                    ## used to get a row's
                                                    ## column text on demand

var
  buf: array[0..4096, char]

proc properFreeResult(hType: int, sqlres: var SqlHandle) {.
          tags: [WriteDbEffect], raises: [].} =
  try:
    discard SQLFreeHandle(hType.TSqlSmallInt, sqlres)
    sqlres = nil
  except: discard

proc getErrInfo(db: var DbConn): tuple[res: int, ss, ne, msg: string] {.
          tags: [ReadDbEffect], raises: [].} =
  ## Returns ODBC error information
  var
    sqlState: array[0..512, char]
    nativeErr: array[0..512, char]
    errMsg: array[0..512, char]
    retSz: TSqlSmallInt = 0
    res: TSqlSmallInt = 0
  try:
    sqlState[0] = '\0'
    nativeErr[0] = '\0'
    errMsg[0] = '\0'
    res = SQLErr(db.env, db.hDb, db.stmt,
              cast[PSQLCHAR](sqlState.addr),
              cast[PSQLCHAR](nativeErr.addr),
              cast[PSQLCHAR](errMsg.addr),
              511.TSqlSmallInt, retSz.addr)
  except:
    discard
  return (res.int, $(cast[cstring](addr sqlState)), $cast[cstring](addr nativeErr), $cast[cstring](addr errMsg))

proc dbError*(db: var DbConn) {.
          tags: [ReadDbEffect, WriteDbEffect], raises: [DbError] .} =
  ## Raises an `[DbError]` exception with ODBC error information
  var
    e: ref DbError
    ss, ne, msg: string = ""
    isAnError = false
    res: int = 0
    prevSs = ""
  while true:
    prevSs = ss
    (res, ss, ne, msg) = db.getErrInfo()
    if prevSs == ss:
      break
    # sqlState of 00000 is not an error
    elif ss == "00000":
      break
    elif ss == "01000":
      echo "\nWarning: ", ss, " ", msg
      continue
    else:
      isAnError = true
      echo "\nError: ", ss, " ", msg
  if isAnError:
    new(e)
    e.msg = "ODBC Error"
    if db.stmt != nil:
      properFreeResult(SQL_HANDLE_STMT, db.stmt)
    properFreeResult(SQL_HANDLE_DBC, db.hDb)
    properFreeResult(SQL_HANDLE_ENV, db.env)
    raise e

proc sqlCheck(db: var DbConn, resVal: TSqlSmallInt) {.raises: [DbError]} =
  ## Wrapper that raises [EDb] if `resVal` is neither SQL_SUCCESS or SQL_NO_DATA
  if resVal notIn [SQL_SUCCESS, SQL_NO_DATA]: dbError(db)

proc sqlGetDBMS(db: var DbConn): string {.
        tags: [ReadDbEffect, WriteDbEffect], raises: [] .} =
  ## Returns the ODBC SQL_DBMS_NAME string
  const
    SQL_DBMS_NAME = 17.SqlUSmallInt
  var
    sz: TSqlSmallInt = 0
  buf[0] = '\0'
  try:
    db.sqlCheck(SQLGetInfo(db.hDb, SQL_DBMS_NAME, cast[SqlPointer](buf.addr),
                        4095.TSqlSmallInt, sz.addr))
  except: discard
  return $(cast[cstring](addr buf))

proc dbQuote*(s: string): string {.noSideEffect.} =
  ## DB quotes the string.
  result = "'"
  for c in items(s):
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

proc dbFormat(formatstr: SqlQuery, args: varargs[string]): string {.
                  noSideEffect.} =
  ## Replace any `?` placeholders with `args`,
  ## and quotes the arguments
  result = ""
  var a = 0
  for c in items(string(formatstr)):
    if c == '?':
      add(result, dbQuote(args[a]))
      inc(a)
    else:
      add(result, c)

proc prepareFetch(db: var DbConn, query: SqlQuery,
                args: varargs[string, `$`]): TSqlSmallInt {.
                tags: [ReadDbEffect, WriteDbEffect], raises: [DbError].} =
  # Prepare a statement, execute it and fetch the data to the driver
  # ready for retrieval of the data
  # Used internally by iterators and retrieval procs
  # requires calling
  #      properFreeResult(SQL_HANDLE_STMT, db.stmt)
  # when finished
  db.sqlCheck(SQLAllocHandle(SQL_HANDLE_STMT, db.hDb, db.stmt))
  var q = dbFormat(query, args)
  db.sqlCheck(SQLPrepare(db.stmt, q.PSQLCHAR, q.len.TSqlSmallInt))
  db.sqlCheck(SQLExecute(db.stmt))
  result = SQLFetch(db.stmt)
  db.sqlCheck(result)

proc prepareFetchDirect(db: var DbConn, query: SqlQuery,
                args: varargs[string, `$`]) {.
                tags: [ReadDbEffect, WriteDbEffect], raises: [DbError].} =
  # Prepare a statement, execute it and fetch the data to the driver
  # ready for retrieval of the data
  # Used internally by iterators and retrieval procs
  # requires calling
  #      properFreeResult(SQL_HANDLE_STMT, db.stmt)
  # when finished
  db.sqlCheck(SQLAllocHandle(SQL_HANDLE_STMT, db.hDb, db.stmt))
  var q = dbFormat(query, args)
  db.sqlCheck(SQLExecDirect(db.stmt, q.PSQLCHAR, q.len.TSqlSmallInt))
  db.sqlCheck(SQLFetch(db.stmt))

proc tryExec*(db: var DbConn, query: SqlQuery, args: varargs[string, `$`]): bool {.
  tags: [ReadDbEffect, WriteDbEffect], raises: [].} =
  ## Tries to execute the query and returns true if successful, false otherwise.
  var
    res:TSqlSmallInt = -1
  try:
    db.prepareFetchDirect(query, args)
    var
      rCnt:TSqlLen = -1
    res = SQLRowCount(db.stmt, rCnt)
    properFreeResult(SQL_HANDLE_STMT, db.stmt)
    if res != SQL_SUCCESS: dbError(db)
  except: discard
  return res == SQL_SUCCESS

proc rawExec(db: var DbConn, query: SqlQuery, args: varargs[string, `$`]) {.
            tags: [ReadDbEffect, WriteDbEffect], raises: [DbError].} =
  db.prepareFetchDirect(query, args)

proc exec*(db: var DbConn, query: SqlQuery, args: varargs[string, `$`]) {.
            tags: [ReadDbEffect, WriteDbEffect], raises: [DbError].} =
  ## Executes the query and raises EDB if not successful.
  db.prepareFetchDirect(query, args)
  properFreeResult(SQL_HANDLE_STMT, db.stmt)

proc newRow(L: int): Row {.noSideEFfect.} =
  newSeq(result, L)
  for i in 0..L-1: result[i] = ""

iterator fastRows*(db: var DbConn, query: SqlQuery,
                   args: varargs[string, `$`]): Row {.
                tags: [ReadDbEffect, WriteDbEffect], raises: [DbError].} =
  ## Executes the query and iterates over the result dataset.
  ##
  ## This is very fast, but potentially dangerous.  Use this iterator only
  ## if you require **ALL** the rows.
  ##
  ## Breaking the fastRows() iterator during a loop may cause a driver error
  ## for subsequent queries
  ##
  ## Rows are retrieved from the server at each iteration.
  var
    rowRes: Row
    sz: TSqlLen = 0
    cCnt: TSqlSmallInt = 0
    res: TSqlSmallInt = 0
  res = db.prepareFetch(query, args)
  if res == SQL_NO_DATA:
    discard
  elif res == SQL_SUCCESS:
    res = SQLNumResultCols(db.stmt, cCnt)
    rowRes = newRow(cCnt)
    rowRes.setLen(max(cCnt,0))
    while res == SQL_SUCCESS:
      for colId in 1..cCnt:
        buf[0] = '\0'
        db.sqlCheck(SQLGetData(db.stmt, colId.SqlUSmallInt, SQL_C_CHAR,
                                 cast[cstring](buf.addr), 4095, sz.addr))
        rowRes[colId-1] = $cast[cstring]((addr buf))
      yield rowRes
      res = SQLFetch(db.stmt)
  properFreeResult(SQL_HANDLE_STMT, db.stmt)
  db.sqlCheck(res)

iterator instantRows*(db: var DbConn, query: SqlQuery,
                      args: varargs[string, `$`]): InstantRow
                {.tags: [ReadDbEffect, WriteDbEffect].} =
  ## Same as fastRows but returns a handle that can be used to get column text
  ## on demand using []. Returned handle is valid only within the iterator body.
  var
    rowRes: Row = @[]
    sz: TSqlLen = 0
    cCnt: TSqlSmallInt = 0
    res: TSqlSmallInt = 0
  res = db.prepareFetch(query, args)
  if res == SQL_NO_DATA:
    discard
  elif res == SQL_SUCCESS:
    res = SQLNumResultCols(db.stmt, cCnt)
    rowRes = newRow(cCnt)
    rowRes.setLen(max(cCnt,0))
    while res == SQL_SUCCESS:
      for colId in 1..cCnt:
        buf[0] = '\0'
        db.sqlCheck(SQLGetData(db.stmt, colId.SqlUSmallInt, SQL_C_CHAR,
                                 cast[cstring](buf.addr), 4095, sz.addr))
        rowRes[colId-1] = $cast[cstring](addr buf)
      yield (row: rowRes, len: cCnt.int)
      res = SQLFetch(db.stmt)
  properFreeResult(SQL_HANDLE_STMT, db.stmt)
  db.sqlCheck(res)

proc `[]`*(row: InstantRow, col: int): string {.inline.} =
  ## Returns text for given column of the row
  $row.row[col]

proc unsafeColumnAt*(row: InstantRow, index: int): cstring {.inline.} =
  ## Return cstring of given column of the row
  row.row[index]

proc len*(row: InstantRow): int {.inline.} =
  ## Returns number of columns in the row
  row.len

proc getRow*(db: var DbConn, query: SqlQuery,
             args: varargs[string, `$`]): Row {.
          tags: [ReadDbEffect, WriteDbEffect], raises: [DbError].} =
  ## Retrieves a single row. If the query doesn't return any rows, this proc
  ## will return a Row with empty strings for each column.
  var
    rowRes: Row
    sz: TSqlLen = 0
    cCnt: TSqlSmallInt = 0
    res: TSqlSmallInt = 0
  res = db.prepareFetch(query, args)
  if res == SQL_NO_DATA:
    result = @[]
  elif res == SQL_SUCCESS:
    res = SQLNumResultCols(db.stmt, cCnt)
    rowRes = newRow(cCnt)
    rowRes.setLen(max(cCnt,0))
    for colId in 1..cCnt:
      buf[0] = '\0'
      db.sqlCheck(SQLGetData(db.stmt, colId.SqlUSmallInt, SQL_C_CHAR,
                               cast[cstring](buf.addr), 4095, sz.addr))
      rowRes[colId-1] = $cast[cstring](addr buf)
    res = SQLFetch(db.stmt)
    result = rowRes
  properFreeResult(SQL_HANDLE_STMT, db.stmt)
  db.sqlCheck(res)

proc getAllRows*(db: var DbConn, query: SqlQuery,
                 args: varargs[string, `$`]): seq[Row] {.
           tags: [ReadDbEffect, WriteDbEffect], raises: [DbError] .} =
  ## Executes the query and returns the whole result dataset.
  var
    rows: seq[Row] = @[]
    rowRes: Row
    sz: TSqlLen = 0
    cCnt: TSqlSmallInt = 0
    res: TSqlSmallInt = 0
  res = db.prepareFetch(query, args)
  if res == SQL_NO_DATA:
    result = @[]
  elif res == SQL_SUCCESS:
    res = SQLNumResultCols(db.stmt, cCnt)
    rowRes = newRow(cCnt)
    rowRes.setLen(max(cCnt,0))
    while res == SQL_SUCCESS:
      for colId in 1..cCnt:
        buf[0] = '\0'
        db.sqlCheck(SQLGetData(db.stmt, colId.SqlUSmallInt, SQL_C_CHAR,
                                 cast[cstring](buf.addr), 4095, sz.addr))
        rowRes[colId-1] = $cast[cstring](addr buf)
      rows.add(rowRes)
      res = SQLFetch(db.stmt)
    result = rows
  properFreeResult(SQL_HANDLE_STMT, db.stmt)
  db.sqlCheck(res)

iterator rows*(db: var DbConn, query: SqlQuery,
               args: varargs[string, `$`]): Row {.
         tags: [ReadDbEffect, WriteDbEffect], raises: [DbError].} =
  ## Same as `fastRows`, but slower and safe.
  ##
  ## This retrieves ALL rows into memory before
  ## iterating through the rows.
  ## Large dataset queries will impact on memory usage.
  for r in items(getAllRows(db, query, args)): yield r

proc getValue*(db: var DbConn, query: SqlQuery,
               args: varargs[string, `$`]): string {.
           tags: [ReadDbEffect, WriteDbEffect], raises: [].} =
  ## Executes the query and returns the first column of the first row of the
  ## result dataset. Returns "" if the dataset contains no rows or the database
  ## value is NULL.
  result = ""
  try:
    result = getRow(db, query, args)[0]
  except: discard

proc tryInsertId*(db: var DbConn, query: SqlQuery,
                  args: varargs[string, `$`]): int64 {.
            tags: [ReadDbEffect, WriteDbEffect], raises: [].} =
  ## Executes the query (typically "INSERT") and returns the
  ## generated ID for the row or -1 in case of an error.
  if not tryExec(db, query, args):
    result = -1'i64
  else:
    result = -1'i64
    try:
      case sqlGetDBMS(db).toLower():
      of "postgresql":
        result = getValue(db, sql"SELECT LASTVAL();", []).parseInt
      of "mysql":
        result = getValue(db, sql"SELECT LAST_INSERT_ID();", []).parseInt
      of "sqlite":
        result = getValue(db, sql"SELECT LAST_INSERT_ROWID();", []).parseInt
      of "microsoft sql server":
        result = getValue(db, sql"SELECT SCOPE_IDENTITY();", []).parseInt
      of "oracle":
        result = getValue(db, sql"SELECT id.currval FROM DUAL;", []).parseInt
      else: result = -1'i64
    except: discard

proc insertId*(db: var DbConn, query: SqlQuery,
               args: varargs[string, `$`]): int64 {.
         tags: [ReadDbEffect, WriteDbEffect], raises: [DbError].} =
  ## Executes the query (typically "INSERT") and returns the
  ## generated ID for the row.
  result = tryInsertID(db, query, args)
  if result < 0: dbError(db)

proc tryInsert*(db: var DbConn, query: SqlQuery,pkName: string,
                args: varargs[string, `$`]): int64
               {.tags: [ReadDbEffect, WriteDbEffect], raises: [], since: (1, 3).} =
  ## same as tryInsertID
  tryInsertID(db, query, args)

proc insert*(db: var DbConn, query: SqlQuery, pkName: string,
             args: varargs[string, `$`]): int64 
            {.tags: [ReadDbEffect, WriteDbEffect], since: (1, 3).} =
  ## same as insertId
  result = tryInsert(db, query,pkName, args)
  if result < 0: dbError(db)

proc execAffectedRows*(db: var DbConn, query: SqlQuery,
                       args: varargs[string, `$`]): int64 {.
             tags: [ReadDbEffect, WriteDbEffect], raises: [DbError].} =
  ## Runs the query (typically "UPDATE") and returns the
  ## number of affected rows
  result = -1
  db.sqlCheck(SQLAllocHandle(SQL_HANDLE_STMT, db.hDb, db.stmt.SqlHandle))
  var q = dbFormat(query, args)
  db.sqlCheck(SQLPrepare(db.stmt, q.PSQLCHAR, q.len.TSqlSmallInt))
  rawExec(db, query, args)
  var rCnt:TSqlLen = -1
  db.sqlCheck(SQLRowCount(db.hDb, rCnt))
  properFreeResult(SQL_HANDLE_STMT, db.stmt)
  result = rCnt.int64

proc close*(db: var DbConn) {.
      tags: [WriteDbEffect], raises: [].} =
  ## Closes the database connection.
  if db.hDb != nil:
    try:
      var res = SQLDisconnect(db.hDb)
      if db.stmt != nil:
        res = SQLFreeHandle(SQL_HANDLE_STMT, db.stmt)
      res = SQLFreeHandle(SQL_HANDLE_DBC, db.hDb)
      res = SQLFreeHandle(SQL_HANDLE_ENV, db.env)
      db = (hDb: nil, env: nil, stmt: nil)
    except:
      discard

proc open*(connection, user, password, database: string): DbConn {.
  tags: [ReadDbEffect, WriteDbEffect], raises: [DbError].} =
  ## Opens a database connection.
  ##
  ## Raises `EDb` if the connection could not be established.
  ##
  ## Currently the database parameter is ignored,
  ## but included to match `open()` in the other db_xxxxx library modules.
  var
    val = SQL_OV_ODBC3
    resLen = 0
  result = (hDb: nil, env: nil, stmt: nil)
  # allocate environment handle
  var res = SQLAllocHandle(SQL_HANDLE_ENV, result.env, result.env)
  if res != SQL_SUCCESS: dbError("Error: unable to initialise ODBC environment.")
  res = SQLSetEnvAttr(result.env,
                      SQL_ATTR_ODBC_VERSION.TSqlInteger,
                      cast[SqlPointer](val), resLen.TSqlInteger)
  if res != SQL_SUCCESS: dbError("Error: unable to set ODBC driver version.")
  # allocate hDb handle
  res = SQLAllocHandle(SQL_HANDLE_DBC, result.env, result.hDb)
  if res != SQL_SUCCESS: dbError("Error: unable to allocate connection handle.")

  # Connect: connection = dsn str,
  res = SQLConnect(result.hDb,
                  connection.PSQLCHAR , connection.len.TSqlSmallInt,
                  user.PSQLCHAR, user.len.TSqlSmallInt,
                  password.PSQLCHAR, password.len.TSqlSmallInt)
  if res != SQL_SUCCESS:
    result.dbError()

proc setEncoding*(connection: DbConn, encoding: string): bool {.
  tags: [ReadDbEffect, WriteDbEffect], raises: [DbError].} =
  ## Currently not implemented for ODBC.
  ##
  ## Sets the encoding of a database connection, returns true for
  ## success, false for failure.
  ##result = set_character_set(connection, encoding) == 0
  dbError("setEncoding() is currently not implemented by the db_odbc module")
