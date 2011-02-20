discard """
  file: "tvariantasgn.nim"
  output: "came here"
"""
#BUG
type
  TAnyKind = enum
    nkInt,
    nkFloat,
    nkString
  TAny = object
    case kind: TAnyKind
    of nkInt: intVal: int
    of nkFloat: floatVal: float
    of nkString: strVal: string

var s: TAny
s.kind = nkString
s.strVal = "test"

var nr: TAny
nr.kind = nkint
nr.intVal = 78


# s = nr # works
nr = s # fails!
echo "came here"


