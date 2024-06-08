discard """
  errormsg: "cannot mutate location kid.parent within a strict func"
  line: 16
"""

{.experimental: "strictFuncs".}

type
  Node = ref object
    name: string
    kids: seq[Node]
    parent: Node

func initParents(tree: Node) =
  for kid in tree.kids:
    kid.parent = tree
    initParents(kid)

proc process(intro: Node): Node =
  var tree = Node(name: "root", kids: @[
    intro,
    Node(name: "one", kids: @[
      Node(name: "two"),
      Node(name: "three"),
    ]),
    Node(name: "four"),
  ])
  initParents(tree)

proc main() =
  var intro = Node(name: "intro")
  var tree = process(intro)
  echo intro.parent.name

main()
