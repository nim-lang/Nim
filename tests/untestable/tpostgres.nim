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

  info "DbError",
    msg = $msg

  doAssert "no parameter" in msg
  doAssert "$1" in msg

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
    
# get column details
db.exec(SqlQuery("DROP TABLE IF EXISTS dbtypes;"))
db.exec(SqlQuery("DROP TYPE IF EXISTS custom_enum;"))
db.exec(SqlQuery("CREATE TYPE custom_enum AS ENUM ('1', '2', '3');"))
db.exec(SqlQuery("DROP TYPE IF EXISTS custom_composite;"))
db.exec(SqlQuery("CREATE TYPE custom_composite AS (r double precision, i double precision);"))
db.exec(SqlQuery("""CREATE TABLE dbtypes(
                    id serial UNIQUE,
                    bytea_col bytea,
                    smallint_col smallint,
                    integer_col integer,
                    bigint_col bigint,
                    decimal_col decimal,
                    numeric_col numeric,
                    real_col real,
                    double_precision_col double precision,
                    smallserial_col smallserial,
                    serial_col serial,
                    bigserial_col bigserial,
                    money_col money,
                    varchar_col varchar(10),
                    character_col character(1),
                    text_col text,
                    timestamp_col timestamp,
                    date_col date,
                    time_col time,
                    interval_col interval,
                    bool_col boolean,
                    custom_enum_col custom_enum,
                    point_col point,
                    line_col line,
                    lseg_col lseg,
                    box_col box,
                    path_col path,
                    polygon_col polygon,
                    circle_col circle,
                    cidr_col cidr,
                    inet_col inet,
                    macaddr_col macaddr,
                    bit_col bit,
                    varbit_col bit(3),
                    tsvector_col tsvector,
                    tsquery_col tsquery,
                    uuid_col uuid,
                    xml_col xml,
                    json_col json,
                    array_col integer[],
                    custom_composite_col custom_composite,
                    range_col int4range
                    );"""))
db.exec(SqlQuery("INSERT INTO dbtypes (id) VALUES(0);"))

var dbCols : DbColumns = @[]
for row in db.instantRows(dbCols, sql"SELECT * FROM dbtypes"):
  doAssert len(dbCols) == 42

doAssert dbCols[0].name == "id"
doAssert dbCols[0].typ.kind == DbTypeKind.dbInt
doAssert dbCols[0].typ.name == "int4"
doAssert dbCols[0].typ.size == 4

doAssert dbCols[1].name == "bytea_col"
doAssert dbCols[1].typ.kind == DbTypeKind.dbBlob
doAssert dbCols[1].typ.name == "bytea"

doAssert dbCols[2].name == "smallint_col"
doAssert dbCols[2].typ.kind == DbTypeKind.dbInt
doAssert dbCols[2].typ.name == "int2"
doAssert dbCols[2].typ.size == 2

doAssert dbCols[3].name == "integer_col"
doAssert dbCols[3].typ.kind == DbTypeKind.dbInt
doAssert dbCols[3].typ.name == "int4"
doAssert dbCols[3].typ.size == 4

doAssert dbCols[4].name == "bigint_col"
doAssert dbCols[4].typ.kind == DbTypeKind.dbInt
doAssert dbCols[4].typ.name == "int8"
doAssert dbCols[4].typ.size == 8

doAssert dbCols[5].name == "decimal_col"
doAssert dbCols[5].typ.kind == DbTypeKind.dbDecimal
doAssert dbCols[5].typ.name == "numeric"

doAssert dbCols[6].name == "numeric_col"
doAssert dbCols[6].typ.kind == DbTypeKind.dbDecimal
doAssert dbCols[6].typ.name == "numeric"

doAssert dbCols[7].name == "real_col"
doAssert dbCols[7].typ.kind == DbTypeKind.dbFloat
doAssert dbCols[7].typ.name == "float4"

doAssert dbCols[8].name == "double_precision_col"
doAssert dbCols[8].typ.kind == DbTypeKind.dbFloat
doAssert dbCols[8].typ.name == "float8"

doAssert dbCols[9].name == "smallserial_col"
doAssert dbCols[9].typ.kind == DbTypeKind.dbInt
doAssert dbCols[9].typ.name == "int2"

doAssert dbCols[10].name == "serial_col"
doAssert dbCols[10].typ.kind == DbTypeKind.dbInt
doAssert dbCols[10].typ.name == "int4"

doAssert dbCols[11].name == "bigserial_col"
doAssert dbCols[11].typ.kind == DbTypeKind.dbInt
doAssert dbCols[11].typ.name == "int8"

doAssert dbCols[12].name == "money_col"
doAssert dbCols[12].typ.kind == DbTypeKind.dbDecimal
doAssert dbCols[12].typ.name == "money"    
    
doAssert dbCols[13].name == "varchar_col"
doAssert dbCols[13].typ.kind == DbTypeKind.dbVarchar
doAssert dbCols[13].typ.name == "varchar"

doAssert dbCols[14].name == "character_col"
doAssert dbCols[14].typ.kind == DbTypeKind.dbFixedChar
doAssert dbCols[14].typ.name == "bpchar"

doAssert dbCols[15].name == "text_col"
doAssert dbCols[15].typ.kind == DbTypeKind.dbVarchar
doAssert dbCols[15].typ.name == "text"

doAssert dbCols[16].name == "timestamp_col"
doAssert dbCols[16].typ.kind == DbTypeKind.dbTimestamp
doAssert dbCols[16].typ.name == "timestamp"

doAssert dbCols[17].name == "date_col"
doAssert dbCols[17].typ.kind == DbTypeKind.dbDate
doAssert dbCols[17].typ.name == "date"

doAssert dbCols[18].name == "time_col"
doAssert dbCols[18].typ.kind == DbTypeKind.dbTime
doAssert dbCols[18].typ.name == "time"

doAssert dbCols[19].name == "interval_col"
doAssert dbCols[19].typ.kind == DbTypeKind.dbTimeInterval
doAssert dbCols[19].typ.name == "interval"

doAssert dbCols[20].name == "bool_col"
doAssert dbCols[20].typ.kind == DbTypeKind.dbBool
doAssert dbCols[20].typ.name == "bool"

doAssert dbCols[21].name == "custom_enum_col"
doAssert dbCols[21].typ.kind == DbTypeKind.dbUnknown
doAssert parseInt(dbCols[21].typ.name) > 0
    
doAssert dbCols[22].name == "point_col"
doAssert dbCols[22].typ.kind == DbTypeKind.dbPoint
doAssert dbCols[22].typ.name == "point"    

doAssert dbCols[23].name == "line_col"
doAssert dbCols[23].typ.kind == DbTypeKind.dbLine
doAssert dbCols[23].typ.name == "line"    

doAssert dbCols[24].name == "lseg_col"
doAssert dbCols[24].typ.kind == DbTypeKind.dbLseg
doAssert dbCols[24].typ.name == "lseg"    

doAssert dbCols[25].name == "box_col"
doAssert dbCols[25].typ.kind == DbTypeKind.dbBox
doAssert dbCols[25].typ.name == "box"    

doAssert dbCols[26].name == "path_col"
doAssert dbCols[26].typ.kind == DbTypeKind.dbPath
doAssert dbCols[26].typ.name == "path"    

doAssert dbCols[27].name == "polygon_col"
doAssert dbCols[27].typ.kind == DbTypeKind.dbPolygon
doAssert dbCols[27].typ.name == "polygon"

doAssert dbCols[28].name == "circle_col"
doAssert dbCols[28].typ.kind == DbTypeKind.dbCircle
doAssert dbCols[28].typ.name == "circle"

doAssert dbCols[29].name == "cidr_col"
doAssert dbCols[29].typ.kind == DbTypeKind.dbInet
doAssert dbCols[29].typ.name == "cidr"

doAssert dbCols[30].name == "inet_col"
doAssert dbCols[30].typ.kind == DbTypeKind.dbInet
doAssert dbCols[30].typ.name == "inet"

doAssert dbCols[31].name == "macaddr_col"
doAssert dbCols[31].typ.kind == DbTypeKind.dbMacAddress
doAssert dbCols[31].typ.name == "macaddr"

doAssert dbCols[32].name == "bit_col"
doAssert dbCols[32].typ.kind == DbTypeKind.dbBit
doAssert dbCols[32].typ.name == "bit"

doAssert dbCols[33].name == "varbit_col"
doAssert dbCols[33].typ.kind == DbTypeKind.dbBit
doAssert dbCols[33].typ.name == "bit"

doAssert dbCols[34].name == "tsvector_col"
doAssert dbCols[34].typ.kind == DbTypeKind.dbVarchar
doAssert dbCols[34].typ.name == "tsvector"

doAssert dbCols[35].name == "tsquery_col"
doAssert dbCols[35].typ.kind == DbTypeKind.dbVarchar
doAssert dbCols[35].typ.name == "tsquery"

doAssert dbCols[36].name == "uuid_col"
doAssert dbCols[36].typ.kind == DbTypeKind.dbVarchar
doAssert dbCols[36].typ.name == "uuid"

doAssert dbCols[37].name == "xml_col"
doAssert dbCols[37].typ.kind == DbTypeKind.dbXml
doAssert dbCols[37].typ.name == "xml"

doAssert dbCols[38].name == "json_col"
doAssert dbCols[38].typ.kind == DbTypeKind.dbJson
doAssert dbCols[38].typ.name == "json"

doAssert dbCols[39].name == "array_col"
doAssert dbCols[39].typ.kind == DbTypeKind.dbArray
doAssert dbCols[39].typ.name == "int4[]"

doAssert dbCols[40].name == "custom_composite_col"
doAssert dbCols[40].typ.kind == DbTypeKind.dbUnknown
doAssert parseInt(dbCols[40].typ.name) > 0

doAssert dbCols[41].name == "range_col"
doAssert dbCols[41].typ.kind == DbTypeKind.dbComposite
doAssert dbCols[41].typ.name == "int4range"

# issue 6571
db.exec(sql"DROP TABLE IF EXISTS DICTIONARY")
db.exec(sql("""CREATE TABLE DICTIONARY(
               id             SERIAL PRIMARY KEY,
               entry      VARCHAR(1000) NOT NULL,
               definition VARCHAR(4000) NOT NULL
            );"""))
var entry = "あっそ"
var definition = "(int) (See ああそうそう) oh, really (uninterested)/oh yeah?/hmmmmm"
discard db.getRow(
  sql("INSERT INTO DICTIONARY(entry, definition) VALUES(?, ?) RETURNING id"), entry, definition)
doAssert db.getValue(sql"SELECT definition FROM DICTIONARY WHERE entry = ?", entry) == definition
entry = "Format string entry"
definition = "Format string definition"
db.exec(SqlQuery("INSERT INTO DICTIONARY(entry, definition) VALUES (?, ?)"), entry, definition)
doAssert db.getValue(sql"SELECT definition FROM DICTIONARY WHERE entry = ?", entry) == definition

echo("All tests succeeded!")

db.close()

