discard """
  output: "SUCCESS"
"""

# A test to ensure that the order in which a variant
# object is constructed doesn't matter.

type
  NodeKind = enum
    Literal, Operator

  Node = ref object
    case kind: NodeKind
    of Literal:
      value: int
    of Operator:
      left, right: Node
      operator: char

# The trees used through out this test should
# be the same after construction, the only difference
# being the way we specify their construction.
# This will test that all the values are what we expect.
proc assertTree(root: Node) =
  # check root of tree
  doAssert root.kind == Operator
  doAssert root.operator == '*'

  # check left subtree
  doAssert root.left.value == 5
  doAssert root.left.kind == Literal

  # check right subtree
  doAssert root.right.kind == Operator
  doAssert root.right.operator == '+'

  doAssert root.right.left.value == 5
  doAssert root.right.left.kind == Literal

  doAssert root.right.right.value == 10
  doAssert root.right.right.kind == Literal

proc newLiteralNode(value: int): Node =
  result = Node(
    kind: Literal,
    value: value
  )

var rootOrder1 = Node(
  kind: Operator,
  operator: '*',
  left: newLiteralNode(5),
  right: Node(
    left: newLiteralNode(5),
    right: newLiteralNode(10),
    kind: Operator,
    operator: '+'
  )
)
assertTree(rootOrder1)

var rootOrder2 = Node(
  operator: '*',
  kind: Operator,
  left: newLiteralNode(5),
  right: Node(
    left: newLiteralNode(5),
    right: newLiteralNode(10),
    kind: Operator,
    operator: '+'
  )
)
assertTree(rootOrder2)

var rootOrder3 = Node(
  left: newLiteralNode(5),
  operator: '*',
  kind: Operator,
  right: Node(
    left: newLiteralNode(5),
    right: newLiteralNode(10),
    kind: Operator,
    operator: '+'
  )
)
assertTree(rootOrder3)

var rootOrder4 = Node(
  left: newLiteralNode(5),
  operator: '*',
  kind: Operator,
  right: Node(
    left: newLiteralNode(5),
    kind: Operator,
    operator: '+',
    right: newLiteralNode(10)
  )
)
assertTree(rootOrder4)

var rootOrder5 = Node(
  left: newLiteralNode(5),
  operator: '*',
  kind: Operator,
  right: Node(
    left: newLiteralNode(5),
    operator: '+',
    right: newLiteralNode(10),
    kind: Operator
  )
)
assertTree(rootOrder5)

echo "SUCCESS"
