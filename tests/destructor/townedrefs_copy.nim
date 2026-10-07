discard """
  errormsg: "'=copy' is not available for type <owned Node>; requires a copy because it's not the last read of 'a'"
  line: 12
"""
{.experimental: "ownedRefs".}
type Node = ref object
  next: owned Node
  data: int

proc main =
  let a = Node(data: 1)
  let b = a
  echo a.data, b.data
main()
