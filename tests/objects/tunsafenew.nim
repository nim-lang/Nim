discard """
  errormsg: "conversion from int literal(-1) to Natural is invalid"
"""

type
  Obj = object
    case b: bool
    else: discard
var o: ref Obj
unsafeNew(o, -1)