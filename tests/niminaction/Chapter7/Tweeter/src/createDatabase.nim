import database

var db = newDatabase()
db.setup()
echo("Database created successfully!")
db.close()