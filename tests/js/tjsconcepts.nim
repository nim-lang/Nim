discard """
  output: "1"
"""

type
  LimitMixin* = object
    min*: int
    max*: int

  A* = ref object
    limit*: LimitMixin
    b*: int

  WithLimit = concept ref a
    a.limit is LimitMixin

proc min(a: WithLimit): int =
  a.limit.min

proc max(a: WithLimit): int =
  a.limit.max

var a = A(limit: LimitMixin(min: 1, max: 2))
echo a.min

