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
## ----------------------
##
## All ``db_*`` modules support the same form of parameter substitution.
## That is, using the ``?`` (question mark) to signify the place where a
## value should be placed. For example:
##
## .. code-block:: Nim
##     sql"INSERT INTO myTable (colA, colB, colC) VALUES (?, ?, ?)"
##
## **Note**: There are two approaches to parameter substitution support by
## this module.
##
## 1.  ``SqlQuery`` using ``?, ?, ?, ...`` (same as all the ``db_*`` modules)
##
## 2. ``SqlPrepared`` using ``$1, $2, $3, ...``
##
## .. code-block:: Nim
##   prepare(db, "myExampleInsert",
##           sql"""INSERT INTO myTable
##                 (colA, colB, colC)
##                 VALUES ($1, $2, $3)""",
##           3)
##
## Examples
## --------
##
## Opening a connection to a database
## ==================================
##
## .. code-block:: Nim
##     import db_postgres
##     let db = open("localhost", "user", "password", "dbname")
##     db.close()
##
## Creating a table
## ================
##
## .. code-block:: Nim
##      db.exec(sql"DROP TABLE IF EXISTS myTable")
##      db.exec(sql("""CREATE TABLE myTable (
##                       id integer,
##                       name varchar(50) not null)"""))
##
## Inserting data
## ==============
##
## .. code-block:: Nim
##     db.exec(sql"INSERT INTO myTable (id, name) VALUES (0, ?)",
##             "Dominik")
import strutils, postgres

import db_common
export db_common

type
  DbConn* = PPGconn   ## encapsulates a database connection
  Row* = seq[string]  ## a row of a dataset. NULL database values will be
                      ## converted to nil.
  InstantRow* = tuple[res: PPGresult, line: int32]  ## a handle that can be
                                                    ## used to get a row's
                                                    ## column text on demand
  SqlPrepared* = distinct string ## a identifier for the prepared queries

{.deprecated: [TRow: Row, TDbConn: DbConn,
              TSqlPrepared: SqlPrepared].}

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
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

proc dbFormat(formatstr: SqlQuery, args: varargs[string]): string =
  result = ""
  var a = 0
  if args.len > 0 and not string(formatstr).contains("?"):
    dbError("""parameter substitution expects "?" """)
  for c in items(string(formatstr)):
    if c == '?':
      if args[a] == nil:
        add(result, "NULL")
      else:
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

proc prepare*(db: DbConn; stmtName: string, query: SqlQuery;
              nParams: int): SqlPrepared =
  ## Creates a new ``SqlPrepared`` statement. Parameter substitution is done
  ## via ``$1``, ``$2``, ``$3``, etc.
  if nParams > 0 and not string(query).contains("$1"):
    dbError("parameter substitution expects \"$1\"")
  var res = pqprepare(db, stmtName, query.string, int32(nParams), nil)
  if pqResultStatus(res) != PGRES_COMMAND_OK: dbError(db)
  return SqlPrepared(stmtName)

proc setRow(res: PPGresult, r: var Row, line, cols: int32) =
  for col in 0..cols-1:
    setLen(r[col], 0)
    let x = pqgetvalue(res, line, col)
    if x.isNil:
      r[col] = nil
    else:
      add(r[col], x)

iterator fastRows*(db: DbConn, query: SqlQuery,
                   args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  ## executes the query and iterates over the result dataset. This is very
  ## fast, but potenially dangerous: If the for-loop-body executes another
  ## query, the results can be undefined. For Postgres it is safe though.
  var res = setupQuery(db, query, args)
  var L = pqnfields(res)
  var result = newRow(L)
  for i in 0..pqntuples(res)-1:
    setRow(res, result, i, L)
    yield result
  pqclear(res)

iterator fastRows*(db: DbConn, stmtName: SqlPrepared,
                   args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  ## executes the prepared query and iterates over the result dataset.
  var res = setupQuery(db, stmtName, args)
  var L = pqNfields(res)
  var result = newRow(L)
  for i in 0..pqNtuples(res)-1:
    setRow(res, result, i, L)
    yield result
  pqClear(res)

iterator instantRows*(db: DbConn, query: SqlQuery,
                      args: varargs[string, `$`]): InstantRow
                      {.tags: [ReadDbEffect].} =
  ## same as fastRows but returns a handle that can be used to get column text
  ## on demand using []. Returned handle is valid only within iterator body.
  var res = setupQuery(db, query, args)
  for i in 0..pqNtuples(res)-1:
    yield (res: res, line: i)
  pqClear(res)

iterator instantRows*(db: DbConn, stmtName: SqlPrepared,
                      args: varargs[string, `$`]): InstantRow
                      {.tags: [ReadDbEffect].} =
  ## same as fastRows but returns a handle that can be used to get column text
  ## on demand using []. Returned handle is valid only within iterator body.
  var res = setupQuery(db, stmtName, args)
  for i in 0..pqNtuples(res)-1:
    yield (res: res, line: i)
  pqClear(res)

proc `[]`*(row: InstantRow, col: int32): string {.inline.} =
  ## returns text for given column of the row
  $pqgetvalue(row.res, row.line, col)

proc len*(row: InstantRow): int32 {.inline.} =
  ## returns number of columns in the row
  pqNfields(row.res)

proc getRow*(db: DbConn, query: SqlQuery,
             args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  ## retrieves a single row. If the query doesn't return any rows, this proc
  ## will return a Row with empty strings for each column.
  var res = setupQuery(db, query, args)
  var L = pqnfields(res)
  result = newRow(L)
  setRow(res, result, 0, L)
  pqclear(res)

proc getRow*(db: DbConn, stmtName: SqlPrepared,
             args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  var res = setupQuery(db, stmtName, args)
  var L = pqNfields(res)
  result = newRow(L)
  setRow(res, result, 0, L)
  pqClear(res)

proc getAllRows*(db: DbConn, query: SqlQuery,
                 args: varargs[string, `$`]): seq[Row] {.
                 tags: [ReadDbEffect].} =
  ## executes the query and returns the whole result dataset.
  result = @[]
  for r in fastRows(db, query, args):
    result.add(r)

proc getAllRows*(db: DbConn, stmtName: SqlPrepared,
                 args: varargs[string, `$`]): seq[Row] {.tags:
                 [ReadDbEffect].} =
  ## executes the prepared query and returns the whole result dataset.
  result = @[]
  for r in fastRows(db, stmtName, args):
    result.add(r)

iterator rows*(db: DbConn, query: SqlQuery,
               args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  ## same as `fastRows`, but slower and safe.
  for r in items(getAllRows(db, query, args)): yield r

iterator rows*(db: DbConn, stmtName: SqlPrepared,
               args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  ## same as `fastRows`, but slower and safe.
  for r in items(getAllRows(db, stmtName, args)): yield r

proc getValue*(db: DbConn, query: SqlQuery,
               args: varargs[string, `$`]): string {.
               tags: [ReadDbEffect].} =
  ## executes the query and returns the first column of the first row of the
  ## result dataset. Returns "" if the dataset contains no rows or the database
  ## value is NULL.
  var x = pqgetvalue(setupQuery(db, query, args), 0, 0)
  result = if isNil(x): "" else: $x

proc getValue*(db: DbConn, stmtName: SqlPrepared,
               args: varargs[string, `$`]): string {.
               tags: [ReadDbEffect].} =
  ## executes the query and returns the first column of the first row of the
  ## result dataset. Returns "" if the dataset contains no rows or the database
  ## value is NULL.
  var x = pqgetvalue(setupQuery(db, stmtName, args), 0, 0)
  result = if isNil(x): "" else: $x

proc tryInsertID*(db: DbConn, query: SqlQuery,
                  args: varargs[string, `$`]): int64 {.
                  tags: [WriteDbEffect].}=
  ## executes the query (typically "INSERT") and returns the
  ## generated ID for the row or -1 in case of an error. For Postgre this adds
  ## ``RETURNING id`` to the query, so it only works if your primary key is
  ## named ``id``.
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
  ## ``RETURNING id`` to the query, so it only works if your primary key is
  ## named ``id``.
  result = tryInsertID(db, query, args)
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
  ##
  ## Note that the connection parameter is not used but exists to maintain
  ## the nim db api.
  result = pqsetdbLogin(nil, nil, nil, nil, database, user, password)
  if pqStatus(result) != CONNECTION_OK: dbError(result) # result = nil

proc setEncoding*(connection: DbConn, encoding: string): bool {.
  tags: [DbEffect].} =
  ## sets the encoding of a database connection, returns true for
  ## success, false for failure.
  return pqsetClientEncoding(connection, encoding) == 0


# Tests are in ../../tests/untestable/tpostgres.
