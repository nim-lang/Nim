discard """
  errormsg: "field access outside of valid case branch: x.x"
  line: 45
"""

{.experimental: "strictCaseObjects".}

type
  NodeKind = enum
    nkParent,
    nkChild
  
  Node {.acyclic.} = ref object
    case kind: NodeKind
    of nkParent:
      children: seq[Node]
    of nkChild:
      name: string

let list = @[Node(kind: nkParent, children: @[]), Node(kind: nkChild, name: "hello")]
for node in list:
  case node.kind
  of nkChild: 
    echo $node.name # here this time there is a warning
  else: discard


type
  Foo = object
    case b: bool
    of false:
      s: string
    of true:
      x: int

var x = Foo(b: true, x: 4)
case x.b
of true:
  echo x.x
of false:
  echo "no"

case x.b
of false:
  echo x.x
of true:
  echo "no"
