
type
  Node = ref object
    val: int
proc bar(c: Node): var int =
  var n = c
  n.val
var a = Node(val: 3)
a.bar() = 5
doAssert a.val == 5 # fails, got 3
