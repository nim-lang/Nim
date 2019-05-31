discard """
action: compile
"""

import db_sqlite

var db: DbConn
exec(db, sql"create table blabla()")
