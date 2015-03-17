#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## A higher level `mySQL`:idx: database wrapper. The same interface is 
## implemented for other databases too.

import strutils, mysql

type
  TDbConn* = PMySQL    ## encapsulates a database connection
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
  e.msg = $mysql.error(db)
  raise e

proc dbError*(msg: string) {.noreturn.} = 
  ## raises an EDb exception with message `msg`.
  var e: ref EDb
  new(e)
  e.msg = msg
  raise e

when false:
  proc dbQueryOpt*(db: TDbConn, query: string, args: varargs[string, `$`]) =
    var stmt = mysql_stmt_init(db)
    if stmt == nil: dbError(db)
    if mysql_stmt_prepare(stmt, query, len(query)) != 0: 
      dbError(db)
    var 
      binding: seq[MYSQL_BIND]
    discard mysql_stmt_close(stmt)

proc dbQuote*(s: string): string =
  ## DB quotes the string.
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
      if args[a] == nil:
        add(result, "NULL")
      else:
        add(result, dbQuote(args[a]))
      inc(a)
    else: 
      add(result, c)
  
proc tryExec*(db: TDbConn, query: TSqlQuery, args: varargs[string, `$`]): bool {.
  tags: [FReadDB, FWriteDb].} =
  ## tries to execute the query and returns true if successful, false otherwise.
  var q = dbFormat(query, args)
  return mysql.realQuery(db, q, q.len) == 0'i32

proc rawExec(db: TDbConn, query: TSqlQuery, args: varargs[string, `$`]) =
  var q = dbFormat(query, args)
  if mysql.realQuery(db, q, q.len) != 0'i32: dbError(db)

proc exec*(db: TDbConn, query: TSqlQuery, args: varargs[string, `$`]) {.
  tags: [FReadDB, FWriteDb].} =
  ## executes the query and raises EDB if not successful.
  var q = dbFormat(query, args)
  if mysql.realQuery(db, q, q.len) != 0'i32: dbError(db)
    
proc newRow(L: int): TRow = 
  newSeq(result, L)
  for i in 0..L-1: result[i] = ""
  
proc properFreeResult(sqlres: mysql.PRES, row: cstringArray) =  
  if row != nil:
    while mysql.fetchRow(sqlres) != nil: discard
  mysql.freeResult(sqlres)
  
iterator fastRows*(db: TDbConn, query: TSqlQuery,
                   args: varargs[string, `$`]): TRow {.tags: [FReadDB].} =
  ## executes the query and iterates over the result dataset. This is very 
  ## fast, but potenially dangerous: If the for-loop-body executes another
  ## query, the results can be undefined. For MySQL this is the case!.
  rawExec(db, query, args)
  var sqlres = mysql.useResult(db)
  if sqlres != nil:
    var L = int(mysql.numFields(sqlres))
    var result = newRow(L)
    var row: cstringArray
    while true:
      row = mysql.fetchRow(sqlres)
      if row == nil: break
      for i in 0..L-1: 
        setLen(result[i], 0)
        if row[i] == nil:
          result[i] = nil
        else:
          add(result[i], row[i])
      yield result
    properFreeResult(sqlres, row)

proc getRow*(db: TDbConn, query: TSqlQuery,
             args: varargs[string, `$`]): TRow {.tags: [FReadDB].} =
  ## retrieves a single row. If the query doesn't return any rows, this proc
  ## will return a TRow with empty strings for each column.
  rawExec(db, query, args)
  var sqlres = mysql.useResult(db)
  if sqlres != nil:
    var L = int(mysql.numFields(sqlres))
    result = newRow(L)
    var row = mysql.fetchRow(sqlres)
    if row != nil: 
      for i in 0..L-1: 
        setLen(result[i], 0)
        if row[i] == nil:
          result[i] = nil
        else:
          add(result[i], row[i])
    properFreeResult(sqlres, row)

proc getAllRows*(db: TDbConn, query: TSqlQuery, 
                 args: varargs[string, `$`]): seq[TRow] {.tags: [FReadDB].} =
  ## executes the query and returns the whole result dataset.
  result = @[]
  rawExec(db, query, args)
  var sqlres = mysql.useResult(db)
  if sqlres != nil:
    var L = int(mysql.numFields(sqlres))
    var row: cstringArray
    var j = 0
    while true:
      row = mysql.fetchRow(sqlres)
      if row == nil: break
      setLen(result, j+1)
      newSeq(result[j], L)
      for i in 0..L-1:
        if row[i] == nil:
          result[j][i] = nil
        else:
          result[j][i] = $row[i]
      inc(j)
    mysql.freeResult(sqlres)

iterator rows*(db: TDbConn, query: TSqlQuery, 
               args: varargs[string, `$`]): TRow {.tags: [FReadDB].} =
  ## same as `fastRows`, but slower and safe.
  for r in items(getAllRows(db, query, args)): yield r

proc getValue*(db: TDbConn, query: TSqlQuery, 
               args: varargs[string, `$`]): string {.tags: [FReadDB].} = 
  ## executes the query and returns the first column of the first row of the
  ## result dataset. Returns "" if the dataset contains no rows or the database
  ## value is NULL.
  result = ""
  for row in fastRows(db, query, args): 
    result = row[0]
    break

proc tryInsertId*(db: TDbConn, query: TSqlQuery, 
                  args: varargs[string, `$`]): int64 {.tags: [FWriteDb].} =
  ## executes the query (typically "INSERT") and returns the 
  ## generated ID for the row or -1 in case of an error.
  var q = dbFormat(query, args)
  if mysql.realQuery(db, q, q.len) != 0'i32: 
    result = -1'i64
  else:
    result = mysql.insertId(db)
  
proc insertId*(db: TDbConn, query: TSqlQuery, 
               args: varargs[string, `$`]): int64 {.tags: [FWriteDb].} = 
  ## executes the query (typically "INSERT") and returns the 
  ## generated ID for the row.
  result = tryInsertID(db, query, args)
  if result < 0: dbError(db)

proc execAffectedRows*(db: TDbConn, query: TSqlQuery, 
                       args: varargs[string, `$`]): int64 {.
                       tags: [FReadDB, FWriteDb].} = 
  ## runs the query (typically "UPDATE") and returns the
  ## number of affected rows
  rawExec(db, query, args)
  result = mysql.affectedRows(db)

proc close*(db: TDbConn) {.tags: [FDb].} = 
  ## closes the database connection.
  if db != nil: mysql.close(db)

proc open*(connection, user, password, database: string): TDbConn {.
  tags: [FDb].} =
  ## opens a database connection. Raises `EDb` if the connection could not
  ## be established.
  result = mysql.init(nil)
  if result == nil: dbError("could not open database connection") 
  let
    colonPos = connection.find(':')
    host = if colonPos < 0: connection
           else: substr(connection, 0, colonPos-1)
    port: int32 = if colonPos < 0: 0'i32
                  else: substr(connection, colonPos+1).parseInt.int32
  if mysql.realConnect(result, host, user, password, database, 
                       port, nil, 0) == nil:
    var errmsg = $mysql.error(result)
    db_mysql.close(result)
    dbError(errmsg)

proc setEncoding*(connection: TDbConn, encoding: string): bool {.
  tags: [FDb].} =
  ## sets the encoding of a database connection, returns true for 
  ## success, false for failure.
  result = mysql.set_character_set(connection, encoding) == 0