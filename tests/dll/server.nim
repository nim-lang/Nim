discard """
  cmd: "nim $target --debuginfo --hints:on --define:useNimRtl --app:lib $options $file"
"""

type
  TNodeKind = enum nkLit, nkSub, nkAdd, nkDiv, nkMul
  TNode = object
    case k: TNodeKind
    of nkLit: x: int
    else: a, b: ref TNode

  PNode = ref TNode
    
proc newLit(x: int): PNode {.exportc: "newLit", dynlib.} =
  new(result)
  result.x = x
  
proc newOp(k: TNodeKind, a, b: PNode): PNode {.exportc: "newOp", dynlib.} =
  assert a != nil
  assert b != nil
  new(result)
  result.k = k
  result.a = a
  result.b = b
  
proc buildTree(x: int): PNode {.exportc: "buildTree", dynlib.} = 
  result = newOp(nkMul, newOp(nkAdd, newLit(x), newLit(x)), newLit(x))

when false:
  # Test the GC:
  for i in 0..100_000:
    discard buildTree(2)
    
  echo "Done"
