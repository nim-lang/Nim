discard """
  errormsg: "illformed AST: "
  line: 24
"""

import macros

type
  Node* = ref object
    children: seq[Node]

proc newNode*(): Node =
  Node(children: newSeq[Node]())

macro build*(body: untyped): untyped =

  template appendElement(tmp, childrenBlock) {.dirty.} =
    bind newNode
    let tmp = newNode()
    tmp.children = childrenBlock  # this line seems to be the problem

  let tmp = genSym(nskLet, "tmp")
  let childrenBlock = newEmptyNode()
  result = getAst(appendElement(tmp, childrenBlock))

build(body)
