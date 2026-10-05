discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
ok
ok
'''
"""
block:
  type Node = object
    children: seq[Node]

  proc buildMoved(n: var Node): Node =
    Node(children: move(n.children[0].children))

  proc actMoved(n: var Node) =
    n.children[0] = Node(children: @[buildMoved(n)])
    doAssert n.children[0].children.len == 1

  proc main =
    var a = Node(children: @[Node(children: @[Node()])])
    actMoved(a)
    doAssert a.children[0].children.len == 1

  main()
  echo "ok"

block:
  type Node = object
    children: seq[Node]

  proc buildCopied(n: var Node): Node =
    let kids = n.children[0].children
    Node(children: kids)

  proc actCopied(n: var Node) =
    n.children[0] = Node(children: @[buildCopied(n)])

  proc main =
    var b = Node(children: @[Node(children: @[Node()])])
    actCopied(b)
    doAssert b.children[0].children.len == 1

  main()
  echo "ok"  