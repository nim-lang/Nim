# helper of tdcelive/tdceliverefc: only some of these are used

type
  Kind* = enum kInt, kBig, kStr, kNode
  Node* = ref object of RootObj
    case kind*: Kind
    of kInt, kBig: i*: int
    of kStr: s*: string
    of kNode: kids*: seq[Node]
  Leaf* = ref object of Node
    tag*: string

proc toStr*(n: Node): string =
  case n.kind
  of kInt: $n.i
  of kBig: "big " & $n.i
  of kStr: n.s
  of kNode:
    var r = "("
    for k in n.kids: r.add toStr(k) & " "
    r & ")"

proc makeBig*(n: Node) =
  # a discriminant assignment: checked against the RTTI's discriminator table
  # (which the type info's init fills); stays in the branch, so it is allowed
  n.kind = kBig

proc tryMakeStr*(n: Node): string =
  # leaves the branch: only a filled discriminator table can tell
  try:
    n.kind = kStr
    result = "not caught"
  except FieldDefect:
    result = "caught"

proc deadSwitch*(n: Node) =
  # never called: neither it nor what only it needs may survive
  n.kind = kInt

proc deadFloat*(x: float): string = "dead:" & $x
