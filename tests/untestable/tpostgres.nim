import db_postgres, strutils


let db = open("localhost", "dom", "", "test")
db.exec(sql"DROP TABLE IF EXISTS myTable")
db.exec(sql("""CREATE TABLE myTable (
                  id integer PRIMARY KEY,
                  name varchar(50) not null)"""))
let name = "Dom"
db.exec(sql"INSERT INTO myTable (id, name) VALUES (0, ?)",
        name)
doAssert db.getValue(sql"SELECT name FROM myTable") == name
# Check issue #3513
doAssert db.getValue(sql"SELECT name FROM myTable") == name


# issue #3560
proc addToDb(conn: DbConn, fileId: int, fileName: string): int64 =
  result = conn.insertId(sql("INSERT into files (id, filename) VALUES (?, ?)"), fileId, fileName)

db.exec(sql"DROP TABLE IF EXISTS files")
db.exec(sql"DROP TABLE IF EXISTS fileobjects")
db.exec(sql("""CREATE TABLE FILEOBJECTS(
               ID             SERIAL PRIMARY KEY,
               FILE_SIZE      INT,
               MD5            CHAR(32)  NOT NULL UNIQUE
            );"""))

db.exec(sql("""CREATE TABLE FILES(
               ID                  SERIAL PRIMARY KEY,
               OBJECT_ID           INT,
               FILENAME            TEXT NOT NULL,
               URI                 TEXT,
               SCHEME              CHAR(10),
               PUBLIC              BOOLEAN DEFAULT FALSE,
               CONSTRAINT fk1_fileobjs FOREIGN KEY (object_id)
               REFERENCES fileobjects (id) MATCH SIMPLE
               ON DELETE CASCADE
            );"""))

let f1 = db.addToDb(1, "hello.tmp")
doAssert f1 == 1
let f2 = db.addToDb(2, "hello2.tmp")
doAssert f2 == 2

# PreparedStmt vs. normal query
try:
  echo db.getValue(sql("select * from files where id = $1"), 1)
  doAssert false, "Exception expected"
except DbError:
  let msg = getCurrentExceptionMsg().normalize
  doAssert "expects" in msg
  doAssert "?" in msg
  doAssert "parameter substitution" in msg

doAssert db.getValue(sql("select filename from files where id = ?"), 1) == "hello.tmp"

var first = prepare(db, "one", sql"select filename from files where id = $1", 1)
doAssert db.getValue(first, 1) == "hello.tmp"

try:
  var second = prepare(db, "two", sql"select filename from files where id = ?", 1)
  doAssert false, "Exception expected"
except:
  let msg = getCurrentExceptionMsg().normalize
  doAssert "expects" in msg
  doAssert "$1" in msg
  doAssert "parameter substitution" in msg

# issue #3569
db.exec(SqlQuery("DROP TABLE IF EXISTS tags"))
db.exec(SqlQuery("CREATE TABLE tags(id serial UNIQUE, name varchar(255))"))

for i in 1..10:
  var name = "t" & $i
  echo(name)
  discard db.getRow(
    SqlQuery("INSERT INTO tags(name) VALUES(\'$1\') RETURNING id" % [name]))

echo("All tests succeeded!")

db.close()
