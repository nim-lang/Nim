discard """
errormsg: "illegal recursion in type 'Weird'"
"""

# issue #3456

import tables
type
  Weird = ref seq[Weird]
var t = newTable[int, Weird]()
