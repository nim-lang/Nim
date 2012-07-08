#
#
#            Nimrod's Runtime Library
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
  TRow* = seq[string]  ## a row of a dataset
  EDb* = object of EIO ## exception that is raised if a database error occurs
  
  TSqlQuery* = distinct string ## an SQL query string
  
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
  result = "'"
  for c in items(s):
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

proc dbFormat(formatstr: TSqlQuery, args: openarray[string]): string =
  result = ""
  var a = 0
  for c in items(string(formatstr)):
    if c == '?':
      add(result, dbQuote(args[a]))
      inc(a)
    else: 
      add(result, c)
  
proc TryExec*(db: TDbConn, query: TSqlQuery, 
              args: openarray[string]): bool =
  ## tries to execute the query and returns true if successful, false otherwise.
  var q = dbFormat(query, args)
  var stmt: sqlite3.PStmt
  if prepare_v2(db, q, q.len.cint, stmt, nil) == SQLITE_OK:
    if step(stmt) == SQLITE_DONE:
      result = finalize(stmt) == SQLITE_OK

proc Exec*(db: TDbConn, query: TSqlQuery, args: openarray[string]) =
  ## executes the query and raises EDB if not successful.
  if not TryExec(db, query, args): dbError(db)
  
proc newRow(L: int): TRow =
  newSeq(result, L)
  for i in 0..L-1: result[i] = ""
  
proc setupQuery(db: TDbConn, query: TSqlQuery, 
                args: openarray[string]): PStmt = 
  var q = dbFormat(query, args)
  if prepare_v2(db, q, q.len.cint, result, nil) != SQLITE_OK: dbError(db)
  
proc setRow(stmt: PStmt, r: var TRow, cols: cint) =
  for col in 0..cols-1:
    setLen(r[col], column_bytes(stmt, col)) # set capacity
    setLen(r[col], 0)
    let x = column_text(stmt, col)
    if not isNil(x): add(r[col], x)
  
iterator FastRows*(db: TDbConn, query: TSqlQuery,
                   args: openarray[string]): TRow =
  ## executes the query and iterates over the result dataset. This is very 
  ## fast, but potenially dangerous: If the for-loop-body executes another
  ## query, the results can be undefined. For Sqlite it is safe though.
  var stmt = setupQuery(db, query, args)
  var L = (columnCount(stmt))
  var result = newRow(L)
  while step(stmt) == SQLITE_ROW: 
    setRow(stmt, result, L)
    yield result
  if finalize(stmt) != SQLITE_OK: dbError(db)

proc getRow*(db: TDbConn, query: TSqlQuery,
             args: openarray[string]): TRow =
  ## retrieves a single row.
  var stmt = setupQuery(db, query, args)
  var L = (columnCount(stmt))
  result = newRow(L)
  if step(stmt) == SQLITE_ROW: 
    setRow(stmt, result, L)
  if finalize(stmt) != SQLITE_OK: dbError(db)

proc GetAllRows*(db: TDbConn, query: TSqlQuery, 
                 args: openarray[string]): seq[TRow] =
  ## executes the query and returns the whole result dataset.
  result = @[]
  for r in FastRows(db, query, args):
    result.add(r)

iterator Rows*(db: TDbConn, query: TSqlQuery, 
               args: openarray[string]): TRow =
  ## same as `FastRows`, but slower and safe.
  for r in FastRows(db, query, args): yield r

proc GetValue*(db: TDbConn, query: TSqlQuery, 
               args: openarray[string]): string = 
  ## executes the query and returns the result dataset's the first column 
  ## of the first row. Returns "" if the dataset contains no rows.
  var stmt = setupQuery(db, query, args)
  if step(stmt) == SQLITE_ROW: 
    result = newStringOfCap(column_bytes(stmt, 0))
    add(result, column_text(stmt, 0))
    if finalize(stmt) != SQLITE_OK: dbError(db)
  else:
    result = ""
  
proc TryInsertID*(db: TDbConn, query: TSqlQuery, 
                  args: openarray[string]): int64 =
  ## executes the query (typically "INSERT") and returns the 
  ## generated ID for the row or -1 in case of an error. 
  if tryExec(db, query, args): 
    result = last_insert_rowid(db)
  else:
    result = -1

proc InsertID*(db: TDbConn, query: TSqlQuery, 
               args: openArray[string]): int64 = 
  ## executes the query (typically "INSERT") and returns the 
  ## generated ID for the row. For Postgre this adds
  ## ``RETURNING id`` to the query, so it only works if your primary key is
  ## named ``id``. 
  result = TryInsertID(db, query, args)
  if result < 0: dbError(db)
  
proc ExecAffectedRows*(db: TDbConn, query: TSqlQuery, 
                       args: openArray[string]): int64 = 
  ## executes the query (typically "UPDATE") and returns the
  ## number of affected rows.
  Exec(db, query, args)
  result = changes(db)

proc Close*(db: TDbConn) = 
  ## closes the database connection.
  if sqlite3.close(db) != SQLITE_OK: dbError(db)
    
proc Open*(connection, user, password, database: string): TDbConn =
  ## opens a database connection. Raises `EDb` if the connection could not
  ## be established. Only the ``connection`` parameter is used for ``sqlite``.
  var db: TDbConn
  if sqlite3.open(connection, db) == SQLITE_OK:
    result = db
  else:
    dbError(db)
   
when isMainModule:
  var db = open("db.sql", "", "", "")
  Exec(db, sql"create table tbl1(one varchar(10), two smallint)", [])
  exec(db, sql"insert into tbl1 values('hello!',10)", [])
  exec(db, sql"insert into tbl1 values('goodbye', 20)", [])
  #db.query("create table tbl1(one varchar(10), two smallint)")
  #db.query("insert into tbl1 values('hello!',10)")
  #db.query("insert into tbl1 values('goodbye', 20)")
  for r in db.rows(sql"select * from tbl1", []):
    echo(r[0], r[1])
  
  db_sqlite.close(db)
