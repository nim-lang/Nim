discard """
  errormsg: "cannot mutate location select(x, z).data within a strict func"
  line: 35
"""

{.experimental: "strictFuncs".}

type
  Node = ref object
    le, ri: Node
    data: string

func insert(x: var seq[Node]; yyy: Node) =
  let L = x.len
  x.setLen L + 1
  x[L] = yyy

func len(n: Node): int =
  var it = n
  while it != nil:
    inc result
    it = it.ri

func doNotDistract(n: Node) =
  var m = Node(data: "abc")

func select(a, b: Node): Node = b

func mutate(n: Node) =
  var it = n
  let x = it
  let y = x
  let z = y

  select(x, z).data = "tricky"
