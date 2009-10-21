# Nimrod PostgreSQL database wrapper
# (c) 2009 Andreas Rumpf

import strutils, postgres

type
  TDbHandle* = PGconn
  TRow* = seq[string]
  EDb* = object of EIO
  
proc dbError(db: TDbHandle) {.noreturn.} = 
  ## raises an EDb exception.
  var e: ref EDb
  new(e)
  e.msg = PQerrorMessage(db)
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
  var res = PQExec(db, q)
  result = PQresultStatus(res) == PGRES_COMMAND_OK
  PQclear(res)

proc dbQuery*(db: TDbHandle, query: string, args: openarray[string]) =
  var q = dbFormat(query, args)
  var res = PQExec(db, q)
  if PQresultStatus(res) != PGRES_COMMAND_OK: dbError(db)
  PQclear(res)
  
proc dbTryInsertID*(db: TDbHandle, query: string, 
                    args: openarray[string]): int64 =
  var q = dbFormat(query, args)
  
  
  if mysqlRealQuery(db, q, q.len) != 0'i32: 
    result = -1'i64
  else:
    result = mysql_insert_id(db)
  LAST_INSERT_ID()

proc dbInsertID*(db: TDbHandle, query: string, args: openArray[string]): int64 = 
  result = dbTryInsertID(db, query, args)
  if result < 0: dbError(db)
  
proc dbQueryAffectedRows*(db: TDbHandle, query: string, 
                          args: openArray[string]): int64 = 
  ## runs the query (typically "UPDATE") and returns the
  ## number of affected rows
  var q = dbFormat(query, args)
  var res = PQExec(db, q)
  if PQresultStatus(res) != PGRES_COMMAND_OK: dbError(db)
  result = parseBiggestInt($PQcmdTuples(res))
  PQclear(res)
  
proc newRow(L: int): TRow =
  newSeq(result, L)
  for i in 0..L-1: result[i] = ""
  
iterator dbFastRows*(db: TDbHandle, query: string,
                     args: openarray[string]): TRow =
  var q = dbFormat(query, args)
  var res = PQExec(db, q)
  if PQresultStatus(res) != PGRES_TUPLES_OK: dbError(db)
  var L = int(PQnfields(res))
  var result = newRow(L)
  for i in 0..PQntuples(res)-1:
    for j in 0..L-1:
      setLen(result[j], 0)
      add(result[j], PQgetvalue(res, i, j))
    yield result
  PQclear(res)

proc dbGetAllRows*(db: TDbHandle, query: string, 
                   args: openarray[string]): seq[TRow] =
  result = @[]
  for r in dbFastRows(db, query, args):
    result.add(r)

iterator dbRows*(db: TDbHandle, query: string, 
                 args: openarray[string]): TRow =
  for r in items(dbGetAllRows(db, query, args)): yield r

proc dbGetValue*(db: TDbHandle, query: string, 
                 args: openarray[string]): string = 
  result = ""
  for row in dbFastRows(db, query, args): 
    result = row[0]
    break

proc dbClose*(db: TDbHandle) = 
  if db != nil: PQfinish(db)

proc dbOpen*(connection, user, password, database: string): TDbHandle =
  result = PQsetdbLogin(nil, nil, nil, nil, database, user, password)
  if PQStatus(result) != CONNECTION_OK: result = nil
