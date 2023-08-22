import std/db_mysql
import std/assertions

doAssert dbQuote("SELECT * FROM foo WHERE col1 = 'bar_baz'") == "'SELECT * FROM foo WHERE col1 = \\'bar_baz\\''"
doAssert dbQuote("SELECT * FROM foo WHERE col1 LIKE '%bar_baz%'") == "'SELECT * FROM foo WHERE col1 LIKE \\'%bar_baz%\\''"
