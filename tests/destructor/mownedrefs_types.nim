{.experimental: "ownedRefs".}
type
  Node* = ref object
    next*: owned Node
    data*: int
    onChange*: owned proc ()

proc len*(n: Node): int =
  var it = n
  while it != nil:
    inc result
    it = it.next
