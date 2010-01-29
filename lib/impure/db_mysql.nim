# Nimrod mySQL database wrapper
# (c) 2009 Andreas Rumpf

import strutils, mysql

type
  TDbHandle* = PMySQL
  TRow* = seq[string]
  EDb* = object of EIO
  
proc dbError(db: TDbHandle) {.noreturn.} = 
  ## raises an EDb exception.
  var e: ref EDb
  new(e)
  e.msg = $mysql_error(db)
  raise e

proc dbError*(msg: string) {.noreturn.} = 
  ## raises an EDb exception with message `msg`.
  var e: ref EDb
  new(e)
  e.msg = msg
  raise e

when false:
  proc dbQueryOpt*(db: TDbHandle, query: string, args: openarray[string]) =
    var stmt = mysql_stmt_init(db)
    if stmt == nil: dbError(db)
    if mysql_stmt_prepare(stmt, query, len(query)) != 0: 
      dbError(db)
    var 
      bind: seq[MYSQL_BIND]
    discard mysql_stmt_close(stmt)

proc dbQuote(s: string): string =
  result = "'"
  for c in items(s):
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

proc dbFormat(formatstr: string, args: openarray[string]): string =
  result = ""
  var a = 0
  for c in items(formatstr):
    if c == '?':
      add(result, dbQuote(args[a]))
      inc(a)
    else: 
      add(result, c)
  
proc dbTryQuery*(db: TDbHandle, query: string, args: openarray[string]): bool =
  var q = dbFormat(query, args)
  return mysqlRealQuery(db, q, q.len) == 0'i32

proc dbQuery*(db: TDbHandle, query: string, args: openarray[string]) =
  var q = dbFormat(query, args)
  if mysqlRealQuery(db, q, q.len) != 0'i32: dbError(db)
  
proc dbTryInsertID*(db: TDbHandle, query: string, 
                    args: openarray[string]): int64 =
  var q = dbFormat(query, args)
  if mysqlRealQuery(db, q, q.len) != 0'i32: 
    result = -1'i64
  else:
    result = mysql_insert_id(db)
  
proc dbInsertID*(db: TDbHandle, query: string, args: openArray[string]): int64 = 
  result = dbTryInsertID(db, query, args)
  if result < 0: dbError(db)
  
proc dbQueryAffectedRows*(db: TDbHandle, query: string, 
                          args: openArray[string]): int64 = 
  ## runs the query (typically "UPDATE") and returns the
  ## number of affected rows
  dbQuery(db, query, args)
  result = mysql_affected_rows(db)
  
proc newRow(L: int): TRow = 
  newSeq(result, L)
  for i in 0..L-1: result[i] = ""
  
proc properFreeResult(sqlres: PMYSQL_RES, row: cstringArray) =  
  if row != nil:
    while mysqlFetchRow(sqlres) != nil: nil
  mysqlFreeResult(sqlres)

proc dbGetAllRows*(db: TDbHandle, query: string, 
                   args: openarray[string]): seq[TRow] =
  result = @[]
  dbQuery(db, query, args)
  var sqlres = mysqlUseResult(db)
  if sqlres != nil:
    var L = int(mysql_num_fields(sqlres))
    var row: cstringArray
    var j = 0
    while true:
      row = mysqlFetchRow(sqlres)
      if row == nil: break
      setLen(result, j+1)
      newSeq(result[j], L)
      for i in 0..L-1: result[j][i] = $row[i]
      inc(j)
    mysqlFreeResult(sqlres)

iterator dbRows*(db: TDbHandle, query: string, 
                 args: openarray[string]): TRow =
  for r in items(dbGetAllRows(db, query, args)): yield r
  
iterator dbFastRows*(db: TDbHandle, query: string,
                     args: openarray[string]): TRow =
  # this is carefully optimized, so that the memory is reused!
  dbQuery(db, query, args)
  var sqlres = mysqlUseResult(db)
  if sqlres != nil:
    var L = int(mysql_num_fields(sqlres))
    var result = newRow(L)
    var row: cstringArray
    while true:
      row = mysqlFetchRow(sqlres)
      if row == nil: break
      for i in 0..L-1: 
        setLen(result[i], 0)
        add(result[i], row[i])
      yield result
    properFreeResult(sqlres, row)

proc dbGetValue*(db: TDbHandle, query: string, 
                 args: openarray[string]): string = 
  result = ""
  for row in dbFastRows(db, query, args): 
    result = row[0]
    break

proc dbClose*(db: TDbHandle) = 
  if db != nil: mysqlClose(db)

proc dbOpen*(connection, user, password, database: string): TDbHandle =
  result = mysqlInit(nil)
  if result != nil: 
    if mysqlRealConnect(result, "", user, password, database, 
                        0'i32, nil, 0) == nil:
      dbClose(result)
      result = nil

