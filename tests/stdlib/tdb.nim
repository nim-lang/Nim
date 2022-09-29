discard """
  action: "compile"
"""


import db_mysql, db_odbc, db_postgres
import os
from stdtest/specialpaths import buildDir


block:
  block:
    const dbName = buildDir / "db.sqlite3"
    var db = db_mysql.open(dbName, "", "", "")
    discard tryInsertId(db, sql"INSERT INTO myTestTbl (name,i,f) VALUES (?,?,?)", "t")

  block:
    const dbName = buildDir / "db.odbc"
    var db = db_odbc.open(dbName, "", "", "")
    discard tryInsertId(db, sql"INSERT INTO myTestTbl (name,i,f) VALUES (?,?,?)", "t")

  block:
    const dbName = buildDir / "db.postgres"
    var db = db_postgres.open(dbName, "", "", "")
    discard tryInsertId(db, sql"INSERT INTO myTestTbl (name,i,f) VALUES (?,?,?)", "t")
