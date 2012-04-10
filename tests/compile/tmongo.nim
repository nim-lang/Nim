
import mongo, db_mongo, oids, json

var conn = db_mongo.open()

var data = %{"a": %13, "b": %"my string value", 
             "inner": %{"i": %71} }

var id = insertID(conn, "test.test", data)

for v in find(conn, "test.test", "this.a == 13"):
  print v

delete(conn, "test.test", id)

close(conn)
