type Node = ref object
  kind: Node

var n1 = Node()
var n2 = Node()
n2.kind = n1

proc foo =
  echo cast[int](n1)

foo()
