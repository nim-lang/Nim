discard """
  errormsg: "cannot instantiate: 'GenericNodeObj[T]'; Maybe generic arguments are missing?"
  line: 21
"""
# bug #2509
type
  GenericNodeObj[T] = ref object
    obj: T

  Node* = ref object
    children*: seq[Node]
    parent*: Node

    nodeObj*: GenericNodeObj # [int]

proc newNode*(nodeObj: GenericNodeObj): Node =
  result = Node(nodeObj: nodeObj)
  newSeq(result.children, 10)

var genericObj = GenericNodeObj[int]()
var myNode = newNode(genericObj)
