
# bug #1700
import tables

type
  E* = enum
    eX
    eY
  T* = object
    case kind: E
    of eX:
      xVal: Table[string, T]
    of eY:
      nil

proc p*(x: Table[string, T]) =
  discard
