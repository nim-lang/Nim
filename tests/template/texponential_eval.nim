# bug #1940

discard """
nimout: '''
===
merge (A) with (B)
merge (A B) with (C)
merge (A B C) with (D)
merge (A B C D) with (E)
merge (A B C D E) with (F)
===
'''

output: "A B C D E F"
"""

type SqlStmt = tuple
  sql: string
  parts: int

proc sql(q: string): SqlStmt =
  result.sql = q
  result.parts = 1

template `&%%`(x, y: SqlStmt): SqlStmt =
  const a = x
  const b = y

  static:
    #echo "some merge"
    echo "merge (", a.sql, ") with (", b.sql, ")"


  const newSql = a.sql & " " & b.sql
  const newParts = a.parts + b.parts

  SqlStmt((sql: newSql, parts: newParts))

static:
  echo "==="

let c =(sql("A") &%%
        sql("B")) &%%
        sql("C")  &%%
        sql("D") &%%
        sql("E") &%%
        sql("F")
echo c.sql

static:
  echo "==="
