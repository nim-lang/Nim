discard """
  disabled: true
"""

type
    PNode = ref TNode
    TNode = tuple[self: PNode]

var node: PNode
new(node)
node.self = node

