#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## A higher level `SQLite`:idx: database wrapper. This interface 
## is implemented for other databases too.

import strutils, sqlite3

type
  TDbConn* = PSqlite3  ## encapsulates a database connection
  TRow* = seq[string]  ## a row of a dataset. NULL database values will be
                       ## transformed always to the empty string.
  EDb* = object of IOError ## exception that is raised if a database error occurs
  
  TSqlQuery* = distinct string ## an SQL query string
  
  FDb* = object of IOEffect ## effect that denotes a database operation
  FReadDb* = object of FDb   ## effect that denotes a read operation
  FWriteDb* = object of FDb  ## effect that denotes a write operation
  
proc sql*(query: string): TSqlQuery {.noSideEffect, inline.} =  
  ## constructs a TSqlQuery from the string `query`. This is supposed to be 
  ## used as a raw-string-literal modifier:
  ## ``sql"update user set counter = counter + 1"``
  ##
  ## If assertions are turned off, it does nothing. If assertions are turned 
  ## on, later versions will check the string for valid syntax.
  result = TSqlQuery(query)
 
proc dbError(db: TDbConn) {.noreturn.} = 
  ## raises an EDb exception.
  var e: ref EDb
  new(e)
  e.msg = $sqlite3.errmsg(db)
  raise e

proc dbError*(msg: string) {.noreturn.} = 
  ## raises an EDb exception with message `msg`.
  var e: ref EDb
  new(e)
  e.msg = msg
  raise e

proc dbQuote(s: string): string =
  if s.isNil: return "NULL"
  result = "'"
  for c in items(s):
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

proc dbFormat(formatstr: TSqlQuery, args: varargs[string]): string =
  result = ""
  var a = 0
  for c in items(string(formatstr)):
    if c == '?':
      add(result, dbQuote(args[a]))
      inc(a)
    else:
      add(result, c)
  
proc tryExec*(db: TDbConn, query: TSqlQuery, 
              args: varargs[string, `$`]): bool {.tags: [FReadDb, FWriteDb].} =
  ## tries to execute the query and returns true if successful, false otherwise.
  var q = dbFormat(query, args)
  var stmt: sqlite3.Pstmt
  if prepare_v2(db, q, q.len.cint, stmt, nil) == SQLITE_OK:
    if step(stmt) == SQLITE_DONE:
      result = finalize(stmt) == SQLITE_OK

proc exec*(db: TDbConn, query: TSqlQuery, args: varargs[string, `$`])  {.
  tags: [FReadDb, FWriteDb].} =
  ## executes the query and raises EDB if not successful.
  if not tryExec(db, query, args): dbError(db)
  
proc newRow(L: int): TRow =
  newSeq(result, L)
  for i in 0..L-1: result[i] = ""
  
proc setupQuery(db: TDbConn, query: TSqlQuery, 
                args: varargs[string]): Pstmt = 
  var q = dbFormat(query, args)
  if prepare_v2(db, q, q.len.cint, result, nil) != SQLITE_OK: dbError(db)
  
proc setRow(stmt: Pstmt, r: var TRow, cols: cint) =
  for col in 0..cols-1:
    setLen(r[col], column_bytes(stmt, col)) # set capacity
    setLen(r[col], 0)
    let x = column_text(stmt, col)
    if not isNil(x): add(r[col], x)
  
iterator fastRows*(db: TDbConn, query: TSqlQuery,
                   args: varargs[string, `$`]): TRow  {.tags: [FReadDb].} =
  ## executes the query and iterates over the result dataset. This is very 
  ## fast, but potenially dangerous: If the for-loop-body executes another
  ## query, the results can be undefined. For Sqlite it is safe though.
  var stmt = setupQuery(db, query, args)
  var L = (column_count(stmt))
  var result = newRow(L)
  while step(stmt) == SQLITE_ROW: 
    setRow(stmt, result, L)
    yield result
  if finalize(stmt) != SQLITE_OK: dbError(db)

proc getRow*(db: TDbConn, query: TSqlQuery,
             args: varargs[string, `$`]): TRow {.tags: [FReadDb].} =
  ## retrieves a single row. If the query doesn't return any rows, this proc
  ## will return a TRow with empty strings for each column.
  var stmt = setupQuery(db, query, args)
  var L = (column_count(stmt))
  result = newRow(L)
  if step(stmt) == SQLITE_ROW: 
    setRow(stmt, result, L)
  if finalize(stmt) != SQLITE_OK: dbError(db)

proc getAllRows*(db: TDbConn, query: TSqlQuery, 
                 args: varargs[string, `$`]): seq[TRow] {.tags: [FReadDb].} =
  ## executes the query and returns the whole result dataset.
  result = @[]
  for r in fastRows(db, query, args):
    result.add(r)

iterator rows*(db: TDbConn, query: TSqlQuery, 
               args: varargs[string, `$`]): TRow {.tags: [FReadDb].} =
  ## same as `FastRows`, but slower and safe.
  for r in fastRows(db, query, args): yield r

proc getValue*(db: TDbConn, query: TSqlQuery, 
               args: varargs[string, `$`]): string {.tags: [FReadDb].} = 
  ## executes the query and returns the first column of the first row of the
  ## result dataset. Returns "" if the dataset contains no rows or the database
  ## value is NULL.
  var stmt = setupQuery(db, query, args)
  if step(stmt) == SQLITE_ROW:
    let cb = column_bytes(stmt, 0)
    if cb == 0: 
      result = ""
    else:
      result = newStringOfCap(cb)
      add(result, column_text(stmt, 0))
  else:
    result = ""
  if finalize(stmt) != SQLITE_OK: dbError(db)
  
proc tryInsertID*(db: TDbConn, query: TSqlQuery, 
                  args: varargs[string, `$`]): int64
                  {.tags: [FWriteDb], raises: [].} =
  ## executes the query (typically "INSERT") and returns the 
  ## generated ID for the row or -1 in case of an error. 
  var q = dbFormat(query, args)
  var stmt: sqlite3.Pstmt
  result = -1
  if prepare_v2(db, q, q.len.cint, stmt, nil) == SQLITE_OK:
    if step(stmt) == SQLITE_DONE:
      result = last_insert_rowid(db)
    if finalize(stmt) != SQLITE_OK:
      result = -1

proc insertID*(db: TDbConn, query: TSqlQuery, 
               args: varargs[string, `$`]): int64 {.tags: [FWriteDb].} = 
  ## executes the query (typically "INSERT") and returns the 
  ## generated ID for the row. For Postgre this adds
  ## ``RETURNING id`` to the query, so it only works if your primary key is
  ## named ``id``. 
  result = tryInsertID(db, query, args)
  if result < 0: dbError(db)
  
proc execAffectedRows*(db: TDbConn, query: TSqlQuery, 
                       args: varargs[string, `$`]): int64 {.
                       tags: [FReadDb, FWriteDb].} = 
  ## executes the query (typically "UPDATE") and returns the
  ## number of affected rows.
  exec(db, query, args)
  result = changes(db)

proc close*(db: TDbConn) {.tags: [FDb].} = 
  ## closes the database connection.
  if sqlite3.close(db) != SQLITE_OK: dbError(db)
    
proc open*(connection, user, password, database: string): TDbConn {.
  tags: [FDb].} =
  ## opens a database connection. Raises `EDb` if the connection could not
  ## be established. Only the ``connection`` parameter is used for ``sqlite``.
  var db: TDbConn
  if sqlite3.open(connection, db) == SQLITE_OK:
    result = db
  else:
    dbError(db)

proc setEncoding*(connection: TDbConn, encoding: string): bool {.
  tags: [FDb].} =
  ## sets the encoding of a database connection, returns true for 
  ## success, false for failure.
  ##
  ## Note that the encoding cannot be changed once it's been set.
  ## According to SQLite3 documentation, any attempt to change 
  ## the encoding after the database is created will be silently 
  ## ignored.
  exec(connection, sql"PRAGMA encoding = ?", [encoding])
  result = connection.getValue(sql"PRAGMA encoding") == encoding

when isMainModule:
  var db = open("db.sql", "", "", "")
  exec(db, sql"create table tbl1(one varchar(10), two smallint)", [])
  exec(db, sql"insert into tbl1 values('hello!',10)", [])
  exec(db, sql"insert into tbl1 values('goodbye', 20)", [])
  #db.query("create table tbl1(one varchar(10), two smallint)")
  #db.query("insert into tbl1 values('hello!',10)")
  #db.query("insert into tbl1 values('goodbye', 20)")
  for r in db.rows(sql"select * from tbl1", []):
    echo(r[0], r[1])
  
  db_sqlite.close(db)
