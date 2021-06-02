#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## A higher level `PostgreSQL`:idx: database wrapper. This interface
## is implemented for other databases also.
##
## See also: `db_odbc <db_odbc.html>`_, `db_sqlite <db_sqlite.html>`_,
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
## **Note**: There are two approaches to parameter substitution support by
## this module.
##
## 1. `SqlQuery` using `?, ?, ?, ...` (same as all the `db_*` modules)
##
## 2. `SqlPrepared` using `$1, $2, $3, ...`
##
## .. code-block:: Nim
##   prepare(db, "myExampleInsert",
##           sql"""INSERT INTO myTable
##                 (colA, colB, colC)
##                 VALUES ($1, $2, $3)""",
##           3)
##
##
## Unix Socket
## ===========
##
## Using Unix sockets instead of TCP connection can
## `improve performance up to 30% ~ 175% for some operations <https://momjian.us/main/blogs/pgblog/2012.html#June_6_2012>`_.
##
## To use Unix sockets with `db_postgres`, change the server address to the socket file path:
##
## .. code-block:: Nim
##   import std/db_postgres ## Change "localhost" or "127.0.0.1" to the socket file path
##   let db = db_postgres.open("/run/postgresql", "user", "password", "database")
##   echo db.getAllRows(sql"SELECT version();")
##   db.close()
##
## The socket file path is operating system specific and distribution specific,
## additional configuration may or may not be needed on your `postgresql.conf`.
## The Postgres server must be on the same computer and only works for Unix-like operating systems.
##
##
## Examples
## ========
##
## Opening a connection to a database
## ----------------------------------
##
## .. code-block:: Nim
##     import std/db_postgres
##     let db = open("localhost", "user", "password", "dbname")
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
##             "Dominik")
import strutils, postgres

import db_common
export db_common

import std/private/since

type
  DbConn* = PPGconn    ## encapsulates a database connection
  Row* = seq[string]   ## a row of a dataset. NULL database values will be
                       ## converted to nil.
  InstantRow* = object ## a handle that can be
    res: PPGresult     ## used to get a row's
  SqlPrepared* = distinct string ## a identifier for the prepared queries

proc dbError*(db: DbConn) {.noreturn.} =
  ## raises a DbError exception.
  var e: ref DbError
  new(e)
  e.msg = $pqErrorMessage(db)
  raise e

proc dbQuote*(s: string): string =
  ## DB quotes the string.
  result = "'"
  for c in items(s):
    case c
    of '\'': add(result, "''")
    of '\0': add(result, "\\0")
    else: add(result, c)
  add(result, '\'')

proc dbFormat(formatstr: SqlQuery, args: varargs[string]): string =
  result = ""
  var a = 0
  if args.len > 0 and not string(formatstr).contains("?"):
    dbError("""parameter substitution expects "?" """)
  if args.len == 0:
    return string(formatstr)
  else:
    for c in items(string(formatstr)):
      if c == '?':
        add(result, dbQuote(args[a]))
        inc(a)
      else:
        add(result, c)

proc tryExec*(db: DbConn, query: SqlQuery,
              args: varargs[string, `$`]): bool {.tags: [ReadDbEffect, WriteDbEffect].} =
  ## tries to execute the query and returns true if successful, false otherwise.
  var res = pqexecParams(db, dbFormat(query, args), 0, nil, nil,
                        nil, nil, 0)
  result = pqresultStatus(res) == PGRES_COMMAND_OK
  pqclear(res)

proc tryExec*(db: DbConn, stmtName: SqlPrepared,
              args: varargs[string, `$`]): bool {.tags: [
              ReadDbEffect, WriteDbEffect].} =
  ## tries to execute the query and returns true if successful, false otherwise.
  var arr = allocCStringArray(args)
  var res = pqexecPrepared(db, stmtName.string, int32(args.len), arr,
                           nil, nil, 0)
  deallocCStringArray(arr)
  result = pqresultStatus(res) == PGRES_COMMAND_OK
  pqclear(res)

proc exec*(db: DbConn, query: SqlQuery, args: varargs[string, `$`]) {.
  tags: [ReadDbEffect, WriteDbEffect].} =
  ## executes the query and raises EDB if not successful.
  var res = pqexecParams(db, dbFormat(query, args), 0, nil, nil,
                        nil, nil, 0)
  if pqresultStatus(res) != PGRES_COMMAND_OK: dbError(db)
  pqclear(res)

proc exec*(db: DbConn, stmtName: SqlPrepared,
          args: varargs[string]) {.tags: [ReadDbEffect, WriteDbEffect].} =
  var arr = allocCStringArray(args)
  var res = pqexecPrepared(db, stmtName.string, int32(args.len), arr,
                           nil, nil, 0)
  deallocCStringArray(arr)
  if pqResultStatus(res) != PGRES_COMMAND_OK: dbError(db)
  pqclear(res)

proc newRow(L: int): Row =
  newSeq(result, L)
  for i in 0..L-1: result[i] = ""

proc setupQuery(db: DbConn, query: SqlQuery,
                args: varargs[string]): PPGresult =
  result = pqexec(db, dbFormat(query, args))
  if pqResultStatus(result) != PGRES_TUPLES_OK: dbError(db)

proc setupQuery(db: DbConn, stmtName: SqlPrepared,
                 args: varargs[string]): PPGresult =
  var arr = allocCStringArray(args)
  result = pqexecPrepared(db, stmtName.string, int32(args.len), arr,
                          nil, nil, 0)
  deallocCStringArray(arr)
  if pqResultStatus(result) != PGRES_TUPLES_OK: dbError(db)

proc setupSingeRowQuery(db: DbConn, query: SqlQuery,
                        args: varargs[string]) =
  if pqsendquery(db, dbFormat(query, args)) != 1:
    dbError(db)
  if pqSetSingleRowMode(db) != 1:
    dbError(db)

proc setupSingeRowQuery(db: DbConn, stmtName: SqlPrepared,
                       args: varargs[string]) =
  var arr = allocCStringArray(args)
  if pqsendqueryprepared(db, stmtName.string, int32(args.len), arr, nil, nil, 0) != 1:
    dbError(db)
  if pqSetSingleRowMode(db) != 1:
    dbError(db)
  deallocCStringArray(arr)

proc prepare*(db: DbConn; stmtName: string, query: SqlQuery;
              nParams: int): SqlPrepared =
  ## Creates a new `SqlPrepared` statement. Parameter substitution is done
  ## via `$1`, `$2`, `$3`, etc.
  if nParams > 0 and not string(query).contains("$1"):
    dbError("parameter substitution expects \"$1\"")
  var res = pqprepare(db, stmtName, query.string, int32(nParams), nil)
  if pqResultStatus(res) != PGRES_COMMAND_OK: dbError(db)
  return SqlPrepared(stmtName)

proc setRow(res: PPGresult, r: var Row, line, cols: int32) =
  for col in 0'i32..cols-1:
    setLen(r[col], 0)
    let x = pqgetvalue(res, line, col)
    if x.isNil:
      r[col] = ""
    else:
      add(r[col], x)

template fetchRows(db: DbConn): untyped =
  var res: PPGresult = nil
  while true:
    res = pqgetresult(db)
    if res == nil:
      break
    let status = pqresultStatus(res)
    if status == PGRES_TUPLES_OK:
      discard
    elif status != PGRES_SINGLE_TUPLE:
      dbError(db)
    else:
      let L = pqNfields(res)
      var result = newRow(L)
      setRow(res, result, 0, L)
      yield result
    pqclear(res)

iterator fastRows*(db: DbConn, query: SqlQuery,
                   args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  ## executes the query and iterates over the result dataset. This is very
  ## fast, but potentially dangerous: If the for-loop-body executes another
  ## query, the results can be undefined. For Postgres it is safe though.
  setupSingeRowQuery(db, query, args)
  fetchRows(db)

iterator fastRows*(db: DbConn, stmtName: SqlPrepared,
                   args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  ## executes the query and iterates over the result dataset. This is very
  ## fast, but potentially dangerous: If the for-loop-body executes another
  ## query, the results can be undefined. For Postgres it is safe though.
  setupSingeRowQuery(db, stmtName, args)
  fetchRows(db)

template fetchinstantRows(db: DbConn): untyped =
  var res: PPGresult = nil
  while true:
    res = pqgetresult(db)
    if res == nil:
      break
    let status = pqresultStatus(res)
    if status == PGRES_TUPLES_OK:
     discard
    elif status != PGRES_SINGLE_TUPLE:
      dbError(db)
    else:
      yield InstantRow(res: res)
    pqclear(res)

iterator instantRows*(db: DbConn, query: SqlQuery,
                      args: varargs[string, `$`]): InstantRow
                      {.tags: [ReadDbEffect].} =
  ## same as fastRows but returns a handle that can be used to get column text
  ## on demand using []. Returned handle is valid only within iterator body.
  setupSingeRowQuery(db, query, args)
  fetchinstantRows(db)

iterator instantRows*(db: DbConn, stmtName: SqlPrepared,
                      args: varargs[string, `$`]): InstantRow
                      {.tags: [ReadDbEffect].} =
  ## same as fastRows but returns a handle that can be used to get column text
  ## on demand using []. Returned handle is valid only within iterator body.
  setupSingeRowQuery(db, stmtName, args)
  fetchinstantRows(db)

proc getColumnType(res: PPGresult, col: int) : DbType =
  ## returns DbType for given column in the row
  ## defined in pg_type.h file in the postgres source code
  ## Wire representation for types: http://www.npgsql.org/dev/types.html
  var oid = pqftype(res, int32(col))
  ## The integer returned is the internal OID number of the type
  case oid
  of 16: return DbType(kind: DbTypeKind.dbBool, name: "bool")
  of 17: return DbType(kind: DbTypeKind.dbBlob, name: "bytea")

  of 21:   return DbType(kind: DbTypeKind.dbInt, name: "int2", size: 2)
  of 23:   return DbType(kind: DbTypeKind.dbInt, name: "int4", size: 4)
  of 20:   return DbType(kind: DbTypeKind.dbInt, name: "int8", size: 8)
  of 1560: return DbType(kind: DbTypeKind.dbBit, name: "bit")
  of 1562: return DbType(kind: DbTypeKind.dbInt, name: "varbit")

  of 18:   return DbType(kind: DbTypeKind.dbFixedChar, name: "char")
  of 19:   return DbType(kind: DbTypeKind.dbFixedChar, name: "name")
  of 1042: return DbType(kind: DbTypeKind.dbFixedChar, name: "bpchar")

  of 25:   return DbType(kind: DbTypeKind.dbVarchar, name: "text")
  of 1043: return DbType(kind: DbTypeKind.dbVarChar, name: "varchar")
  of 2275: return DbType(kind: DbTypeKind.dbVarchar, name: "cstring")

  of 700: return DbType(kind: DbTypeKind.dbFloat, name: "float4")
  of 701: return DbType(kind: DbTypeKind.dbFloat, name: "float8")

  of 790:  return DbType(kind: DbTypeKind.dbDecimal, name: "money")
  of 1700: return DbType(kind: DbTypeKind.dbDecimal, name: "numeric")

  of 704:  return DbType(kind: DbTypeKind.dbTimeInterval, name: "tinterval")
  of 702:  return DbType(kind: DbTypeKind.dbTimestamp, name: "abstime")
  of 703:  return DbType(kind: DbTypeKind.dbTimeInterval, name: "reltime")
  of 1082: return DbType(kind: DbTypeKind.dbDate, name: "date")
  of 1083: return DbType(kind: DbTypeKind.dbTime, name: "time")
  of 1114: return DbType(kind: DbTypeKind.dbTimestamp, name: "timestamp")
  of 1184: return DbType(kind: DbTypeKind.dbTimestamp, name: "timestamptz")
  of 1186: return DbType(kind: DbTypeKind.dbTimeInterval, name: "interval")
  of 1266: return DbType(kind: DbTypeKind.dbTime, name: "timetz")

  of 114:  return DbType(kind: DbTypeKind.dbJson, name: "json")
  of 142:  return DbType(kind: DbTypeKind.dbXml, name: "xml")
  of 3802: return DbType(kind: DbTypeKind.dbJson, name: "jsonb")

  of 600: return DbType(kind: DbTypeKind.dbPoint, name: "point")
  of 601: return DbType(kind: DbTypeKind.dbLseg, name: "lseg")
  of 602: return DbType(kind: DbTypeKind.dbPath, name: "path")
  of 603: return DbType(kind: DbTypeKind.dbBox, name: "box")
  of 604: return DbType(kind: DbTypeKind.dbPolygon, name: "polygon")
  of 628: return DbType(kind: DbTypeKind.dbLine, name: "line")
  of 718: return DbType(kind: DbTypeKind.dbCircle, name: "circle")

  of 650: return DbType(kind: DbTypeKind.dbInet, name: "cidr")
  of 829: return DbType(kind: DbTypeKind.dbMacAddress, name: "macaddr")
  of 869: return DbType(kind: DbTypeKind.dbInet, name: "inet")

  of 2950: return DbType(kind: DbTypeKind.dbVarchar, name: "uuid")
  of 3614: return DbType(kind: DbTypeKind.dbVarchar, name: "tsvector")
  of 3615: return DbType(kind: DbTypeKind.dbVarchar, name: "tsquery")
  of 2970: return DbType(kind: DbTypeKind.dbVarchar, name: "txid_snapshot")

  of 27:   return DbType(kind: DbTypeKind.dbComposite, name: "tid")
  of 1790: return DbType(kind: DbTypeKind.dbComposite, name: "refcursor")
  of 2249: return DbType(kind: DbTypeKind.dbComposite, name: "record")
  of 3904: return DbType(kind: DbTypeKind.dbComposite, name: "int4range")
  of 3906: return DbType(kind: DbTypeKind.dbComposite, name: "numrange")
  of 3908: return DbType(kind: DbTypeKind.dbComposite, name: "tsrange")
  of 3910: return DbType(kind: DbTypeKind.dbComposite, name: "tstzrange")
  of 3912: return DbType(kind: DbTypeKind.dbComposite, name: "daterange")
  of 3926: return DbType(kind: DbTypeKind.dbComposite, name: "int8range")

  of 22:   return DbType(kind: DbTypeKind.dbArray, name: "int2vector")
  of 30:   return DbType(kind: DbTypeKind.dbArray, name: "oidvector")
  of 143:  return DbType(kind: DbTypeKind.dbArray, name: "xml[]")
  of 199:  return DbType(kind: DbTypeKind.dbArray, name: "json[]")
  of 629:  return DbType(kind: DbTypeKind.dbArray, name: "line[]")
  of 651:  return DbType(kind: DbTypeKind.dbArray, name: "cidr[]")
  of 719:  return DbType(kind: DbTypeKind.dbArray, name: "circle[]")
  of 791:  return DbType(kind: DbTypeKind.dbArray, name: "money[]")
  of 1000: return DbType(kind: DbTypeKind.dbArray, name: "bool[]")
  of 1001: return DbType(kind: DbTypeKind.dbArray, name: "bytea[]")
  of 1002: return DbType(kind: DbTypeKind.dbArray, name: "char[]")
  of 1003: return DbType(kind: DbTypeKind.dbArray, name: "name[]")
  of 1005: return DbType(kind: DbTypeKind.dbArray, name: "int2[]")
  of 1006: return DbType(kind: DbTypeKind.dbArray, name: "int2vector[]")
  of 1007: return DbType(kind: DbTypeKind.dbArray, name: "int4[]")
  of 1008: return DbType(kind: DbTypeKind.dbArray, name: "regproc[]")
  of 1009: return DbType(kind: DbTypeKind.dbArray, name: "text[]")
  of 1028: return DbType(kind: DbTypeKind.dbArray, name: "oid[]")
  of 1010: return DbType(kind: DbTypeKind.dbArray, name: "tid[]")
  of 1011: return DbType(kind: DbTypeKind.dbArray, name: "xid[]")
  of 1012: return DbType(kind: DbTypeKind.dbArray, name: "cid[]")
  of 1013: return DbType(kind: DbTypeKind.dbArray, name: "oidvector[]")
  of 1014: return DbType(kind: DbTypeKind.dbArray, name: "bpchar[]")
  of 1015: return DbType(kind: DbTypeKind.dbArray, name: "varchar[]")
  of 1016: return DbType(kind: DbTypeKind.dbArray, name: "int8[]")
  of 1017: return DbType(kind: DbTypeKind.dbArray, name: "point[]")
  of 1018: return DbType(kind: DbTypeKind.dbArray, name: "lseg[]")
  of 1019: return DbType(kind: DbTypeKind.dbArray, name: "path[]")
  of 1020: return DbType(kind: DbTypeKind.dbArray, name: "box[]")
  of 1021: return DbType(kind: DbTypeKind.dbArray, name: "float4[]")
  of 1022: return DbType(kind: DbTypeKind.dbArray, name: "float8[]")
  of 1023: return DbType(kind: DbTypeKind.dbArray, name: "abstime[]")
  of 1024: return DbType(kind: DbTypeKind.dbArray, name: "reltime[]")
  of 1025: return DbType(kind: DbTypeKind.dbArray, name: "tinterval[]")
  of 1027: return DbType(kind: DbTypeKind.dbArray, name: "polygon[]")
  of 1040: return DbType(kind: DbTypeKind.dbArray, name: "macaddr[]")
  of 1041: return DbType(kind: DbTypeKind.dbArray, name: "inet[]")
  of 1263: return DbType(kind: DbTypeKind.dbArray, name: "cstring[]")
  of 1115: return DbType(kind: DbTypeKind.dbArray, name: "timestamp[]")
  of 1182: return DbType(kind: DbTypeKind.dbArray, name: "date[]")
  of 1183: return DbType(kind: DbTypeKind.dbArray, name: "time[]")
  of 1185: return DbType(kind: DbTypeKind.dbArray, name: "timestamptz[]")
  of 1187: return DbType(kind: DbTypeKind.dbArray, name: "interval[]")
  of 1231: return DbType(kind: DbTypeKind.dbArray, name: "numeric[]")
  of 1270: return DbType(kind: DbTypeKind.dbArray, name: "timetz[]")
  of 1561: return DbType(kind: DbTypeKind.dbArray, name: "bit[]")
  of 1563: return DbType(kind: DbTypeKind.dbArray, name: "varbit[]")
  of 2201: return DbType(kind: DbTypeKind.dbArray, name: "refcursor[]")
  of 2951: return DbType(kind: DbTypeKind.dbArray, name: "uuid[]")
  of 3643: return DbType(kind: DbTypeKind.dbArray, name: "tsvector[]")
  of 3645: return DbType(kind: DbTypeKind.dbArray, name: "tsquery[]")
  of 3807: return DbType(kind: DbTypeKind.dbArray, name: "jsonb[]")
  of 2949: return DbType(kind: DbTypeKind.dbArray, name: "txid_snapshot[]")
  of 3905: return DbType(kind: DbTypeKind.dbArray, name: "int4range[]")
  of 3907: return DbType(kind: DbTypeKind.dbArray, name: "numrange[]")
  of 3909: return DbType(kind: DbTypeKind.dbArray, name: "tsrange[]")
  of 3911: return DbType(kind: DbTypeKind.dbArray, name: "tstzrange[]")
  of 3913: return DbType(kind: DbTypeKind.dbArray, name: "daterange[]")
  of 3927: return DbType(kind: DbTypeKind.dbArray, name: "int8range[]")
  of 2287: return DbType(kind: DbTypeKind.dbArray, name: "record[]")

  of 705:  return DbType(kind: DbTypeKind.dbUnknown, name: "unknown")
  else: return DbType(kind: DbTypeKind.dbUnknown, name: $oid) ## Query the system table pg_type to determine exactly which type is referenced.

proc setColumnInfo(columns: var DbColumns; res: PPGresult, L: int32) =
  setLen(columns, L)
  for i in 0'i32..<L:
    columns[i].name = $pqfname(res, i)
    columns[i].typ = getColumnType(res, i)
    columns[i].tableName = $(pqftable(res, i)) ## Returns the OID of the table from which the given column was fetched.
                                               ## Query the system table pg_class to determine exactly which table is referenced.
    #columns[i].primaryKey = libpq does not have a function for that
    #columns[i].foreignKey = libpq does not have a function for that

iterator instantRows*(db: DbConn; columns: var DbColumns; query: SqlQuery;
                      args: varargs[string, `$`]): InstantRow
                      {.tags: [ReadDbEffect].} =
  setupSingeRowQuery(db, query, args)
  var res: PPGresult = nil
  var colsObtained = false
  while true:
    res = pqgetresult(db)
    if not colsObtained:
      setColumnInfo(columns, res, pqnfields(res))
      colsObtained = true
    if res == nil:
      break
    let status = pqresultStatus(res)
    if status == PGRES_TUPLES_OK:
      discard
    elif status != PGRES_SINGLE_TUPLE:
      dbError(db)
    else:
      yield InstantRow(res: res)
    pqclear(res)

proc `[]`*(row: InstantRow; col: int): string {.inline.} =
  ## returns text for given column of the row
  $pqgetvalue(row.res, int32(0), int32(col))

proc unsafeColumnAt*(row: InstantRow, index: int): cstring {.inline.} =
  ## Return cstring of given column of the row
  pqgetvalue(row.res, int32(0), int32(index))

proc len*(row: InstantRow): int {.inline.} =
  ## returns number of columns in the row
  int(pqNfields(row.res))

proc getRow(res: PPGresult): Row =
  let L = pqnfields(res)
  result = newRow(L)
  if pqntuples(res) > 0:
    setRow(res, result, 0, L)
  pqclear(res)

proc getRow*(db: DbConn, query: SqlQuery,
             args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  ## retrieves a single row. If the query doesn't return any rows, this proc
  ## will return a Row with empty strings for each column.
  let res = setupQuery(db, query, args)
  getRow(res)

proc getRow*(db: DbConn, stmtName: SqlPrepared,
             args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  let res = setupQuery(db, stmtName, args)
  getRow(res)

proc getAllRows(res: PPGresult): seq[Row] =
  let N = pqntuples(res)
  let L = pqnfields(res)
  result = newSeqOfCap[Row](N)
  var row = newRow(L)
  for i in 0'i32..N-1:
    setRow(res, row, i, L)
    result.add(row)
  pqclear(res)

proc getAllRows*(db: DbConn, query: SqlQuery,
                 args: varargs[string, `$`]): seq[Row] {.
                 tags: [ReadDbEffect].} =
  ## executes the query and returns the whole result dataset.
  let res = setupQuery(db, query, args)
  getAllRows(res)

proc getAllRows*(db: DbConn, stmtName: SqlPrepared,
                 args: varargs[string, `$`]): seq[Row] {.tags:
                 [ReadDbEffect].} =
  ## executes the prepared query and returns the whole result dataset.
  let res = setupQuery(db, stmtName, args)
  getAllRows(res)

iterator rows*(db: DbConn, query: SqlQuery,
               args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  ## same as `fastRows`, but slower and safe.
  for r in items(getAllRows(db, query, args)): yield r

iterator rows*(db: DbConn, stmtName: SqlPrepared,
               args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  ## same as `fastRows`, but slower and safe.
  for r in items(getAllRows(db, stmtName, args)): yield r

proc getValue(res: PPGresult): string =
  if pqntuples(res) > 0:
    var x = pqgetvalue(res, 0, 0)
    result = if isNil(x): "" else: $x
  else:
    result = ""

proc getValue*(db: DbConn, query: SqlQuery,
               args: varargs[string, `$`]): string {.
               tags: [ReadDbEffect].} =
  ## executes the query and returns the first column of the first row of the
  ## result dataset. Returns "" if the dataset contains no rows or the database
  ## value is NULL.
  let res = setupQuery(db, query, args)
  getValue(res)

proc getValue*(db: DbConn, stmtName: SqlPrepared,
               args: varargs[string, `$`]): string {.
               tags: [ReadDbEffect].} =
  ## executes the query and returns the first column of the first row of the
  ## result dataset. Returns "" if the dataset contains no rows or the database
  ## value is NULL.
  let res = setupQuery(db, stmtName, args)
  getValue(res)

proc tryInsertID*(db: DbConn, query: SqlQuery,
                  args: varargs[string, `$`]): int64 {.
                  tags: [WriteDbEffect].}=
  ## executes the query (typically "INSERT") and returns the
  ## generated ID for the row or -1 in case of an error. For Postgre this adds
  ## `RETURNING id` to the query, so it only works if your primary key is
  ## named `id`.
  var x = pqgetvalue(setupQuery(db, SqlQuery(string(query) & " RETURNING id"),
    args), 0, 0)
  if not isNil(x):
    result = parseBiggestInt($x)
  else:
    result = -1

proc insertID*(db: DbConn, query: SqlQuery,
               args: varargs[string, `$`]): int64 {.
               tags: [WriteDbEffect].} =
  ## executes the query (typically "INSERT") and returns the
  ## generated ID for the row. For Postgre this adds
  ## `RETURNING id` to the query, so it only works if your primary key is
  ## named `id`.
  result = tryInsertID(db, query, args)
  if result < 0: dbError(db)

proc tryInsert*(db: DbConn, query: SqlQuery,pkName: string,
                args: varargs[string, `$`]): int64
               {.tags: [WriteDbEffect], since: (1, 3).}=
  ## executes the query (typically "INSERT") and returns the
  ## generated ID for the row or -1 in case of an error.
  var x = pqgetvalue(setupQuery(db, SqlQuery(string(query) & " RETURNING " & pkName),
    args), 0, 0)
  if not isNil(x):
    result = parseBiggestInt($x)
  else:
    result = -1

proc insert*(db: DbConn, query: SqlQuery, pkName: string,
             args: varargs[string, `$`]): int64
            {.tags: [WriteDbEffect], since: (1, 3).} =
  ## executes the query (typically "INSERT") and returns the
  ## generated ID
  result = tryInsert(db, query, pkName, args)
  if result < 0: dbError(db)

proc execAffectedRows*(db: DbConn, query: SqlQuery,
                       args: varargs[string, `$`]): int64 {.tags: [
                       ReadDbEffect, WriteDbEffect].} =
  ## executes the query (typically "UPDATE") and returns the
  ## number of affected rows.
  var q = dbFormat(query, args)
  var res = pqExec(db, q)
  if pqresultStatus(res) != PGRES_COMMAND_OK: dbError(db)
  result = parseBiggestInt($pqcmdTuples(res))
  pqclear(res)

proc execAffectedRows*(db: DbConn, stmtName: SqlPrepared,
                       args: varargs[string, `$`]): int64 {.tags: [
                       ReadDbEffect, WriteDbEffect].} =
  ## executes the query (typically "UPDATE") and returns the
  ## number of affected rows.
  var arr = allocCStringArray(args)
  var res = pqexecPrepared(db, stmtName.string, int32(args.len), arr,
                           nil, nil, 0)
  deallocCStringArray(arr)
  if pqresultStatus(res) != PGRES_COMMAND_OK: dbError(db)
  result = parseBiggestInt($pqcmdTuples(res))
  pqclear(res)

proc close*(db: DbConn) {.tags: [DbEffect].} =
  ## closes the database connection.
  if db != nil: pqfinish(db)

proc open*(connection, user, password, database: string): DbConn {.
  tags: [DbEffect].} =
  ## opens a database connection. Raises `EDb` if the connection could not
  ## be established.
  ##
  ## Clients can also use Postgres keyword/value connection strings to
  ## connect.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##      con = open("", "", "", "host=localhost port=5432 dbname=mydb")
  ##
  ## See http://www.postgresql.org/docs/current/static/libpq-connect.html#LIBPQ-CONNSTRING
  ## for more information.
  let
    colonPos = connection.find(':')
    host = if colonPos < 0: connection
           else: substr(connection, 0, colonPos-1)
    port = if colonPos < 0: ""
           else: substr(connection, colonPos+1)
  result = pqsetdbLogin(host, port, nil, nil, database, user, password)
  if pqStatus(result) != CONNECTION_OK: dbError(result) # result = nil

proc setEncoding*(connection: DbConn, encoding: string): bool {.
  tags: [DbEffect].} =
  ## sets the encoding of a database connection, returns true for
  ## success, false for failure.
  return pqsetClientEncoding(connection, encoding) == 0


# Tests are in ../../tests/untestable/tpostgres.
