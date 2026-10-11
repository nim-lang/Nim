discard """
  errormsg: "illegal recursion in type 'A'"
  line: 9
"""

# bug #14015: used to crash the compiler with an endless recursion
import std/tables
type
  A* = TableRef[string, B]
  B* = A

proc test*() =
  var tabl = newTable[string, B]()

test()
