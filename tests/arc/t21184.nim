discard """
  matrix: "--mm:orc"
"""

import std/[with]

type
  Node* {.acyclic.} = ref object of RootObj
    name: string
    data: pointer
    children: seq[Node]
  TextNode = ref object of Node
    text: string

proc fakeEcho(s: string) =
  if s.len < 0:
    echo s

proc newNode[T: Node](parent: Node): T =
  new result
  result.data = alloc0(250)
  parent.children.add(result)

proc newRootNode(): Node =
  new result
  result.data = alloc0(250)

method printNode(node: Node) {.base.} =
  fakeEcho node.name

method printNode(node: TextNode) =
  procCall printNode(Node(node))
  fakeEcho node.text

proc printChildren(node: Node) =
  for child in node.children:
    child.printNode()
    printChildren(child)

proc free(node: Node) =
  for child in node.children:
    free(child)
  dealloc(node.data)

template node(parent: Node, body: untyped): untyped =
  var node = newNode[Node](parent)
  with node:
    body

proc textNode(parent: Node, text: string) =
  var node = newNode[TextNode](parent)
  node.text = text

template withRootNode(body: untyped): untyped =
  var root = newRootNode()
  root.name = "root"
  with root:
    body
  root.printNode()
  printChildren(root)
  root.free()

proc doTest() =
  withRootNode:
    node:
      name = "child1"
      node:
        name = "child2"
        node:
          name = "child3"
          textNode "Hello, world!"


# bug #21171
if isMainModule:
  for i in 0..100000:
    doTest()
