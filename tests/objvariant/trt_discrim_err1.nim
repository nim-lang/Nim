discard """
  errormsg: "possible values {0, 2147483643 .. 2147483647} are in conflict with discriminator values for selected object branch 4"
  line: 19
"""
type
  IntObj = object
    case kind: int32
    of low(int32) .. -1: bad: string
    of 0: neutral: string
    of 1 .. high(int32): good: string
    else: error: string # should not be needed.

let intKind = 29'i32

static:echo high(int32)
case intKind
of low(int32) .. -1: discard IntObj(kind: intKind, bad: "bad")
of 1 .. high(int32)-5: discard IntObj(kind: intKind, good: "good")
else: discard IntObj(kind: intKind, error: "error")
