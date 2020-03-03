discard """
output: "Database created successfully!"
"""

import database

var db = newDatabase()
db.setup()
echo("Database created successfully!")
db.close()
