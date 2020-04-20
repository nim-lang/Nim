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
## All ``db_*`` modules support the same form of parameter substitution.
## That is, using the ``?`` (question mark) to signify the place where a
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
##    import db_sqlite
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
##    import db_sqlite, math
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
##
## Note
## ====
## This module does not implement any ORM features such as mapping the types from the schema.
## Instead, a ``seq[string]`` is returned for each row.
##
## The reasoning is as follows:
## 1. it's close to what many DBs offer natively (char**)
## 2. it hides the number of types that the DB supports
## (int? int64? decimal up to 10 places? geo coords?)
## 3. it's convenient when all you do is to forward the data to somewhere else (echo, log, put the data into a new query)
##
## See also
## ========
##
## * `db_odbc module <db_odbc.html>`_ for ODBC database wrapper
## * `db_mysql module <db_mysql.html>`_ for MySQL database wrapper
## * `db_postgres module <db_postgres.html>`_ for PostgreSQL database wrapper

import sqlite3

import db_common
export db_common

type
  DbConn* = PSqlite3  ## Encapsulates a database connection.
  Row* = seq[string]  ## A row of a dataset. `NULL` database values will be
                      ## converted to an empty string.
  InstantRow* = PStmt ## A handle that can be used to get a row's column
                      ## text on demand.

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
  result = ""
  var a = 0
  for c in items(string(formatstr)):
    if c == '?':
      add(result, dbQuote(args[a]))
      inc(a)
    else:
      add(result, c)

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

proc setRow(stmt: PStmt, r: var Row, cols: cint) =
  for col in 0'i32..cols-1:
    setLen(r[col], column_bytes(stmt, col)) # set capacity
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
  ## next database query to raise a `DbError` exception ``unable to close due
  ## to ...``.
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
      result = newStringOfCap(cb)
      add(result, column_text(stmt, 0))
  else:
    result = ""
  if finalize(stmt) != SQLITE_OK: dbError(db)

proc tryInsertID*(db: DbConn, query: SqlQuery,
                  args: varargs[string, `$`]): int64
                  {.tags: [WriteDbEffect], raises: [].} =
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
  ## For Postgre this adds ``RETURNING id`` to the query, so it only works
  ## if your primary key is named ``id``.
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
  ## **Note:** Only the ``connection`` parameter is used for ``sqlite``.
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

when not defined(testing) and isMainModule:
  var db = open("db.sql", "", "", "")
  exec(db, sql"create table tbl1(one varchar(10), two smallint)", [])
  exec(db, sql"insert into tbl1 values('hello!',10)", [])
  exec(db, sql"insert into tbl1 values('goodbye', 20)", [])
  #db.query("create table tbl1(one varchar(10), two smallint)")
  #db.query("insert into tbl1 values('hello!',10)")
  #db.query("insert into tbl1 values('goodbye', 20)")
  for r in db.rows(sql"select * from tbl1", []):
    echo(r[0], r[1])
  for r in db.instantRows(sql"select * from tbl1", []):
    echo(r[0], r[1])

  db_sqlite.close(db)
