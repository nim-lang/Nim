## DB is a single wrapper around three wrappers: db_sqlite, db_mysql  and db_postgres
##
## This module aims to simplify writing code to access multiple types of databases.
##
## Example:
##
## .. code-block:: nim
##
##  import db, math
##
##  var theDb: DbConnId             # this id uniquely identifies this database session
##
##  when defined(sqlite):           # configure the database type to connect to
##    theDb = initDb(DbKind.Sqlite)
##  elif defined(mysql):
##    theDb = initDb(DbKind.Mysql)
##  elif defined(postgres):
##    theDb = initDb(DbKind.Postgres)
##  else:
##    {.fatal: "DEFINE one of: sqlite mysql postgres  eg, -d:sqlite ".}
##
##  theDb.open("localhost", "nim", "nim", "test")   # actual db connection made here!
##
##  theDb.exec(sql"Drop table if exists myTestTbl")
##  let mquery = sql"""create table myTestTbl (
##        Id    INT(11)     NOT NULL AUTO_INCREMENT PRIMARY KEY,
##        Name  VARCHAR(50) NOT NULL,
##        i     INT(11),
##        f     DECIMAL(18,10))"""
##  let squery = sql"""create table myTestTbl (
##        Id    INTEGER     PRIMARY KEY,
##        Name  VARCHAR(50) NOT NULL,
##        i     INT(11),
##        f     DECIMAL(18,10))"""
##  let pquery = sql"""create table myTestTbl (
##        Id    SERIAL PRIMARY KEY,
##        Name  VARCHAR(50) NOT NULL,
##        i     int,
##        f     NUMERIC(18,10))"""
##
##  when defined(sqlite):           # create the table myTestTbl
##    theDb.exec(squery)
##  elif defined(mysql):
##    theDb.exec(mquery)
##  else:
##    theDb.exec(pquery)
##
##  when not defined(sqlite):       # wrap multi inserts in a transaction to improved performance
##  theDb.exec(sql"START TRANSACTION")   # both mysql & postgres
##  else:
##    theDb.exec(sql"BEGIN")   # sqlite only
##
##  for i in 1..1000:               # do 1000 inserts
##    theDb.exec(sql"INSERT INTO myTestTbl (name,i,f) VALUES (?,?,?)",
##          "Item#" & $i, i, sqrt(i.float))
##  theDb.exec(sql"COMMIT")
##
##  for x in theDb.instantRows(sql"select * from myTestTbl"):   # show what has been inserted
##    echo x.row
##
##  let id = theDb.tryInsertId(sql"INSERT INTO myTestTbl (name,i,f) VALUES (?,?,?)",
##               "Item#1001", 1001, sqrt(1001.0))
##  echo "Inserted item: ", theDb.getValue(sql"SELECT name FROM myTestTbl WHERE id=?", id)
##
##  theDb.close()   # bye  -> note theDb is now no longer valid
##
##
## Compile the code including one of  ``-d:sqlite`` ``-d:mysql`` ``-d:postgres``
##
## to run the code against the different databases.
##
## The above example is with mutually exclusive database access.
## This is not a limitation of the module, but is how the example is written.
import db_sqlite, db_mysql, db_postgres, oids

type
  DbKind* = enum   ## define which database (and module) to use
    DbNone, Sqlite, Mysql, Postgres

  DbConnId* = Oid  ## a unique identifier for interfacing to this module
  DbDataObj = tuple[kind: DbKind, id: Oid, db: pointer]
  Row* = seq[string]  ## a row of a dataset. NULL database values will be
                      ## transformed always to the empty string.
  InstantRow* = tuple[row: seq[string], len: int] ## a handle that
                      ## can be used to get a row's column text on demand
  SqlQuery* = distinct string   ## an SQL query string
  EDb* = object of IOError  ## exception that is raised if a
                            ## database error occurs

  DbObj = object of RootObj  ## A collection of Db interfaces (independant of db type)
    len: int
    dbInfo: seq[DbDataObj]

proc initDb*(knd: DbKind): DbConnId  # fwd declaration
  ## Initiate the generation of a unique identifier for subsequent
  ## calls to this module.
  ##
  ## Returns a unique connection identifier.
  ##
  ## Note: the actual database connection is made when `open()` is called.

var
  theDbObj: DbObj = DbObj(len: 0, dbInfo: @[])  # internal db tracking collection

proc initDb(knd: DbKind): DbConnId =
  result = genOid()
  theDbObj.dbInfo.add((kind: knd, id: result, db: nil))
  inc(theDbObj.len)

proc dbError*(msg: string) {.noreturn.} =
  ## Raises an EDb exception with message `msg`.
  var e: ref EDb
  new(e)
  e.msg = msg
  raise e

proc getDbId(o: DbConnId): int =
  result = -1
  for i in 0..<theDbObj.len:
    if theDbObj.dbInfo[i].id == o: return i

proc sql*(query: string): SqlQuery {.noSideEffect, inline, raises: [], tags: [].} =
  ## Constructs an SqlQuery from the string `query`.
  ## This is supposed to be used as a raw-string-literal modifier:
  ## ``sql"update user set counter = counter + 1"``
  ##
  ## If assertions are turned off, it does nothing. If assertions are turned on,
  ## later versions will check the string for valid syntax.
  result = SqlQuery(db_mysql.sql(query))

proc dbQuote*(s: string): string {.raises: [], tags: [].} =
  ## DB quotes the string.
  result = db_mysql.dbQuote(s)

template doEachCmdResNoErr(cmd: expr, dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]): stmt =
  let db = dbId.getDbId()
  case theDbObj.dbInfo[db].kind:
    of Sqlite:
      let dbConn = cast[db_sqlite.DbConn](theDbObj.dbInfo[db].db)
      result = db_sqlite.`cmd`(dbConn, db_sqlite.SqlQuery(query), args)
    of Mysql:
      let dbConn = cast[db_mysql.DbConn](theDbObj.dbInfo[db].db)
      result = db_mysql.`cmd`(dbConn, db_mysql.SqlQuery(query), args)
    of Postgres:
      let dbConn = cast[db_postgres.DbConn](theDbObj.dbInfo[db].db)
      result = db_postgres.`cmd`(dbConn, db_postgres.SqlQuery(query), args)
    else: discard

template doEachCmdResErr(cmd: expr, dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]): stmt =
  let db = dbId.getDbId()
  case theDbObj.dbInfo[db].kind:
    of Sqlite:
      let dbConn = cast[db_sqlite.DbConn](theDbObj.dbInfo[db].db)
      result = db_sqlite.`cmd`(dbConn, db_sqlite.SqlQuery(query), args)
    of Mysql:
      let dbConn = cast[db_mysql.DbConn](theDbObj.dbInfo[db].db)
      result = db_mysql.`cmd`(dbConn, db_mysql.SqlQuery(query), args)
    of Postgres:
      let dbConn = cast[db_postgres.DbConn](theDbObj.dbInfo[db].db)
      result = db_postgres.`cmd`(dbConn, db_postgres.SqlQuery(query), args)
    else: dbError("Error: unknown Db type")

template doEachCmdNoResErr(cmd: expr, dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]): stmt =
  let db = dbId.getDbId()
  case theDbObj.dbInfo[db].kind:
    of Sqlite:
      let dbConn = cast[db_sqlite.DbConn](theDbObj.dbInfo[db].db)
      db_sqlite.`cmd`(dbConn, db_sqlite.SqlQuery(query), args)
    of Mysql:
      let dbConn = cast[db_mysql.DbConn](theDbObj.dbInfo[db].db)
      db_mysql.`cmd`(dbConn, db_mysql.SqlQuery(query), args)
    of Postgres:
      let dbConn = cast[db_postgres.DbConn](theDbObj.dbInfo[db].db)
      db_postgres.`cmd`(dbConn, db_postgres.SqlQuery(query), args)
    else: dbError("Error: unknown Db type")

template doEachCmdNoResNoErr(cmd: expr, dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]): stmt =
  let db = dbId.getDbId()
  case theDbObj.dbInfo[db].kind:
    of Sqlite:
      let dbConn = cast[db_sqlite.DbConn](theDbObj.dbInfo[db].db)
      db_sqlite.`cmd`(dbConn, db_sqlite.SqlQuery(query), args)
    of Mysql:
      let dbConn = cast[db_mysql.DbConn](theDbObj.dbInfo[db].db)
      db_mysql.`cmd`(dbConn, db_mysql.SqlQuery(query), args)
    of Postgres:
      let dbConn = cast[db_postgres.DbConn](theDbObj.dbInfo[db].db)
      db_postgres.`cmd`(dbConn, db_postgres.SqlQuery(query), args)
    else: discard

proc tryExec*(dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]): bool {.
    tags: [db_sqlite.FReadDb, db_mysql.FReadDb, db_postgres.FReadDb,
      db_sqlite.FWriteDb, db_mysql.FWriteDb, db_postgres.FWriteDb],
    raises: [db_postgres.EDb].} =
  ## Tries to execute the query and returns true if successful, false otherwise.
  result = false
  doEachCmdResNoErr(tryExec, dbId, query, args)

proc exec*(dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]) {.
    tags: [db_sqlite.FReadDb, db_mysql.FReadDb, db_postgres.FReadDb,
      db_sqlite.FWriteDb, db_mysql.FWriteDb, db_postgres.FWriteDb],
    raises: [db_sqlite.EDb, db_mysql.EDb, db_postgres.EDb, EDb].} =
  ## Executes the query and raises EDB if not successful.
  doEachCmdNoResErr(exec, dbId, query, args)

proc getRow*(dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]): Row {.
    tags: [db_sqlite.FReadDb, db_mysql.FReadDb, db_postgres.FReadDb],
    raises: [db_sqlite.EDb, db_mysql.EDb, db_postgres.EDb, EDb].} =
  ## Retrieves a single row. If the query doesn't return any rows,
  ## this proc will return a Row with empty strings for each column.
  doEachCmdResErr(getRow, dbId, query, args)

proc getAllRows*(dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]): seq[Row] {.
    tags: [db_sqlite.FReadDb, db_mysql.FReadDb, db_postgres.FReadDb],
    raises: [db_sqlite.EDb, db_mysql.EDb, db_postgres.EDb, EDb].} =
  ## Executes the query and returns the whole result dataset.
  doEachCmdResErr(getAllRows, dbId, query, args)

proc getValue*(dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]): string {.
    tags: [db_sqlite.FReadDb, db_mysql.FReadDb, db_postgres.FReadDb],
    raises: [db_sqlite.EDb, db_mysql.EDb, db_postgres.EDb, EDb].} =
  ## Executes the query and returns the first column of the first row of the result dataset.
  ## Returns "" if the dataset contains no rows or the database value is NULL.
  doEachCmdResErr(getValue, dbId, query, args)

proc tryInsertId*(dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]): int64 {.
    tags: [db_sqlite.FWriteDb, db_mysql.FWriteDb, db_postgres.FWriteDb],
    raises: [db_postgres.EDb, ValueError].} =
  ## Executes the query (typically "INSERT") and returns the generated ID for the
  ## row, or -1 in case of an error.
  doEachCmdResNoErr(tryInsertId, dbId, query, args)

proc insertId*(dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]): int64 {.
    tags: [db_sqlite.FWriteDb, db_mysql.FWriteDb, db_postgres.FWriteDb],
    raises: [db_postgres.EDb, EDb, ValueError].} =
  ## Executes the query (typically "INSERT") and returns the generated ID for the row.
  doEachCmdResErr(tryInsertId, dbId, query, args)

proc execAffectedRows*(dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]): int64 {.
    tags: [db_sqlite.FReadDb, db_mysql.FReadDb, db_postgres.FReadDb,
      db_sqlite.FWriteDb, db_mysql.FWriteDb, db_postgres.FWriteDb],
    raises: [db_sqlite.EDb, db_mysql.EDb, db_postgres.EDb, EDb, ValueError].} =
  ## Runs the query (typically "UPDATE") and returns the number of affected rows.
  doEachCmdResErr(execAffectedRows, dbId, query, args)

proc open*(dbId: DbConnId, connection, user, password, database: string) {.tags: [db_sqlite.FDb,
    db_mysql.FDb, db_postgres.FDb], raises: [db_sqlite.EDb, db_mysql.EDb, db_postgres.EDb, EDb,
    OverflowError, ValueError].} =
  ## Opens a database connection. Raises EDb if the connection could not be established.
  let db = dbId.getDbId()
  case theDbObj.dbInfo[db].kind:
    of Sqlite:
      theDbObj.dbInfo[db].db = cast[pointer](db_sqlite.open(connection, user, password, database))
    of Mysql:
      theDbObj.dbInfo[db].db = cast[pointer](db_mysql.open(connection, user, password, database))
    of Postgres:
      theDbObj.dbInfo[db].db = cast[pointer](db_postgres.open(connection, user, password, database))
    else: dbError("Error: unknown Db type")

proc close*(dbId: DbConnId) {.
      tags: [db_sqlite.FDb, db_mysql.FDb, db_postgres.FDb], raises: [db_sqlite.EDb].} =
  ## Closes the database connection.
  let db = dbId.getDbId()
  case theDbObj.dbInfo[db].kind:
    of Sqlite:
      let dbConn = cast[db_sqlite.DbConn](theDbObj.dbInfo[db].db)
      db_sqlite.close(dbConn)
      theDbObj.dbInfo.delete(db)
      dec(theDbObj.len)
    of Mysql:
      let dbConn = cast[db_mysql.DbConn](theDbObj.dbInfo[db].db)
      db_mysql.close(dbConn)
      theDbObj.dbInfo.delete(db)
      dec(theDbObj.len)
    of Postgres:
      let dbConn = cast[db_postgres.DbConn](theDbObj.dbInfo[db].db)
      db_postgres.close(dbConn)
      theDbObj.dbInfo.delete(db)
      dec(theDbObj.len)
    else: discard

proc setEncoding*(dbId: DbConnId; encoding: string): bool {.
    tags: [db_sqlite.FDb, db_mysql.FDb, db_postgres.FDb], raises: [db_sqlite.EDb].} =
  ## Sets the encoding of a database connection, returns true for success, false for failure.
  let db = dbId.getDbId()
  case theDbObj.dbInfo[db].kind:
    of Sqlite:
      let dbConn = cast[db_sqlite.DbConn](theDbObj.dbInfo[db].db)
      result = db_sqlite.setEncoding(dbConn, encoding)
    of Mysql:
      let dbConn = cast[db_mysql.DbConn](theDbObj.dbInfo[db].db)
      result = db_mysql.setEncoding(dbConn, encoding)
    of Postgres:
      let dbConn = cast[db_postgres.DbConn](theDbObj.dbInfo[db].db)
      result = db_postgres.setEncoding(dbConn, encoding)
    else: result = false

#let dbConn = cast[db_sqlite.DbConn](theDbObj.dbInfo[db].db)
#for r in db_sqlite.fastRows(dbConn, db_sqlite.SqlQuery(query), args):
#  yield r
template fastRowsIterate(conn, cmd, sqCmd: expr, db: int, query: SqlQuery, args: varargs[string, `$`]): stmt =
  let dbConn = cast[`conn`](theDbObj.dbInfo[db].db)
  for r in `cmd`(dbConn, `sqCmd`(query), args):
    yield r

iterator fastRows*(dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]): Row {.
    tags: [db_sqlite.FReadDb, db_mysql.FReadDb, db_postgres.FReadDb],
    raises: [db_sqlite.EDb, db_mysql.EDb, db_postgres.EDb, EDb].} =
  ## Executes the query and iterates over the result dataset.
  ##
  ## This is very fast, but potentially dangerous. Use this iterator only if you require ``ALL`` the rows.
  ##
  ## Breaking the `fastRows()` iterator during a loop will cause the next database query to raise
  ## an [EDb] exception
  ## ``Commands out of sync``.
  let db = dbId.getDbId()
  case theDbObj.dbInfo[db].kind:
    of Sqlite:
      fastRowsIterate(db_sqlite.DbConn, db_sqlite.fastRows, db_sqlite.SqlQuery, db, query, args)
    of Mysql:
      fastRowsIterate(db_mysql.DbConn, db_mysql.fastRows, db_mysql.SqlQuery, db, query, args)
    of Postgres:
      fastRowsIterate(db_postgres.DbConn, db_postgres.fastRows, db_postgres.SqlQuery, db, query, args)
    else: dbError("Error: unknown Db type")

#let dbConn = cast[db_sqlite.DbConn](theDbObj.dbInfo[db].db)
#for r in db_sqlite.instantRows(dbConn, db_sqlite.SqlQuery(query), args):
#  instR.row.setlen(r.len)
#  for i in 0..<r.len:
#    instR.row[i] = db_sqlite.`[]`(r, i.int32)
#  instR.len = r.len
#  yield instR
template instantRowsIterate(conn, cmd, sqCmd, brktCmd: expr, db: int, query: SqlQuery, args: varargs[string, `$`]): stmt =
  let dbConn = cast[`conn`](theDbObj.dbInfo[db].db)
  for r in `cmd`(dbConn, sqCmd(query), args):
    instR.row.setlen(r.len)
    for i in 0..<r.len:
      instR.row[i] = `brktCmd`(r, i.int32)
    instR.len = r.len
    yield instR

iterator instantRows*(dbId: DbConnId; query: SqlQuery; args: varargs[string, `$`]): InstantRow {.
    tags: [db_sqlite.FReadDb, db_mysql.FReadDb, db_postgres.FReadDb],
    raises: [db_sqlite.EDb, db_mysql.EDb, db_postgres.EDb, EDb].} =
  ## Same as fastRows but returns a handle that can be used to get column text on demand using [].
  ## Returned handle is valid only within the interator body.
  let db = dbId.getDbId()
  var instR: InstantRow
  instR.row = newSeq[string](64)
  case theDbObj.dbInfo[db].kind:
    of Sqlite:
      instantRowsIterate(db_sqlite.DbConn, db_sqlite.instantRows, db_sqlite.SqlQuery, db_sqlite.`[]`,
            db, query, args)
    of Mysql:
      instantRowsIterate(db_mysql.DbConn, db_mysql.instantRows, db_mysql.SqlQuery, db_mysql.`[]`,
            db, query, args)
    of Postgres:
      instantRowsIterate(db_postgres.DbConn, db_postgres.instantRows, db_postgres.SqlQuery, db_postgres.`[]`,
            db, query, args)
    else: dbError("Error: unknown Db type")

proc `[]`*(row: InstantRow; col: int): string {.inline, raises: [], tags: [].} =
  ## Returns the text for a given column of the row
  result = row.row[col]

proc len*(row: InstantRow): int {.inline, raises: [], tags: [].} =
  ## Returns the number of columns in the row
  result = row.len
