#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## A higher level `PostgreSQL`:idx: database wrapper. This interface
## is implemented for other databases too.

import strutils, postgres

type
  DbConn* = PPGconn   ## encapsulates a database connection
  Row* = seq[string]  ## a row of a dataset. NULL database values will be
                       ## transformed always to the empty string.
  InstantRow* = tuple[res: PPGresult, line: int32]  ## a handle that can be
                                                    ## used to get a row's
                                                    ## column text on demand
  EDb* = object of IOError ## exception that is raised if a database error occurs

  SqlQuery* = distinct string ## an SQL query string
  SqlPrepared* = distinct string ## a identifier for the prepared queries

  FDb* = object of IOEffect ## effect that denotes a database operation
  FReadDb* = object of FDb   ## effect that denotes a read operation
  FWriteDb* = object of FDb  ## effect that denotes a write operation
{.deprecated: [TRow: Row, TSqlQuery: SqlQuery, TDbConn: DbConn,
              TSqlPrepared: SqlPrepared].}

proc sql*(query: string): SqlQuery {.noSideEffect, inline.} =
  ## constructs a SqlQuery from the string `query`. This is supposed to be
  ## used as a raw-string-literal modifier:
  ## ``sql"update user set counter = counter + 1"``
  ##
  ## If assertions are turned off, it does nothing. If assertions are turned
  ## on, later versions will check the string for valid syntax.
  result = SqlQuery(query)

proc dbError*(db: DbConn) {.noreturn.} =
  ## raises an EDb exception.
  var e: ref EDb
  new(e)
  e.msg = $pqErrorMessage(db)
  raise e

proc dbError*(msg: string) {.noreturn.} =
  ## raises an EDb exception with message `msg`.
  var e: ref EDb
  new(e)
  e.msg = msg
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
              args: varargs[string, `$`]): bool {.tags: [FReadDB, FWriteDb].} =
  ## tries to execute the query and returns true if successful, false otherwise.
  var res = pqexecParams(db, dbFormat(query, args), 0, nil, nil,
                        nil, nil, 0)
  result = pqresultStatus(res) == PGRES_COMMAND_OK
  pqclear(res)

proc tryExec*(db: DbConn, stmtName: SqlPrepared,
              args: varargs[string, `$`]): bool {.tags: [FReadDB, FWriteDb].} =
  ## tries to execute the query and returns true if successful, false otherwise.
  var arr = allocCStringArray(args)
  var res = pqexecPrepared(db, stmtName.string, int32(args.len), arr,
                           nil, nil, 0)
  deallocCStringArray(arr)
  result = pqresultStatus(res) == PGRES_COMMAND_OK
  pqclear(res)

proc exec*(db: DbConn, query: SqlQuery, args: varargs[string, `$`]) {.
  tags: [FReadDB, FWriteDb].} =
  ## executes the query and raises EDB if not successful.
  var res = pqexecParams(db, dbFormat(query, args), 0, nil, nil,
                        nil, nil, 0)
  if pqresultStatus(res) != PGRES_COMMAND_OK: dbError(db)
  pqclear(res)

proc exec*(db: DbConn, stmtName: SqlPrepared,
          args: varargs[string]) {.tags: [FReadDB, FWriteDb].} =
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
  # s is a dummy unique id str for each setupQuery query
  let s = "setupQuery_Query_" & string(query)
  var res = pqprepare(db, s, dbFormat(query, args), 0, nil)
  result = pqexecPrepared(db, s, 0, nil,
                        nil, nil, 0)
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
  if nParams > 0 and not string(query).contains("$1"):
    dbError("""parameter substitution expects "$1" """)
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
                   args: varargs[string, `$`]): Row {.tags: [FReadDB].} =
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
                   args: varargs[string, `$`]): Row {.tags: [FReadDB].} =
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
                      {.tags: [FReadDb].} =
  ## same as fastRows but returns a handle that can be used to get column text
  ## on demand using []. Returned handle is valid only within interator body.
  var res = setupQuery(db, query, args)
  for i in 0..pqNtuples(res)-1:
    yield (res: res, line: i)
  pqClear(res)

iterator instantRows*(db: DbConn, stmtName: SqlPrepared,
                      args: varargs[string, `$`]): InstantRow
                      {.tags: [FReadDb].} =
  ## same as fastRows but returns a handle that can be used to get column text
  ## on demand using []. Returned handle is valid only within interator body.
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
             args: varargs[string, `$`]): Row {.tags: [FReadDB].} =
  ## retrieves a single row. If the query doesn't return any rows, this proc
  ## will return a Row with empty strings for each column.
  var res = setupQuery(db, query, args)
  var L = pqnfields(res)
  result = newRow(L)
  setRow(res, result, 0, L)
  pqclear(res)

proc getRow*(db: DbConn, stmtName: SqlPrepared,
             args: varargs[string, `$`]): Row {.tags: [FReadDB].} =
  var res = setupQuery(db, stmtName, args)
  var L = pqNfields(res)
  result = newRow(L)
  setRow(res, result, 0, L)
  pqClear(res)

proc getAllRows*(db: DbConn, query: SqlQuery,
                 args: varargs[string, `$`]): seq[Row] {.tags: [FReadDB].} =
  ## executes the query and returns the whole result dataset.
  result = @[]
  for r in fastRows(db, query, args):
    result.add(r)

proc getAllRows*(db: DbConn, stmtName: SqlPrepared,
                 args: varargs[string, `$`]): seq[Row] {.tags: [FReadDB].} =
  ## executes the prepared query and returns the whole result dataset.
  result = @[]
  for r in fastRows(db, stmtName, args):
    result.add(r)

iterator rows*(db: DbConn, query: SqlQuery,
               args: varargs[string, `$`]): Row {.tags: [FReadDB].} =
  ## same as `fastRows`, but slower and safe.
  for r in items(getAllRows(db, query, args)): yield r

iterator rows*(db: DbConn, stmtName: SqlPrepared,
               args: varargs[string, `$`]): Row {.tags: [FReadDB].} =
  ## same as `fastRows`, but slower and safe.
  for r in items(getAllRows(db, stmtName, args)): yield r

proc getValue*(db: DbConn, query: SqlQuery,
               args: varargs[string, `$`]): string {.tags: [FReadDB].} =
  ## executes the query and returns the first column of the first row of the
  ## result dataset. Returns "" if the dataset contains no rows or the database
  ## value is NULL.
  var x = pqgetvalue(setupQuery(db, query, args), 0, 0)
  result = if isNil(x): "" else: $x

proc tryInsertID*(db: DbConn, query: SqlQuery,
                  args: varargs[string, `$`]): int64  {.tags: [FWriteDb].}=
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
               args: varargs[string, `$`]): int64 {.tags: [FWriteDb].} =
  ## executes the query (typically "INSERT") and returns the
  ## generated ID for the row. For Postgre this adds
  ## ``RETURNING id`` to the query, so it only works if your primary key is
  ## named ``id``.
  result = tryInsertID(db, query, args)
  if result < 0: dbError(db)

proc execAffectedRows*(db: DbConn, query: SqlQuery,
                       args: varargs[string, `$`]): int64 {.tags: [
                       FReadDB, FWriteDb].} =
  ## executes the query (typically "UPDATE") and returns the
  ## number of affected rows.
  var q = dbFormat(query, args)
  var res = pqExec(db, q)
  if pqresultStatus(res) != PGRES_COMMAND_OK: dbError(db)
  result = parseBiggestInt($pqcmdTuples(res))
  pqclear(res)

proc execAffectedRows*(db: DbConn, stmtName: SqlPrepared,
                       args: varargs[string, `$`]): int64 {.tags: [
                       FReadDB, FWriteDb].} =
  ## executes the query (typically "UPDATE") and returns the
  ## number of affected rows.
  var arr = allocCStringArray(args)
  var res = pqexecPrepared(db, stmtName.string, int32(args.len), arr,
                           nil, nil, 0)
  deallocCStringArray(arr)
  if pqresultStatus(res) != PGRES_COMMAND_OK: dbError(db)
  result = parseBiggestInt($pqcmdTuples(res))
  pqclear(res)

proc close*(db: DbConn) {.tags: [FDb].} =
  ## closes the database connection.
  if db != nil: pqfinish(db)

proc open*(connection, user, password, database: string): DbConn {.
  tags: [FDb].} =
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
  tags: [FDb].} =
  ## sets the encoding of a database connection, returns true for
  ## success, false for failure.
  return pqsetClientEncoding(connection, encoding) == 0
