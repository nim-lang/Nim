discard """
action: reject
"""

proc somefn*[T](list: openarray[T], op: proc (v: T): float) =
  discard op(list[0])

type TimeD* = object
  year*:  Natural
  month*: 1..12
  day*:   1..31

@[TimeD()].somefn(proc (v: auto): auto =
  v
)
