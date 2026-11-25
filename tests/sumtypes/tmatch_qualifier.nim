discard """
  errormsg: "undeclared sum type branch: strutils.Some"
  line: 13
"""

import std/strutils
type
  Opt = object
    case
    of None: discard
    of Some: val: int
case Some(val: 1)
of strutils.Some(v): echo v
of None: discard
