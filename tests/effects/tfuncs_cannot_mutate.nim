discard """
  errormsg: "'mutate' can have side effects"
  line: 25
"""

{.experimental: "strictFuncs".}

type
  Node = ref object
    le, ri: Node
    data: string

func len(n: Node): int =
  var it = n
  while it != nil:
    inc result
    it = it.ri

func doNotDistract(n: Node) =
  var m = Node()
  m.data = "abc"

func select(a, b: Node): Node = b

func mutate(n: Node) =
  var it = n
  let x = it
  let y = x
  let z = y

  select(x, z).data = "tricky"
