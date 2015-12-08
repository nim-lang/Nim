discard """
  file: "trectuple.nim"
  errormsg: "illegal recursion in type 'TNode'"
  line: 9
  disabled: true
"""

type
    PNode = ref TNode
    TNode = tuple # comment
      self: PNode # comment
      a, b: int # comment

var node: PNode
new(node)
node.self = node
