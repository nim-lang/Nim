discard """
  output: '''
42
5
3
2
'''
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

# Sink and move semantics
type
  BigObj = object
    data: seq[int]

proc consume(x: sink BigObj) =
  echo x.data.len

var b = BigObj(data: @[1, 2, 3, 4, 5])
consume(move b)

proc divmod(a, b: int): (int, int) =
  (a div b, a mod b)


let (q, r) = divmod(17, 5)
echo q
echo r