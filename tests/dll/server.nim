discard """
action: compile
  cmd: "nim $target --debuginfo --hints:on --define:useNimRtl --app:lib $options $file"
batchable: false
"""

type
  TNodeKind = enum nkLit, nkSub, nkAdd, nkDiv, nkMul
  TNode = object
    case k: TNodeKind
    of nkLit: x: int
    else: a, b: ref TNode

  PNode = ref TNode

proc newLit(x: int): PNode {.exportc: "newLit", dynlib.} =
  result = PNode(k: nkLit, x: x)

proc newOp(k: TNodeKind, a, b: PNode): PNode {.exportc: "newOp", dynlib.} =
  assert a != nil
  assert b != nil
  result = PNode(k: nkSub, a: a, b: b)
  # now overwrite with the real value:
  result.k = k

proc buildTree(x: int): PNode {.exportc: "buildTree", dynlib.} =
  result = newOp(nkMul, newOp(nkAdd, newLit(x), newLit(x)), newLit(x))
