#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## A higher level `SQLite`:idx: database wrapper. This interface
## is implemented for other databases too.
##
## Basic usage
## ===========
##
## The basic flow of using this module is:
##
## 1. Open database connection
## 2. Execute SQL query
## 3. Close database connection
##
## Parameter substitution
## ----------------------
##
## All `db_*` modules support the same form of parameter substitution.
## That is, using the `?` (question mark) to signify the place where a
## value should be placed. For example:
##
## .. code-block:: Nim
##
##    sql"INSERT INTO my_table (colA, colB, colC) VALUES (?, ?, ?)"
##
## Opening a connection to a database
## ----------------------------------
##
## .. code-block:: Nim
##
##    import std/db_sqlite
##
##    # user, password, database name can be empty.
##    # These params are not used on db_sqlite module.
##    let db = open("mytest.db", "", "", "")
##    db.close()
##
## Creating a table
## ----------------
##
## .. code-block:: Nim
##
##    db.exec(sql"DROP TABLE IF EXISTS my_table")
##    db.exec(sql"""CREATE TABLE my_table (
##                     id   INTEGER,
##                     name VARCHAR(50) NOT NULL
##                  )""")
##
## Inserting data
## --------------
##
## .. code-block:: Nim
##
##    db.exec(sql"INSERT INTO my_table (id, name) VALUES (0, ?)",
##            "Jack")
##
## Larger example
## --------------
##
## .. code-block:: nim
##
##    import std/[db_sqlite, math]
##
##    let db = open("mytest.db", "", "", "")
##
##    db.exec(sql"DROP TABLE IF EXISTS my_table")
##    db.exec(sql"""CREATE TABLE my_table (
##                     id    INTEGER PRIMARY KEY,
##                     name  VARCHAR(50) NOT NULL,
##                     i     INT(11),
##                     f     DECIMAL(18, 10)
##                  )""")
##
##    db.exec(sql"BEGIN")
##    for i in 1..1000:
##      db.exec(sql"INSERT INTO my_table (name, i, f) VALUES (?, ?, ?)",
##              "Item#" & $i, i, sqrt(i.float))
##    db.exec(sql"COMMIT")
##
##    for x in db.fastRows(sql"SELECT * FROM my_table"):
##      echo x
##
##    let id = db.tryInsertId(sql"""INSERT INTO my_table (name, i, f)
##                                  VALUES (?, ?, ?)""",
##                            "Item#1001", 1001, sqrt(1001.0))
##    echo "Inserted item: ", db.getValue(sql"SELECT name FROM my_table WHERE id=?", id)
##
##    db.close()
##
## Storing binary data example
##----------------------------
##
## .. code-block:: nim
##
##   import std/random
##
##   ## Generate random float datas
##   var orig = newSeq[float64](150)
##   randomize()
##   for x in orig.mitems:
##     x = rand(1.0)/10.0
##
##   let db = open("mysqlite.db", "", "", "")
##   block: ## Create database
##     ## Binary datas needs to be of type BLOB in SQLite
##     let createTableStr = sql"""CREATE TABLE test(
##       id INTEGER NOT NULL PRIMARY KEY,
##       data BLOB
##     )
##     """
##     db.exec(createTableStr)
##
##   block: ## Insert data
##     var id = 1
##     ## Data needs to be converted to seq[byte] to be interpreted as binary by bindParams
##     var dbuf = newSeq[byte](orig.len*sizeof(float64))
##     copyMem(unsafeAddr(dbuf[0]), unsafeAddr(orig[0]), dbuf.len)
##
##     ## Use prepared statement to insert binary data into database
##     var insertStmt = db.prepare("INSERT INTO test (id, data) VALUES (?, ?)")
##     insertStmt.bindParams(id, dbuf)
##     let bres = db.tryExec(insertStmt)
##     ## Check insert
##     doAssert(bres)
##     # Destroy statement
##     finalize(insertStmt)
##
##   block: ## Use getValue to select data
##     var dataTest = db.getValue(sql"SELECT data FROM test WHERE id = ?", 1)
##     ## Calculate sequence size from buffer size
##     let seqSize = int(dataTest.len*sizeof(byte)/sizeof(float64))
##     ## Copy binary string data in dataTest into a seq
##     var res: seq[float64] = newSeq[float64](seqSize)
##     copyMem(unsafeAddr(res[0]), addr(dataTest[0]), dataTest.len)
##
##     ## Check datas obtained is identical
##     doAssert res == orig
##
##   db.close()
##
##
## Note
## ====
## This module does not implement any ORM features such as mapping the types from the schema.
## Instead, a `seq[string]` is returned for each row.
##
## The reasoning is as follows:
## 1. it's close to what many DBs offer natively (`char**`:c:)
## 2. it hides the number of types that the DB supports
##    (int? int64? decimal up to 10 places? geo coords?)
## 3. it's convenient when all you do is to forward the data to somewhere else (echo, log, put the data into a new query)
##
## See also
## ========
##
## * `db_odbc module <db_odbc.html>`_ for ODBC database wrapper
## * `db_mysql module <db_mysql.html>`_ for MySQL database wrapper
## * `db_postgres module <db_postgres.html>`_ for PostgreSQL database wrapper

{.experimental: "codeReordering".}

import sqlite3, macros

import db_common
export db_common

import std/private/[since, dbutils]

type
  DbConn* = PSqlite3  ## Encapsulates a database connection.
  Row* = seq[string]  ## A row of a dataset. `NULL` database values will be
                      ## converted to an empty string.
  InstantRow* = PStmt ## A handle that can be used to get a row's column
                      ## text on demand.
  SqlPrepared* = distinct PStmt ## a identifier for the prepared queries

proc dbError*(db: DbConn) {.noreturn.} =
  ## Raises a `DbError` exception.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##    if not db.tryExec(sql"SELECT * FROM not_exist_table"):
  ##      dbError(db)
  ##    db.close()
  var e: ref DbError
  new(e)
  e.msg = $sqlite3.errmsg(db)
  raise e

proc dbQuote*(s: string): string =
  ## Escapes the `'` (single quote) char to `''`.
  ## Because single quote is used for defining `VARCHAR` in SQL.
  runnableExamples:
    doAssert dbQuote("'") == "''''"
    doAssert dbQuote("A Foobar's pen.") == "'A Foobar''s pen.'"

  result = "'"
  for c in items(s):
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

proc dbFormat(formatstr: SqlQuery, args: varargs[string]): string =
  dbFormatImpl(formatstr, dbQuote, args)

proc prepare*(db: DbConn; q: string): SqlPrepared {.since: (1, 3).} =
  ## Creates a new `SqlPrepared` statement.
  if prepare_v2(db, q, q.len.cint,result.PStmt, nil) != SQLITE_OK:
    discard finalize(result.PStmt)
    dbError(db)

proc tryExec*(db: DbConn, query: SqlQuery,
              args: varargs[string, `$`]): bool {.
              tags: [ReadDbEffect, WriteDbEffect].} =
  ## Tries to execute the query and returns `true` if successful, `false` otherwise.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##    if not db.tryExec(sql"SELECT * FROM my_table"):
  ##      dbError(db)
  ##    db.close()
  assert(not db.isNil, "Database not connected.")
  var q = dbFormat(query, args)
  var stmt: sqlite3.PStmt
  if prepare_v2(db, q, q.len.cint, stmt, nil) == SQLITE_OK:
    let x = step(stmt)
    if x in {SQLITE_DONE, SQLITE_ROW}:
      result = finalize(stmt) == SQLITE_OK
    else:
      discard finalize(stmt)
      result = false

proc tryExec*(db: DbConn, stmtName: SqlPrepared): bool {.
              tags: [ReadDbEffect, WriteDbEffect].} =
    let x = step(stmtName.PStmt)
    if x in {SQLITE_DONE, SQLITE_ROW}:
      result = true
    else:
      discard finalize(stmtName.PStmt)
      result = false

proc exec*(db: DbConn, query: SqlQuery, args: varargs[string, `$`])  {.
  tags: [ReadDbEffect, WriteDbEffect].} =
  ## Executes the query and raises a `DbError` exception if not successful.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##    try:
  ##      db.exec(sql"INSERT INTO my_table (id, name) VALUES (?, ?)",
  ##              1, "item#1")
  ##    except:
  ##      stderr.writeLine(getCurrentExceptionMsg())
  ##    finally:
  ##      db.close()
  if not tryExec(db, query, args): dbError(db)

proc newRow(L: int): Row =
  newSeq(result, L)
  for i in 0..L-1: result[i] = ""

proc setupQuery(db: DbConn, query: SqlQuery,
                args: varargs[string]): PStmt =
  assert(not db.isNil, "Database not connected.")
  var q = dbFormat(query, args)
  if prepare_v2(db, q, q.len.cint, result, nil) != SQLITE_OK: dbError(db)

proc setupQuery(db: DbConn, stmtName: SqlPrepared): SqlPrepared {.since: (1, 3).} =
  assert(not db.isNil, "Database not connected.")
  result = stmtName

proc setRow(stmt: PStmt, r: var Row, cols: cint) =
  for col in 0'i32..cols-1:
    let cb = column_bytes(stmt, col)
    setLen(r[col], cb) # set capacity
    if column_type(stmt, col) == SQLITE_BLOB:
      copyMem(addr(r[col][0]), column_blob(stmt, col), cb)
    else:
      setLen(r[col], 0)
      let x = column_text(stmt, col)
      if not isNil(x): add(r[col], x)

iterator fastRows*(db: DbConn, query: SqlQuery,
                   args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  ## Executes the query and iterates over the result dataset.
  ##
  ## This is very fast, but potentially dangerous. Use this iterator only
  ## if you require **ALL** the rows.
  ##
  ## **Note:** Breaking the `fastRows()` iterator during a loop will cause the
  ## next database query to raise a `DbError` exception `unable to close due
  ## to ...`.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##
  ##    # Records of my_table:
  ##    # | id | name     |
  ##    # |----|----------|
  ##    # |  1 | item#1   |
  ##    # |  2 | item#2   |
  ##
  ##    for row in db.fastRows(sql"SELECT id, name FROM my_table"):
  ##      echo row
  ##
  ##    # Output:
  ##    # @["1", "item#1"]
  ##    # @["2", "item#2"]
  ##
  ##    db.close()
  var stmt = setupQuery(db, query, args)
  var L = (column_count(stmt))
  var result = newRow(L)
  try:
    while step(stmt) == SQLITE_ROW:
      setRow(stmt, result, L)
      yield result
  finally:
    if finalize(stmt) != SQLITE_OK: dbError(db)

iterator fastRows*(db: DbConn, stmtName: SqlPrepared): Row
                  {.tags: [ReadDbEffect,WriteDbEffect], since: (1, 3).} =
  discard setupQuery(db, stmtName)
  var L = (column_count(stmtName.PStmt))
  var result = newRow(L)
  try:
    while step(stmtName.PStmt) == SQLITE_ROW:
      setRow(stmtName.PStmt, result, L)
      yield result
  except:
    dbError(db)

iterator instantRows*(db: DbConn, query: SqlQuery,
                      args: varargs[string, `$`]): InstantRow
                      {.tags: [ReadDbEffect].} =
  ## Similar to `fastRows iterator <#fastRows.i,DbConn,SqlQuery,varargs[string,]>`_
  ## but returns a handle that can be used to get column text
  ## on demand using `[]`. Returned handle is valid only within the iterator body.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##
  ##    # Records of my_table:
  ##    # | id | name     |
  ##    # |----|----------|
  ##    # |  1 | item#1   |
  ##    # |  2 | item#2   |
  ##
  ##    for row in db.instantRows(sql"SELECT * FROM my_table"):
  ##      echo "id:" & row[0]
  ##      echo "name:" & row[1]
  ##      echo "length:" & $len(row)
  ##
  ##    # Output:
  ##    # id:1
  ##    # name:item#1
  ##    # length:2
  ##    # id:2
  ##    # name:item#2
  ##    # length:2
  ##
  ##    db.close()
  var stmt = setupQuery(db, query, args)
  try:
    while step(stmt) == SQLITE_ROW:
      yield stmt
  finally:
    if finalize(stmt) != SQLITE_OK: dbError(db)

iterator instantRows*(db: DbConn, stmtName: SqlPrepared): InstantRow
                      {.tags: [ReadDbEffect,WriteDbEffect], since: (1, 3).} =
  var stmt = setupQuery(db, stmtName).PStmt
  try:
    while step(stmt) == SQLITE_ROW:
      yield stmt
  except:
    dbError(db)

proc toTypeKind(t: var DbType; x: int32) =
  case x
  of SQLITE_INTEGER:
    t.kind = dbInt
    t.size = 8
  of SQLITE_FLOAT:
    t.kind = dbFloat
    t.size = 8
  of SQLITE_BLOB: t.kind = dbBlob
  of SQLITE_NULL: t.kind = dbNull
  of SQLITE_TEXT: t.kind = dbVarchar
  else: t.kind = dbUnknown

proc setColumns(columns: var DbColumns; x: PStmt) =
  let L = column_count(x)
  setLen(columns, L)
  for i in 0'i32 ..< L:
    columns[i].name = $column_name(x, i)
    columns[i].typ.name = $column_decltype(x, i)
    toTypeKind(columns[i].typ, column_type(x, i))
    columns[i].tableName = $column_table_name(x, i)

iterator instantRows*(db: DbConn; columns: var DbColumns; query: SqlQuery,
                      args: varargs[string, `$`]): InstantRow
                      {.tags: [ReadDbEffect].} =
  ## Similar to `instantRows iterator <#instantRows.i,DbConn,SqlQuery,varargs[string,]>`_,
  ## but sets information about columns to `columns`.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##
  ##    # Records of my_table:
  ##    # | id | name     |
  ##    # |----|----------|
  ##    # |  1 | item#1   |
  ##    # |  2 | item#2   |
  ##
  ##    var columns: DbColumns
  ##    for row in db.instantRows(columns, sql"SELECT * FROM my_table"):
  ##      discard
  ##    echo columns[0]
  ##
  ##    # Output:
  ##    # (name: "id", tableName: "my_table", typ: (kind: dbNull,
  ##    # notNull: false, name: "INTEGER", size: 0, maxReprLen: 0, precision: 0,
  ##    # scale: 0, min: 0, max: 0, validValues: @[]), primaryKey: false,
  ##    # foreignKey: false)
  ##
  ##    db.close()
  var stmt = setupQuery(db, query, args)
  setColumns(columns, stmt)
  try:
    while step(stmt) == SQLITE_ROW:
      yield stmt
  finally:
    if finalize(stmt) != SQLITE_OK: dbError(db)

proc `[]`*(row: InstantRow, col: int32): string {.inline.} =
  ## Returns text for given column of the row.
  ##
  ## See also:
  ## * `instantRows iterator <#instantRows.i,DbConn,SqlQuery,varargs[string,]>`_
  ##   example code
  $column_text(row, col)

proc unsafeColumnAt*(row: InstantRow, index: int32): cstring {.inline.} =
  ## Returns cstring for given column of the row.
  ##
  ## See also:
  ## * `instantRows iterator <#instantRows.i,DbConn,SqlQuery,varargs[string,]>`_
  ##   example code
  column_text(row, index)

proc len*(row: InstantRow): int32 {.inline.} =
  ## Returns number of columns in a row.
  ##
  ## See also:
  ## * `instantRows iterator <#instantRows.i,DbConn,SqlQuery,varargs[string,]>`_
  ##   example code
  column_count(row)

proc getRow*(db: DbConn, query: SqlQuery,
             args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  ## Retrieves a single row. If the query doesn't return any rows, this proc
  ## will return a `Row` with empty strings for each column.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##
  ##    # Records of my_table:
  ##    # | id | name     |
  ##    # |----|----------|
  ##    # |  1 | item#1   |
  ##    # |  2 | item#2   |
  ##
  ##    doAssert db.getRow(sql"SELECT id, name FROM my_table"
  ##                       ) == Row(@["1", "item#1"])
  ##    doAssert db.getRow(sql"SELECT id, name FROM my_table WHERE id = ?",
  ##                       2) == Row(@["2", "item#2"])
  ##
  ##    # Returns empty.
  ##    doAssert db.getRow(sql"INSERT INTO my_table (id, name) VALUES (?, ?)",
  ##                       3, "item#3") == @[]
  ##    doAssert db.getRow(sql"DELETE FROM my_table WHERE id = ?", 3) == @[]
  ##    doAssert db.getRow(sql"UPDATE my_table SET name = 'ITEM#1' WHERE id = ?",
  ##                       1) == @[]
  ##    db.close()
  var stmt = setupQuery(db, query, args)
  var L = (column_count(stmt))
  result = newRow(L)
  if step(stmt) == SQLITE_ROW:
    setRow(stmt, result, L)
  if finalize(stmt) != SQLITE_OK: dbError(db)

proc getAllRows*(db: DbConn, query: SqlQuery,
                 args: varargs[string, `$`]): seq[Row] {.tags: [ReadDbEffect].} =
  ## Executes the query and returns the whole result dataset.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##
  ##    # Records of my_table:
  ##    # | id | name     |
  ##    # |----|----------|
  ##    # |  1 | item#1   |
  ##    # |  2 | item#2   |
  ##
  ##    doAssert db.getAllRows(sql"SELECT id, name FROM my_table") == @[Row(@["1", "item#1"]), Row(@["2", "item#2"])]
  ##    db.close()
  result = @[]
  for r in fastRows(db, query, args):
    result.add(r)

proc getAllRows*(db: DbConn, stmtName: SqlPrepared): seq[Row]
                {.tags: [ReadDbEffect,WriteDbEffect], since: (1, 3).} =
  result = @[]
  for r in fastRows(db, stmtName):
    result.add(r)

iterator rows*(db: DbConn, query: SqlQuery,
               args: varargs[string, `$`]): Row {.tags: [ReadDbEffect].} =
  ## Similar to `fastRows iterator <#fastRows.i,DbConn,SqlQuery,varargs[string,]>`_,
  ## but slower and safe.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##
  ##    # Records of my_table:
  ##    # | id | name     |
  ##    # |----|----------|
  ##    # |  1 | item#1   |
  ##    # |  2 | item#2   |
  ##
  ##    for row in db.rows(sql"SELECT id, name FROM my_table"):
  ##      echo row
  ##
  ##    ## Output:
  ##    ## @["1", "item#1"]
  ##    ## @["2", "item#2"]
  ##
  ##    db.close()
  for r in fastRows(db, query, args): yield r

iterator rows*(db: DbConn, stmtName: SqlPrepared): Row
              {.tags: [ReadDbEffect,WriteDbEffect], since: (1, 3).} =
  for r in fastRows(db, stmtName): yield r

proc getValue*(db: DbConn, query: SqlQuery,
               args: varargs[string, `$`]): string {.tags: [ReadDbEffect].} =
  ## Executes the query and returns the first column of the first row of the
  ## result dataset. Returns `""` if the dataset contains no rows or the database
  ## value is `NULL`.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##
  ##    # Records of my_table:
  ##    # | id | name     |
  ##    # |----|----------|
  ##    # |  1 | item#1   |
  ##    # |  2 | item#2   |
  ##
  ##    doAssert db.getValue(sql"SELECT name FROM my_table WHERE id = ?",
  ##                         2) == "item#2"
  ##    doAssert db.getValue(sql"SELECT id, name FROM my_table") == "1"
  ##    doAssert db.getValue(sql"SELECT name, id FROM my_table") == "item#1"
  ##
  ##    db.close()
  var stmt = setupQuery(db, query, args)
  if step(stmt) == SQLITE_ROW:
    let cb = column_bytes(stmt, 0)
    if cb == 0:
      result = ""
    else:
      if column_type(stmt, 0) == SQLITE_BLOB:
        result.setLen(cb)
        copyMem(addr(result[0]), column_blob(stmt, 0), cb)
      else:
        result = newStringOfCap(cb)
        add(result, column_text(stmt, 0))
  else:
    result = ""
  if finalize(stmt) != SQLITE_OK: dbError(db)

proc getValue*(db: DbConn,  stmtName: SqlPrepared): string
              {.tags: [ReadDbEffect,WriteDbEffect], since: (1, 3).} =
  var stmt = setupQuery(db, stmtName).PStmt
  if step(stmt) == SQLITE_ROW:
    let cb = column_bytes(stmt, 0)
    if cb == 0:
      result = ""
    else:
      if column_type(stmt, 0) == SQLITE_BLOB:
        result.setLen(cb)
        copyMem(addr(result[0]), column_blob(stmt, 0), cb)
      else:
        result = newStringOfCap(cb)
        add(result, column_text(stmt, 0))
  else:
    result = ""

proc tryInsertID*(db: DbConn, query: SqlQuery,
                  args: varargs[string, `$`]): int64
                  {.tags: [WriteDbEffect], raises: [DbError].} =
  ## Executes the query (typically "INSERT") and returns the
  ## generated ID for the row or -1 in case of an error.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##    db.exec(sql"CREATE TABLE my_table (id INTEGER, name VARCHAR(50) NOT NULL)")
  ##
  ##    doAssert db.tryInsertID(sql"INSERT INTO not_exist_table (id, name) VALUES (?, ?)",
  ##                            1, "item#1") == -1
  ##    db.close()
  assert(not db.isNil, "Database not connected.")
  var q = dbFormat(query, args)
  var stmt: sqlite3.PStmt
  result = -1
  if prepare_v2(db, q, q.len.cint, stmt, nil) == SQLITE_OK:
    if step(stmt) == SQLITE_DONE:
      result = last_insert_rowid(db)
    if finalize(stmt) != SQLITE_OK:
      result = -1
  else:
    discard finalize(stmt)

proc insertID*(db: DbConn, query: SqlQuery,
               args: varargs[string, `$`]): int64 {.tags: [WriteDbEffect].} =
  ## Executes the query (typically "INSERT") and returns the
  ## generated ID for the row.
  ##
  ## Raises a `DbError` exception when failed to insert row.
  ## For Postgre this adds `RETURNING id` to the query, so it only works
  ## if your primary key is named `id`.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##    db.exec(sql"CREATE TABLE my_table (id INTEGER, name VARCHAR(50) NOT NULL)")
  ##
  ##    for i in 0..2:
  ##      let id = db.insertID(sql"INSERT INTO my_table (id, name) VALUES (?, ?)", i, "item#" & $i)
  ##      echo "LoopIndex = ", i, ", InsertID = ", id
  ##
  ##    # Output:
  ##    # LoopIndex = 0, InsertID = 1
  ##    # LoopIndex = 1, InsertID = 2
  ##    # LoopIndex = 2, InsertID = 3
  ##
  ##    db.close()
  result = tryInsertID(db, query, args)
  if result < 0: dbError(db)

proc tryInsert*(db: DbConn, query: SqlQuery, pkName: string,
                args: varargs[string, `$`]): int64
               {.tags: [WriteDbEffect], raises: [DbError], since: (1, 3).} =
  ## same as tryInsertID
  tryInsertID(db, query, args)

proc insert*(db: DbConn, query: SqlQuery, pkName: string,
             args: varargs[string, `$`]): int64
            {.tags: [WriteDbEffect], since: (1, 3).} =
  ## same as insertId
  result = tryInsert(db, query,pkName, args)
  if result < 0: dbError(db)

proc execAffectedRows*(db: DbConn, query: SqlQuery,
                       args: varargs[string, `$`]): int64 {.
                       tags: [ReadDbEffect, WriteDbEffect].} =
  ## Executes the query (typically "UPDATE") and returns the
  ## number of affected rows.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##
  ##    # Records of my_table:
  ##    # | id | name     |
  ##    # |----|----------|
  ##    # |  1 | item#1   |
  ##    # |  2 | item#2   |
  ##
  ##    doAssert db.execAffectedRows(sql"UPDATE my_table SET name = 'TEST'") == 2
  ##
  ##    db.close()
  exec(db, query, args)
  result = changes(db)

proc execAffectedRows*(db: DbConn, stmtName: SqlPrepared): int64
                      {.tags: [ReadDbEffect, WriteDbEffect],since: (1, 3).} =
  exec(db, stmtName)
  result = changes(db)

proc close*(db: DbConn) {.tags: [DbEffect].} =
  ## Closes the database connection.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    let db = open("mytest.db", "", "", "")
  ##    db.close()
  if sqlite3.close(db) != SQLITE_OK: dbError(db)

proc open*(connection, user, password, database: string): DbConn {.
  tags: [DbEffect].} =
  ## Opens a database connection. Raises a `DbError` exception if the connection
  ## could not be established.
  ##
  ## **Note:** Only the `connection` parameter is used for `sqlite`.
  ##
  ## **Examples:**
  ##
  ## .. code-block:: Nim
  ##
  ##    try:
  ##      let db = open("mytest.db", "", "", "")
  ##      ## do something...
  ##      ## db.getAllRows(sql"SELECT * FROM my_table")
  ##      db.close()
  ##    except:
  ##      stderr.writeLine(getCurrentExceptionMsg())
  var db: DbConn
  if sqlite3.open(connection, db) == SQLITE_OK:
    result = db
  else:
    dbError(db)

proc setEncoding*(connection: DbConn, encoding: string): bool {.
  tags: [DbEffect].} =
  ## Sets the encoding of a database connection, returns `true` for
  ## success, `false` for failure.
  ##
  ## **Note:** The encoding cannot be changed once it's been set.
  ## According to SQLite3 documentation, any attempt to change
  ## the encoding after the database is created will be silently
  ## ignored.
  exec(connection, sql"PRAGMA encoding = ?", [encoding])
  result = connection.getValue(sql"PRAGMA encoding") == encoding

proc finalize*(sqlPrepared:SqlPrepared) {.discardable, since: (1, 3).} =
  discard finalize(sqlPrepared.PStmt)

template dbBindParamError*(paramIdx: int, val: varargs[untyped]) =
  ## Raises a `DbError` exception.
  var e: ref DbError
  new(e)
  e.msg = "error binding param in position " & $paramIdx
  raise e

proc bindParam*(ps: SqlPrepared, paramIdx: int, val: int32) {.since: (1, 3).} =
  ## Binds a int32  to the specified paramIndex.
  if bind_int(ps.PStmt, paramIdx.int32, val) != SQLITE_OK:
    dbBindParamError(paramIdx, val)

proc bindParam*(ps: SqlPrepared, paramIdx: int, val: int64) {.since: (1, 3).} =
  ## Binds a int64  to the specified paramIndex.
  if bind_int64(ps.PStmt, paramIdx.int32, val) != SQLITE_OK:
    dbBindParamError(paramIdx, val)

proc bindParam*(ps: SqlPrepared, paramIdx: int, val: int) {.since: (1, 3).} =
  ## Binds a int  to the specified paramIndex.
  when sizeof(int) == 8:
    bindParam(ps, paramIdx, val.int64)
  else:
    bindParam(ps, paramIdx, val.int32)

proc bindParam*(ps: SqlPrepared, paramIdx: int, val: float64) {.since: (1, 3).} =
  ## Binds a 64bit float to the specified paramIndex.
  if bind_double(ps.PStmt, paramIdx.int32, val) != SQLITE_OK:
    dbBindParamError(paramIdx, val)

proc bindNull*(ps: SqlPrepared, paramIdx: int) {.since: (1, 3).} =
  ## Sets the bindparam at the specified paramIndex to null
  ## (default behaviour by sqlite).
  if bind_null(ps.PStmt, paramIdx.int32) != SQLITE_OK:
    dbBindParamError(paramIdx)

proc bindParam*(ps: SqlPrepared, paramIdx: int, val: string, copy = true) {.since: (1, 3).} =
  ## Binds a string to the specified paramIndex.
  ## if copy is true then SQLite makes its own private copy of the data immediately
  if bind_text(ps.PStmt, paramIdx.int32, val.cstring, val.len.int32, if copy: SQLITE_TRANSIENT else: SQLITE_STATIC) != SQLITE_OK:
    dbBindParamError(paramIdx, val)

proc bindParam*(ps: SqlPrepared, paramIdx: int,val: openArray[byte], copy = true) {.since: (1, 3).} =
  ## binds a blob to the specified paramIndex.
  ## if copy is true then SQLite makes its own private copy of the data immediately
  let len = val.len
  if bind_blob(ps.PStmt, paramIdx.int32, val[0].unsafeAddr, len.int32, if copy: SQLITE_TRANSIENT else: SQLITE_STATIC) != SQLITE_OK:
    dbBindParamError(paramIdx, val)

macro bindParams*(ps: SqlPrepared, params: varargs[untyped]): untyped {.since: (1, 3).} =
  let bindParam = bindSym("bindParam", brOpen)
  let bindNull = bindSym("bindNull")
  let preparedStatement = genSym()
  result = newStmtList()
  # Store `ps` in a temporary variable. This prevents `ps` from being evaluated every call.
  result.add newNimNode(nnkLetSection).add(newIdentDefs(preparedStatement, newEmptyNode(), ps))
  for idx, param in params:
    if param.kind != nnkNilLit:
      result.add newCall(bindParam, preparedStatement, newIntLitNode idx + 1, param)
    else:
      result.add newCall(bindNull, preparedStatement, newIntLitNode idx + 1)

macro untypedLen(args: varargs[untyped]): int =
  newLit(args.len)

template exec*(db: DbConn, stmtName: SqlPrepared,
          args: varargs[typed]): untyped =
  when untypedLen(args) > 0:
    if reset(stmtName.PStmt) != SQLITE_OK:
      dbError(db)
    if clear_bindings(stmtName.PStmt) != SQLITE_OK:
      dbError(db)
    stmtName.bindParams(args)
  if not tryExec(db, stmtName): dbError(db)

when not defined(testing) and isMainModule:
  var db = open(":memory:", "", "", "")
  exec(db, sql"create table tbl1(one varchar(10), two smallint)", [])
  exec(db, sql"insert into tbl1 values('hello!',10)", [])
  exec(db, sql"insert into tbl1 values('goodbye', 20)", [])
  var p1 = db.prepare "create table tbl2(one varchar(10), two smallint)"
  exec(db, p1)
  finalize(p1)
  var p2 = db.prepare "insert into tbl2 values('hello!',10)"
  exec(db, p2)
  finalize(p2)
  var p3 = db.prepare "insert into tbl2 values('goodbye', 20)"
  exec(db, p3)
  finalize(p3)
  #db.query("create table tbl1(one varchar(10), two smallint)")
  #db.query("insert into tbl1 values('hello!',10)")
  #db.query("insert into tbl1 values('goodbye', 20)")
  for r in db.rows(sql"select * from tbl1", []):
    echo(r[0], r[1])
  for r in db.instantRows(sql"select * from tbl1", []):
    echo(r[0], r[1])
  var p4 =  db.prepare "select * from tbl2"
  for r in db.rows(p4):
    echo(r[0], r[1])
  finalize(p4)
  var i5 = 0
  var p5 =  db.prepare "select * from tbl2"
  for r in db.instantRows(p5):
    inc i5
    echo(r[0], r[1])
  assert i5 == 2
  finalize(p5)

  for r in db.rows(sql"select * from tbl2", []):
    echo(r[0], r[1])
  for r in db.instantRows(sql"select * from tbl2", []):
    echo(r[0], r[1])
  var p6 = db.prepare "select * from tbl2 where one = ? "
  p6.bindParams("goodbye")
  var rowsP3 = 0
  for r in db.rows(p6):
    rowsP3 = 1
    echo(r[0], r[1])
  assert rowsP3 == 1
  finalize(p6)

  var p7 = db.prepare "select * from tbl2 where two=?"
  p7.bindParams(20'i32)
  when sizeof(int) == 4:
    p7.bindParams(20)
  var rowsP = 0
  for r in db.rows(p7):
    rowsP = 1
    echo(r[0], r[1])
  assert rowsP == 1
  finalize(p7)

  exec(db, sql"CREATE TABLE photos(ID INTEGER PRIMARY KEY AUTOINCREMENT, photo BLOB)")
  var p8 = db.prepare "INSERT INTO photos (ID,PHOTO) VALUES (?,?)"
  var d = "abcdefghijklmnopqrstuvwxyz"
  p8.bindParams(1'i32, "abcdefghijklmnopqrstuvwxyz")
  exec(db, p8)
  finalize(p8)
  var p10 = db.prepare "INSERT INTO photos (ID,PHOTO) VALUES (?,?)"
  p10.bindParams(2'i32,nil)
  exec(db, p10)
  exec( db, p10, 3, nil)
  finalize(p10)
  for r in db.rows(sql"select * from photos where ID = 1", []):
    assert r[1].len == d.len
    assert r[1] == d
  var i6 = 0
  for r in db.rows(sql"select * from photos where ID = 3", []):
    i6 = 1
  assert i6 == 1
  var p9 = db.prepare("select * from photos where PHOTO is ?")
  p9.bindParams(nil)
  var rowsP2 = 0
  for r in db.rows(p9):
    rowsP2 = 1
    echo(r[0], repr r[1])
  assert rowsP2 == 1
  finalize(p9)

  db_sqlite.close(db)
