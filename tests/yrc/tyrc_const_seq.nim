discard """
  matrix: "--mm:yrc; --mm:orc"
  output: "2 24 2 24"
"""

# bug #26579: seqs of cyclic refs and closures at compile time under YRC
type Node = ref object
  next: Node
  value: int

proc build(): seq[Node] =
  var nodes: seq[Node]
  nodes.add Node(value: 1)
  nodes.add Node(value: 2)
  nodes[0].next = nodes[1]
  nodes[1].next = nodes[0]
  nodes.setLen 3
  nodes.del 0
  result = nodes

proc closures(): int =
  var fs: seq[proc(): int {.closure.}]
  for i in 0..3:
    let j = i
    fs.add proc(): int = j * 2
  var g = fs[1]
  g = fs[3]
  fs.del 0
  for f in fs: result += f()
  result += g()

const count = build().len
const c2 = closures()
echo count, " ", c2, " ", build().len, " ", closures()
