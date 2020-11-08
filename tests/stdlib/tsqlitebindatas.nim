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
