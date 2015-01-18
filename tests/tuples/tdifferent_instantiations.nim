# bug #1920
import tables

var p: OrderedTable[tuple[a:int], int]
var q: OrderedTable[tuple[x:int], int]
for key in p.keys:
  echo key.a
for key in q.keys:
  echo key.x
