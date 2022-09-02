import std/db_mysql

doAssert dbQuote("SELECT * FROM foo WHERE col1 = 'bar_baz'") == "'SELECT * FROM foo WHERE col1 = \\'bar_baz\\''"
doAssert dbQuote("SELECT * FROM foo WHERE col1 LIKE '%bar_baz%'") == "'SELECT * FROM foo WHERE col1 LIKE \\'%bar_baz%\\''"
