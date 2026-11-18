discard """
  output: '''
p Table[system.int, system.string] Table[system.string, system.int]
p Table[system.int, system.string] Table[system.int, system.string]
q seq[int] seq[string]
'''
"""

# bug #1385: the manual's `distinct Table` example
import std/tables

proc p(a: Table, b: distinct Table) =
  echo "p ", $typeof(a), " ", $typeof(b)

var t1: Table[int, string]
var t2: Table[string, int]
p(t1, t2)
p(t1, t1)

proc q(a: seq, b: distinct seq) =
  echo "q ", $typeof(a), " ", $typeof(b)

q(@[1], @["a"])

# without `distinct` the type class still binds once
proc r(a: Table, b: Table) = discard
doAssert not compiles(r(t1, t2))
doAssert compiles(r(t1, t1))
