discard """
  file: "tnoargopenarray.nim"
"""

import db_sqlite

var db: TDbConn
exec(db, sql"create table blabla()")
