discard """
  cmd: "nim check $file"
  action: "reject"
  errormsg: "type mismatch:"
"""

# `nim check` used to crash on this after the first error
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
