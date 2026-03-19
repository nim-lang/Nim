discard """
  disabled: "linux"
  output: "42"
"""

# Object variant / case object
type
  NodeKind = enum
    nkInt, nkStr, nkAdd

  Node = object
    case kind: NodeKind
    of nkInt: intVal: int
    of nkStr: strVal: string
    of nkAdd: left, right: ref Node

proc newInt(v: int): ref Node =
  new(result)
  result[] = Node(kind: nkInt, intVal: v)

let n = newInt(42)
echo n.intVal
