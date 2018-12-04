discard """
action: compile
"""

#bug #712

import tables

proc test(): Table[string, string] =
  discard

proc test2(): Table[string, string] =
  discard

var x = 5
let blah =
  case x
  of 5:
    test2()
  of 2:
    test()
  else: test()

echo blah.len
