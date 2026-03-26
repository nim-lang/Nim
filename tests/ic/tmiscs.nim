discard """
  output: '''
42
5
3
2
1.0
2.0
55
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


# Shallow object with seq (trigger GC interaction)
type
  Matrix = object
    rows, cols: int
    data: seq[float]

proc newMatrix(r, c: int): Matrix =
  Matrix(rows: r, cols: c, data: newSeq[float](r * c))

proc `[]`(m: Matrix, r, c: int): float =
  m.data[r * m.cols + c]

proc `[]=`(m: var Matrix, r, c: int, v: float) =
  m.data[r * m.cols + c] = v

var m = newMatrix(2, 2)
m[0, 0] = 1.0
m[1, 1] = 2.0
echo m[0, 0]
echo m[1, 1]

block:
  template compute(body: untyped): int =
    block:
      body
  let x = compute:
    var sum = 0
    for i in 1..10: sum += i
    sum

  echo x

