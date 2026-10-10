discard """
  errormsg: "type mismatch: got <Node> but expected 'owned Node'"
  line: 11
"""
# shared cannot be upgraded to unique
{.experimental: "ownedRefs".}
type Node = ref object
  next: owned Node
proc main(u: Node) =
  let a = Node()
  a.next = u
main(nil)
