discard """
  errormsg: "branch initialization with a runtime discriminator only supports ordinal types."
  line: 13
"""
type
  HoledObj = object
    case kind: string
    of "A": a: int
    else: discard

let str = "B"
case str
of "A": echo HoledObj(kind: str, a: 1)
else: discard
