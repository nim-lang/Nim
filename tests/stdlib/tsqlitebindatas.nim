discard """
  action: "run"
  exitcode: 0
"""
import db_sqlite
import random
import os
from stdtest/specialpaths import buildDir

block tsqlitebindatas: ## db_sqlite binary data
  const dbName = buildDir / "tsqlitebindatas.db"

  let origName = "Bobby"
  var orig = newSeq[float64](150)
  randomize()
  for x in orig.mitems:
    x = rand(1.0)/10.0

  discard tryRemoveFile(dbName)
  let db = open(dbName, "", "", "")
  let createTableStr = sql"""CREATE TABLE test(
    id INTEGER NOT NULL PRIMARY KEY,
    name TEXT,
    data BLOB
  )
  """
  db.exec(createTableStr)

  var dbuf = newSeq[byte](orig.len*sizeof(float64))
  copyMem(unsafeAddr(dbuf[0]), unsafeAddr(orig[0]), dbuf.len)

  var insertStmt = db.prepare("INSERT INTO test (id, name, data) VALUES (?, ?, ?)")
  insertStmt.bindParams(1, origName, dbuf)
  let bres = db.tryExec(insertStmt)
  doAssert(bres)

  finalize(insertStmt)

  var nameTest = db.getValue(sql"SELECT name FROM test WHERE id = ?", 1)
  doAssert nameTest == origName

  var dataTest = db.getValue(sql"SELECT data FROM test WHERE id = ?", 1)
  let seqSize = int(dataTest.len*sizeof(byte)/sizeof(float64))
  var res: seq[float64] = newSeq[float64](seqSize)
  copyMem(unsafeAddr(res[0]), addr(dataTest[0]), dataTest.len)
  doAssert res.len == orig.len
  doAssert res == orig

  db.close()
  doAssert tryRemoveFile(dbName)


block:
  block:
    const dbName = buildDir / "db.sqlite3"
    var db = db_sqlite.open(dbName, "", "", "")
    var witness = false
    try:
      db.exec(sql("CREATE TABLE table1 (url TEXT, other_field INT);"))
      db.exec(sql("REPLACE INTO table (url, another_field) VALUES (?, '123');"))
    except DbError as e:
      witness = true
      doAssert e.msg == "The number of \"?\" given exceeds the number of parameters present in the query."
    finally:
      db.close()
      removeFile(dbName)

    doAssert witness

  block:
    const dbName = buildDir / "db.sqlite3"
    var db = db_sqlite.open(dbName, "", "", "")
    try:
      db.exec(sql("CREATE TABLE table1 (url TEXT, other_field INT);"))
      db.exec(sql("INSERT INTO table1 (url, other_field) VALUES (?, ?);"), "http://domain.com/test?param=1", 123)
    finally:
      db.close()
      removeFile(dbName)
