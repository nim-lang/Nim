import macros

proc doCheck(tree: NimNode) =
  let res: tuple[n: NimNode] = (n: tree)
  assert: tree.kind == res.n.kind
  for sub in tree:
    doCheck(sub)

macro id(body: untyped): untyped =
  doCheck(body)

id(foo((i: int)))

static:
  let tree = newTree(nnkExprColonExpr)
  let t = (n: tree)
  assert: t.n.kind == tree.kind
