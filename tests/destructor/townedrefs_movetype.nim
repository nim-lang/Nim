discard """
  errormsg: "'=copy' is not available for type <Holder>; requires a copy because it's not the last read of 'h'"
  line: 14
"""
# a value type with an `owned` field is move-only
{.experimental: "ownedRefs".}
type
  Node = ref object
    data: int
  Holder = object
    n: owned Node
proc main =
  var h = Holder(n: Node(data: 1))
  var h2 = h
  echo h.n.data, h2.n.data
main()
