discard """
  errormsg: "cannot instantiate: 'T'"
  line: 12
"""

# bug #2594


type
  ResultValue* = int64

proc toNumber[T: int|uint|int64|uint64](v: ResultValue): T =
  if v < low(T) or v > high(T):
    raise newException(RangeDefect, "protocol error")
  return T(v)

#proc toNumber[T](v: int32): T =
#  return (v)

echo toNumber(23)
