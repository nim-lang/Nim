
# Program to detect bug #1796 reliably

type
  Node = ref object
    a, b: Node
    leaf: string

proc createCycle(leaf: string): Node =
  new result
  result.a = result
  shallowCopy result.leaf, leaf

proc main =
  for i in 0 .. 100_000:
    var leaf = "this is the leaf. it allocates"
    let x = createCycle(leaf)
    let y = createCycle(leaf)

main()
