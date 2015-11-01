import db_postgres

let db = open("localhost", "dom", "", "test")
db.exec(sql"DROP TABLE IF EXISTS myTable")
db.exec(sql("""CREATE TABLE myTable (
                  id integer PRIMARY KEY,
                  name varchar(50) not null)"""))
let name = "Dom"
db.exec(sql"INSERT INTO myTable (id, name) VALUES (0, ?)",
        name)
doAssert db.getValue(sql"SELECT name FROM myTable") == name

db.close()