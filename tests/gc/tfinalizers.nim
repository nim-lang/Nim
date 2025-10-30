
type
  PNode = ref TNode
  TNode = object
    le: PNode

proc finalizeNode(n: PNode) =
  var s = @[0]

proc returnTree() =
  var cycle: PNode
  new(cycle, finalizeNode)
  cycle.le = cycle

for i in 1..100:
  returnTree()

GC_fullCollect()
GC_fullCollect()
